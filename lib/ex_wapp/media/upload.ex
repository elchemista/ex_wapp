defmodule ExWapp.Media.Upload do
  @moduledoc """
  Metadata returned after uploading encrypted media to WhatsApp.

  The upload struct contains everything needed to embed a media reference into
  an outbound protobuf message.
  """

  defstruct [
    :type,
    :url,
    :direct_path,
    :handle,
    :object_id,
    :media_key,
    :file_sha256,
    :file_enc_sha256,
    :file_length,
    :media_key_timestamp
  ]

  @type t :: %__MODULE__{
          type: ExWapp.Media.media_type(),
          url: binary() | nil,
          direct_path: binary() | nil,
          handle: binary() | nil,
          object_id: binary() | nil,
          media_key: binary(),
          file_sha256: binary(),
          file_enc_sha256: binary(),
          file_length: non_neg_integer(),
          media_key_timestamp: non_neg_integer() | nil
        }
end
