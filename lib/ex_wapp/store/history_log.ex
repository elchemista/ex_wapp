defmodule ExWapp.Store.HistoryLog do
  @moduledoc false
  alias ExWapp.Store.{Codec, FileSync, MessageTable}
  @magic "EXWAPPH1\n"
  @max_record 128 * 1024 * 1024
  @compact_growth 64 * 1024 * 1024

  @spec load(Path.t(), MessageTable.t(), boolean()) :: :ok | {:error, term()}
  def load(path, table, repair_tail? \\ true) do
    modes = if repair_tail?, do: [:read, :write, :binary, :raw], else: [:read, :binary, :raw]

    case :file.open(String.to_charlist(path), modes) do
      {:ok, file} ->
        try do
          case :file.read(file, byte_size(@magic)) do
            {:ok, @magic} -> replay(file, table, byte_size(@magic), repair_tail?)
            _ -> {:error, :invalid_history_log}
          end
        after
          :file.close(file)
        end

      {:error, _} = error ->
        error
    end
  end

  @spec flush(Path.t(), MessageTable.t(), non_neg_integer()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def flush(path, table, baseline) do
    dirty = :ets.tab2list(table.dirty_table)

    with :ok <- append_changes(path, table, dirty),
         {:ok, stat} <- File.stat(path) do
      result =
        if stat.size > baseline * 2 + @compact_growth,
          do: compact(path, table),
          else: {:ok, baseline}

      case result do
        {:ok, size} ->
          :ets.delete_all_objects(table.dirty_table)
          {:ok, size}

        error ->
          error
      end
    end
  end

  @spec compact(Path.t(), MessageTable.t()) :: {:ok, non_neg_integer()} | {:error, term()}
  def compact(path, table) do
    tmp = path <> ".tmp." <> Integer.to_string(System.unique_integer([:positive, :monotonic]))

    with :ok <- write_compacted_file(tmp, table),
         :ok <- File.rename(tmp, path),
         :ok <- FileSync.directory(path),
         {:ok, stat} <- File.stat(path) do
      {:ok, stat.size}
    else
      error ->
        File.rm(tmp)
        error
    end
  end

  defp write_compacted_file(path, table) do
    case :file.open(String.to_charlist(path), [:write, :binary, :raw, :exclusive]) do
      {:ok, file} ->
        try do
          with :ok <- File.chmod(path, 0o600),
               :ok <- :file.write(file, @magic),
               :ok <-
                 write_table(file, :ets.select(table.table, [{{:"$1", :"$2"}, [], [:"$_"]}], 128)) do
            :file.sync(file)
          end
        after
          :file.close(file)
        end

      error ->
        error
    end
  end

  defp write_table(_file, :"$end_of_table"), do: :ok

  defp write_table(file, {rows, continuation}) do
    changes = Enum.map(rows, fn {{jid, _ts, id}, message} -> {jid, id, message} end)
    with :ok <- write_record(file, changes), do: write_table(file, :ets.select(continuation))
  end

  defp append_changes(_path, _table, []), do: :ok

  defp append_changes(path, table, dirty) do
    case :file.open(String.to_charlist(path), [:read, :write, :binary, :raw]) do
      {:ok, file} ->
        try do
          with {:ok, offset} <- :file.position(file, :eof) do
            append_from_offset(file, table, dirty, offset)
          end
        after
          :file.close(file)
        end

      error ->
        error
    end
  end

  defp append_from_offset(file, table, dirty, offset) do
    result = with :ok <- write_dirty_chunks(file, table, dirty), do: :file.sync(file)

    case result do
      :ok -> :ok
      error -> rollback_append(file, offset, error)
    end
  end

  defp write_dirty_chunks(file, table, dirty) do
    dirty
    |> Enum.chunk_every(128)
    |> Enum.reduce_while(:ok, fn rows, :ok ->
      changes =
        Enum.map(rows, fn {{jid, id}} -> {jid, id, MessageTable.find(table, jid, id)} end)

      case write_record(file, changes) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp rollback_append(file, offset, error) do
    rollback =
      with {:ok, _} <- :file.position(file, offset),
           :ok <- :file.truncate(file),
           do: :file.sync(file)

    case rollback do
      :ok -> error
      {:error, reason} -> {:error, {:history_rollback_failed, reason}}
    end
  end

  defp write_record(file, changes) do
    with {:ok, payload} <- Codec.encode(%{changes: changes}) do
      if byte_size(payload) <= @max_record,
        do: :file.write(file, [<<byte_size(payload)::32, :erlang.crc32(payload)::32>>, payload]),
        else: {:error, :history_record_too_large}
    end
  end

  defp replay(file, table, offset, repair?) do
    case :file.read(file, 8) do
      :eof ->
        :ok

      {:ok, <<length::32, checksum::32>>} when length <= @max_record ->
        read_record(file, table, length, checksum, offset, repair?)

      {:ok, <<_length::32, _checksum::32>>} ->
        {:error, :history_record_too_large}

      {:ok, _short} ->
        repair_tail(file, offset, repair?)

      error ->
        error
    end
  end

  defp read_record(file, table, length, checksum, offset, repair?) do
    case :file.read(file, length) do
      {:ok, payload} when byte_size(payload) == length ->
        replay_record(file, table, payload, checksum, offset + 8 + length, repair?)

      :eof ->
        repair_tail(file, offset, repair?)

      {:ok, _short} ->
        repair_tail(file, offset, repair?)

      error ->
        error
    end
  end

  defp replay_record(file, table, payload, checksum, next_offset, repair?) do
    with true <- :erlang.crc32(payload) == checksum,
         {:ok, %{changes: changes}} when is_list(changes) <- Codec.decode(payload),
         :ok <- apply_changes(table, changes) do
      replay(file, table, next_offset, repair?)
    else
      _ -> {:error, :corrupt_history_record}
    end
  end

  defp apply_changes(table, changes) do
    Enum.reduce_while(changes, :ok, fn
      {jid, id, nil}, :ok when is_binary(jid) and is_binary(id) ->
        MessageTable.delete(table, jid, [id])
        {:cont, :ok}

      {jid, id, %{id: id} = message}, :ok when is_binary(jid) and is_binary(id) ->
        MessageTable.upsert(table, jid, [message])
        {:cont, :ok}

      _, :ok ->
        {:halt, {:error, :invalid_history_change}}
    end)
  end

  defp repair_tail(_file, _offset, false), do: :ok

  defp repair_tail(file, offset, true) do
    with {:ok, _} <- :file.position(file, offset),
         :ok <- :file.truncate(file),
         do: :file.sync(file)
  end
end
