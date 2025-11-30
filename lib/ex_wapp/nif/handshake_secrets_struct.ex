defmodule ExWappNif.HandshakeSecrets do
  @moduledoc false

  defstruct [
    :write_key,
    :read_key,
    :handshake_hash,
    :handshake_ck,
    :server_static,
    :server_certificate
  ]
end
