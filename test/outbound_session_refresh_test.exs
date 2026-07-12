defmodule ExWapp.OutboundSessionRefreshTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Binary, Signal}
  alias ExWapp.Session.Account
  alias ExWapp.Session.Worker.Outbound
  alias ExWapp.Signal.SessionStore
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

  test "direct usync query skips known LID aliases when a phone-number JID is available" do
    local_jid = "55555555555@s.whatsapp.net"
    recipient_base_jid = "66666666666@s.whatsapp.net"
    recipient_lid_jid = "777777777777777@lid"

    lid_mapping = %{
      {:pn_to_lid, recipient_base_jid} => recipient_lid_jid,
      {:lid_to_pn, recipient_lid_jid} => recipient_base_jid
    }

    %{store: store, local_signal: local_signal} =
      build_local_store(local_jid, lid_mapping: lid_mapping)

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

    assert_receive {:usync_query, queried_jids}
    assert Enum.sort(queried_jids) == Enum.sort([recipient_base_jid, local_jid])
    refute recipient_lid_jid in queried_jids
    assert_receive {:message_send, %Binary.Node{tag: "message"}}
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

  defp build_local_store(local_jid, opts \\ []) do
    {:ok, _signal_info, local_signal} = Signal.bootstrap(%{device_attrs: %{"jid" => local_jid}})

    client_info =
      case Keyword.get(opts, :lid) do
        lid when is_binary(lid) and lid != "" -> %{jid: local_jid, lid: lid}
        _ -> %{jid: local_jid}
      end

    store =
      Memory.new(
        initial_data: %{
          client_info: client_info,
          pairing: %{adv_device_identity: <<1, 2, 3, 4>>},
          signal: local_signal,
          lid_mapping: Keyword.get(opts, :lid_mapping, %{})
        }
      )

    %{store: store, local_signal: local_signal}
  end

  defp build_remote_bundle(jid) do
    {:ok, signal_info, _signal_state} = Signal.bootstrap(%{device_attrs: %{"jid" => jid}})
    signal_info.bundle
  end

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
