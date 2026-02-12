defmodule ExWapp.MapPath do
  @moduledoc """
  Map path helpers that tolerate both atom and string keys.
  """

  @spec get(map() | nil, [atom() | String.t()]) :: term() | nil
  def get(data, path) when is_list(path) do
    Enum.reduce_while(path, data, fn key, acc ->
      case fetch_key(acc, key) do
        {:ok, value} -> {:cont, value}
        :error -> {:halt, nil}
      end
    end)
  end

  def get(_data, _path), do: nil

  @spec first(map() | nil, [[atom() | String.t()]]) :: term() | nil
  def first(data, paths) when is_list(paths) do
    Enum.find_value(paths, fn path ->
      value = get(data, path)
      if is_nil(value), do: nil, else: value
    end)
  end

  def first(_data, _paths), do: nil

  defp fetch_key(map, key) when is_map(map) do
    key
    |> key_variants()
    |> Enum.find_value(:error, fn candidate ->
      if Map.has_key?(map, candidate) do
        {:ok, Map.get(map, candidate)}
      else
        nil
      end
    end)
  end

  defp fetch_key(_value, _key), do: :error

  defp key_variants(key) when is_atom(key), do: [key, Atom.to_string(key)]

  defp key_variants(key) when is_binary(key) do
    case safe_to_existing_atom(key) do
      nil -> [key]
      atom -> [key, atom]
    end
  end

  defp key_variants(key), do: [key]

  defp safe_to_existing_atom(value) when is_binary(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError -> nil
  end
end
