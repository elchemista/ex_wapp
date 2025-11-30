defmodule ExWappNif.NoiseKeys do
  @moduledoc false

  @enforce_keys [:write_key, :read_key]
  defstruct [:write_key, :read_key]

  @type t :: %__MODULE__{
          write_key: binary(),
          read_key: binary()
        }
end
