defmodule ExWapp.Log do
  @moduledoc false

  @safe_attr_keys MapSet.new(["class", "code", "count", "offline", "type", "xmlns"])

  # Attributes that identify *which* conversation or stanza a line is about.
  # These are fingerprinted rather than blanked, because `[FILTERED]` is a
  # constant and therefore joins to nothing: with it, `[SEND] Sent encrypted
  # message to <ref>` and the `<message to="...">` node it produced cannot be
  # tied together, and diagnosing a dropped stanza means enabling plaintext
  # logging globally — which prints every contact's real phone number.
  # A fingerprint is stable for a given value, so the same identity can be
  # followed across the send path, the wire node, and the ack that returns,
  # while remaining useless to anyone who does not already know the value.
  @correlatable_attr_keys MapSet.new([
                            "from",
                            "id",
                            "jid",
                            "participant",
                            "recipient",
                            "sender_pn",
                            "to"
                          ])

  # Local vendor change: with `config :ex_wapp, :unsafe_plaintext_logs?, true`
  # JIDs and stanza attributes are logged verbatim instead of fingerprinted.
  # Redaction hides the addressing detail that decides whether the server
  # accepts or silently drops a stanza, which cannot be diagnosed from a
  # SHA-256 prefix. Off by default; only switch it on to capture a failing
  # exchange, since it prints real phone numbers and JIDs.
  @spec unsafe_plaintext_logs?() :: boolean()
  def unsafe_plaintext_logs?, do: Application.get_env(:ex_wapp, :unsafe_plaintext_logs?, false)

  @spec reference(term()) :: String.t()
  def reference(nil), do: "[none]"
  def reference(""), do: "[none]"

  # A JID reaching here as a struct must fingerprint identically to the same
  # JID reaching here as a string, or the two halves of a send stop correlating
  # for the exact identities worth correlating. Matched structurally to avoid a
  # compile-time dependency on the JID module.
  def reference(%{__struct__: ExWapp.JID} = jid), do: reference(ExWapp.JID.to_string(jid))

  def reference(value) do
    if unsafe_plaintext_logs?() do
      "[plain:#{inspect(value)}]"
    else
      fingerprint =
        value
        |> :erlang.term_to_binary()
        |> then(&:crypto.hash(:sha256, &1))
        |> Base.encode16(case: :lower)
        |> binary_part(0, 12)

      "[redacted:#{fingerprint}]"
    end
  end

  @spec references(list()) :: String.t()
  def references(values) when is_list(values) do
    "count=#{length(values)} refs=#{inspect(Enum.map(values, &reference/1))}"
  end

  @spec attrs(map() | term()) :: map() | String.t()
  def attrs(attrs) when is_map(attrs) do
    Map.new(attrs, fn {key, value} ->
      cond do
        unsafe_plaintext_logs?() -> {key, value}
        MapSet.member?(@safe_attr_keys, to_string(key)) -> {key, safe_scalar(value)}
        MapSet.member?(@correlatable_attr_keys, to_string(key)) -> {key, reference(value)}
        true -> {key, "[FILTERED]"}
      end
    end)
  end

  def attrs(attrs) do
    if unsafe_plaintext_logs?(), do: attrs, else: "[FILTERED]"
  end

  @spec term_summary(term()) :: String.t()
  def term_summary(value) when is_binary(value), do: "binary(bytes=#{byte_size(value)})"
  def term_summary(value) when is_map(value), do: "map(keys=#{map_size(value)})"
  def term_summary(value) when is_list(value), do: "list(length=#{length(value)})"
  def term_summary(value) when is_tuple(value), do: "tuple(size=#{tuple_size(value)})"
  def term_summary(value) when is_atom(value), do: Atom.to_string(value)
  def term_summary(_value), do: "term"

  @doc false
  @spec safe_term(term()) :: term()
  def safe_term(value), do: sanitize(value, 0)

  @doc false
  @spec reason(term()) :: String.t()
  def reason(value), do: value |> safe_term() |> inspect(limit: 50)

  defp safe_scalar(value) when is_atom(value) or is_integer(value) or is_boolean(value), do: value

  defp safe_scalar(value) when is_binary(value) and byte_size(value) <= 64 do
    if Regex.match?(~r/\A[a-zA-Z0-9_.:-]+\z/, value), do: value, else: "[FILTERED]"
  end

  defp safe_scalar(value) when is_binary(value), do: "[binary:#{byte_size(value)}]"
  defp safe_scalar(_value), do: "[FILTERED]"

  defp sanitize(value, _depth)
       when is_nil(value) or is_atom(value) or is_integer(value) or is_float(value),
       do: value

  defp sanitize(value, _depth) when is_binary(value) do
    {:binary, byte_size(value), reference(value)}
  end

  defp sanitize(_value, depth) when depth >= 4, do: :redacted_nested_term

  defp sanitize(%module{}, _depth), do: {:struct, module}

  defp sanitize(value, depth) when is_tuple(value) do
    value
    |> Tuple.to_list()
    |> Enum.map(&sanitize(&1, depth + 1))
    |> List.to_tuple()
  end

  defp sanitize(value, _depth) when is_map(value), do: {:map, map_size(value)}
  defp sanitize(value, _depth) when is_list(value), do: {:list, length(value)}
  defp sanitize(value, _depth) when is_pid(value), do: :pid
  defp sanitize(value, _depth) when is_reference(value), do: :reference
  defp sanitize(value, _depth) when is_function(value), do: :function
  defp sanitize(_value, _depth), do: :term
end
