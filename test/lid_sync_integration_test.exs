defmodule ExWapp.LIDSyncIntegrationTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Binary, Chat, JID, Session, Store}
  alias ExWapp.AppState.Engine
  alias ExWapp.Binary.Node
  alias ExWapp.Signal.{Encryption, SessionStore}
  alias ExWapp.Test.{ProtocolPeer, SignalDevice}
  alias ExWapp.Test.ProtocolTransport, as: Transport
  alias WAWebProtobufsE2E.{Message, ProtocolMessage}

  @pn "15550009999:7@s.whatsapp.net"
  @lid "90000000099:7@lid"
  @chat "15550001111@s.whatsapp.net"

  setup context do
    local = SignalDevice.new()
    {:ok, pn} = JID.parse(@pn)
    {:ok, lid} = JID.parse(@lid)

    device =
      if context[:identity_source] == :success,
        do: %{"jid" => pn},
        else: %{"jid" => pn, "lid" => lid}

    # Exercise the same persisted JID structs and mixed atom/string keys as a
    # restored pairing, without reading or writing a real account's store.
    assert {:ok, snapshot} =
             Store.Codec.encode(%{
               pairing: %{device: device},
               client_info: %{jid: pn},
               signal:
                 Map.merge(local.local_prekeys, %{
                   identity_key: local.identity,
                   registration_id: local.bundle.registration_id
                 })
             })

    assert {:ok, restored} = Store.Codec.decode(snapshot)
    store = Store.Memory.new(initial_data: restored)
    on_exit(fn -> Store.Memory.stop(store) end)
    Store.put(store, :test_peer, %{owner: self(), auto_success: false})

    id = "lid-sync-#{System.unique_integer([:positive])}"
    :ok = ExWapp.subscribe(id)

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
               runtime: [app_state: [initial_sync_enabled: true]]
             ]
           ]}
      })

    assert_receive {:peer_authenticated, conn, _}, 2_000
    attrs = if context[:identity_source] == :success, do: %{"lid" => lid}, else: %{}
    assert :ok = Transport.inject(conn, %Node{tag: "success", attrs: attrs})

    assert_receive {:ex_wapp_session, :post_auth_ready, %{status: :connected}}, 2_000
    assert {:error, :app_state_keys_unavailable} = ExWapp.sync_contacts(session)
    assert Chat.list(store) == []
    refute_received {:ex_wapp_session, :initial_sync, :started, _}

    # Hold collection replies so the test can verify the sync gate and then
    # release each collection in order, without sleeps or a live connection.
    :ok =
      Transport.set_reply(conn, fn
        %Node{attrs: %{"xmlns" => "w:sync:app:state"}} -> nil
        _ -> :default
      end)

    %{store: store, session: session, conn: conn, local: local, peer: SignalDevice.new()}
  end

  for source <- [:pairing, :success], sender <- ["90000000099@lid", "90000000099:3@lid"] do
    @tag identity_source: source
    @source source
    @sender sender

    test "restored #{source} LID accepts encrypted history and late keys from #{sender}", ctx do
      if @source == :success do
        assert Store.get(ctx.store, :client_info).lid == @lid

        assert Store.get(ctx.store, :lid_mapping)[{:lid_to_pn, "90000000099@lid"}] ==
                 "15550009999@s.whatsapp.net"
      else
        refute Map.has_key?(Store.get(ctx.store, :client_info), :lid)
      end

      sender_sessions = deliver(ctx, history_message(), "bootstrap", @sender, SessionStore.new())
      assert [%{jid: @chat, name: "Recovered chat"}] = Chat.list(ctx.store)
      assert [%{id: "history-message", text: "Recovered text"}] = Chat.messages(ctx.store, @chat)

      key = :crypto.strong_rand_bytes(32)
      deliver(ctx, key_share_message(key), "key-share", @sender, sender_sessions)
      assert %{"010203" => %{data: ^key}} = Store.get(ctx.store, :app_state_keys)
      assert_receive {:ex_wapp_session, :initial_sync, :started, _}, 2_000

      # The first collection cannot finish until the test replies below.
      state = :sys.get_state(ctx.session)
      assert state.status == :syncing
      assert is_pid(state.initial_sync.task)
      monitor = Process.monitor(state.initial_sync.task)

      for name <- Engine.all_collections() do
        assert_receive {:peer_node, _,
                        %Node{
                          tag: "iq",
                          attrs: %{"xmlns" => "w:sync:app:state", "id" => request_id},
                          content: [
                            %Node{
                              tag: "sync",
                              content: [%Node{tag: "collection", attrs: %{"name" => ^name}}]
                            }
                          ]
                        }},
                       2_000

        assert :ok =
                 Transport.inject(ctx.conn, %Node{
                   tag: "iq",
                   attrs: %{"id" => request_id, "type" => "result"},
                   content: [
                     %Node{
                       tag: "sync",
                       content: [%Node{tag: "collection", attrs: %{"name" => name}}]
                     }
                   ]
                 })
      end

      assert_receive {:ex_wapp_session, :initial_sync, :completed, %{success_count: 5}}, 2_000
      assert_receive {:DOWN, ^monitor, :process, _, :normal}, 2_000
      assert Session.state(ctx.session) == :connected
      assert :sys.get_state(ctx.session).initial_sync.task == nil
      refute_received {:ex_wapp_session, :initial_sync, :started, _}
      refute_received {:ex_wapp_session, :post_auth_ready, _}
      refute_received {:ex_wapp_message, _, _}

      # The acquired keys must also survive the next store restore.
      assert {:ok, snapshot} =
               ctx.store |> Store.load!() |> Map.delete(:test_peer) |> Store.Codec.encode()

      assert {:ok, restored} = Store.Codec.decode(snapshot)
      assert %{"010203" => %{data: ^key}} = restored.app_state_keys
    end
  end

  @tag identity_source: :pairing
  test "a decryptable foreign LID cannot populate history or trigger app-state sync", ctx do
    foreign = "90000000001@lid"

    sender_sessions =
      deliver(ctx, history_message(), "foreign-bootstrap", foreign, SessionStore.new())

    deliver(
      ctx,
      key_share_message(:crypto.strong_rand_bytes(32)),
      "foreign-keys",
      foreign,
      sender_sessions
    )

    assert SessionStore.has_session?(:sys.get_state(ctx.session).signal_sessions, foreign)
    assert Chat.list(ctx.store) == []
    assert Store.get(ctx.store, :app_state_keys, %{}) == %{}
    assert Session.state(ctx.session) == :connected
    refute_received {:ex_wapp_session, :initial_sync, :started, _}
    refute_received {:peer_node, _, %Node{attrs: %{"xmlns" => "w:sync:app:state"}}}
    refute_received {:ex_wapp_message, _, _}
  end

  defp deliver(ctx, message, id, sender, sender_sessions) do
    plaintext = message |> ProtocolPeer.encode() |> Encryption.pad_message()

    assert {:ok, ciphertext, :prekey, sender_sessions} =
             SessionStore.encrypt_message(
               sender_sessions,
               @pn,
               plaintext,
               ctx.peer.identity,
               ctx.peer.bundle.registration_id,
               ctx.local.bundle
             )

    assert :ok =
             Transport.inject(ctx.conn, %Node{
               tag: "message",
               attrs: %{"from" => sender, "id" => id, "type" => "text", "category" => "peer"},
               content: [
                 %Node{
                   tag: "enc",
                   attrs: %{"type" => "pkmsg", "v" => "2"},
                   content: Binary.raw(ciphertext)
                 }
               ]
             })

    # Receipts follow decryption and ingestion; stanza ACKs alone are insufficient.
    assert_receive {:peer_node, _, %Node{tag: "receipt", attrs: %{"id" => ^id} = attrs}}, 2_000
    refute attrs["type"] == "retry"
    sender_sessions
  end

  defp key_share_message(key) do
    alias WAWebProtobufsE2E.{
      AppStateSyncKey,
      AppStateSyncKeyData,
      AppStateSyncKeyId,
      AppStateSyncKeyShare
    }

    %Message{
      protocolMessage: %ProtocolMessage{
        type: :APP_STATE_SYNC_KEY_SHARE,
        appStateSyncKeyShare: %AppStateSyncKeyShare{
          keys: [
            %AppStateSyncKey{
              keyID: %AppStateSyncKeyId{keyID: <<1, 2, 3>>},
              keyData: %AppStateSyncKeyData{keyData: key, timestamp: 123}
            }
          ]
        }
      }
    }
  end

  defp history_message do
    alias WAWebProtobufsHistorySync.{Conversation, HistorySync, HistorySyncMsg}

    history = %HistorySync{
      syncType: :INITIAL_BOOTSTRAP,
      conversations: [
        %Conversation{
          ID: @chat,
          displayName: "Recovered chat",
          messages: [
            %HistorySyncMsg{
              message: %WAWebProtobufsWeb.WebMessageInfo{
                key: %WACommon.MessageKey{remoteJID: @chat, fromMe: false, ID: "history-message"},
                messageTimestamp: 1_700_000_000,
                message: %Message{conversation: "Recovered text"}
              }
            }
          ]
        }
      ]
    }

    %Message{
      protocolMessage: %ProtocolMessage{
        type: :HISTORY_SYNC_NOTIFICATION,
        historySyncNotification: %WAWebProtobufsE2E.HistorySyncNotification{
          syncType: :INITIAL_BOOTSTRAP,
          initialHistBootstrapInlinePayload: history |> ProtocolPeer.encode() |> :zlib.compress()
        }
      }
    }
  end
end
