defmodule ExWapp.Session.OutboundQueueTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary.Node
  alias ExWapp.Session.OutboundQueue

  defmodule Transport do
    def send_node(conn, node), do: dispatch(conn, {:node, node})
    def restart_stream(conn), do: dispatch(conn, :restart)

    defp dispatch(conn, item) do
      {owner, mode} = Agent.get(conn, & &1)

      case mode do
        :ok ->
          send(owner, {:sent, item})
          :ok

        :error ->
          {:error, :closed}

        :raise ->
          raise "transport unavailable"
      end
    end
  end

  setup do
    owner = self()
    conn = start_supervised!({Agent, fn -> {owner, :ok} end})
    %{conn: conn}
  end

  test "retains FIFO commands while disconnected and resumes them on a new connection", ctx do
    queue = start_queue()
    first = message_node("first")
    second = message_node("second")
    OutboundQueue.enqueue_node(queue, first)
    OutboundQueue.restart_stream(queue)
    assert :queue.len(:sys.get_state(queue).queue) == 2
    refute_received {:sent, _}

    OutboundQueue.set_conn(queue, ctx.conn)
    assert_receive {:sent, {:node, ^first}}
    assert_receive {:sent, :restart}
    OutboundQueue.clear_conn(queue)
    OutboundQueue.enqueue_node(queue, second)
    assert :sys.get_state(queue).conn == nil
    refute_received {:sent, _}
    OutboundQueue.set_conn(queue, ctx.conn)
    assert_receive {:sent, {:node, ^second}}
    assert :queue.is_empty(:sys.get_state(queue).queue)
  end

  test "a full queue rejects the new command without losing earlier commands", ctx do
    queue = start_queue(max_size: 2)
    [first, second, rejected] = Enum.map(["first", "second", "rejected"], &message_node/1)
    Enum.each([first, second, rejected], &OutboundQueue.enqueue_node(queue, &1))
    assert_receive {:outbound_error, {:send_node, ^rejected}, :queue_full}
    OutboundQueue.set_conn(queue, ctx.conn)
    assert_receive {:sent, {:node, ^first}}
    assert_receive {:sent, {:node, ^second}}
    assert :queue.is_empty(:sys.get_state(queue).queue)
    refute_received {:sent, _}
  end

  test "drop-oldest policy retains the most recent commands in order", ctx do
    queue = start_queue(max_size: 2, drop_policy: :drop_oldest)
    [first, second, third] = Enum.map(["first", "second", "third"], &message_node/1)
    Enum.each([first, second, third], &OutboundQueue.enqueue_node(queue, &1))
    OutboundQueue.set_conn(queue, ctx.conn)
    assert_receive {:sent, {:node, ^second}}
    assert_receive {:sent, {:node, ^third}}
    assert :queue.is_empty(:sys.get_state(queue).queue)
    refute_received {:sent, {:node, ^first}}
  end

  test "a protocol ACK preempts the newest queued message and is dispatched first", ctx do
    queue = start_queue(max_size: 2)
    first = message_node("first")
    dropped = message_node("dropped")
    ack = %Node{tag: "ack", attrs: %{"id" => "inbound"}}
    OutboundQueue.enqueue_node(queue, first)
    OutboundQueue.enqueue_node(queue, dropped)
    OutboundQueue.enqueue_priority_node(queue, ack)
    assert_receive {:outbound_error, {:send_node, ^dropped}, :preempted_by_protocol_ack}
    OutboundQueue.set_conn(queue, ctx.conn)
    assert_receive {:sent, {:node, ^ack}}
    assert_receive {:sent, {:node, ^first}}
    assert :queue.is_empty(:sys.get_state(queue).queue)
    refute_received {:sent, {:node, ^dropped}}
  end

  test "a backlog larger than one batch drains on subsequent timer ticks", ctx do
    queue = start_queue(flush_batch_size: 2, flush_tick_ms: 1)
    nodes = Enum.map(1..7, &message_node(to_string(&1)))
    Enum.each(nodes, &OutboundQueue.enqueue_node(queue, &1))
    OutboundQueue.set_conn(queue, ctx.conn)

    for node <- nodes, do: assert_receive({:sent, {:node, ^node}}, 1_000)
    assert :queue.is_empty(:sys.get_state(queue).queue)
    refute_received {:sent, _}
  end

  for mode <- [:error, :raise], command <- [:node, :restart] do
    @mode mode
    @command command

    test "retains #{@command} after transport #{@mode} and retries on reconnect", ctx do
      queue = start_queue()
      owner = self()
      Agent.update(ctx.conn, fn _ -> {owner, @mode} end)
      OutboundQueue.set_conn(queue, ctx.conn)

      item =
        case @command do
          :node ->
            message = message_node("retry")
            OutboundQueue.enqueue_node(queue, message)
            {:send_node, message}

          :restart ->
            OutboundQueue.restart_stream(queue)
            :restart_stream
        end

      assert_receive {:outbound_error, ^item, reason}

      if @mode == :raise,
        do: assert({:exception, %RuntimeError{}} = reason),
        else: assert(reason == :closed)

      assert :queue.len(:sys.get_state(queue).queue) == 1
      assert Process.alive?(queue)
      Agent.update(ctx.conn, fn _ -> {owner, :ok} end)
      OutboundQueue.set_conn(queue, ctx.conn)

      expected = if @command == :node, do: {:node, message_node("retry")}, else: :restart
      assert_receive {:sent, ^expected}
      assert :queue.is_empty(:sys.get_state(queue).queue)
      refute_received {:sent, _}
    end
  end

  defp start_queue(opts \\ []) do
    start_supervised!(
      {OutboundQueue, Keyword.merge([session: self(), transport: Transport], opts)}
    )
  end

  defp message_node(id), do: %Node{tag: "message", attrs: %{"id" => id}}
end
