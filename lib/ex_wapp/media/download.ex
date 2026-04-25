defmodule ExWapp.Media.Download do
  @moduledoc """
  Downloaded and decrypted media payload.

  The raw bytes stay separate from the reference so callers can still inspect
  the original transport metadata after download.
  """

  defstruct [:ref, :bytes, :mimetype, metadata: %{}]

  @type t :: %__MODULE__{
          ref: ExWapp.Media.Ref.t(),
          bytes: binary(),
          mimetype: binary() | nil,
          metadata: map()
        }
end
