defmodule ExWapp.Session.Worker.PostAuth do
  @moduledoc """
  Post-authentication helpers triggered after the `success` node is received.

  Handles LID persistence, PN↔LID mapping, prekey count queries, and
  prekey upload logic.
  """

  require Logger

  alias ExWapp.{Binary, Config, JID, Log, MapPath, Store}
  alias ExWapp.Session.{JIDUtils, Worker}
  alias ExWapp.Session.Worker.Subscribers

  @min_prekey_threshold 5

  @doc """
  Persists the LID value from the success node and creates own PN↔LID mapping.
  """
  @spec persist_lid_and_mapping(Worker.t(), JID.t() | binary() | nil) :: Worker.t()
  def persist_lid_and_mapping(state, nil), do: state

  def persist_lid_and_mapping(state, %JID{} = lid),
    do: persist_lid_and_mapping(state, JID.to_string(lid))

  def persist_lid_and_mapping(state, lid) when is_binary(lid) do
    Logger.debug("[SESSION] Persisting LID from success")

    Store.transaction(state.store, fn data ->
      client_info = data |> Map.get(:client_info, %{}) |> Map.put(:lid, lid)

      own_pn =
        MapPath.first(data, [
          ["pairing", "device", "jid"],
          ["client_info", "jid"]
        ])

      lid_mapping =
        if own_pn do
          pn_normalized = normalize_jid_string(to_string(own_pn))
          lid_normalized = normalize_jid_string(to_string(lid))

          data
          |> Map.get(:lid_mapping, %{})
          |> Map.put({:pn_to_lid, pn_normalized}, lid_normalized)
          |> Map.put({:lid_to_pn, lid_normalized}, pn_normalized)
        else
          Map.get(data, :lid_mapping, %{})
        end

      data
      |> Map.put(:client_info, client_info)
      |> Map.put(:lid_mapping, lid_mapping)
    end)

    state
  end

  def persist_lid_and_mapping(state, _), do: state

  @doc """
  Starts the post-auth flow after receiving the `success` node.

  To preserve live inbound delivery, the activation path mirrors the older
  working runtime sequence:
  1. query prekey count
  2. send `SetPassive(false)` immediately
  3. send `presence type="available"` immediately
  4. upload prekeys later only if the server count requires it

  Digest validation remains available as an explicit opt-in, but it is disabled
  by default because some fresh-pair sessions are being invalidated immediately
  after the digest IQ is sent.
  """
  @spec start(Worker.t(), (-> Binary.Node.t())) :: {Worker.t(), list()}
  def start(state, build_passive_iq_fun) when is_function(build_passive_iq_fun, 0) do
    prekey_count_query = ExWapp.Prekeys.build_prekey_count_query()
    query_id = Map.get(prekey_count_query.attrs, "id")
    passive_iq = build_passive_iq_fun.()
    passive_iq_id = Map.get(passive_iq.attrs, "id")

    presence_node = %Binary.Node{
      tag: "presence",
      attrs: %{"type" => "available"},
      content: nil
    }

    next_state =
      state
      |> reset_tracking()
      |> Map.put(:post_auth_phase, :awaiting_prekey_count)
      |> Map.put(:prekey_count_query_id, query_id)
      |> Map.put(:passive_iq_id, passive_iq_id)

    Logger.info(
      "[POST_AUTH] starting session=#{Log.reference(Map.get(state, :session_id))} query_id=#{Log.reference(query_id)} passive_iq_id=#{Log.reference(passive_iq_id)} status=#{inspect(Map.get(state, :status))} app_state_keys=#{app_state_key_count(state.store)}"
    )

    Logger.info(
      "[SESSION] Sending prekey count query (id=#{Log.reference(query_id)}) + SetPassive(false) (id=#{Log.reference(passive_iq_id)}) + presence available"
    )

    {next_state,
     [
       {:send_node, prekey_count_query},
       {:send_node, passive_iq},
       {:send_node, presence_node}
     ]}
  end

  @doc """
  Handles the prekey count response from the server and decides whether to upload.

  Returns `{state, actions}`.
  """
  @spec handle_prekey_count_response(Binary.Node.t(), map(), (-> Binary.Node.t())) ::
          {map(), list()}
  def handle_prekey_count_response(%Binary.Node{content: content}, state, build_passive_iq_fun)
      when is_function(build_passive_iq_fun, 0) do
    state = Map.put(state, :prekey_count_query_id, nil)

    server_count = ExWapp.Prekeys.parse_count_response(content)
    Logger.info("[SESSION] Server prekey count: #{server_count}")

    data = Store.load!(state.store)
    signal = Map.get(data, :signal, %{})
    inventory = local_prekey_inventory(signal)
    local_count = inventory.total_count

    Logger.info(
      "[POST_AUTH] prekey count decision session=#{Log.reference(Map.get(state, :session_id))} " <>
        "server_count=#{server_count} local_count=#{local_count} " <>
        "usable_local_count=#{inventory.usable_count} durable_unacked_count=#{inventory.unacked_count} " <>
        "oldest_unacked_age_s=#{inventory.oldest_unacked_age_s || "none"} " <>
        "min_threshold=#{min_prekey_threshold(state)}"
    )

    if inventory.unacked_count > 0 and server_count > min_prekey_threshold(state) do
      Logger.warning(
        "[PREKEYS] Durable unacknowledged key material found while server inventory is healthy; " <>
          "keys are retained and will be reused on the next upload instead of regenerated " <>
          "count=#{inventory.unacked_count}"
      )
    end

    if server_count > inventory.usable_count do
      Logger.error(
        "[PREKEYS] Server advertises more one-time keys than have usable local private halves; " <>
          "inbound pkmsg decrypts may require retry server_count=#{server_count} " <>
          "usable_local_count=#{inventory.usable_count} private_key_deficit=#{server_count - inventory.usable_count}"
      )
    end

    # Baileys logic: if server count == 0 -> INITIAL (812), low -> refill (50)
    # For fresh devices, server_count == 0 always needs full initial upload
    cond do
      server_count == 0 ->
        Logger.debug(
          "[SESSION] No prekeys on server, uploading initial batch (local=#{local_count})"
        )

        do_prekey_upload(state, build_passive_iq_fun, initial: true)

      server_count <= min_prekey_threshold(state) ->
        Logger.debug("[SESSION] Server prekeys low (#{server_count}), uploading refill batch")
        do_prekey_upload(state, build_passive_iq_fun, initial: false)

      true ->
        Logger.debug(
          "[SESSION] Prekey count OK (server=#{server_count}, local=#{local_count}), skipping upload"
        )

        state
        |> sync_post_auth_phase_after_prekey_step()
        |> maybe_send_passive_iq(build_passive_iq_fun)
    end
  end

  @doc """
  Handles the response to a prekey upload IQ.
  """
  @spec handle_prekey_upload_response(Binary.Node.t(), String.t(), map(), (-> Binary.Node.t())) ::
          {map(), list()}
  def handle_prekey_upload_response(_node, "result", state, build_passive_iq_fun)
      when is_function(build_passive_iq_fun, 0) do
    pending_prekeys = Map.get(state, :pending_prekey_upload, [])

    upload_mark_result = ExWapp.Prekeys.mark_uploaded(state.store, pending_prekeys)

    if upload_mark_result != :ok do
      Logger.warning(
        "[PREKEYS] Server acknowledged upload but local uploaded-state marking failed; " <>
          "private keys remain durable and will be safe to retry reason=#{Log.reason(upload_mark_result)}"
      )
    end

    state =
      state
      |> Map.put(:prekey_upload_iq_id, nil)
      |> Map.put(:pending_prekey_upload, [])
      |> sync_post_auth_phase_after_prekey_step()

    Logger.info(
      "[POST_AUTH] prekey upload acknowledged session=#{Log.reference(Map.get(state, :session_id))} " <>
        "uploaded_count=#{length(pending_prekeys)} local_marked?=#{upload_mark_result == :ok}"
    )

    announce_key_material(state, pending_prekeys)

    Logger.debug("[SESSION] Prekey upload acknowledged, continuing post-auth")
    maybe_send_passive_iq(state, build_passive_iq_fun)
  end

  def handle_prekey_upload_response(node, "error", state, build_passive_iq_fun)
      when is_function(build_passive_iq_fun, 0) do
    reserved_count = state |> Map.get(:pending_prekey_upload, []) |> length()

    Logger.warning("[SESSION] Prekey upload failed: #{inspect(Log.attrs(node.attrs || %{}))}")

    state =
      state
      |> Map.put(:prekey_upload_iq_id, nil)
      |> Map.put(:pending_prekey_upload, [])
      |> sync_post_auth_phase_after_prekey_step()

    Logger.warning(
      "[POST_AUTH] prekey upload returned error session=#{Log.reference(Map.get(state, :session_id))} " <>
        "durable_reserved_count=#{reserved_count} will_reuse=true " <>
        "attrs=#{inspect(Log.attrs(node.attrs || %{}), limit: 50)}"
    )

    maybe_send_passive_iq(state, build_passive_iq_fun)
  end

  # The server now hands these public halves to any peer that asks. Their private
  # halves live in the store, which a host archives on its own schedule — so
  # until that archive catches up, a lost process leaves the server advertising
  # keys nothing can decrypt with. The host is told the moment the gap opens
  # rather than being left to pick an interval narrow enough to hide it.
  defp announce_key_material(state, prekeys) do
    highest_id =
      prekeys
      |> Enum.map(&(Map.get(&1, :key_id) || Map.get(&1, :id)))
      |> Enum.filter(&(is_integer(&1) and &1 > 0))
      |> Enum.max(fn -> nil end)

    case Map.get(state, :session_id) do
      session_id when is_binary(session_id) and highest_id != nil ->
        Subscribers.broadcast_lifecycle(
          session_id,
          {:ex_wapp_session, :key_material_advertised,
           %{
             session_id: session_id,
             reason: :prekey_upload,
             highest_prekey_id: highest_id,
             count: length(prekeys)
           }}
        )

      _no_session_or_keys ->
        :ok
    end
  end

  @doc """
  Handles the response to SetPassive(false) and finalizes post-auth by default.

  Digest validation can be re-enabled with `runtime: [protocol: [post_auth_digest_enabled: true]]`.
  """
  @spec handle_passive_response(
          Binary.Node.t(),
          String.t(),
          map(),
          (-> Binary.Node.t()),
          (-> Binary.Node.t())
        ) ::
          {map(), list()}
  def handle_passive_response(
        _node,
        iq_type,
        state,
        build_digest_query_fun,
        build_unified_session_fun
      )
      when is_function(build_digest_query_fun, 0) and is_function(build_unified_session_fun, 0) do
    if iq_type == "error" do
      Logger.warning("[SESSION] SetPassive(false) returned error, continuing post-auth")
    end

    Logger.info(
      "[POST_AUTH] passive response session=#{Log.reference(Map.get(state, :session_id))} iq_type=#{iq_type} digest_enabled=#{digest_enabled?(state)}"
    )

    state =
      state
      |> Map.put(:passive_iq_id, nil)
      |> Map.put(:digest_iq_id, nil)

    if digest_enabled?(state) do
      digest_query = build_digest_query_fun.()
      digest_iq_id = Map.get(digest_query.attrs, "id")

      next_state =
        state
        |> Map.put(:digest_iq_id, digest_iq_id)
        |> Map.put(:post_auth_phase, :awaiting_digest)

      Logger.debug("[SESSION] Sending digest query (id=#{Log.reference(digest_iq_id)})")
      {next_state, [{:send_node, digest_query}]}
    else
      Logger.debug("[SESSION] Skipping digest query, proceeding directly to unified_session")

      next_state =
        state
        |> Map.put(:post_auth_phase, :complete)

      {next_state, [{:send_node, build_unified_session_fun.()}, :mark_authenticated]}
    end
  end

  @doc """
  Refills the server prekey pool after an `encrypt` inventory notification.

  The upload restores the pool toward the configured initial size instead of
  adding only a tiny fixed batch. An already in-flight upload is left alone.
  """
  @spec refill_from_notification(Worker.t(), non_neg_integer()) :: {Worker.t(), list()}
  def refill_from_notification(%{prekey_upload_iq_id: request_id} = state, _server_count)
      when is_binary(request_id),
      do: {state, []}

  def refill_from_notification(state, server_count)
      when is_integer(server_count) and server_count >= 0 do
    runtime_cfg = Map.get(state, :runtime_cfg) || %{}
    initial_count = Config.get(runtime_cfg, [:prekeys, :initial_prekey_count], 812)
    refill_count = Config.get(runtime_cfg, [:prekeys, :refill_prekey_count], 50)
    upload_count = max(refill_count, initial_count - server_count)

    case ExWapp.Prekeys.build_prekey_upload(state.store,
           runtime_cfg: runtime_cfg,
           count: upload_count
         ) do
      {:ok, prekey_node, prekeys} ->
        request_id = Map.get(prekey_node.attrs, "id")

        next_state =
          state
          |> Map.put(:prekey_upload_iq_id, request_id)
          |> Map.put(:pending_prekey_upload, prekeys)

        Logger.debug(
          "[PREKEYS] Refilling #{length(prekeys)} keys after server inventory=#{server_count}"
        )

        {next_state, [{:send_node, prekey_node}]}

      {:error, reason} ->
        Logger.warning("[PREKEYS] Notification refill failed: #{Log.reason(reason)}")
        {state, []}
    end
  end

  @doc """
  Handles the response to the digest query and finalizes post-auth.
  """
  @spec handle_digest_response(Binary.Node.t(), String.t(), map(), (-> Binary.Node.t())) ::
          {map(), list()}
  def handle_digest_response(
        %Binary.Node{content: content},
        iq_type,
        state,
        build_unified_session_fun
      )
      when is_function(build_unified_session_fun, 0) do
    if iq_type == "error" do
      Logger.warning("[SESSION] Digest query returned error, continuing")
    else
      has_digest? =
        Enum.any?(content || [], fn
          %Binary.Node{tag: "digest"} -> true
          _ -> false
        end)

      if not has_digest? do
        Logger.warning("[SESSION] Digest response contained no digest node, continuing")
      end
    end

    Logger.info(
      "[POST_AUTH] digest response session=#{Log.reference(Map.get(state, :session_id))} iq_type=#{iq_type}"
    )

    next_state =
      state
      |> Map.put(:digest_iq_id, nil)
      |> Map.put(:post_auth_phase, :complete)

    {next_state, [{:send_node, build_unified_session_fun.()}, :mark_authenticated]}
  end

  # -- Internal helpers -------------------------------------------------------

  defp do_prekey_upload(state, build_passive_iq_fun, opts) do
    case ExWapp.Prekeys.build_prekey_upload(
           state.store,
           Keyword.put(opts, :runtime_cfg, state.runtime_cfg || %{})
         ) do
      {:ok, prekey_node, prekeys} ->
        initial = Keyword.get(opts, :initial, false)
        request_id = Map.get(prekey_node.attrs, "id")

        Logger.debug(
          "[SESSION] Uploading prekeys (initial=#{initial}, count=#{length(prekeys)}, id=#{Log.reference(request_id)})"
        )

        Logger.debug(
          "[POST_AUTH] upload prekeys session=#{Log.reference(Map.get(state, :session_id))} initial=#{initial} request_id=#{Log.reference(request_id)} count=#{length(prekeys)}"
        )

        next_state =
          state
          |> put_prekey_phase(:awaiting_prekey_upload)
          |> Map.put(:prekey_upload_iq_id, request_id)
          |> Map.put(:pending_prekey_upload, prekeys)

        {next_state, [{:send_node, prekey_node}]}

      {:error, reason} ->
        Logger.warning("[SESSION] Cannot upload prekeys: #{Log.reason(reason)}")
        maybe_send_passive_iq(state, build_passive_iq_fun)
    end
  end

  defp maybe_send_passive_iq(%{passive_iq_id: passive_iq_id} = state, _build_passive_iq_fun)
       when is_binary(passive_iq_id) do
    Logger.debug(
      "[POST_AUTH] passive iq already in flight session=#{Log.reference(Map.get(state, :session_id))} request_id=#{Log.reference(passive_iq_id)}"
    )

    {Map.put(state, :post_auth_phase, :awaiting_passive_ack), []}
  end

  defp maybe_send_passive_iq(%{post_auth_phase: :complete} = state, _build_passive_iq_fun) do
    Logger.debug(
      "[POST_AUTH] passive iq already completed session=#{Log.reference(Map.get(state, :session_id))}"
    )

    {state, []}
  end

  defp maybe_send_passive_iq(%{post_auth_phase: :awaiting_digest} = state, _build_passive_iq_fun),
    do: {state, []}

  defp maybe_send_passive_iq(state, build_passive_iq_fun),
    do: send_passive_iq(state, build_passive_iq_fun)

  defp send_passive_iq(state, build_passive_iq_fun) when is_function(build_passive_iq_fun, 0) do
    passive_iq = build_passive_iq_fun.()
    request_id = Map.get(passive_iq.attrs, "id")

    next_state =
      state
      |> Map.put(:post_auth_phase, :awaiting_passive_ack)
      |> Map.put(:passive_iq_id, request_id)

    Logger.info(
      "[POST_AUTH] sending passive iq session=#{Log.reference(Map.get(state, :session_id))} request_id=#{Log.reference(request_id)}"
    )

    Logger.debug("[SESSION] Sending SetPassive(false) (id=#{Log.reference(request_id)})")
    {next_state, [{:send_node, passive_iq}]}
  end

  defp sync_post_auth_phase_after_prekey_step(%{passive_iq_id: passive_iq_id} = state)
       when is_binary(passive_iq_id) do
    put_prekey_phase(state, :awaiting_passive_ack)
  end

  defp sync_post_auth_phase_after_prekey_step(state) do
    put_prekey_phase(state, :idle)
  end

  # Activation runs concurrently with the prekey query/upload. Late prekey
  # responses must not undo an acknowledged activation or restart its digest.
  defp put_prekey_phase(%{post_auth_phase: phase} = state, _next_phase)
       when phase in [:complete, :awaiting_digest],
       do: state

  defp put_prekey_phase(state, phase), do: Map.put(state, :post_auth_phase, phase)

  defp reset_tracking(state) do
    state
    |> Map.put(:prekey_count_query_id, nil)
    |> Map.put(:prekey_upload_iq_id, nil)
    |> Map.put(:pending_prekey_upload, [])
    |> Map.put(:passive_iq_id, nil)
    |> Map.put(:digest_iq_id, nil)
  end

  defp normalize_jid_string(jid) when is_binary(jid) do
    jid
    |> JIDUtils.normalize_with_device()
    |> JIDUtils.strip_device()
  end

  defp min_prekey_threshold(state) do
    Config.get(state.runtime_cfg || %{}, [:prekeys, :min_threshold], @min_prekey_threshold)
  end

  defp digest_enabled?(state) do
    Config.get(state.runtime_cfg || %{}, [:protocol, :post_auth_digest_enabled], false)
  end

  defp app_state_key_count(store) do
    store
    |> Store.load!()
    |> Map.get(:app_state_keys, %{})
    |> map_size()
  rescue
    _ -> 0
  end

  defp local_prekey_inventory(signal) do
    prekeys = Map.get(signal, :prekeys, %{})

    usable_prekeys =
      Enum.filter(prekeys, fn
        {_id, %{public: public, private: private}}
        when is_binary(public) and byte_size(public) == 32 and is_binary(private) and
               byte_size(private) == 32 ->
          true

        _entry ->
          false
      end)

    unacknowledged =
      Enum.filter(usable_prekeys, fn {_id, prekey} ->
        Map.get(prekey, :uploaded, true) == false
      end)

    oldest_generated_at =
      unacknowledged
      |> Enum.map(fn {_id, prekey} -> Map.get(prekey, :generated_at) end)
      |> Enum.filter(&is_integer/1)
      |> Enum.min(fn -> nil end)

    %{
      total_count: map_size(prekeys),
      usable_count: length(usable_prekeys),
      unacked_count: length(unacknowledged),
      oldest_unacked_age_s:
        if(is_integer(oldest_generated_at),
          do: max(System.system_time(:second) - oldest_generated_at, 0),
          else: nil
        )
    }
  end
end
