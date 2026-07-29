defmodule ExWapp.Test.FlushProbeStore do
  @moduledoc false

  alias ExWapp.Store.Memory

  defstruct [:memory, :owner, :flush_result]

  @spec new(keyword()) :: %__MODULE__{}
  def new(opts) do
    %__MODULE__{
      memory: Memory.new(initial_data: Keyword.get(opts, :initial_data, %{})),
      owner: Keyword.fetch!(opts, :owner),
      flush_result: Keyword.get(opts, :flush_result, :ok)
    }
  end

  @spec load(%__MODULE__{}) :: {:ok, map()}
  def load(%__MODULE__{memory: memory}), do: Memory.load(memory)

  @spec get(%__MODULE__{}, atom(), term()) :: term()
  def get(%__MODULE__{memory: memory}, key, default), do: Memory.get(memory, key, default)

  @spec get_and_update(%__MODULE__{}, atom(), term(), (term() -> {term(), term()})) :: term()
  def get_and_update(%__MODULE__{memory: memory}, key, default, updater) do
    Memory.get_and_update(memory, key, default, updater)
  end

  @spec flush(%__MODULE__{}) :: :ok | {:error, term()}
  def flush(%__MODULE__{owner: owner, flush_result: result}) do
    send(owner, :retry_store_flushed)
    result
  end

  @spec stop(%__MODULE__{}) :: :ok
  def stop(%__MODULE__{memory: memory}), do: Memory.stop(memory)
end
