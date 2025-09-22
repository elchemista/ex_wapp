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
  @spec bootstrap(map()) :: {:ok, map()} | {:error, term()}
  def bootstrap(params) when is_map(params) do
    identity_seed = Map.get(params, :device_identity, <<>>)
    adv_seed = Map.get(params, :adv_device_identity, <<>>)

    identity_key = derive_key(identity_seed)
    signed_prekey = :crypto.strong_rand_bytes(32)
    one_time_prekey = :crypto.strong_rand_bytes(32)

    registration_id = :rand.uniform(65_535)

    {:ok,
     %{
       identity_key: identity_key,
       signed_prekey: signed_prekey,
       one_time_prekey: one_time_prekey,
       registration_id: registration_id,
       adv_seed: adv_seed
     }}
  end

  def bootstrap(_), do: {:error, :invalid_parameters}

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

  defp derive_key(<<>>), do: :crypto.strong_rand_bytes(32)
  defp derive_key(seed), do: :crypto.hash(:sha256, seed)
end
