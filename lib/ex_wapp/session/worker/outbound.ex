defmodule ExWapp.Session.Worker.Outbound do
  @moduledoc """
  Coordinates outbound sends from the session worker.

  The module selects direct or group delivery, prepares Signal sessions, delegates
  device discovery and encryption, sends protocol nodes, and records delivery
  metadata. Message construction remains separate from the WebSocket transport.
  """

  require Logger

  alias ExWapp.{Binary, Chat, Config, JID, Log, Messages, Store, Telemetry}
  alias WAWebProtobufsE2E.Message
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
  @doc "Sends text or an optional prebuilt protobuf payload through the session pipeline."
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

    # One send touches the store on the order of twenty times — device cache,
    # LID mapping, prekeys, per-target Signal sessions, the ADV identity, the
    # pending chat record. Unbatched, each of those is a full adapter load, so
    # an in-memory adapter pays nothing and a durable one pays a round trip and
    # a whole-blob decode per access. Holding one batch open for the send lets
    # the adapter answer them from a single load.
    with_send_batch(state, {:outbound_send, normalized_jid}, fn ->
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
    end)
  end

  # Deliberately not `Store.batch/3`: that helper replaces the wrapped result
  # with `{:error, _}` when the closing flush fails, which would report a
  # message already on the wire as unsent and invite a duplicate resend. Here
  # the send's own result always wins and a persistence problem is logged
  # instead of substituted. A batch that cannot be opened degrades to the
  # unbatched path rather than failing the send.
  defp with_send_batch(%{store: store}, reason, fun) when not is_nil(store) do
    case Store.begin_batch(store, reason) do
      :ok ->
        try do
          fun.()
        after
          case Store.finish_batch(store, reason) do
            :ok ->
              :ok

            {:error, flush_reason} ->
              Logger.warning(
                "[SEND] Batch flush failed after send reason=#{Log.reason(flush_reason)}"
              )
          end
        end

      {:error, batch_reason} ->
        Logger.debug("[SEND] Proceeding unbatched reason=#{Log.reason(batch_reason)}")
        fun.()
    end
  end

  defp with_send_batch(_state, _reason, fun), do: fun.()

  @doc "Sends a constructed WhatsApp protobuf message through the normal outbound pipeline."
  @spec send_proto_worker(pid(), map(), String.t(), %WAWebProtobufsE2E.Message{}, keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_proto_worker(session_pid, state, jid, %Message{} = proto, opts \\ []) do
    chat_text = Keyword.get(opts, :chat_text)
    send_text_worker(session_pid, state, jid, chat_text, Keyword.put(opts, :proto_message, proto))
  end

  @doc "Sends an internal protocol message directly to the account's primary device."
  @spec send_peer_proto_worker(pid(), map(), %WAWebProtobufsE2E.Message{}) ::
          {:ok, String.t()} | {:error, term()}
  def send_peer_proto_worker(_session_pid, %{status: status}, _proto)
      when status not in [:connected, :syncing] do
    {:error, {:not_connected, status}}
  end

  def send_peer_proto_worker(_session_pid, %{status: status, conn: conn}, _proto)
      when not is_pid(conn) do
    {:error, {:not_connected, status}}
  end

  def send_peer_proto_worker(
        session_pid,
        %{conn: conn, store: store} = state,
        %Message{} = proto
      ) do
    destination_jid = peer_destination_jid(store)

    with destination when destination != "" <- destination_jid,
         {:ok, signal_sessions, prekey_bundles, target_hints} <-
           ensure_signal_session_worker(state, destination, reuse_self_chat_sessions: true),
         {target_specs, _all_usync_devices} <-
           Direct.resolve_targets(
             store,
             signal_sessions,
             destination,
             prekey_bundles,
             target_hints,
             self_chat_mode: :recipient_primary
           ),
         {:ok, target_spec} <- select_primary_peer_target(target_specs),
         {:ok, payloads} <- Direct.build_payloads(proto, destination, []),
         {:ok, [participant_node], updated_sessions, include_identity} <-
           Encryptor.encrypt_for_targets(
             store,
             signal_sessions,
             [%{target_spec | payload_kind: :recipient}],
             %{recipient: payloads.recipient},
             prekey_bundles
           ),
         {:ok, encrypted_node} <- extract_peer_encrypted_node(participant_node),
         message_id <- Direct.message_id([], destination),
         node <-
           build_peer_message_node(
             destination,
             message_id,
             encrypted_node,
             store,
             include_identity
           ),
         :ok <- persist_signal_sessions(session_pid, updated_sessions, state),
         :ok <- send_transport_node(state, conn, node) do
      Logger.debug(
        "[PLACEHOLDER] Sent peer-data request to primary device id=#{Log.reference(message_id)}"
      )

      emit_telemetry(
        :message_sent,
        %{message_count: 1, payload_bytes: payloads.raw_size},
        state,
        %{jid: destination, message_id: message_id, encryption: :peer}
      )

      {:ok, message_id}
    else
      "" -> {:error, :missing_local_account_jid}
      {:error, reason} -> {:error, {:peer_send_failed, reason}}
      other -> {:error, {:peer_send_failed, other}}
    end
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
      "[SEND] Fanout incomplete for #{Log.reference(jid)}, clearing cached sessions and retrying once: missing_count=#{length(missing_targets)}"
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
    message_id = Direct.message_id(opts, own_jid)
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
         {:ok, iodata} <- Message.encode(proto),
         payload = IO.iodata_to_binary(iodata),
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
             prekey_bundles
           ) do
      missing_targets =
        Encryptor.missing_expected_targets(distribution_target_specs, participant_nodes)

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
        Logger.error(
          "[SEND] Group send failed for #{Log.reference(group_jid)}: #{Log.reason(reason)}"
        )

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
      "[SEND] Aborting group send to #{Log.reference(group_jid)}: missing_count=#{length(missing_targets)}"
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
          "[SEND] Sent group encrypted message to #{Log.reference(context.group_jid)} (distribution_targets=#{length(context.participant_nodes)})"
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
          "[SEND] Group transport send failed for #{Log.reference(context.group_jid)} id=#{Log.reference(context.message_id)}: #{Log.reason(error)}"
        )

        Chat.update_message_status(context.store, context.group_jid, context.message_id, :failed)
        error
    end
  end

  @spec retry_group_distribution(map(), [term()]) :: {:ok, String.t()} | {:error, term()}
  defp retry_group_distribution(context, missing_targets) do
    Logger.warning(
      "[SEND] Group distribution incomplete for #{Log.reference(context.group_jid)}, clearing cached sessions and retrying once: missing_count=#{length(missing_targets)}"
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
      "[SEND] Group sender-key distribution targets for #{Log.reference(group_jid)}: live_count=#{length(live_distribution_targets)} cached_count=#{length(cached_distribution_targets)}"
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
        Logger.debug(
          "[SEND] Group usync device map for #{Log.reference(group_jid)}: recipients=#{map_size(map)}"
        )

        map

      {:error, reason} ->
        Logger.warning(
          "[SEND] Group usync query failed for #{Log.reference(group_jid)}: #{Log.reason(reason)}"
        )

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

  @spec ensure_signal_session_worker(map(), String.t(), keyword()) ::
          {:ok, SessionStore.t(), map(), Direct.target_hints()} | {:error, term()}
  defp ensure_signal_session_worker(state, jid, opts \\ []) when is_list(opts) do
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
      end,
      opts
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
          Logger.debug("[SEND] USync device map: recipients=#{map_size(map)}")
          map

        {:error, reason} ->
          Logger.warning(
            "[SEND] USync query failed (#{Log.reason(reason)}), falling back to prekey-only"
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
      "[SEND] Discovered recipient devices: count=#{length(discovery.recipient_devices)}"
    )

    Logger.debug(
      "[SEND] Cached recipient devices: count=#{length(discovery.recipient_cached_devices)}"
    )

    Logger.debug(
      "[SEND] Discovered own devices (excl. self): count=#{length(discovery.own_devices)}"
    )

    Logger.debug(
      "[SEND] Cached own devices (excl. self): count=#{length(discovery.own_cached_devices)}"
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
             prekey_bundles
           ),
         :ok <- Direct.validate_participant_family(jid, participant_nodes) do
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
            "[SEND] Aborting DM send to #{Log.reference(jid)}: missing_count=#{length(missing)}"
          )

          {:error, {:fanout_incomplete, missing}}
      end
    else
      {:error, reason} ->
        Logger.error(
          "[SEND] Encrypted send failed for #{Log.reference(jid)}: #{Log.reason(reason)}"
        )

        {:error, {:send_failed, reason}}
    end
  end

  @doc false
  @spec outbound_proto(outbound_text(), keyword()) :: %Message{}
  def outbound_proto(text, opts) do
    case Keyword.get(opts, :proto_message) do
      %Message{} = proto -> proto
      _ -> Messages.build_text_proto(text, opts)
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
        Logger.debug(
          "[SEND] Sent encrypted message to #{Log.reference(jid)} id=#{Log.reference(message_id)}"
        )

        emit_telemetry(
          :message_sent,
          %{message_count: 1, payload_bytes: payloads.raw_size},
          state,
          %{jid: jid, message_id: message_id, encryption: :multi_device}
        )

        {:ok, message_id}

      error ->
        Logger.error(
          "[SEND] Transport send failed for #{Log.reference(jid)} id=#{Log.reference(message_id)}: #{Log.reason(error)}"
        )

        Chat.update_message_status(store, jid, message_id, :failed)
        error
    end
  end

  @spec peer_destination_jid(Store.t()) :: String.t()
  defp peer_destination_jid(store) do
    case Account.local_account_base_jid(store) do
      "" -> Account.local_account_lid_jid(store)
      jid -> jid
    end
  end

  @spec select_primary_peer_target([map()]) :: {:ok, map()} | {:error, :no_peer_target}
  defp select_primary_peer_target([]), do: {:error, :no_peer_target}

  defp select_primary_peer_target(target_specs) when is_list(target_specs) do
    target = Enum.min_by(target_specs, &peer_target_rank/1)
    {:ok, target}
  end

  @spec peer_target_rank(map()) :: {non_neg_integer(), non_neg_integer()}
  defp peer_target_rank(target_spec) do
    jid = Map.get(target_spec, :jid, "")
    device_id = JIDUtils.device_id(jid)

    {
      if(device_id in [nil, 0], do: 0, else: 1),
      if(Map.get(target_spec, :payload_kind) == :recipient, do: 0, else: 1)
    }
  end

  @spec extract_peer_encrypted_node(Binary.Node.t()) ::
          {:ok, Binary.Node.t()} | {:error, :missing_peer_encrypted_node}
  defp extract_peer_encrypted_node(%Binary.Node{tag: "to", content: content})
       when is_list(content) do
    case Enum.find(content, &match?(%Binary.Node{tag: "enc"}, &1)) do
      %Binary.Node{} = encrypted_node -> {:ok, encrypted_node}
      nil -> {:error, :missing_peer_encrypted_node}
    end
  end

  defp extract_peer_encrypted_node(_participant_node),
    do: {:error, :missing_peer_encrypted_node}

  @spec build_peer_message_node(
          String.t(),
          String.t(),
          Binary.Node.t(),
          Store.t(),
          boolean()
        ) :: Binary.Node.t()
  defp build_peer_message_node(
         destination_jid,
         message_id,
         encrypted_node,
         store,
         include_identity
       ) do
    meta_node = %Binary.Node{
      tag: "meta",
      attrs: %{"appdata" => "default"},
      content: nil
    }

    content = [meta_node, encrypted_node] ++ peer_identity_content(store, include_identity)

    %Binary.Node{
      tag: "message",
      attrs: %{
        "id" => message_id,
        "type" => "text",
        "category" => "peer",
        "to" => destination_jid
      },
      content: content
    }
  end

  @spec peer_identity_content(Store.t(), boolean()) :: [Binary.Node.t()]
  defp peer_identity_content(_store, false), do: []

  defp peer_identity_content(store, true) do
    case Account.get_device_identity_node(store) do
      {:ok, identity_node} -> [identity_node]
      {:error, _reason} -> []
    end
  end

  @spec normalize_jid_for_signal(String.t()) :: String.t()
  defp normalize_jid_for_signal(jid), do: JIDUtils.normalize_for_signal(jid)

  @spec normalize_jid_with_device(String.t()) :: String.t()
  defp normalize_jid_with_device(jid), do: JIDUtils.normalize_with_device(jid)

  @spec strip_device_from_jid(String.t()) :: String.t()
  defp strip_device_from_jid(jid), do: JIDUtils.strip_device(jid)

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
    case Map.get(state, :outbound_iq_router) do
      session_pid when is_pid(session_pid) ->
        fn node -> route_worker_iq(session_pid, state, node) end

      _other ->
        fn node -> send_transport_node(state, state.conn, node) end
    end
  end

  defp route_worker_iq(session_pid, state, node) do
    GenServer.call(session_pid, {:send_worker_iq, self(), node}, iq_timeout_ms(state))
  catch
    :exit, reason -> {:error, {:iq_router_exit, reason}}
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
      Logger.warning("[SEND] persist_signal_sessions failed: #{Log.reason(e)}")
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
