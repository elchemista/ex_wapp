defmodule ExWapp.Store.FileSync do
  @moduledoc false

  # A synced temporary file is not enough to publish a new filename durably.
  # Incremental mode fails explicitly if the filesystem cannot sync directories.
  def directory(path) do
    case :file.open(String.to_charlist(Path.dirname(path)), [:read, :raw, :directory]) do
      {:ok, directory} ->
        try do
          :file.sync(directory)
        after
          :file.close(directory)
        end

      {:error, _} = error ->
        error
    end
  end

  def preserve_snapshot(path) do
    case File.read(path) do
      {:ok, data} ->
        backup = path <> ".pre-history"
        temporary = backup <> ".#{System.unique_integer([:positive])}.tmp"

        try do
          with {:ok, :ok} <-
                 File.open(temporary, [:write, :binary, :exclusive], fn file ->
                   with :ok <- File.chmod(temporary, 0o600),
                        :ok <- IO.binwrite(file, data),
                        do: :file.sync(file)
                 end),
               :ok <- publish_backup(temporary, backup, data) do
            directory(backup)
          else
            {:ok, {:error, _} = error} -> error
            {:error, _} = error -> error
          end
        after
          File.rm(temporary)
        end

      {:error, :enoent} ->
        :ok

      {:error, _} = error ->
        error
    end
  end

  defp publish_backup(temporary, backup, data) do
    # Publish only a complete, synced inode, without replacing a prior backup.
    case File.ln(temporary, backup) do
      :ok ->
        :ok

      {:error, :eexist} ->
        case File.read(backup) do
          {:ok, ^data} -> :ok
          {:ok, _} -> {:error, :snapshot_backup_conflict}
          {:error, _} = error -> error
        end

      {:error, _} = error ->
        error
    end
  end
end
