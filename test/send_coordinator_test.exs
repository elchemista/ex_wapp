defmodule ExWapp.Session.SendCoordinatorTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Session.SendCoordinator
  alias ExWapp.Session.Worker.NodeHandler

  test "routes an IQ response only to the registered worker" do
    parent = self()
    worker_one = forwarding_worker(parent, :worker_one)
    worker_two = forwarding_worker(parent, :worker_two)
    monitor_one = Process.monitor(worker_one)
    monitor_two = Process.monitor(worker_two)

    coordinator =
      SendCoordinator.new()
      |> SendCoordinator.register(worker_one, monitor_one, "one")
      |> SendCoordinator.register(worker_two, monitor_two, "two")

    assert {:ok, coordinator} = SendCoordinator.register_iq(coordinator, worker_one, "iq-one")
    assert {:ok, coordinator} = SendCoordinator.register_iq(coordinator, worker_two, "iq-two")

    node = %Binary.Node{
      tag: "iq",
      attrs: %{"id" => "iq-one", "type" => "result"},
      content: nil
    }

    state = %{
      send_coordinator: coordinator,
      pending_iqs: %{},
      stats: %{messages_received: 0, errors: 0}
    }

    assert {next_state, []} = NodeHandler.safe_handle_node(node, state)
    assert_receive {:worker_one, {:prekey_response, "iq-one", ^node}}
    refute_receive {:worker_two, _message}, 50
    assert SendCoordinator.iq_route_count(next_state.send_coordinator) == 1

    Process.exit(worker_one, :kill)
    Process.exit(worker_two, :kill)
  end

  test "completion and DOWN remove every IQ route owned by the operation" do
    worker = spawn(fn -> Process.sleep(:infinity) end)
    monitor = Process.monitor(worker)

    coordinator =
      SendCoordinator.new()
      |> SendCoordinator.register(worker, monitor, "send")

    assert {:ok, coordinator} = SendCoordinator.register_iq(coordinator, worker, "iq-1")
    assert {:ok, coordinator} = SendCoordinator.register_iq(coordinator, worker, "iq-2")
    assert SendCoordinator.operation_count(coordinator) == 1
    assert SendCoordinator.iq_route_count(coordinator) == 2

    assert {:ok, operation, completed} = SendCoordinator.complete(coordinator, worker)
    assert operation.label == "send"
    assert SendCoordinator.operation_count(completed) == 0
    assert SendCoordinator.iq_route_count(completed) == 0

    coordinator = SendCoordinator.register(SendCoordinator.new(), worker, monitor, "send")
    assert {:ok, ^operation, down} = SendCoordinator.down(coordinator, monitor)
    assert SendCoordinator.operation_count(down) == 0

    Process.exit(worker, :kill)
  end

  test "rejects unknown workers and duplicate IQ IDs" do
    worker_one = spawn(fn -> Process.sleep(:infinity) end)
    worker_two = spawn(fn -> Process.sleep(:infinity) end)
    monitor_one = Process.monitor(worker_one)
    monitor_two = Process.monitor(worker_two)

    coordinator = SendCoordinator.register(SendCoordinator.new(), worker_one, monitor_one, "one")

    assert {:error, :unknown_send_worker} =
             SendCoordinator.register_iq(coordinator, worker_two, "iq")

    assert {:ok, coordinator} = SendCoordinator.register_iq(coordinator, worker_one, "iq")

    coordinator = SendCoordinator.register(coordinator, worker_two, monitor_two, "two")

    assert {:error, {:duplicate_iq_id, "iq"}} =
             SendCoordinator.register_iq(coordinator, worker_two, "iq")

    Process.exit(worker_one, :kill)
    Process.exit(worker_two, :kill)
  end

  defp forwarding_worker(parent, tag) do
    spawn(fn ->
      receive do
        message -> send(parent, {tag, message})
      end
    end)
  end
end
