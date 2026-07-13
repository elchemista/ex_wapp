defmodule ExWapp.Session.Worker.Outbound do
  @moduledoc false

  require Logger

  alias ExWapp.{Binary, Chat, Config, JID, Messages, Store, Telemetry}
  alias ExWapp.Proto.Message
  alias ExWapp.Signal.{Encryption, SessionStore}

  alias ExWapp.Session.{
    Account,
    DeviceCache,
    IQ,
    JIDUtils,
    MessageNode
  }

  alias ExWapp.Session.Outbound.{DeviceDiscovery, Direct, Fanout, Group, Prekeys}

  @spec send_text_worker(pid(), map(), String.t(), iodata(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_text_worker(session_pid, state, jid, text, opts \\ [])

  def send_text_worker(_session_pid, %{status: status}, _jid, _text, _opts)
      when status != :connected do
    {:error, {:not_connected, status}}
  end

  def send_text_worker(_session_pid, %{status: status, conn: conn}, _jid, _text, _opts)
      when not is_pid(conn) do
    {:error, {:not_connected, status}}
  end

  def send_text_worker(session_pid, state, jid, text, opts) do
    normalized_jid = normalize_jid_with_device(jid)

    if JID.group?(normalized_jid) do
      do_send_group_worker(session_pid, state, normalized_jid, text, opts)
    else
      send_direct_text_worker(
        session_pid,
        state,
        normalize_jid_for_signal(normalized_jid),
        text,
        opts
      )
    end
  end

  @spec send_proto_worker(pid(), map(), String.t(), ExWapp.Proto.Message.t(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_proto_worker(session_pid, state, jid, %Message{} = proto, opts \\ []) do
    chat_text = Keyword.get(opts, :chat_text)
    send_text_worker(session_pid, state, jid, chat_text, Keyword.put(opts, :proto_message, proto))
  end

  @spec send_direct_text_worker(pid(), map(), String.t(), iodata(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  defp send_direct_text_worker(session_pid, state, jid, text, opts) do
    case ensure_signal_session_worker(state, jid) do
      {:ok, updated_sessions, prekey_bundles, target_hints} ->
        session_pid
        |> do_send_encrypted(
          state,
          updated_sessions,
          jid,
          text,
          prekey_bundles,
          target_hints,
          opts
        )
        |> maybe_retry_recipient_fanout(
          session_pid,
          state,
          updated_sessions,
          jid,
          text,
          opts
        )

      {:error, reason} ->
        {:error, {:session_failed, reason}}
    end
  end

  @spec maybe_retry_recipient_fanout(
          {:ok, String.t()} | {:error, term()},
          pid(),
          map(),
          term(),
          String.t(),
          iodata(),
          keyword()
        ) :: {:ok, String.t()} | {:error, term()}
  defp maybe_retry_recipient_fanout(
         {:error, {:fanout_incomplete, missing_targets}},
         session_pid,
         state,
         updated_sessions,
         jid,
         text,
         opts
       ) do
    if Keyword.get(opts, :recipient_fanout_retry, false) do
      {:error, {:fanout_incomplete, missing_targets}}
    else
      retry_recipient_fanout(
        session_pid,
        state,
        updated_sessions,
        jid,
        text,
        opts,
        missing_targets
      )
    end
  end

  defp maybe_retry_recipient_fanout(
         result,
         _session_pid,
         _state,
         _updated_sessions,
         _jid,
         _text,
         _opts
       ),
       do: result

  @spec retry_recipient_fanout(pid(), map(), term(), String.t(), iodata(), keyword(), [term()]) ::
          {:ok, String.t()} | {:error, term()}
  defp retry_recipient_fanout(
         session_pid,
         state,
         updated_sessions,
         jid,
         text,
         opts,
         missing_targets
       ) do
    Logger.warning(
      "[SEND] Fanout incomplete for #{jid}, clearing cached sessions and retrying once: #{inspect(missing_targets)}"
    )

    retry_state = %{
      state
      | signal_sessions:
          clear_cached_signal_sessions_for_targets(updated_sessions, missing_targets, state.store)
    }

    case ensure_signal_session_worker(retry_state, jid) do
      {:ok, retried_sessions, retried_prekey_bundles, retried_target_hints} ->
        do_send_encrypted(
          session_pid,
          retry_state,
          retried_sessions,
          jid,
          text,
          retried_prekey_bundles,
          retried_target_hints,
          Keyword.put(opts, :recipient_fanout_retry, true)
        )

      {:error, reason} ->
        {:error, {:session_failed, reason}}
    end
  end

  @spec do_send_group_worker(pid(), map(), String.t(), iodata(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  defp do_send_group_worker(
         session_pid,
         %{conn: conn, store: store} = state,
         group_jid,
         text,
         opts
       )
       when is_pid(conn) do
    group_jid = strip_device_from_jid(normalize_jid_with_device(group_jid))
    group_fanout_retry? = Keyword.get(opts, :group_fanout_retry, false)
    own_jid = Account.local_account_base_jid(store)
    message_id = Messages.generate_id(own_jid)
    timestamp = System.system_time(:second)

    with {:ok, group_info} <- query_group_info_worker(state, group_jid),
         {:ok, updated_sessions, prekey_bundles, distribution_targets} <-
           ensure_group_sender_key_sessions_worker(
             state,
             group_jid,
             group_info.participants,
             group_info.addressing_mode
           ),
         proto <- outbound_proto(text, opts),
         {:ok, payload} <- Message.encode(proto),
         {:ok, distribution_payload, skmsg_payload} <-
           Group.build_sender_key_payloads(store, group_jid, payload),
         distribution_target_specs <-
           Enum.map(distribution_targets, &%{jid: &1, payload_kind: :recipient}),
         {:ok, participant_nodes, persisted_sessions, include_identity} <-
           encrypt_for_targets(
             store,
             updated_sessions,
             distribution_target_specs,
             %{recipient: distribution_payload},
             prekey_bundles || %{}
           ) do
      missing_targets = missing_expected_targets(distribution_target_specs, participant_nodes)

      handle_group_distribution_result(
        missing_targets,
        %{
          session_pid: session_pid,
          state: state,
          conn: conn,
          store: store,
          group_jid: group_jid,
          message_id: message_id,
          participant_nodes: participant_nodes,
          skmsg_payload: skmsg_payload,
          addressing_mode: group_info.addressing_mode,
          include_identity: include_identity,
          payload: payload,
          text: text,
          timestamp: timestamp,
          opts: opts,
          persisted_sessions: persisted_sessions,
          retried?: group_fanout_retry?
        }
      )
    else
      {:error, reason} ->
        Logger.error("[SEND] Group send failed for #{group_jid}: #{inspect(reason)}")
        {:error, {:group_send_failed, reason}}
    end
  end

  defp do_send_group_worker(_session_pid, %{status: status}, _group_jid, _text, _opts),
    do: {:error, {:not_connected, status}}

  @spec handle_group_distribution_result([term()], map()) :: {:ok, String.t()} | {:error, term()}
  defp handle_group_distribution_result([], context), do: send_group_distribution(context)

  defp handle_group_distribution_result(missing_targets, %{retried?: false} = context),
    do: retry_group_distribution(context, missing_targets)

  defp handle_group_distribution_result(missing_targets, %{group_jid: group_jid}) do
    Logger.error(
      "[SEND] Aborting group send to #{group_jid}: missing encrypted targets #{inspect(missing_targets)}"
    )

    {:error, {:group_distribution_incomplete, missing_targets}}
  end

  @spec send_group_distribution(map()) :: {:ok, String.t()} | {:error, term()}
  defp send_group_distribution(context) do
    persist_signal_sessions(context.session_pid, context.persisted_sessions, context.state)

    pending_message = %{
      id: context.message_id,
      from_me: true,
      timestamp: context.timestamp,
      text: context.text,
      status: :pending,
      participant: nil,
      raw: Keyword.get(context.opts, :outgoing_raw)
    }

    Chat.add_message(context.store, context.group_jid, pending_message)

    node =
      Group.build_encrypted_message_node(
        context.group_jid,
        context.message_id,
        context.participant_nodes,
        context.skmsg_payload,
        context.addressing_mode,
        context.store,
        context.include_identity
      )
      |> MessageNode.apply_outbound_options(context.opts)

    case send_transport_node(context.state, context.conn, node) do
      :ok ->
        Logger.debug(
          "[SEND] Sent group encrypted message to #{context.group_jid} (distribution_targets=#{length(context.participant_nodes)})"
        )

        emit_telemetry(
          :message_sent,
          %{message_count: 1, payload_bytes: byte_size(context.payload)},
          context.state,
          %{jid: context.group_jid, message_id: context.message_id, encryption: :group_sender_key}
        )

        {:ok, context.message_id}

      error ->
        Logger.error(
          "[SEND] Group transport send failed for #{context.group_jid} id=#{context.message_id}: #{inspect(error)}"
        )

        Chat.update_message_status(context.store, context.group_jid, context.message_id, :failed)
        error
    end
  end

  @spec retry_group_distribution(map(), [term()]) :: {:ok, String.t()} | {:error, term()}
  defp retry_group_distribution(context, missing_targets) do
    Logger.warning(
      "[SEND] Group distribution incomplete for #{context.group_jid}, clearing cached sessions and retrying once: #{inspect(missing_targets)}"
    )

    retry_state = %{
      context.state
      | signal_sessions:
          clear_cached_signal_sessions_for_targets(
            context.persisted_sessions,
            missing_targets,
            context.state.store
          )
    }

    do_send_group_worker(
      context.session_pid,
      retry_state,
      context.group_jid,
      context.text,
      Keyword.put(context.opts, :group_fanout_retry, true)
    )
  end

  @spec ensure_group_sender_key_sessions_worker(map(), String.t(), [term()], term()) ::
          {:ok, SessionStore.t(), map(), [String.t()]} | {:error, term()}
  defp ensure_group_sender_key_sessions_worker(
         state,
         group_jid,
         participant_jids,
         addressing_mode
       ) do
    signal_sessions = state.signal_sessions || SessionStore.new()
    own_base_jid = Account.local_account_base_jid(state.store)
    own_lid_jid = Account.local_account_lid_jid(state.store)
    own_device_id = Account.local_account_device_id(state.store)

    query_jids =
      Group.query_jids(participant_jids, addressing_mode, own_base_jid, own_lid_jid)
    device_map = fetch_group_device_map(state, group_jid, query_jids)

    {live_distribution_targets, cached_distribution_targets} =
      Group.distribution_targets(
        query_jids,
        device_map,
        addressing_mode,
        own_device_id,
        own_base_jid,
        own_lid_jid,
        state.store,
        state.runtime_cfg
      )

    Logger.debug(
      "[SEND] Group sender-key distribution targets for #{group_jid}: live=#{inspect(live_distribution_targets)} cached=#{inspect(cached_distribution_targets)}"
    )

    lid_mapping = Account.load_lid_mapping(state.store)

    devices_needing_prekeys =
      Group.prekey_targets(
        JIDUtils.normalize_target_list(live_distribution_targets ++ cached_distribution_targets),
        state.runtime_cfg,
        signal_sessions,
        lid_mapping,
        own_base_jid,
        own_lid_jid,
        System.system_time(:millisecond)
      )

    {updated_sessions, prekey_bundles} =
      fetch_group_prekeys(state, devices_needing_prekeys, signal_sessions, "group")

    Group.finalize_sessions_result(
      updated_sessions,
      prekey_bundles,
      finalize_soft_targets(
        state.store,
        updated_sessions,
        prekey_bundles,
        live_distribution_targets,
        cached_distribution_targets
      )
    )
  end

  @spec fetch_group_device_map(map(), String.t(), [String.t()]) :: map()
  defp fetch_group_device_map(state, group_jid, query_jids) do
    case query_device_list_worker(state, query_jids) do
      {:ok, map} ->
        Logger.debug("[SEND] Group usync device map for #{group_jid}: #{inspect(map)}")
        map

      {:error, reason} ->
        Logger.warning("[SEND] Group usync query failed for #{group_jid}: #{inspect(reason)}")
        %{}
    end
  end

  @spec fetch_group_prekeys(map(), [String.t()], SessionStore.t(), term()) ::
          {Prekeys.fetch_state(), map()}
  defp fetch_group_prekeys(state, devices_needing_prekeys, signal_sessions, context) do
    Prekeys.fetch_group(
      devices_needing_prekeys,
      signal_sessions,
      context,
      fn target_jids, current_sessions ->
        fetch_prekeys_batch_worker(state, target_jids, current_sessions)
      end,
      fn target_jid, current_sessions ->
        fetch_prekeys_worker(state, target_jid, current_sessions)
      end
    )
  end

  @spec query_group_info_worker(map(), String.t()) ::
          {:ok, Group.group_info()} | {:error, term()}
  defp query_group_info_worker(%{conn: conn} = state, group_jid) do
    message_id = generate_request_id()
    query_node = Group.build_info_query(group_jid, message_id)

    Logger.debug("[GROUP] Querying group info for #{group_jid}")

    case send_transport_node(state, conn, query_node) do
      :ok ->
        receive do
          {:prekey_response, ^message_id, response_node} ->
            Group.parse_info_response(response_node, group_jid)

          {:prekey_error, ^message_id, error} ->
            {:error, {:group_info_query_error, error}}
        after
          group_info_timeout_ms(state) ->
            {:error, :group_info_timeout}
        end

      error ->
        {:error, {:group_info_send_failed, error}}
    end
  end

  @spec ensure_signal_session_worker(map(), String.t()) ::
          {:ok, SessionStore.t(), map(), Direct.target_hints()} | {:error, term()}
  defp ensure_signal_session_worker(state, jid) do
    Direct.prepare_sessions(
      state,
      jid,
      System.system_time(:millisecond),
      fn recipient_base_jid, own_sender_jid, own_device_id ->
        discover_devices(state, recipient_base_jid, own_sender_jid, own_device_id)
      end,
      fn target_jids, current_sessions ->
        fetch_prekeys_batch_worker(state, target_jids, current_sessions)
      end,
      fn target_jid, current_sessions ->
        fetch_prekeys_worker(state, target_jid, current_sessions)
      end
    )
  end

  @spec discover_devices(map(), String.t(), String.t(), non_neg_integer() | nil) ::
          Direct.discovery_result()
  defp discover_devices(state, recipient_base_jid, own_sender_jid, own_device_id) do
    lid_mapping = Account.load_lid_mapping(state.store)
    own_base_jid = Account.local_account_base_jid(state.store)
    own_lid_jid = Account.local_account_lid_jid(state.store)

    query_jids =
      DeviceDiscovery.query_jids(
        recipient_base_jid,
        own_sender_jid,
        own_base_jid,
        own_lid_jid,
        lid_mapping
      )

    device_map =
      case query_device_list_worker(state, query_jids) do
        {:ok, map} ->
          Logger.debug("[SEND] USync device map: #{inspect(map)}")
          map

        {:error, reason} ->
          Logger.warning(
            "[SEND] USync query failed (#{inspect(reason)}), falling back to prekey-only"
          )

          %{}
      end

    own_preferred_jid =
      DeviceDiscovery.own_preferred_jid(own_base_jid, own_sender_jid)

    recipient_cached_devices =
      DeviceCache.resolve_recent_devices(state.store, recipient_base_jid, state.runtime_cfg)

    own_cached_devices =
      DeviceCache.resolve_recent_devices(state.store, own_preferred_jid, state.runtime_cfg)

    discovery =
      DeviceDiscovery.resolve(%{
        device_map: device_map,
        recipient_base_jid: recipient_base_jid,
        recipient_cached_devices: recipient_cached_devices,
        own_sender_jid: own_sender_jid,
        own_base_jid: own_base_jid,
        own_lid_jid: own_lid_jid,
        own_cached_devices: own_cached_devices,
        own_device_id: own_device_id,
        lid_mapping: lid_mapping
      })

    Logger.debug(
      "[SEND] Discovered recipient devices: #{inspect(discovery.recipient_devices)}"
    )

    Logger.debug(
      "[SEND] Cached recipient devices: #{inspect(discovery.recipient_cached_devices)}"
    )

    Logger.debug("[SEND] Discovered own devices (excl. self): #{inspect(discovery.own_devices)}")

    Logger.debug(
      "[SEND] Cached own devices (excl. self): #{inspect(discovery.own_cached_devices)}"
    )

    {
      discovery.recipient_devices,
      discovery.recipient_cached_devices,
      discovery.own_devices,
      discovery.own_cached_devices,
      discovery.all_usync_devices,
      discovery.all_device_jids
    }
  end

  # Fetch prekeys for multiple device JIDs in a single IQ request
  defp fetch_prekeys_batch_worker(
         %{conn: conn, store: store} = state,
         device_jids,
         signal_sessions
       )
       when is_list(device_jids) and device_jids != [] do
    message_id = generate_request_id()
    request_node = IQ.build_prekey_request(device_jids, message_id)

    Logger.debug("[PREKEY] Sending batch prekey request for #{length(device_jids)} devices")

    case send_transport_node(state, conn, request_node) do
      :ok ->
        receive do
          {:prekey_response, ^message_id, response_node} ->
            Logger.debug("[PREKEY] Got batch prekey response")
            process_prekey_response(store, response_node, nil, signal_sessions)

          {:prekey_error, ^message_id, error} ->
            {:error, {:prekey_fetch_error, error}}
        after
          prekey_timeout_ms(state) ->
            {:error, :prekey_timeout}
        end

      error ->
        {:error, {:send_failed, error}}
    end
  end

  defp fetch_prekeys_worker(%{conn: conn, store: store} = state, jid, signal_sessions) do
    message_id = generate_request_id()
    request_node = IQ.build_prekey_request(jid, message_id)

    Logger.debug("[PREKEY] Sending prekey request for #{jid}")

    # Send the IQ - we'll receive the response directly since we're not a GenServer
    case send_transport_node(state, conn, request_node) do
      :ok ->
        # Wait for response - the session will forward it to us
        receive do
          {:prekey_response, ^message_id, response_node} ->
            Logger.debug("[PREKEY] Got prekey response")
            process_prekey_response(store, response_node, jid, signal_sessions)

          {:prekey_error, ^message_id, error} ->
            {:error, {:prekey_fetch_error, error}}
        after
          prekey_timeout_ms(state) ->
            {:error, :prekey_timeout}
        end

      error ->
        {:error, {:send_failed, error}}
    end
  end

  defp process_prekey_response(store, response_node, requested_jid, signal_sessions) do
    case IQ.parse_prekey_response(response_node) do
      {:ok, bundles} ->
        Logger.debug("[PREKEY] Parsed #{length(bundles)} prekey bundles, creating sessions")

        # Get local identity
        data = Store.load!(store)
        signal_data = Map.get(data, :signal, %{})
        local_identity = Map.get(signal_data, :identity_key)
        local_reg_id = Map.get(signal_data, :registration_id, 0)
        lid_mapping = Account.load_lid_mapping(store)

        if local_identity do
          Prekeys.create_sessions_for_bundles(
            signal_sessions,
            requested_jid,
            bundles,
            local_identity,
            local_reg_id,
            lid_mapping
          )
        else
          {:error, :no_local_identity}
        end

      {:error, reason} ->
        {:error, {:prekey_parse_failed, reason}}
    end
  end

  @spec do_send_encrypted(
          pid(),
          map(),
          SessionStore.t(),
          String.t(),
          iodata(),
          map(),
          Direct.target_hints(),
          keyword()
        ) :: {:ok, String.t()} | {:error, term()}
  defp do_send_encrypted(
         session_pid,
         %{conn: conn, store: store} = state,
         signal_sessions,
         jid,
         text,
         prekey_bundles,
         target_hints,
         opts
       ) do
    own_jid = Account.local_account_base_jid(store)
    message_id = Direct.message_id(opts, own_jid)
    timestamp = System.system_time(:second)

    with {target_specs, _all_usync_devices} <-
           Direct.resolve_targets(
             store,
             signal_sessions,
             jid,
             prekey_bundles,
             target_hints,
             opts
           ),
         proto <- outbound_proto(text, opts),
         {:ok, payloads} <- Direct.build_payloads(proto, jid, opts),
         {:ok, participant_nodes, updated_sessions, include_identity} <-
           encrypt_for_targets(
             store,
             signal_sessions,
             target_specs,
             payloads,
             prekey_bundles || %{}
           ) do
      case missing_expected_targets(target_specs, participant_nodes) do
        [] ->
          persist_signal_sessions(session_pid, updated_sessions, state)
          maybe_record_outgoing_message(store, jid, message_id, timestamp, text, opts)

          node =
            Direct.build_encrypted_message_node(
              jid,
              message_id,
              participant_nodes,
              store,
              include_identity
            )
            |> MessageNode.apply_outbound_options(opts)

          send_encrypted_node(state, conn, store, jid, message_id, node, payloads)

        missing ->
          Logger.warning(
            "[SEND] Aborting DM send to #{jid}: missing encrypted targets #{inspect(missing)}"
          )

          {:error, {:fanout_incomplete, missing}}
      end
    else
      {:error, reason} ->
        Logger.error("[SEND] Encrypted send failed for #{jid}: #{inspect(reason)}")
        {:error, {:send_failed, reason}}
    end
  end

  @spec outbound_proto(iodata(), keyword()) :: Message.t()
  defp outbound_proto(text, opts) do
    case Keyword.get(opts, :proto_message) do
      %Message{} = proto -> proto
      _ -> Messages.build_text_proto(text, [])
    end
  end

  @spec finalize_soft_targets(term(), term(), term(), term(), term()) :: [String.t()]
  defp finalize_soft_targets(
         store,
         signal_sessions,
         prekey_bundles,
         live_targets,
         cached_targets
       ) do
    {targets, unreachable_cached_targets} =
      Fanout.resolve_soft_targets(
        signal_sessions,
        prekey_bundles,
        live_targets,
        cached_targets,
        Account.load_lid_mapping(store)
      )

    if unreachable_cached_targets != [] do
      DeviceCache.evict_devices(store, unreachable_cached_targets)
    end

    targets
  end

  defp send_encrypted_node(state, conn, store, jid, message_id, node, payloads) do
    case send_transport_node(state, conn, node) do
      :ok ->
        Logger.debug("[SEND] Sent encrypted message to #{jid} id=#{message_id}")

        emit_telemetry(
          :message_sent,
          %{message_count: 1, payload_bytes: payloads.raw_size},
          state,
          %{jid: jid, message_id: message_id, encryption: :multi_device}
        )

        {:ok, message_id}

      error ->
        Logger.error(
          "[SEND] Transport send failed for #{jid} id=#{message_id}: #{inspect(error)}"
        )

        Chat.update_message_status(store, jid, message_id, :failed)
        error
    end
  end

  defp encrypt_for_targets(store, signal_sessions, target_specs, payloads, prekey_bundles) do
    lid_mapping = Account.load_lid_mapping(store)
    init_acc = %{nodes: [], sessions: signal_sessions, include_identity: false, errors: []}

    result =
      Enum.reduce(target_specs, init_acc, fn spec, acc ->
        encrypt_single_target(store, acc, spec, payloads, prekey_bundles, lid_mapping)
      end)

    if result.nodes == [] do
      {:error, {:no_encrypted_targets, Enum.reverse(result.errors)}}
    else
      {:ok, Enum.reverse(result.nodes), result.sessions, result.include_identity}
    end
  end

  defp encrypt_single_target(
         store,
         acc,
         %{jid: raw_jid, payload_kind: kind},
         payloads,
         bundles,
         lid_mapping
       ) do
    target_jid = normalize_jid_with_device(raw_jid)
    mapped_jid = JIDUtils.resolve_signal_encryption_jid(target_jid, lid_mapping)

    signal_jid =
      if mapped_jid == "" or mapped_jid == target_jid,
        do: target_jid,
        else: mapped_jid

    sessions =
      if signal_jid != target_jid,
        do: ensure_signal_session_alias(acc.sessions, signal_jid, target_jid),
        else: acc.sessions

    if signal_jid != target_jid do
      Logger.debug("[SEND] Encrypting wire_jid=#{target_jid} using signal_jid=#{signal_jid}")
    end

    padded_payload = Map.get(payloads, kind, Map.get(payloads, :recipient))
    bundle = Map.get(bundles, target_jid) || Map.get(bundles, signal_jid) || %{}
    bundle_for_encrypt = if is_binary(Map.get(bundle, :base_key)), do: bundle, else: %{}

    if is_binary(padded_payload) do
      do_encrypt_and_accumulate(
        store,
        acc,
        sessions,
        target_jid,
        signal_jid,
        padded_payload,
        bundle_for_encrypt
      )
    else
      Logger.warning("[SEND] Missing payload for target=#{target_jid} kind=#{kind}")
      %{acc | errors: [{target_jid, :missing_payload} | acc.errors]}
    end
  end

  defp do_encrypt_and_accumulate(store, acc, sessions, target_jid, signal_jid, payload, bundle) do
    case encrypt_for_target_with_fallback(
           store,
           sessions,
           target_jid,
           signal_jid,
           payload,
           bundle
         ) do
      {:ok, ciphertext, enc_type, updated_sessions} ->
        accumulate_encrypted_target(
          acc,
          target_jid,
          signal_jid,
          ciphertext,
          enc_type,
          updated_sessions
        )

      {:error, reason} ->
        Logger.warning("[SEND] Failed to encrypt for wire_jid=#{target_jid}: #{inspect(reason)}")
        %{acc | errors: [{target_jid, reason} | acc.errors]}
    end
  end

  defp encrypt_for_target_with_fallback(store, sessions, target_jid, signal_jid, payload, bundle) do
    case Encryption.encrypt_for_recipient_sync(store, sessions, signal_jid, payload, bundle) do
      {:error, :missing_bundle} when signal_jid != target_jid ->
        Logger.debug("[SEND] No session for signal_jid=#{signal_jid}, retrying with wire jid")
        Encryption.encrypt_for_recipient_sync(store, sessions, target_jid, payload, bundle)

      other ->
        other
    end
  end

  defp accumulate_encrypted_target(
         acc,
         target_jid,
         signal_jid,
         ciphertext,
         enc_type,
         updated_sessions
       ) do
    maybe_log_prekey_wire_fields(target_jid, enc_type, ciphertext)

    updated_sessions =
      if signal_jid != target_jid,
        do: ensure_signal_session_alias(updated_sessions, signal_jid, target_jid),
        else: updated_sessions

    node = MessageNode.build_participant_encrypted_node(target_jid, ciphertext, enc_type)

    %{
      acc
      | nodes: [node | acc.nodes],
        sessions: updated_sessions,
        include_identity: acc.include_identity or enc_type == :prekey
    }
  end

  defp maybe_log_prekey_wire_fields(_target_jid, enc_type, _ciphertext) when enc_type != :prekey,
    do: :ok

  defp maybe_log_prekey_wire_fields(target_jid, :prekey, ciphertext) do
    case ExWapp.Signal.WireFormat.parse_prekey_signal_message(ciphertext) do
      {:ok, parsed} ->
        Logger.debug(
          "[SEND] pkmsg wire fields target=#{target_jid} reg_id=#{parsed.registration_id} signed_prekey_id=#{parsed.signed_prekey_id} prekey_id=#{inspect(parsed.prekey_id)} base_key_size=#{byte_size(parsed.base_key)} inner_size=#{byte_size(parsed.message)}"
        )

      {:error, reason} ->
        Logger.warning(
          "[SEND] pkmsg wire parse failed for target=#{target_jid}: #{inspect(reason)}"
        )
    end
  end

  defp ensure_signal_session_alias(signal_sessions, alias_jid, source_jid) do
    alias_jid = normalize_jid_with_device(alias_jid)
    source_jid = normalize_jid_with_device(source_jid)

    cond do
      alias_jid == "" or source_jid == "" or alias_jid == source_jid ->
        signal_sessions

      SessionStore.has_session?(signal_sessions, alias_jid) ->
        signal_sessions

      true ->
        case SessionStore.get_session(signal_sessions, source_jid) do
          {:ok, session} ->
            Logger.debug("[SEND] Migrating session #{source_jid} -> #{alias_jid}")
            SessionStore.put_session(signal_sessions, alias_jid, session)

          :not_found ->
            signal_sessions
        end
    end
  end

  defp query_device_list_worker(%{conn: conn} = state, jids) when is_list(jids) do
    message_id = generate_request_id()
    query_node = IQ.build_usync_device_query(jids, message_id)

    Logger.debug("[USYNC] Querying device list for #{inspect(jids)}")

    case send_transport_node(state, conn, query_node) do
      :ok ->
        receive do
          {:prekey_response, ^message_id, response_node} ->
            Logger.debug("[USYNC] Got device list response")

            case IQ.parse_usync_device_response(response_node) do
              {:ok, device_map} = ok ->
                DeviceCache.persist_usync_map(state.store, device_map)
                ok

              other ->
                other
            end

          {:prekey_error, ^message_id, error} ->
            Logger.warning("[USYNC] Device list query error: #{inspect(error)}")
            {:error, {:usync_query_error, error}}
        after
          usync_timeout_ms(state) ->
            Logger.warning("[USYNC] Device list query timed out")
            {:error, :usync_timeout}
        end

      error ->
        {:error, {:usync_send_failed, error}}
    end
  end

  defp find_child(content, tag) when is_list(content) do
    Enum.find(content, fn
      %Binary.Node{tag: ^tag} -> true
      _ -> false
    end)
  end

  defp normalize_jid_for_signal(jid) when is_binary(jid), do: JIDUtils.normalize_for_signal(jid)

  defp normalize_jid_for_signal(_), do: ""

  defp normalize_jid_with_device(jid) when is_binary(jid), do: JIDUtils.normalize_with_device(jid)

  defp normalize_jid_with_device(%ExWapp.JID{} = jid), do: JIDUtils.normalize_with_device(jid)

  defp normalize_jid_with_device(_), do: ""

  defp strip_device_from_jid(jid) when is_binary(jid), do: JIDUtils.strip_device(jid)

  defp strip_device_from_jid(%ExWapp.JID{} = jid), do: JIDUtils.strip_device(jid)

  defp strip_device_from_jid(_), do: ""

  defp generate_request_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64() |> String.slice(0, 16)
  end

  defp maybe_record_outgoing_message(store, jid, message_id, timestamp, text, opts) do
    if Keyword.get(opts, :suppress_outgoing_chat_add, false) do
      Chat.update_message_status(store, jid, message_id, :pending)
    else
      Chat.add_message(store, jid, %{
        id: message_id,
        from_me: true,
        timestamp: timestamp,
        text: text,
        status: :pending,
        participant: nil,
        raw: Keyword.get(opts, :outgoing_raw)
      })
    end
  end

  defp send_transport_node(%{transport_mod: transport_mod}, conn, node) when is_pid(conn) do
    transport_mod.send_node(conn, node)
  end

  defp send_transport_node(%{status: status}, _conn, _node) do
    {:error, {:not_connected, status}}
  end

  defp persist_signal_sessions(session_pid, sessions, state) do
    GenServer.call(session_pid, {:update_signal_sessions, sessions}, iq_timeout_ms(state))
    :ok
  rescue
    e ->
      Logger.warning("[SEND] persist_signal_sessions failed: #{inspect(e)}")
      :ok
  end

  defp iq_timeout_ms(state),
    do: Config.get(state.runtime_cfg || %{}, [:iq, :default_timeout_ms], 30_000)

  defp prekey_timeout_ms(state),
    do: Config.get(state.runtime_cfg || %{}, [:iq, :prekey_timeout_ms], 30_000)

  defp usync_timeout_ms(state),
    do: Config.get(state.runtime_cfg || %{}, [:iq, :usync_timeout_ms], 15_000)

  defp group_info_timeout_ms(state),
    do: Config.get(state.runtime_cfg || %{}, [:iq, :group_info_timeout_ms], 15_000)

  defp clear_cached_signal_sessions_for_targets(signal_sessions, targets, store) do
    if SessionStore.store?(signal_sessions) do
      lid_mapping = Account.load_lid_mapping(store)

      targets
      |> Enum.map(fn
        %{jid: jid} -> jid
        jid when is_binary(jid) -> jid
        _ -> ""
      end)
      |> Enum.reject(&(&1 == ""))
      |> Enum.reduce(signal_sessions, &SessionStore.delete_sessions_for_user(&2, &1, lid_mapping))
    else
      signal_sessions
    end
  end

  defp missing_expected_targets(target_specs, participant_nodes) do
    encrypted_targets =
      participant_nodes
      |> MessageNode.extract_participant_jids()
      |> MapSet.new()

    target_specs
    |> Enum.map(fn spec ->
      %{
        jid: normalize_jid_with_device(Map.get(spec, :jid, "")),
        payload_kind: Map.get(spec, :payload_kind)
      }
    end)
    |> Enum.reject(fn %{jid: jid} -> jid == "" or MapSet.member?(encrypted_targets, jid) end)
  end

  defp emit_telemetry(event, measurements, state, extra_metadata) do
    metadata =
      Map.merge(
        %{
          session_id: state.session_id,
          status: state.status
        },
        extra_metadata
      )

    Telemetry.execute(event, measurements, metadata)
  end
end
