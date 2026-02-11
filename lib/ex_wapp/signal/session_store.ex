defmodule ExWapp.Signal.SessionStore do
  @moduledoc """
  Manages Signal sessions for multiple recipients.

  Sessions are stored per (user, device) pair and persisted to the main store.

  Uses `ExWapp.Signal.Adapter` to switch between Signal implementations.
  """

  alias ExWapp.Signal.Adapter, as: Signal

  require Logger

  @type t :: %{
          sessions: %{String.t() => map()},
          pending_prekeys: %{String.t() => map()}
        }

  @doc """
  Creates a new empty session store.
  """
  @spec new() :: t()
  def new do
    %{
      sessions: %{},
      pending_prekeys: %{}
    }
  end

  @doc """
  Gets a session for a recipient JID.
  """
  @spec get_session(t(), String.t()) :: {:ok, map()} | :not_found
  def get_session(store, jid) do
    case Map.get(store.sessions, normalize_jid(jid)) do
      nil -> :not_found
      session -> {:ok, session}
    end
  end

  @doc """
  Stores a session for a recipient JID.
  """
  @spec put_session(t(), String.t(), map()) :: t()
  def put_session(store, jid, session) do
    jid = normalize_jid(jid)
    Logger.debug("[SESSION_STORE] Stored session for #{jid}")
    %{store | sessions: Map.put(store.sessions, jid, session)}
  end

  @doc """
  Removes a session for a recipient JID.
  """
  @spec delete_session(t(), String.t()) :: t()
  def delete_session(store, jid) do
    %{store | sessions: Map.delete(store.sessions, normalize_jid(jid))}
  end

  @doc """
  Checks if we have a session for a recipient.
  """
  @spec has_session?(t(), String.t()) :: boolean()
  def has_session?(store, jid) do
    Map.has_key?(store.sessions, normalize_jid(jid))
  end

  @doc """
  Lists all JIDs with active sessions.
  """
  @spec list_sessions(t()) :: [String.t()]
  def list_sessions(store) do
    Map.keys(store.sessions)
  end

  @doc """
  Creates or gets a session for a recipient.

  If no session exists, uses the prekey bundle to create one.
  """
  @spec get_or_create_session(t(), String.t(), map(), map(), non_neg_integer()) ::
          {:ok, map(), binary() | nil, t()} | {:error, term()}
  def get_or_create_session(store, jid, local_identity, remote_bundle, _local_registration_id) do
    jid = normalize_jid(jid)

    case get_session(store, jid) do
      {:ok, session} ->
        # Existing session - return it with nil base_key (not a prekey message)
        {:ok, session, nil, store}

      :not_found ->
        cond do
          remote_bundle in [nil, %{}] ->
            {:error, :missing_bundle}

          true ->
            case Signal.create_session(local_identity, remote_bundle) do
              {:ok, session, base_key} ->
                Logger.info(
                  "[SESSION_STORE] Created session using #{Signal.get_impl()} implementation"
                )

                updated_store = put_session(store, jid, session)
                {:ok, session, base_key, updated_store}

              {:error, reason} ->
                {:error, reason}
            end
        end
    end
  end

  @doc """
  Updates a session after encryption/decryption.
  """
  @spec update_session(t(), String.t(), map()) :: t()
  def update_session(store, jid, session) do
    put_session(store, jid, session)
  end

  @doc """
  Encrypts a message to a recipient.

  Creates a session if needed using the provided prekey bundle.
  Returns either a PreKeySignalMessage (new session) or regular SignalMessage.
  """
  @spec encrypt_message(t(), String.t(), binary(), map(), non_neg_integer(), map()) ::
          {:ok, binary(), :prekey | :whisper, t()} | {:error, term()}
  def encrypt_message(store, jid, plaintext, local_identity, local_registration_id, remote_bundle) do
    jid = normalize_jid(jid)

    with {:ok, session, base_key, store} <-
           get_or_create_session(
             store,
             jid,
             local_identity,
             remote_bundle,
             local_registration_id
           ) do
      case Signal.encrypt(session, plaintext) do
        {:ok, ciphertext, updated_session} ->
          updated_store = update_session(store, jid, updated_session)

          # If caller already created the session in a previous step (e.g. prekey fetch
          # worker), base_key will be nil here. Preserve first-message wrapping by honoring
          # the provided remote_bundle base_key.
          prekey_base_key = base_key || Map.get(remote_bundle || %{}, :base_key)

          if prekey_base_key do
            prekey_id = get_in(remote_bundle, [:prekey, :id]) || 0
            signed_prekey_id = get_in(remote_bundle, [:signed_prekey, :id]) || 0
            identity_pub = local_identity.public

            wrapped =
              ExWapp.Signal.WireFormat.serialize_prekey_signal_message(
                local_registration_id,
                prekey_id,
                signed_prekey_id,
                prekey_base_key,
                identity_pub,
                ciphertext
              )

            {:ok, wrapped, :prekey, updated_store}
          else
            {:ok, ciphertext, :whisper, updated_store}
          end
      end
    end
  end

  @doc """
  Decrypts a message from a sender.
  """
  @spec decrypt_message(t(), String.t(), binary(), boolean(), map(), map()) ::
          {:ok, binary(), t()} | {:error, term()}
  def decrypt_message(store, jid, ciphertext, is_prekey_message, local_identity, local_prekeys) do
    jid = normalize_jid(jid)

    Logger.info(
      "[SESSION_STORE] decrypt_message: jid=#{jid} is_prekey=#{is_prekey_message} ct_size=#{byte_size(ciphertext)} existing_session=#{has_session?(store, jid)}"
    )

    if is_prekey_message do
      # PreKeySignalMessage - but if we already have a valid session, try it first
      # (whatsapp-rust: avoid replacing an existing valid session; prevents MAC failures)
      existing_result =
        case get_session(store, jid) do
          {:ok, session} ->
            Logger.info(
              "[SESSION_STORE] Trying existing session first for prekey msg from #{jid}"
            )

            case Signal.decrypt_prekey_message(ciphertext, local_identity, local_prekeys) do
              {:ok, plaintext, new_session} ->
                Logger.info("[SESSION_STORE] PreKey decrypt succeeded (new session) for #{jid}")
                {:ok, plaintext, new_session}

              {:error, _prekey_err} ->
                # Fallback: try as regular message on existing session
                case Signal.decrypt(session, ciphertext) do
                  {:ok, plaintext, updated_session} ->
                    Logger.info(
                      "[SESSION_STORE] Decrypt on existing session succeeded for #{jid}"
                    )

                    {:ok, plaintext, updated_session}

                  {:error, _} ->
                    :try_fresh
                end
            end

          :not_found ->
            :try_fresh
        end

      case existing_result do
        {:ok, plaintext, session} ->
          updated_store = put_session(store, jid, session)
          {:ok, plaintext, updated_store}

        :try_fresh ->
          case Signal.decrypt_prekey_message(ciphertext, local_identity, local_prekeys) do
            {:ok, plaintext, session} ->
              Logger.info("[SESSION_STORE] PreKey decrypt succeeded (fresh) for #{jid}")
              updated_store = put_session(store, jid, session)
              {:ok, plaintext, updated_store}

            {:error, reason} ->
              Logger.warning(
                "[SESSION_STORE] PreKey decrypt failed for #{jid}: #{inspect(reason)}"
              )

              {:error, reason}
          end
      end
    else
      # Regular SignalMessage - use existing session
      case get_session(store, jid) do
        {:ok, session} ->
          case Signal.decrypt(session, ciphertext) do
            {:ok, plaintext, updated_session} ->
              updated_store = update_session(store, jid, updated_session)
              {:ok, plaintext, updated_store}

            {:error, reason} ->
              Logger.warning(
                "[SESSION_STORE] Whisper decrypt failed for #{jid}: #{inspect(reason)}"
              )

              {:error, reason}
          end

        :not_found ->
          Logger.warning("[SESSION_STORE] No session found for #{jid} (whisper message)")
          {:error, :no_session}
      end
    end
  end

  # Normalize JID to consistent format
  defp normalize_jid(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
  end

  defp normalize_jid(%{user: user, device: device, server: server})
       when is_integer(device) and device > 0 and is_binary(server) and server != "" do
    "#{user}:#{device}@#{server}"
  end

  defp normalize_jid(%{user: user, server: server}) when is_binary(server) and server != "" do
    "#{user}@#{server}"
  end

  defp normalize_jid(%{user: user}), do: "#{user}@s.whatsapp.net"
end
