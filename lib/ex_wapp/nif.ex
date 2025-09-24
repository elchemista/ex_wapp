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
        write_key: nif.write_key,
        read_key: nif.read_key,
        handshake_hash: nif.handshake_hash,
        handshake_salt: nif.handshake_ck,
        server_static: nif.server_static,
        server_certificate: nif.server_certificate
      }
    end
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
  def noise_cipher_new(_keys, _hash), do: :erlang.nif_error(:nif_not_loaded)
  def noise_encrypt(_res, _pt), do: :erlang.nif_error(:nif_not_loaded)
  def noise_decrypt(_res, _ct), do: :erlang.nif_error(:nif_not_loaded)
end
