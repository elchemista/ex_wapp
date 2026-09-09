defmodule ExWapp.HistoryKeyIngestionTest do
  use ExUnit.Case, async: true
  alias ExWapp.{Chat, Store}
  alias ExWapp.Message.Handler.Inbound.Sync
  alias ExWapp.Test.ProtocolPeer, as: Proto

  alias WAWebProtobufsE2E.{
    Message,
    ProtocolMessage,
    HistorySyncNotification,
    FutureProofMessage,
    AppStateSyncKey,
    AppStateSyncKeyId,
    AppStateSyncKeyData,
    AppStateSyncKeyShare,
    AppStateSyncKeyFingerprint
  }

  alias WAWebProtobufsHistorySync.{Conversation, HistorySync, HistorySyncMsg}
  alias WAWebProtobufsWeb.WebMessageInfo
  @jid "15550001111@s.whatsapp.net"
  @moduletag capture_log: true

  test "plain history chunks unwrap supported message containers and deduplicate missing IDs" do
    inner = %Message{
      extendedTextMessage: %WAWebProtobufsE2E.ExtendedTextMessage{text: "wrapped text"}
    }

    view_once = %Message{viewOnceMessage: %FutureProofMessage{message: inner}}
    wrapped = %Message{ephemeralMessage: %FutureProofMessage{message: view_once}}

    too_deep =
      Enum.reduce(1..8, %Message{conversation: "too deep"}, fn _, message ->
        %Message{ephemeralMessage: %FutureProofMessage{message: message}}
      end)

    history = %HistorySync{
      syncType: :RECENT,
      conversations: [
        %Conversation{ID: "", messages: []},
        %Conversation{
          ID: @jid,
          name: "History",
          pinned: 0,
          messages: [
            %HistorySyncMsg{
              message: %WebMessageInfo{key: %WACommon.MessageKey{}, message: wrapped}
            },
            %HistorySyncMsg{
              message: %WebMessageInfo{key: %WACommon.MessageKey{}, message: too_deep}
            },
            %HistorySyncMsg{
              message: %WebMessageInfo{
                key: %WACommon.MessageKey{},
                message: %Message{conversation: @jid}
              }
            },
            %HistorySyncMsg{},
            %HistorySyncMsg{message: %WebMessageInfo{key: %WACommon.MessageKey{}}}
          ]
        }
      ]
    }

    payload = history_payload(Proto.encode(history))

    assert {:ok, %{conversations: [conversation]}} =
             ExWapp.Proto.HistorySync.extract_from_message(payload)

    assert [%{text: "wrapped text", id: nil}] = conversation.messages
    refute conversation.pinned
    store = Store.Memory.new()
    state = %{store: store}

    for _ <- 1..2 do
      assert ^state = ingest(payload, state, true)
    end

    assert [%{text: "wrapped text", timestamp: 0, id: id}] = Chat.messages(store, @jid)
    assert String.starts_with?(id, "history-sync-")
  end

  test "malformed history is rejected and cannot mutate existing messages" do
    store = Store.Memory.new()
    :ok = Store.upsert_messages(store, @jid, [%{id: "keep", text: "retained", timestamp: 1}])
    state = %{store: store}

    for bytes <- [
          <<10, 255>>,
          history_payload(<<10, 255>>),
          history_payload(:zlib.compress(<<10, 255>>))
        ] do
      assert {:error, _} = ExWapp.Proto.HistorySync.extract_from_message(bytes)
      assert ^state = ingest(bytes, state, true)
      assert [%{id: "keep", text: "retained"}] = Chat.messages(store, @jid)
    end

    assert :not_history_sync = ExWapp.Proto.HistorySync.extract_from_message(nil)
  end

  test "key shares require our own authenticated sender, retain fingerprints and trigger sync after persistence" do
    id = <<1, 2, 3>>
    key_data = :crypto.strong_rand_bytes(32)
    fingerprint = %AppStateSyncKeyFingerprint{rawID: 9, currentIndex: 3, deviceIndexes: [1, 2]}

    key = %AppStateSyncKey{
      keyID: %AppStateSyncKeyId{keyID: id},
      keyData: %AppStateSyncKeyData{keyData: key_data, timestamp: 123, fingerprint: fingerprint}
    }

    payload =
      Proto.encode(%Message{
        protocolMessage: %ProtocolMessage{
          type: :APP_STATE_SYNC_KEY_SHARE,
          appStateSyncKeyShare: %AppStateSyncKeyShare{keys: [key, %AppStateSyncKey{}]}
        }
      })

    store = Store.Memory.new()
    state = %{store: store}
    assert ^state = ingest(payload, state, false)
    assert Store.get(store, :app_state_keys, %{}) == %{}
    refute_receive {:app_state_initial_sync, _}
    assert ^state = ingest(payload, state, true)
    assert_receive {:app_state_initial_sync, collections}
    assert "regular_low" in collections

    assert %{"010203" => %{data: ^key_data, timestamp: 123, fingerprint: encoded}} =
             Store.get(store, :app_state_keys)

    assert AppStateSyncKeyFingerprint.decode!(encoded) == fingerprint
    before = Store.load!(store)
    assert ^state = ingest(payload, state, true)
    assert Store.load!(store) == before
    assert_receive {:app_state_initial_sync, _}
    assert %{} == ingest(payload, %{}, true)
    refute_receive {:app_state_initial_sync, _}
  end

  test "failed app-state key storage never triggers a sync with unavailable keys" do
    alias ExWapp.Test.FaultStore
    store = FaultStore.new()
    state = %{store: store}

    key = %AppStateSyncKey{
      keyID: %AppStateSyncKeyId{keyID: <<1>>},
      keyData: %AppStateSyncKeyData{keyData: <<1::256>>, timestamp: 123}
    }

    payload =
      Proto.encode(%Message{
        protocolMessage: %ProtocolMessage{
          type: :APP_STATE_SYNC_KEY_SHARE,
          appStateSyncKeyShare: %AppStateSyncKeyShare{keys: [key]}
        }
      })

    for failure <- [:raise, {:return, {:error, :disk_full}}] do
      FaultStore.arm(store, :get_and_update, failure)
      assert ingest(payload, state, true) == state
      assert Store.get(store, :app_state_keys, %{}) == %{}
      refute_receive {:app_state_initial_sync, _}
    end

    assert ingest(payload, state, true) == state
    assert_receive {:app_state_initial_sync, _}
    assert Store.get(store, :app_state_keys)["01"].data == <<1::256>>
  end

  defp ingest(payload, state, own?),
    do:
      Sync.ingest(
        %{message_content_type: :protocol, protocol_payload: payload},
        self(),
        state,
        @jid,
        "sync",
        own?
      )

  defp history_payload(bytes),
    do:
      Proto.encode(%Message{
        protocolMessage: %ProtocolMessage{
          type: :HISTORY_SYNC_NOTIFICATION,
          historySyncNotification: %HistorySyncNotification{
            syncType: :RECENT,
            initialHistBootstrapInlinePayload: bytes
          }
        }
      })
end
