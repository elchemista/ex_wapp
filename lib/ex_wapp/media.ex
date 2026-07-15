defmodule ExWapp.Media do
  @moduledoc """
  Public media helpers shared by send and receive flows.

  The media domain is split into smaller files under `lib/ex_wapp/domains/media/`
  so the public API stays easy to find while crypto, HTTP, and source-handling
  details live in focused modules.
  """

  alias ExWapp.Domains.Media.Source
  alias ExWapp.Media.Retry

  @typedoc """
  Media kinds currently supported by the high-level API.
  """
  @type media_type :: :image | :audio | :document

  @typedoc """
  Accepted media input values when sending a message.

  `{:bytes, binary}` keeps everything in memory, `{:path, path}` reads from
  disk, and `%ExWapp.Media.Upload{}` skips the upload step when the caller
  already has WhatsApp upload metadata.
  """
  @type source :: {:bytes, binary()} | {:path, Path.t()} | ExWapp.Media.Upload.t()

  @doc """
  Normalizes a send source into plaintext bytes.

  This is the boundary between the user-facing send API and the upload
  pipeline. Existing `%Upload{}` values are rejected because they already
  represent uploaded server-side media rather than local plaintext bytes.
  """
  @spec read_source(source()) :: {:ok, binary()} | {:error, term()}
  def read_source(source), do: Source.read(source)

  @doc """
  Converts upload metadata into a reusable download reference.

  The resulting `%ExWapp.Media.Ref{}` can be attached to an event payload or
  passed back into `ExWapp.download_media/3`.
  """
  @spec ref_from_upload(ExWapp.Media.Upload.t(), keyword()) :: ExWapp.Media.Ref.t()
  def ref_from_upload(%ExWapp.Media.Upload{} = upload, opts \\ []) do
    %ExWapp.Media.Ref{
      type: upload.type,
      url: upload.url,
      direct_path: upload.direct_path,
      media_key: upload.media_key,
      file_sha256: upload.file_sha256,
      file_enc_sha256: upload.file_enc_sha256,
      file_length: upload.file_length,
      media_key_timestamp: upload.media_key_timestamp,
      mimetype: Keyword.get(opts, :mimetype),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc "Builds the authenticated `server-error` receipt used to re-request expired media."
  defdelegate build_retry_receipt(
                msg_id,
                own_jid,
                chat_jid,
                from_me,
                participant_jid,
                media_key
              ),
              to: Retry,
              as: :build_receipt

  @doc "Decrypts a `mediaretry` notification with the original message media key."
  defdelegate decode_retry_notification(node, media_key),
    to: Retry,
    as: :decode_notification

  @doc "Derives the media-retry wrapping key from a media key."
  defdelegate retry_key(media_key), to: Retry
end
