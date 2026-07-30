defmodule ExWapp.Session.Outbound.Direct do
  @moduledoc """
  Direct-message and self-chat outbound orchestration decisions.

  The session worker provides callbacks for USync and prekey IQ effects and
  remains responsible for encryption, persistence, and transport sends. This
  module owns direct session preparation, payload construction, fanout
  resolution, and final direct message-node composition.
  """

  require Logger

  alias ExWapp.{Binary, Config, Log, Messages}
  alias ExWapp.Signal.{Encryption, SessionStore}
  alias WAWebProtobufsE2E.{DeviceSentMessage, Message}

  alias ExWapp.Session.{
    Account,
    DeviceCache,
    JIDUtils
  }

  alias ExWapp.Session.Outbound.{Fanout, Prekeys}

  @type discovery_result ::
          {[String.t()], [String.t()], [String.t()], [String.t()], [String.t()], [String.t()]}

  @type discover_fun ::
          (String.t(), String.t(), non_neg_integer() | nil -> discovery_result())

  @type target_hints :: %{
          recipient_devices: [String.t()],
          recipient_cached_devices: [String.t()],
          own_devices: [String.t()],
          own_cached_devices: [String.t()],
          own_identity_jid: String.t(),
          all_usync_devices: [String.t()]
        }

  @type payloads :: %{
          recipient: binary(),
          own: binary(),
          raw_size: non_neg_integer()
        }

  @doc """
  Prepares Signal sessions and target hints for a direct or self-chat send.

  Network effects are supplied as callbacks so the worker keeps ownership of
  IQ sends, receives, and timeouts.
  """
  @spec prepare_sessions(
          map(),
          String.t(),
          non_neg_integer(),
          discover_fun(),
          Prekeys.fetch_many_fun(),
          Prekeys.fetch_one_fun(),
          keyword()
        ) ::
          {:ok, SessionStore.t(), map(), target_hints()} | {:error, term()}
  def prepare_sessions(
        state,
        jid,
        now_ms,
        discover_fun,
        fetch_many_fun,
        fetch_one_fun,
        opts \\ []
      )
      when is_binary(jid) and is_integer(now_ms) and is_function(discover_fun, 3) and
             is_function(fetch_many_fun, 2) and is_function(fetch_one_fun, 2) and
             is_list(opts) do
    signal_sessions = state.signal_sessions || SessionStore.new()
    own_sender_jid = Account.local_account_sender_identity_for_destination(state.store, jid)
    own_device_id = Account.local_account_device_id(state.store)
    recipient_base_jid = jid |> normalize_jid() |> strip_device()

    {recipient_devices, recipient_cached_devices, own_devices, own_cached_devices,
     all_usync_devices, all_device_jids} =
      discover_fun.(recipient_base_jid, own_sender_jid, own_device_id)

    self_chat? = self_chat_destination?(state.store, jid, own_sender_jid)

    reuse_self_chat_sessions? =
      self_chat? and Keyword.get(opts, :reuse_self_chat_sessions, false)

    signal_sessions =
      maybe_clear_self_chat_sessions(
        state.store,
        signal_sessions,
        all_device_jids,
        self_chat? and not reuse_self_chat_sessions?
      )

    own_target_candidates =
      own_devices
      |> JIDUtils.normalize_target_list()
      |> Enum.reject(&current_device_target?(&1, own_device_id))

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
      devices_needing_prekeys(
        state.runtime_cfg,
        state.store,
        signal_sessions,
        all_target_device_jids,
        own_targets_needing_prekeys(
          own_target_candidates,
          own_cached_devices,
          reuse_self_chat_sessions?
        ),
        now_ms
      )

    devices_needing_prekeys =
      maybe_expand_recipient_identity_targets(
        devices_needing_prekeys,
        recipient_devices,
        self_chat?
      )

    {updated_sessions, prekey_bundles} =
      Prekeys.fetch_direct(
        devices_needing_prekeys,
        signal_sessions,
        recipient_base_jid,
        fetch_many_fun,
        fetch_one_fun
      )

    finalize_prepared_sessions(
      updated_sessions,
      prekey_bundles,
      recipient_devices,
      recipient_cached_devices,
      own_target_candidates,
      own_cached_devices,
      own_sender_jid,
      all_participant_devices
    )
  end

  # Reusing a self-chat session leaves stale ratchet state behind, which makes
  # the whisper undecryptable on the other device; clearing forces a fresh pkmsg.
  @spec maybe_clear_self_chat_sessions(term(), SessionStore.t(), [String.t()], boolean()) ::
          SessionStore.t()
  defp maybe_clear_self_chat_sessions(store, sessions, all_device_jids, true),
    do: clear_self_chat_sessions(store, sessions, all_device_jids)

  defp maybe_clear_self_chat_sessions(_store, sessions, _all_device_jids, false), do: sessions

  # When self-chat sessions are reused none of our own devices needs a bundle.
  @spec own_targets_needing_prekeys([String.t()], [String.t()], boolean()) :: [String.t()]
  defp own_targets_needing_prekeys(_candidates, _cached, true = _reuse?), do: []

  defp own_targets_needing_prekeys(candidates, cached, false = _reuse?), do: candidates ++ cached

  # A self-chat has no recipient identity to expand: every target is our own.
  @spec maybe_expand_recipient_identity_targets([String.t()], [String.t()], boolean()) ::
          [String.t()]
  defp maybe_expand_recipient_identity_targets(devices, _recipient_devices, true = _self_chat?),
    do: devices

  defp maybe_expand_recipient_identity_targets(devices, recipient_devices, false = _self_chat?),
    do: Prekeys.expand_recipient_identity_targets(devices, recipient_devices)

  @doc """
  Builds padded recipient and own-device payloads for a direct send.
  """
  @spec build_payloads(Message.t(), String.t(), keyword()) ::
          {:ok, payloads()} | {:error, {:proto_encode, term()}}
  def build_payloads(%Message{} = proto, jid, opts)
      when is_binary(jid) and is_list(opts) do
    case Message.encode(proto) do
      {:ok, iodata} ->
        payload = IO.iodata_to_binary(iodata)
        recipient_payload = Encryption.pad_message(payload)
        own_device_destination = Keyword.get(opts, :own_device_destination_jid, jid)

        own_payload =
          build_own_payload_or_fallback(
            proto,
            own_device_destination,
            recipient_payload
          )

        {:ok, %{recipient: recipient_payload, own: own_payload, raw_size: byte_size(payload)}}

      {:error, reason} ->
        {:error, {:proto_encode, reason}}
    end
  end

  @doc """
  Resolves direct recipient and own-device fanout targets.

  Stale cached device entries rejected by the resolution are evicted.
  """
  @spec resolve_targets(
          term(),
          SessionStore.t(),
          String.t(),
          map(),
          map(),
          keyword()
        ) :: {[map()], [String.t()]}
  def resolve_targets(store, signal_sessions, jid, prekey_bundles, target_hints, opts)
      when is_binary(jid) and is_map(prekey_bundles) and is_map(target_hints) and is_list(opts) do
    self_chat_mode = Keyword.get(opts, :self_chat_mode, :dsm_all_non_current)

    resolution =
      Fanout.resolve(%{
        signal_sessions: signal_sessions,
        jid: jid,
        prekey_bundles: prekey_bundles,
        target_hints: target_hints,
        own_base_jid: Account.local_account_base_jid(store),
        own_lid_jid: Account.local_account_lid_jid(store),
        own_device_id: Account.local_account_device_id(store),
        lid_mapping: Account.load_lid_mapping(store),
        self_chat_mode: self_chat_mode
      })

    Enum.each(resolution.cached_eviction_batches, &DeviceCache.evict_devices(store, &1))
    log_resolution(resolution, jid, self_chat_mode)

    {resolution.target_specs, resolution.all_usync_devices}
  end

  @doc """
  Returns the retry message ID or generates a new outbound ID.
  """
  @spec message_id(keyword(), String.t()) :: String.t()
  def message_id(opts, own_jid) when is_list(opts) and is_binary(own_jid) do
    case Keyword.get(opts, :retry_message_id) do
      message_id when is_binary(message_id) and message_id != "" -> message_id
      _ -> Messages.generate_id(own_jid)
    end
  end

  @doc """
  Builds the final multi-device direct message node.
  """
  @spec build_encrypted_message_node(
          String.t(),
          String.t(),
          [Binary.Node.t()],
          term(),
          boolean()
        ) :: Binary.Node.t()
  def build_encrypted_message_node(jid, message_id, participant_nodes, store, include_identity)
      when is_binary(jid) and is_binary(message_id) and is_list(participant_nodes) and
             is_boolean(include_identity) do
    destination_jid = strip_device(jid)

    {participant_nodes, rejected_count} =
      filter_participants_for_destination(participant_nodes, destination_jid)

    if rejected_count > 0 do
      Logger.error(
        "[SEND] Removed #{rejected_count} mixed-family participant(s) at final message boundary " <>
          "destination_family=#{jid_family(destination_jid)}"
      )
    end

    attrs = %{
      "id" => message_id,
      "to" => destination_jid,
      "type" => "text"
    }

    participants_node = %Binary.Node{
      tag: "participants",
      attrs: %{},
      content: participant_nodes
    }

    content = [participants_node] ++ identity_content(store, include_identity)
    content = Account.maybe_append_tctoken(content, destination_jid, store)

    %Binary.Node{tag: "message", attrs: attrs, content: content}
  end

  @doc """
  Verifies that every encrypted participant uses the destination JID family.

  This is the final pre-send invariant. Fanout resolution performs the mapping;
  this check prevents a later regression from putting a PN participant into a
  LID message (or the reverse).
  """
  @spec validate_participant_family(String.t(), [Binary.Node.t()]) ::
          :ok | {:error, {:mixed_addressing_family, non_neg_integer()}}
  def validate_participant_family(jid, participant_nodes)
      when is_binary(jid) and is_list(participant_nodes) do
    destination_jid = strip_device(jid)

    {_accepted, rejected_count} =
      filter_participants_for_destination(participant_nodes, destination_jid)

    if rejected_count == 0 do
      :ok
    else
      Logger.error(
        "[SEND] Refusing direct message with #{rejected_count} mixed-family participant(s) " <>
          "destination_family=#{jid_family(destination_jid)}"
      )

      {:error, {:mixed_addressing_family, rejected_count}}
    end
  end

  @spec finalize_prepared_sessions(
          Prekeys.fetch_state(),
          map(),
          [String.t()],
          [String.t()],
          [String.t()],
          [String.t()],
          String.t(),
          [String.t()]
        ) ::
          {:ok, SessionStore.t(), map(), target_hints()} | {:error, term()}
  defp finalize_prepared_sessions(
         {:error, reason},
         _prekey_bundles,
         _recipient_devices,
         _recipient_cached_devices,
         _own_devices,
         _own_cached_devices,
         _own_sender_jid,
         _all_participant_devices
       ) do
    {:error, reason}
  end

  defp finalize_prepared_sessions(
         sessions,
         prekey_bundles,
         recipient_devices,
         recipient_cached_devices,
         own_devices,
         own_cached_devices,
         own_sender_jid,
         all_participant_devices
       ) do
    {:ok, sessions, prekey_bundles,
     %{
       recipient_devices: recipient_devices,
       recipient_cached_devices: recipient_cached_devices,
       own_devices: own_devices,
       own_cached_devices: own_cached_devices,
       own_identity_jid: own_sender_jid,
       all_usync_devices: all_participant_devices
     }}
  end

  @spec self_chat_destination?(term(), String.t(), String.t()) :: boolean()
  defp self_chat_destination?(store, jid, own_sender_jid) do
    Fanout.self_chat_destination?(
      jid,
      own_sender_jid,
      Account.local_account_base_jid(store),
      Account.local_account_lid_jid(store)
    )
  end

  @spec clear_self_chat_sessions(term(), SessionStore.t(), [String.t()]) :: SessionStore.t()
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

  @spec devices_needing_prekeys(
          map(),
          term(),
          SessionStore.t(),
          [term()],
          [term()],
          non_neg_integer()
        ) :: [String.t()]
  defp devices_needing_prekeys(
         runtime_cfg,
         store,
         signal_sessions,
         all_device_jids,
         own_device_jids,
         now_ms
       ) do
    session_max_age_ms =
      Config.get(
        runtime_cfg || %{},
        [:signal, :session_max_age_ms],
        :timer.hours(12)
      )

    Prekeys.devices_needing_prekeys(
      signal_sessions,
      all_device_jids,
      own_device_jids,
      Account.load_lid_mapping(store),
      session_max_age_ms,
      now_ms
    )
  end

  @spec current_device_target?(term(), term()) :: boolean()
  defp current_device_target?(jid, own_device_id)
       when is_integer(own_device_id) and own_device_id >= 0,
       do: JIDUtils.current_device_target?(jid, own_device_id)

  defp current_device_target?(_jid, _own_device_id), do: false

  @spec build_own_payload_or_fallback(Message.t(), String.t(), binary()) :: binary()
  defp build_own_payload_or_fallback(proto, own_device_destination, recipient_payload) do
    case build_own_devices_payload(proto, own_device_destination, nil) do
      {:ok, own_payload} ->
        Encryption.pad_message(own_payload)

      {:error, reason} ->
        Logger.warning(
          "[SEND] Own-device payload failed for #{Log.reference(own_device_destination)}: #{Log.reason(reason)}"
        )

        recipient_payload
    end
  end

  @spec build_own_devices_payload(Message.t(), String.t(), String.t() | nil) ::
          {:ok, binary()} | {:error, term()}
  defp build_own_devices_payload(proto_message, destination_jid, phash) do
    wrapped = %Message{
      deviceSentMessage: %DeviceSentMessage{
        destinationJID: strip_device(destination_jid),
        message: proto_message,
        phash: phash
      }
    }

    with {:ok, iodata} <- Message.encode(wrapped) do
      {:ok, IO.iodata_to_binary(iodata)}
    end
  end

  @spec log_resolution(map(), String.t(), term()) :: :ok
  defp log_resolution(resolution, jid, self_chat_mode) do
    if resolution.self_chat? do
      log_self_chat_resolution(resolution, self_chat_mode)
    end

    Logger.debug(
      "[SEND] Recipient targets for #{Log.reference(jid)}: count=#{length(resolution.recipient_targets)}"
    )

    Logger.debug("[SEND] Own-device targets: count=#{length(resolution.own_targets)}")
    Logger.debug("[SEND] Final fanout targets: count=#{length(resolution.target_specs)}")
  end

  @spec log_self_chat_resolution(map(), term()) :: :ok
  defp log_self_chat_resolution(resolution, :recipient_primary) do
    Logger.warning("[SEND] Self-chat fallback mode: recipient payload primary")
    Logger.debug("[SEND] Self-chat target specs: count=#{length(resolution.target_specs)}")
  end

  defp log_self_chat_resolution(resolution, _mode) do
    Logger.debug("[SEND] Self-chat detected: DSM payload for all non-current targets")
    Logger.debug("[SEND] Self-chat target specs: count=#{length(resolution.target_specs)}")
  end

  @spec identity_content(term(), boolean()) :: [Binary.Node.t()]
  defp identity_content(_store, false), do: []

  defp identity_content(store, true) do
    case Account.get_device_identity_node(store) do
      {:ok, identity_node} ->
        Logger.debug("[SEND] Including device-identity in message")
        [identity_node]

      _ ->
        []
    end
  end

  @spec normalize_jid(String.t()) :: String.t()
  defp normalize_jid(jid), do: JIDUtils.normalize_with_device(jid)

  @spec strip_device(term()) :: String.t()
  defp strip_device(jid) when is_binary(jid), do: JIDUtils.strip_device(jid)
  defp strip_device(%ExWapp.JID{} = jid), do: JIDUtils.strip_device(jid)
  defp strip_device(_), do: ""

  @spec filter_participants_for_destination([Binary.Node.t()], String.t()) ::
          {[Binary.Node.t()], non_neg_integer()}
  defp filter_participants_for_destination(participant_nodes, destination_jid) do
    {accepted, rejected} =
      Enum.split_with(participant_nodes, fn
        %Binary.Node{tag: "to", attrs: %{"jid" => participant_jid}} ->
          normalized_jid = JIDUtils.normalize_with_device(participant_jid)

          normalized_jid != "" and
            JIDUtils.lid_jid?(normalized_jid) == JIDUtils.lid_jid?(destination_jid)

        _ ->
          false
      end)

    {accepted, length(rejected)}
  end

  @spec jid_family(String.t()) :: String.t()
  defp jid_family(jid), do: if(JIDUtils.lid_jid?(jid), do: "lid", else: "pn")
end
