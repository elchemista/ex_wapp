defmodule ExWapp.Error.Ack do
  @moduledoc """
  Classifies the `error` attribute WhatsApp puts on a message acknowledgement.

  A rejection code answers a question the caller cannot answer any other way:
  whether to send the message again, and if so whether anything has to change
  first. Collapsing every code to `:failed` throws that away, leaving callers to
  choose between retrying a permanently refused message and giving up on a
  transient one.

  Only codes this library has direct evidence for are classified. Everything
  else is `:unknown`, which callers must treat as *not* safely retryable — an
  unrecognised rejection is far more likely to be a policy refusal that repeats
  than a blip that clears, and retrying into a refusal is how a number gets
  rate limited or banned.
  """

  @type category :: :session | :throttled | :transient | :permanent | :unknown

  @type t :: %__MODULE__{
          code: String.t(),
          category: category(),
          retriable?: boolean(),
          detail: String.t()
        }

  defstruct [:code, :category, :retriable?, :detail]

  @doc """
  Classifies a raw `error` attribute value.

  `retriable?` means "sending this message again may succeed", not "send it
  again immediately" — `:throttled` in particular requires a backoff.
  """
  @spec classify(String.t() | nil) :: t()
  def classify(code) when is_binary(code) do
    {category, retriable?, detail} = categorize(code)
    %__MODULE__{code: code, category: category, retriable?: retriable?, detail: detail}
  end

  def classify(_code), do: classify("")

  @doc "True when the send may be attempted again, possibly after repairing state."
  @spec retriable?(t()) :: boolean()
  def retriable?(%__MODULE__{retriable?: retriable?}), do: retriable?

  # The peer could not decrypt what we encrypted: our Signal session no longer
  # matches the one they are using. Documented at length in
  # `ExWapp.Signal.SessionStore.replace_prekey_candidate/3`, which exists
  # specifically because leaving a stale session as `current` makes the server
  # answer every send with this code while the peer keeps re-initiating.
  # Retriable, but only after the session is refreshed — an immediate resend
  # with the same session reproduces it exactly.
  defp categorize("463"),
    do: {:session, true, "peer session mismatch; refresh the Signal session before resending"}

  # Observed as a generic server-side refusal that clears on its own.
  defp categorize("479"), do: {:transient, true, "server rejected the stanza; retry with backoff"}

  # Stream-level conditions that also surface on acks. `node_handler` already
  # treats these as recoverable at the connection layer via
  # `transient_stream_error?/1`; the message layer should agree with it.
  defp categorize(code) when code in ["503", "515"],
    do: {:transient, true, "server temporarily unavailable; retry after reconnect"}

  defp categorize("429"), do: {:throttled, true, "rate limited; back off before resending"}

  # Authorization and addressing refusals. `node_handler` treats these as fatal
  # at the stream level; a resend cannot change the outcome.
  defp categorize(code) when code in ["401", "403"],
    do: {:permanent, false, "not authorized to message this recipient"}

  defp categorize(code) when code in ["404", "405"],
    do: {:permanent, false, "recipient or route not available"}

  defp categorize(""), do: {:unknown, false, "no error code supplied"}

  defp categorize(_code),
    do: {:unknown, false, "unrecognised rejection; treat as non-retriable until identified"}
end
