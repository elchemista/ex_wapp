defmodule ExWapp.Store.Codec do
  @moduledoc """
  Versioned codec for persisted ExWapp store data.

  The codec writes a gzipped JSON envelope with explicit type tags so session
  state survives cold boots without depending on raw BEAM term decoding.
  """

  @magic "EXWAPPJ2"
  @codec "ex_wapp_json_v2"
  @version 2

  alias ExWapp.JSON

  @type decode_result :: {:ok, map()} | {:error, :unknown_codec | :invalid_store_blob}

  @spec encode(map()) :: {:ok, binary()} | {:error, term()}
  def encode(data) when is_map(data) do
    envelope = %{
      "codec" => @codec,
      "version" => @version,
      "data" => encode_value(data)
    }

    with {:ok, json} <- JSON.encode(envelope) do
      {:ok, @magic <> :zlib.gzip(json)}
    end
  rescue
    exception in [ArgumentError, Protocol.UndefinedError] ->
      {:error, {:unsupported_store_term, Exception.message(exception)}}
  end

  def encode(_data), do: {:error, :invalid_store_map}

  @spec decode(binary()) :: decode_result()
  def decode(<<@magic, compressed::binary>>) do
    with {:ok, json} <- gunzip(compressed),
         {:ok, envelope} <- JSON.decode(json),
         {:ok, data} <- decode_envelope(envelope) do
      {:ok, data}
    else
      {:error, _reason} -> {:error, :invalid_store_blob}
    end
  end

  def decode(blob) when is_binary(blob), do: {:error, :unknown_codec}

  @spec encoded?(binary()) :: boolean()
  def encoded?(<<@magic, _rest::binary>>), do: true
  def encoded?(_blob), do: false

  defp gunzip(compressed) do
    {:ok, :zlib.gunzip(compressed)}
  rescue
    _exception -> {:error, :invalid_store_blob}
  end

  defp decode_envelope(%{"codec" => @codec, "version" => @version, "data" => data}) do
    with {:ok, decoded} <- decode_value(data),
         true <- is_map(decoded) do
      {:ok, decoded}
    else
      false -> {:error, :invalid_store_blob}
      {:error, _reason} = error -> error
    end
  end

  defp decode_envelope(_envelope), do: {:error, :invalid_store_blob}

  defp encode_value(value) when is_nil(value), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_integer(value), do: value
  defp encode_value(value) when is_float(value), do: value

  defp encode_value(value) when is_binary(value),
    do: %{"$t" => "bin", "v" => Base.encode64(value)}

  defp encode_value(value) when is_atom(value),
    do: %{"$t" => "atom", "v" => Atom.to_string(value)}

  defp encode_value(value) when is_list(value), do: Enum.map(value, &encode_value/1)

  defp encode_value(value) when is_tuple(value) do
    %{"$t" => "tuple", "v" => value |> Tuple.to_list() |> Enum.map(&encode_value/1)}
  end

  defp encode_value(%module{} = value) do
    %{
      "$t" => "struct",
      "m" => Atom.to_string(module),
      "v" => encode_value(Map.from_struct(value))
    }
  end

  defp encode_value(value) when is_map(value) do
    %{
      "$t" => "map",
      "v" =>
        Enum.map(value, fn {key, item} ->
          [encode_value(key), encode_value(item)]
        end)
    }
  end

  defp encode_value(value) do
    raise ArgumentError, "unsupported store term #{inspect(value, limit: 10)}"
  end

  defp decode_value(nil), do: {:ok, nil}
  defp decode_value(value) when is_boolean(value), do: {:ok, value}
  defp decode_value(value) when is_integer(value), do: {:ok, value}
  defp decode_value(value) when is_float(value), do: {:ok, value}

  defp decode_value(value) when is_list(value) do
    decode_list(value)
  end

  defp decode_value(%{"$t" => "bin", "v" => encoded}) when is_binary(encoded) do
    case Base.decode64(encoded) do
      {:ok, decoded} -> {:ok, decoded}
      :error -> {:error, :invalid_store_blob}
    end
  end

  defp decode_value(%{"$t" => "atom", "v" => name}) when is_binary(name) do
    {:ok, String.to_atom(name)}
  end

  defp decode_value(%{"$t" => "tuple", "v" => encoded_items}) when is_list(encoded_items) do
    with {:ok, decoded_items} <- decode_list(encoded_items) do
      {:ok, List.to_tuple(decoded_items)}
    end
  end

  defp decode_value(%{"$t" => "map", "v" => encoded_entries}) when is_list(encoded_entries) do
    with {:ok, entries} <- decode_entries(encoded_entries) do
      {:ok, Map.new(entries)}
    end
  end

  defp decode_value(%{"$t" => "struct", "m" => module_name, "v" => encoded_fields})
       when is_binary(module_name) do
    with {:ok, module} <- load_module(module_name),
         {:ok, fields} <- decode_value(encoded_fields),
         true <- is_map(fields),
         {:ok, struct_value} <- build_struct(module, fields) do
      {:ok, struct_value}
    else
      false -> {:error, :invalid_store_blob}
      {:error, _reason} = error -> error
    end
  end

  defp decode_value(_value), do: {:error, :invalid_store_blob}

  defp decode_list(values) when is_list(values) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, acc} ->
      case decode_value(value) do
        {:ok, decoded} -> {:cont, {:ok, [decoded | acc]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, decoded} -> {:ok, Enum.reverse(decoded)}
      {:error, _reason} = error -> error
    end
  end

  defp decode_entries(entries) when is_list(entries) do
    Enum.reduce_while(entries, {:ok, []}, fn
      [encoded_key, encoded_value], {:ok, acc} ->
        with {:ok, key} <- decode_value(encoded_key),
             {:ok, value} <- decode_value(encoded_value) do
          {:cont, {:ok, [{key, value} | acc]}}
        else
          {:error, _reason} = error -> {:halt, error}
        end

      _other, _acc ->
        {:halt, {:error, :invalid_store_blob}}
    end)
    |> case do
      {:ok, decoded} -> {:ok, Enum.reverse(decoded)}
      {:error, _reason} = error -> error
    end
  end

  defp load_module(module_name) when is_binary(module_name) do
    module = String.to_atom(module_name)

    if Code.ensure_loaded?(module) and function_exported?(module, :__struct__, 0) do
      {:ok, module}
    else
      {:error, :invalid_store_blob}
    end
  end

  defp build_struct(module, fields) when is_atom(module) and is_map(fields) do
    {:ok, struct(module, fields)}
  rescue
    _exception -> {:error, :invalid_store_blob}
  end
end
