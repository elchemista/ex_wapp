defmodule ExWapp.Noise.Backend do
  @moduledoc """
  Behaviour describing the callbacks required by a Noise handshake backend.

  Backends are responsible for managing the Noise handshake and transport
  cipher lifecycle. The default implementation is pure Elixir, and alternate
  implementations can be provided by implementing this behaviour.
  """

  alias ExWapp.Noise.HandshakeSecrets

  @type handshake_state :: term()
  @type cipher_state :: term()
  @type static_key :: %{optional(:priv) => binary(), optional(:pub) => binary()}

  @callback init_handshake(binary(), static_key() | nil, keyword()) ::
              {:ok, handshake_state(), binary(), static_key() | nil} | {:error, term()}

  @callback write_client_finish(handshake_state(), binary()) ::
              {:ok, handshake_state(), binary()} | {:error, term()}

  @callback complete_handshake(handshake_state()) ::
              {:ok, HandshakeSecrets.t()} | {:error, term()}

  @callback setup_transport(HandshakeSecrets.t()) ::
              {:ok, cipher_state()} | {:error, term()}

  @callback encrypt(cipher_state(), binary(), non_neg_integer()) ::
              {:ok, cipher_state(), binary()} | {:error, term()}

  @callback decrypt(cipher_state(), binary(), non_neg_integer()) ::
              {:ok, cipher_state(), binary()} | {:error, term()}
end
