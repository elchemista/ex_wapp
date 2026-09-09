defmodule ExWapp.ConnectionRecoveryIntegrationTest do
  use ExUnit.Case, async: true
  alias ExWapp.{Session, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Test.ProtocolTransport

  defmodule IntermittentTransport do
    def start_link(opts) do
      store = Keyword.fetch!(opts, :store)
      owner = Store.get(store, :test_peer).owner

      failure =
        Store.get_and_update(store, :transport_failures, [], fn
          [action | rest] -> {action, rest}
          [] -> {nil, []}
        end)

      send(owner, {:connection_attempt, failure})

      case failure do
        :raise -> raise "socket unavailable"
        :exit -> exit(:socket_unavailable)
        :error -> {:error, :econnrefused}
        nil -> ProtocolTransport.start_link(opts)
      end
    end

    defdelegate send_node(pid, node), to: ProtocolTransport
  end

  test "connection failures retry and recover through a complete signed Noise handshake" do
    {session, store} = start_session([:raise, :exit, :error])

    for action <- [:raise, :exit, :error, nil],
        do: assert_receive({:connection_attempt, ^action}, 2000)

    assert_receive {:peer_authenticated, conn, _}, 2000
    await(fn -> Session.state(session) == :connected end)
    assert Store.get(store, :transport_failures) == []
    assert :ok = Session.send_typing(session, "123@s.whatsapp.net")
    assert_receive {:peer_node, ^conn, %Node{tag: "chatstate"}}, 1000
    Process.exit(conn, :kill)
    assert_receive {:connection_attempt, nil}, 2000
    assert_receive {:peer_authenticated, replacement, _}, 2000
    refute replacement == conn
    await(fn -> Session.state(session) == :connected end)
    assert Session.stats(session).reconnects >= 1
  end

  test "an external runtime owns retry decisions and a later explicit reconnect recovers" do
    {session, _} = start_session([:error], ownership: [vext_managed: true])
    assert_receive {:connection_attempt, :error}, 1000
    await(fn -> Session.state(session) == :disconnected end)
    assert :sys.get_state(session).last_disconnect_reason == {:connect_failed, :econnrefused}
    refute_receive {:connection_attempt, _}, 100
    assert :ok = Session.connect(session)
    assert_receive {:connection_attempt, nil}, 1000
    assert_receive {:peer_authenticated, conn, _}, 2000
    await(fn -> Session.state(session) == :connected end)
    send(session, {:connection_event, {:error, :temporary_noise_error}})
    send(session, {:connection_event, {:connection_binary, <<1, 2>>}})
    assert Session.state(session) == :connected
    Process.exit(conn, :kill)
    await(fn -> Session.state(session) == :disconnected end)
    refute_receive {:connection_attempt, _}, 100
  end

  defp start_session(failures, extra \\ []) do
    store =
      Store.Memory.new(
        initial_data: %{
          transport_failures: failures,
          test_peer: %{owner: self()},
          client_info: %{jid: "456:1@s.whatsapp.net"}
        }
      )

    runtime =
      Keyword.merge(
        [
          app_state: [initial_sync_enabled: false],
          reconnect: [initial_backoff_ms: 1, max_backoff_ms: 2, jitter_ms: 0],
          prekeys: [initial_prekey_count: 8]
        ],
        extra
      )

    session =
      start_supervised!(%{
        id: make_ref(),
        restart: :temporary,
        start:
          {Session, :start_link,
           [
             [
               store: store,
               session_id: "recovery-#{System.unique_integer([:positive])}",
               transport: IntermittentTransport,
               auto_connect: true,
               runtime: runtime
             ]
           ]}
      })

    {session, store}
  end

  defp await(fun, attempts \\ 200)
  defp await(fun, 0), do: assert(fun.())

  defp await(fun, attempts) do
    if fun.(),
      do: :ok,
      else:
        (
          Process.sleep(5)
          await(fun, attempts - 1)
        )
  end
end
