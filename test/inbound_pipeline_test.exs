defmodule ExWapp.Message.Handler.Inbound.PipelineTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias ExWapp.Binary.Node
  alias ExWapp.{Binary, JID, MessageHandler, Store}
  alias ExWapp.Signal.{Encryption, SessionStore}
  alias ExWapp.Test.{ProtocolPeer, SignalDevice}

  defmodule FailingStore do
    @behaviour ExWapp.Store

    defstruct []

    @impl true
    def new(_opts), do: %__MODULE__{}

    @impl true
    def load(_store), do: raise("store unavailable")

    @impl true
    def persist(_store, _data), do: {:error, :store_unavailable}
  end

  test "application persistence failures do not suppress the protocol receipt" do
    node = %Node{
      tag: "message",
      attrs: %{
        "from" => "15550001111@s.whatsapp.net",
        "id" => "message-with-failed-persistence",
        "type" => "text",
        "t" => "1730000000"
      },
      content: [%Node{tag: "body", attrs: %{}, content: "hello"}]
    }

    result =
      capture_log(fn ->
        send(
          self(),
          {:result, MessageHandler.handle_node(node, self(), %{store: %FailingStore{}})}
        )
      end)

    assert result =~ "phase=application_publish failed"

    assert_receive {:result, {:ok, state, actions}}

    assert state.stats == %{errors: 1, messages_received: 1}

    assert actions == [
             {:send_receipt, "15550001111@s.whatsapp.net", "message-with-failed-persistence", nil,
              nil, %{recipient: nil}}
           ]

    refute_received {:new_message, _, _}
  end

  for {sender, trusted?} <- [{"90000000099@lid", true}, {"90000000001@lid", false}] do
    @sender sender
    @trusted trusted?

    test "encrypted key shares from #{@sender} with only a persisted pairing LID" do
      local = SignalDevice.new()
      peer = SignalDevice.new()
      pn = JID.new("15550009999", "s.whatsapp.net") |> JID.with_device(7)
      lid = JID.new("90000000099", "lid") |> JID.with_device(7)

      store =
        Store.Memory.new(
          initial_data: %{
            pairing: %{device: %{"jid" => pn, "lid" => lid}},
            client_info: %{jid: pn},
            signal:
              Map.merge(local.local_prekeys, %{
                identity_key: local.identity,
                registration_id: local.bundle.registration_id
              })
          }
        )

      on_exit(fn -> Store.Memory.stop(store) end)

      key_data = :crypto.strong_rand_bytes(32)
      plaintext = key_share_payload(key_data) |> Encryption.pad_message()

      {:ok, ciphertext, :prekey, _} =
        SessionStore.encrypt_message(
          SessionStore.new(),
          JID.to_string(pn),
          plaintext,
          peer.identity,
          peer.bundle.registration_id,
          local.bundle
        )

      node =
        %Node{
          tag: "message",
          attrs: %{"from" => @sender, "id" => "key-share", "type" => "text"},
          content: [
            %Node{
              tag: "enc",
              attrs: %{"type" => "pkmsg", "v" => "2"},
              content: Binary.raw(ciphertext)
            }
          ]
        }
        |> Binary.encode!()
        |> Binary.decode!()

      assert {:ok, state, _actions} =
               MessageHandler.handle_node(node, self(), %{
                 store: store,
                 signal_sessions: SessionStore.new()
               })

      assert SessionStore.has_session?(state.signal_sessions, @sender)

      if @trusted do
        assert %{"010203" => %{data: ^key_data}} = Store.get(store, :app_state_keys)
        assert_receive {:app_state_initial_sync, collections}
        assert "regular_low" in collections
      else
        assert Store.get(store, :app_state_keys, %{}) == %{}
        refute_received {:app_state_initial_sync, _}
      end

      refute_received {:new_message, _, _}
    end
  end

  defp key_share_payload(key_data) do
    alias WAWebProtobufsE2E.{
      AppStateSyncKey,
      AppStateSyncKeyData,
      AppStateSyncKeyId,
      AppStateSyncKeyShare,
      Message,
      ProtocolMessage
    }

    ProtocolPeer.encode(%Message{
      protocolMessage: %ProtocolMessage{
        type: :APP_STATE_SYNC_KEY_SHARE,
        appStateSyncKeyShare: %AppStateSyncKeyShare{
          keys: [
            %AppStateSyncKey{
              keyID: %AppStateSyncKeyId{keyID: <<1, 2, 3>>},
              keyData: %AppStateSyncKeyData{keyData: key_data, timestamp: 123}
            }
          ]
        }
      }
    })
  end
end
