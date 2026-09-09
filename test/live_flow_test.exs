defmodule ExWapp.LiveFlowTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias ExWapp.{Chat, Live, Session, Store}
  alias ExWapp.Session.Supervisor, as: Sessions
  alias ExWapp.Test.ProtocolTransport
  @moduletag :tmp_dir
  @moduletag capture_log: true

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

  test "QR pairing writes a usable SVG and accepts only the signed account identity", ctx do
    Store.transaction(ctx.store, &Map.delete(&1, :pairing))

    output =
      capture_io(fn ->
        task =
          Task.async(fn ->
            Live.run_session(ctx.id,
              store_path: ctx.path,
              qr_path: ctx.qr,
              replace_existing: false,
              sync_wait_ms: 0
            )
          end)

        await(fn -> map_size(:sys.get_state(ctx.session).qr_subscribers) > 0 end)
        send_pair_reference(ctx)
        await(fn -> File.exists?(ctx.qr) end)
        assert File.read!(ctx.qr) =~ "<svg"
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
