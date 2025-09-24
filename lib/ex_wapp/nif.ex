defmodule ExWapp.Nif do
  @moduledoc false
  use Rustler,
    otp_app: :ex_wapp,
    crate: :ex_wapp_nif

  defmodule Secrets do
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

    @spec from_nif(struct()) :: t()
    def from_nif(%ExWappNif.HandshakeSecrets{} = nif) do
      %__MODULE__{
        write_key: ensure_binary(nif.write_key),
        read_key: ensure_binary(nif.read_key),
        handshake_hash: ensure_binary(nif.handshake_hash),
        handshake_salt: ensure_binary(nif.handshake_ck),
        server_static: ensure_binary(nif.server_static),
        server_certificate: ensure_binary(nif.server_certificate)
      }
    end

    defp ensure_binary(value) when is_binary(value), do: value
    defp ensure_binary(value) when is_list(value), do: :erlang.list_to_binary(value)
    defp ensure_binary(value), do: value
  end

  @spec to_secrets(struct()) :: Secrets.t()
  def to_secrets(%ExWappNif.HandshakeSecrets{} = secrets), do: Secrets.from_nif(secrets)

  # NIFs
  def generate_noise_keypair, do: :erlang.nif_error(:nif_not_loaded)
  def handshake_new(_payload, _maybe_priv), do: :erlang.nif_error(:nif_not_loaded)
  def handshake_client_finish(_state, _server_payload), do: :erlang.nif_error(:nif_not_loaded)
  def handshake_finish(_state), do: :erlang.nif_error(:nif_not_loaded)
  def pack_frame(_bin, _include_header), do: :erlang.nif_error(:nif_not_loaded)
  def unpack_frame(_bin, _expect_header), do: :erlang.nif_error(:nif_not_loaded)
  def noise_cipher_new(_write_key, _read_key, _hash), do: :erlang.nif_error(:nif_not_loaded)
  def noise_encrypt(_res, _pt), do: :erlang.nif_error(:nif_not_loaded)
  def noise_decrypt(_res, _ct), do: :erlang.nif_error(:nif_not_loaded)
end
