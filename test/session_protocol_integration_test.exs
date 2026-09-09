defmodule ExWapp.SessionProtocolIntegrationTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias ExWapp.{Chat, Contact, Media, Session, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Test.ProtocolTransport, as: Transport
  @jid "15550001111@s.whatsapp.net"
  @moduletag capture_log: true

  setup context do
    previous_level = Logger.level()
    Logger.configure(level: :debug)
    on_exit(fn -> Logger.configure(level: previous_level) end)
    local = ExWapp.Test.SignalDevice.new()

    store_module = if context[:fault_store], do: ExWapp.Test.FaultStore, else: Store.Memory

    store =
      store_module.new(
        initial_data: %{
          test_peer: %{owner: self()},
          client_info: %{jid: "15550002222:1@s.whatsapp.net"},
          signal:
            Map.merge(local.local_prekeys, %{identity_key: local.identity, registration_id: 123})
        }
      )

    id = "protocol-#{System.unique_integer([:positive])}"

    if context[:unpaired] do
      Store.transaction(store, &Map.delete(&1, :client_info))
      Store.put(store, :test_peer, %{owner: self(), auto_success: false})
    end

    if context[:initial_sync] do
      Store.put(store, :app_state_keys, %{
        "01" => %{data: :crypto.strong_rand_bytes(32), timestamp: 1}
      })

      Store.put(store, :test_peer, %{
        owner: self(),
        reply: fn %Node{attrs: attrs} ->
          if attrs["xmlns"] == "w:sync:app:state", do: nil, else: :default
        end
      })
    end

    runtime =
      Keyword.merge(
        [
          app_state: [initial_sync_enabled: context[:initial_sync] || false],
          prekeys: [initial_prekey_count: 8, refill_prekey_count: 4],
          iq: [
            default_timeout_ms: 300,
            max_pending_requests: 2,
            usync_timeout_ms: 300,
            prekey_timeout_ms: 300
          ]
        ],
        context[:runtime] || []
      )

    session =
      start_supervised!(%{
        id: make_ref(),
        restart: :temporary,
        start:
          {Session, :start_link,
           [
             [
               store: store,
               session_id: id,
               transport: Transport,
               reconnect: false,
               auto_connect: true,
               runtime: runtime
             ]
           ]}
      })

    assert_receive {:peer_authenticated, conn, _}, 2000

    expected_status =
      cond do
        context[:initial_sync] -> :syncing
        context[:unpaired] -> :handshaking
        true -> :connected
      end

    await(fn -> Session.state(session) == expected_status end)
    %{store: store, session: session, conn: conn, id: id}
  end

  test "signed connection reaches ready state and typing is transmitted over encrypted frames",
       ctx do
    assert ExWapp.state(ctx.session) == :connected
    assert ExWapp.get_session_id(ctx.session) == ctx.id
    assert ExWapp.stats(ctx.session).status == :connected
    assert ExWapp.runtime_config(ctx.session).iq.max_pending_requests == 2
    assert :ok = ExWapp.connect(ctx.session)
    assert :ok = ExWapp.send_typing(ctx.session, @jid)

    assert_receive {:peer_node, _, %Node{tag: "chatstate", content: [%Node{tag: "composing"}]}},
                   1000

    assert :ok = ExWapp.send_typing(ctx.session, @jid, false)
    assert_receive {:peer_node, _, %Node{tag: "chatstate", content: [%Node{tag: "paused"}]}}, 1000
    assert :ok = ExWapp.disconnect(ctx.session)
    await(fn -> ExWapp.state(ctx.session) == :idle end)
    refute Process.alive?(ctx.conn)
    assert {:error, {:not_connected, :idle}} = ExWapp.send_typing(ctx.session, @jid)
  end

  test "IQ routing isolates concurrent replies, rejects duplicate IDs and releases timed out slots",
       ctx do
    request = %Node{tag: "iq", attrs: %{"id" => "one", "xmlns" => "test", "type" => "get"}}
    first = Task.async(fn -> GenServer.call(ctx.session, {:send_iq, request, "one", 2000}) end)
    assert_receive {:peer_node, _, %Node{attrs: %{"id" => "one"}}}, 1000

    assert {:error, {:duplicate_iq_id, "one"}} =
             GenServer.call(ctx.session, {:send_iq, request, "one"})

    second =
      Task.async(fn ->
        GenServer.call(
          ctx.session,
          {:send_iq, %{request | attrs: Map.put(request.attrs, "id", "two")}, "two", 100}
        )
      end)

    assert_receive {:peer_node, _, %Node{attrs: %{"id" => "two"}}}, 1000

    assert {:error, :too_many_pending_iq_requests} =
             GenServer.call(ctx.session, {:send_iq, request, "three"})

    assert {:error, :timeout} = Task.await(second)

    response = %Node{
      tag: "iq",
      attrs: %{"id" => "one", "type" => "result"},
      content: [%Node{tag: "value", content: "accepted"}]
    }

    assert :ok = Transport.inject(ctx.conn, response)
    assert {:ok, %Node{attrs: %{"id" => "one"}}} = Task.await(first)
    assert :sys.get_state(ctx.session).pending_iqs == %{}
    send(ctx.session, {:iq_timeout, "one"})
    assert Session.state(ctx.session) == :connected
  end

  test "disconnect cancels pending IQ callers and replacement transport can reconnect", ctx do
    task =
      Task.async(fn ->
        GenServer.call(
          ctx.session,
          {:send_iq, %Node{tag: "iq", attrs: %{"id" => "pending", "xmlns" => "test"}}, "pending",
           5000}
        )
      end)

    assert_receive {:peer_node, _, %Node{attrs: %{"id" => "pending"}}}, 1000
    assert :ok = Session.disconnect(ctx.session)
    assert {:error, _} = Task.await(task)
    assert :sys.get_state(ctx.session).pending_iqs == %{}
    assert :ok = Session.connect(ctx.session)
    assert_receive {:peer_authenticated, replacement, _}, 2000
    refute replacement == ctx.conn
    await(fn -> Session.state(ctx.session) == :connected end)
    assert :ok = Session.send_typing(ctx.session, @jid)
  end

  test "worker rejects unknown IQ routes without leaving pending operations", ctx do
    valid = %Node{tag: "iq", attrs: %{"id" => "worker-id", "xmlns" => "test"}}

    assert {:error, :unknown_send_worker} =
             GenServer.call(ctx.session, {:send_worker_iq, self(), valid})

    assert {:error, :invalid_iq_route} =
             GenServer.call(ctx.session, {:send_worker_iq, self(), %{valid | attrs: %{}}})

    assert :sys.get_state(ctx.session).pending_iqs == %{}
  end

  test "internal process crashes are repaired and subsequent traffic still flows", ctx do
    for field <- [:outbound_queue, :inbound_router, :send_worker_sup] do
      previous = Map.fetch!(:sys.get_state(ctx.session), field)
      Process.exit(previous, :kill)

      await(fn ->
        current = Map.fetch!(:sys.get_state(ctx.session), field)
        is_pid(current) and current != previous and Process.alive?(current)
      end)
    end

    assert :ok = ExWapp.send_typing(ctx.session, @jid)
    assert_receive {:peer_node, _, %Node{tag: "chatstate"}}, 1000

    assert :ok =
             Transport.inject(ctx.conn, %Node{
               tag: "iq",
               attrs: %{"id" => "server-ping", "type" => "get", "xmlns" => "w:p"},
               content: [%Node{tag: "ping"}]
             })

    assert_receive {:peer_node, _,
                    %Node{tag: "iq", attrs: %{"id" => "server-ping", "type" => "result"}}},
                   1000

    assert Session.state(ctx.session) == :connected
  end

  test "public local APIs read and delete durable data through the live worker", ctx do
    :ok = Chat.update_pinned(ctx.store, @jid, true)

    :ok =
      Store.upsert_messages(ctx.store, @jid, [
        %{id: "a", timestamp: 1, text: "hello"},
        %{id: "b", timestamp: 2, text: "world"}
      ])

    :ok = Contact.update_push_name(ctx.store, @jid, "Alice")
    assert [%Chat{pinned: true}] = ExWapp.list_chats(ctx.session)
    assert [] = ExWapp.list_groups(ctx.session)
    assert {:ok, %Chat{pinned: true}} = ExWapp.get_chat(ctx.session, @jid)
    assert {:ok, %Chat{pinned: true}} = ExWapp.get_chat_info(ctx.session, @jid)
    assert [%Contact{push_name: "Alice"}] = ExWapp.list_contacts(ctx.session)
    assert %Contact{push_name: "Alice"} = ExWapp.get_contact(ctx.session, @jid)
    assert Enum.map(ExWapp.all_messages(ctx.session, @jid), & &1.id) == ["a", "b"]
    assert [%{id: "a"}] = Enum.take(ExWapp.stream_messages(ctx.session, @jid), 1)
    assert :ok = ExWapp.delete_messages(ctx.session, @jid, ["a"])
    assert [%{id: "b"}] = ExWapp.get_messages(ctx.session, @jid)
    assert :ok = ExWapp.mark_chat_read(ctx.session, @jid)
    assert [] = ExWapp.Live.list_calls(ctx.session)
    assert [] = ExWapp.stream_calls(ctx.session) |> Enum.to_list()
    assert {:error, :not_found} = ExWapp.get_call(ctx.session, "absent")
    assert ExWapp.Live.list_chats(ctx.session) == ExWapp.list_chats(ctx.session)
    assert [] = ExWapp.Live.list_groups(ctx.session)
    assert [%{id: "b"}] = ExWapp.Live.get_messages(ctx.session, @jid)
  end

  test "media retry rejects missing keys and duplicate retries, then expires the pending request",
       ctx do
    assert {:error, :message_not_found} = ExWapp.retry_media(ctx.session, "missing")

    :ok =
      Store.upsert_messages(ctx.store, @jid, [
        %{id: "text", text: "hello"},
        %{id: "bad", media: %Media.Ref{media_key: <<1>>, type: :image}},
        %{id: "image", media: %Media.Ref{media_key: <<1::256>>, type: :image}}
      ])

    assert {:error, _} = ExWapp.retry_media(ctx.session, "text")
    assert {:error, :invalid_media_key} = ExWapp.retry_media(ctx.session, "bad")
    task = Task.async(fn -> ExWapp.retry_media(ctx.session, "image", timeout: 150) end)
    assert_receive {:peer_node, _, %Node{tag: "receipt", attrs: %{"id" => "image"}}}, 1000
    assert {:error, :media_retry_already_pending} = ExWapp.retry_media(ctx.session, "image")
    assert {:error, :media_retry_timeout} = Task.await(task, 2000)
    assert :sys.get_state(ctx.session).pending_media_retries == %{}
  end

  test "public pause and resume commands change send policy through PID and PubSub", ctx do
    assert :ok = ExWapp.subscribe(ctx.session)
    assert :ok = ExWapp.subscribe_all()
    assert :ok = ExWapp.control_session(ctx.session, :pause_sends)
    assert ExWapp.health_status(ctx.session).paused
    assert {:error, _} = ExWapp.send_message(ctx.session, @jid, "blocked")
    assert :ok = ExWapp.send_message(ctx.id, @jid, "also blocked")
    assert :ok = ExWapp.control_session(ctx.id, :resume_sends)
    await(fn -> not ExWapp.health_status(ctx.session).paused end)
    assert :ok = ExWapp.control_session(ctx.session, :resume_sends)
    assert is_map(ExWapp.policy_status(ctx.session))
    assert :ok = ExWapp.unsubscribe(ctx.session)
    assert :ok = ExWapp.unsubscribe_all()
  end

  test "app-state mutations report missing keys and do not deadlock the session", ctx do
    assert {:error, :app_state_keys_unavailable} = ExWapp.sync_contacts(ctx.session)
    assert {:error, :no_app_state_keys} = ExWapp.pin_chat(ctx.session, @jid)
    assert Session.state(ctx.session) == :connected

    assert ExWapp.request_pairing_code(ctx.session, "15550001111") ==
             {:error, {:pairing_not_ready, :connected}}

    assert {:error, :invalid_media_reference} =
             GenServer.call(ctx.session, {:download_media, :invalid, []})

    assert {:error, :invalid_message} = GenServer.call(ctx.session, {:send_message, :invalid})
  end

  test "Signal key discovery encrypts messages the other device can decrypt and ratchet replies",
       ctx do
    alias ExWapp.Signal.{Encryption, SessionStore}
    remote = ExWapp.Test.SignalDevice.new()
    :ok = Transport.set_reply(ctx.conn, &ExWapp.Test.SignalDevice.reply(remote, &1))

    assert {:ok, encrypted, :prekey} =
             Encryption.encrypt_for_recipient(ctx.session, @jid, "first secret")

    assert {:ok, "first secret", remote_sessions} =
             SessionStore.decrypt_message(
               SessionStore.new(),
               "15550002222:1@s.whatsapp.net",
               encrypted,
               true,
               remote.identity,
               remote.local_prekeys
             )

    assert {:ok, reply, :whisper, remote_sessions} =
             SessionStore.encrypt_message(
               remote_sessions,
               "15550002222:1@s.whatsapp.net",
               "reply",
               remote.identity,
               8193,
               %{}
             )

    assert {:ok, "reply"} = Encryption.decrypt_from_sender(ctx.session, @jid, reply, :msg)

    assert {:ok, encrypted2, :whisper} =
             Encryption.encrypt_for_recipient(ctx.session, @jid, "second secret")

    assert {:ok, "second secret", _} =
             SessionStore.decrypt_message(
               remote_sessions,
               "15550002222:1@s.whatsapp.net",
               encrypted2,
               false,
               remote.identity,
               remote.local_prekeys
             )

    assert {:error, _} = Encryption.decrypt_from_sender(ctx.session, @jid, <<0, 1, 2>>, :msg)
    assert SessionStore.has_session?(Store.load_signal_sessions(ctx.store), @jid)
  end

  test "outbound text traverses discovery, Signal encryption and server acknowledgement", ctx do
    alias ExWapp.Signal.{Encryption, SessionStore}
    remote = ExWapp.Test.SignalDevice.new()
    :ok = Transport.set_reply(ctx.conn, &ExWapp.Test.SignalDevice.reply(remote, &1))

    logs =
      capture_log(fn ->
        send(
          self(),
          {:outbound_result, ExWapp.send_message(ctx.session, @jid, "Ciao dal client")}
        )
      end)

    assert_receive {:outbound_result, {:ok, message_id}}
    refute logs =~ "Ciao dal client"
    refute logs =~ Base.encode64(Store.load!(ctx.store).signal.identity_key.private)
    assert logs =~ "[SEND]"

    assert_receive {:peer_node, _,
                    %Node{tag: "message", attrs: %{"id" => ^message_id}, content: content}},
                   2000

    participants = Enum.find(content, &(&1.tag == "participants"))
    target = Enum.find(participants.content, &(to_string(&1.attrs["jid"]) == @jid))

    [
      %Node{
        tag: "enc",
        attrs: %{"type" => "pkmsg"},
        content: %ExWapp.Binary.Raw{data: ciphertext}
      }
    ] = target.content

    assert {:ok, padded, _} =
             SessionStore.decrypt_message(
               SessionStore.new(),
               "15550002222:1@s.whatsapp.net",
               ciphertext,
               true,
               remote.identity,
               remote.local_prekeys
             )

    assert %{conversation: "Ciao dal client"} =
             WAWebProtobufsE2E.Message.decode!(Encryption.unpad_message(padded))

    assert Store.find_message(ctx.store, @jid, message_id).text == "Ciao dal client"

    :ok =
      Transport.inject(ctx.conn, %Node{
        tag: "ack",
        attrs: %{"id" => message_id, "class" => "message", "from" => @jid}
      })

    await(fn -> Store.find_message(ctx.store, @jid, message_id).status == :sent end)
    assert :ok = ExWapp.send_read_receipt(ctx.session, @jid, [message_id])

    assert_receive {:peer_node, _,
                    %Node{tag: "receipt", attrs: %{"id" => ^message_id, "type" => "read"}}},
                   1000
  end

  for {code, reason, invalid?} <- [
        {"401", :unauthorized, true},
        {"403", :forbidden, true},
        {"405", :client_outdated, false},
        {"499", {:failure, "499"}, false}
      ] do
    test "server failure #{code} reaches QR subscribers and updates session validity", ctx do
      {:ok, ref} = Session.subscribe_qr(ctx.session)
      assert :ok = ExWapp.subscribe(ctx.id)

      :ok =
        Transport.inject(ctx.conn, %Node{
          tag: "failure",
          attrs: %{"reason" => unquote(code), "location" => "test"}
        })

      reason = unquote(Macro.escape(reason))
      assert_receive {:ex_wapp_qr, ^ref, {:error, ^reason}}, 1000
      assert_receive {:ex_wapp_session, :error, {:connection_failure, _, "test"}}, 1000
      assert :sys.get_state(ctx.session).session_invalid == unquote(invalid?)
      if unquote(invalid?), do: assert(Session.state(ctx.session) == :idle)
      :ok = Session.unsubscribe_qr(ctx.session, ref)
      assert_receive {:ex_wapp_qr_closed, ^ref}
      :ok = ExWapp.unsubscribe(ctx.id)
    end
  end

  for code <- ["401", "503", "515", "599"] do
    test "stream error #{code} closes the connection and reports its reason", ctx do
      :ok = ExWapp.subscribe(ctx.session)

      :ok =
        Transport.inject(ctx.conn, %Node{
          tag: "stream:error",
          attrs: %{"code" => unquote(code)},
          content: [%Node{tag: "ack", attrs: %{"class" => "message", "type" => "text"}}]
        })

      code = unquote(code)

      if code in ["503", "515"] do
        assert_receive {:ex_wapp_session, :reconnecting,
                        {:stream_error, ^code, {:missing_stanza_ack, "message", "text"}}},
                       1000
      else
        assert_receive {:ex_wapp_session, :error, {:stream_error, ^code, _}}, 1000
      end

      await(fn -> not :sys.get_state(ctx.session).transport_ready? end)
      assert :sys.get_state(ctx.session).conn == nil
      assert :sys.get_state(ctx.session).session_invalid == (code == "401")
    end
  end

  test "stream replacement respects disabled reconnect and XML stream end releases the transport",
       ctx do
    :ok =
      Transport.inject(ctx.conn, %Node{
        tag: "stream:error",
        attrs: %{"code" => "409"},
        content: [%Node{tag: "conflict", attrs: %{"type" => "replaced"}}]
      })

    await(fn -> :sys.get_state(ctx.session).conn == nil end)
    assert Session.state(ctx.session) == :idle
    :ok = Session.connect(ctx.session)
    assert_receive {:peer_authenticated, replacement, _}, 2000
    await(fn -> Session.state(ctx.session) == :connected end)
    :ok = Transport.inject(replacement, %Node{tag: "xmlstreamend"})
    await(fn -> :sys.get_state(ctx.session).conn == nil end)
    assert :sys.get_state(ctx.session).pending_iqs == %{}
  end

  test "QR stream emits a server reference tied to the actual client keys and unsubscribes",
       ctx do
    task = Task.async(fn -> ExWapp.qr_stream(ctx.session) |> Enum.take(1) end)
    await(fn -> map_size(:sys.get_state(ctx.session).qr_subscribers) == 1 end)

    :ok =
      Transport.inject(ctx.conn, %Node{
        tag: "iq",
        attrs: %{"id" => "qr", "type" => "set", "from" => "s.whatsapp.net"},
        content: [
          %Node{
            tag: "pair-device",
            content: [%Node{tag: "ref", content: ExWapp.Binary.raw("fresh-reference")}]
          }
        ]
      })

    assert [{:code, code}] = Task.await(task)
    ["2@fresh-reference", noise, identity, secret] = String.split(code, ",")
    data = Store.load!(ctx.store)
    assert Base.decode64!(noise) == data.noise.static_public
    assert Base.decode64!(identity) == data.signal.identity_key.public
    assert Base.decode64!(secret) == data.adv_secret
    await(fn -> :sys.get_state(ctx.session).qr_subscribers == %{} end)

    assert_receive {:peer_node, _, %Node{tag: "iq", attrs: %{"id" => "qr", "type" => "result"}}},
                   1000
  end

  test "closing stream subscriptions terminates enumeration and removes monitors", ctx do
    for {factory, field, unsubscribe} <- [
          {&ExWapp.qr_stream/1, :qr_subscribers, &Session.unsubscribe_qr/2},
          {&ExWapp.message_stream/1, :message_subscribers,
           &ExWapp.Session.Worker.unsubscribe_messages/2}
        ] do
      task = Task.async(fn -> factory.(ctx.session) |> Enum.to_list() end)
      await(fn -> map_size(Map.fetch!(:sys.get_state(ctx.session), field)) == 1 end)
      [{ref, _}] = Map.to_list(Map.fetch!(:sys.get_state(ctx.session), field))
      assert :ok = unsubscribe.(ctx.session, ref)
      assert [] = Task.await(task)
      assert %{} == Map.fetch!(:sys.get_state(ctx.session), field)
    end
  end

  test "media download worker authenticates bytes and releases its task registration", ctx do
    alias ExWapp.Test.LocalHTTP
    plaintext = <<0, 255, "private image">>
    {:ok, upload, encrypted} = Media.Crypto.encrypt_upload(plaintext, :image)
    server = start_supervised!({LocalHTTP, %{owner: self(), response: {200, encrypted}}})

    ref = %{
      Media.ref_from_upload(upload)
      | url: LocalHTTP.url(server) <> "/media",
        mimetype: "image/png",
        metadata: %{caption: "caption"}
    }

    assert {:ok,
            %Media.Download{
              bytes: ^plaintext,
              mimetype: "image/png",
              metadata: %{caption: "caption"}
            }} = ExWapp.download_media(ctx.session, ref)

    assert ExWapp.Session.SendCoordinator.operation_count(
             :sys.get_state(ctx.session).send_coordinator
           ) == 0

    assert :ok = Session.disconnect(ctx.session)
    assert {:error, {:not_connected, :idle}} = ExWapp.download_media(ctx.session, ref)
    assert {:error, {:not_connected, :idle}} = ExWapp.retry_media(ctx.session, "image")
  end

  test "incoming encrypted message is projected to a subscribed message stream", ctx do
    alias ExWapp.Signal.{Encryption, SessionStore}
    remote = ExWapp.Test.SignalDevice.new()
    signal = Store.get(ctx.store, :signal)
    signed = signal.signed_prekeys[257]
    prekey = signal.prekeys[65537]

    bundle = %{
      registration_id: signal.registration_id,
      identity_key: signal.identity_key.public,
      signed_prekey: Map.take(signed, [:id, :public, :signature]),
      prekey: Map.take(prekey, [:id, :public])
    }

    raw =
      %WAWebProtobufsE2E.Message{conversation: "authenticated inbound"}
      |> ExWapp.Test.ProtocolPeer.encode()
      |> Encryption.pad_message()

    {:ok, ciphertext, :prekey, _} =
      SessionStore.encrypt_message(
        SessionStore.new(),
        "15550002222:1@s.whatsapp.net",
        raw,
        remote.identity,
        8193,
        bundle
      )

    task = Task.async(fn -> ExWapp.message_stream(ctx.session) |> Enum.take(1) end)
    await(fn -> map_size(:sys.get_state(ctx.session).message_subscribers) == 1 end)

    :ok =
      Transport.inject(ctx.conn, %Node{
        tag: "message",
        attrs: %{"id" => "incoming", "from" => @jid, "type" => "text", "t" => "1700000000"},
        content: [
          %Node{
            tag: "enc",
            attrs: %{"type" => "pkmsg", "v" => "2"},
            content: ExWapp.Binary.raw(ciphertext)
          }
        ]
      })

    assert [{@jid, %{id: "incoming", text: "authenticated inbound"}}] = Task.await(task, 3000)
    assert Store.find_message(ctx.store, @jid, "incoming").text == "authenticated inbound"
    refute Map.has_key?(Store.get(ctx.store, :signal).prekeys, 65537)
    await(fn -> :sys.get_state(ctx.session).message_subscribers == %{} end)

    assert_receive {:peer_node, _,
                    %Node{tag: "ack", attrs: %{"id" => "incoming", "class" => "message"}}},
                   1000
  end

  test "identity change fetches a signed bundle and installs a new usable peer session", ctx do
    alias ExWapp.Signal.SessionStore
    old = ExWapp.Test.SignalDevice.new()
    local = Store.get(ctx.store, :signal)

    assert {:ok, _, _, _} =
             SessionStore.get_or_create_session(
               :sys.get_state(ctx.session).signal_sessions,
               @jid,
               local.identity_key,
               old.bundle,
               local.registration_id
             )

    remote = ExWapp.Test.SignalDevice.new()
    :ok = Transport.set_reply(ctx.conn, &ExWapp.Test.SignalDevice.reply(remote, &1))

    :ok =
      Transport.inject(ctx.conn, %Node{
        tag: "notification",
        attrs: %{"id" => "identity", "type" => "encrypt", "from" => @jid},
        content: [%Node{tag: "identity"}]
      })

    await(fn ->
      case SessionStore.get_session(:sys.get_state(ctx.session).signal_sessions, @jid) do
        {:ok, session} -> session.remote_identity_key == remote.identity.public
        _ -> false
      end
    end)

    assert {:ok, installed} =
             SessionStore.get_session(:sys.get_state(ctx.session).signal_sessions, @jid)

    assert installed.remote_identity_key == remote.identity.public

    assert {:ok, ciphertext, :prekey} =
             ExWapp.Signal.Encryption.encrypt_for_recipient(
               ctx.session,
               @jid,
               "after identity change"
             )

    assert {:ok, "after identity change", _} =
             SessionStore.decrypt_message(
               SessionStore.new(),
               "15550002222:1@s.whatsapp.net",
               ciphertext,
               true,
               remote.identity,
               remote.local_prekeys
             )

    assert_receive {:peer_node, _, %Node{tag: "ack", attrs: %{"id" => "identity"}}}, 1000
  end

  test "inventory notifications persist private prekeys before upload and mark them only after ACK",
       ctx do
    :ok =
      Transport.inject(ctx.conn, %Node{
        tag: "notification",
        attrs: %{"id" => "inventory", "type" => "encrypt", "from" => "s.whatsapp.net"},
        content: [%Node{tag: "count", attrs: %{"value" => "0"}}]
      })

    assert_receive {:peer_node, _,
                    %Node{tag: "iq", attrs: %{"xmlns" => "encrypt", "type" => "set", "id" => id}}},
                   2000

    pending = :sys.get_state(ctx.session).pending_prekey_upload
    assert length(pending) == 8
    stored = Store.get(ctx.store, :signal).prekeys

    for key <- pending do
      assert byte_size(stored[key.key_id].private) == 32
      refute stored[key.key_id].uploaded
    end

    send(ctx.session, {:refill_prekeys, 0})
    assert :sys.get_state(ctx.session).prekey_upload_iq_id == id
    :ok = Transport.inject(ctx.conn, %Node{tag: "iq", attrs: %{"id" => id, "type" => "result"}})
    await(fn -> :sys.get_state(ctx.session).prekey_upload_iq_id == nil end)
    for key <- pending, do: assert(Store.get(ctx.store, :signal).prekeys[key.key_id].uploaded)
    assert Session.state(ctx.session) == :connected
  end

  test "contact sync and notifications run with real collection IQ responses", ctx do
    key = :crypto.strong_rand_bytes(32)
    :ok = Store.put(ctx.store, :app_state_keys, %{"01" => %{data: key, timestamp: 1}})
    assert :ok = ExWapp.sync_contacts(ctx.session)
    assert_receive {:peer_node, _, %Node{attrs: %{"xmlns" => "w:sync:app:state"}}}, 1000
    send(ctx.session, {:app_state_sync_collections, ["regular_low"]})
    assert_receive {:peer_node, _, %Node{attrs: %{"xmlns" => "w:sync:app:state"}}}, 1000
    send(ctx.session, {:app_state_initial_sync, ["regular_low"]})
    assert Session.state(ctx.session) == :connected

    assert {:ok, %{version: 0}, %{}} =
             ExWapp.AppState.Engine.get_collection_state(ctx.store, "regular_low")
  end

  test "a crashed in-flight send worker replies to its caller and removes IQ routes", ctx do
    :ok = Transport.set_reply(ctx.conn, fn _ -> nil end)
    key = :crypto.strong_rand_bytes(32)
    :ok = Store.put(ctx.store, :app_state_keys, %{"01" => %{data: key, timestamp: 1}})
    task = Task.async(fn -> ExWapp.sync_contacts(ctx.session) end)
    assert_receive {:peer_node, _, %Node{attrs: %{"xmlns" => "w:sync:app:state"}}}, 1000
    [worker] = Task.Supervisor.children(:sys.get_state(ctx.session).send_worker_sup)
    Process.exit(worker, :kill)
    assert {:error, {:send_worker_exited, :killed}} = Task.await(task)

    assert ExWapp.Session.SendCoordinator.operation_count(
             :sys.get_state(ctx.session).send_coordinator
           ) == 0

    assert Session.state(ctx.session) == :connected
  end

  @tag initial_sync: true
  test "a killed initial-sync task releases the send gate and reports failure", ctx do
    :ok = ExWapp.subscribe(ctx.id)
    await(fn -> is_pid(:sys.get_state(ctx.session).initial_sync.task) end)
    task = :sys.get_state(ctx.session).initial_sync.task
    send(ctx.session, {:app_state_initial_sync, ["regular_low"]})
    assert :sys.get_state(ctx.session).initial_sync.task == task

    assert {:error, {:not_connected, :syncing}} =
             ExWapp.send_message(ctx.session, @jid, "waiting")

    Process.exit(task, :kill)
    await(fn -> Session.state(ctx.session) == :connected end)
    assert :sys.get_state(ctx.session).initial_sync.task == nil

    assert_receive {:ex_wapp_session, :initial_sync, :failed,
                    {:task_exited_without_result, :killed}, _},
                   1000

    send(ctx.session, {:initial_sync_finished, task, :completed})
    assert Session.state(ctx.session) == :connected
  end

  @tag initial_sync: true
  test "disconnect cancels initial synchronization and late completion cannot reopen the session",
       ctx do
    await(fn -> is_pid(:sys.get_state(ctx.session).initial_sync.task) end)
    task = :sys.get_state(ctx.session).initial_sync.task
    assert :ok = ExWapp.disconnect(ctx.session)
    assert Session.state(ctx.session) == :idle
    refute Process.alive?(task)
    send(ctx.session, {:initial_sync_finished, task, :completed})
    send(ctx.session, {:app_state_sync_collections, ["regular_low"]})
    send(ctx.session, {:app_state_initial_sync, ["regular_low"]})
    assert Session.state(ctx.session) == :idle
    assert :sys.get_state(ctx.session).pending_iqs == %{}
  end

  @tag runtime: [app_state: [initial_sync_enabled: true]]
  test "new app-state keys release deferred sync and complete every collection", ctx do
    send(ctx.session, {:app_state_initial_sync, ["regular_low"]})
    assert :sys.get_state(ctx.session).initial_sync.task == nil

    :ok =
      Store.put(ctx.store, :app_state_keys, %{
        "01" => %{data: :crypto.strong_rand_bytes(32), timestamp: 1}
      })

    :ok = ExWapp.subscribe(ctx.id)
    send(ctx.session, {:app_state_initial_sync, ["regular_low", "regular_high"]})
    assert_receive {:ex_wapp_session, :initial_sync, :completed, %{success_count: 2}}, 2000
    await(fn -> Session.state(ctx.session) == :connected end)
    assert :sys.get_state(ctx.session).initial_sync.task == nil
  end

  @tag runtime: [throttle: [enabled: false]]
  test "location, contact and event public APIs produce recipient-decryptable protobufs", ctx do
    remote = ExWapp.Test.SignalDevice.new()
    :ok = Transport.set_reply(ctx.conn, &ExWapp.Test.SignalDevice.reply(remote, &1))

    sends = [
      {fn -> ExWapp.send_location(ctx.session, @jid, 45.0, 9.0) end, :locationMessage,
       :degreesLatitude, 45.0},
      {fn ->
         ExWapp.send_contact(ctx.session, @jid, "Alice", "BEGIN:VCARD\nFN:Alice\nEND:VCARD")
       end, :contactMessage, :displayName, "Alice"},
      {fn -> ExWapp.send_event(ctx.session, @jid, "Meeting", 1_800_000_000) end, :eventMessage,
       :name, "Meeting"}
    ]

    Enum.reduce(sends, ExWapp.Signal.SessionStore.new(), fn {send_message, field, attribute,
                                                             expected},
                                                            receiver ->
      assert {:ok, id} = send_message.()
      assert_receive {:peer_node, _, %Node{tag: "message", attrs: %{"id" => ^id}} = node}, 1000
      {proto, receiver} = decrypt_received(node, remote, receiver)
      assert Map.fetch!(Map.fetch!(proto, field), attribute) == expected

      assert Store.find_message(ctx.store, @jid, id).raw.content_type in [
               :location,
               :contact,
               :event
             ]

      receiver
    end)
  end

  for type <- [:image, :audio, :document] do
    @media_type type
    test "#{type} public API preserves authenticated upload metadata through encryption", ctx do
      remote = ExWapp.Test.SignalDevice.new()
      :ok = Transport.set_reply(ctx.conn, &ExWapp.Test.SignalDevice.reply(remote, &1))
      assert {:ok, upload, _encrypted} = Media.Crypto.encrypt_upload("media body", @media_type)
      upload = %{upload | url: "https://media.example.test/file", direct_path: "/file"}

      assert {:ok, id} =
               apply(ExWapp, String.to_existing_atom("send_#{@media_type}"), [
                 ctx.session,
                 @jid,
                 upload
               ])

      assert_receive {:peer_node, _, %Node{tag: "message", attrs: %{"id" => ^id}} = node}, 1000
      {proto, _} = decrypt_received(node, remote, ExWapp.Signal.SessionStore.new())

      media =
        Map.fetch!(
          proto,
          %{image: :imageMessage, audio: :audioMessage, document: :documentMessage}[@media_type]
        )

      assert media.mediaKey == upload.media_key
      assert media.fileSHA256 == :crypto.hash(:sha256, "media body")
      assert media.fileLength == 10
      assert Store.find_message(ctx.store, @jid, id).raw.media.media_key == upload.media_key
    end
  end

  test "invalid public content fails before discovery and does not store a pending message",
       ctx do
    assert {:error, :invalid_location} = ExWapp.send_location(ctx.session, @jid, 91, 0)
    assert {:error, :invalid_contact} = ExWapp.send_contact(ctx.session, @jid, "", "")
    assert {:error, :invalid_event} = ExWapp.send_event(ctx.session, @jid, "", 1)

    assert {:error, {:unsupported_media_source, :invalid}} =
             ExWapp.send_audio(ctx.session, @jid, :invalid)

    assert {:error, :enoent} =
             ExWapp.send_document(ctx.session, @jid, {:path, "/nonexistent-ex-wapp-file"})

    assert Store.list_messages(ctx.store, @jid) == []
  end

  @tag runtime: [quota: [enabled: true, per_session: [daily_messages: 1]]]
  test "daily quota blocks the second send before encryption and emits its scope", ctx do
    remote = ExWapp.Test.SignalDevice.new()
    :ok = Transport.set_reply(ctx.conn, &ExWapp.Test.SignalDevice.reply(remote, &1))
    assert {:ok, _} = ExWapp.send_message(ctx.session, @jid, "allowed")

    assert {:error, {:quota_exceeded, {:session, 1}}} =
             ExWapp.send_message(ctx.session, @jid, "blocked")

    assert length(Store.list_messages(ctx.store, @jid)) == 1
  end

  for action <- [:pause, :disconnect, :none] do
    @tag runtime: [send_error_guard: [enabled: true, max_consecutive_errors: 1, action: action]]
    @guard_action action
    test "real discovery failure activates configured #{@guard_action} guard", ctx do
      :ok =
        Transport.set_reply(ctx.conn, fn
          %Node{attrs: %{"xmlns" => "encrypt", "id" => id}} ->
            %Node{
              tag: "iq",
              attrs: %{"id" => id, "type" => "error"},
              content: [%Node{tag: "error", attrs: %{"code" => "503"}}]
            }

          _ ->
            :default
        end)

      assert {:error, _} = ExWapp.send_message(ctx.session, @jid, "cannot encrypt")
      await(fn -> ExWapp.health_status(ctx.session).guard_trips > 0 end)
      assert ExWapp.health_status(ctx.session).last_guard_action == @guard_action
      if @guard_action == :disconnect, do: assert(Session.state(ctx.session) == :idle)
      if @guard_action == :pause, do: assert(ExWapp.health_status(ctx.session).paused == true)
      assert Store.list_messages(ctx.store, @jid) == []
    end
  end

  @tag runtime: [throttle: [enabled: false]]
  test "complete group send distributes the key and the recipient decrypts the signed group body",
       ctx do
    remote = ExWapp.Test.SignalDevice.new()
    :ok = Transport.set_reply(ctx.conn, &group_reply(remote, &1))
    group = "123@g.us"
    receiver_store = Store.Memory.new()

    Enum.reduce(
      ["first group body", "second group body"],
      ExWapp.Signal.SessionStore.new(),
      fn text, receiver ->
        assert {:ok, id} = ExWapp.send_message(ctx.session, group, text)

        assert_receive {:peer_node, _,
                        %Node{tag: "message", attrs: %{"id" => ^id}, content: content} = node},
                       1000

        {distribution, receiver} = decrypt_received(node, remote, receiver)

        assert {:ok, 1} =
                 ExWapp.Signal.SenderKey.process_distributions_from_plaintext(
                   receiver_store,
                   group,
                   "15550002222@s.whatsapp.net",
                   ExWapp.Test.ProtocolPeer.encode(distribution)
                 )

        encrypted = Enum.find(content, &(&1.tag == "enc"))
        assert encrypted.attrs["type"] == "skmsg"

        assert {:ok, padded} =
                 ExWapp.Signal.SenderKey.decrypt_group_message(
                   receiver_store,
                   group,
                   "15550002222@s.whatsapp.net",
                   encrypted.content.data
                 )

        assert %{conversation: ^text} =
                 WAWebProtobufsE2E.Message.decode!(ExWapp.Signal.Encryption.unpad_message(padded))

        assert Store.find_message(ctx.store, group, id).text == text
        receiver
      end
    )
  end

  for destination <- [@jid, "123@g.us"] do
    @destination destination
    test "failed socket write marks the #{@destination} message failed", ctx do
      remote = ExWapp.Test.SignalDevice.new()
      :ok = Transport.set_reply(ctx.conn, &group_reply(remote, &1))
      :ok = Transport.fail_send(ctx.conn, "message", :closed)
      assert {:error, :closed} = ExWapp.send_message(ctx.session, @destination, "undelivered")

      assert [%{status: :failed, text: "undelivered"}] =
               Store.list_messages(ctx.store, @destination)

      refute_receive {:peer_node, _, %Node{tag: "message"}}
    end
  end

  for destination <- [@jid, "123@g.us"] do
    @destination destination
    test "unavailable linked device aborts #{@destination} after one fanout repair", ctx do
      remote = ExWapp.Test.SignalDevice.new()

      :ok =
        Transport.set_reply(ctx.conn, fn
          %Node{attrs: %{"xmlns" => "usync", "id" => id}, content: [usync]} ->
            users = Enum.find(usync.content, &(&1.tag == "list")).content

            %Node{
              tag: "iq",
              attrs: %{"id" => id, "type" => "result"},
              content: [
                %Node{
                  tag: "usync",
                  content: [
                    %Node{
                      tag: "list",
                      content:
                        Enum.map(users, fn user ->
                          ids = if to_string(user.attrs["jid"]) == @jid, do: [0, 2], else: [0]

                          %Node{
                            tag: "user",
                            attrs: user.attrs,
                            content: [
                              %Node{
                                tag: "devices",
                                content: [
                                  %Node{
                                    tag: "device-list",
                                    content:
                                      Enum.map(
                                        ids,
                                        &%Node{tag: "device", attrs: %{"id" => to_string(&1)}}
                                      )
                                  }
                                ]
                              }
                            ]
                          }
                        end)
                    }
                  ]
                }
              ]
            }

          %Node{attrs: %{"xmlns" => "encrypt", "id" => id}, content: [key]} ->
            users =
              Enum.reject(
                key.content,
                &(to_string(&1.attrs["jid"]) == "15550001111:2@s.whatsapp.net")
              )

            %Node{
              tag: "iq",
              attrs: %{"id" => id, "type" => "result"},
              content: [
                %Node{
                  tag: "list",
                  content:
                    Enum.map(users, &ExWapp.Test.SignalDevice.user(remote, &1.attrs["jid"]))
                }
              ]
            }

          node ->
            group_reply(remote, node)
        end)

      assert {:error, {reason, missing}} =
               ExWapp.send_message(ctx.session, @destination, "all devices required")

      assert reason in [:fanout_incomplete, :group_distribution_incomplete]
      assert Enum.any?(missing, &(&1.jid == "15550001111:2@s.whatsapp.net"))
      refute_receive {:peer_node, _, %Node{tag: "message"}}
      assert Store.list_messages(ctx.store, @destination) == []
    end
  end

  @tag fault_store: true
  @tag runtime: [throttle: [enabled: false]]
  test "batch adapter failures do not report an already transmitted message as unsent", ctx do
    remote = ExWapp.Test.SignalDevice.new()
    :ok = Transport.set_reply(ctx.conn, &ExWapp.Test.SignalDevice.reply(remote, &1))

    for callback <- [:begin_batch, :finish_batch] do
      ExWapp.Test.FaultStore.arm(ctx.store, callback, {:return, {:error, :disk_full}})
      assert {:ok, id} = ExWapp.send_message(ctx.session, @jid, "accepted on wire")
      assert_receive {:peer_node, _, %Node{tag: "message", attrs: %{"id" => ^id}}}, 1000
      assert Store.find_message(ctx.store, @jid, id).status == :pending
    end
  end

  @tag unpaired: true
  test "phone-number pairing persists credentials before sending its authenticated finish", ctx do
    alias ExWapp.Pairing.LinkCode
    alias ExWapp.Signal.Keys
    assert {:ok, subscription} = Session.subscribe_qr(ctx.session)
    assert {:error, :invalid_phone_number} = Session.request_pairing_code(ctx.session, "invalid")

    assert {:ok, "ABCD2345"} =
             Session.request_pairing_code(ctx.session, "15550002222", custom_code: "ABCD2345")

    assert_receive {:peer_node, _,
                    %Node{
                      tag: "iq",
                      content: [
                        %Node{
                          tag: "link_code_companion_reg",
                          attrs: %{"stage" => "companion_hello"}
                        }
                      ]
                    }},
                   1000

    primary = Keys.generate_key_pair()
    ephemeral = Keys.generate_key_pair()
    salt = :crypto.strong_rand_bytes(32)
    iv = :crypto.strong_rand_bytes(16)

    wrapped =
      salt <>
        iv <>
        :crypto.crypto_one_time(
          :aes_256_ctr,
          LinkCode.derive_pairing_code_key("ABCD2345", salt),
          iv,
          ephemeral.public,
          true
        )

    node = %Node{
      tag: "notification",
      attrs: %{"id" => "link", "from" => "s.whatsapp.net", "type" => "link_code_companion_reg"},
      content: [
        %Node{
          tag: "link_code_companion_reg",
          content: [
            %Node{tag: "link_code_pairing_ref", content: "reference"},
            %Node{tag: "primary_identity_pub", content: %ExWapp.Binary.Raw{data: primary.public}},
            %Node{
              tag: "link_code_pairing_wrapped_primary_ephemeral_pub",
              content: %ExWapp.Binary.Raw{data: wrapped}
            }
          ]
        }
      ]
    }

    :ok = Transport.inject(ctx.conn, node)

    assert_receive {:peer_node, _,
                    %Node{
                      tag: "iq",
                      content: [
                        %Node{
                          tag: "link_code_companion_reg",
                          attrs: %{"stage" => "companion_finish"}
                        }
                      ]
                    }},
                   1000

    assert byte_size(Store.get(ctx.store, :adv_secret)) == 32
    assert Store.get(ctx.store, :client_info).jid == "15550002222@s.whatsapp.net"
    assert :ok = Session.unsubscribe_qr(ctx.session, subscription)
  end

  @tag runtime: [send: [confirm_timeout_ms: 30, max_silent_drop_fallback_attempts: 0]]
  test "unacknowledged sends expire their confirmations and increment drop counters", ctx do
    remote = ExWapp.Test.SignalDevice.new()
    :ok = Transport.set_reply(ctx.conn, &ExWapp.Test.SignalDevice.reply(remote, &1))

    assert {:ok, id} =
             ExWapp.send_message(ctx.session, "15550002222@s.whatsapp.net", "not acknowledged")

    await(fn -> ExWapp.health_status(ctx.session).drops_total == 1 end)
    assert :sys.get_state(ctx.session).outbound_confirmations == %{}
    assert Store.find_message(ctx.store, "15550002222@s.whatsapp.net", id).status == :failed
    send(ctx.session, {:outbound_confirm_timeout, id})
    assert ExWapp.health_status(ctx.session).drops_total == 1
  end

  @tag runtime: [send_error_guard: [enabled: true, max_errors_per_minute: 1, notify_only: true]]
  test "a queued transport failure updates health while notification-only guard keeps the session usable",
       ctx do
    :ok = Transport.fail_send(ctx.conn, "receipt", :closed)

    assert :ok =
             ExWapp.Session.OutboundQueue.enqueue_node(
               :sys.get_state(ctx.session).outbound_queue,
               %Node{tag: "receipt", attrs: %{"id" => "receipt"}}
             )

    await(fn -> ExWapp.health_status(ctx.session).outbound_queue_errors_total == 1 end)
    assert ExWapp.stats(ctx.session).errors >= 1
    :ok = Transport.fail_send(ctx.conn, "iq", :closed)
    assert {:error, _} = ExWapp.send_message(ctx.session, @jid, "failed discovery")
    await(fn -> ExWapp.health_status(ctx.session).guard_trips == 1 end)
    assert Session.state(ctx.session) == :connected
    refute ExWapp.health_status(ctx.session).hard_stopped
    assert :ok = Session.send_typing(ctx.session, @jid)
  end

  test "PubSub sends route through encryption and disconnect control cancels pending operations",
       ctx do
    remote = ExWapp.Test.SignalDevice.new()
    :ok = Transport.set_reply(ctx.conn, &ExWapp.Test.SignalDevice.reply(remote, &1))
    assert :ok = ExWapp.send_message(ctx.id, @jid, "PubSub delivery")
    assert_receive {:peer_node, _, %Node{tag: "message"} = node}, 1000
    {proto, _} = decrypt_received(node, remote, ExWapp.Signal.SessionStore.new())
    assert proto.conversation == "PubSub delivery"
    assert :ok = ExWapp.control_session(ctx.id, :disconnect)
    await(fn -> Session.state(ctx.session) == :idle end)
    assert :sys.get_state(ctx.session).send_coordinator.operations == %{}
  end

  for route <- [:pid, :pubsub] do
    @route route
    test "stop control via #{@route} terminates the session and all owned workers", ctx do
      monitor = Process.monitor(ctx.session)

      workers =
        for key <- [:outbound_queue, :inbound_router, :send_worker_sup],
            do: Map.fetch!(:sys.get_state(ctx.session), key)

      target = if @route == :pid, do: ctx.session, else: ctx.id
      assert :ok = ExWapp.control_session(target, :stop_session)
      assert_receive {:DOWN, ^monitor, :process, _, _}, 2000
      refute Process.alive?(ctx.conn)
      for pid <- workers, do: refute(Process.alive?(pid))
    end
  end

  test "in-flight discovery callers are released when the connection closes", ctx do
    :ok = Transport.set_reply(ctx.conn, fn _ -> nil end)
    task = Task.async(fn -> ExWapp.send_message(ctx.session, @jid, "pending discovery") end)
    assert_receive {:peer_node, _, %Node{tag: "iq", attrs: %{"xmlns" => "usync"}}}, 1000
    assert :ok = Session.disconnect(ctx.session)
    assert {:error, {:disconnected, _}} = Task.await(task)
    assert :sys.get_state(ctx.session).pending_iqs == %{}
  end

  test "public chat and contact commands persist only acknowledged app-state mutations", ctx do
    Store.put(ctx.store, :app_state_keys, %{
      "01" => %{data: :crypto.strong_rand_bytes(32), timestamp: 1}
    })

    assert %Chat{} = Chat.get_or_create(ctx.store, @jid)

    for {operation, field, expected} <- [
          {:archive_chat, :archived, true},
          {:unarchive_chat, :archived, false},
          {:pin_chat, :pinned, true},
          {:unpin_chat, :pinned, false},
          {:mute_chat, :muted_until, -1},
          {:unmute_chat, :muted_until, nil}
        ] do
      assert :ok = apply(ExWapp, operation, [ctx.session, @jid])
      assert {:ok, chat} = Chat.get(ctx.store, @jid)
      assert Map.fetch!(chat, field) == expected
    end

    assert :ok = ExWapp.mark_chat_as_read(ctx.session, @jid)
    assert {:ok, %Chat{unread_count: 0}} = Chat.get(ctx.store, @jid)
    assert :ok = ExWapp.create_contact(ctx.session, @jid, "Protocol contact")
    assert %Contact{full_name: "Protocol contact"} = Contact.get(ctx.store, @jid)
    assert :ok = ExWapp.delete_contact(ctx.session, @jid)
    assert Contact.get(ctx.store, @jid) == nil
    assert :ok = ExWapp.delete_chat(ctx.session, @jid)
    assert {:error, :not_found} = Chat.get(ctx.store, @jid)
  end

  test "disconnected public chat commands retain their documented local fallback", ctx do
    Session.disconnect(ctx.session)
    assert Session.state(ctx.session) == :idle
    Chat.get_or_create(ctx.store, @jid)

    for {operation, field, expected} <- [
          {:archive_chat, :archived, true},
          {:unarchive_chat, :archived, false},
          {:pin_chat, :pinned, true},
          {:unpin_chat, :pinned, false}
        ] do
      assert :ok = apply(ExWapp, operation, [ctx.session, @jid])
      assert {:ok, chat} = Chat.get(ctx.store, @jid)
      assert Map.fetch!(chat, field) == expected
    end

    assert :ok = ExWapp.mark_chat_as_read(ctx.session, @jid)

    for operation <- [:mute_chat, :unmute_chat, :delete_contact] do
      assert {:error, {:not_connected, :idle}} = apply(ExWapp, operation, [ctx.session, @jid])
    end

    assert :ok = ExWapp.delete_chat(ctx.session, @jid)
    assert {:error, :not_found} = Chat.get(ctx.store, @jid)
  end

  test "worker exhaustion rejects requests promptly without recording a send", ctx do
    supervisor = start_supervised!({Task.Supervisor, max_children: 0})
    original = :sys.get_state(ctx.session).send_worker_sup
    :sys.replace_state(ctx.session, &%{&1 | send_worker_sup: supervisor})

    try do
      assert {:error, {:send_worker_start_failed, :max_children}} =
               ExWapp.send_message(ctx.session, @jid, "no worker capacity")

      assert {:error, {:send_worker_start_failed, :max_children}} =
               ExWapp.pin_chat(ctx.session, @jid)

      assert {:error, {:download_worker_start_failed, :max_children}} =
               ExWapp.download_media(ctx.session, %Media.Ref{type: :image, media_key: <<0::256>>})

      assert :sys.get_state(ctx.session).send_coordinator.operations == %{}
      assert Store.list_messages(ctx.store, @jid) == []
    after
      :sys.replace_state(ctx.session, &%{&1 | send_worker_sup: original})
    end

    assert :ok = Session.send_typing(ctx.session, @jid)
  end

  test "server initialization and ping stanzas preserve readiness and receive a pong", ctx do
    :ok =
      Transport.inject(ctx.conn, %Node{
        tag: "ib",
        content:
          Enum.map(["offline_preview", "offline", "dirty", "future_extension"], &%Node{tag: &1})
      })

    :ok = Transport.inject(ctx.conn, %Node{tag: "stream:features"})

    :ok =
      Transport.inject(ctx.conn, %Node{
        tag: "iq",
        attrs: %{
          "type" => "get",
          "xmlns" => "urn:xmpp:ping",
          "id" => "ping",
          "from" => "s.whatsapp.net"
        }
      })

    assert_receive {:peer_node, _,
                    %Node{
                      tag: "iq",
                      attrs: %{"id" => "ping", "type" => "result", "to" => destination}
                    }},
                   1000

    assert to_string(destination) == "s.whatsapp.net"
    assert Session.state(ctx.session) == :connected
    assert :ok = Session.send_typing(ctx.session, @jid)
  end

  for failure <- [:raise, :throw, :exit, {:return, {:error, :disk_full}}] do
    @tag fault_store: true
    @failure failure
    test "shutdown still stops owned workers when flushing returns #{inspect(failure)}", ctx do
      state = :sys.get_state(ctx.session)
      workers = [state.outbound_queue, state.inbound_router, state.send_worker_sup, ctx.conn]
      ExWapp.Test.FaultStore.arm(ctx.store, :flush, @failure)
      monitor = Process.monitor(ctx.session)
      log = capture_log(fn -> assert :ok = GenServer.stop(ctx.session, :normal) end)
      assert log =~ "Failed flushing store"
      assert_receive {:DOWN, ^monitor, :process, _, :normal}, 1000
      for pid <- workers, do: refute(Process.alive?(pid))
      assert Store.get(ctx.store, :signal).identity_key != nil
    end
  end

  test "successful media reupload refreshes every stored reference and resolves its waiting caller",
       ctx do
    alias ExWapp.Media.Retry
    key = :crypto.strong_rand_bytes(32)

    ref = %Media.Ref{
      type: :image,
      media_key: key,
      url: "https://expired.invalid/image",
      direct_path: "/old"
    }

    message = %{
      id: "reupload",
      media: ref,
      content: %ExWapp.Message.Content{kind: :media, media_type: :image, media: ref},
      raw: %{media: ref}
    }

    Store.upsert_messages(ctx.store, @jid, [message])
    assert :ok = ExWapp.subscribe(ctx.session)
    caller = Task.async(fn -> ExWapp.retry_media(ctx.session, "reupload", timeout: 2000) end)
    assert_receive {:peer_node, _, %Node{tag: "receipt", attrs: %{"id" => "reupload"}}}, 1000
    iv = :crypto.strong_rand_bytes(12)
    payload = Retry.encode_notification("reupload", "/new/path", :success)
    encrypted = Retry.encrypt_notification(payload, key, iv, "reupload")

    node = %Node{
      tag: "notification",
      attrs: %{"id" => "reupload", "type" => "mediaretry", "from" => "s.whatsapp.net"},
      content: [
        %Node{
          tag: "encrypt",
          content: [
            %Node{tag: "enc_p", content: %ExWapp.Binary.Raw{data: encrypted}},
            %Node{tag: "enc_iv", content: %ExWapp.Binary.Raw{data: iv}}
          ]
        }
      ]
    }

    assert :ok = Transport.inject(ctx.conn, node)
    assert {:ok, refreshed} = Task.await(caller)
    assert refreshed.direct_path == "/new/path"
    assert refreshed.url == nil
    assert_receive {:ex_wapp_session, :media_retry, {:ok, ^refreshed}}, 1000
    stored = Store.find_message(ctx.store, @jid, "reupload")
    assert stored.media == refreshed
    assert stored.content.media == refreshed
    assert stored.raw.media == refreshed
    assert :sys.get_state(ctx.session).pending_media_retries == %{}
    assert :ok = Transport.inject(ctx.conn, node)
    assert Store.find_message(ctx.store, @jid, "reupload") == stored
    assert :ok = ExWapp.unsubscribe(ctx.session)
  end

  @tag fault_store: true
  test "a store failure while processing an authentication stanza does not take down the session",
       ctx do
    for failure <- [:raise, :exit] do
      before = ExWapp.stats(ctx.session).errors
      ExWapp.Test.FaultStore.arm(ctx.store, :transaction, failure)
      assert :ok = Transport.inject(ctx.conn, %Node{tag: "success", attrs: %{"lid" => "999@lid"}})
      await(fn -> ExWapp.stats(ctx.session).errors > before end)
      assert to_string(Store.get(ctx.store, :client_info).jid) == "15550002222:1@s.whatsapp.net"
      refute Map.has_key?(Store.get(ctx.store, :client_info), :lid)
      assert Session.state(ctx.session) == :connected
      assert :ok = Session.send_typing(ctx.session, @jid)
    end
  end

  test "public app-state commands report missing keys without modifying the chat", ctx do
    original = Chat.get_or_create(ctx.store, @jid, name: "Unchanged")

    for operation <- [
          :archive_chat,
          :unarchive_chat,
          :unpin_chat,
          :delete_chat,
          :mute_chat,
          :unmute_chat,
          :mark_chat_as_read
        ] do
      assert {:error, :no_app_state_keys} = apply(ExWapp, operation, [ctx.session, @jid])
      assert {:ok, ^original} = Chat.get(ctx.store, @jid)
    end
  end

  defp group_reply(_remote, %Node{attrs: %{"xmlns" => "w:g2", "id" => id}}) do
    %Node{
      tag: "iq",
      attrs: %{"id" => id, "type" => "result"},
      content: [
        %Node{
          tag: "group",
          attrs: %{"addressing_mode" => "pn"},
          content: [%Node{tag: "participant", attrs: %{"jid" => @jid}}]
        }
      ]
    }
  end

  defp group_reply(remote, node), do: ExWapp.Test.SignalDevice.reply(remote, node)

  defp decrypt_received(%Node{content: content}, remote, receiver) do
    participants = Enum.find(content, &(&1.tag == "participants"))
    target = Enum.find(participants.content, &(to_string(&1.attrs["jid"]) == @jid))
    [enc] = target.content

    assert {:ok, padded, updated} =
             ExWapp.Signal.SessionStore.decrypt_message(
               receiver,
               "15550002222:1@s.whatsapp.net",
               enc.content.data,
               enc.attrs["type"] == "pkmsg",
               remote.identity,
               remote.local_prekeys
             )

    {WAWebProtobufsE2E.Message.decode!(ExWapp.Signal.Encryption.unpad_message(padded)), updated}
  end

  defp await(fun, attempts \\ 200)
  defp await(fun, 0), do: assert(fun.())

  defp await(fun, attempts) do
    if fun.(),
      do: :ok,
      else:
        (
          Process.sleep(5)
          await(fun, attempts - 1)
        )
  end
end
