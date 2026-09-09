defmodule ExWapp.MediaTLSIntegrationTest do
  use ExUnit.Case, async: false
  alias ExWapp.Media
  @moduletag capture_log: true

  setup_all do
    dir = Path.join(System.tmp_dir!(), "ex_wapp_tls_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    cert = Path.join(dir, "cert.pem")
    key = Path.join(dir, "key.pem")
    previous = Path.join(dir, "previous-ca.pem")

    old_certs =
      Enum.map(:public_key.cacerts_get(), fn
        {:cert, der, _} -> {:Certificate, der, :not_encrypted}
        der when is_binary(der) -> {:Certificate, der, :not_encrypted}
      end)

    File.write!(previous, :public_key.pem_encode(old_certs))
    ca = Path.join(dir, "ca.pem")
    ca_key = Path.join(dir, "ca-key.pem")
    csr = Path.join(dir, "server.csr")
    extensions = Path.join(dir, "extensions.cnf")

    File.write!(
      extensions,
      "subjectAltName=DNS:localhost\nbasicConstraints=CA:FALSE\nextendedKeyUsage=serverAuth\nkeyUsage=digitalSignature,keyEncipherment\n"
    )

    {_, 0} =
      System.cmd(
        "openssl",
        [
          "req",
          "-x509",
          "-newkey",
          "rsa:2048",
          "-nodes",
          "-keyout",
          ca_key,
          "-out",
          ca,
          "-days",
          "1",
          "-subj",
          "/CN=ExWapp Test CA"
        ],
        stderr_to_stdout: true
      )

    {_, 0} =
      System.cmd(
        "openssl",
        [
          "req",
          "-new",
          "-newkey",
          "rsa:2048",
          "-nodes",
          "-keyout",
          key,
          "-out",
          csr,
          "-subj",
          "/CN=localhost"
        ],
        stderr_to_stdout: true
      )

    {_, 0} =
      System.cmd(
        "openssl",
        [
          "x509",
          "-req",
          "-in",
          csr,
          "-CA",
          ca,
          "-CAkey",
          ca_key,
          "-CAcreateserial",
          "-out",
          cert,
          "-days",
          "1",
          "-extfile",
          extensions
        ],
        stderr_to_stdout: true
      )

    :ok = :public_key.cacerts_load(String.to_charlist(ca))

    on_exit(fn ->
      :ok = :public_key.cacerts_load(String.to_charlist(previous))
      File.rm_rf!(dir)
    end)

    %{cert: cert, key: key}
  end

  for type <- [:image, :audio, :document] do
    @media_type type
    test "uploads #{@media_type} over verified TLS and authenticates the captured encrypted body",
         ctx do
      host =
        serve(
          ctx,
          200,
          ~s({"url":"https://cdn.example.test/media","direct_path":"/media","handle":"h","object_id":"o"})
        )

      assert {:ok, upload} =
               Media.HTTP.upload(%{}, @media_type, <<0, 255, "private media">>,
                 media_conn: %{hosts: [%{hostname: host}], auth: "a+b/c?"}
               )

      assert upload.url == "https://cdn.example.test/media"
      assert upload.direct_path == "/media"
      assert upload.handle == "h"
      assert upload.object_id == "o"
      assert_receive {:tls_request, :POST, path, headers, encrypted}, 1000
      assert path =~ "/mms/#{@media_type}/"
      assert URI.decode_query(URI.parse(path).query)["auth"] == "a+b/c?"
      assert headers["content-type"] == "application/octet-stream"
      assert headers["origin"] == "https://web.whatsapp.com"
      refute :binary.match(encrypted, "private media") != :nomatch

      assert {:ok, <<0, 255, "private media">>} =
               Media.Crypto.decrypt_download(encrypted, Media.ref_from_upload(upload))
    end
  end

  test "upload preserves useful metadata from a malformed JSON response", ctx do
    host =
      serve(ctx, 200, ~s({"url":"https://cdn.example.test/media","direct_path":"/media", broken))

    assert {:ok, upload} =
             Media.HTTP.upload(%{}, :image, "body",
               media_conn: %{hosts: [%{hostname: host}], auth: ""}
             )

    assert upload.url == "https://cdn.example.test/media"
    assert upload.direct_path == "/media"
    assert upload.handle == nil
  end

  test "server upload rejection reports status without returning an upload", ctx do
    host = serve(ctx, 503, "unavailable")

    assert {:error, {:upload_http_error, 503, 11}} =
             Media.HTTP.upload(%{}, :image, "body",
               media_conn: %{hosts: [%{hostname: host}], auth: "token"}
             )
  end

  test "direct-path download falls back across hosts and validates the recovered file", ctx do
    {:ok, upload, body} = Media.Crypto.encrypt_upload("recovered media", :document)
    first = serve(ctx, 404, "gone")
    second = serve(ctx, 200, body)
    ref = %{Media.ref_from_upload(upload) | direct_path: "/media?existing=1"}

    assert {:ok, "recovered media"} =
             Media.HTTP.download(%{}, ref,
               media_conn: %{hosts: [%{hostname: first}, %{hostname: second}]}
             )

    for _ <- 1..2 do
      assert_receive {:tls_request, :GET, path, _, ""}, 1000
      query = URI.decode_query(URI.parse(path).query)
      assert query["existing"] == "1"
      assert query["hash"] == Base.url_encode64(upload.file_enc_sha256)
      assert query["mms-type"] == "document"
    end
  end

  test "connection failures are returned instead of inventing successful upload metadata" do
    {:ok, listener} = :gen_tcp.listen(0, [:binary, active: false, ip: {127, 0, 0, 1}])
    {:ok, {_, port}} = :inet.sockname(listener)
    :gen_tcp.close(listener)

    assert {:error, {:upload_failed, _}} =
             Media.HTTP.upload(%{}, :image, "body",
               media_conn: %{hosts: [%{hostname: "localhost:#{port}"}], auth: ""}
             )

    assert {:error, {:download_failed, _}} =
             Media.HTTP.download(%{}, %Media.Ref{type: :image, direct_path: "/missing?x=1"},
               media_conn: %{hosts: [%{hostname: "localhost:#{port}"}]}
             )
  end

  defp serve(ctx, status, response) do
    {:ok, listener} =
      :ssl.listen(0, [
        :binary,
        active: false,
        reuseaddr: true,
        ip: {127, 0, 0, 1},
        certfile: String.to_charlist(ctx.cert),
        keyfile: String.to_charlist(ctx.key)
      ])

    {:ok, {_, port}} = :ssl.sockname(listener)
    owner = self()

    task =
      Task.async(fn ->
        {:ok, transport} = :ssl.transport_accept(listener, 5000)
        {:ok, socket} = :ssl.handshake(transport, 5000)
        :ok = :ssl.setopts(socket, packet: :http_bin)
        {:ok, {:http_request, method, {:abs_path, path}, _}} = :ssl.recv(socket, 0, 5000)
        headers = read_headers(socket, %{})
        :ok = :ssl.setopts(socket, packet: :raw)
        size = String.to_integer(headers["content-length"] || "0")
        body = if size == 0, do: "", else: elem(:ssl.recv(socket, size, 5000), 1)
        send(owner, {:tls_request, method, path, headers, body})

        :ok =
          :ssl.send(socket, [
            "HTTP/1.1 #{status} Response\r\nContent-Length: #{byte_size(response)}\r\nConnection: close\r\n\r\n",
            response
          ])

        :ssl.close(socket)
      end)

    on_exit(fn ->
      :ssl.close(listener)
      if Process.alive?(task.pid), do: Process.exit(task.pid, :kill)
    end)

    "localhost:#{port}"
  end

  defp read_headers(socket, acc) do
    case :ssl.recv(socket, 0, 5000) do
      {:ok, {:http_header, _, name, _, value}} ->
        read_headers(socket, Map.put(acc, String.downcase(to_string(name)), value))

      {:ok, :http_eoh} ->
        acc
    end
  end
end
