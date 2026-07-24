defmodule ExWapp.Message.Handler.Inbound.ReceiptsTest do
  use ExUnit.Case, async: true

  alias ExWapp.Message.Handler.Inbound.Receipts
  alias ExWapp.Store
  alias ExWapp.Store.Memory

  test "plans a delivery receipt for a normalized user message" do
    from = "15550001111@s.whatsapp.net"
    state = %{marker: :unchanged}

    assert {[
              {:send_receipt, ^from, "message-1", nil, nil, %{recipient: nil}}
            ], ^state} =
             Receipts.build_actions(
               from,
               "message-1",
               nil,
               %{},
               %{decrypt_status: :ok},
               state
             )
  end

  test "plans one placeholder resend with the first retry receipt" do
    from = "15550001111:7@s.whatsapp.net"

    message_data = %{
      encrypted: true,
      decrypt_status: {:error, :no_ciphertext_candidates}
    }

    assert {actions, state} =
             Receipts.build_actions(
               from,
               "message-2",
               nil,
               %{"t" => "123"},
               message_data,
               %{}
             )

    assert [
             {:send_retry_receipt, ^from, "message-2", nil, "123", 1, 0,
              %{category: nil, recipient: nil}},
             {:request_placeholder_resend, "15550001111@s.whatsapp.net", ^from, "message-2",
              %{from_me: false}}
           ] = actions

    assert map_size(state.retry_counters) == 1

    assert {second_actions, _state} =
             Receipts.build_actions(
               from,
               "message-2",
               nil,
               %{"t" => "123"},
               message_data,
               state
             )

    assert [
             {:send_retry_receipt, ^from, "message-2", nil, "123", 2, 0,
              %{category: nil, recipient: nil}}
           ] = second_actions
  end

  test "does not build receipts without a sender and message id" do
    assert {[], %{}} = Receipts.build_actions("", "", nil, %{}, %{}, %{})
  end

  test "treats a ratchet-proven replay of a stored message as delivered" do
    from = "15550001111@s.whatsapp.net"
    store = Memory.new()
    state = %{marker: :unchanged, store: store}
    message_id = "duplicate-message-key"

    assert :ok =
             Store.upsert_messages(store, from, [
               %{id: message_id, timestamp: 1, status: :received}
             ])

    decrypt_status =
      {:error,
       {:decrypt_failed_for_payload, "pkmsg",
        {:decrypt_failed_for_candidate, from, :message_key_not_found}}}

    message_data = %{
      encrypted: true,
      placeholder_unavailable: true,
      decrypt_status: decrypt_status
    }

    assert Receipts.duplicate_decrypt_error?(decrypt_status)

    assert {[
              {:send_receipt, ^from, ^message_id, nil, nil, %{recipient: nil}}
            ], ^state} =
             Receipts.build_actions(
               from,
               message_id,
               nil,
               %{},
               message_data,
               state
             )
  end

  test "does not call missing prekey material a duplicate even when the message id is stored" do
    from = "15550001111@s.whatsapp.net"
    message_id = "stored-but-not-ratchet-proven"
    store = Memory.new()

    assert :ok =
             Store.upsert_messages(store, from, [
               %{id: message_id, timestamp: 1, status: :received}
             ])

    decrypt_status =
      {:error,
       {:decrypt_failed_for_payload, "pkmsg",
        {:decrypt_failed_for_candidate, from, :prekey_not_found}}}

    refute Receipts.duplicate_decrypt_error?(decrypt_status)

    assert {actions, _state} =
             Receipts.build_actions(
               from,
               message_id,
               nil,
               %{"t" => "321"},
               %{encrypted: true, decrypt_status: decrypt_status},
               %{store: store}
             )

    assert [
             {:send_retry_receipt, ^from, ^message_id, nil, "321", 1, 0,
              %{category: nil, recipient: nil}},
             {:request_placeholder_resend, ^from, ^from, ^message_id, %{from_me: false}}
           ] = actions
  end

  test "requests a retry when consumed key material belongs to an unseen message" do
    from = "15550001111@s.whatsapp.net"

    decrypt_status =
      {:error,
       {:decrypt_failed_for_payload, "pkmsg",
        {:decrypt_failed_for_candidate, from, :prekey_not_found}}}

    assert {actions, updated_state} =
             Receipts.build_actions(
               from,
               "unseen-prekey-message",
               nil,
               %{"t" => "322"},
               %{encrypted: true, decrypt_status: decrypt_status},
               %{store: Memory.new()}
             )

    assert [
             {:send_retry_receipt, ^from, "unseen-prekey-message", nil, "322", 1, 0,
              %{category: nil, recipient: nil}},
             {:request_placeholder_resend, ^from, ^from, "unseen-prekey-message",
              %{from_me: false}}
           ] = actions

    assert map_size(updated_state.retry_counters) == 1
  end

  test "does not suppress a decrypt failure because another chat reused the message id" do
    from = "15550001111@s.whatsapp.net"
    other_chat = "15550002222@s.whatsapp.net"
    message_id = "chat-scoped-message-id"
    store = Memory.new()

    assert :ok =
             Store.upsert_messages(store, other_chat, [
               %{id: message_id, timestamp: 1, status: :received}
             ])

    decrypt_status =
      {:error,
       {:decrypt_failed_for_payload, "pkmsg",
        {:decrypt_failed_for_candidate, from, :prekey_not_found}}}

    assert {actions, _state} =
             Receipts.build_actions(
               from,
               message_id,
               nil,
               %{"t" => "323"},
               %{encrypted: true, decrypt_status: decrypt_status},
               %{store: store}
             )

    assert [
             {:send_retry_receipt, ^from, ^message_id, nil, "323", 1, 0,
              %{category: nil, recipient: nil}},
             {:request_placeholder_resend, ^from, ^from, ^message_id, %{from_me: false}}
           ] = actions
  end

  test "genuine Signal decrypt failures still request a retry" do
    from = "15550001111@s.whatsapp.net"

    decrypt_status =
      {:error,
       {:decrypt_failed_for_payload, "msg", {:decrypt_failed_for_candidate, from, :invalid_mac}}}

    refute Receipts.duplicate_decrypt_error?(decrypt_status)

    assert {actions, updated_state} =
             Receipts.build_actions(
               from,
               "message-invalid-mac",
               nil,
               %{"t" => "321"},
               %{encrypted: true, decrypt_status: decrypt_status},
               %{}
             )

    assert [
             {:send_retry_receipt, ^from, "message-invalid-mac", nil, "321", 1, 7,
              %{category: nil, recipient: nil}},
             {:request_placeholder_resend, ^from, ^from, "message-invalid-mac", %{from_me: false}}
           ] = actions

    assert map_size(updated_state.retry_counters) == 1
  end

  test "uses the recipient chat and from-me key for an unavailable linked-device message" do
    own_device = "15550009999:7@s.whatsapp.net"
    recipient = "15550002222@lid"

    store =
      Memory.new(
        initial_data: %{
          pairing: %{device: %{jid: "15550009999@s.whatsapp.net"}},
          client_info: %{jid: "15550009999@s.whatsapp.net"}
        }
      )

    decrypt_status =
      {:error,
       {:decrypt_failed_for_payload, "msg",
        {:decrypt_failed_for_candidate, own_device, :no_session}}}

    assert {actions, _state} =
             Receipts.build_actions(
               own_device,
               "linked-device-message",
               nil,
               %{
                 "recipient" => recipient,
                 "peer_recipient_pn" => "15550002222@s.whatsapp.net",
                 "t" => "654"
               },
               %{encrypted: true, decrypt_status: decrypt_status},
               %{store: store}
             )

    assert {:request_placeholder_resend, recipient, own_device, "linked-device-message",
            %{from_me: true}} in actions
  end
end
