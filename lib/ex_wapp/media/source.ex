defmodule ExWapp.Domains.Media.Source do
  @moduledoc false

  alias ExWapp.Media.Upload

  @doc false
  @spec read(ExWapp.Media.source(), keyword()) :: {:ok, binary()} | {:error, term()}
  def read(source, opts \\ []) do
    limit = Keyword.get(opts, :max_bytes, 64 * 1024 * 1024)

    if is_integer(limit) and limit > 0,
      do: read_bounded(source, limit),
      else: {:error, :invalid_media_limit}
  end

  @spec read_bounded(term(), pos_integer()) :: {:ok, binary()} | {:error, term()}
  defp read_bounded({:bytes, bytes}, limit) when is_binary(bytes) do
    if byte_size(bytes) <= limit, do: {:ok, bytes}, else: {:error, :media_too_large}
  end

  defp read_bounded({:path, path}, limit) when is_binary(path) do
    with {:ok, %{type: :regular, size: size}} <- File.stat(path),
         true <- size <= limit do
      read_file(path, limit)
    else
      false -> {:error, :media_too_large}
      {:ok, _} -> {:error, :invalid_media_file}
      {:error, _} = error -> error
    end
  end

  defp read_bounded(%Upload{}, _limit), do: {:error, :already_uploaded}
  defp read_bounded(other, _limit), do: {:error, {:unsupported_media_source, other}}

  @spec read_file(Path.t(), pos_integer()) :: {:ok, binary()} | {:error, term()}
  defp read_file(path, limit) do
    case File.open(path, [:read, :binary], &read_file_bytes(&1, limit)) do
      {:ok, result} -> result
      {:error, _} = error -> error
    end
  end

  @spec read_file_bytes(IO.device(), pos_integer()) :: {:ok, binary()} | {:error, term()}
  defp read_file_bytes(file, limit) do
    case IO.binread(file, limit + 1) do
      :eof -> {:ok, <<>>}
      bytes when is_binary(bytes) -> read_bounded({:bytes, bytes}, limit)
      {:error, _} = error -> error
    end
  end
end
