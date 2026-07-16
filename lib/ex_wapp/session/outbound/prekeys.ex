defmodule ExWapp.Session.Outbound.Prekeys do
  @moduledoc """
  Prekey target decisions and Signal-session bootstrap for outbound messages.

  Raw network requests, response receives, and persistence remain in the
  outbound worker. This module owns deterministic target selection, batch and
  individual fallback decisions, missing-bundle retries, and the transformation
  of parsed prekey bundles into Signal sessions.
  """

  require Logger

  alias ExWapp.Log
  alias ExWapp.Session.JIDUtils
  alias ExWapp.Signal.SessionStore

  @type fetch_result :: {:ok, SessionStore.t(), map()} | {:error, term()}
  @type fetch_many_fun :: ([String.t()], SessionStore.t() -> fetch_result())
  @type fetch_one_fun :: (String.t(), SessionStore.t() -> fetch_result())
  @type fetch_state :: SessionStore.t() | {:error, term()}

  @doc """
  Fetches direct-message prekeys with batch fallback and missing-bundle retry.
  """
  @spec fetch_direct(
          [String.t()],
          SessionStore.t(),
          String.t(),
          fetch_many_fun(),
          fetch_one_fun()
        ) :: {fetch_state(), map()}
  def fetch_direct(
        devices_needing_prekeys,
        signal_sessions,
        recipient_base_jid,
        fetch_many_fun,
        fetch_one_fun
      )
      when is_list(devices_needing_prekeys) and is_function(fetch_many_fun, 2) and
             is_function(fetch_one_fun, 2) do
    {updated_sessions, prekey_bundles} =
      fetch_needed(
        devices_needing_prekeys,
        signal_sessions,
        recipient_base_jid,
        fetch_many_fun,
        fetch_one_fun
      )

    retry_missing(
      devices_needing_prekeys,
      updated_sessions,
      prekey_bundles,
      "dm",
      fetch_one_fun
    )
  end

  @doc """
  Fetches group distribution prekeys with batch and individual fallback.

  Missing bundles are retried individually after the initial result.
  """
  @spec fetch_group(
          [String.t()],
          SessionStore.t(),
          term(),
          fetch_many_fun(),
          fetch_one_fun()
        ) :: {fetch_state(), map()}
  def fetch_group([], signal_sessions, _context, _fetch_many_fun, _fetch_one_fun) do
    {signal_sessions, %{}}
  end

  def fetch_group(
        devices_needing_prekeys,
        signal_sessions,
        context,
        fetch_many_fun,
        fetch_one_fun
      )
      when is_list(devices_needing_prekeys) and is_function(fetch_many_fun, 2) and
             is_function(fetch_one_fun, 2) do
    Logger.debug("[SEND] Fetching group prekeys for #{length(devices_needing_prekeys)} devices")

    {updated_sessions, prekey_bundles} =
      case fetch_many_fun.(devices_needing_prekeys, signal_sessions) do
        {:ok, sessions, bundles} ->
          {sessions, bundles}

        {:error, reason} ->
          Logger.warning(
            "[SEND] Group batch prekey fetch failed: #{Log.reason(reason)}, retrying individually"
          )

          case fetch_individually(devices_needing_prekeys, signal_sessions, fetch_one_fun) do
            {:ok, sessions, bundles} -> {sessions, bundles}
            {:error, fallback_reason} -> {{:error, fallback_reason}, %{}}
          end
      end

    retry_missing(
      devices_needing_prekeys,
      updated_sessions,
      prekey_bundles,
      context,
      fetch_one_fun
    )
  end

  @spec fetch_needed(
          [String.t()],
          SessionStore.t(),
          String.t(),
          fetch_many_fun(),
          fetch_one_fun()
        ) :: {fetch_state(), map()}
  defp fetch_needed([], signal_sessions, _recipient_base_jid, _fetch_many_fun, _fetch_one_fun) do
    {signal_sessions, %{}}
  end

  defp fetch_needed(
         devices_needing_prekeys,
         signal_sessions,
         recipient_base_jid,
         fetch_many_fun,
         fetch_one_fun
       ) do
    Logger.debug("[SEND] Fetching prekeys for #{length(devices_needing_prekeys)} devices")

    case fetch_many_fun.(devices_needing_prekeys, signal_sessions) do
      {:ok, sessions, bundles} ->
        {sessions, bundles}

      {:error, reason} ->
        Logger.warning(
          "[SEND] Batch prekey fetch failed: #{Log.reason(reason)}, trying individual"
        )

        case fetch_one_fun.(recipient_base_jid, signal_sessions) do
          {:ok, sessions, bundles} -> {sessions, bundles}
          {:error, fallback_reason} -> {{:error, fallback_reason}, %{}}
        end
    end
  end

  @spec retry_missing([term()], fetch_state(), term(), term(), fetch_one_fun()) ::
          {fetch_state(), map()}
  defp retry_missing(
         _requested_device_jids,
         {:error, _reason} = error,
         _prekey_bundles,
         _context,
         _fetch_one_fun
       ) do
    {error, %{}}
  end

  defp retry_missing(
         requested_device_jids,
         sessions,
         prekey_bundles,
         context,
         fetch_one_fun
       ) do
    prekey_bundles = if is_map(prekey_bundles), do: prekey_bundles, else: %{}

    if SessionStore.store?(sessions) do
      retry_missing_from_store(
        requested_device_jids,
        sessions,
        prekey_bundles,
        context,
        fetch_one_fun
      )
    else
      {sessions, prekey_bundles}
    end
  end

  @spec retry_missing_from_store(
          [term()],
          SessionStore.t(),
          map(),
          term(),
          fetch_one_fun()
        ) :: {SessionStore.t(), map()}
  defp retry_missing_from_store(
         requested_device_jids,
         sessions,
         prekey_bundles,
         context,
         fetch_one_fun
       ) do
    missing =
      requested_device_jids
      |> missing_bundle_targets(prekey_bundles)
      |> Enum.sort()

    if missing == [] do
      {sessions, prekey_bundles}
    else
      fetch_missing_individually(
        missing,
        sessions,
        prekey_bundles,
        context,
        fetch_one_fun
      )
    end
  end

  @spec fetch_missing_individually(
          [String.t()],
          SessionStore.t(),
          map(),
          term(),
          fetch_one_fun()
        ) :: {SessionStore.t(), map()}
  defp fetch_missing_individually(
         missing,
         sessions,
         prekey_bundles,
         context,
         fetch_one_fun
       ) do
    Logger.warning(
      "[SEND] Missing #{context} prekey bundles for #{length(missing)} device(s), retrying individually"
    )

    case fetch_individually(missing, sessions, fetch_one_fun) do
      {:ok, retried_sessions, retried_bundles} ->
        {retried_sessions, Map.merge(prekey_bundles, retried_bundles)}

      {:error, reason} ->
        Logger.warning("[SEND] Individual #{context} prekey retry failed: #{Log.reason(reason)}")
        {sessions, prekey_bundles}
    end
  end

  @spec fetch_individually([String.t()], SessionStore.t(), fetch_one_fun()) :: fetch_result()
  defp fetch_individually(device_jids, signal_sessions, fetch_one_fun) do
    Enum.reduce_while(
      device_jids,
      {:ok, signal_sessions, %{}},
      fn device_jid, {:ok, sessions, bundles} ->
        case fetch_one_fun.(device_jid, sessions) do
          {:ok, updated_sessions, fetched_bundles} ->
            {:cont, {:ok, updated_sessions, Map.merge(bundles, fetched_bundles)}}

          {:error, reason} ->
            {:halt, {:error, {:prekey_fetch_failed, device_jid, reason}}}
        end
      end
    )
  end

  @doc """
  Returns outbound devices that require a prekey bootstrap.

  Local-account identities are always refreshed. Other targets are selected
  when their PN/LID session is missing or older than the configured maximum.
  """
  @spec devices_needing_prekeys(
          SessionStore.t(),
          [term()],
          [term()],
          map(),
          pos_integer(),
          integer()
        ) :: [String.t()]
  def devices_needing_prekeys(
        signal_sessions,
        target_jids,
        own_device_jids,
        lid_mapping,
        session_max_age_ms,
        now_ms
      ) do
    targets_needing_prekeys(
      signal_sessions,
      target_jids,
      identity_set(own_device_jids),
      lid_mapping,
      session_max_age_ms,
      now_ms
    )
  end

  @doc """
  Selects targets requiring prekeys with an explicit forced identity set.

  This form is shared by group sender-key distribution.
  """
  @spec targets_needing_prekeys(
          SessionStore.t(),
          [term()],
          MapSet.t({String.t(), String.t()}),
          map(),
          pos_integer(),
          integer()
        ) :: [String.t()]
  def targets_needing_prekeys(
        signal_sessions,
        target_jids,
        forced_identity_set,
        lid_mapping,
        session_max_age_ms,
        now_ms
      )
      when is_list(target_jids) and is_struct(forced_identity_set, MapSet) and
             is_map(lid_mapping) and is_integer(session_max_age_ms) and
             session_max_age_ms > 0 and is_integer(now_ms) do
    target_jids
    |> Enum.filter(fn target_jid ->
      target_needs_prekey?(
        target_jid,
        signal_sessions,
        forced_identity_set,
        lid_mapping,
        session_max_age_ms,
        now_ms
      )
    end)
    |> JIDUtils.normalize_target_list()
  end

  @doc """
  Expands a partial recipient prekey selection to all known recipient devices.
  """
  @spec expand_recipient_identity_targets([term()], [term()]) :: [String.t()]
  def expand_recipient_identity_targets(devices_needing_prekeys, recipient_devices) do
    devices_needing_prekeys = JIDUtils.normalize_target_list(devices_needing_prekeys)
    recipient_devices = JIDUtils.normalize_target_list(recipient_devices)
    recipient_identity_set = identity_set(recipient_devices)

    if recipient_devices != [] and
         Enum.any?(devices_needing_prekeys, fn device_jid ->
           MapSet.member?(recipient_identity_set, JIDUtils.identity(device_jid))
         end) do
      JIDUtils.normalize_target_list(recipient_devices ++ devices_needing_prekeys)
    else
      devices_needing_prekeys
    end
  end

  @doc """
  Returns requested device JIDs for which no prekey bundle was returned.
  """
  @spec missing_bundle_targets([term()], map()) :: [String.t()]
  def missing_bundle_targets(requested_device_jids, prekey_bundles)
      when is_map(prekey_bundles) do
    requested =
      requested_device_jids
      |> JIDUtils.normalize_target_list()
      |> MapSet.new()

    returned =
      prekey_bundles
      |> Map.keys()
      |> JIDUtils.normalize_target_list()
      |> MapSet.new()

    requested
    |> MapSet.difference(returned)
    |> MapSet.to_list()
  end

  @doc """
  Creates Signal sessions and bundle aliases from parsed prekey bundles.
  """
  @spec create_sessions_for_bundles(
          SessionStore.t(),
          term(),
          [map()],
          term(),
          non_neg_integer(),
          map()
        ) :: {:ok, SessionStore.t(), map()} | {:error, term()}
  def create_sessions_for_bundles(
        signal_sessions,
        requested_jid,
        bundles,
        local_identity,
        local_reg_id,
        lid_mapping
      )
      when is_list(bundles) and is_map(lid_mapping) do
    requested_jid = JIDUtils.normalize_for_signal(requested_jid)

    bundles
    |> Enum.reduce_while({:ok, signal_sessions, %{}}, fn bundle, acc ->
      create_session_for_bundle(
        bundle,
        requested_jid,
        acc,
        local_identity,
        local_reg_id,
        lid_mapping
      )
    end)
    |> finalize_bundle_session_creation()
  end

  @spec identity_set([term()]) :: MapSet.t({String.t(), String.t()})
  defp identity_set(jids) do
    jids
    |> Enum.map(&JIDUtils.identity/1)
    |> Enum.reject(fn {user, server} -> user == "" or server == "" end)
    |> MapSet.new()
  end

  @spec target_needs_prekey?(
          term(),
          SessionStore.t(),
          MapSet.t({String.t(), String.t()}),
          map(),
          pos_integer(),
          integer()
        ) :: boolean()
  defp target_needs_prekey?(
         target_jid,
         signal_sessions,
         forced_identity_set,
         lid_mapping,
         session_max_age_ms,
         now_ms
       ) do
    target_jid = JIDUtils.normalize_with_device(target_jid)
    signal_jid = JIDUtils.resolve_signal_encryption_jid(target_jid, lid_mapping)
    target_identity = JIDUtils.identity(target_jid)

    has_session =
      SessionStore.has_session?(signal_sessions, signal_jid) or
        SessionStore.has_session?(signal_sessions, target_jid)

    MapSet.member?(forced_identity_set, target_identity) or
      not has_session or
      SessionStore.stale_or_missing?(
        signal_sessions,
        [signal_jid, target_jid],
        session_max_age_ms,
        now_ms
      )
  end

  @spec create_session_for_bundle(
          map(),
          String.t(),
          {:ok, SessionStore.t(), map()},
          term(),
          non_neg_integer(),
          map()
        ) :: {:cont, {:ok, SessionStore.t(), map()}} | {:halt, {:error, term()}}
  defp create_session_for_bundle(
         bundle,
         requested_jid,
         {:ok, sessions, bundle_map},
         local_identity,
         local_reg_id,
         lid_mapping
       ) do
    {device_jid, signal_jid} = resolve_bundle_jids(bundle, requested_jid, lid_mapping)

    if device_jid == "" do
      {:halt, {:error, :invalid_device_jid}}
    else
      Logger.debug(
        "[PREKEY] Creating session for wire_jid=#{Log.reference(device_jid)} signal_jid=#{Log.reference(signal_jid)} (request_jid=#{Log.reference(requested_jid)})"
      )

      create_bundle_session(
        sessions,
        bundle,
        requested_jid,
        signal_jid,
        device_jid,
        bundle_map,
        local_identity,
        local_reg_id
      )
    end
  end

  @spec create_bundle_session(
          SessionStore.t(),
          map(),
          String.t(),
          String.t(),
          String.t(),
          map(),
          term(),
          non_neg_integer()
        ) :: {:cont, {:ok, SessionStore.t(), map()}} | {:halt, {:error, term()}}
  defp create_bundle_session(
         sessions,
         bundle,
         requested_jid,
         signal_jid,
         device_jid,
         bundle_map,
         local_identity,
         local_reg_id
       ) do
    case SessionStore.get_or_create_session(
           sessions,
           signal_jid,
           local_identity,
           bundle,
           local_reg_id,
           force: true
         ) do
      {:ok, created_session, base_key, updated_sessions} ->
        {:cont,
         finalize_created_bundle_session(
           bundle,
           requested_jid,
           signal_jid,
           device_jid,
           created_session,
           base_key,
           updated_sessions,
           bundle_map
         )}

      {:error, reason} ->
        {:halt, {:error, {:session_create_failed, device_jid, reason}}}
    end
  end

  @spec resolve_bundle_jids(map(), String.t(), map()) :: {String.t(), String.t()}
  defp resolve_bundle_jids(bundle, requested_jid, lid_mapping) do
    device_jid =
      bundle
      |> Map.get(:device_jid, requested_jid)
      |> JIDUtils.normalize_with_device()
      |> case do
        "" -> requested_jid
        jid -> jid
      end

    signal_jid =
      device_jid
      |> JIDUtils.resolve_signal_encryption_jid(lid_mapping)
      |> case do
        "" -> device_jid
        jid -> jid
      end

    {device_jid, signal_jid}
  end

  @spec finalize_created_bundle_session(
          map(),
          String.t(),
          String.t(),
          String.t(),
          map(),
          binary() | nil,
          SessionStore.t(),
          map()
        ) :: {:ok, SessionStore.t(), map()}
  defp finalize_created_bundle_session(
         bundle,
         requested_jid,
         signal_jid,
         device_jid,
         created_session,
         base_key,
         updated_sessions,
         bundle_map
       ) do
    updated_sessions =
      updated_sessions
      |> maybe_alias_signal_session(requested_jid, signal_jid, created_session)
      |> maybe_alias_signal_session(device_jid, signal_jid, created_session)

    Logger.debug(
      "[PREKEY] Session ready for wire_jid=#{Log.reference(device_jid)} signal_jid=#{Log.reference(signal_jid)}, base_key=#{if base_key, do: byte_size(base_key), else: "nil"} bytes"
    )

    bundle_with_info =
      bundle
      |> Map.put(:base_key, base_key)
      |> Map.put(:device_jid, device_jid)
      |> Map.put(:signal_jid, signal_jid)

    bundle_map =
      bundle_map
      |> Map.put(device_jid, bundle_with_info)
      |> maybe_put_bundle_alias(signal_jid, device_jid, bundle_with_info)

    {:ok, updated_sessions, bundle_map}
  end

  @spec finalize_bundle_session_creation({:ok, SessionStore.t(), map()} | {:error, term()}) ::
          {:ok, SessionStore.t(), map()} | {:error, term()}
  defp finalize_bundle_session_creation({:ok, updated_sessions, bundle_map})
       when map_size(bundle_map) > 0,
       do: {:ok, updated_sessions, bundle_map}

  defp finalize_bundle_session_creation({:ok, _updated_sessions, _bundle_map}),
    do: {:error, :no_sessions_created}

  defp finalize_bundle_session_creation({:error, reason}), do: {:error, reason}

  @spec maybe_put_bundle_alias(map(), term(), term(), map()) :: map()
  defp maybe_put_bundle_alias(bundle_map, alias_jid, source_jid, bundle)
       when is_binary(alias_jid) and is_binary(source_jid) and alias_jid != "" and
              source_jid != "" and alias_jid != source_jid do
    Map.put(bundle_map, alias_jid, bundle)
  end

  defp maybe_put_bundle_alias(bundle_map, _alias_jid, _source_jid, _bundle),
    do: bundle_map

  @spec maybe_alias_signal_session(SessionStore.t(), term(), term(), map()) ::
          SessionStore.t()
  defp maybe_alias_signal_session(signal_sessions, requested_jid, device_jid, session) do
    requested_jid = JIDUtils.normalize_with_device(requested_jid)
    device_jid = JIDUtils.normalize_with_device(device_jid)

    if requested_jid != "" and device_jid != "" and requested_jid != device_jid and
         not SessionStore.has_session?(signal_sessions, requested_jid) do
      Logger.debug(
        "[PREKEY] Aliasing session #{Log.reference(requested_jid)} -> #{Log.reference(device_jid)}"
      )

      SessionStore.put_session(signal_sessions, requested_jid, session)
    else
      signal_sessions
    end
  end
end
