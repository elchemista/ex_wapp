defmodule ExWapp.Session.Worker.PostAuth do
  @moduledoc """
  Post-authentication helpers triggered after the `success` node is received.

  Handles LID persistence, PN↔LID mapping, prekey count queries, and
  prekey upload logic.
  """

  require Logger

  alias ExWapp.{Binary, Config, MapPath, Store}

  @min_prekey_threshold 5

  @doc """
  Persists the LID value from the success node and creates own PN↔LID mapping.
  """
  @spec persist_lid_and_mapping(map(), binary() | nil) :: map()
  def persist_lid_and_mapping(state, nil), do: state

  def persist_lid_and_mapping(state, lid) when is_binary(lid) do
    Logger.debug("[SESSION] LID from success: #{inspect(lid)}")

    data = Store.load!(state.store)

    # Persist LID in client_info
    client_info = Map.get(data, :client_info, %{})
    client_info = Map.put(client_info, :lid, lid)

    # Create own PN<->LID mapping (Baileys: storeLIDPNMappings)
    own_pn =
      MapPath.first(data, [
        ["pairing", "device", "jid"],
        ["client_info", "jid"]
      ])

    lid_mapping = Map.get(data, :lid_mapping, %{})

    lid_mapping =
      if own_pn do
        pn_normalized = normalize_jid_string(to_string(own_pn))
        lid_normalized = normalize_jid_string(to_string(lid))

        Logger.debug(
          "[SESSION] Storing own PN<->LID mapping: #{pn_normalized} <-> #{lid_normalized}"
        )

        lid_mapping
        |> Map.put({:pn_to_lid, pn_normalized}, lid_normalized)
        |> Map.put({:lid_to_pn, lid_normalized}, pn_normalized)
      else
        lid_mapping
      end

    data =
      data
      |> Map.put(:client_info, client_info)
      |> Map.put(:lid_mapping, lid_mapping)

    Store.persist(state.store, data)
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
  @spec start(map(), (-> Binary.Node.t())) :: {map(), list()}
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
      "[POST_AUTH] starting session_id=#{inspect(Map.get(state, :session_id))} query_id=#{query_id} passive_iq_id=#{passive_iq_id} status=#{inspect(Map.get(state, :status))} app_state_keys=#{app_state_key_count(state.store)}"
    )

    Logger.info(
      "[SESSION] Sending prekey count query (id=#{query_id}) + SetPassive(false) (id=#{passive_iq_id}) + presence available"
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
    local_count = signal |> Map.get(:prekeys, %{}) |> map_size()

    Logger.info(
      "[POST_AUTH] prekey count decision session_id=#{inspect(Map.get(state, :session_id))} server_count=#{server_count} local_count=#{local_count} min_threshold=#{min_prekey_threshold(state)}"
    )

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
    persist_uploaded_prekeys(state.store, pending_prekeys)

    state =
      state
      |> Map.put(:prekey_upload_iq_id, nil)
      |> Map.put(:pending_prekey_upload, [])
      |> sync_post_auth_phase_after_prekey_step()

    Logger.info(
      "[POST_AUTH] prekey upload acknowledged session_id=#{inspect(Map.get(state, :session_id))} uploaded_count=#{length(pending_prekeys)}"
    )

    Logger.debug("[SESSION] Prekey upload acknowledged, continuing post-auth")
    maybe_send_passive_iq(state, build_passive_iq_fun)
  end

  def handle_prekey_upload_response(node, "error", state, build_passive_iq_fun)
      when is_function(build_passive_iq_fun, 0) do
    Logger.warning("[SESSION] Prekey upload failed: #{inspect(node.attrs || %{})}")

    state =
      state
      |> Map.put(:prekey_upload_iq_id, nil)
      |> Map.put(:pending_prekey_upload, [])
      |> sync_post_auth_phase_after_prekey_step()

    Logger.warning(
      "[POST_AUTH] prekey upload returned error session_id=#{inspect(Map.get(state, :session_id))} attrs=#{inspect(node.attrs || %{}, limit: 50)}"
    )

    maybe_send_passive_iq(state, build_passive_iq_fun)
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
      "[POST_AUTH] passive response session_id=#{inspect(Map.get(state, :session_id))} iq_type=#{iq_type} digest_enabled=#{digest_enabled?(state)}"
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

      Logger.debug("[SESSION] Sending digest query (id=#{digest_iq_id})")
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
  @spec refill_from_notification(map(), non_neg_integer()) :: {map(), list()}
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
        Logger.warning("[PREKEYS] Notification refill failed: #{inspect(reason)}")
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
      "[POST_AUTH] digest response session_id=#{inspect(Map.get(state, :session_id))} iq_type=#{iq_type}"
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
          "[SESSION] Uploading prekeys (initial=#{initial}, count=#{length(prekeys)}, id=#{request_id})"
        )

        Logger.debug(
          "[POST_AUTH] upload prekeys session_id=#{inspect(Map.get(state, :session_id))} initial=#{initial} request_id=#{request_id} count=#{length(prekeys)}"
        )

        next_state =
          state
          |> Map.put(:post_auth_phase, :awaiting_prekey_upload)
          |> Map.put(:prekey_upload_iq_id, request_id)
          |> Map.put(:pending_prekey_upload, prekeys)

        {next_state, [{:send_node, prekey_node}]}

      {:error, reason} ->
        Logger.warning("[SESSION] Cannot upload prekeys: #{inspect(reason)}")
        maybe_send_passive_iq(state, build_passive_iq_fun)
    end
  end

  defp maybe_send_passive_iq(%{passive_iq_id: passive_iq_id} = state, _build_passive_iq_fun)
       when is_binary(passive_iq_id) do
    Logger.debug(
      "[POST_AUTH] passive iq already in flight session_id=#{inspect(Map.get(state, :session_id))} request_id=#{passive_iq_id}"
    )

    {Map.put(state, :post_auth_phase, :awaiting_passive_ack), []}
  end

  defp maybe_send_passive_iq(%{post_auth_phase: :complete} = state, _build_passive_iq_fun) do
    Logger.debug(
      "[POST_AUTH] passive iq already completed session_id=#{inspect(Map.get(state, :session_id))}"
    )

    {state, []}
  end

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
      "[POST_AUTH] sending passive iq session_id=#{inspect(Map.get(state, :session_id))} request_id=#{request_id}"
    )

    Logger.debug("[SESSION] Sending SetPassive(false) (id=#{request_id})")
    {next_state, [{:send_node, passive_iq}]}
  end

  defp sync_post_auth_phase_after_prekey_step(%{post_auth_phase: :complete} = state), do: state

  defp sync_post_auth_phase_after_prekey_step(%{passive_iq_id: passive_iq_id} = state)
       when is_binary(passive_iq_id) do
    Map.put(state, :post_auth_phase, :awaiting_passive_ack)
  end

  defp sync_post_auth_phase_after_prekey_step(state) do
    Map.put(state, :post_auth_phase, :idle)
  end

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
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
  end

  defp persist_uploaded_prekeys(store, prekeys) when is_list(prekeys) do
    data = Store.load!(store)
    signal = Map.get(data, :signal, %{})
    existing_prekeys = Map.get(signal, :prekeys, %{})

    merged_prekeys =
      Enum.reduce(prekeys, existing_prekeys, fn
        %{key_id: id, public: pub, private: priv}, acc ->
          Map.put(acc, id, %{id: id, public: pub, private: priv})

        _, acc ->
          acc
      end)

    next_prekey_id =
      prekeys
      |> Enum.map(&Map.get(&1, :key_id))
      |> Enum.filter(&is_integer/1)
      |> case do
        [] -> Map.get(signal, :next_prekey_id, 1)
        ids -> Enum.max(ids) + 1
      end

    updated_signal =
      signal
      |> Map.put(:prekeys, merged_prekeys)
      |> Map.put(:next_prekey_id, next_prekey_id)

    Store.persist(store, Map.put(data, :signal, updated_signal))
    :ok
  rescue
    error ->
      Logger.warning("[SESSION] Failed to persist uploaded prekeys: #{inspect(error)}")
      :ok
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
end
