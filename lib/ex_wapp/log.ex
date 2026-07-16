defmodule ExWapp.Log do
  @moduledoc false

  @safe_attr_keys MapSet.new(["class", "code", "count", "offline", "type", "xmlns"])

  @spec reference(term()) :: String.t()
  def reference(nil), do: "[none]"
  def reference(""), do: "[none]"

  def reference(value) do
    fingerprint =
      value
      |> :erlang.term_to_binary()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 12)

    "[redacted:#{fingerprint}]"
  end

  @spec references(list()) :: String.t()
  def references(values) when is_list(values) do
    "count=#{length(values)} refs=#{inspect(Enum.map(values, &reference/1))}"
  end

  @spec attrs(map() | term()) :: map() | String.t()
  def attrs(attrs) when is_map(attrs) do
    Map.new(attrs, fn {key, value} ->
      if MapSet.member?(@safe_attr_keys, to_string(key)) do
        {key, safe_scalar(value)}
      else
        {key, "[FILTERED]"}
      end
    end)
  end

  def attrs(_attrs), do: "[FILTERED]"

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
