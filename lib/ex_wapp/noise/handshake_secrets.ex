defmodule ExWapp.Noise.HandshakeSecrets do
  @moduledoc """
  Immutable container for the transport keys and metadata derived from a Noise handshake.
  """

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

  @typep required_field ::
           :write_key
           | :read_key
           | :handshake_hash
           | :handshake_salt
           | :server_static
           | :server_certificate

  @doc """
  Builds a `t:t/0` struct from a map or keyword list.
  """
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

  @spec fetch_binary!(map(), required_field()) :: binary()
  defp fetch_binary!(attrs, key) do
    attrs
    |> Map.fetch!(key)
    |> ensure_binary()
  end

  @spec ensure_binary(term()) :: binary()
  defp ensure_binary(value) when is_binary(value), do: value
  defp ensure_binary(value) when is_list(value), do: :erlang.list_to_binary(value)

  defp ensure_binary(value) do
    raise ArgumentError,
          "expected binary-compatible handshake secret field, got: #{inspect(value)}"
  end
end
