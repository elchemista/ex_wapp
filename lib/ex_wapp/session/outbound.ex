defmodule ExWapp.Session.Outbound do
  @moduledoc false

  require Logger

  alias ExWapp.{Binary, Store, Telemetry}

  alias ExWapp.Session.{
    Account,
    IQ,
    JIDUtils,
    MessageNode,
    Targets
  }

  def send_text_worker(session_pid, state, jid, text) do
    normalized_jid = normalize_jid_with_device(jid)

    if ExWapp.JID.is_group?(normalized_jid) do
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
            target_hints
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
    message_id = ExWapp.Messages.generate_id()
    timestamp = System.system_time(:second)

    with {:ok, group_info} <- query_group_info_worker(state, group_jid),
         {:ok, updated_sessions, prekey_bundles, distribution_targets} <-
           ensure_group_sender_key_sessions_worker(state, group_jid, group_info.participants),
         proto <- ExWapp.Messages.build_text_proto(text, []),
         {:ok, payload} <- ExWapp.Proto.Message.encode(proto),
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

      ExWapp.Chat.add_message(store, group_jid, pending_message)

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
          ExWapp.Chat.update_message_status(store, group_jid, message_id, :failed)
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
    padded_group_payload = ExWapp.Signal.Encryption.pad_message(message_payload)
    sender_identity = local_account_sender_key_jid(store)

    with true <- sender_identity != "" or {:error, :missing_sender_identity},
         {:ok, distribution_payload} <-
           ExWapp.Signal.SenderKey.create_outbound_distribution_message(
             store,
             group_jid,
             sender_identity
           ),
         {:ok, skmsg_payload} <-
           ExWapp.Signal.SenderKey.encrypt_outbound_group_message(
             store,
             group_jid,
             sender_identity,
             padded_group_payload
           ) do
      {:ok, ExWapp.Signal.Encryption.pad_message(distribution_payload), skmsg_payload}
    else
      false -> {:error, :missing_sender_identity}
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_group_sender_key_sessions_worker(state, group_jid, participant_jids) do
    signal_sessions = state.signal_sessions || ExWapp.Signal.SessionStore.new()
    own_base_jid = local_account_base_jid(state.store)
    own_lid_jid = local_account_lid_jid(state.store)
    own_device_id = local_account_device_id(state.store)

    query_jids =
      (participant_jids ++ [own_base_jid, own_lid_jid])
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.map(&strip_device_from_jid/1)
      |> Enum.uniq()

    device_map =
      case query_device_list_worker(state, query_jids) do
        {:ok, map} ->
          Logger.info("[SEND] Group usync device map for #{group_jid}: #{inspect(map)}")
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
      |> normalize_target_list()
      |> Enum.reject(
        &group_current_device_target?(&1, own_device_id, [own_base_jid, own_lid_jid])
      )
      |> Enum.uniq()

    Logger.info(
      "[SEND] Group sender-key distribution targets for #{group_jid}: #{inspect(distribution_targets)}"
    )

    own_identity_set =
      [own_base_jid, own_lid_jid]
      |> Enum.map(&jid_identity/1)
      |> Enum.reject(fn {user, server} -> user == "" or server == "" end)
      |> MapSet.new()

    devices_needing_prekeys =
      Enum.filter(distribution_targets, fn device_jid ->
        target_identity = jid_identity(device_jid)

        # Pragmatic sync fix: always refresh our own targets so distribution fanout
        # to phone/other linked devices starts with a clean pkmsg bootstrap.
        MapSet.member?(own_identity_set, target_identity) or
          not ExWapp.Signal.SessionStore.has_session?(signal_sessions, device_jid)
      end)

    {updated_sessions, prekey_bundles} =
      if devices_needing_prekeys == [] do
        {signal_sessions, %{}}
      else
        Logger.info(
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
    target_identity = jid_identity(target_jid)

    own_identity_set =
      own_identities
      |> Enum.map(&jid_identity/1)
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
      maybe_put_message_attr(attrs, "addressing_mode", normalize_addressing_mode(addressing_mode))

    participant_jids = extract_participant_jids(participant_nodes)
    attrs = maybe_put_message_attr(attrs, "phash", generate_participant_hash_v2(participant_jids))

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
        case get_device_identity_node(store) do
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

    Logger.info("[GROUP] Querying group info for #{group_jid}")

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
        |> normalize_target_list()
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
    signal_sessions = state.signal_sessions || ExWapp.Signal.SessionStore.new()
    own_sender_jid = local_account_sender_identity_for_destination(state.store, jid)
    own_device_id = local_account_device_id(state.store)
    recipient_base_jid = strip_device_from_jid(normalize_jid_with_device(jid))

    # Step 1: Discover devices for both recipient and own JID via usync
    query_jids =
      if own_sender_jid != "" and own_sender_jid != recipient_base_jid do
        [recipient_base_jid, own_sender_jid]
      else
        [recipient_base_jid]
      end

    device_map =
      case query_device_list_worker(state, query_jids) do
        {:ok, map} ->
          Logger.info("[SEND] USync device map: #{inspect(map)}")
          map

        {:error, reason} ->
          Logger.warning(
            "[SEND] USync query failed (#{inspect(reason)}), falling back to prekey-only discovery"
          )

          %{}
      end

    # Step 2: Determine all device JIDs that need sessions
    recipient_devices =
      case Map.get(device_map, recipient_base_jid, []) do
        [] -> [recipient_base_jid]
        devices -> devices
      end
      |> normalize_target_list()

    own_devices_all = Map.get(device_map, own_sender_jid, []) |> normalize_target_list()

    # Filter out current device from own devices (for encryption targets)
    own_devices =
      own_devices_all
      |> Enum.reject(&current_device_target?(&1, own_device_id))

    # All usync devices INCLUDING current device — needed for phash (whatsmeow parity)
    all_usync_devices = normalize_target_list(recipient_devices ++ own_devices_all)

    Logger.info("[SEND] Discovered recipient devices: #{inspect(recipient_devices)}")
    Logger.info("[SEND] Discovered own devices (excl. self): #{inspect(own_devices)}")

    # Step 3: Find devices that need prekey fetch.
    # Follow WhatsMeow/Baileys behavior: reuse any existing session regardless of
    # whether the target is recipient or one of our own devices.
    all_device_jids = normalize_target_list(recipient_devices ++ own_devices)

    lid_mapping = load_lid_mapping(state.store)

    # Match whatsmeow: check existing sessions by BOTH wire JID and LID-mapped JID,
    # but fetch prekeys using the ORIGINAL wire JIDs (PN), not the LID-mapped ones.
    # The server expects prekey requests with PN JIDs; LID mapping is only for
    # Signal session storage/encryption (see whatsmeow send.go:1261-1289).
    devices_needing_prekeys =
      Enum.filter(all_device_jids, fn device_jid ->
        device_jid = normalize_jid_with_device(device_jid)
        signal_jid = resolve_signal_encryption_jid(device_jid, lid_mapping)

        not (ExWapp.Signal.SessionStore.has_session?(signal_sessions, signal_jid) or
               ExWapp.Signal.SessionStore.has_session?(signal_sessions, device_jid))
      end)
      |> normalize_target_list()

    # Step 4: Fetch prekeys for all devices that need them (batch)
    {updated_sessions, prekey_bundles} =
      if devices_needing_prekeys != [] do
        Logger.info(
          "[SEND] Fetching prekeys for #{length(devices_needing_prekeys)} devices: #{inspect(devices_needing_prekeys)}"
        )

        case fetch_prekeys_batch_worker(state, devices_needing_prekeys, signal_sessions) do
          {:ok, sessions, bundles} ->
            {sessions, bundles}

          {:error, reason} ->
            Logger.warning(
              "[SEND] Batch prekey fetch failed: #{inspect(reason)}, trying individual fetch"
            )

            # Fallback: fetch prekeys individually for recipient at least
            case fetch_prekeys_worker(state, recipient_base_jid, signal_sessions) do
              {:ok, sessions, bundles} -> {sessions, bundles}
              {:error, reason2} -> {:error, reason2}
            end
        end
      else
        Logger.info("[SEND] All #{length(all_device_jids)} devices already have sessions")
        {signal_sessions, %{}}
      end

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

  # Fetch prekeys for multiple device JIDs in a single IQ request
  defp fetch_prekeys_batch_worker(
         %{conn: conn, store: store} = state,
         device_jids,
         signal_sessions
       )
       when is_list(device_jids) and device_jids != [] do
    message_id = generate_request_id()
    request_node = build_prekey_request(device_jids, message_id)

    Logger.info("[PREKEY] Sending batch prekey request for #{length(device_jids)} devices")

    case send_transport_node(state, conn, request_node) do
      :ok ->
        receive do
          {:prekey_response, ^message_id, response_node} ->
            Logger.info("[PREKEY] Got batch prekey response")
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
    request_node = build_prekey_request(jid, message_id)

    Logger.info("[PREKEY] Sending prekey request for #{jid}")

    # Send the IQ - we'll receive the response directly since we're not a GenServer
    case send_transport_node(state, conn, request_node) do
      :ok ->
        # Wait for response - the session will forward it to us
        receive do
          {:prekey_response, ^message_id, response_node} ->
            Logger.info("[PREKEY] Got prekey response")
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
      |> normalize_target_list()
      |> MapSet.new()

    returned =
      prekey_bundles
      |> Map.keys()
      |> normalize_target_list()
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
    case parse_prekey_response(response_node) do
      {:ok, bundles} ->
        Logger.info("[PREKEY] Parsed #{length(bundles)} prekey bundles, creating sessions")

        # Get local identity
        data = Store.load!(store)
        signal_data = Map.get(data, :signal, %{})
        local_identity = Map.get(signal_data, :identity_key)
        local_reg_id = Map.get(signal_data, :registration_id, 0)
        lid_mapping = load_lid_mapping(store)

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
         target_hints
       ) do
    message_id = ExWapp.Messages.generate_id()
    timestamp = System.system_time(:second)

    proto = ExWapp.Messages.build_text_proto(text, [])

    case ExWapp.Proto.Message.encode(proto) do
      {:ok, payload} ->
        recipient_payload = ExWapp.Signal.Encryption.pad_message(payload)

        own_payload =
          case build_own_devices_payload(proto, jid) do
            {:ok, own_payload} ->
              ExWapp.Signal.Encryption.pad_message(own_payload)

            {:error, reason} ->
              Logger.warning(
                "[SEND] Failed to build own-device payload for #{jid}, reusing primary payload: #{inspect(reason)}"
              )

              recipient_payload
          end

        all_prekey_bundles = prekey_bundles || %{}

        recipient_prekey_bundles =
          filter_prekey_bundles_for_identity(all_prekey_bundles, jid)

        hinted_recipient_targets = Map.get(target_hints || %{}, :recipient_devices, [])

        recipient_targets =
          resolve_encryption_targets(
            signal_sessions,
            jid,
            recipient_prekey_bundles,
            hinted_recipient_targets
          )

        own_base_jid = local_account_base_jid(store)
        own_sender_jid = Map.get(target_hints || %{}, :own_identity_jid, own_base_jid)
        own_device_id = local_account_device_id(store)
        hinted_own_targets = Map.get(target_hints || %{}, :own_devices, [])
        all_usync_devices = Map.get(target_hints || %{}, :all_usync_devices, [])

        own_targets =
          resolve_own_device_targets(
            signal_sessions,
            own_sender_jid,
            own_device_id,
            hinted_own_targets
          )

        own_lid_jid = local_account_lid_jid(store)

        # Match whatsmeow: compare user parts only (not full {user, server} tuples),
        # since own JIDs may use different server suffixes (@s.whatsapp.net vs @lid).
        own_user_parts =
          [own_base_jid, own_sender_jid, own_lid_jid]
          |> Enum.map(&jid_user_part/1)
          |> Enum.reject(&(&1 == ""))
          |> MapSet.new()

        dest_user = jid_user_part(jid)
        self_chat_destination? = dest_user != "" and MapSet.member?(own_user_parts, dest_user)

        recipient_targets =
          if self_chat_destination? do
            recipient_targets
            |> normalize_target_list()
            |> Enum.reject(&current_device_target?(&1, own_device_id))
          else
            recipient_targets
          end

        {target_specs, own_targets} =
          if self_chat_destination? do
            self_sync_targets = normalize_target_list(recipient_targets ++ own_targets)
            self_specs = Enum.map(self_sync_targets, &%{jid: &1, payload_kind: :own})
            {self_specs, self_sync_targets}
          else
            {build_dm_target_specs(recipient_targets, own_targets), own_targets}
          end

        if self_chat_destination? do
          Logger.info("[SEND] Self-chat detected: routing all non-self targets as own payload")
        end

        Logger.info("[SEND] Recipient targets for #{jid}: #{inspect(recipient_targets)}")
        Logger.info("[SEND] Own-device targets: #{inspect(own_targets)}")
        Logger.info("[SEND] Final fanout targets: #{inspect(target_specs)}")

        case encrypt_for_targets(
               store,
               signal_sessions,
               target_specs,
               %{recipient: recipient_payload, own: own_payload},
               all_prekey_bundles
             ) do
          {:ok, participant_nodes, updated_sessions, include_identity} ->
            persist_signal_sessions(session_pid, updated_sessions)

            pending_message = %{
              id: message_id,
              from_me: true,
              timestamp: timestamp,
              text: text,
              status: :pending,
              participant: nil,
              raw: nil
            }

            ExWapp.Chat.add_message(store, jid, pending_message)

            node =
              build_multi_device_encrypted_message_node(
                jid,
                message_id,
                participant_nodes,
                timestamp,
                store,
                include_identity,
                all_usync_devices
              )

            case send_transport_node(state, conn, node) do
              :ok ->
                Logger.info(
                  "[SEND] Sent encrypted message to #{length(participant_nodes)} targets (base=#{jid})"
                )

                emit_telemetry(
                  :message_sent,
                  %{message_count: 1, payload_bytes: byte_size(payload)},
                  state,
                  %{jid: jid, message_id: message_id, encryption: :multi_device}
                )

                {:ok, message_id}

              error ->
                ExWapp.Chat.update_message_status(store, jid, message_id, :failed)
                error
            end

          {:error, reason} ->
            Logger.error("[SEND] Encryption failed for all targets: #{inspect(reason)}")
            {:error, {:encryption_failed, reason}}
        end

      {:error, reason} ->
        {:error, {:proto_encode, reason}}
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
             signal_jid = resolve_signal_encryption_jid(device_jid, lid_mapping)
             signal_jid = if signal_jid == "", do: device_jid, else: signal_jid

             if device_jid == "" do
               {:halt, {:error, :invalid_device_jid}}
             else
               Logger.info(
                 "[PREKEY] Creating session for wire_jid=#{device_jid} signal_jid=#{signal_jid} (request_jid=#{requested_jid})"
               )

               case ExWapp.Signal.SessionStore.get_or_create_session(
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

                   Logger.info(
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

  defp resolve_encryption_targets(signal_sessions, jid, prekey_bundles, hinted_targets) do
    Targets.resolve_encryption_targets(signal_sessions, jid, prekey_bundles, hinted_targets)
  end

  defp filter_prekey_bundles_for_identity(prekey_bundles, jid)
       when is_map(prekey_bundles) and map_size(prekey_bundles) > 0 do
    Targets.filter_prekey_bundles_for_identity(prekey_bundles, jid)
  end

  defp filter_prekey_bundles_for_identity(_prekey_bundles, _jid), do: %{}

  defp resolve_own_device_targets(signal_sessions, own_base_jid, own_device_id, hinted_targets) do
    Targets.resolve_own_device_targets(
      signal_sessions,
      own_base_jid,
      own_device_id,
      hinted_targets
    )
  end

  defp normalize_target_list(targets), do: JIDUtils.normalize_target_list(targets)

  defp build_dm_target_specs(recipient_targets, own_targets),
    do: JIDUtils.build_dm_target_specs(recipient_targets, own_targets)

  defp current_device_target?(jid, own_device_id)
       when is_integer(own_device_id) and own_device_id >= 0,
       do: JIDUtils.current_device_target?(jid, own_device_id)

  defp current_device_target?(_jid, _own_device_id), do: false

  defp load_lid_mapping(store), do: Account.load_lid_mapping(store)

  defp resolve_signal_encryption_jid(target_jid, lid_mapping) do
    JIDUtils.resolve_signal_encryption_jid(target_jid, lid_mapping)
  end

  defp local_account_base_jid(store), do: Account.local_account_base_jid(store)

  defp local_account_device_id(store), do: Account.local_account_device_id(store)

  defp local_account_lid_jid(store), do: Account.local_account_lid_jid(store)

  defp local_account_sender_key_jid(store), do: Account.local_account_sender_key_jid(store)

  defp local_account_sender_identity_for_destination(store, destination_jid),
    do: Account.local_account_sender_identity_for_destination(store, destination_jid)

  defp build_own_devices_payload(proto_message, destination_jid) do
    wrapped = %ExWapp.Proto.Message{
      deviceSentMessage: %ExWapp.Proto.DeviceSentMessage{
        destinationJid: strip_device_from_jid(destination_jid),
        message: proto_message,
        phash: nil
      }
    }

    ExWapp.Proto.Message.encode(wrapped)
  end

  defp encrypt_for_targets(store, signal_sessions, target_specs, payloads, prekey_bundles) do
    lid_mapping = load_lid_mapping(store)

    result =
      Enum.reduce(
        target_specs,
        %{nodes: [], sessions: signal_sessions, include_identity: false, errors: []},
        fn %{jid: target_jid, payload_kind: payload_kind}, acc ->
          target_jid = normalize_jid_with_device(target_jid)
          mapped_jid = resolve_signal_encryption_jid(target_jid, lid_mapping)

          signal_jid =
            cond do
              mapped_jid == "" or mapped_jid == target_jid ->
                target_jid

              true ->
                mapped_jid
            end

          sessions =
            if signal_jid != target_jid do
              ensure_signal_session_alias(acc.sessions, signal_jid, target_jid)
            else
              acc.sessions
            end

          if signal_jid != target_jid do
            Logger.info("[SEND] Encrypting wire_jid=#{target_jid} using signal_jid=#{signal_jid}")
          end

          padded_payload = Map.get(payloads, payload_kind, Map.get(payloads, :recipient))

          bundle =
            Map.get(prekey_bundles, target_jid) || Map.get(prekey_bundles, signal_jid) || %{}

          bundle_for_encrypt = if is_binary(Map.get(bundle, :base_key)), do: bundle, else: %{}

          if is_binary(padded_payload) do
            encrypt_result =
              ExWapp.Signal.Encryption.encrypt_for_recipient_sync(
                store,
                sessions,
                signal_jid,
                padded_payload,
                bundle_for_encrypt
              )

            encrypt_result =
              case encrypt_result do
                {:error, :no_session} when signal_jid != target_jid ->
                  Logger.info(
                    "[SEND] No session for signal_jid=#{signal_jid}, retrying with wire jid=#{target_jid}"
                  )

                  ExWapp.Signal.Encryption.encrypt_for_recipient_sync(
                    store,
                    sessions,
                    target_jid,
                    padded_payload,
                    bundle_for_encrypt
                  )

                other ->
                  other
              end

            case encrypt_result do
              {:ok, ciphertext, enc_type, updated_sessions} ->
                updated_sessions =
                  if signal_jid != target_jid do
                    ensure_signal_session_alias(updated_sessions, signal_jid, target_jid)
                  else
                    updated_sessions
                  end

                node = build_participant_encrypted_node(target_jid, ciphertext, enc_type)

                %{
                  acc
                  | nodes: [node | acc.nodes],
                    sessions: updated_sessions,
                    include_identity: acc.include_identity or enc_type == :prekey
                }

              {:error, reason} ->
                Logger.warning(
                  "[SEND] Failed to encrypt for wire_jid=#{target_jid} signal_jid=#{signal_jid}: #{inspect(reason)}"
                )

                %{acc | errors: [{target_jid, reason} | acc.errors]}
            end
          else
            Logger.warning("[SEND] Missing payload for target=#{target_jid} kind=#{payload_kind}")
            %{acc | errors: [{target_jid, :missing_payload} | acc.errors]}
          end
        end
      )

    if result.nodes == [] do
      {:error, {:no_encrypted_targets, Enum.reverse(result.errors)}}
    else
      {:ok, Enum.reverse(result.nodes), result.sessions, result.include_identity}
    end
  end

  defp ensure_signal_session_alias(signal_sessions, alias_jid, source_jid) do
    alias_jid = normalize_jid_with_device(alias_jid)
    source_jid = normalize_jid_with_device(source_jid)

    cond do
      alias_jid == "" or source_jid == "" or alias_jid == source_jid ->
        signal_sessions

      ExWapp.Signal.SessionStore.has_session?(signal_sessions, alias_jid) ->
        signal_sessions

      true ->
        case ExWapp.Signal.SessionStore.get_session(signal_sessions, source_jid) do
          {:ok, session} ->
            Logger.info("[SEND] Migrating session #{source_jid} -> #{alias_jid}")
            ExWapp.Signal.SessionStore.put_session(signal_sessions, alias_jid, session)

          :not_found ->
            signal_sessions
        end
    end
  end

  defp maybe_alias_signal_session(signal_sessions, requested_jid, device_jid, session) do
    requested_jid = normalize_jid_for_signal(requested_jid)
    device_jid = normalize_jid_with_device(device_jid)

    if requested_jid != "" and device_jid != "" and requested_jid != device_jid do
      Logger.info("[PREKEY] Aliasing session #{requested_jid} -> #{device_jid}")
      ExWapp.Signal.SessionStore.put_session(signal_sessions, requested_jid, session)
    else
      signal_sessions
    end
  end

  defp build_participant_encrypted_node(jid, ciphertext, enc_type) do
    MessageNode.build_participant_encrypted_node(jid, ciphertext, enc_type)
  end

  defp build_multi_device_encrypted_message_node(
         jid,
         message_id,
         participant_nodes,
         _timestamp,
         store,
         include_identity,
         all_usync_devices
       ) do
    attrs = %{
      "id" => message_id,
      "to" => strip_device_from_jid(jid),
      "type" => "text"
    }

    # Match whatsmeow: phash is computed from ALL usync devices (including current device),
    # not just the encrypted targets. See whatsmeow send.go:859 participantListHashV2(allDevices).
    phash_jids =
      if all_usync_devices != [] do
        all_usync_devices
      else
        extract_participant_jids(participant_nodes)
      end

    attrs = maybe_put_message_attr(attrs, "phash", generate_participant_hash_v2(phash_jids))

    participants_node = %Binary.Node{
      tag: "participants",
      attrs: %{},
      content: participant_nodes
    }

    content =
      if include_identity do
        case get_device_identity_node(store) do
          {:ok, identity_node} ->
            Logger.info("[SEND] Including device-identity in message")
            [participants_node, identity_node]

          _ ->
            [participants_node]
        end
      else
        [participants_node]
      end

    # Append tctoken for 1:1 messages if available (Baileys: messages-send.ts)
    base_jid = strip_device_from_jid(jid)
    content = maybe_append_tctoken(content, base_jid, store)

    %Binary.Node{
      tag: "message",
      attrs: attrs,
      content: content
    }
  end

  defp extract_participant_jids(participant_nodes) when is_list(participant_nodes) do
    MessageNode.extract_participant_jids(participant_nodes)
  end

  defp extract_participant_jids(_), do: []

  defp generate_participant_hash_v2(participants),
    do: MessageNode.generate_participant_hash_v2(participants)

  defp maybe_put_message_attr(attrs, key, value),
    do: MessageNode.maybe_put_message_attr(attrs, key, value)

  defp build_prekey_request(jid_or_jids, message_id),
    do: IQ.build_prekey_request(jid_or_jids, message_id)

  defp build_usync_device_query(jids, message_id),
    do: IQ.build_usync_device_query(jids, message_id)

  defp parse_usync_device_response(node), do: IQ.parse_usync_device_response(node)

  defp query_device_list_worker(%{conn: conn} = state, jids) when is_list(jids) do
    message_id = generate_request_id()
    query_node = build_usync_device_query(jids, message_id)

    Logger.info("[USYNC] Querying device list for #{inspect(jids)}")

    case send_transport_node(state, conn, query_node) do
      :ok ->
        receive do
          {:prekey_response, ^message_id, response_node} ->
            Logger.info("[USYNC] Got device list response")
            parse_usync_device_response(response_node)

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

  defp parse_prekey_response(node), do: IQ.parse_prekey_response(node)

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

  defp jid_identity(jid), do: JIDUtils.identity(jid)

  defp jid_user_part(jid) when is_binary(jid), do: JIDUtils.user_part(jid)

  defp jid_user_part(_), do: ""

  defp maybe_append_tctoken(content, jid, store),
    do: Account.maybe_append_tctoken(content, jid, store)

  defp get_device_identity_node(store), do: Account.get_device_identity_node(store)

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
    _ -> :ok
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

    Telemetry.execute([:ex_wapp, :session, event], measurements, metadata)
  end
end
