defmodule ExWapp.MediaRetryProtocolTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Binary.Node
  alias ExWapp.Media
  alias ExWapp.Media.Retry
  alias ExWapp.Message.Content
  alias ExWapp.MessageHandler
  alias ExWapp.Session
  alias ExWapp.Session.Worker
  alias ExWapp.Store

  test "server-error receipt round trips its authenticated protobuf" do
    media_key = :crypto.strong_rand_bytes(32)

    receipt =
      Media.build_retry_receipt(
        "MSG-1",
        "me@s.whatsapp.net",
        "group@g.us",
        false,
        "sender:2@s.whatsapp.net",
        media_key
      )

    assert %Node{
             tag: "receipt",
             attrs: %{
               "id" => "MSG-1",
               "to" => "me@s.whatsapp.net",
               "type" => "server-error"
             }
           } = receipt

    assert %Node{attrs: rmr_attrs} = child(receipt, "rmr")
    assert rmr_attrs["jid"] == "group@g.us"
    assert rmr_attrs["from_me"] == "false"
    assert rmr_attrs["participant"] == "sender:2@s.whatsapp.net"

    enc_p = raw_child(receipt, "encrypt", "enc_p")
    iv = raw_child(receipt, "encrypt", "enc_iv")
    assert byte_size(iv) == 12

    assert {:ok, plaintext} = decrypt_gcm(enc_p, Media.retry_key(media_key), iv, "MSG-1")
    assert {:ok, "MSG-1"} = Retry.decode_server_error_receipt(plaintext)
  end

  test "decodes an authenticated SUCCESS notification and rejects tampering" do
    media_key = :crypto.strong_rand_bytes(32)
    node = retry_notification("MSG-2", media_key, :success, "/mms/image/new")

    assert {:ok, "/mms/image/new"} = Media.decode_retry_notification(node, media_key)

    assert {:error, :invalid_media_retry_auth} =
             Media.decode_retry_notification(node, :crypto.strong_rand_bytes(32))

    encrypt = child(node, "encrypt")
    enc_p_node = child(encrypt, "enc_p")
    enc_p = raw_data(enc_p_node.content)
    <<first, rest::binary>> = enc_p
    tampered_enc = %{enc_p_node | content: Binary.raw(<<Bitwise.bxor(first, 1), rest::binary>>)}
    tampered = replace_child(node, "encrypt", replace_child(encrypt, "enc_p", tampered_enc))

    assert {:error, :invalid_media_retry_auth} =
             Media.decode_retry_notification(tampered, media_key)
  end

  test "validates result, stanza correlation, direct path and wire errors" do
    media_key = :crypto.strong_rand_bytes(32)

    assert {:error, {:result, :not_found}} =
             retry_notification("MSG-3", media_key, :not_found, "")
             |> Media.decode_retry_notification(media_key)

    assert {:error, :missing_direct_path} =
             retry_notification("MSG-3", media_key, :success, "")
             |> Media.decode_retry_notification(media_key)

    mismatch = retry_notification("MSG-3", media_key, :success, "/new", "OTHER")

    assert {:error, :stanza_id_mismatch} =
             Media.decode_retry_notification(mismatch, media_key)

    not_on_phone = %Node{
      tag: "notification",
      attrs: %{"id" => "MSG-3", "type" => "mediaretry"},
      content: [%Node{tag: "error", attrs: %{"code" => "2"}, content: nil}]
    }

    assert {:error, :not_on_phone} = Media.decode_retry_notification(not_on_phone, media_key)

    server_error_node = %{hd(not_on_phone.content) | attrs: %{"code" => "7"}}
    server_error = %{not_on_phone | content: [server_error_node]}

    assert {:error, {:server_error, "7"}} =
             Media.decode_retry_notification(server_error, media_key)
  end

  test "notification handler resolves a pending request and persists the fresh path" do
    media_key = :crypto.strong_rand_bytes(32)
    old_ref = %Media.Ref{type: :image, media_key: media_key, direct_path: "/old"}

    message = %{
      id: "MSG-4",
      media: old_ref,
      content: %Content{kind: :media, media: old_ref, media_type: :image},
      raw: %{media: old_ref},
      from_me: false,
      status: :received,
      timestamp: 1
    }

    store = Store.Memory.new(initial_data: %{messages: %{"peer@s.whatsapp.net" => [message]}})
    caller = {self(), make_ref()}

    state = %{
      store: store,
      pending_media_retries: %{
        "MSG-4" => %{
          from: caller,
          timer: nil,
          media_key: media_key,
          ref: old_ref,
          message: message,
          chat_jid: "peer@s.whatsapp.net"
        }
      }
    }

    notification = retry_notification("MSG-4", media_key, :success, "/fresh")

    assert {:ok, next_state, actions} =
             MessageHandler.handle_node(notification, self(), state)

    assert next_state.pending_media_retries == %{}

    assert [
             {:send_node, %Node{tag: "ack"}},
             {:resolve_media_retry, ^caller, {:ok, %Media.Ref{direct_path: "/fresh", url: nil}}}
           ] = actions

    assert {"peer@s.whatsapp.net", stored} = Store.find_message_by_id(store, "MSG-4")
    assert stored.media.direct_path == "/fresh"
    assert stored.content.media.direct_path == "/fresh"
    assert stored.raw.media.direct_path == "/fresh"
  end

  test "disconnect resolves an in-flight media retry and cancels its timer" do
    media_key = :crypto.strong_rand_bytes(32)
    ref = %Media.Ref{type: :image, media_key: media_key, direct_path: "/expired"}

    message = %{
      id: "MSG-DISCONNECT",
      media: ref,
      from_me: false,
      participant: nil,
      status: :received,
      timestamp: 1
    }

    initial_data = %{
      client_info: %{jid: "15550001111:4@s.whatsapp.net"},
      chat_messages: %{"peer@s.whatsapp.net" => [message]}
    }

    {:ok, session} =
      GenServer.start(Worker,
        reconnect: false,
        store: {Store.Memory, initial_data: initial_data}
      )

    conn = spawn(fn -> Process.sleep(:infinity) end)

    on_exit(fn ->
      if Process.alive?(session), do: GenServer.stop(session)
      if Process.alive?(conn), do: Process.exit(conn, :kill)
    end)

    :sys.replace_state(session, fn state ->
      %{state | status: :connected, conn: conn, conn_ref: Process.monitor(conn)}
    end)

    request = Task.async(fn -> Session.retry_media(session, "MSG-DISCONNECT", timeout: 5_000) end)

    assert eventually(fn ->
             map_size(:sys.get_state(session).pending_media_retries) == 1
           end)

    timer =
      session
      |> :sys.get_state()
      |> Map.fetch!(:pending_media_retries)
      |> Map.fetch!("MSG-DISCONNECT")
      |> Map.fetch!(:timer)

    send(session, {:connection_event, {:transport, {:closed, :network_lost}}})

    assert {:error, {:disconnected, {:transport_closed, :network_lost}}} =
             Task.await(request, 1_000)

    assert eventually(fn -> :sys.get_state(session).pending_media_retries == %{} end)
    assert Process.read_timer(timer) == false
  end

  defp retry_notification(msg_id, media_key, result, direct_path, stanza_id \\ nil) do
    iv = :crypto.strong_rand_bytes(12)
    plaintext = Retry.encode_notification(stanza_id || msg_id, direct_path, result)
    encrypted = Retry.encrypt_notification(plaintext, media_key, iv, msg_id)

    %Node{
      tag: "notification",
      attrs: %{"id" => msg_id, "type" => "mediaretry", "from" => "peer@s.whatsapp.net"},
      content: [
        %Node{
          tag: "encrypt",
          attrs: %{},
          content: [
            %Node{tag: "enc_p", attrs: %{}, content: Binary.raw(encrypted)},
            %Node{tag: "enc_iv", attrs: %{}, content: Binary.raw(iv)}
          ]
        }
      ]
    }
  end

  defp child(%Node{content: content}, tag) when is_list(content),
    do: Enum.find(content, &match?(%Node{tag: ^tag}, &1))

  defp raw_child(node, parent_tag, child_tag) do
    node |> child(parent_tag) |> child(child_tag) |> Map.fetch!(:content) |> raw_data()
  end

  defp raw_data(%Binary.Raw{data: data}), do: data
  defp raw_data(data) when is_binary(data), do: data

  defp replace_child(%Node{content: content} = node, tag, replacement) do
    %{
      node
      | content:
          Enum.map(content, fn
            %Node{tag: ^tag} -> replacement
            child -> child
          end)
    }
  end

  defp decrypt_gcm(payload, key, iv, aad) do
    ciphertext_size = byte_size(payload) - 16
    <<ciphertext::binary-size(^ciphertext_size), tag::binary-size(16)>> = payload

    case :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ciphertext, aad, tag, false) do
      :error -> {:error, :auth}
      plaintext -> {:ok, plaintext}
    end
  end

  defp eventually(fun, attempts \\ 50)

  defp eventually(fun, attempts) when attempts > 0 do
    if fun.() do
      true
    else
      Process.sleep(10)
      eventually(fun, attempts - 1)
    end
  end

  defp eventually(_fun, 0), do: false
end
