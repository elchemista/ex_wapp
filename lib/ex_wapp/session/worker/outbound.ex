defmodule ExWapp.Session.Worker.Outbound do
  @moduledoc false

  require Logger

  alias ExWapp.{Binary, Chat, Config, JID, Messages, Store, Telemetry}
  alias ExWapp.Proto.Message
  alias ExWapp.Signal.{Encryption, SenderKey, SessionStore}

  alias ExWapp.Session.{
    Account,
    DeviceCache,
    IQ,
    JIDUtils,
    MessageNode,
    Targets
  }

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
      direct_jid = preferred_direct_jid(state.store, normalized_jid)

      send_direct_text_worker(
        session_pid,
        state,
        normalize_jid_for_signal(direct_jid),
        text,
        opts
      )
    end
  end

  @spec preferred_direct_jid(term(), String.t()) :: String.t()
  defp preferred_direct_jid(store, jid) do
    mapped_jid =
      jid
      |> JIDUtils.resolve_signal_encryption_jid(Account.load_lid_mapping(store))
      |> normalize_jid_with_device()

    if mapped_jid != "" and mapped_jid != jid do
      Logger.debug("[SEND] Using mapped LID destination original=#{jid} destination=#{mapped_jid}")
      mapped_jid
    else
      jid
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

    with {:ok, group_info} <- query_group_info_worker(session_pid, state, group_jid),
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
           build_group_sender_key_payloads(store, group_jid, payload),
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
      build_group_encrypted_message_node(
        context.group_jid,
        context.message_id,
        context.participant_nodes,
        context.skmsg_payload,
        context.addressing_mode,
        context.store,
        context.include_identity
      )
      |> apply_message_node_attrs(context.opts)

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

  defp build_group_sender_key_payloads(store, group_jid, message_payload) do
    padded_group_payload = Encryption.pad_message(message_payload)
    sender_identity = Account.local_account_sender_key_jid(store)

    if sender_identity == "" do
      {:error, :missing_sender_identity}
    else
      do_build_group_sender_key_payloads(
        store,
        group_jid,
        sender_identity,
        padded_group_payload
      )
    end
  end

  defp do_build_group_sender_key_payloads(store, group_jid, sender_identity, padded_payload) do
    with {:ok, distribution_payload} <-
           SenderKey.create_outbound_distribution_message(
             store,
             group_jid,
             sender_identity
           ),
         {:ok, skmsg_payload} <-
           SenderKey.encrypt_outbound_group_message(
             store,
             group_jid,
             sender_identity,
             padded_payload
           ) do
      {:ok, Encryption.pad_message(distribution_payload), skmsg_payload}
    end
  end

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

    own_jids_for_query = own_jids_for_group_query(addressing_mode, own_base_jid, own_lid_jid)
    query_jids = build_group_query_jids(participant_jids, own_jids_for_query)
    device_map = fetch_group_device_map(state, group_jid, query_jids)

    {live_distribution_targets, cached_distribution_targets} =
      build_group_distribution_targets(
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

    own_identity_set = group_own_identity_set(own_base_jid, own_lid_jid)
    lid_mapping = Account.load_lid_mapping(state.store)

    devices_needing_prekeys =
      find_group_devices_needing_prekeys(
        JIDUtils.normalize_target_list(live_distribution_targets ++ cached_distribution_targets),
        state.runtime_cfg,
        signal_sessions,
        lid_mapping,
        own_identity_set
      )

    {updated_sessions, prekey_bundles} =
      fetch_group_prekeys(state, devices_needing_prekeys, signal_sessions, "group")

    finalize_group_sessions_result(
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

  # Only add the own JID variant that matches the group's addressing_mode.
  # Mixing PN and LID in a LID-addressed message causes the server to drop it.
  defp own_jids_for_group_query("lid", _own_base_jid, own_lid_jid), do: [own_lid_jid]
  defp own_jids_for_group_query(_mode, own_base_jid, _own_lid_jid), do: [own_base_jid]

  defp build_group_query_jids(participant_jids, own_jids_for_query) do
    (participant_jids ++ own_jids_for_query)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&strip_device_from_jid/1)
    |> Enum.uniq()
  end

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

  defp build_group_distribution_targets(
         query_jids,
         device_map,
         addressing_mode,
         own_device_id,
         own_base_jid,
         own_lid_jid,
         store,
         runtime_cfg
       ) do
    {live_targets, cached_targets} =
      expand_group_distribution_targets(query_jids, device_map, store, runtime_cfg)

    live_targets =
      live_targets
      |> JIDUtils.normalize_target_list()
      |> filter_group_targets_for_addressing_mode(addressing_mode)
      |> Enum.reject(
        &group_current_device_target?(&1, own_device_id, [own_base_jid, own_lid_jid])
      )
      |> Enum.uniq()

    cached_targets =
      cached_targets
      |> JIDUtils.normalize_target_list()
      |> filter_group_targets_for_addressing_mode(addressing_mode)
      |> Enum.reject(
        &(group_current_device_target?(&1, own_device_id, [own_base_jid, own_lid_jid]) or
            &1 in live_targets)
      )
      |> Enum.uniq()

    {live_targets, cached_targets}
  end

  defp expand_group_distribution_targets(query_jids, device_map, store, runtime_cfg)
       when is_list(query_jids) do
    lid_mapping = Account.load_lid_mapping(store)

    Enum.reduce(query_jids, {[], []}, fn participant, {live_acc, cached_acc} ->
      base_participant = strip_device_from_jid(participant)

      live_targets =
        [
          base_participant
          | resolve_usync_devices_for_identity(device_map, base_participant, lid_mapping)
        ]
        |> JIDUtils.normalize_target_list()

      cached_targets =
        DeviceCache.resolve_recent_devices(store, base_participant, runtime_cfg)
        |> Enum.reject(&(&1 in live_targets))

      {live_acc ++ live_targets, cached_acc ++ cached_targets}
    end)
  end

  defp finalize_group_sessions_result({:error, reason}, _prekey_bundles, _distribution_targets),
    do: {:error, reason}

  defp finalize_group_sessions_result(sessions, prekey_bundles, distribution_targets) do
    {:ok, sessions, prekey_bundles, distribution_targets}
  end

  defp group_current_device_target?(target_jid, own_device_id, own_identities) do
    target_identity = JIDUtils.identity(target_jid)

    own_identity_set =
      own_identities
      |> Enum.map(&JIDUtils.identity/1)
      |> Enum.reject(fn {user, server} -> user == "" or server == "" end)
      |> MapSet.new()

    MapSet.member?(own_identity_set, target_identity) and
      current_device_target?(target_jid, own_device_id)
  end

  defp filter_group_targets_for_addressing_mode(targets, "lid") when is_list(targets) do
    {lid_targets, mismatched_targets} =
      Enum.split_with(targets, fn target_jid ->
        target_jid
        |> strip_device_from_jid()
        |> JIDUtils.lid_jid?()
      end)

    if mismatched_targets != [] do
      Logger.warning(
        "[SEND] Dropping non-LID targets in lid addressing mode: #{inspect(mismatched_targets)}"
      )
    end

    lid_targets
  end

  defp filter_group_targets_for_addressing_mode(targets, _), do: targets

  defp group_own_identity_set(own_base_jid, own_lid_jid) do
    [own_base_jid, own_lid_jid]
    |> Enum.map(&JIDUtils.identity/1)
    |> Enum.reject(fn {user, server} -> user == "" or server == "" end)
    |> MapSet.new()
  end

  defp find_group_devices_needing_prekeys(
         distribution_targets,
         runtime_cfg,
         signal_sessions,
         lid_mapping,
         own_identity_set
       ) do
    Enum.filter(distribution_targets, fn device_jid ->
      group_target_needs_prekey?(
        device_jid,
        runtime_cfg,
        signal_sessions,
        lid_mapping,
        own_identity_set
      )
    end)
  end

  defp group_target_needs_prekey?(
         device_jid,
         runtime_cfg,
         signal_sessions,
         lid_mapping,
         own_identity_set
       ) do
    device_jid = normalize_jid_with_device(device_jid)
    signal_jid = JIDUtils.resolve_signal_encryption_jid(device_jid, lid_mapping)
    target_identity = JIDUtils.identity(device_jid)
    now_ms = System.system_time(:millisecond)

    session_max_age_ms =
      Config.get(
        runtime_cfg || %{},
        [:signal, :session_max_age_ms],
        :timer.hours(12)
      )

    # Pragmatic sync fix: always refresh our own targets so distribution fanout
    # to phone/other linked devices starts with a clean pkmsg bootstrap.
    MapSet.member?(own_identity_set, target_identity) or
      not (SessionStore.has_session?(signal_sessions, signal_jid) or
             SessionStore.has_session?(signal_sessions, device_jid)) or
      SessionStore.stale_or_missing?(
        signal_sessions,
        [signal_jid, device_jid],
        session_max_age_ms,
        now_ms
      )
  end

  defp fetch_group_prekeys(_state, [], signal_sessions, _context), do: {signal_sessions, %{}}

  defp fetch_group_prekeys(state, devices_needing_prekeys, signal_sessions, context) do
    Logger.debug(
      "[SEND] Fetching group prekeys for #{length(devices_needing_prekeys)} devices: #{inspect(devices_needing_prekeys)}"
    )

    {updated_sessions, prekey_bundles} =
      case fetch_prekeys_batch_worker(state, devices_needing_prekeys, signal_sessions) do
        {:ok, sessions, bundles} ->
          {sessions, bundles}

        {:error, reason} ->
          Logger.warning(
            "[SEND] Group batch prekey fetch failed: #{inspect(reason)}, retrying individually"
          )

          case fetch_prekeys_individually_worker(state, devices_needing_prekeys, signal_sessions) do
            {:ok, sessions, bundles} -> {sessions, bundles}
            {:error, fallback_reason} -> {{:error, fallback_reason}, %{}}
          end
      end

    retry_missing_prekeys_worker(
      state,
      devices_needing_prekeys,
      updated_sessions,
      prekey_bundles,
      context
    )
  end

  defp build_group_encrypted_message_node(
         group_jid,
         message_id,
         participant_nodes,
         skmsg_payload,
         addressing_mode,
         store,
         include_identity
       ) do
    attrs = %{
      "id" => message_id,
      "to" => strip_device_from_jid(group_jid),
      "type" => "text"
    }

    attrs =
      MessageNode.maybe_put_message_attr(
        attrs,
        "addressing_mode",
        normalize_addressing_mode(addressing_mode)
      )

    participant_jids = MessageNode.extract_participant_jids(participant_nodes)

    attrs =
      MessageNode.maybe_put_message_attr(
        attrs,
        "phash",
        MessageNode.generate_participant_hash_v2(participant_jids)
      )

    participants_content =
      if participant_nodes == [] do
        []
      else
        [
          %Binary.Node{
            tag: "participants",
            attrs: %{},
            content: participant_nodes
          }
        ]
      end

    skmsg_node = %Binary.Node{
      tag: "enc",
      attrs: %{"v" => "2", "type" => "skmsg"},
      content: Binary.raw(skmsg_payload)
    }

    content =
      if include_identity do
        case Account.get_device_identity_node(store) do
          {:ok, identity_node} ->
            participants_content ++ [identity_node, skmsg_node]

          _ ->
            participants_content ++ [skmsg_node]
        end
      else
        participants_content ++ [skmsg_node]
      end

    %Binary.Node{
      tag: "message",
      attrs: attrs,
      content: content
    }
  end

  defp normalize_addressing_mode(mode) when mode in ["lid", "pn"], do: mode
  defp normalize_addressing_mode(_), do: nil

  defp query_group_info_worker(session_pid, state, group_jid) do
    message_id = generate_request_id()
    query_node = build_group_info_query(group_jid, message_id)
    timeout_ms = group_info_timeout_ms(state)

    Logger.debug(
      "[GROUP] Querying group info jid=#{group_jid} request_id=#{message_id} timeout_ms=#{timeout_ms}"
    )

    try do
      case GenServer.call(
             session_pid,
             {:send_iq, query_node, message_id, timeout_ms},
             timeout_ms + 1_000
           ) do
        {:ok, response_node} ->
          Logger.debug(
            "[GROUP] Received group info response jid=#{group_jid} request_id=#{message_id} attrs=#{inspect(response_node.attrs || %{})}"
          )

          parse_group_info_response(response_node, group_jid)

        {:error, :timeout} ->
          Logger.error(
            "[GROUP] Group info query timed out jid=#{group_jid} request_id=#{message_id} timeout_ms=#{timeout_ms}"
          )

          {:error, :group_info_timeout}

        {:error, error} ->
          Logger.warning(
            "[GROUP] Group info query error jid=#{group_jid} request_id=#{message_id} error=#{inspect(error)}"
          )

          {:error, {:group_info_query_error, error}}

        error ->
          {:error, {:group_info_send_failed, error}}
      end
    catch
      :exit, {:timeout, _call} ->
        Logger.error(
          "[GROUP] Group info call exited on timeout jid=#{group_jid} request_id=#{message_id} timeout_ms=#{timeout_ms}"
        )

        {:error, :group_info_timeout}
    end
  end

  defp build_group_info_query(group_jid, message_id) do
    %Binary.Node{
      tag: "iq",
      attrs: %{
        "id" => message_id,
        "xmlns" => "w:g2",
        "type" => "get",
        "to" => strip_device_from_jid(group_jid)
      },
      content: [
        %Binary.Node{
          tag: "query",
          attrs: %{"request" => "interactive"},
          content: nil
        }
      ]
    }
  end

  defp parse_group_info_response(
         %Binary.Node{tag: "iq", attrs: %{"type" => "result"}, content: content},
         group_jid
       )
       when is_list(content) do
    group_node = find_child(content, "group")

    if is_nil(group_node) do
      {:error, :missing_group_node}
    else
      addressing_mode = Map.get(group_node.attrs || %{}, "addressing_mode")

      participants =
        (group_node.content || [])
        |> Enum.filter(&match?(%Binary.Node{tag: "participant"}, &1))
        |> Enum.map(&extract_group_participant_identity(&1, addressing_mode))
        |> Enum.reject(&(&1 == ""))
        |> JIDUtils.normalize_target_list()
        |> Enum.map(&strip_device_from_jid/1)
        |> Enum.reject(&(&1 == group_jid))
        |> Enum.uniq()

      if participants == [] do
        {:error, :empty_group_participants}
      else
        {:ok, %{participants: participants, addressing_mode: addressing_mode}}
      end
    end
  end

  defp parse_group_info_response(%Binary.Node{attrs: %{"type" => "error"}} = node, _group_jid),
    do: {:error, {:group_info_error, node}}

  defp parse_group_info_response(_response, _group_jid),
    do: {:error, :invalid_group_info_response}

  defp extract_group_participant_identity(%Binary.Node{attrs: attrs}, addressing_mode)
       when is_map(attrs) do
    lid = normalize_jid_with_device(attrs["lid"])
    pn = normalize_jid_with_device(attrs["jid"] || attrs["pn"] || attrs["phone_number"])

    case addressing_mode do
      "lid" -> if lid != "", do: lid, else: pn
      _ -> if pn != "", do: pn, else: lid
    end
  end

  defp extract_group_participant_identity(_, _), do: ""

  defp ensure_signal_session_worker(state, jid) do
    signal_sessions = state.signal_sessions || SessionStore.new()
    own_sender_jid = Account.local_account_sender_identity_for_destination(state.store, jid)
    own_device_id = Account.local_account_device_id(state.store)
    recipient_base_jid = strip_device_from_jid(normalize_jid_with_device(jid))

    {recipient_devices, recipient_cached_devices, own_devices, own_cached_devices,
     all_usync_devices, all_device_jids} =
      discover_devices(state, recipient_base_jid, own_sender_jid, own_device_id)

    # For self-chat, force fresh prekey-based sessions for all targets.
    # Existing sessions may have stale ratchet state from inbound sync or
    # previously failed sends.  A fresh outbound pkmsg is the most reliable
    # way to establish a working session pair (same approach as group send).
    self_chat? = self_chat_destination?(state.store, jid, own_sender_jid)

    signal_sessions =
      if self_chat? do
        clear_self_chat_sessions(state.store, signal_sessions, all_device_jids)
      else
        signal_sessions
      end

    own_target_candidates =
      Targets.resolve_own_device_targets(
        signal_sessions,
        own_sender_jid,
        own_device_id,
        own_devices
      )

    all_target_device_jids =
      JIDUtils.normalize_target_list(
        recipient_devices ++
          recipient_cached_devices ++ own_target_candidates ++ own_cached_devices
      )
      |> Enum.reject(&current_device_target?(&1, own_device_id))

    all_participant_devices =
      JIDUtils.normalize_target_list(
        all_usync_devices ++ recipient_cached_devices ++ own_target_candidates
      )

    devices_needing_prekeys =
      find_devices_needing_prekeys(
        state.runtime_cfg,
        state.store,
        signal_sessions,
        all_target_device_jids,
        own_target_candidates ++ own_cached_devices
      )

    devices_needing_prekeys =
      if self_chat? do
        devices_needing_prekeys
      else
        expand_recipient_identity_prekey_targets(devices_needing_prekeys, recipient_devices)
      end

    {updated_sessions, prekey_bundles} =
      fetch_needed_prekeys(state, devices_needing_prekeys, signal_sessions, recipient_base_jid)

    {updated_sessions, prekey_bundles} =
      retry_missing_prekeys_worker(
        state,
        devices_needing_prekeys,
        updated_sessions,
        prekey_bundles,
        "dm"
      )

    case updated_sessions do
      {:error, reason} ->
        {:error, reason}

      sessions ->
        {:ok, sessions, prekey_bundles,
         %{
           recipient_devices: recipient_devices,
           recipient_cached_devices: recipient_cached_devices,
           own_devices: own_target_candidates,
           own_cached_devices: own_cached_devices,
           own_identity_jid: own_sender_jid,
           all_usync_devices: all_participant_devices
         }}
    end
  end

  defp clear_self_chat_sessions(store, signal_sessions, all_device_jids) do
    lid_mapping = Account.load_lid_mapping(store)

    Logger.debug(
      "[SEND] Self-chat: clearing #{length(all_device_jids)} existing sessions to force fresh pkmsg"
    )

    Enum.reduce(all_device_jids, signal_sessions, fn device_jid, sessions ->
      signal_jid = JIDUtils.resolve_signal_encryption_jid(device_jid, lid_mapping)
      sessions = SessionStore.delete_session(sessions, device_jid)

      if signal_jid != "" and signal_jid != device_jid do
        SessionStore.delete_session(sessions, signal_jid)
      else
        sessions
      end
    end)
  end

  defp discover_devices(state, recipient_base_jid, own_sender_jid, own_device_id) do
    lid_mapping = Account.load_lid_mapping(state.store)

    # WhatsApp expects a single addressing family per direct-message fanout.
    # `recipient_base_jid` and `own_sender_jid` are both LID when a PN-to-LID
    # mapping is known, and both PN otherwise.
    query_jids = JIDUtils.normalize_target_list([recipient_base_jid, own_sender_jid])

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

    recipient_devices =
      [
        recipient_base_jid
        | resolve_usync_devices_for_identity(device_map, recipient_base_jid, lid_mapping)
      ]
      |> JIDUtils.normalize_target_list()

    recipient_cached_devices =
      DeviceCache.resolve_recent_devices(state.store, recipient_base_jid, state.runtime_cfg)
      |> Enum.reject(&(&1 in recipient_devices))

    own_devices_all =
      resolve_usync_devices_for_identity(device_map, own_sender_jid, lid_mapping)
      |> JIDUtils.normalize_target_list()

    own_cached_devices =
      DeviceCache.resolve_recent_devices(state.store, own_sender_jid, state.runtime_cfg)
      |> Enum.reject(&(&1 in own_devices_all))

    own_devices = Enum.reject(own_devices_all, &current_device_target?(&1, own_device_id))

    own_cached_devices =
      Enum.reject(own_cached_devices, &current_device_target?(&1, own_device_id))

    # All usync devices INCLUDING current device — needed for phash (whatsmeow parity)
    all_usync_devices = JIDUtils.normalize_target_list(recipient_devices ++ own_devices_all)

    # Exclude current device from send targets.  For self-chat the recipient IS us,
    # so device 40 appears in recipient_devices — must be filtered here.
    all_device_jids =
      JIDUtils.normalize_target_list(
        recipient_devices ++ recipient_cached_devices ++ own_devices ++ own_cached_devices
      )
      |> Enum.reject(&current_device_target?(&1, own_device_id))

    Logger.debug("[SEND] Discovered recipient devices: #{inspect(recipient_devices)}")
    Logger.debug("[SEND] Cached recipient devices: #{inspect(recipient_cached_devices)}")
    Logger.debug("[SEND] Discovered own devices (excl. self): #{inspect(own_devices)}")
    Logger.debug("[SEND] Cached own devices (excl. self): #{inspect(own_cached_devices)}")

    {recipient_devices, recipient_cached_devices, own_devices, own_cached_devices,
     all_usync_devices, all_device_jids}
  end

  defp related_query_bases(base_jid, lid_mapping) do
    JIDUtils.related_bases(base_jid, lid_mapping)
  end

  defp resolve_usync_devices_for_identity(device_map, base_jid, lid_mapping) do
    aliases = related_query_bases(base_jid, lid_mapping)
    prefer_lid? = JIDUtils.lid_jid?(base_jid)

    preferred_devices =
      aliases
      |> Enum.filter(&(JIDUtils.lid_jid?(&1) == prefer_lid?))
      |> Enum.flat_map(&Map.get(device_map, &1, []))

    fallback_devices =
      aliases
      |> Enum.reject(&(JIDUtils.lid_jid?(&1) == prefer_lid?))
      |> Enum.flat_map(&Map.get(device_map, &1, []))

    (preferred_devices ++ fallback_devices)
    |> Enum.map(&JIDUtils.map_to_preferred_family(&1, base_jid, lid_mapping))
    |> JIDUtils.normalize_target_list()
  end

  # Match whatsmeow: check existing sessions by BOTH wire JID and LID-mapped JID,
  # but fetch prekeys using the ORIGINAL wire JIDs (PN), not the LID-mapped ones.
  defp find_devices_needing_prekeys(
         runtime_cfg,
         store,
         signal_sessions,
         all_device_jids,
         own_device_jids
       ) do
    lid_mapping = Account.load_lid_mapping(store)
    now_ms = System.system_time(:millisecond)

    own_identity_set =
      own_device_jids
      |> Enum.map(&JIDUtils.identity/1)
      |> Enum.reject(fn {user, server} -> user == "" or server == "" end)
      |> MapSet.new()

    session_max_age_ms =
      Config.get(
        runtime_cfg || %{},
        [:signal, :session_max_age_ms],
        :timer.hours(12)
      )

    Enum.filter(all_device_jids, fn device_jid ->
      device_jid = normalize_jid_with_device(device_jid)
      signal_jid = JIDUtils.resolve_signal_encryption_jid(device_jid, lid_mapping)
      target_identity = JIDUtils.identity(device_jid)

      has_session =
        SessionStore.has_session?(signal_sessions, signal_jid) or
          SessionStore.has_session?(signal_sessions, device_jid)

      MapSet.member?(own_identity_set, target_identity) or
        not has_session or
        SessionStore.stale_or_missing?(
          signal_sessions,
          [signal_jid, device_jid],
          session_max_age_ms,
          now_ms
        )
    end)
    |> JIDUtils.normalize_target_list()
  end

  defp fetch_needed_prekeys(_state, [], signal_sessions, _recipient_base_jid) do
    {signal_sessions, %{}}
  end

  defp fetch_needed_prekeys(state, devices_needing_prekeys, signal_sessions, recipient_base_jid) do
    Logger.debug(
      "[SEND] Fetching prekeys for #{length(devices_needing_prekeys)} devices: #{inspect(devices_needing_prekeys)}"
    )

    case fetch_prekeys_batch_worker(state, devices_needing_prekeys, signal_sessions) do
      {:ok, sessions, bundles} ->
        {sessions, bundles}

      {:error, reason} ->
        Logger.warning("[SEND] Batch prekey fetch failed: #{inspect(reason)}, trying individual")

        case fetch_prekeys_worker(state, recipient_base_jid, signal_sessions) do
          {:ok, sessions, bundles} -> {sessions, bundles}
          {:error, reason2} -> {{:error, reason2}, %{}}
        end
    end
  end

  defp expand_recipient_identity_prekey_targets(devices_needing_prekeys, recipient_devices) do
    devices_needing_prekeys = JIDUtils.normalize_target_list(devices_needing_prekeys)
    recipient_devices = JIDUtils.normalize_target_list(recipient_devices)

    recipient_identities =
      recipient_devices
      |> Enum.map(&JIDUtils.identity/1)
      |> Enum.reject(fn {user, server} -> user == "" or server == "" end)
      |> MapSet.new()

    if recipient_devices != [] and
         Enum.any?(devices_needing_prekeys, fn device_jid ->
           MapSet.member?(recipient_identities, JIDUtils.identity(device_jid))
         end) do
      JIDUtils.normalize_target_list(recipient_devices ++ devices_needing_prekeys)
    else
      devices_needing_prekeys
    end
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

  defp fetch_prekeys_individually_worker(state, device_jids, signal_sessions)
       when is_list(device_jids) do
    Enum.reduce_while(device_jids, {:ok, signal_sessions, %{}}, fn device_jid,
                                                                   {:ok, sessions, bundles} ->
      case fetch_prekeys_worker(state, device_jid, sessions) do
        {:ok, updated_sessions, fetched_bundles} ->
          {:cont, {:ok, updated_sessions, Map.merge(bundles, fetched_bundles)}}

        {:error, reason} ->
          {:halt, {:error, {:prekey_fetch_failed, device_jid, reason}}}
      end
    end)
  end

  defp retry_missing_prekeys_worker(
         _state,
         _requested_device_jids,
         {:error, _reason} = error,
         _prekey_bundles,
         _context
       ),
       do: {error, %{}}

  defp retry_missing_prekeys_worker(
         state,
         requested_device_jids,
         sessions,
         prekey_bundles,
         context
       ) do
    prekey_bundles = prekey_bundles || %{}

    case SessionStore.store?(sessions) do
      true ->
        retry_missing_prekeys_from_store(
          state,
          requested_device_jids,
          sessions,
          prekey_bundles,
          context
        )

      false ->
        {sessions, prekey_bundles}
    end
  end

  @spec retry_missing_prekeys_from_store(map(), [term()], term(), map(), term()) ::
          {term(), map()}
  defp retry_missing_prekeys_from_store(
         state,
         requested_device_jids,
         sessions,
         prekey_bundles,
         context
       ) do
    missing =
      requested_device_jids
      |> missing_prekey_bundle_targets(prekey_bundles)
      |> Enum.sort()

    case missing do
      [] ->
        {sessions, prekey_bundles}

      _ ->
        fetch_missing_prekeys_individually(state, missing, sessions, prekey_bundles, context)
    end
  end

  @spec missing_prekey_bundle_targets([term()], map()) :: [String.t()]
  defp missing_prekey_bundle_targets(requested_device_jids, prekey_bundles) do
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

  @spec fetch_missing_prekeys_individually(map(), [String.t()], term(), map(), term()) ::
          {term(), map()}
  defp fetch_missing_prekeys_individually(state, missing, sessions, prekey_bundles, context) do
    Logger.warning(
      "[SEND] Missing #{context} prekey bundles for #{length(missing)} device(s), retrying individually: #{inspect(missing)}"
    )

    case fetch_prekeys_individually_worker(state, missing, sessions) do
      {:ok, retried_sessions, retried_bundles} ->
        {retried_sessions, Map.merge(prekey_bundles, retried_bundles)}

      {:error, reason} ->
        Logger.warning("[SEND] Individual #{context} prekey retry failed: #{inspect(reason)}")

        {sessions, prekey_bundles}
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
          create_sessions_for_bundles(
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
    message_id = outbound_message_id(opts, own_jid)
    timestamp = System.system_time(:second)

    with {target_specs, _all_usync_devices} <-
           resolve_send_targets(store, signal_sessions, jid, prekey_bundles, target_hints, opts),
         {:ok, payloads} <- build_send_payloads(jid, text, opts),
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
            build_multi_device_encrypted_message_node(
              jid,
              message_id,
              participant_nodes,
              store,
              include_identity
            )
            |> apply_message_node_attrs(opts)

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

  defp build_send_payloads(jid, text, opts) do
    proto = outbound_proto(text, opts)

    case Message.encode(proto) do
      {:ok, payload} ->
        recipient_payload = Encryption.pad_message(payload)

        own_payload =
          case build_own_devices_payload(proto, jid, nil) do
            {:ok, own_p} ->
              Encryption.pad_message(own_p)

            {:error, reason} ->
              Logger.warning("[SEND] Own-device payload failed for #{jid}: #{inspect(reason)}")
              recipient_payload
          end

        {:ok, %{recipient: recipient_payload, own: own_payload, raw_size: byte_size(payload)}}

      {:error, reason} ->
        {:error, {:proto_encode, reason}}
    end
  end

  defp outbound_proto(text, opts) do
    case Keyword.get(opts, :proto_message) do
      %Message{} = proto -> proto
      _ -> Messages.build_text_proto(text, [])
    end
  end

  defp resolve_send_targets(store, signal_sessions, jid, prekey_bundles, target_hints, opts) do
    all_prekey_bundles = prekey_bundles
    hints = target_hints
    self_chat_mode = Keyword.get(opts, :self_chat_mode, :dsm_all_non_current)

    recipient_targets_hint =
      finalize_soft_targets(
        store,
        signal_sessions,
        all_prekey_bundles,
        Map.get(hints, :recipient_devices, []),
        Map.get(hints, :recipient_cached_devices, [])
      )

    recipient_prekey_bundles = filter_prekey_bundles_for_identity(all_prekey_bundles, jid)

    recipient_targets =
      Targets.resolve_encryption_targets(
        signal_sessions,
        jid,
        recipient_prekey_bundles,
        recipient_targets_hint
      )

    own_base_jid = Account.local_account_base_jid(store)
    own_sender_jid = Map.get(hints, :own_identity_jid, own_base_jid)
    own_device_id = Account.local_account_device_id(store)
    all_usync_devices = Map.get(hints, :all_usync_devices, [])

    own_targets_hint =
      finalize_soft_targets(
        store,
        signal_sessions,
        all_prekey_bundles,
        Map.get(hints, :own_devices, []),
        Map.get(hints, :own_cached_devices, [])
      )

    own_targets =
      Targets.resolve_own_device_targets(
        signal_sessions,
        own_sender_jid,
        own_device_id,
        own_targets_hint
      )

    self_chat? = self_chat_destination?(store, jid, own_sender_jid)

    recipient_targets =
      if self_chat? do
        recipient_targets
        |> JIDUtils.normalize_target_list()
        |> Enum.reject(&current_device_target?(&1, own_device_id))
      else
        recipient_targets
      end

    target_specs =
      if self_chat? do
        specs =
          case self_chat_mode do
            :recipient_primary ->
              Logger.warning("[SEND] Self-chat fallback mode: recipient payload primary")
              JIDUtils.build_self_chat_fallback_target_specs(recipient_targets, own_targets, jid)

            _ ->
              Logger.debug("[SEND] Self-chat detected: DSM payload for all non-current targets")
              JIDUtils.build_self_chat_target_specs(recipient_targets, own_targets, jid)
          end

        Logger.debug("[SEND] Self-chat target specs: #{inspect(specs)}")
        specs
      else
        JIDUtils.build_dm_target_specs(recipient_targets, own_targets)
      end

    Logger.debug("[SEND] Recipient targets for #{jid}: #{inspect(recipient_targets)}")
    Logger.debug("[SEND] Own-device targets: #{inspect(own_targets)}")
    Logger.debug("[SEND] Final fanout targets: #{inspect(target_specs)}")

    {target_specs, all_usync_devices}
  end

  defp finalize_soft_targets(store, signal_sessions, prekey_bundles, live_targets, cached_targets) do
    if SessionStore.store?(signal_sessions) do
      live_targets = JIDUtils.normalize_target_list(live_targets)
      cached_targets = JIDUtils.normalize_target_list(cached_targets)

      {reachable_cached_targets, unreachable_cached_targets} =
        cached_targets
        |> Enum.reject(&(&1 in live_targets))
        |> split_reachable_cached_targets(store, prekey_bundles)

      if unreachable_cached_targets != [] do
        DeviceCache.evict_devices(store, unreachable_cached_targets)
      end

      JIDUtils.normalize_target_list(live_targets ++ reachable_cached_targets)
    else
      JIDUtils.normalize_target_list(live_targets)
    end
  end

  defp split_reachable_cached_targets(targets, store, prekey_bundles) do
    lid_mapping = Account.load_lid_mapping(store)

    Enum.split_with(targets, fn target_jid ->
      signal_jid = JIDUtils.resolve_signal_encryption_jid(target_jid, lid_mapping)

      Map.has_key?(prekey_bundles || %{}, target_jid) or
        Map.has_key?(prekey_bundles || %{}, signal_jid)
    end)
  end

  defp self_chat_destination?(store, jid, own_sender_jid) do
    own_base_jid = Account.local_account_base_jid(store)
    own_lid_jid = Account.local_account_lid_jid(store)

    own_user_parts =
      [own_base_jid, own_sender_jid, own_lid_jid]
      |> Enum.map(&jid_user_part/1)
      |> Enum.reject(&(&1 == ""))
      |> MapSet.new()

    dest_user = jid_user_part(jid)
    dest_user != "" and MapSet.member?(own_user_parts, dest_user)
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
        Chat.update_message_status(store, jid, message_id, :failed)
        error
    end
  end

  defp create_sessions_for_bundles(
         signal_sessions,
         requested_jid,
         bundles,
         local_identity,
         local_reg_id,
         lid_mapping
       ) do
    requested_jid = normalize_jid_for_signal(requested_jid)

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
        "[PREKEY] Creating session for wire_jid=#{device_jid} signal_jid=#{signal_jid} (request_jid=#{requested_jid})"
      )

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
  end

  defp resolve_bundle_jids(bundle, requested_jid, lid_mapping) do
    device_jid =
      bundle
      |> Map.get(:device_jid, requested_jid)
      |> normalize_jid_with_device()
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
      "[PREKEY] Session ready for wire_jid=#{device_jid} signal_jid=#{signal_jid}, base_key=#{if base_key, do: byte_size(base_key), else: "nil"} bytes"
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

  defp finalize_bundle_session_creation({:ok, updated_sessions, bundle_map})
       when map_size(bundle_map) > 0,
       do: {:ok, updated_sessions, bundle_map}

  defp finalize_bundle_session_creation({:ok, _updated_sessions, _bundle_map}),
    do: {:error, :no_sessions_created}

  defp finalize_bundle_session_creation({:error, reason}), do: {:error, reason}

  defp maybe_put_bundle_alias(bundle_map, alias_jid, source_jid, bundle)
       when is_binary(alias_jid) and is_binary(source_jid) and alias_jid != "" and
              source_jid != "" and
              alias_jid != source_jid do
    Map.put(bundle_map, alias_jid, bundle)
  end

  defp maybe_put_bundle_alias(bundle_map, _alias_jid, _source_jid, _bundle), do: bundle_map

  defp filter_prekey_bundles_for_identity(prekey_bundles, jid)
       when is_map(prekey_bundles) and map_size(prekey_bundles) > 0 do
    Targets.filter_prekey_bundles_for_identity(prekey_bundles, jid)
  end

  defp filter_prekey_bundles_for_identity(_prekey_bundles, _jid), do: %{}

  defp current_device_target?(jid, own_device_id)
       when is_integer(own_device_id) and own_device_id >= 0,
       do: JIDUtils.current_device_target?(jid, own_device_id)

  defp current_device_target?(_jid, _own_device_id), do: false

  defp build_own_devices_payload(proto_message, destination_jid, phash) do
    wrapped = %ExWapp.Proto.Message{
      deviceSentMessage: %ExWapp.Proto.DeviceSentMessage{
        destinationJid: strip_device_from_jid(destination_jid),
        message: proto_message,
        phash: phash
      }
    }

    Message.encode(wrapped)
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

  defp maybe_alias_signal_session(signal_sessions, requested_jid, device_jid, session) do
    requested_jid = normalize_jid_for_signal(requested_jid)
    device_jid = normalize_jid_with_device(device_jid)

    if requested_jid != "" and device_jid != "" and requested_jid != device_jid do
      Logger.debug("[PREKEY] Aliasing session #{requested_jid} -> #{device_jid}")
      SessionStore.put_session(signal_sessions, requested_jid, session)
    else
      signal_sessions
    end
  end

  defp build_multi_device_encrypted_message_node(
         jid,
         message_id,
         participant_nodes,
         store,
         include_identity
       ) do
    attrs = %{
      "id" => message_id,
      "to" => strip_device_from_jid(jid),
      "type" => "text"
    }

    participants_node = %Binary.Node{
      tag: "participants",
      attrs: %{},
      content: participant_nodes
    }

    content =
      if include_identity do
        case Account.get_device_identity_node(store) do
          {:ok, identity_node} ->
            Logger.debug("[SEND] Including device-identity in message")
            [participants_node, identity_node]

          _ ->
            [participants_node]
        end
      else
        [participants_node]
      end

    # Append tctoken for 1:1 messages if available (Baileys: messages-send.ts)
    base_jid = strip_device_from_jid(jid)
    content = Account.maybe_append_tctoken(content, base_jid, store)

    %Binary.Node{
      tag: "message",
      attrs: attrs,
      content: content
    }
  end

  defp apply_message_node_attrs(%Binary.Node{} = node, opts) do
    attrs = Map.put(node.attrs, "type", Keyword.get(opts, :message_node_type, "text"))

    attrs =
      case Keyword.get(opts, :mediatype) do
        mediatype when is_binary(mediatype) and mediatype != "" ->
          Map.put(attrs, "mediatype", mediatype)

        _ ->
          attrs
      end

    %{node | attrs: attrs}
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

  defp jid_user_part(jid) when is_binary(jid), do: JIDUtils.user_part(jid)

  defp jid_user_part(_), do: ""

  defp generate_request_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64() |> String.slice(0, 16)
  end

  defp outbound_message_id(opts, own_jid) do
    case Keyword.get(opts, :retry_message_id) do
      message_id when is_binary(message_id) and message_id != "" -> message_id
      _ -> Messages.generate_id(own_jid)
    end
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
