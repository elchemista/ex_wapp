defmodule ExWapp.MediaRetryBoundariesTest do
  use ExUnit.Case, async: true
  alias ExWapp.Binary.{Node, Raw}
  alias ExWapp.Media.Retry

  test "authenticated phone error results and stanza mismatches are preserved" do
    key = :crypto.strong_rand_bytes(32)

    for result <- [:general_error, :not_found, :decryption_error, 257] do
      payload = Retry.encode_notification("message", "/new/path", result, "secret")

      assert {:error, {:result, ^result}} =
               Retry.decode_notification(notification(payload, key), key)
    end

    payload = Retry.encode_notification("different", "/new/path", :success)

    assert {:error, :stanza_id_mismatch} =
             Retry.decode_notification(notification(payload, key), key)

    payload = Retry.encode_notification("message", "", :success)

    assert {:error, :missing_direct_path} =
             Retry.decode_notification(notification(payload, key), key)

    payload = Retry.encode_notification(nil, "/new/path", :success)
    assert {:ok, "/new/path"} = Retry.decode_notification(notification(payload, key), key)
  end

  test "future unknown fields are accepted while malformed authenticated protobufs are rejected" do
    key = :crypto.strong_rand_bytes(32)
    unknown_fields = <<160, 1, 128, 1, 169, 1, 0::64, 181, 1, 0::32>>
    payload = Retry.encode_notification("message", String.duplicate("/long", 40), :success)

    assert {:ok, path} =
             Retry.decode_notification(notification(unknown_fields <> payload, key), key)

    assert path == String.duplicate("/long", 40)

    for bytes <- [<<10, 5, 1>>, <<8>>, <<11>>, :binary.copy(<<128>>, 12)] do
      assert {:error, _} = Retry.decode_notification(notification(bytes, key), key)
      assert {:error, _} = Retry.decode_server_error_receipt(bytes)
    end

    assert {:error, :missing_stanza_id} = Retry.decode_server_error_receipt(<<>>)
    assert {:error, :missing_stanza_id} = Retry.decode_server_error_receipt(<<10, 0>>)
    assert {:error, :malformed_server_error_receipt} = Retry.decode_server_error_receipt(<<8, 1>>)
  end

  test "missing encryption material and bad media keys never return a usable path" do
    key = :crypto.strong_rand_bytes(32)

    for node <- [
          %Node{tag: "notification"},
          %Node{
            tag: "notification",
            attrs: %{"id" => "message"},
            content: [%Node{tag: "encrypt"}]
          }
        ] do
      assert {:error, :malformed_notification} = Retry.decode_notification(node, key)
    end

    node = notification(Retry.encode_notification("message", "/new", :success), key)
    assert {:error, :malformed_notification} = Retry.decode_notification(node, <<1>>)

    assert {:error, {:server_error, "503"}} =
             Retry.decode_notification(
               %Node{
                 tag: "notification",
                 content: [%Node{tag: "error", attrs: %{"code" => "503"}}]
               },
               key
             )
  end

  defp notification(payload, key) do
    iv = :crypto.strong_rand_bytes(12)
    encrypted = Retry.encrypt_notification(payload, key, iv, "message")

    %Node{
      tag: "notification",
      attrs: %{"id" => "message"},
      content: [
        %Node{
          tag: "encrypt",
          content: [
            %Node{tag: "enc_p", content: %Raw{data: encrypted}},
            %Node{tag: "enc_iv", content: %Raw{data: iv}}
          ]
        }
      ]
    }
  end
end
