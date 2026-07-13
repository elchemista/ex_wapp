defmodule ExWapp.Message.Handler.Inbound.DecryptorTest do
  use ExUnit.Case, async: true

  alias ExWapp.Message.Handler.Inbound.Decryptor
  alias ExWapp.Signal.SessionStore
  alias ExWapp.Store.Memory

  test "normalizes an encrypted message when the store is missing" do
    message_data = %{
      encrypted: true,
      enc_type: "msg",
      enc_candidates: [%{enc_type: "msg", ciphertext: <<1>>, to_jid: nil}]
    }

    state = %{store: nil, signal_sessions: SessionStore.new()}

    assert {:error, updated_message_data, ^state} =
             Decryptor.decrypt(
               message_data,
               state,
               "15550001111@s.whatsapp.net",
               nil,
               %{}
             )

    assert updated_message_data.decrypt_status == {:error, :missing_store}
  end

  test "reports missing sender candidates before attempting Signal decrypt" do
    store = Memory.new()
    on_exit(fn -> Memory.stop(store) end)

    message_data = %{
      encrypted: true,
      enc_type: "msg",
      enc_candidates: [%{enc_type: "msg", ciphertext: <<1>>, to_jid: nil}]
    }

    state = %{store: store, signal_sessions: SessionStore.new()}

    assert {:error, updated_message_data, ^state} =
             Decryptor.decrypt(message_data, state, "", nil, %{})

    assert updated_message_data.decrypt_status == {:error, :no_sender_candidates}
  end

  test "reports missing ciphertext candidates before attempting Signal decrypt" do
    store = Memory.new()
    on_exit(fn -> Memory.stop(store) end)

    message_data = %{
      encrypted: true,
      enc_type: "msg",
      enc_candidates: [%{enc_type: "msg", ciphertext: nil, to_jid: nil}]
    }

    state = %{store: store, signal_sessions: SessionStore.new()}

    assert {:error, updated_message_data, ^state} =
             Decryptor.decrypt(
               message_data,
               state,
               "15550001111@s.whatsapp.net",
               nil,
               %{}
             )

    assert updated_message_data.decrypt_status == {:error, :no_ciphertext_candidates}
  end
end
