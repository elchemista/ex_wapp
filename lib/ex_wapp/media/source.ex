defmodule ExWapp.Domains.Media.Source do
  @moduledoc false

  alias ExWapp.Media.Upload

  @doc false
  def read(source, opts \\ []) do
    limit = Keyword.get(opts, :max_bytes, 64 * 1024 * 1024)

    if is_integer(limit) and limit > 0,
      do: read_bounded(source, limit),
      else: {:error, :invalid_media_limit}
  end

  defp read_bounded({:bytes, bytes}, limit) when is_binary(bytes) do
    if byte_size(bytes) <= limit, do: {:ok, bytes}, else: {:error, :media_too_large}
  end

  defp read_bounded({:path, path}, limit) when is_binary(path) do
    with {:ok, %{type: :regular, size: size}} <- File.stat(path),
         true <- size <= limit do
      case File.open(path, [:read, :binary], fn file ->
             case IO.binread(file, limit + 1) do
               :eof -> {:ok, <<>>}
               bytes when is_binary(bytes) -> read_bounded({:bytes, bytes}, limit)
               {:error, _} = error -> error
             end
           end) do
        {:ok, result} -> result
        {:error, _} = error -> error
      end
    else
      false -> {:error, :media_too_large}
      {:ok, _} -> {:error, :invalid_media_file}
      {:error, _} = error -> error
    end
  end

  defp read_bounded(%Upload{}, _limit), do: {:error, :already_uploaded}
  defp read_bounded(other, _limit), do: {:error, {:unsupported_media_source, other}}
end
