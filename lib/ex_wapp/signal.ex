defmodule ExWapp.Signal do
  @moduledoc """
  Placeholder for the Signal protocol implementation.

  The WhatsApp Web stack uses X3DH for session setup and the Double Ratchet
  for transport messages. The scaffolding below defines the API shape the
  rest of the client will use – actual cryptographic logic still needs to
  be ported.
  """

  @type peer_id :: binary()
  @type plaintext :: binary()
  @type ciphertext :: binary()

  @doc """
  Initialises local identity and prekey material.
  """
  @spec bootstrap(keyword()) :: {:ok, map()} | {:error, term()}
  def bootstrap(_opts), do: {:error, :not_implemented}

  @doc """
  Encrypts a protobuf payload for the given peer.
  """
  @spec encrypt(peer_id(), plaintext()) :: {:ok, ciphertext(), map()} | {:error, term()}
  def encrypt(_peer, _msg), do: {:error, :not_implemented}

  @doc """
  Decrypts an incoming ciphertext for the active session.
  """
  @spec decrypt(peer_id(), ciphertext()) :: {:ok, plaintext(), map()} | {:error, term()}
  def decrypt(_peer, _cipher), do: {:error, :not_implemented}
end
