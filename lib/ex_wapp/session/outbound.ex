defmodule ExWapp.Session.Outbound do
  @moduledoc false

  require Logger

  alias ExWapp.{Binary, Chat, JID, Messages, Store, Telemetry}
  alias ExWapp.Proto.Message
  alias ExWapp.Signal.{Encryption, SenderKey, SessionStore}

  alias ExWapp.Session.{
    Account,
    IQ,
    JIDUtils,
    MessageNode,
    Targets
  }

  @spec send_text_worker(pid(), map(), String.t(), iodata(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_text_worker(session_pid, state, jid, text, opts \\ []) do
    normalized_jid = normalize_jid_with_device(jid)

    if JID.is_group?(normalized_jid) do
      do_send_group_worker(session_pid, state, normalized_jid, text)
    else
      jid = normalize_jid_for_signal(normalized_jid)

      case ensure_signal_session_worker(state, jid) do
        {:ok, updated_sessions, prekey_bundles, target_hints} ->
          # Now send with encryption
          do_send_encrypted(
            session_pid,
            state,
            updated_sessions,
            jid,
            text,
            prekey_bundles,
            target_hints,
            opts
          )

        {:error, reason} ->
          {:error, {:session_failed, reason}}
      end
    end
  end

  defp do_send_group_worker(
         session_pid,
         %{conn: conn, store: store} = state,
         group_jid,
         text
       )
       when is_pid(conn) do
    group_jid = strip_device_from_jid(normalize_jid_with_device(group_jid))
    own_jid = Account.local_account_base_jid(store)
    message_id = Messages.generate_id(own_jid)
    timestamp = System.system_time(:second)

    with {:ok, group_info} <- query_group_info_worker(state, group_jid),
         {:ok, updated_sessions, prekey_bundles, distribution_targets} <-
           ensure_group_sender_key_sessions_worker(state, group_jid, group_info.participants),
         proto <- Messages.build_text_proto(text, []),
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
      persist_signal_sessions(session_pid, persisted_sessions)

      pending_message = %{
        id: message_id,
        from_me: true,
        timestamp: timestamp,
        text: text,
        status: :pending,
        participant: nil,
        raw: nil
      }

      Chat.add_message(store, group_jid, pending_message)

      node =
        build_group_encrypted_message_node(
          group_jid,
          message_id,
          participant_nodes,
          skmsg_payload,
          group_info.addressing_mode,
          store,
          include_identity
        )

      case send_transport_node(state, conn, node) do
        :ok ->
          Logger.info(
            "[SEND] Sent group encrypted message to #{group_jid} (distribution_targets=#{length(participant_nodes)})"
          )

          emit_telemetry(
            :message_sent,
            %{message_count: 1, payload_bytes: byte_size(payload)},
            state,
            %{jid: group_jid, message_id: message_id, encryption: :group_sender_key}
          )

          {:ok, message_id}

        error ->
          Chat.update_message_status(store, group_jid, message_id, :failed)
          error
      end
    else
      {:error, reason} ->
        Logger.error("[SEND] Group send failed for #{group_jid}: #{inspect(reason)}")
        {:error, {:group_send_failed, reason}}
    end
  end

  defp do_send_group_worker(_session_pid, %{status: status}, _group_jid, _text),
    do: {:error, {:not_connected, status}}

  defp build_group_sender_key_payloads(store, group_jid, message_payload) do
    padded_group_payload = Encryption.pad_message(message_payload)
    sender_identity = Account.local_account_sender_key_jid(store)

    with true <- sender_identity != "" or {:error, :missing_sender_identity},
         {:ok, distribution_payload} <-
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
             padded_group_payload
           ) do
      {:ok, Encryption.pad_message(distribution_payload), skmsg_payload}
    else
      false -> {:error, :missing_sender_identity}
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_group_sender_key_sessions_worker(state, group_jid, participant_jids) do
    signal_sessions = state.signal_sessions || SessionStore.new()
    own_base_jid = Account.local_account_base_jid(state.store)
    own_lid_jid = Account.local_account_lid_jid(state.store)
    own_device_id = Account.local_account_device_id(state.store)

    query_jids =
      (participant_jids ++ [own_base_jid, own_lid_jid])
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.map(&strip_device_from_jid/1)
      |> Enum.uniq()

    device_map =
      case query_device_list_worker(state, query_jids) do
        {:ok, map} ->
          Logger.debug("[SEND] Group usync device map for #{group_jid}: #{inspect(map)}")
          map

        {:error, reason} ->
          Logger.warning("[SEND] Group usync query failed for #{group_jid}: #{inspect(reason)}")

          %{}
      end

    distribution_targets =
      query_jids
      |> Enum.flat_map(fn participant ->
        base_participant = strip_device_from_jid(participant)

        case Map.get(device_map, base_participant, []) do
          [] -> [base_participant]
          devices -> devices
        end
      end)
      |> JIDUtils.normalize_target_list()
      |> Enum.reject(
        &group_current_device_target?(&1, own_device_id, [own_base_jid, own_lid_jid])
      )
      |> Enum.uniq()

    Logger.debug(
      "[SEND] Group sender-key distribution targets for #{group_jid}: #{inspect(distribution_targets)}"
    )

    own_identity_set =
      [own_base_jid, own_lid_jid]
      |> Enum.map(&JIDUtils.identity/1)
      |> Enum.reject(fn {user, server} -> user == "" or server == "" end)
      |> MapSet.new()

    devices_needing_prekeys =
      Enum.filter(distribution_targets, fn device_jid ->
        target_identity = JIDUtils.identity(device_jid)

        # Pragmatic sync fix: always refresh our own targets so distribution fanout
        # to phone/other linked devices starts with a clean pkmsg bootstrap.
        MapSet.member?(own_identity_set, target_identity) or
          not SessionStore.has_session?(signal_sessions, device_jid)
      end)

    {updated_sessions, prekey_bundles} =
      if devices_needing_prekeys == [] do
        {signal_sessions, %{}}
      else
        Logger.debug(
          "[SEND] Fetching group prekeys for #{length(devices_needing_prekeys)} devices: #{inspect(devices_needing_prekeys)}"
        )

        case fetch_prekeys_batch_worker(state, devices_needing_prekeys, signal_sessions) do
          {:ok, sessions, bundles} ->
            {sessions, bundles}

          {:error, reason} ->
            Logger.warning(
              "[SEND] Group batch prekey fetch failed: #{inspect(reason)}, retrying individually"
            )

            fetch_prekeys_individually_worker(state, devices_needing_prekeys, signal_sessions)
        end
      end

    {updated_sessions, prekey_bundles} =
      retry_missing_prekeys_worker(
        state,
        devices_needing_prekeys,
        updated_sessions,
        prekey_bundles,
        "group"
      )

    case updated_sessions do
      {:error, reason} ->
        {:error, reason}

      sessions ->
        {:ok, sessions, prekey_bundles, distribution_targets}
    end
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

  defp query_group_info_worker(%{conn: conn} = state, group_jid) do
    message_id = generate_request_id()
    query_node = build_group_info_query(group_jid, message_id)

    Logger.debug("[GROUP] Querying group info for #{group_jid}")

    case send_transport_node(state, conn, query_node) do
      :ok ->
        receive do
          {:prekey_response, ^message_id, response_node} ->
            parse_group_info_response(response_node, group_jid)

          {:prekey_error, ^message_id, error} ->
            {:error, {:group_info_query_error, error}}
        after
          15_000 ->
            {:error, :group_info_timeout}
        end

      error ->
        {:error, {:group_info_send_failed, error}}
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
      participants =
        (group_node.content || [])
        |> Enum.filter(&match?(%Binary.Node{tag: "participant"}, &1))
        |> Enum.flat_map(&extract_group_participant_identities/1)
        |> JIDUtils.normalize_target_list()
        |> Enum.map(&strip_device_from_jid/1)
        |> Enum.reject(&(&1 == group_jid))
        |> Enum.uniq()

      if participants == [] do
        {:error, :empty_group_participants}
      else
        addressing_mode = Map.get(group_node.attrs || %{}, "addressing_mode")
        {:ok, %{participants: participants, addressing_mode: addressing_mode}}
      end
    end
  end

  defp parse_group_info_response(%Binary.Node{attrs: %{"type" => "error"}} = node, _group_jid),
    do: {:error, {:group_info_error, node}}

  defp parse_group_info_response(_response, _group_jid),
    do: {:error, :invalid_group_info_response}

  defp extract_group_participant_identities(%Binary.Node{attrs: attrs}) when is_map(attrs) do
    [
      attrs["jid"],
      attrs["lid"],
      attrs["phone_number"],
      attrs["pn"]
    ]
    |> Enum.map(&normalize_jid_with_device/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp extract_group_participant_identities(_), do: []

  defp ensure_signal_session_worker(state, jid) do
    signal_sessions = state.signal_sessions || SessionStore.new()
    own_sender_jid = Account.local_account_sender_identity_for_destination(state.store, jid)
    own_device_id = Account.local_account_device_id(state.store)
    recipient_base_jid = strip_device_from_jid(normalize_jid_with_device(jid))

    {recipient_devices, own_devices, all_usync_devices, all_device_jids} =
      discover_devices(state, recipient_base_jid, own_sender_jid, own_device_id)

    # For self-chat, force fresh prekey-based sessions for all targets.
    # Existing sessions may have stale ratchet state from inbound sync or
    # previously failed sends.  A fresh outbound pkmsg is the most reliable
    # way to establish a working session pair (same approach as group send).
    self_chat? = self_chat_destination?(state.store, jid, own_sender_jid)

    signal_sessions =
      if self_chat? do
        lid_mapping = Account.load_lid_mapping(state.store)

        Logger.info(
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
      else
        signal_sessions
      end

    devices_needing_prekeys =
      find_devices_needing_prekeys(state.store, signal_sessions, all_device_jids)

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
           own_devices: own_devices,
           own_identity_jid: own_sender_jid,
           all_usync_devices: all_usync_devices
         }}
    end
  end

  defp discover_devices(state, recipient_base_jid, own_sender_jid, own_device_id) do
    query_jids =
      if own_sender_jid != "" and own_sender_jid != recipient_base_jid do
        [recipient_base_jid, own_sender_jid]
      else
        [recipient_base_jid]
      end

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
      case Map.get(device_map, recipient_base_jid, []) do
        [] -> [recipient_base_jid]
        devices -> devices
      end
      |> JIDUtils.normalize_target_list()

    own_devices_all = Map.get(device_map, own_sender_jid, []) |> JIDUtils.normalize_target_list()
    own_devices = Enum.reject(own_devices_all, &current_device_target?(&1, own_device_id))

    # All usync devices INCLUDING current device — needed for phash (whatsmeow parity)
    all_usync_devices = JIDUtils.normalize_target_list(recipient_devices ++ own_devices_all)

    # Exclude current device from send targets.  For self-chat the recipient IS us,
    # so device 40 appears in recipient_devices — must be filtered here.
    all_device_jids =
      JIDUtils.normalize_target_list(recipient_devices ++ own_devices)
      |> Enum.reject(&current_device_target?(&1, own_device_id))

    Logger.debug("[SEND] Discovered recipient devices: #{inspect(recipient_devices)}")
    Logger.debug("[SEND] Discovered own devices (excl. self): #{inspect(own_devices)}")

    {recipient_devices, own_devices, all_usync_devices, all_device_jids}
  end

  # Match whatsmeow: check existing sessions by BOTH wire JID and LID-mapped JID,
  # but fetch prekeys using the ORIGINAL wire JIDs (PN), not the LID-mapped ones.
  defp find_devices_needing_prekeys(store, signal_sessions, all_device_jids) do
    lid_mapping = Account.load_lid_mapping(store)

    Enum.filter(all_device_jids, fn device_jid ->
      device_jid = normalize_jid_with_device(device_jid)
      signal_jid = JIDUtils.resolve_signal_encryption_jid(device_jid, lid_mapping)

      not (SessionStore.has_session?(signal_sessions, signal_jid) or
             SessionStore.has_session?(signal_sessions, device_jid))
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
          {:error, reason2} -> {:error, reason2}
        end
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
          30_000 ->
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
          30_000 ->
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
          {:cont, {:ok, updated_sessions, Map.merge(bundles, fetched_bundles || %{})}}

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
       )
       when is_map(sessions) do
    prekey_bundles = prekey_bundles || %{}

    requested =
      requested_device_jids
      |> JIDUtils.normalize_target_list()
      |> MapSet.new()

    returned =
      prekey_bundles
      |> Map.keys()
      |> JIDUtils.normalize_target_list()
      |> MapSet.new()

    missing =
      requested
      |> MapSet.difference(returned)
      |> MapSet.to_list()
      |> Enum.sort()

    if missing == [] do
      {sessions, prekey_bundles}
    else
      Logger.warning(
        "[SEND] Missing #{context} prekey bundles for #{length(missing)} device(s), retrying individually: #{inspect(missing)}"
      )

      case fetch_prekeys_individually_worker(state, missing, sessions) do
        {:ok, retried_sessions, retried_bundles} ->
          {retried_sessions, Map.merge(prekey_bundles, retried_bundles || %{})}

        {:error, reason} ->
          Logger.warning("[SEND] Individual #{context} prekey retry failed: #{inspect(reason)}")

          {sessions, prekey_bundles}
      end
    end
  end

  defp retry_missing_prekeys_worker(
         _state,
         _requested_device_jids,
         sessions,
         prekey_bundles,
         _context
       ),
       do: {sessions, prekey_bundles || %{}}

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
    message_id = Messages.generate_id(own_jid)
    timestamp = System.system_time(:second)

    with {target_specs, all_usync_devices} <-
           resolve_send_targets(store, signal_sessions, jid, prekey_bundles, target_hints, opts),
         # Keep participant hash computation for diagnostics/parity checks, but do not
         # include it in DM message attrs or DeviceSentMessage payloads.
         _participant_hash <- compute_participant_hash_for_send(all_usync_devices, target_specs),
         {:ok, payloads} <- build_send_payloads(jid, text),
         {:ok, participant_nodes, updated_sessions, include_identity} <-
           encrypt_for_targets(
             store,
             signal_sessions,
             target_specs,
             payloads,
             prekey_bundles || %{}
           ) do
      persist_signal_sessions(session_pid, updated_sessions)

      Chat.add_message(store, jid, %{
        id: message_id,
        from_me: true,
        timestamp: timestamp,
        text: text,
        status: :pending,
        participant: nil,
        raw: nil
      })

      node =
        build_multi_device_encrypted_message_node(
          jid,
          message_id,
          participant_nodes,
          store,
          include_identity
        )

      send_encrypted_node(state, conn, store, jid, message_id, node, payloads)
    else
      {:error, reason} ->
        Logger.error("[SEND] Encrypted send failed for #{jid}: #{inspect(reason)}")
        {:error, {:send_failed, reason}}
    end
  end

  defp build_send_payloads(jid, text) do
    proto = Messages.build_text_proto(text, [])

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

  defp compute_participant_hash_for_send(all_usync_devices, _target_specs)
       when is_list(all_usync_devices) and all_usync_devices != [] do
    MessageNode.generate_participant_hash_v2(all_usync_devices)
  end

  defp compute_participant_hash_for_send(_all_usync_devices, target_specs)
       when is_list(target_specs) do
    target_specs
    |> Enum.map(&Map.get(&1, :jid, ""))
    |> JIDUtils.normalize_target_list()
    |> MessageNode.generate_participant_hash_v2()
  end

  defp resolve_send_targets(store, signal_sessions, jid, prekey_bundles, target_hints, opts) do
    all_prekey_bundles = prekey_bundles || %{}
    hints = target_hints || %{}
    self_chat_mode = Keyword.get(opts, :self_chat_mode, :dsm_all_non_current)

    recipient_prekey_bundles = filter_prekey_bundles_for_identity(all_prekey_bundles, jid)

    recipient_targets =
      Targets.resolve_encryption_targets(
        signal_sessions,
        jid,
        recipient_prekey_bundles,
        Map.get(hints, :recipient_devices, [])
      )

    own_base_jid = Account.local_account_base_jid(store)
    own_sender_jid = Map.get(hints, :own_identity_jid, own_base_jid)
    own_device_id = Account.local_account_device_id(store)
    all_usync_devices = Map.get(hints, :all_usync_devices, [])

    own_targets =
      Targets.resolve_own_device_targets(
        signal_sessions,
        own_sender_jid,
        own_device_id,
        Map.get(hints, :own_devices, [])
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
              Logger.info("[SEND] Self-chat detected: DSM payload for all non-current targets")
              JIDUtils.build_self_chat_target_specs(recipient_targets, own_targets, jid)
          end

        Logger.info("[SEND] Self-chat target specs: #{inspect(specs)}")
        specs
      else
        JIDUtils.build_dm_target_specs(recipient_targets, own_targets)
      end

    Logger.debug("[SEND] Recipient targets for #{jid}: #{inspect(recipient_targets)}")
    Logger.debug("[SEND] Own-device targets: #{inspect(own_targets)}")
    Logger.debug("[SEND] Final fanout targets: #{inspect(target_specs)}")

    {target_specs, all_usync_devices}
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
        Logger.info("[SEND] Sent encrypted message to #{jid} id=#{message_id}")

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

    case Enum.reduce_while(
           bundles,
           {:ok, signal_sessions, %{}},
           fn bundle, {:ok, sessions, bundle_map} ->
             device_jid =
               bundle
               |> Map.get(:device_jid, requested_jid)
               |> normalize_jid_with_device()

             device_jid = if device_jid == "", do: requested_jid, else: device_jid
             signal_jid = JIDUtils.resolve_signal_encryption_jid(device_jid, lid_mapping)
             signal_jid = if signal_jid == "", do: device_jid, else: signal_jid

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
                      local_reg_id
                    ) do
                 {:ok, created_session, base_key, updated_sessions} ->
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

                   {:cont, {:ok, updated_sessions, bundle_map}}

                 {:error, reason} ->
                   {:halt, {:error, {:session_create_failed, device_jid, reason}}}
               end
             end
           end
         ) do
      {:ok, updated_sessions, bundle_map} when map_size(bundle_map) > 0 ->
        {:ok, updated_sessions, bundle_map}

      {:ok, _updated_sessions, _bundle_map} ->
        {:error, :no_sessions_created}

      {:error, reason} ->
        {:error, reason}
    end
  end

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
    result =
      Encryption.encrypt_for_recipient_sync(store, sessions, signal_jid, payload, bundle)

    result =
      case result do
        {:error, :no_session} when signal_jid != target_jid ->
          Logger.debug("[SEND] No session for signal_jid=#{signal_jid}, retrying with wire jid")
          Encryption.encrypt_for_recipient_sync(store, sessions, target_jid, payload, bundle)

        other ->
          other
      end

    case result do
      {:ok, ciphertext, enc_type, updated_sessions} ->
        if enc_type == :prekey do
          case ExWapp.Signal.WireFormat.parse_prekey_signal_message(ciphertext) do
            {:ok, parsed} ->
              Logger.info(
                "[SEND] pkmsg wire fields target=#{target_jid} reg_id=#{parsed.registration_id} signed_prekey_id=#{parsed.signed_prekey_id} prekey_id=#{inspect(parsed.prekey_id)} base_key_size=#{byte_size(parsed.base_key)} inner_size=#{byte_size(parsed.message)}"
              )

            {:error, reason} ->
              Logger.warning(
                "[SEND] pkmsg wire parse failed for target=#{target_jid}: #{inspect(reason)}"
              )
          end
        end

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

      {:error, reason} ->
        Logger.warning("[SEND] Failed to encrypt for wire_jid=#{target_jid}: #{inspect(reason)}")
        %{acc | errors: [{target_jid, reason} | acc.errors]}
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

  defp query_device_list_worker(%{conn: conn} = state, jids) when is_list(jids) do
    message_id = generate_request_id()
    query_node = IQ.build_usync_device_query(jids, message_id)

    Logger.debug("[USYNC] Querying device list for #{inspect(jids)}")

    case send_transport_node(state, conn, query_node) do
      :ok ->
        receive do
          {:prekey_response, ^message_id, response_node} ->
            Logger.debug("[USYNC] Got device list response")
            IQ.parse_usync_device_response(response_node)

          {:prekey_error, ^message_id, error} ->
            Logger.warning("[USYNC] Device list query error: #{inspect(error)}")
            {:error, {:usync_query_error, error}}
        after
          15_000 ->
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

  defp find_child(_, _), do: nil

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

  defp send_transport_node(%{transport_mod: transport_mod}, conn, node) when is_pid(conn) do
    transport_mod.send_node(conn, node)
  end

  defp persist_signal_sessions(session_pid, sessions) do
    GenServer.call(session_pid, {:update_signal_sessions, sessions}, 30_000)
    :ok
  rescue
    e ->
      Logger.warning("[SEND] persist_signal_sessions failed: #{inspect(e)}")
      :ok
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
