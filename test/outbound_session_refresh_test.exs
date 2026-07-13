defmodule ExWapp.OutboundSessionRefreshTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Binary, Session, Signal}
  alias ExWapp.Session.Account
  alias ExWapp.Session.Worker.Outbound
  alias ExWapp.Signal.{Encryption, SessionStore}
  alias ExWapp.Store.Memory

  defmodule FakeTransport do
    def send_node(conn, node) when is_pid(conn) do
      send(conn, {:transport_send, self(), node})
      :ok
    end

    def restart_stream(_conn), do: :ok
  end

  defmodule SessionSink do
    use GenServer

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, Keyword.get(opts, :initial, nil))
    end

    @impl true
    def init(state), do: {:ok, state}

    @impl true
    def handle_call({:update_signal_sessions, sessions}, _from, _state) do
      {:reply, :ok, sessions}
    end
  end

  test "recipient prekey refresh expands to all discovered recipient devices when one is stale" do
    local_jid = "11111111111@s.whatsapp.net"
    recipient_base_jid = "22222222222@s.whatsapp.net"
    recipient_linked_jid = "22222222222:91@s.whatsapp.net"

    %{store: store, local_signal: local_signal} = build_local_store(local_jid)
    recipient_base_bundle = build_remote_bundle(recipient_base_jid)
    recipient_linked_bundle = build_remote_bundle(recipient_linked_jid)

    signal_sessions =
      build_existing_session(local_signal, recipient_base_jid, recipient_base_bundle)

    session_pid = start_supervised!({SessionSink, initial: signal_sessions})

    conn =
      start_fake_conn(self(), %{
        device_map: %{
          recipient_base_jid => [recipient_base_jid, recipient_linked_jid]
        },
        prekey_bundles: %{
          recipient_base_jid => recipient_base_bundle,
          recipient_linked_jid => recipient_linked_bundle
        }
      })

    state = outbound_state(store, conn, signal_sessions)

    assert {:ok, _message_id} =
             Outbound.send_text_worker(session_pid, state, recipient_base_jid, "hello")

    assert_receive {:prekey_request, requested_jids}

    assert Enum.sort(requested_jids) ==
             Enum.sort([recipient_base_jid, recipient_linked_jid])

    assert_receive {:message_send, %Binary.Node{tag: "message"}}
  end

  test "healthy single-device recipient reuses the existing session without a prekey refresh" do
    local_jid = "33333333333@s.whatsapp.net"
    recipient_base_jid = "44444444444@s.whatsapp.net"

    %{store: store, local_signal: local_signal} = build_local_store(local_jid)
    recipient_base_bundle = build_remote_bundle(recipient_base_jid)

    signal_sessions =
      build_existing_session(local_signal, recipient_base_jid, recipient_base_bundle)

    session_pid = start_supervised!({SessionSink, initial: signal_sessions})

    conn =
      start_fake_conn(self(), %{
        device_map: %{
          recipient_base_jid => [recipient_base_jid]
        },
        prekey_bundles: %{
          recipient_base_jid => recipient_base_bundle
        }
      })

    state = outbound_state(store, conn, signal_sessions)

    assert {:ok, _message_id} =
             Outbound.send_text_worker(session_pid, state, recipient_base_jid, "hello")

    refute_receive {:prekey_request, _requested_jids}, 50
    assert_receive {:message_send, %Binary.Node{tag: "message"}}
  end

  test "direct media puts every supported mediatype on participant enc nodes" do
    local_jid = "55555555555@s.whatsapp.net"
    recipient_jid = "66666666666@s.whatsapp.net"

    %{store: store, local_signal: local_signal} = build_local_store(local_jid)
    recipient_bundle = build_remote_bundle(recipient_jid)
    signal_sessions = build_existing_session(local_signal, recipient_jid, recipient_bundle)
    session_pid = start_supervised!({SessionSink, initial: signal_sessions})

    conn =
      start_fake_conn(self(), %{
        device_map: %{recipient_jid => [recipient_jid]},
        prekey_bundles: %{recipient_jid => recipient_bundle}
      })

    state = outbound_state(store, conn, signal_sessions)

    for mediatype <- ~w(image ptt document vcard) do
      proto = %ExWapp.Proto.Message{conversation: "#{mediatype} payload"}

      assert {:ok, _message_id} =
               Outbound.send_proto_worker(session_pid, state, recipient_jid, proto,
                 chat_text: "#{mediatype} payload",
                 message_node_type: "media",
                 mediatype: mediatype
               )

      assert_receive {:message_send,
                      %Binary.Node{tag: "message", attrs: attrs, content: content} = node}

      assert attrs["type"] == "media"
      refute Map.has_key?(attrs, "mediatype")

      assert Enum.all?(encrypted_participant_nodes(node), fn %Binary.Node{content: [enc]} ->
               enc.attrs["mediatype"] == mediatype
             end)

      refute Enum.any?(content, &match?(%Binary.Node{tag: "meta"}, &1))
    end
  end

  test "additional message nodes are appended for event metadata" do
    local_jid = "77777777777@s.whatsapp.net"
    recipient_jid = "88888888888@s.whatsapp.net"

    %{store: store, local_signal: local_signal} = build_local_store(local_jid)
    recipient_bundle = build_remote_bundle(recipient_jid)
    signal_sessions = build_existing_session(local_signal, recipient_jid, recipient_bundle)
    session_pid = start_supervised!({SessionSink, initial: signal_sessions})

    conn =
      start_fake_conn(self(), %{
        device_map: %{recipient_jid => [recipient_jid]},
        prekey_bundles: %{recipient_jid => recipient_bundle}
      })

    state = outbound_state(store, conn, signal_sessions)
    proto = %ExWapp.Proto.Message{conversation: "event payload"}
    meta = %Binary.Node{tag: "meta", attrs: %{"event_type" => "creation"}, content: nil}

    assert {:ok, _message_id} =
             Outbound.send_proto_worker(session_pid, state, recipient_jid, proto,
               chat_text: "event payload",
               message_node_type: "event",
               additional_message_nodes: [meta]
             )

    assert_receive {:message_send,
                    %Binary.Node{tag: "message", attrs: attrs, content: content}}

    assert attrs["type"] == "event"
    assert List.last(content) == meta
  end

  test "encrypted DM fans out to recipient devices and own PN devices" do
    local_pn_device_jid = "19995550101:5@s.whatsapp.net"
    local_lid_device_jid = "19995550202:5@lid"
    local_pn_base_jid = "19995550101@s.whatsapp.net"
    local_pn_linked_jid = "19995550101:91@s.whatsapp.net"
    local_lid_base_jid = "19995550202@lid"
    local_lid_linked_jid = "19995550202:91@lid"

    recipient_base_jid = "19995550404@s.whatsapp.net"
    recipient_linked_jid = "19995550404:45@s.whatsapp.net"

    %{store: store, local_signal: local_signal} =
      build_local_store(local_pn_device_jid, local_lid_device_jid)

    signal_sessions = SessionStore.new()

    target_jids = [
      recipient_base_jid,
      recipient_linked_jid,
      local_pn_base_jid,
      local_pn_linked_jid
    ]

    remote_devices =
      target_jids
      |> Enum.map(fn jid -> {jid, build_remote_device(jid)} end)
      |> Map.new()

    prekey_bundles =
      remote_devices
      |> Enum.map(fn {jid, %{bundle: bundle}} -> {jid, bundle} end)
      |> Map.new()

    conn =
      start_fake_conn(self(), %{
        device_map: %{
          recipient_base_jid => [recipient_base_jid, recipient_linked_jid],
          local_lid_base_jid => [
            local_lid_base_jid,
            local_lid_device_jid,
            local_lid_linked_jid
          ]
        },
        prekey_bundles: prekey_bundles
      })

    session = start_connected_session(store, conn, signal_sessions)

    assert {:ok, message_id} = Session.send_text(session, recipient_base_jid, "hello md")
    assert is_binary(message_id)

    assert_receive {:message_send, %Binary.Node{tag: "message", attrs: attrs} = node}

    assert attrs["to"] == recipient_base_jid

    participant_targets = encrypted_participant_targets(node)

    assert Enum.sort(participant_targets) == Enum.sort(target_jids)
    refute local_pn_device_jid in participant_targets
    refute local_lid_base_jid in participant_targets
    refute local_lid_device_jid in participant_targets
    refute local_lid_linked_jid in participant_targets

    assert Enum.all?(encrypted_participant_nodes(node), fn %Binary.Node{content: [enc_node]} ->
             enc_node.tag == "enc" and enc_node.attrs["type"] in ["pkmsg", "msg"] and
               match?(
                 %Binary.Raw{data: data} when is_binary(data) and byte_size(data) > 0,
                 enc_node.content
               )
           end)

    decrypted_payloads =
      node
      |> encrypted_participant_nodes()
      |> Enum.map(fn %Binary.Node{attrs: %{"jid" => jid}, content: [enc_node]} ->
        plaintext = decrypt_participant_payload(jid, enc_node, remote_devices)
        {jid, plaintext}
      end)
      |> Map.new()

    for jid <- [recipient_base_jid, recipient_linked_jid] do
      plaintext = Map.fetch!(decrypted_payloads, jid)
      assert :binary.match(plaintext, "hello md") != :nomatch
      refute :binary.match(plaintext, recipient_base_jid) != :nomatch
      refute match?(<<0xFA, 0x01, _::binary>>, plaintext)
    end

    for jid <- [local_pn_base_jid, local_pn_linked_jid] do
      plaintext = Map.fetch!(decrypted_payloads, jid)
      assert <<0xFA, 0x01, _::binary>> = plaintext
      assert :binary.match(plaintext, recipient_base_jid) != :nomatch
      assert :binary.match(plaintext, "hello md") != :nomatch
    end

    assert Enum.any?(node.content, &match?(%Binary.Node{tag: "device-identity"}, &1))
    assert local_signal.device_id == 5
  end

  test "self-send fans out to all non-current own devices with own-device payloads" do
    local_pn_device_jid = "19995550101:5@s.whatsapp.net"
    local_lid_device_jid = "19995550202:5@lid"
    local_pn_base_jid = "19995550101@s.whatsapp.net"
    local_pn_linked_jid = "19995550101:91@s.whatsapp.net"
    local_lid_base_jid = "19995550202@lid"
    local_lid_linked_jid = "19995550202:91@lid"

    %{store: store} = build_local_store(local_pn_device_jid, local_lid_device_jid)

    signal_sessions = SessionStore.new()

    target_jids = [
      local_pn_base_jid,
      local_pn_linked_jid
    ]

    remote_devices =
      target_jids
      |> Enum.map(fn jid -> {jid, build_remote_device(jid)} end)
      |> Map.new()

    prekey_bundles =
      remote_devices
      |> Enum.map(fn {jid, %{bundle: bundle}} -> {jid, bundle} end)
      |> Map.new()

    conn =
      start_fake_conn(self(), %{
        device_map: %{
          local_pn_base_jid => [
            local_pn_base_jid,
            local_pn_device_jid,
            local_pn_linked_jid
          ],
          local_lid_base_jid => [
            local_lid_base_jid,
            local_lid_device_jid,
            local_lid_linked_jid
          ]
        },
        prekey_bundles: prekey_bundles
      })

    session = start_connected_session(store, conn, signal_sessions)

    assert {:ok, message_id} = Session.send_text(session, local_pn_base_jid, "note to self")
    assert is_binary(message_id)

    assert_receive {:message_send, %Binary.Node{tag: "message", attrs: attrs} = node}

    assert attrs["to"] == local_pn_base_jid

    participant_targets = encrypted_participant_targets(node)

    assert Enum.sort(participant_targets) == Enum.sort(target_jids)
    refute local_pn_device_jid in participant_targets
    refute local_lid_base_jid in participant_targets
    refute local_lid_device_jid in participant_targets
    refute local_lid_linked_jid in participant_targets

    decrypted_payloads =
      node
      |> encrypted_participant_nodes()
      |> Enum.map(fn %Binary.Node{attrs: %{"jid" => jid}, content: [enc_node]} ->
        plaintext = decrypt_participant_payload(jid, enc_node, remote_devices)
        {jid, plaintext}
      end)
      |> Map.new()

    for jid <- target_jids do
      plaintext = Map.fetch!(decrypted_payloads, jid)
      assert <<0xFA, 0x01, _::binary>> = plaintext
      assert :binary.match(plaintext, local_pn_base_jid) != :nomatch
      assert :binary.match(plaintext, "note to self") != :nomatch
    end

    assert Enum.any?(node.content, &match?(%Binary.Node{tag: "device-identity"}, &1))
  end

  test "send_text_worker returns not_connected when the runtime is disconnected" do
    assert {:error, {:not_connected, :disconnected}} =
             Outbound.send_text_worker(
               self(),
               %{status: :disconnected, conn: nil},
               "15550001111@s.whatsapp.net",
               "hello"
             )
  end

  defp outbound_state(store, conn, signal_sessions) do
    %{
      conn: conn,
      runtime_cfg: %{
        iq: %{
          default_timeout_ms: 500,
          prekey_timeout_ms: 500,
          usync_timeout_ms: 500
        }
      },
      session_id: "test-session",
      signal_sessions: signal_sessions,
      store: store,
      status: :connected,
      transport_mod: FakeTransport
    }
  end

  defp start_connected_session(store, conn, signal_sessions) do
    session =
      start_supervised!(
        {Session,
         [
           store: store,
           transport: FakeTransport,
           runtime: %{
             iq: %{
               default_timeout_ms: 500,
               prekey_timeout_ms: 500,
               usync_timeout_ms: 500
             }
           }
         ]}
      )

    :sys.replace_state(session, fn state ->
      %{
        state
        | conn: conn,
          signal_sessions: signal_sessions,
          status: :connected,
          transport_ready?: true
      }
    end)

    session
  end

  defp build_local_store(local_jid) do
    build_local_store(local_jid, nil)
  end

  defp build_local_store(local_jid, local_lid) do
    {:ok, _signal_info, local_signal} = Signal.bootstrap(%{device_attrs: %{"jid" => local_jid}})

    client_info =
      %{jid: local_jid}
      |> maybe_put_lid(local_lid)

    pairing_device =
      %{jid: local_jid}
      |> maybe_put_lid(local_lid)

    store =
      Memory.new(
        initial_data: %{
          client_info: client_info,
          pairing: %{adv_device_identity: <<1, 2, 3, 4>>, device: pairing_device},
          signal: local_signal
        }
      )

    %{store: store, local_signal: local_signal}
  end

  defp maybe_put_lid(map, nil), do: map
  defp maybe_put_lid(map, lid), do: Map.put(map, :lid, lid)

  defp build_remote_bundle(jid) do
    %{bundle: bundle} = build_remote_device(jid)
    bundle
  end

  defp build_remote_device(jid) do
    {:ok, signal_info, signal_state} = Signal.bootstrap(%{device_attrs: %{"jid" => jid}})

    %{
      bundle: signal_info.bundle,
      signal: signal_state
    }
  end

  defp decrypt_participant_payload(
         jid,
         %Binary.Node{attrs: attrs, content: %Binary.Raw{data: ciphertext}},
         remote_devices
       ) do
    %{signal: signal_state} = Map.fetch!(remote_devices, jid)
    enc_type = Map.get(attrs, "type", "msg")

    is_prekey? = enc_type == "pkmsg"

    {:ok, padded_plaintext, _sessions} =
      SessionStore.decrypt_message(
        SessionStore.new(),
        "19995550101:5@s.whatsapp.net",
        ciphertext,
        is_prekey?,
        signal_state.identity_key,
        %{
          signed_prekeys: signal_state.signed_prekeys,
          prekeys: signal_state.prekeys
        }
      )

    Encryption.unpad_message(padded_plaintext)
  end

  defp decrypt_participant_payload(_jid, _node, _remote_devices) do
    flunk("participant node did not contain encrypted raw payload")
  end

  defp encrypted_participant_targets(%Binary.Node{} = node) do
    node
    |> encrypted_participant_nodes()
    |> Enum.map(fn %Binary.Node{attrs: attrs} -> Map.fetch!(attrs, "jid") end)
  end

  defp encrypted_participant_nodes(%Binary.Node{content: content}) when is_list(content) do
    content
    |> Enum.find(fn
      %Binary.Node{tag: "participants"} -> true
      _ -> false
    end)
    |> case do
      %Binary.Node{content: participants} when is_list(participants) -> participants
      _ -> []
    end
  end

  defp encrypted_participant_nodes(_node), do: []

  defp build_existing_session(local_signal, recipient_jid, recipient_bundle) do
    {:ok, _session, _base_key, signal_sessions} =
      SessionStore.get_or_create_session(
        SessionStore.new(),
        recipient_jid,
        local_signal.identity_key,
        recipient_bundle,
        local_signal.registration_id,
        force: true
      )

    signal_sessions
  end

  defp start_fake_conn(owner, responses) do
    spawn_link(fn -> fake_conn_loop(owner, responses) end)
  end

  defp fake_conn_loop(owner, responses) do
    receive do
      {:transport_send, caller,
       %Binary.Node{tag: "iq", attrs: %{"xmlns" => "usync", "id" => id}} = node} ->
        send(owner, {:usync_query, extract_query_jids(node)})
        send(caller, {:prekey_response, id, build_usync_response(id, responses.device_map)})
        fake_conn_loop(owner, responses)

      {:transport_send, caller,
       %Binary.Node{tag: "iq", attrs: %{"xmlns" => "encrypt", "id" => id}} = node} ->
        requested_jids = extract_query_jids(node)
        send(owner, {:prekey_request, requested_jids})

        send(
          caller,
          {:prekey_response, id,
           build_prekey_response(id, responses.prekey_bundles, requested_jids)}
        )

        fake_conn_loop(owner, responses)

      {:transport_send, _caller, %Binary.Node{tag: "message"} = node} ->
        send(owner, {:message_send, node})
        fake_conn_loop(owner, responses)
    end
  end

  defp extract_query_jids(%Binary.Node{content: content}) when is_list(content) do
    content
    |> extract_users()
    |> Enum.map(fn %Binary.Node{attrs: attrs} -> Map.fetch!(attrs, "jid") end)
  end

  defp extract_query_jids(_node), do: []

  defp extract_users(content) when is_list(content) do
    Enum.flat_map(content, fn
      %Binary.Node{tag: "usync", content: usync_content} ->
        usync_content
        |> Enum.find(fn
          %Binary.Node{tag: "list"} -> true
          _ -> false
        end)
        |> case do
          %Binary.Node{content: users} when is_list(users) -> users
          _ -> []
        end

      %Binary.Node{tag: "key", content: users} when is_list(users) ->
        users

      _ ->
        []
    end)
  end

  defp build_usync_response(id, device_map) do
    %Binary.Node{
      tag: "iq",
      attrs: %{"id" => id, "type" => "result"},
      content: [
        %Binary.Node{
          tag: "usync",
          attrs: %{},
          content: [
            %Binary.Node{
              tag: "list",
              attrs: %{},
              content: Enum.map(device_map, &build_usync_user_node/1)
            }
          ]
        }
      ]
    }
  end

  defp build_usync_user_node({base_jid, device_jids}) do
    user =
      base_jid
      |> String.split("@", parts: 2)
      |> hd()

    %Binary.Node{
      tag: "user",
      attrs: %{"jid" => base_jid},
      content: [
        %Binary.Node{
          tag: "devices",
          attrs: %{},
          content: [
            %Binary.Node{
              tag: "device-list",
              attrs: %{},
              content:
                Enum.map(device_jids, fn device_jid ->
                  device_id =
                    case device_jid
                         |> String.split("@", parts: 2)
                         |> hd()
                         |> String.split(":", parts: 2) do
                      [^user] -> "0"
                      [^user, id] -> id
                      _ -> "0"
                    end

                  %Binary.Node{tag: "device", attrs: %{"id" => device_id}, content: nil}
                end)
            }
          ]
        }
      ]
    }
  end

  defp build_prekey_response(id, prekey_bundles, requested_jids) do
    %Binary.Node{
      tag: "iq",
      attrs: %{"id" => id, "type" => "result"},
      content: [
        %Binary.Node{
          tag: "list",
          attrs: %{},
          content:
            Enum.map(requested_jids, fn jid ->
              build_prekey_user_node(jid, Map.fetch!(prekey_bundles, jid))
            end)
        }
      ]
    }
  end

  defp build_prekey_user_node(jid, bundle) do
    registration_id = Map.fetch!(bundle, :registration_id)
    identity_key = Map.fetch!(bundle, :identity_key)
    signed_prekey = Map.fetch!(bundle, :signed_prekey)
    prekey = Map.fetch!(bundle, :prekey)

    %Binary.Node{
      tag: "user",
      attrs: %{"jid" => jid},
      content: [
        %Binary.Node{
          tag: "registration",
          attrs: %{},
          content: Binary.raw(<<registration_id::big-32>>)
        },
        %Binary.Node{
          tag: "identity",
          attrs: %{},
          content: Binary.raw(identity_key)
        },
        Account.signed_prekey_to_node(signed_prekey),
        Account.prekey_to_node(prekey.id, prekey.public)
      ]
    }
  end
end
