defmodule ExWapp.Media.Ref do
  @moduledoc """
  Downloadable media reference extracted from an inbound message or upload.

  This is the minimum information required to fetch encrypted media bytes and
  verify/decrypt them locally.
  """

  defstruct [
    :type,
    :url,
    :direct_path,
    :media_key,
    :file_sha256,
    :file_enc_sha256,
    :file_length,
    :media_key_timestamp,
    :mimetype,
    metadata: %{}
  ]

  @type t :: %__MODULE__{
          type: ExWapp.Media.media_type(),
          url: binary() | nil,
          direct_path: binary() | nil,
          media_key: binary() | nil,
          file_sha256: binary() | nil,
          file_enc_sha256: binary() | nil,
          file_length: non_neg_integer() | nil,
          media_key_timestamp: non_neg_integer() | nil,
          mimetype: binary() | nil,
          metadata: map()
        }
end
