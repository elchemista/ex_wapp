defmodule ExWapp.Signal.Adapter do
  @moduledoc """
  Adapter module for Signal Protocol implementations.

  Provides a unified interface that can switch between:
  - `:native` - Rust NIF implementation (recommended, uses wacore-libsignal format)
  - `:elixir` - Pure Elixir implementation (fallback)

  ## Configuration

  Set the implementation in your config:

      config :ex_wapp, :signal_impl, :native

  Or switch at runtime:

      ExWapp.Signal.Adapter.set_impl(:elixir)

  ## Usage

      alias ExWapp.Signal.Adapter, as: Signal

      # Create session
      {:ok, session, base_key} = Signal.create_session(local_identity, remote_bundle)

      # Encrypt
      {:ok, ciphertext, session} = Signal.encrypt(session, plaintext, opts)
  """

  require Logger

  # Default to native (Rust NIF)
  @default_impl :native

  # Process dictionary key for runtime switching
  @impl_key :ex_wapp_signal_impl

  @doc """
  Gets the current Signal implementation.
  """
  @spec get_impl() :: :native | :elixir
  def get_impl do
    Process.get(@impl_key) ||
      Application.get_env(:ex_wapp, :signal_impl, @default_impl)
  end

  @doc """
  Sets the Signal implementation for the current process.
  """
  @spec set_impl(:native | :elixir) :: :ok
  def set_impl(impl) when impl in [:native, :elixir] do
    Process.put(@impl_key, impl)
    Logger.info("[SIGNAL] Switched to #{impl} implementation")
    :ok
  end

  @doc """
  Returns the implementation module for the current setting.
  """
  @spec impl_module() :: module()
  def impl_module do
    case get_impl() do
      :native -> ExWapp.Signal.NativeSession
      :elixir -> ExWapp.Signal.Session
    end
  end

  # ============================================================================
  # Session Management
  # ============================================================================

  @doc """
  Creates a new session using X3DH key agreement.

  Returns `{:ok, session, base_key}` where base_key is the ephemeral
  public key to include in PreKeySignalMessage.
  """
  @spec create_session(map(), map()) :: {:ok, map(), binary()} | {:error, term()}
  def create_session(local_identity, remote_bundle) do
    impl_module().create_session(local_identity, remote_bundle)
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
    case get_impl() do
      :native ->
        ExWapp.Signal.NativeSession.encrypt(session, plaintext, opts)

      :elixir ->
        is_prekey = Keyword.get(opts, :is_prekey, false)
        bundle_info = Keyword.get(opts, :bundle_info, %{})

        if is_prekey do
          ExWapp.Signal.Session.encrypt_prekey_message(session, plaintext, bundle_info)
        else
          ExWapp.Signal.Session.encrypt(session, plaintext)
        end
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
    impl_module().decrypt(session, ciphertext)
  end

  @doc """
  Decrypts a PreKeySignalMessage (initial message from new sender).
  """
  @spec decrypt_prekey_message(binary(), map(), map()) ::
          {:ok, binary(), map()} | {:error, term()}
  def decrypt_prekey_message(ciphertext, local_identity, local_prekeys) do
    impl_module().decrypt_prekey_message(ciphertext, local_identity, local_prekeys)
  end

  # ============================================================================
  # Key Generation (always use native for consistency)
  # ============================================================================

  @doc """
  Generate a new Curve25519 key pair.

  Always uses native implementation for key generation.
  """
  @spec generate_key_pair() :: {binary(), binary()}
  def generate_key_pair do
    case get_impl() do
      :native ->
        ExWapp.Signal.Native.generate_key_pair()

      :elixir ->
        ExWapp.Signal.Keys.generate_key_pair() |> then(fn kp -> {kp.public, kp.private} end)
    end
  end

  @doc """
  Generate a signed prekey with XEdDSA signature.
  """
  @spec generate_signed_prekey(binary()) :: {binary(), binary(), binary()}
  def generate_signed_prekey(identity_private) do
    case get_impl() do
      :native ->
        ExWapp.Signal.Native.generate_signed_prekey(identity_private)

      :elixir ->
        kp = ExWapp.Signal.Keys.generate_key_pair()
        sig = ExWapp.Signal.Keys.sign(identity_private, kp.public)
        {kp.public, kp.private, sig}
    end
  end

  @doc """
  Verify XEdDSA signature.
  """
  @spec verify_signature(binary(), binary(), binary()) :: boolean()
  def verify_signature(public_key, message, signature) do
    case get_impl() do
      :native -> ExWapp.Signal.Native.verify_signature(public_key, message, signature)
      :elixir -> ExWapp.Signal.Keys.verify(public_key, message, signature)
    end
  end

  # ============================================================================
  # Debug Helpers
  # ============================================================================

  @doc """
  Debug: dump a message's structure.
  """
  @spec debug_message(binary()) :: String.t()
  def debug_message(message) do
    ExWapp.Signal.Native.debug_prekey_message(message)
  end

  @doc """
  Returns info about the current implementation.
  """
  @spec info() :: map()
  def info do
    %{
      impl: get_impl(),
      module: impl_module(),
      native_available: Code.ensure_loaded?(ExWapp.Signal.Native),
      elixir_available: Code.ensure_loaded?(ExWapp.Signal.Session)
    }
  end
end
