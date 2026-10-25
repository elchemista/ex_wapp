defmodule ExWapp.LiveFlowTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias ExWapp.{Chat, Live, Session, Store}
  alias ExWapp.Session.Supervisor, as: Sessions
  alias ExWapp.Test.ProtocolTransport
  @moduletag :tmp_dir
  @moduletag capture_log: true

  defmodule Renderer do
    @behaviour ExWapp.QR.Renderer

    def render(payload, opts) do
      send(Keyword.fetch!(opts, :owner), {:rendered, payload, opts})
      {:ok, ["<svg>", "configured renderer", "</svg>"]}
    end
  end

  defmodule FailingRenderer do
    @behaviour ExWapp.QR.Renderer

    def render(_payload, opts) do
      case Keyword.fetch!(opts, :failure) do
        :raise -> raise "renderer failed"
        :throw -> throw(:renderer_failed)
        :exit -> exit(:renderer_failed)
        :invalid -> :unexpected
        :invalid_data -> {:ok, %{not: :iodata}}
        :error -> {:error, :render_failed}
      end
    end
  end

  setup %{tmp_dir: dir} do
    id = "live-#{System.unique_integer([:positive])}"
    path = Path.join(dir, "session.etf")
    store = Store.Ets.new(path: path)
    local = ExWapp.Test.SignalDevice.new()

    :ok =
      Store.persist(store, %{
        pairing: %{device: %{jid: "15550002222:1@s.whatsapp.net"}},
        signal:
          Map.merge(local.local_prekeys, %{identity_key: local.identity, registration_id: 123})
      })

    :ok = Store.close(store)

    {:ok, session} =
      Sessions.start_session(id,
        store: {Store.Ets, path: path},
        transport: ProtocolTransport,
        reconnect: false,
        auto_connect: true,
        runtime: [app_state: [initial_sync_enabled: false]]
      )

    store = GenServer.call(session, :get_store)
    on_exit(fn -> Sessions.stop_session(id) end)
    await(fn -> Session.state(session) == :connected end)
    conn = GenServer.call(session, :get_conn)

    %{
      session: session,
      store: store,
      id: id,
      path: path,
      qr: Path.join(dir, "qr.svg"),
      conn: conn
    }
  end

  test "live runner reuses a connected session and prints its stored chats and groups", ctx do
    Chat.get_or_create(ctx.store, "1555@s.whatsapp.net", name: "Alice")
    Chat.get_or_create(ctx.store, "123@g.us", name: "Project")
    options = [store_path: ctx.path, qr_path: ctx.qr, replace_existing: false, sync_wait_ms: 1]

    output =
      capture_io(fn ->
        assert {:ok, result} = Live.run(Keyword.put(options, :session_id, ctx.id))
        assert result.session == ctx.session
        assert length(result.chats) == 2
        assert [%Chat{jid: "123@g.us"}] = result.groups
        assert {ctx.id, ctx.session} in Live.list_sessions()
      end)

    assert output =~ "Stored pairing found"
    assert output =~ "Alice"
    assert output =~ "Project"
    refute File.exists?(ctx.qr)
    assert Process.alive?(ctx.conn)
  end

  test "single-session runner can reuse an existing registry name without connecting twice",
       ctx do
    name = {:via, Registry, {ExWapp.Session.Registry, ctx.id}}

    output =
      capture_io(fn ->
        assert {:ok, result} =
                 Live.run(
                   name: name,
                   replace_existing: false,
                   store_path: ctx.path,
                   qr_path: ctx.qr,
                   sync_wait_ms: 0
                 )

        assert result.session == ctx.session
        assert result.session_name == name
        assert result.chats == []
        assert result.groups == []
      end)

    assert output =~ "No chats found"
    assert output =~ "No groups found"
    assert Process.alive?(ctx.conn)
  end

  test "live runner prevents sharing one persistent store between different sessions", ctx do
    path = Path.relative_to_cwd(ctx.path)

    output =
      capture_io(fn ->
        assert {:error, {:store_path_in_use, actual, id}} =
                 Live.run_session("another-session", store_path: path, qr_path: ctx.qr)

        assert actual == ctx.path
        assert id == ctx.id
      end)

    assert output =~ "Store path:"
    assert :error == Sessions.get_session("another-session")
    assert :ok = Live.stop_session(ctx.id)
    refute Process.alive?(ctx.session)
    assert {:error, :not_found} = Live.stop_session(ctx.id)
  end

  test "QR pairing writes the configured renderer output and accepts the signed identity", ctx do
    Store.transaction(ctx.store, &Map.delete(&1, :pairing))
    owner = self()

    output =
      capture_io(fn ->
        task =
          Task.async(fn ->
            Live.run_session(ctx.id,
              store_path: ctx.path,
              qr_path: ctx.qr,
              qr_renderer: Renderer,
              qr_options: [owner: owner, format: :svg],
              replace_existing: false,
              sync_wait_ms: 0
            )
          end)

        await(fn -> map_size(:sys.get_state(ctx.session).qr_subscribers) > 0 end)
        send_pair_reference(ctx)
        await(fn -> File.exists?(ctx.qr) end)
        assert File.read!(ctx.qr) == "<svg>configured renderer</svg>"
        assert_receive {:rendered, payload, [owner: ^owner, format: :svg]}
        assert payload =~ "2@local-pairing-reference,"
        node = ExWapp.Test.SignalDevice.pairing_success(ctx.store, "15550002222:1@s.whatsapp.net")
        :ok = ProtocolTransport.inject(ctx.conn, node)
        assert {:ok, %{session: session}} = Task.await(task)
        assert session == ctx.session

        assert to_string(Store.get(ctx.store, :pairing).device["jid"]) ==
                 "15550002222:1@s.whatsapp.net"
      end)

    assert output =~ "QR updated"
    assert output =~ "Pairing complete"
  end

  test "single-session runner uses the application renderer and passes its options", ctx do
    previous = Application.fetch_env(:ex_wapp, :qr_renderer)
    Application.put_env(:ex_wapp, :qr_renderer, Renderer)
    on_exit(fn -> restore_renderer(previous) end)
    Store.transaction(ctx.store, &Map.delete(&1, :pairing))
    owner = self()

    capture_io(fn ->
      task =
        Task.async(fn ->
          Live.run(
            name: {:via, Registry, {ExWapp.Session.Registry, ctx.id}},
            store_path: ctx.path,
            qr_path: ctx.qr,
            qr_options: [owner: owner],
            replace_existing: false,
            sync_wait_ms: 0
          )
        end)

      await(fn -> map_size(:sys.get_state(ctx.session).qr_subscribers) > 0 end)
      send_pair_reference(ctx)
      assert_receive {:rendered, _, [owner: ^owner]}, 1_000
      await(fn -> File.exists?(ctx.qr) end)
      node = ExWapp.Test.SignalDevice.pairing_success(ctx.store, "15550002222:1@s.whatsapp.net")
      :ok = ProtocolTransport.inject(ctx.conn, node)
      assert {:ok, _} = Task.await(task)
    end)
  end

  test "an explicit renderer overrides the application default", ctx do
    previous = Application.fetch_env(:ex_wapp, :qr_renderer)
    Application.put_env(:ex_wapp, :qr_renderer, FailingRenderer)
    on_exit(fn -> restore_renderer(previous) end)
    Store.transaction(ctx.store, &Map.delete(&1, :pairing))

    # A file write error proves the explicit renderer ran; the default would raise.
    assert {:error, :eisdir} =
             pairing_result(ctx,
               qr_renderer: Renderer,
               qr_options: [owner: self()],
               qr_path: Path.dirname(ctx.qr)
             )

    assert_receive {:rendered, _, _}
  end

  test "missing or invalid renderers return errors and release the pairing subscription", ctx do
    Store.transaction(ctx.store, &Map.delete(&1, :pairing))

    assert {:error, :qr_renderer_not_configured} = pairing_result(ctx, qr_renderer: nil)

    for renderer <- ["invalid", MissingQRRenderer, String] do
      assert {:error, {:invalid_qr_renderer, ^renderer}} =
               pairing_result(ctx, qr_renderer: renderer)
    end

    refute File.exists?(ctx.qr)
  end

  test "renderer failures are returned without saving or logging the pairing payload", ctx do
    Store.transaction(ctx.store, &Map.delete(&1, :pairing))

    for {failure, expected} <- [
          error: :render_failed,
          invalid: :invalid_qr_renderer_response,
          invalid_data: :invalid_qr_renderer_response,
          throw: {:throw, :renderer_failed},
          exit: {:exit, :renderer_failed}
        ] do
      assert {:error, ^expected} =
               pairing_result(ctx, qr_renderer: FailingRenderer, qr_options: [failure: failure])
    end

    assert {:error, %RuntimeError{message: "renderer failed"}} =
             pairing_result(ctx, qr_renderer: FailingRenderer, qr_options: [failure: :raise])

    refute File.exists?(ctx.qr)
  end

  test "QR pairing returns the server rejection and releases its subscription", ctx do
    Store.transaction(ctx.store, &Map.delete(&1, :pairing))

    capture_io(fn ->
      task =
        Task.async(fn ->
          Live.run_session(ctx.id, store_path: ctx.path, qr_path: ctx.qr, replace_existing: false)
        end)

      await(fn -> map_size(:sys.get_state(ctx.session).qr_subscribers) > 0 end)

      :ok =
        ProtocolTransport.inject(ctx.conn, %ExWapp.Binary.Node{
          tag: "failure",
          attrs: %{"reason" => "403"}
        })

      assert {:error, _} = Task.await(task)
    end)

    await(fn -> map_size(:sys.get_state(ctx.session).qr_subscribers) == 0 end)
    assert Store.get(ctx.store, :pairing) == nil
  end

  test "pairing deadline is checked before saving a newly delivered reference", ctx do
    Store.transaction(ctx.store, &Map.delete(&1, :pairing))

    capture_io(fn ->
      task =
        Task.async(fn ->
          Live.run_session(ctx.id,
            store_path: ctx.path,
            qr_path: ctx.qr,
            replace_existing: false,
            pair_timeout_ms: 0
          )
        end)

      await(fn -> map_size(:sys.get_state(ctx.session).qr_subscribers) > 0 end)
      send_pair_reference(ctx)
      assert {:error, :pair_timeout} = Task.await(task)
    end)

    refute File.exists?(ctx.qr)
  end

  defp send_pair_reference(ctx) do
    alias ExWapp.Binary.Node

    ProtocolTransport.inject(ctx.conn, %Node{
      tag: "iq",
      attrs: %{"id" => "pair", "type" => "set"},
      content: [
        %Node{
          tag: "pair-device",
          content: [%Node{tag: "ref", content: "2@local-pairing-reference"}]
        }
      ]
    })
  end

  defp pairing_result(ctx, opts) do
    options =
      Keyword.merge(
        [store_path: ctx.path, qr_path: ctx.qr, replace_existing: false, sync_wait_ms: 0],
        opts
      )

    parent = self()
    ref = make_ref()

    output =
      capture_io(fn ->
        task = Task.async(fn -> Live.run_session(ctx.id, options) end)
        await(fn -> map_size(:sys.get_state(ctx.session).qr_subscribers) > 0 end)
        send_pair_reference(ctx)
        send(parent, {ref, Task.await(task)})
      end)

    await(fn -> map_size(:sys.get_state(ctx.session).qr_subscribers) == 0 end)
    refute output =~ "2@local-pairing-reference"
    assert_receive {^ref, result}
    result
  end

  defp restore_renderer({:ok, renderer}),
    do: Application.put_env(:ex_wapp, :qr_renderer, renderer)

  defp restore_renderer(:error), do: Application.delete_env(:ex_wapp, :qr_renderer)

  defp await(fun, attempts \\ 200)
  defp await(fun, 0), do: assert(fun.())

  defp await(fun, attempts),
    do:
      if(fun.(),
        do: :ok,
        else:
          (
            Process.sleep(5)
            await(fun, attempts - 1)
          )
      )
end
