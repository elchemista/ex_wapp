defmodule ExWapp.PrivacyToken do
  @moduledoc """
  Validates trusted-contact privacy tokens used by direct-message sends.

  WhatsApp rotates these tokens in seven-day buckets and accepts the current
  bucket plus the previous three. Tokens outside that window must not be
  attached to outbound stanzas.
  """

  @bucket_duration_seconds 7 * 24 * 60 * 60
  @bucket_count 4

  @type tctoken_record :: %{
          required(:token) => binary(),
          required(:timestamp) => non_neg_integer() | String.t(),
          optional(:sender_timestamp) => non_neg_integer() | String.t() | nil
        }

  @spec valid?(term(), integer()) :: boolean()
  def valid?(record, now_seconds \\ System.system_time(:second))

  def valid?(%{token: token, timestamp: timestamp}, now_seconds)
      when is_binary(token) and byte_size(token) > 0 and is_integer(now_seconds) do
    case normalize_timestamp(timestamp) do
      {:ok, token_timestamp} -> token_timestamp >= cutoff_timestamp(now_seconds)
      :error -> false
    end
  end

  def valid?(_record, _now_seconds), do: false

  @doc """
  Stores `record` under every JID in `jids`, keeping whichever token is newer.

  One contact reaches the store under several JID aliases (phone number and LID),
  and the same token arrives through more than one path — a notification and a
  history sync chunk. Overwriting blindly would let a stale copy win.
  """
  @spec put_newer(map(), [binary()], map()) :: map()
  def put_newer(tokens, jids, record) do
    Enum.reduce(jids, tokens, fn jid, acc ->
      Map.update(acc, jid, record, &keep_newer(record, &1))
    end)
  end

  @spec keep_newer(map(), map()) :: map()
  defp keep_newer(candidate, existing) do
    if newer_or_equal?(candidate, existing), do: candidate, else: existing
  end

  @spec newer_or_equal?(term(), term()) :: boolean()
  def newer_or_equal?(candidate, existing) do
    case {record_timestamp(candidate), record_timestamp(existing)} do
      {{:ok, candidate_timestamp}, {:ok, existing_timestamp}} ->
        candidate_timestamp >= existing_timestamp

      {{:ok, _candidate_timestamp}, :error} ->
        true

      _ ->
        false
    end
  end

  @spec normalize_timestamp(term()) :: {:ok, non_neg_integer()} | :error
  def normalize_timestamp(timestamp) when is_integer(timestamp) and timestamp >= 0,
    do: {:ok, timestamp}

  def normalize_timestamp(timestamp) when is_binary(timestamp) do
    case Integer.parse(timestamp) do
      {parsed, ""} when parsed >= 0 -> {:ok, parsed}
      _ -> :error
    end
  end

  def normalize_timestamp(_timestamp), do: :error

  @spec cutoff_timestamp(integer()) :: integer()
  def cutoff_timestamp(now_seconds) when is_integer(now_seconds) do
    current_bucket = div(now_seconds, @bucket_duration_seconds)
    (current_bucket - (@bucket_count - 1)) * @bucket_duration_seconds
  end

  defp record_timestamp(%{timestamp: timestamp}), do: normalize_timestamp(timestamp)
  defp record_timestamp(_record), do: :error
end
