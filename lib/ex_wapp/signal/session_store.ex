defmodule ExWapp.Signal.SessionStore do
  @moduledoc """
  Manages Signal sessions for multiple recipients.

  Sessions are stored per (user, device) pair and persisted to the main store.

  Uses `ExWapp.Signal.Adapter` to switch between Signal implementations.
  """

  alias ExWapp.Log
  alias ExWapp.Session.JIDUtils
  alias ExWapp.Signal.Adapter, as: Signal
  alias ExWapp.Signal.MutationLock
  alias ExWapp.Signal.WireFormat

  require Logger

  @max_previous_sessions 5

  @type pending_prekey :: %{
          required(:base_key) => binary(),
          required(:signed_prekey_id) => non_neg_integer(),
          optional(:prekey_id) => non_neg_integer() | nil
        }

  defmodule Ref do
    @moduledoc """
    Reference to an ETS-backed Signal session store.

    Wrapping the table identifier lets the same API support persistent maps and
    concurrent runtime storage without leaking ETS details to callers.
    """
    defstruct [:table]

    @type t :: %__MODULE__{table: term()}
  end

  @type t ::
          %{
            sessions: %{String.t() => map()},
            pending_prekeys: %{String.t() => map()},
            session_touched_at_ms: %{String.t() => integer()}
          }
          | Ref.t()

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
  @spec attach(term()) :: t()
  def attach(table) when is_reference(table), do: %Ref{table: table}

  @doc """
  Returns true when the given value is a valid session-store backend.
  """
  @spec store?(term()) :: boolean()
  def store?(%Ref{table: table}) when is_reference(table), do: true

  def store?(%{
        sessions: sessions,
        pending_prekeys: pending_prekeys,
        session_touched_at_ms: touched_at_ms
      })
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
  def replace(store, %Ref{} = snapshot), do: replace(store, snapshot(snapshot))

  def replace(%Ref{table: table} = store, %{sessions: sessions} = snapshot)
      when is_map(sessions) do
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
    Logger.debug("[SESSION_STORE] Stored session for #{Log.reference(jid)}")
    touched_at_ms = System.system_time(:millisecond)
    :ets.insert(table, {{:session, jid}, session})
    :ets.insert(table, {{:touched_at_ms, jid}, touched_at_ms})
    store
  end

  def put_session(store, jid, session) do
    jid = normalize_jid(jid)
    Logger.debug("[SESSION_STORE] Stored session for #{Log.reference(jid)}")
    touched_at_ms = System.system_time(:millisecond)

    %{
      store
      | sessions: Map.put(store.sessions, jid, session),
        session_touched_at_ms:
          Map.put(Map.get(store, :session_touched_at_ms, %{}), jid, touched_at_ms)
    }
  end

  @doc """
  Gets the pending outbound pre-key wrapper for a device session.

  A pending wrapper remains active until that same device proves the Signal
  session by sending a message that decrypts successfully.
  """
  @spec get_pending_prekey(t(), String.t()) :: {:ok, pending_prekey()} | :not_found
  def get_pending_prekey(%Ref{table: table}, jid) do
    case :ets.lookup(table, {:pending_prekey, normalize_jid(jid)}) do
      [{{:pending_prekey, _jid}, pending_prekey}] -> {:ok, pending_prekey}
      [] -> :not_found
    end
  end

  def get_pending_prekey(store, jid) do
    case store
         |> Map.get(:pending_prekeys, %{})
         |> Map.get(normalize_jid(jid)) do
      nil -> :not_found
      pending_prekey -> {:ok, pending_prekey}
    end
  end

  @doc """
  Stores the pending outbound pre-key wrapper for one device session.
  """
  @spec put_pending_prekey(t(), String.t(), pending_prekey()) :: t()
  def put_pending_prekey(%Ref{table: table} = store, jid, pending_prekey)
      when is_map(pending_prekey) do
    :ets.insert(table, {{:pending_prekey, normalize_jid(jid)}, pending_prekey})
    store
  end

  def put_pending_prekey(store, jid, pending_prekey) when is_map(pending_prekey) do
    pending_prekeys =
      store
      |> Map.get(:pending_prekeys, %{})
      |> Map.put(normalize_jid(jid), pending_prekey)

    Map.put(store, :pending_prekeys, pending_prekeys)
  end

  @doc """
  Removes the pending outbound pre-key wrapper for one device session.
  """
  @spec delete_pending_prekey(t(), String.t()) :: t()
  def delete_pending_prekey(%Ref{table: table} = store, jid) do
    :ets.delete(table, {:pending_prekey, normalize_jid(jid)})
    store
  end

  def delete_pending_prekey(store, jid) do
    pending_prekeys =
      store
      |> Map.get(:pending_prekeys, %{})
      |> Map.delete(normalize_jid(jid))

    Map.put(store, :pending_prekeys, pending_prekeys)
  end

  @doc """
  Copies a device session and its pending pre-key state to a PN/LID alias.
  """
  @spec copy_session(t(), String.t(), String.t()) :: t()
  def copy_session(store, source_jid, alias_jid) do
    source_jid = normalize_jid(source_jid)
    alias_jid = normalize_jid(alias_jid)

    with_session_mutation(store, [source_jid, alias_jid], [], fn ->
      do_copy_session(store, source_jid, alias_jid)
    end)
  end

  defp do_copy_session(store, source_jid, alias_jid) do
    if source_jid == alias_jid do
      store
    else
      case get_session(store, source_jid) do
        {:ok, session} ->
          store
          |> put_session(alias_jid, session)
          |> copy_pending_prekey(source_jid, alias_jid)

        :not_found ->
          store
      end
    end
  end

  @doc """
  Removes a session for a recipient JID.
  """
  @spec delete_session(t(), String.t()) :: t()
  def delete_session(store, jid) do
    jid = normalize_jid(jid)

    with_session_mutation(store, [jid], [], fn ->
      do_delete_session(store, jid)
    end)
  end

  defp do_delete_session(%Ref{table: table} = store, jid) do
    :ets.delete(table, {:session, jid})
    :ets.delete(table, {:touched_at_ms, jid})
    :ets.delete(table, {:pending_prekey, jid})
    store
  end

  defp do_delete_session(store, jid) do
    %{
      store
      | sessions: Map.delete(store.sessions, jid),
        pending_prekeys: Map.delete(Map.get(store, :pending_prekeys, %{}), jid),
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
  def stale_or_missing?(
        store,
        candidate_jids,
        max_age_ms,
        now_ms \\ System.system_time(:millisecond)
      )
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
  Deletes sessions this device has only ever sent on.

  A session with traffic in one direction and nothing coming back is the shape a
  desync leaves behind: the peer dropped its half and re-initiated, this device
  never managed to adopt the new one, and every send since has been encrypted
  against a ratchet the peer abandoned. The server answers those with
  `<ack error="463">` forever, because nothing in the send path ever concludes
  that the session itself is the problem.

  It is also the shape of a perfectly healthy session to someone who has not
  replied yet, so age is what tells them apart — hence `min_age_ms`, and hence
  calling this at connect rather than mid-conversation. An unstamped session is
  treated as old: timestamps are written on every store, so their absence means
  the session outlived the process that made it.

  Returns the store and the JIDs that were dropped. The next send to those peers
  fetches a fresh bundle and negotiates from scratch.
  """
  @spec evict_one_way_sessions(t(), non_neg_integer(), integer()) :: {t(), [String.t()]}
  def evict_one_way_sessions(store, min_age_ms, now_ms \\ System.system_time(:millisecond))

  def evict_one_way_sessions(store, min_age_ms, _now_ms) when min_age_ms <= 0, do: {store, []}

  def evict_one_way_sessions(store, min_age_ms, now_ms)
      when is_integer(min_age_ms) and is_integer(now_ms) do
    evictable =
      store
      |> list_sessions()
      |> Enum.filter(&one_way_session?(store, &1, min_age_ms, now_ms))

    {Enum.reduce(evictable, store, &delete_session(&2, &1)), evictable}
  end

  defp one_way_session?(store, jid, min_age_ms, now_ms) do
    with {:ok, session} <- get_session(store, jid),
         sent when is_integer(sent) and sent > 0 <-
           session |> Map.get(:sending_chain) |> chain_counter(),
         received when received in [nil, 0] <-
           session |> Map.get(:receiving_chain) |> chain_counter() do
      case session_touched_at(store, jid) do
        nil -> true
        touched_at_ms -> now_ms - touched_at_ms >= min_age_ms
      end
    else
      _other -> false
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
    identity_hints = remote_identity_hints(remote_bundle)

    with_session_mutation(store, [jid], identity_hints, fn ->
      do_get_or_create_session(
        store,
        jid,
        local_identity,
        remote_bundle,
        opts
      )
    end)
  end

  defp do_get_or_create_session(store, jid, local_identity, remote_bundle, opts) do
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

    with_session_mutation(store, [jid], remote_identity_hints(remote_bundle), fn ->
      do_encrypt_message(
        store,
        jid,
        plaintext,
        local_identity,
        local_registration_id,
        remote_bundle
      )
    end)
  end

  defp do_encrypt_message(
         store,
         jid,
         plaintext,
         local_identity,
         local_registration_id,
         remote_bundle
       ) do
    with {:ok, session, base_key, store} <-
           do_get_or_create_session(
             store,
             jid,
             local_identity,
             remote_bundle,
             []
           ) do
      {session, store} =
        ensure_outbound_pending_prekey(store, jid, session, base_key, remote_bundle)

      {:ok, ciphertext, updated_session} = Signal.encrypt(session, plaintext)
      updated_store = update_session(store, jid, updated_session)

      wrap_encrypted(
        ciphertext,
        active_pending_prekey(updated_store, jid, updated_session),
        local_identity,
        local_registration_id,
        updated_store
      )
    end
  end

  @doc """
  Decrypts a message from a sender.
  """
  @spec decrypt_message(t(), String.t(), binary(), boolean(), map(), map()) ::
          {:ok, binary(), t()} | {:error, term()}
  def decrypt_message(store, jid, ciphertext, is_prekey_message, local_identity, local_prekeys) do
    jid = normalize_jid(jid)

    with_session_mutation(
      store,
      [jid],
      prekey_identity_hints(ciphertext, is_prekey_message),
      fn ->
        do_decrypt_message(
          store,
          jid,
          ciphertext,
          is_prekey_message,
          local_identity,
          local_prekeys
        )
      end
    )
  end

  defp do_decrypt_message(
         store,
         jid,
         ciphertext,
         is_prekey_message,
         local_identity,
         local_prekeys
       ) do
    Logger.debug(
      "[SESSION_STORE] decrypt_message: jid=#{Log.reference(jid)} is_prekey=#{is_prekey_message} ct_size=#{byte_size(ciphertext)} existing_session=#{has_session?(store, jid)}"
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

  # Keep wrapping for this specific device until it proves the session by sending
  # a message that decrypts successfully. Transport ACKs are intentionally not
  # part of this lifecycle.
  defp wrap_encrypted(ciphertext, nil, _local_identity, _reg_id, store),
    do: {:ok, ciphertext, :whisper, store}

  defp wrap_encrypted(ciphertext, pending_prekey, local_identity, reg_id, store) do
    wrapped =
      WireFormat.serialize_prekey_signal_message(
        reg_id,
        Map.get(pending_prekey, :prekey_id),
        Map.fetch!(pending_prekey, :signed_prekey_id),
        Map.fetch!(pending_prekey, :base_key),
        local_identity.public,
        ciphertext
      )

    {:ok, wrapped, :prekey, store}
  end

  defp decrypt_prekey(store, jid, ciphertext, local_identity, local_prekeys) do
    debug = %{
      payload: prekey_message_debug(ciphertext),
      local: local_prekeys_debug(local_identity, local_prekeys)
    }

    existing_session? = has_session?(store, jid)

    Logger.debug(
      "[SESSION_STORE] PreKey decrypt attempt jid=#{Log.reference(jid)} existing_session=#{existing_session?} " <>
        "payload=#{inspect(debug.payload)} local=#{inspect(debug.local)}"
    )

    case try_existing_session_for_prekey(store, jid, ciphertext) do
      {:ok, plaintext, updated_session, decrypted_session} ->
        {:ok, plaintext, store_decrypted_session(store, jid, updated_session, decrypted_session)}

      {:error, reason} ->
        {:error, reason}

      :try_fresh ->
        decrypt_fresh_prekey(store, jid, ciphertext, local_identity, local_prekeys, debug)
    end
  end

  defp decrypt_fresh_prekey(store, jid, ciphertext, local_identity, local_prekeys, debug) do
    case Signal.decrypt_prekey_message(ciphertext, local_identity, local_prekeys) do
      {:ok, plaintext, session} ->
        Logger.debug("[SESSION_STORE] PreKey decrypt succeeded (fresh) for #{Log.reference(jid)}")
        session = retain_current_session(store, jid, session)
        {:ok, plaintext, store_decrypted_session(store, jid, session, session)}

      {:error, reason} ->
        Logger.error(
          "[SESSION_STORE] PreKey decrypt failed for #{Log.reference(jid)}: #{Log.reason(reason)} " <>
            "payload=#{inspect(debug.payload)} local=#{inspect(debug.local)}"
        )

        {:error, reason}
    end
  end

  defp retain_current_session(store, jid, session) do
    case get_session(store, jid) do
      {:ok, previous_session} -> retain_previous_session(session, previous_session)
      :not_found -> session
    end
  end

  defp try_existing_session_for_prekey(store, jid, ciphertext) do
    case get_session(store, jid) do
      {:ok, session} ->
        case WireFormat.parse_prekey_signal_message(ciphertext) do
          {:ok, parsed} ->
            decrypt_prekey_with_stored_sessions(session, ciphertext, jid, parsed.base_key)

          {:error, reason} ->
            Logger.warning(
              "[SESSION_STORE] Cannot route malformed prekey message for #{Log.reference(jid)}: #{Log.reason(reason)}"
            )

            {:error, reason}
        end

      :not_found ->
        :try_fresh
    end
  end

  defp decrypt_prekey_with_stored_sessions(session, ciphertext, jid, base_key) do
    candidates = prekey_session_candidates(session)
    matching = Enum.filter(candidates, &session_matches_base_key?(&1, base_key))

    Logger.debug(
      "[SESSION_STORE] Routing prekey message for #{Log.reference(jid)} " <>
        "stored_sessions=#{length(candidates)} base_key_matches=#{length(matching)} " <>
        "legacy_sessions=#{Enum.count(candidates, &legacy_session_candidate?/1)} " <>
        "current=#{inspect(session_debug(session))}"
    )

    case matching do
      [candidate | _rest] ->
        decrypt_matching_prekey_session(session, candidate, ciphertext, jid)

      [] ->
        decrypt_legacy_prekey_sessions(session, candidates, ciphertext, jid, base_key)
    end
  end

  defp decrypt_matching_prekey_session(session, candidate, ciphertext, jid) do
    {_location, stored_session} = candidate

    case Signal.decrypt_prekey_message_with_session(stored_session, ciphertext) do
      {:ok, plaintext, updated_session} ->
        Logger.debug(
          "[SESSION_STORE] PreKey decrypt succeeded on base-key-matched #{candidate_label(candidate)} " <>
            "for #{Log.reference(jid)}"
        )

        {:ok, plaintext, replace_prekey_candidate(session, candidate, updated_session),
         updated_session}

      {:error, :message_key_not_found} = duplicate ->
        Logger.debug(
          "[SESSION_STORE] Base-key-matched ratchet proved prekey replay for #{Log.reference(jid)}"
        )

        duplicate

      {:error, reason} ->
        Logger.warning(
          "[SESSION_STORE] Base-key-matched prekey session failed for #{Log.reference(jid)} " <>
            "location=#{candidate_label(candidate)} reason=#{Log.reason(reason)}"
        )

        {:error, reason}
    end
  end

  defp decrypt_legacy_prekey_sessions(session, candidates, ciphertext, jid, base_key) do
    legacy_candidates = Enum.filter(candidates, &legacy_session_candidate?/1)

    case try_legacy_prekey_candidates(session, legacy_candidates, ciphertext, base_key) do
      {:ok, plaintext, updated_session, decrypted_session, candidate} ->
        Logger.debug(
          "[SESSION_STORE] PreKey decrypt succeeded on legacy #{candidate_label(candidate)} " <>
            "for #{Log.reference(jid)}; attached envelope base key for future routing"
        )

        {:ok, plaintext, updated_session, decrypted_session}

      {:error, reasons} ->
        Logger.debug(
          "[SESSION_STORE] No stored session matched prekey base key for #{Log.reference(jid)}; " <>
            "legacy_attempts=#{length(legacy_candidates)} legacy_errors=#{summarize_decrypt_reasons(reasons)} " <>
            "trying fresh X3DH"
        )

        :try_fresh
    end
  end

  defp try_legacy_prekey_candidates(session, candidates, ciphertext, base_key) do
    Enum.reduce_while(candidates, {:error, []}, fn candidate, {:error, reasons} ->
      {_location, legacy_session} = candidate

      case Signal.decrypt_prekey_message_with_session(legacy_session, ciphertext) do
        {:ok, plaintext, updated_legacy_session} ->
          updated_legacy_session =
            Map.put(updated_legacy_session, :initiator_base_key, base_key)

          {:halt,
           {:ok, plaintext, replace_prekey_candidate(session, candidate, updated_legacy_session),
            updated_legacy_session, candidate}}

        {:error, reason} ->
          {:cont, {:error, [reason | reasons]}}
      end
    end)
  end

  defp prekey_session_candidates(session) do
    [{:current, session}] ++
      (session
       |> Map.get(:previous_sessions, [])
       |> Enum.with_index()
       |> Enum.map(fn {previous, index} -> {{:previous, index}, previous} end))
  end

  defp session_matches_base_key?({_location, session}, base_key),
    do: is_binary(base_key) and Map.get(session, :initiator_base_key) == base_key

  defp legacy_session_candidate?({_location, session}),
    do: not is_binary(Map.get(session, :initiator_base_key))

  defp replace_prekey_candidate(_session, {:current, _stored}, updated_session),
    do: updated_session

  # A previous session that just decrypted a peer message is the session the
  # peer is actually using, so it is promoted to current and the outgoing
  # session is demoted into the slot it vacated. Writing the ratcheted state
  # back into the previous list and leaving `current` alone would keep every
  # outbound message encrypted against a session the peer has moved off: the
  # server answers those with `<ack class="message" error="463">`, and because
  # the peer never receives a decryptable reply it keeps re-initiating, so the
  # mismatch never heals.
  defp replace_prekey_candidate(session, {{:previous, index}, _stored}, updated_session) do
    demoted = strip_previous_sessions(session)

    previous_sessions =
      session
      |> Map.get(:previous_sessions, [])
      |> List.replace_at(index, demoted)
      |> Enum.take(@max_previous_sessions)

    updated_session
    |> strip_previous_sessions()
    |> Map.put(:previous_sessions, previous_sessions)
  end

  defp candidate_label({:current, _session}), do: "current-session"
  defp candidate_label({{:previous, index}, _session}), do: "previous-session[#{index}]"

  defp summarize_decrypt_reasons([]), do: "none"

  defp summarize_decrypt_reasons(reasons) do
    reasons
    |> Enum.frequencies()
    |> Enum.map_join(",", fn {reason, count} -> "#{inspect(reason)}:#{count}" end)
  end

  defp decrypt_whisper(store, jid, ciphertext) do
    case get_session(store, jid) do
      {:ok, session} ->
        decrypt_whisper_session(store, jid, ciphertext, session)

      :not_found ->
        Logger.error(
          "[SESSION_STORE] No session found for #{Log.reference(jid)} (whisper message)"
        )

        {:error, :no_session}
    end
  end

  defp decrypt_whisper_session(store, jid, ciphertext, session) do
    case Signal.decrypt(session, ciphertext) do
      {:ok, plaintext, updated_session} ->
        {:ok, plaintext, store_decrypted_session(store, jid, updated_session, updated_session)}

      {:error, current_reason} ->
        decrypt_whisper_previous(store, jid, ciphertext, session, current_reason)
    end
  end

  defp decrypt_whisper_previous(store, jid, ciphertext, session, current_reason) do
    case decrypt_with_previous_sessions(session, ciphertext) do
      {:ok, plaintext, updated_session, decrypted_session} ->
        Logger.debug(
          "[SESSION_STORE] Whisper decrypt succeeded on a previous base-key session for #{Log.reference(jid)}"
        )

        {:ok, plaintext, store_decrypted_session(store, jid, updated_session, decrypted_session)}

      {:error, previous_reasons} ->
        reason = preferred_decrypt_error(current_reason, previous_reasons)

        Logger.error(
          "[SESSION_STORE] Whisper decrypt failed for #{Log.reference(jid)}: #{Log.reason(reason)}"
        )

        {:error, reason}
    end
  end

  defp ensure_outbound_pending_prekey(store, jid, session, base_key, remote_bundle) do
    case get_pending_prekey(store, jid) do
      {:ok, %{base_key: pending_base_key}} when is_binary(pending_base_key) ->
        if Map.get(session, :initiator_base_key) do
          {session, store}
        else
          session = Map.put(session, :initiator_base_key, pending_base_key)
          {session, update_session(store, jid, session)}
        end

      _ ->
        pending_base_key = base_key || bundle_base_key(remote_bundle)

        if is_binary(pending_base_key) do
          session = Map.put(session, :initiator_base_key, pending_base_key)

          store =
            store
            |> update_session(jid, session)
            |> put_pending_prekey(
              jid,
              pending_prekey_from_bundle(pending_base_key, remote_bundle)
            )

          {session, store}
        else
          {session, store}
        end
    end
  end

  defp active_pending_prekey(store, jid, session) do
    session_base_key = Map.get(session, :initiator_base_key)

    case get_pending_prekey(store, jid) do
      {:ok, %{base_key: ^session_base_key} = pending_prekey}
      when is_binary(session_base_key) ->
        pending_prekey

      _ ->
        nil
    end
  end

  defp store_decrypted_session(store, jid, updated_session, decrypted_session) do
    store
    |> update_session(jid, updated_session)
    |> sync_pending_session_aliases(updated_session, decrypted_session)
    |> clear_pending_prekey_for_session(decrypted_session)
  end

  defp sync_pending_session_aliases(store, updated_session, decrypted_session) do
    updated_base_key = Map.get(updated_session, :initiator_base_key)
    decrypted_base_key = Map.get(decrypted_session, :initiator_base_key)

    if is_binary(decrypted_base_key) and updated_base_key == decrypted_base_key do
      store
      |> pending_prekey_jids_for_base(decrypted_base_key)
      |> Enum.reduce(store, &put_session(&2, &1, updated_session))
    else
      store
    end
  end

  defp clear_pending_prekey_for_session(store, session) do
    case Map.get(session, :initiator_base_key) do
      base_key when is_binary(base_key) ->
        matching_jids = pending_prekey_jids_for_base(store, base_key)

        if matching_jids != [] do
          Logger.debug(
            "[SESSION_STORE] Peer message acknowledged pending pre-key session for #{length(matching_jids)} device alias(es)"
          )
        end

        Enum.reduce(matching_jids, store, &delete_pending_prekey(&2, &1))

      _ ->
        store
    end
  end

  defp pending_prekey_jids_for_base(%Ref{table: table}, base_key) do
    :ets.foldl(
      fn
        {{:pending_prekey, jid}, %{base_key: ^base_key}}, acc -> [jid | acc]
        _entry, acc -> acc
      end,
      [],
      table
    )
  end

  defp pending_prekey_jids_for_base(store, base_key) do
    store
    |> Map.get(:pending_prekeys, %{})
    |> Enum.flat_map(fn
      {jid, %{base_key: ^base_key}} -> [jid]
      _entry -> []
    end)
  end

  defp pending_prekey_from_bundle(base_key, remote_bundle) do
    %{
      base_key: base_key,
      prekey_id: bundle_value(remote_bundle, [:prekey, :id]),
      signed_prekey_id: bundle_value(remote_bundle, [:signed_prekey, :id]) || 0
    }
  end

  defp bundle_base_key(remote_bundle), do: Map.get(remote_bundle, :base_key)

  defp bundle_value(remote_bundle, path), do: get_in(remote_bundle, path)

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

  defp with_session_mutation(%Ref{} = store, jids, identity_hints, fun) do
    lock_keys = session_mutation_lock_keys(store, jids, identity_hints)

    case MutationLock.with_locks(lock_keys, fn ->
           run_locked_session_mutation(store, jids, identity_hints, lock_keys, fun)
         end) do
      {:mutation_result, result} -> result
      :retry_mutation_lock -> with_session_mutation(store, jids, identity_hints, fun)
    end
  end

  defp with_session_mutation(_store, _jids, _identity_hints, fun), do: fun.()

  defp run_locked_session_mutation(store, jids, identity_hints, lock_keys, fun) do
    refreshed_keys = session_mutation_lock_keys(store, jids, identity_hints)

    if Enum.all?(refreshed_keys, &(&1 in lock_keys)) do
      {:mutation_result, fun.()}
    else
      :retry_mutation_lock
    end
  end

  defp session_mutation_lock_keys(%Ref{table: table} = store, jids, identity_hints) do
    normalized_jids = jids |> Enum.map(&normalize_jid/1) |> Enum.uniq()

    jid_keys =
      Enum.map(normalized_jids, &{:signal_session, table, {:jid, &1}})

    stored_identities =
      Enum.flat_map(normalized_jids, fn jid ->
        case get_session(store, jid) do
          {:ok, %{remote_identity_key: identity}}
          when is_binary(identity) and byte_size(identity) > 0 ->
            [identity]

          _other ->
            []
        end
      end)

    identity_keys =
      stored_identities
      |> Kernel.++(identity_hints)
      |> Enum.filter(&(is_binary(&1) and byte_size(&1) > 0))
      |> Enum.uniq()
      |> Enum.map(&{:signal_session, table, {:remote_identity, &1}})

    jid_keys ++ identity_keys
  end

  defp remote_identity_hints(%{identity_key: identity})
       when is_binary(identity) and byte_size(identity) > 0,
       do: [identity]

  defp remote_identity_hints(_remote_bundle), do: []

  defp prekey_identity_hints(ciphertext, true) do
    case WireFormat.parse_prekey_signal_message(ciphertext) do
      {:ok, %{identity_key: identity}} when is_binary(identity) -> [identity]
      _other -> []
    end
  end

  defp prekey_identity_hints(_ciphertext, false), do: []

  defp create_session_from_bundle(store, jid, local_identity, remote_bundle) do
    case Signal.create_session(local_identity, remote_bundle) do
      {:ok, session, base_key} ->
        Logger.debug("[SESSION_STORE] Created session using #{Signal.get_impl()} implementation")

        session = Map.put(session, :initiator_base_key, base_key)

        session =
          case get_session(store, jid) do
            {:ok, previous_session} -> retain_previous_session(session, previous_session)
            :not_found -> session
          end

        updated_store =
          store
          |> put_session(jid, session)
          |> put_pending_prekey(jid, pending_prekey_from_bundle(base_key, remote_bundle))

        {:ok, session, base_key, updated_store}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp copy_pending_prekey(store, source_jid, alias_jid) do
    case get_pending_prekey(store, source_jid) do
      {:ok, pending_prekey} -> put_pending_prekey(store, alias_jid, pending_prekey)
      :not_found -> delete_pending_prekey(store, alias_jid)
    end
  end

  defp decrypt_with_previous_sessions(session, ciphertext) do
    previous_sessions = Map.get(session, :previous_sessions, [])

    previous_sessions
    |> Enum.with_index()
    |> Enum.reduce_while({:error, []}, fn {previous_session, index}, {:error, reasons} ->
      case Signal.decrypt(previous_session, ciphertext) do
        {:ok, plaintext, updated_previous_session} ->
          updated_previous_sessions =
            List.replace_at(
              previous_sessions,
              index,
              strip_previous_sessions(updated_previous_session)
            )

          {:halt,
           {:ok, plaintext, Map.put(session, :previous_sessions, updated_previous_sessions),
            updated_previous_session}}

        {:error, reason} ->
          {:cont, {:error, [reason | reasons]}}
      end
    end)
  end

  defp preferred_decrypt_error(current_reason, previous_reasons) do
    Enum.find([current_reason | previous_reasons], &duplicate_key_error?/1) || current_reason
  end

  defp duplicate_key_error?(reason), do: reason == :message_key_not_found

  defp retain_previous_session(new_session, previous_session) do
    if same_remote_identity?(new_session, previous_session) do
      previous_sessions =
        [
          strip_previous_sessions(previous_session)
          | Map.get(previous_session, :previous_sessions, [])
        ]
        |> Enum.uniq_by(&session_fingerprint/1)
        |> Enum.take(@max_previous_sessions)

      Map.put(new_session, :previous_sessions, previous_sessions)
    else
      new_session
    end
  end

  defp same_remote_identity?(left, right) do
    left_identity = Map.get(left, :remote_identity_key)
    is_binary(left_identity) and left_identity == Map.get(right, :remote_identity_key)
  end

  defp strip_previous_sessions(session), do: Map.delete(session, :previous_sessions)

  defp session_fingerprint(session) do
    {
      Map.get(session, :remote_identity_key),
      Map.get(session, :remote_ratchet_key),
      get_in(session, [:ratchet_key, :public])
    }
  end

  @spec prekey_message_debug(binary()) :: map()
  defp prekey_message_debug(ciphertext) when is_binary(ciphertext) do
    case WireFormat.parse_prekey_signal_message(ciphertext) do
      {:ok, parsed} ->
        %{
          registration_id: parsed.registration_id,
          prekey_id: parsed.prekey_id,
          signed_prekey_id: parsed.signed_prekey_id,
          base_key_size: byte_size(parsed.base_key),
          identity_key_size: byte_size(parsed.identity_key),
          inner_size: byte_size(parsed.message)
        }

      {:error, reason} ->
        %{parse_error: reason, ciphertext_size: byte_size(ciphertext)}
    end
  end

  @spec local_prekeys_debug(map(), map()) :: map()
  defp local_prekeys_debug(local_identity, local_prekeys) do
    signed_prekeys = Map.get(local_prekeys, :signed_prekeys, %{})
    prekeys = Map.get(local_prekeys, :prekeys, %{})

    %{
      local_identity_present?: is_binary(Map.get(local_identity, :public)),
      signed_prekey_count: map_size(signed_prekeys),
      signed_prekey_ids: signed_prekeys |> Map.keys() |> Enum.sort() |> Enum.take(12),
      prekey_count: map_size(prekeys),
      prekey_ids: prekeys |> Map.keys() |> Enum.sort() |> Enum.take(12)
    }
  end

  @spec session_debug(map()) :: map()
  defp session_debug(session) when is_map(session) do
    %{
      remote_identity_present?: is_binary(Map.get(session, :remote_identity_key)),
      initiator_base_key_present?: is_binary(Map.get(session, :initiator_base_key)),
      local_identity_present?:
        session
        |> Map.get(:local_identity_key, %{})
        |> Map.get(:public)
        |> is_binary(),
      root_key_present?: is_binary(Map.get(session, :root_key)),
      remote_ratchet_present?: is_binary(Map.get(session, :remote_ratchet_key)),
      sending_counter:
        session
        |> Map.get(:sending_chain)
        |> chain_counter(),
      receiving_counter:
        session
        |> Map.get(:receiving_chain)
        |> chain_counter()
    }
  end

  @spec chain_counter(map() | nil) :: non_neg_integer() | nil
  defp chain_counter(%{counter: counter}) when is_integer(counter), do: counter
  defp chain_counter(_), do: nil
end
