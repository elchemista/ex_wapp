defmodule ExWapp.Proto.BoundedInflate do
  @moduledoc false
  @max_compressed_bytes 64 * 1024 * 1024
  @max_plain_bytes 128 * 1024 * 1024

  def max_plain_bytes, do: @max_plain_bytes

  def inflate(data) when byte_size(data) > @max_compressed_bytes,
    do: {:error, :history_payload_too_large}

  def inflate(data) do
    z = :zlib.open()

    try do
      :ok = :zlib.inflateInit(z)

      with {:ok, chunks} <- drain(z, :zlib.safeInflate(z, data), [], 0) do
        # `finished` means input consumed; inflateEnd also verifies stream end.
        :ok = :zlib.inflateEnd(z)
        {:ok, chunks |> Enum.reverse() |> IO.iodata_to_binary()}
      end
    rescue
      _ -> {:error, :invalid_history_compression}
    catch
      _, _ -> {:error, :invalid_history_compression}
    after
      :zlib.close(z)
    end
  end

  defp drain(z, {status, output}, chunks, size) when status in [:continue, :finished] do
    size = size + IO.iodata_length(output)

    cond do
      size > @max_plain_bytes -> {:error, :history_payload_too_large}
      status == :finished -> {:ok, [output | chunks]}
      true -> drain(z, :zlib.safeInflate(z, []), [output | chunks], size)
    end
  end

  defp drain(_z, _result, _chunks, _size), do: {:error, :invalid_history_compression}
end
