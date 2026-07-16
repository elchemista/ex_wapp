defmodule ExWapp.Session.SendCoordinator do
  @moduledoc false

  defmodule Operation do
    @moduledoc false

    @enforce_keys [:pid, :monitor, :label]
    defstruct [:pid, :monitor, :label, :from]

    @type t :: %__MODULE__{
            pid: pid(),
            monitor: reference(),
            label: term(),
            from: GenServer.from() | nil
          }
  end

  defstruct operations: %{}, monitors: %{}, iq_routes: %{}

  @type t :: %__MODULE__{
          operations: %{pid() => Operation.t()},
          monitors: %{reference() => pid()},
          iq_routes: %{String.t() => pid()}
        }

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec register(t(), pid(), reference(), term(), GenServer.from() | nil) :: t()
  def register(%__MODULE__{} = coordinator, pid, monitor, label, from \\ nil)
      when is_pid(pid) and is_reference(monitor) do
    operation = %Operation{pid: pid, monitor: monitor, label: label, from: from}

    %{
      coordinator
      | operations: Map.put(coordinator.operations, pid, operation),
        monitors: Map.put(coordinator.monitors, monitor, pid)
    }
  end

  @spec registered?(t(), pid()) :: boolean()
  def registered?(%__MODULE__{operations: operations}, pid) when is_pid(pid),
    do: Map.has_key?(operations, pid)

  @spec register_iq(t(), pid(), String.t()) :: {:ok, t()} | {:error, term()}
  def register_iq(%__MODULE__{} = coordinator, pid, iq_id)
      when is_pid(pid) and is_binary(iq_id) and iq_id != "" do
    cond do
      not registered?(coordinator, pid) ->
        {:error, :unknown_send_worker}

      Map.has_key?(coordinator.iq_routes, iq_id) ->
        {:error, {:duplicate_iq_id, iq_id}}

      true ->
        {:ok, %{coordinator | iq_routes: Map.put(coordinator.iq_routes, iq_id, pid)}}
    end
  end

  def register_iq(%__MODULE__{}, _pid, _iq_id), do: {:error, :invalid_iq_route}

  @spec take_iq(t(), String.t()) :: {:ok, pid(), t()} | {:error, :not_found, t()}
  def take_iq(%__MODULE__{} = coordinator, iq_id) when is_binary(iq_id) do
    case Map.pop(coordinator.iq_routes, iq_id) do
      {nil, routes} -> {:error, :not_found, %{coordinator | iq_routes: routes}}
      {pid, routes} -> {:ok, pid, %{coordinator | iq_routes: routes}}
    end
  end

  @spec complete(t(), pid()) :: {:ok, Operation.t(), t()} | {:error, :not_found, t()}
  def complete(%__MODULE__{} = coordinator, pid) when is_pid(pid) do
    case Map.pop(coordinator.operations, pid) do
      {nil, operations} ->
        {:error, :not_found, %{coordinator | operations: operations}}

      {%Operation{} = operation, operations} ->
        {:ok, operation,
         %{
           coordinator
           | operations: operations,
             monitors: Map.delete(coordinator.monitors, operation.monitor),
             iq_routes: drop_iq_routes(coordinator.iq_routes, pid)
         }}
    end
  end

  @spec down(t(), reference()) :: {:ok, Operation.t(), t()} | {:error, :not_found, t()}
  def down(%__MODULE__{} = coordinator, monitor) when is_reference(monitor) do
    case Map.fetch(coordinator.monitors, monitor) do
      {:ok, pid} -> complete(coordinator, pid)
      :error -> {:error, :not_found, coordinator}
    end
  end

  @spec drain(t()) :: {[Operation.t()], %{String.t() => pid()}, t()}
  def drain(%__MODULE__{} = coordinator) do
    {Map.values(coordinator.operations), coordinator.iq_routes, new()}
  end

  @spec operation_count(t()) :: non_neg_integer()
  def operation_count(%__MODULE__{operations: operations}), do: map_size(operations)

  @spec iq_route_count(t()) :: non_neg_integer()
  def iq_route_count(%__MODULE__{iq_routes: routes}), do: map_size(routes)

  @spec has_iq?(t(), String.t()) :: boolean()
  def has_iq?(%__MODULE__{iq_routes: routes}, iq_id) when is_binary(iq_id),
    do: Map.has_key?(routes, iq_id)

  defp drop_iq_routes(routes, pid) do
    routes
    |> Enum.reject(fn {_iq_id, worker_pid} -> worker_pid == pid end)
    |> Map.new()
  end
end
