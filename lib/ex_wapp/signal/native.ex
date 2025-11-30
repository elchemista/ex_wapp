defmodule ExWapp.Signal.Native do
  @moduledoc """
  Native Signal Protocol implementation using Rustler NIF.

  This module wraps the Rust libsignal-compatible implementation for:
  - Key generation and X25519 key exchange
  - XEdDSA signatures
  - HKDF key derivation (same as Signal protocol)
  - AES-256-CBC encryption/decryption
  - SignalMessage and PreKeySignalMessage serialization

  The Rust implementation ensures binary compatibility with the official
  Signal protocol used by WhatsApp.
  """

  use Rustler, otp_app: :ex_wapp, crate: "signal_nif"

  @doc """
  Generate a new Curve25519 key pair.

  Returns `{public_key, private_key}` where each is a 32-byte binary.
  """
  @spec generate_key_pair() :: {binary(), binary()}
  def generate_key_pair(), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Generate a signed prekey pair with XEdDSA signature.

  Returns `{public_key, private_key, signature}` where:
  - public_key: 32 bytes
  - private_key: 32 bytes
  - signature: 64 bytes (XEdDSA signature of public_key by identity_private)
  """
  @spec generate_signed_prekey(binary()) :: {binary(), binary(), binary()}
  def generate_signed_prekey(_identity_private), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Compute X25519 shared secret.

  Both keys must be 32 bytes. Returns 32-byte shared secret.
  """
  @spec x25519_shared_secret(binary(), binary()) :: binary()
  def x25519_shared_secret(_private_key, _public_key), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Verify XEdDSA signature.

  - public_key: 32-byte Curve25519 public key
  - message: arbitrary bytes
  - signature: 64-byte XEdDSA signature

  Returns `true` if signature is valid, `false` otherwise.
  """
  @spec verify_signature(binary(), binary(), binary()) :: boolean()
  def verify_signature(_public_key, _message, _signature), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Derive initial keys from X3DH shared secret.

  Input should be the concatenated DH outputs with 32-byte 0xFF prefix:
  `<<0xFF::256>> <> dh1 <> dh2 <> dh3 <> dh4`

  Returns `{root_key, chain_key}` each 32 bytes.
  """
  @spec hkdf_derive_initial(binary()) :: {binary(), binary()}
  def hkdf_derive_initial(_shared_secret), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Derive ratchet keys from DH output and current root key.

  Returns `{new_root_key, chain_key}` each 32 bytes.
  """
  @spec hkdf_derive_ratchet(binary(), binary()) :: {binary(), binary()}
  def hkdf_derive_ratchet(_dh_output, _root_key), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Derive message keys from chain key.

  Returns `{new_chain_key, cipher_key, mac_key, iv}`:
  - new_chain_key: 32 bytes
  - cipher_key: 32 bytes (for AES-256)
  - mac_key: 32 bytes (for HMAC-SHA256)
  - iv: 16 bytes (for AES-CBC)
  """
  @spec derive_message_keys(binary()) :: {binary(), binary(), binary(), binary()}
  def derive_message_keys(_chain_key), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Encrypt plaintext with AES-256-CBC + PKCS7 padding.

  - cipher_key: 32 bytes
  - iv: 16 bytes

  Returns ciphertext.
  """
  @spec encrypt_aes_cbc(binary(), binary(), binary()) :: binary()
  def encrypt_aes_cbc(_plaintext, _cipher_key, _iv), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Decrypt ciphertext with AES-256-CBC + PKCS7 padding removal.

  Returns plaintext or raises on error.
  """
  @spec decrypt_aes_cbc(binary(), binary(), binary()) :: binary()
  def decrypt_aes_cbc(_ciphertext, _cipher_key, _iv), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Build a complete SignalMessage with proper protobuf encoding and MAC.

  Args:
  - ratchet_key: 32-byte sender's current ratchet public key
  - counter: message counter
  - previous_counter: previous chain's counter
  - ciphertext: AES-CBC encrypted message content
  - mac_key: 32-byte key for HMAC
  - sender_identity: 32-byte sender's identity public key
  - receiver_identity: 32-byte receiver's identity public key

  Returns the complete serialized SignalMessage (version || protobuf || mac).
  """
  @spec build_signal_message(
          binary(),
          non_neg_integer(),
          non_neg_integer(),
          binary(),
          binary(),
          binary(),
          binary()
        ) :: binary()
  def build_signal_message(
        _ratchet_key,
        _counter,
        _previous_counter,
        _ciphertext,
        _mac_key,
        _sender_identity,
        _receiver_identity
      ),
      do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Build a complete PreKeySignalMessage.

  Args:
  - registration_id: sender's registration ID
  - prekey_id: one-time prekey ID (0 if not used)
  - signed_prekey_id: signed prekey ID
  - base_key: 32-byte ephemeral public key from X3DH
  - identity_key: 32-byte sender's identity public key
  - signal_message: already-serialized SignalMessage bytes

  Returns the complete serialized PreKeySignalMessage.
  """
  @spec build_prekey_signal_message(
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          binary(),
          binary(),
          binary()
        ) :: binary()
  def build_prekey_signal_message(
        _registration_id,
        _prekey_id,
        _signed_prekey_id,
        _base_key,
        _identity_key,
        _signal_message
      ),
      do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Full message encryption for WhatsApp.

  This does everything: derives keys, encrypts, builds SignalMessage,
  optionally wraps in PreKeySignalMessage.

  Args:
  - plaintext: message to encrypt
  - chain_key: current sending chain key (32 bytes)
  - ratchet_public: our ratchet public key (32 bytes)
  - counter: current message counter
  - previous_counter: previous chain counter
  - sender_identity: our identity public key (32 bytes)
  - receiver_identity: their identity public key (32 bytes)
  - is_prekey: whether to wrap in PreKeySignalMessage
  - registration_id: our registration ID (only needed if is_prekey)
  - prekey_id: one-time prekey ID (only needed if is_prekey, 0 if not used)
  - signed_prekey_id: signed prekey ID (only needed if is_prekey)
  - base_key: ephemeral key from X3DH (only needed if is_prekey, 32 bytes)

  Returns `{encrypted_message, new_chain_key, new_counter}`.
  """
  @spec encrypt_message(
          binary(),
          binary(),
          binary(),
          non_neg_integer(),
          non_neg_integer(),
          binary(),
          binary(),
          boolean(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          binary()
        ) :: {binary(), binary(), non_neg_integer()}
  def encrypt_message(
        _plaintext,
        _chain_key,
        _ratchet_public,
        _counter,
        _previous_counter,
        _sender_identity,
        _receiver_identity,
        _is_prekey,
        _registration_id,
        _prekey_id,
        _signed_prekey_id,
        _base_key
      ),
      do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Debug: dump the hex of a PreKeySignalMessage with field breakdown.
  """
  @spec debug_prekey_message(binary()) :: String.t()
  def debug_prekey_message(_message), do: :erlang.nif_error(:nif_not_loaded)

  # ============================================================================
  # Complete Session Cipher Functions (ported from wacore)
  # ============================================================================

  @doc """
  Create a new outbound Signal session.

  Performs X3DH key agreement and returns a serialized session state.

  ## Parameters
  - local_identity_public: Our identity public key (32 bytes)
  - local_identity_private: Our identity private key (32 bytes)
  - local_registration_id: Our registration ID
  - remote_identity: Their identity public key (32 bytes)
  - remote_signed_prekey: Their signed prekey public key (32 bytes)
  - remote_prekey: Their one-time prekey (32 bytes or empty)
  - remote_registration_id: Their registration ID
  - prekey_id: Their prekey ID (0 if no prekey)
  - signed_prekey_id: Their signed prekey ID

  Returns serialized session state binary.
  """
  @spec create_outbound_session(
          binary(),
          binary(),
          non_neg_integer(),
          binary(),
          binary(),
          binary(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: binary()
  def create_outbound_session(
        _local_identity_public,
        _local_identity_private,
        _local_registration_id,
        _remote_identity,
        _remote_signed_prekey,
        _remote_prekey,
        _remote_registration_id,
        _prekey_id,
        _signed_prekey_id
      ),
      do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Encrypt a message using a session.

  Takes serialized session state and plaintext, returns {encrypted_message, updated_session}.
  """
  @spec session_encrypt_message(binary(), binary()) :: {binary(), binary(), boolean()}
  def session_encrypt_message(_session_data, _plaintext),
    do: :erlang.nif_error(:nif_not_loaded)
end
