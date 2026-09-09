defmodule ExWapp.MediaHTTPTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary.Node
  alias ExWapp.Media.{Crypto, HTTP, Ref}

  defmodule IQSession do
    use GenServer
    def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
    @impl true
    def init(opts), do: {:ok, opts}
    @impl true
    def handle_call({:send_iq, node, id}, _from, {owner, reply} = state) do
      send(owner, {:media_iq, node, id})
      {:reply, reply, state}
    end
  end

  test "downloads binary media over HTTP and verifies and decrypts the response" do
    plaintext = <<0, 255, "image", 0, 128>>
    {:ok, upload, body} = Crypto.encrypt_upload(plaintext, :image)
    url = serve(200, body)

    ref = %Ref{
      url: url,
      type: :image,
      media_key: upload.media_key,
      file_sha256: upload.file_sha256,
      file_enc_sha256: upload.file_enc_sha256,
      file_length: upload.file_length
    }

    assert {:ok, ^plaintext} = HTTP.download(%{}, ref)
    assert_receive {:http_request, {:http_request, :GET, {:abs_path, "/media"}, _}, headers}
    assert {"origin", "https://web.whatsapp.com"} in headers
    assert {"referer", "https://web.whatsapp.com/"} in headers
  end

  test "unencrypted downloads ignore a media key but still verify the plaintext hash" do
    body = "thumbnail"

    ref = %Ref{
      url: serve(200, body),
      type: :image,
      media_key: <<1>>,
      file_sha256: :crypto.hash(:sha256, body)
    }

    assert {:ok, ^body} = HTTP.download(%{}, ref)
  end

  test "a tampered HTTP response fails media authentication" do
    {:ok, upload, body} = Crypto.encrypt_upload("private media", :image)
    <<first, rest::binary>> = body

    ref = %Ref{
      url: serve(200, <<Bitwise.bxor(first, 1), rest::binary>>),
      type: :image,
      media_key: upload.media_key,
      file_enc_sha256: upload.file_enc_sha256
    }

    assert {:error, :invalid_media_hmac} = HTTP.download(%{}, ref)
  end

  test "HTTP errors fall back to media connection lookup" do
    ref = %Ref{url: serve(404, "expired"), type: :image, direct_path: "/missing?x=1"}
    assert {:error, :media_download_failed} = HTTP.download(%{}, ref, media_conn: %{hosts: []})
  end

  test "missing connection data and missing paths return actionable errors" do
    ref = %Ref{type: :document}
    assert {:error, :missing_session_for_media_conn} = HTTP.download(%{}, ref)
    assert {:error, :missing_media_url} = HTTP.download(%{}, ref, media_conn: %{hosts: []})
    assert {:error, :missing_session_for_media_conn} = HTTP.upload(%{}, :image, "image")

    assert {:error, :missing_media_host} =
             HTTP.upload(%{}, :audio, "audio", media_conn: %{hosts: [], auth: "token"})
  end

  test "media connection IQ errors are propagated without an HTTP request" do
    session = start_supervised!({IQSession, {self(), {:error, :iq_timeout}}})
    assert {:error, :iq_timeout} = HTTP.upload(%{}, :document, "document", session: session)

    assert_receive {:media_iq,
                    %Node{tag: "iq", attrs: attrs, content: [%Node{tag: "media_conn"}]}, id}

    assert attrs["id"] == id
    assert attrs["xmlns"] == "w:m"
    assert attrs["type"] == "set"
  end

  test "unexpected media connection replies are classified" do
    session = start_supervised!({IQSession, {self(), :unexpected}})

    assert {:error, {:bad_media_conn_response, :unexpected}} =
             HTTP.download(%{}, %Ref{}, session: session)
  end

  test "successful media connection replies still require an upload host" do
    response = %Node{
      tag: "iq",
      attrs: %{"type" => "result"},
      content: [%Node{tag: "media_conn", attrs: %{"auth" => "token"}, content: []}]
    }

    session = start_supervised!({IQSession, {self(), {:ok, response}}})
    assert {:error, :missing_media_host} = HTTP.upload(%{}, :image, "image", session: session)
  end

  defp serve(status, body) do
    {:ok, listener} =
      :gen_tcp.listen(0, [:binary, active: false, packet: :http_bin, ip: {127, 0, 0, 1}])

    {:ok, port} = :inet.port(listener)
    on_exit(fn -> :gen_tcp.close(listener) end)
    owner = self()
    supervisor = start_supervised!(Task.Supervisor)

    Task.Supervisor.start_child(supervisor, fn ->
      {:ok, socket} = :gen_tcp.accept(listener, 2_000)

      try do
        {:ok, request} = :gen_tcp.recv(socket, 0, 2_000)
        send(owner, {:http_request, request, read_headers(socket, [])})

        :ok =
          :gen_tcp.send(socket, [
            "HTTP/1.1 #{status} Response\r\ncontent-length: #{byte_size(body)}\r\nconnection: close\r\n\r\n",
            body
          ])
      after
        :gen_tcp.close(socket)
      end
    end)

    "http://127.0.0.1:#{port}/media"
  end

  defp read_headers(socket, headers) do
    case :gen_tcp.recv(socket, 0, 2_000) do
      {:ok, :http_eoh} ->
        headers

      {:ok, {:http_header, _, name, _, value}} ->
        read_headers(socket, [{name |> to_string() |> String.downcase(), value} | headers])
    end
  end
end
