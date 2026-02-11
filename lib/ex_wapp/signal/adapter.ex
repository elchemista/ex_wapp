defmodule ExWapp.Signal.Adapter do
  @moduledoc """
  Pure Elixir Signal adapter.

  Historically this project had both Rust NIF and Elixir implementations.
  To keep protocol debugging predictable, the adapter now exposes a single
  implementation: `ExWapp.Signal.Session`.
  """

  require Logger

  alias ExWapp.Signal.Keys
  alias ExWapp.Signal.Session

  @type impl :: :elixir

  @spec get_impl() :: impl()
  def get_impl, do: :elixir

  @spec set_impl(:elixir | :native) :: :ok
  def set_impl(:elixir), do: :ok

  def set_impl(:native) do
    Logger.warning("[SIGNAL] :native implementation was removed, staying on :elixir")
    :ok
  end

  @spec impl_module() :: module()
  def impl_module, do: Session

  # ============================================================================
  # Session Management
  # ============================================================================

  @doc """
  Creates a new session using X3DH key agreement.
  """
  @spec create_session(map(), map()) :: {:ok, map(), binary()} | {:error, term()}
  def create_session(local_identity, remote_bundle) do
    Session.create_session(local_identity, remote_bundle)
  end

  @doc """
  Encrypts a message using the session.

  ## Options
  - `:is_prekey` - Whether to wrap in PreKeySignalMessage (default: false)
  - `:bundle_info` - Bundle info for PreKeySignalMessage (required if is_prekey)

  Returns `{:ok, ciphertext, updated_session}`.
  """
  @spec encrypt(map(), binary(), keyword()) :: {:ok, binary(), map()} | {:error, term()}
  def encrypt(session, plaintext, opts \\ []) do
    is_prekey = Keyword.get(opts, :is_prekey, false)
    bundle_info = Keyword.get(opts, :bundle_info, %{})

    if is_prekey do
      Session.encrypt_prekey_message(session, plaintext, bundle_info)
    else
      Session.encrypt(session, plaintext)
    end
  end

  @doc """
  Encrypts a first message (PreKeySignalMessage).

  Convenience wrapper for `encrypt/3` with `is_prekey: true`.
  """
  @spec encrypt_prekey_message(map(), binary(), map()) ::
          {:ok, binary(), map()} | {:error, term()}
  def encrypt_prekey_message(session, plaintext, bundle_info) do
    encrypt(session, plaintext, is_prekey: true, bundle_info: bundle_info)
  end

  @doc """
  Decrypts a regular Signal message.
  """
  @spec decrypt(map(), binary()) :: {:ok, binary(), map()} | {:error, term()}
  def decrypt(session, ciphertext) do
    Session.decrypt(session, ciphertext)
  end

  @doc """
  Decrypts a PreKeySignalMessage (initial message from new sender).
  """
  @spec decrypt_prekey_message(binary(), map(), map()) ::
          {:ok, binary(), map()} | {:error, term()}
  def decrypt_prekey_message(ciphertext, local_identity, local_prekeys) do
    Session.decrypt_prekey_message(ciphertext, local_identity, local_prekeys)
  end

  @doc """
  Decrypts a PreKeySignalMessage using an existing session.
  """
  @spec decrypt_prekey_message_with_session(map(), binary()) ::
          {:ok, binary(), map()} | {:error, term()}
  def decrypt_prekey_message_with_session(session, ciphertext) do
    Session.decrypt_prekey_message_with_session(session, ciphertext)
  end

  # ============================================================================
  # Key Generation
  # ============================================================================

  @doc """
  Generate a new Curve25519 key pair.
  """
  @spec generate_key_pair() :: {binary(), binary()}
  def generate_key_pair do
    Keys.generate_key_pair() |> then(fn kp -> {kp.public, kp.private} end)
  end

  @doc """
  Generate a signed prekey with XEdDSA signature.
  """
  @spec generate_signed_prekey(binary()) :: {binary(), binary(), binary()}
  def generate_signed_prekey(identity_private) do
    kp = Keys.generate_key_pair()
    sig = Keys.sign(identity_private, kp.public)
    {kp.public, kp.private, sig}
  end

  @doc """
  Verify XEdDSA signature.
  """
  @spec verify_signature(binary(), binary(), binary()) :: boolean()
  def verify_signature(public_key, message, signature) do
    Keys.verify(public_key, message, signature)
  end

  # ============================================================================
  # Debug Helpers
  # ============================================================================

  @doc """
  Debug: dump a message's structure.
  """
  @spec debug_message(binary()) :: String.t()
  def debug_message(message) do
    "Signal message bytes=#{byte_size(message)} hex=#{Base.encode16(message, case: :lower)}"
  end

  @doc """
  Returns info about the current implementation.
  """
  @spec info() :: map()
  def info do
    %{
      impl: :elixir,
      module: Session,
      native_available: false,
      elixir_available: true
    }
  end
end
