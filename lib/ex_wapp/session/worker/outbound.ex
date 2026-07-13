defmodule ExWapp.Session.Worker.Outbound do
  @moduledoc false

  require Logger

  alias ExWapp.{Binary, Chat, Config, JID, Messages, Store, Telemetry}
  alias ExWapp.Proto.Message
  alias ExWapp.Signal.SessionStore

  alias ExWapp.Session.{
    Account,
    DeviceCache,
    JIDUtils,
    MessageNode
  }

  alias ExWapp.Session.Outbound.{
    DeviceDiscovery,
    Direct,
    Encryptor,
    Fanout,
    Group,
    IQRequests,
    Prekeys
  }

  @typep worker_state :: map()
  @typep outbound_text :: iodata() | nil
  @doc false
  @spec send_text_worker(pid(), map(), String.t(), outbound_text(), keyword()) ::
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

  @doc false
  @spec send_proto_worker(pid(), map(), String.t(), ExWapp.Proto.Message.t(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_proto_worker(session_pid, state, jid, %Message{} = proto, opts \\ []) do
    chat_text = Keyword.get(opts, :chat_text)
    send_text_worker(session_pid, state, jid, chat_text, Keyword.put(opts, :proto_message, proto))
  end

  @spec send_direct_text_worker(pid(), map(), String.t(), outbound_text(), keyword()) ::
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
          outbound_text(),
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

  @spec retry_recipient_fanout(
          pid(),
          worker_state(),
          SessionStore.t(),
          String.t(),
          outbound_text(),
          keyword(),
          [Encryptor.target_spec()]
        ) ::
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
          Encryptor.clear_sessions_for_targets(updated_sessions, missing_targets, state.store)
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

  @spec do_send_group_worker(pid(), map(), String.t(), outbound_text(), keyword()) ::
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

    with {:ok, group_info} <- IQRequests.query_group_info(state, group_jid, send_node_fun(state)),
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
           Encryptor.encrypt_for_targets(
             store,
             updated_sessions,
             distribution_target_specs,
             %{recipient: distribution_payload},
             prekey_bundles || %{}
           ) do
      missing_targets = Encryptor.missing_expected_targets(distribution_target_specs, participant_nodes)

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
          Encryptor.clear_sessions_for_targets(
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
    case IQRequests.query_devices(state, query_jids, send_node_fun(state)) do
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
        IQRequests.fetch_prekeys_batch(
          state,
          target_jids,
          current_sessions,
          send_node_fun(state)
        )
      end,
      fn target_jid, current_sessions ->
        IQRequests.fetch_prekey(
          state,
          target_jid,
          current_sessions,
          send_node_fun(state)
        )
      end
    )
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
        IQRequests.fetch_prekeys_batch(
          state,
          target_jids,
          current_sessions,
          send_node_fun(state)
        )
      end,
      fn target_jid, current_sessions ->
        IQRequests.fetch_prekey(
          state,
          target_jid,
          current_sessions,
          send_node_fun(state)
        )
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
      case IQRequests.query_devices(state, query_jids, send_node_fun(state)) do
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
           Encryptor.encrypt_for_targets(
             store,
             signal_sessions,
             target_specs,
             payloads,
             prekey_bundles || %{}
           ) do
      case Encryptor.missing_expected_targets(target_specs, participant_nodes) do
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

  @spec outbound_proto(outbound_text(), keyword()) :: Message.t()
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

  @spec send_encrypted_node(
          worker_state(),
          pid(),
          Store.t(),
          String.t(),
          String.t(),
          Binary.Node.t(),
          Direct.payloads()
        ) :: {:ok, String.t()} | {:error, term()}
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

  @spec normalize_jid_for_signal(term()) :: String.t()
  defp normalize_jid_for_signal(jid) when is_binary(jid), do: JIDUtils.normalize_for_signal(jid)

  defp normalize_jid_for_signal(_), do: ""

  @spec normalize_jid_with_device(term()) :: String.t()
  defp normalize_jid_with_device(jid) when is_binary(jid), do: JIDUtils.normalize_with_device(jid)

  defp normalize_jid_with_device(%ExWapp.JID{} = jid), do: JIDUtils.normalize_with_device(jid)

  defp normalize_jid_with_device(_), do: ""

  @spec strip_device_from_jid(term()) :: String.t()
  defp strip_device_from_jid(jid) when is_binary(jid), do: JIDUtils.strip_device(jid)

  defp strip_device_from_jid(%ExWapp.JID{} = jid), do: JIDUtils.strip_device(jid)

  defp strip_device_from_jid(_), do: ""

  @spec maybe_record_outgoing_message(
          Store.t(),
          String.t(),
          String.t(),
          integer(),
          outbound_text(),
          keyword()
        ) :: :ok
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

  @spec send_node_fun(worker_state()) :: IQRequests.send_node_fun()
  defp send_node_fun(state) do
    fn node -> send_transport_node(state, state.conn, node) end
  end

  @spec send_transport_node(worker_state(), pid() | nil, Binary.Node.t()) ::
          :ok | {:error, term()}
  defp send_transport_node(%{transport_mod: transport_mod}, conn, node) when is_pid(conn) do
    transport_mod.send_node(conn, node)
  end

  defp send_transport_node(%{status: status}, _conn, _node) do
    {:error, {:not_connected, status}}
  end

  @spec persist_signal_sessions(pid(), SessionStore.t(), worker_state()) :: :ok
  defp persist_signal_sessions(session_pid, sessions, state) do
    GenServer.call(session_pid, {:update_signal_sessions, sessions}, iq_timeout_ms(state))
    :ok
  rescue
    e ->
      Logger.warning("[SEND] persist_signal_sessions failed: #{inspect(e)}")
      :ok
  end

  @spec iq_timeout_ms(worker_state()) :: non_neg_integer()
  defp iq_timeout_ms(state),
    do: Config.get(state.runtime_cfg || %{}, [:iq, :default_timeout_ms], 30_000)

  @spec emit_telemetry(atom(), map(), worker_state(), map()) :: :ok
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
