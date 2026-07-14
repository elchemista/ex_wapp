defmodule ExWapp.Message.Handler.Inbound.ReceiptsTest do
  use ExUnit.Case, async: true

  alias ExWapp.Message.Handler.Inbound.Receipts

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
             {:request_placeholder_resend, "15550001111@s.whatsapp.net", ^from, "message-2"}
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

  test "treats consumed Signal key failures as delivered duplicates" do
    from = "15550001111@s.whatsapp.net"
    state = %{marker: :unchanged}

    for reason <- [:message_key_not_found, :prekey_not_found, :key_unavailable] do
      decrypt_status =
        {:error,
         {:decrypt_failed_for_payload, "pkmsg",
          {:decrypt_failed_for_candidate, from, reason}}}

      message_data = %{
        encrypted: true,
        placeholder_unavailable: true,
        decrypt_status: decrypt_status
      }

      assert Receipts.duplicate_decrypt_error?(decrypt_status)

      assert {[
                {:send_receipt, ^from, "duplicate-#{reason}", nil, nil, %{recipient: nil}}
              ], ^state} =
               Receipts.build_actions(
                 from,
                 "duplicate-#{reason}",
                 nil,
                 %{},
                 message_data,
                 state
               )
    end
  end

  test "genuine Signal decrypt failures still request a retry" do
    from = "15550001111@s.whatsapp.net"

    decrypt_status =
      {:error,
       {:decrypt_failed_for_payload, "msg",
        {:decrypt_failed_for_candidate, from, :invalid_mac}}}

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
             {:request_placeholder_resend, ^from, ^from, "message-invalid-mac"}
           ] = actions

    assert map_size(updated_state.retry_counters) == 1
  end
end
