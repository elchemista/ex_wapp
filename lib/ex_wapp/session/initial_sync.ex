defmodule ExWapp.Session.InitialSync do
  @moduledoc false

  defstruct [:task, :monitor]

  @type t :: %__MODULE__{
          task: pid() | nil,
          monitor: reference() | nil
        }

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec active?(t()) :: boolean()
  def active?(%__MODULE__{task: task}), do: is_pid(task)

  @spec track(t(), pid(), reference()) :: t()
  def track(%__MODULE__{}, task, monitor) when is_pid(task) and is_reference(monitor) do
    %__MODULE__{task: task, monitor: monitor}
  end

  @spec reset(t()) :: t()
  def reset(%__MODULE__{}), do: new()
end
