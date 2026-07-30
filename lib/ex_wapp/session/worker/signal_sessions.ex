defmodule ExWapp.Session.Worker.SignalSessions do
  @moduledoc """
  Keeps the session's Signal sessions loaded, pruned and persisted.

  The worker holds Signal sessions in memory and mirrors them to the store; this
  module owns that mirroring, plus the two moments the set is pruned: dropping
  stale one-way sessions when a connection comes up, and clearing a peer's
  sessions when its identity changes.

  Every function returns usable state even when the store misbehaves: losing a
  Signal session costs one renegotiation, whereas crashing the session process
  costs the connection.
  """

  require Logger

  alias ExWapp.Config
  alias ExWapp.Log
  alias ExWapp.Session.Account
  alias ExWapp.Session.Worker
  alias ExWapp.Signal.SessionStore
  alias ExWapp.Store

  @doc "Loads the persisted sessions, falling back to an empty set."
  @spec load(Store.t() | nil) :: SessionStore.t() | nil
  def load(store) do
    store
    |> Store.load_signal_sessions()
    |> normalize()
  rescue
    error ->
      Logger.warning("[SESSION] Failed to load persisted signal sessions: #{Log.reason(error)}")
      nil
  end

  @doc "Mirrors the in-memory sessions to the store, flushing them to disk."
  @spec persist(Store.t() | nil, SessionStore.t()) :: :ok
  def persist(nil, _sessions), do: :ok

  def persist(store, sessions) do
    if SessionStore.store?(sessions) do
      case Store.persist_signal_sessions(store, sessions) do
        :ok ->
          flush(store)

        {:error, reason} ->
          Logger.warning("[SESSION] Failed to persist signal sessions: #{Log.reason(reason)}")
          :ok
      end
    else
      :ok
    end
  rescue
    error ->
      Logger.warning("[SESSION] Failed to persist signal sessions: #{Log.reason(error)}")
      :ok
  end

  @doc """
  Prunes sessions a new connection should not reuse.

  With `signal.reset_sessions_on_connect` every session goes; otherwise only the
  one-way ones, which are the sessions a peer never answered on and which would
  otherwise make the next send undecryptable.
  """
  @spec refresh_on_connect(Worker.t()) :: Worker.t()
  def refresh_on_connect(%{signal_sessions: nil} = state), do: state

  def refresh_on_connect(state) do
    runtime_cfg = Map.get(state, :runtime_cfg) || %{}
    reset? = Config.get(runtime_cfg, [:signal, :reset_sessions_on_connect], false)
    {sessions, dropped} = prune(state.signal_sessions, runtime_cfg, reset?)

    if dropped == [] do
      state
    else
      scope = if reset?, do: "every", else: "one-way"

      Logger.warning(
        "[SESSION] Dropped #{length(dropped)} #{scope} Signal session(s) at connect; " <>
          "the next send to those peers negotiates a fresh one"
      )

      persist(state.store, sessions)
      %{state | signal_sessions: sessions}
    end
  end

  @doc "Forgets every session recorded for one peer, across its JID aliases."
  @spec clear_for_jid(Worker.t(), String.t()) :: Worker.t()
  def clear_for_jid(%{signal_sessions: nil} = state, _jid), do: state

  def clear_for_jid(state, jid) do
    lid_mapping = Account.load_lid_mapping(state.store)
    sessions = SessionStore.delete_sessions_for_user(state.signal_sessions, jid, lid_mapping)
    %{state | signal_sessions: sessions}
  end

  @doc """
  Replaces a peer's session from a freshly fetched prekey bundle.

  Used after an identity change: the old session can no longer decrypt, so it is
  rebuilt with `force: true`. An unusable bundle is logged and the state is left
  alone rather than raising inside the session process.
  """
  @spec install_refreshed_identity(Worker.t(), String.t(), map()) :: Worker.t()
  def install_refreshed_identity(state, jid, bundle) do
    data = Store.load!(state.store)
    local_identity = get_in(data, [:signal, :identity_key])
    local_registration_id = get_in(data, [:signal, :registration_id]) || 0

    with true <- SessionStore.store?(state.signal_sessions),
         %{private: private, public: public} = identity <- local_identity,
         true <- is_binary(private) and is_binary(public),
         target_jid when is_binary(target_jid) <- Map.get(bundle, :jid) || jid,
         {:ok, _session, _base_key, sessions} <-
           SessionStore.get_or_create_session(
             state.signal_sessions,
             target_jid,
             identity,
             bundle,
             local_registration_id,
             force: true
           ) do
      persist(state.store, sessions)
      %{state | signal_sessions: sessions}
    else
      reason ->
        Logger.warning(
          "[IDENTITY] Invalid refreshed bundle for #{Log.reference(jid)}: #{Log.reason(reason)}"
        )

        state
    end
  rescue
    error ->
      Logger.warning(
        "[IDENTITY] Failed installing refreshed bundle for #{Log.reference(jid)}: #{Log.reason(error)}"
      )

      state
  end

  @spec prune(SessionStore.t(), map(), boolean()) :: {SessionStore.t(), [String.t()]}
  defp prune(sessions, _runtime_cfg, true = _reset?) do
    jids = SessionStore.list_sessions(sessions)
    {Enum.reduce(jids, sessions, &SessionStore.delete_session(&2, &1)), jids}
  end

  defp prune(sessions, runtime_cfg, false = _reset?) do
    SessionStore.evict_one_way_sessions(
      sessions,
      Config.get(runtime_cfg, [:signal, :evict_one_way_sessions_after_ms], :timer.hours(1))
    )
  end

  @doc "Coerces a persisted or in-memory session set into the ETS-backed form."
  @spec normalize(term()) :: SessionStore.t()
  def normalize(nil), do: SessionStore.new_ets()
  def normalize(%SessionStore.Ref{} = persisted), do: persisted

  def normalize(%{sessions: sessions} = persisted) when is_map(sessions) do
    SessionStore.new()
    |> Map.merge(persisted)
    |> Map.put(:pending_prekeys, Map.get(persisted, :pending_prekeys, %{}))
    |> Map.put(:session_touched_at_ms, Map.get(persisted, :session_touched_at_ms, %{}))
    |> SessionStore.new_ets()
  end

  def normalize(_), do: SessionStore.new_ets()

  @spec flush(Store.t()) :: :ok
  defp flush(store) do
    case Store.flush(store) do
      :ok -> :ok
      {:error, reason} -> Logger.warning("[SESSION] Failed flushing store: #{Log.reason(reason)}")
    end

    :ok
  rescue
    error ->
      Logger.warning("[SESSION] Failed flushing store: #{Log.reason(error)}")
      :ok
  end
end
