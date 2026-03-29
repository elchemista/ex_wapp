defmodule ExWapp.Signal.SessionStore do
  @moduledoc """
  Manages Signal sessions for multiple recipients.

  Sessions are stored per (user, device) pair and persisted to the main store.

  Uses `ExWapp.Signal.Adapter` to switch between Signal implementations.
  """

  alias ExWapp.Signal.Adapter, as: Signal
  alias ExWapp.Signal.WireFormat
  alias ExWapp.Session.JIDUtils

  require Logger

  defmodule Ref do
    @moduledoc false
    defstruct [:table]
  end

  @type t :: %{
          sessions: %{String.t() => map()},
          pending_prekeys: %{String.t() => map()},
          session_touched_at_ms: %{String.t() => integer()}
        }
        | %Ref{table: :ets.tid()}

  @doc """
  Creates a new empty session store.
  """
  @spec new() :: t()
  def new do
    %{
      sessions: %{},
      pending_prekeys: %{},
      session_touched_at_ms: %{}
    }
  end

  @doc """
  Creates a lightweight ETS-backed session store reference.
  """
  @spec new_ets(t() | nil) :: t()
  def new_ets(initial \\ nil) do
    table =
      :ets.new(:ex_wapp_signal_sessions, [
        :set,
        :public,
        :compressed,
        read_concurrency: true,
        write_concurrency: true
      ])

    ref = %Ref{table: table}
    replace(ref, initial || new())
  end

  @doc """
  Attaches to an existing ETS-backed session store table.
  """
  @spec attach(:ets.tid()) :: t()
  def attach(table) when is_reference(table), do: %Ref{table: table}

  @doc """
  Returns true when the given value is a valid session-store backend.
  """
  @spec store?(term()) :: boolean()
  def store?(%Ref{table: table}) when is_reference(table), do: true

  def store?(%{sessions: sessions, pending_prekeys: pending_prekeys, session_touched_at_ms: touched_at_ms})
      when is_map(sessions) and is_map(pending_prekeys) and is_map(touched_at_ms),
      do: true

  def store?(_), do: false

  @doc """
  Returns a plain snapshot map for persistence/debugging.
  """
  @spec snapshot(t() | nil) :: map() | nil
  def snapshot(nil), do: nil
  def snapshot(%{sessions: _} = store), do: store

  def snapshot(%Ref{table: table}) do
    :ets.foldl(
      fn
        {{:session, jid}, session}, acc ->
          put_in(acc, [:sessions, jid], session)

        {{:pending_prekey, jid}, prekey}, acc ->
          put_in(acc, [:pending_prekeys, jid], prekey)

        {{:touched_at_ms, jid}, touched_at_ms}, acc ->
          put_in(acc, [:session_touched_at_ms, jid], touched_at_ms)
      end,
      new(),
      table
    )
  end

  @doc """
  Replaces the backend contents with the provided snapshot and returns the store.
  """
  @spec replace(t(), t() | nil) :: t()
  def replace(store, nil), do: replace(store, new())

  def replace(%Ref{table: table} = store, %{sessions: sessions} = snapshot) when is_map(sessions) do
    :ets.delete_all_objects(table)

    snapshot
    |> Map.get(:sessions, %{})
    |> Enum.each(fn {jid, session} ->
      :ets.insert(table, {{:session, normalize_jid(jid)}, session})
    end)

    snapshot
    |> Map.get(:pending_prekeys, %{})
    |> Enum.each(fn {jid, prekey} ->
      :ets.insert(table, {{:pending_prekey, normalize_jid(jid)}, prekey})
    end)

    snapshot
    |> Map.get(:session_touched_at_ms, %{})
    |> Enum.each(fn {jid, touched_at_ms} ->
      :ets.insert(table, {{:touched_at_ms, normalize_jid(jid)}, touched_at_ms})
    end)

    store
  end

  def replace(_store, %{sessions: _} = snapshot), do: snapshot

  @doc """
  Gets a session for a recipient JID.
  """
  @spec get_session(t(), String.t()) :: {:ok, map()} | :not_found
  def get_session(%Ref{table: table}, jid) do
    case :ets.lookup(table, {:session, normalize_jid(jid)}) do
      [{{:session, _jid}, session}] -> {:ok, session}
      [] -> :not_found
    end
  end

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
  def put_session(%Ref{table: table} = store, jid, session) do
    jid = normalize_jid(jid)
    Logger.debug("[SESSION_STORE] Stored session for #{jid}")
    touched_at_ms = System.system_time(:millisecond)
    :ets.insert(table, {{:session, jid}, session})
    :ets.insert(table, {{:touched_at_ms, jid}, touched_at_ms})
    store
  end

  def put_session(store, jid, session) do
    jid = normalize_jid(jid)
    Logger.debug("[SESSION_STORE] Stored session for #{jid}")
    touched_at_ms = System.system_time(:millisecond)

    %{
      store
      | sessions: Map.put(store.sessions, jid, session),
        session_touched_at_ms:
          Map.put(Map.get(store, :session_touched_at_ms, %{}), jid, touched_at_ms)
    }
  end

  @doc """
  Removes a session for a recipient JID.
  """
  @spec delete_session(t(), String.t()) :: t()
  def delete_session(%Ref{table: table} = store, jid) do
    jid = normalize_jid(jid)
    :ets.delete(table, {:session, jid})
    :ets.delete(table, {:touched_at_ms, jid})
    :ets.delete(table, {:pending_prekey, jid})
    store
  end

  def delete_session(store, jid) do
    jid = normalize_jid(jid)

    %{
      store
      | sessions: Map.delete(store.sessions, jid),
        session_touched_at_ms: Map.delete(Map.get(store, :session_touched_at_ms, %{}), jid)
    }
  end

  @doc """
  Checks if we have a session for a recipient.
  """
  @spec has_session?(t(), String.t()) :: boolean()
  def has_session?(nil, _jid), do: false

  def has_session?(%Ref{table: table}, jid) do
    :ets.member(table, {:session, normalize_jid(jid)})
  end

  def has_session?(store, jid) do
    Map.has_key?(store.sessions, normalize_jid(jid))
  end

  @doc """
  Lists all JIDs with active sessions.
  """
  @spec list_sessions(t()) :: [String.t()]
  def list_sessions(nil), do: []

  def list_sessions(%Ref{table: table}) do
    :ets.foldl(
      fn
        {{:session, jid}, _session}, acc -> [jid | acc]
        _, acc -> acc
      end,
      [],
      table
    )
    |> Enum.reverse()
  end

  def list_sessions(store) do
    Map.keys(store.sessions)
  end

  @doc """
  Returns the last-touch timestamp for a stored session, in wall-clock milliseconds.
  """
  @spec session_touched_at(t(), String.t()) :: integer() | nil
  def session_touched_at(%Ref{table: table}, jid) do
    case :ets.lookup(table, {:touched_at_ms, normalize_jid(jid)}) do
      [{{:touched_at_ms, _jid}, touched_at_ms}] -> touched_at_ms
      [] -> nil
    end
  end

  def session_touched_at(store, jid) do
    store
    |> Map.get(:session_touched_at_ms, %{})
    |> Map.get(normalize_jid(jid))
  end

  @doc """
  Returns true when none of the candidate JIDs has a recent session touch timestamp.
  """
  @spec stale_or_missing?(t(), [String.t()], pos_integer(), integer()) :: boolean()
  def stale_or_missing?(store, candidate_jids, max_age_ms, now_ms \\ System.system_time(:millisecond))
      when is_list(candidate_jids) and is_integer(max_age_ms) and max_age_ms > 0 do
    freshest_touch_ms =
      candidate_jids
      |> Enum.map(&session_touched_at(store, &1))
      |> Enum.reject(&is_nil/1)
      |> Enum.max(fn -> nil end)

    case freshest_touch_ms do
      nil -> true
      touched_at_ms -> now_ms - touched_at_ms >= max_age_ms
    end
  end

  @doc """
  Deletes cached sessions for the target JID and any PN<->LID aliases derived from
  the current mapping store. Matching is done on the stripped base JID so all
  device variants are cleared together.
  """
  @spec delete_sessions_for_user(t(), String.t(), map()) :: t()
  def delete_sessions_for_user(store, jid, lid_mapping \\ %{}) do
    related_bases = related_session_bases(jid, lid_mapping)

    if MapSet.size(related_bases) == 0 do
      store
    else
      store
      |> list_sessions()
      |> Enum.filter(fn candidate ->
        candidate_base =
          candidate
          |> JIDUtils.normalize_with_device()
          |> JIDUtils.strip_device()

        MapSet.member?(related_bases, candidate_base)
      end)
      |> Enum.reduce(store, &delete_session(&2, &1))
    end
  end

  defp related_session_bases(jid, lid_mapping) do
    base_jid =
      jid
      |> JIDUtils.normalize_with_device()
      |> JIDUtils.strip_device()

    mapped_lid =
      lid_mapping
      |> Map.get({:pn_to_lid, base_jid}, "")
      |> JIDUtils.normalize_with_device()
      |> JIDUtils.strip_device()

    mapped_pn =
      lid_mapping
      |> Map.get({:lid_to_pn, base_jid}, "")
      |> JIDUtils.normalize_with_device()
      |> JIDUtils.strip_device()

    [base_jid, mapped_lid, mapped_pn]
    |> Enum.reject(&(&1 == ""))
    |> MapSet.new()
  end

  @doc """
  Creates or gets a session for a recipient.

  If no session exists, uses the prekey bundle to create one.
  """
  @spec get_or_create_session(t(), String.t(), map(), map(), non_neg_integer()) ::
          {:ok, map(), binary() | nil, t()} | {:error, term()}
  def get_or_create_session(store, jid, local_identity, remote_bundle, local_registration_id) do
    get_or_create_session(
      store,
      jid,
      local_identity,
      remote_bundle,
      local_registration_id,
      []
    )
  end

  @doc """
  Creates or gets a session for a recipient with options.

  ## Options
    * `:force` - force creation from the supplied bundle even if a session exists.
  """
  @spec get_or_create_session(t(), String.t(), map(), map(), non_neg_integer(), keyword()) ::
          {:ok, map(), binary() | nil, t()} | {:error, term()}
  def get_or_create_session(
        store,
        jid,
        local_identity,
        remote_bundle,
        _local_registration_id,
        opts
      ) do
    jid = normalize_jid(jid)
    force? = Keyword.get(opts, :force, false)

    cond do
      force? and remote_bundle in [nil, %{}] ->
        {:error, :missing_bundle}

      force? ->
        create_session_from_bundle(store, jid, local_identity, remote_bundle)

      true ->
        case get_session(store, jid) do
          {:ok, session} ->
            {:ok, session, nil, store}

          :not_found ->
            create_or_reject(store, jid, local_identity, remote_bundle)
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
          prekey_base_key = base_key || Map.get(remote_bundle, :base_key)

          wrap_encrypted(
            ciphertext,
            prekey_base_key,
            remote_bundle,
            local_identity,
            local_registration_id,
            updated_store
          )
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

    Logger.debug(
      "[SESSION_STORE] decrypt_message: jid=#{jid} is_prekey=#{is_prekey_message} ct_size=#{byte_size(ciphertext)} existing_session=#{has_session?(store, jid)}"
    )

    if is_prekey_message do
      decrypt_prekey(store, jid, ciphertext, local_identity, local_prekeys)
    else
      decrypt_whisper(store, jid, ciphertext)
    end
  end

  defp create_or_reject(store, jid, local_identity, remote_bundle) do
    if remote_bundle in [nil, %{}] do
      {:error, :missing_bundle}
    else
      create_session_from_bundle(store, jid, local_identity, remote_bundle)
    end
  end

  # If we have a prekey base_key, wrap as PreKeySignalMessage; otherwise return whisper.
  defp wrap_encrypted(ciphertext, nil, _remote_bundle, _local_identity, _reg_id, store),
    do: {:ok, ciphertext, :whisper, store}

  defp wrap_encrypted(ciphertext, prekey_base_key, remote_bundle, local_identity, reg_id, store) do
    prekey_id = get_in(remote_bundle, [:prekey, :id]) || 0
    signed_prekey_id = get_in(remote_bundle, [:signed_prekey, :id]) || 0

    wrapped =
      WireFormat.serialize_prekey_signal_message(
        reg_id,
        prekey_id,
        signed_prekey_id,
        prekey_base_key,
        local_identity.public,
        ciphertext
      )

    {:ok, wrapped, :prekey, store}
  end

  defp decrypt_prekey(store, jid, ciphertext, local_identity, local_prekeys) do
    case try_existing_session_for_prekey(store, jid, ciphertext) do
      {:ok, plaintext, session} ->
        {:ok, plaintext, put_session(store, jid, session)}

      :try_fresh ->
        case Signal.decrypt_prekey_message(ciphertext, local_identity, local_prekeys) do
          {:ok, plaintext, session} ->
            Logger.debug("[SESSION_STORE] PreKey decrypt succeeded (fresh) for #{jid}")
            {:ok, plaintext, put_session(store, jid, session)}

          {:error, reason} ->
            Logger.error("[SESSION_STORE] PreKey decrypt failed for #{jid}: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  defp try_existing_session_for_prekey(store, jid, ciphertext) do
    case get_session(store, jid) do
      {:ok, session} ->
        Logger.debug("[SESSION_STORE] Trying existing session ratchet for prekey msg from #{jid}")

        case Signal.decrypt_prekey_message_with_session(session, ciphertext) do
          {:ok, plaintext, updated_session} ->
            Logger.debug(
              "[SESSION_STORE] PreKey decrypt succeeded on existing session for #{jid}"
            )

            {:ok, plaintext, updated_session}

          {:error, reason} ->
            Logger.debug(
              "[SESSION_STORE] Existing session prekey decrypt failed for #{jid}, trying fresh X3DH: #{inspect(reason)}"
            )

            :try_fresh
        end

      :not_found ->
        :try_fresh
    end
  end

  defp decrypt_whisper(store, jid, ciphertext) do
    case get_session(store, jid) do
      {:ok, session} ->
        case Signal.decrypt(session, ciphertext) do
          {:ok, plaintext, updated_session} ->
            {:ok, plaintext, update_session(store, jid, updated_session)}

          {:error, reason} ->
            Logger.error(
              "[SESSION_STORE] Whisper decrypt failed for #{jid}: #{inspect(reason)}"
            )

            {:error, reason}
        end

      :not_found ->
        Logger.error("[SESSION_STORE] No session found for #{jid} (whisper message)")
        {:error, :no_session}
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

  defp create_session_from_bundle(store, jid, local_identity, remote_bundle) do
    case Signal.create_session(local_identity, remote_bundle) do
      {:ok, session, base_key} ->
        Logger.debug("[SESSION_STORE] Created session using #{Signal.get_impl()} implementation")

        updated_store = put_session(store, jid, session)
        {:ok, session, base_key, updated_store}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
