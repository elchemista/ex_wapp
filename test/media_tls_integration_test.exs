defmodule ExWapp.MediaTLSIntegrationTest do
  use ExUnit.Case, async: false
  alias ExWapp.Media
  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.Inbound.Sync
  alias ExWapp.Test.{FaultStore, HistoryBlob}
  @moduletag capture_log: true

  defmodule MediaConnection do
    def send_node(conn, %Node{attrs: %{"id" => id}} = node) do
      %{session: session, host: host, owner: owner} = Agent.get(conn, & &1)
      send(owner, {:media_conn_requested, node})

      if host do
        response = %Node{
          tag: "iq",
          attrs: %{"id" => id, "type" => "result"},
          content: [
            %Node{
              tag: "media_conn",
              attrs: %{"auth" => "test", "ttl" => "60"},
              content: [%Node{tag: "host", attrs: %{"hostname" => host}}]
            }
          ]
        }

        send(session, {:connection_event, {:connection_message, response}})
      end

      :ok
    end
  end

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

  test "the existing client download API supports history blobs and paths without a query", ctx do
    {blob, body} = HistoryBlob.encrypted()
    host = serve(ctx, 200, body)
    %{client: client} = history_session(host)
    ref = HistoryBlob.ref(blob)

    assert {:ok, updated, %Media.Download{ref: ^ref, bytes: bytes}} =
             ExWapp.download_media(client, ref)

    assert updated.metadata.session_pid == client.metadata.session_pid
    assert bytes == HistoryBlob.payload()
    assert hd(updated.trace).operation == :download_media
    assert_receive {:tls_request, :GET, path, _, ""}, 1000
    assert URI.parse(path).path == "/history"
    query = URI.decode_query(URI.parse(path).query)
    assert query["mms-type"] == "md-msg-hist"
    assert query["hash"] == Base.url_encode64(blob.file_enc_sha256)
  end

  test "history blobs are automatically imported, queryable and idempotent", ctx do
    {blob, body} = HistoryBlob.encrypted()
    host = serve(ctx, 200, body)
    session_ctx = history_session(host)
    jid = "15550001111@s.whatsapp.net"

    # Live traffic can precede a slower history download.
    :ok =
      ExWapp.Chat.add_message(session_ctx.store, jid, %{
        id: "live",
        text: "latest",
        from_me: false,
        timestamp: 900
      })

    enqueue_history(session_ctx, blob)

    assert_receive {:ex_wapp_session, :history_sync, :completed,
                    %{sync_type: :RECENT, chunk_order: 2, conversations: 1, messages: 2}},
                   2000

    assert {:ok, [%{id: "live"}, %{id: "history-2"}, %{id: "history-1"}]} =
             ExWapp.get_messages(session_ctx.client, jid)

    assert {:ok, %{last_message_timestamp: 900}} = ExWapp.get_chat(session_ctx.client, jid)

    assert ExWapp.Store.get(session_ctx.store, :lid_mapping)[{:lid_to_pn, "90000000011@lid"}] ==
             jid

    # A repeated chunk must not duplicate messages or discard newer local ones.
    new_host = serve(ctx, 200, body)
    Agent.update(session_ctx.conn, &%{&1 | host: new_host})
    enqueue_history(session_ctx, blob)
    assert_receive {:ex_wapp_session, :history_sync, :completed, _}, 2000

    assert {:ok, messages} = ExWapp.get_messages(session_ctx.client, jid)
    assert Enum.map(messages, & &1.id) == ["live", "history-2", "history-1"]
  end

  test "a corrupt history download reports failure and preserves the local messages", ctx do
    {blob, body} = HistoryBlob.encrypted()
    <<first, rest::binary>> = body
    host = serve(ctx, 200, <<Bitwise.bxor(first, 1), rest::binary>>)
    session_ctx = history_session(host)
    enqueue_history(session_ctx, blob)

    assert_receive {:ex_wapp_session, :history_sync, :failed, :invalid_media_hmac, _}, 2000
    assert ExWapp.Chat.list(session_ctx.store) == []
    assert ExWapp.Session.state(session_ctx.session) == :connected
    refute_received {:ex_wapp_session, :history_sync, :completed, _}
  end

  test "history persistence errors are not reported as completed", ctx do
    {blob, body} = HistoryBlob.encrypted()
    host = serve(ctx, 200, body)
    store = FaultStore.new()
    FaultStore.arm(store, :begin_batch, {:return, {:error, :disk_full}})
    session_ctx = history_session(host, store)
    enqueue_history(session_ctx, blob)

    assert_receive {:ex_wapp_session, :history_sync, :failed, :disk_full, _}, 2000
    assert ExWapp.Chat.list(store) == []
    refute_received {:ex_wapp_session, :history_sync, :completed, _}
    stop_supervised!(:history_session)
  end

  test "a final history flush failure never emits a successful completion", ctx do
    # No conversation batches: this failure belongs to the chunk's final flush.
    payload =
      %WAWebProtobufsHistorySync.HistorySync{syncType: :NON_BLOCKING_DATA}
      |> WAWebProtobufsHistorySync.HistorySync.encode!()
      |> elem(0)
      |> IO.iodata_to_binary()
      |> :zlib.compress()

    {blob, body} = HistoryBlob.encrypted(payload)
    host = serve(ctx, 200, body)
    store = FaultStore.new()
    FaultStore.arm(store, :finish_batch, {:return, {:error, :disk_full}})
    session_ctx = history_session(host, store)
    enqueue_history(session_ctx, blob)

    assert_receive {:ex_wapp_session, :history_sync, :failed, :disk_full, _}, 2000
    refute_received {:ex_wapp_session, :history_sync, :completed, _}
    assert ExWapp.Session.state(session_ctx.session) == :connected
    stop_supervised!(:history_session)
  end

  test "malformed downloaded history does not create local chats", ctx do
    {blob, body} = HistoryBlob.encrypted(:zlib.compress(<<10, 255>>))
    host = serve(ctx, 200, body)
    session_ctx = history_session(host)
    enqueue_history(session_ctx, blob)

    assert_receive {:ex_wapp_session, :history_sync, :failed, _, _}, 2000
    assert ExWapp.Chat.list(session_ctx.store) == []
    refute_received {:ex_wapp_session, :history_sync, :completed, _}
  end

  test "a history task crash is observable and leaves the session usable" do
    session_ctx = history_session(nil)
    {blob, _} = HistoryBlob.encrypted()
    enqueue_history(session_ctx, blob)
    assert_receive {:media_conn_requested, _}, 1000
    [operation] = :sys.get_state(session_ctx.session).send_coordinator.operations |> Map.values()
    Process.exit(operation.pid, :kill)

    assert_receive {:ex_wapp_session, :history_sync, :failed, {:send_worker_exited, :killed}, _},
                   1000

    assert ExWapp.Session.state(session_ctx.session) == :connected
    assert ExWapp.Chat.list(session_ctx.store) == []
    refute_received {:ex_wapp_session, :history_sync, :completed, _}
  end

  test "disconnect cancels a pending history task and ignores its late completion" do
    session_ctx = history_session(nil)
    {blob, _} = HistoryBlob.encrypted()
    enqueue_history(session_ctx, blob)
    assert_receive {:media_conn_requested, _}, 1000

    [operation] = :sys.get_state(session_ctx.session).send_coordinator.operations |> Map.values()
    assert {:history_sync, _} = operation.label
    monitor = Process.monitor(operation.pid)

    # The session remains responsive while the history task waits for the CDN lookup.
    assert ExWapp.Session.state(session_ctx.session) == :connected
    :ok = ExWapp.Session.disconnect(session_ctx.session)
    assert_receive {:DOWN, ^monitor, :process, _, _}, 1000
    assert ExWapp.Session.state(session_ctx.session) == :idle

    send(
      session_ctx.session,
      {:send_worker_finished, operation.pid, {:ok, %{conversations: 99, messages: 99}}}
    )

    assert ExWapp.Session.state(session_ctx.session) == :idle
    assert ExWapp.Chat.list(session_ctx.store) == []
    refute_received {:ex_wapp_session, :history_sync, :completed, _}
  end

  defp history_session(host, store \\ ExWapp.Store.Memory.new()) do
    id = "history-blob-#{System.unique_integer([:positive])}"
    :ok = ExWapp.subscribe(id)

    session =
      start_supervised!(%{
        id: :history_session,
        start:
          {ExWapp.Session, :start_link,
           [[store: store, session_id: id, transport: MediaConnection, reconnect: false]]}
      })

    owner = self()
    conn = start_supervised!({Agent, fn -> %{session: session, host: host, owner: owner} end})
    :sys.replace_state(session, &%{&1 | conn: conn, status: :connected, transport_ready?: true})

    client =
      ExWapp.new(
        store: store,
        transport: ExWapp.Client.Transport.Session,
        metadata: %{session_pid: session}
      )

    %{session: session, conn: conn, client: client, store: store}
  end

  defp enqueue_history(ctx, blob) do
    message = %{message_content_type: :protocol, protocol_payload: HistoryBlob.notification(blob)}
    state = :sys.get_state(ctx.session)

    assert Sync.ingest(
             message,
             ctx.session,
             state,
             "15550009999@s.whatsapp.net",
             "blob-notification",
             true
           ) == state
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
