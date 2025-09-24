# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc

defmodule ExWapp.Noise.HandshakeSecrets do
  @enforce_keys [
    :write_key,
    :read_key,
    :handshake_hash,
    :handshake_salt,
    :server_static,
    :server_certificate
  ]
  defstruct [
    :write_key,
    :read_key,
    :handshake_hash,
    :handshake_salt,
    :server_static,
    :server_certificate
  ]

  @type t :: %__MODULE__{
          write_key: binary(),
          read_key: binary(),
          handshake_hash: binary(),
          handshake_salt: binary(),
          server_static: binary(),
          server_certificate: binary()
        }

  @spec new(map() | keyword()) :: t()
  def new(attrs) when is_map(attrs) do
    %__MODULE__{
      write_key: fetch_binary!(attrs, :write_key),
      read_key: fetch_binary!(attrs, :read_key),
      handshake_hash: fetch_binary!(attrs, :handshake_hash),
      handshake_salt: fetch_binary!(attrs, :handshake_salt),
      server_static: fetch_binary!(attrs, :server_static),
      server_certificate: fetch_binary!(attrs, :server_certificate)
    }
  end

  def new(attrs) when is_list(attrs) do
    attrs
    |> Map.new()
    |> new()
  end

  @spec from_nif(%ExWappNif.HandshakeSecrets{}) :: t()
  def from_nif(%ExWappNif.HandshakeSecrets{} = secrets) do
    new(%{
      write_key: secrets.write_key,
      read_key: secrets.read_key,
      handshake_hash: secrets.handshake_hash,
      handshake_salt: secrets.handshake_ck,
      server_static: secrets.server_static,
      server_certificate: secrets.server_certificate
    })
  end

  defp fetch_binary!(attrs, key) do
    attrs
    |> Map.fetch!(key)
    |> ensure_binary()
  end

  defp ensure_binary(value) when is_binary(value), do: value
  defp ensure_binary(value) when is_list(value), do: :erlang.list_to_binary(value)
  defp ensure_binary(value), do: value
end
