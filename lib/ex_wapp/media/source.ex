defmodule ExWapp.Domains.Media.Source do
  @moduledoc false

  alias ExWapp.Media.Upload

  @doc false
  @spec read(ExWapp.Media.source()) :: {:ok, binary()} | {:error, term()}
  def read({:bytes, bytes}) when is_binary(bytes), do: {:ok, bytes}

  def read({:path, path}) when is_binary(path) do
    # File IO is intentionally isolated here so higher-level media helpers stay pure.
    File.read(path)
  end

  def read(%Upload{}), do: {:error, :already_uploaded}
  def read(other), do: {:error, {:unsupported_media_source, other}}
end
