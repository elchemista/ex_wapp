defmodule ExWapp.Session.Outbound.Group do
  @moduledoc """
  Group-specific outbound transformations and routing decisions.

  The session worker remains responsible for transport calls, response
  receives, timeouts, persistence, and retries. This module owns sender-key
  payload construction, group target selection, group IQ shapes, and group
  message-node composition.
  """

  require Logger

  alias ExWapp.{Binary, Config}
  alias ExWapp.Signal.{Encryption, SenderKey, SessionStore}

  alias ExWapp.Session.{
    Account,
    DeviceCache,
    JIDUtils,
    MessageNode
  }

  alias ExWapp.Session.Outbound.{DeviceDiscovery, Prekeys}

  @type group_info :: %{
          participants: [String.t()],
          addressing_mode: String.t() | nil
        }

  @doc """
  Creates the sender-key distribution payload and encrypted group payload.
  """
  @spec build_sender_key_payloads(term(), String.t(), binary()) ::
          {:ok, binary(), binary()} | {:error, term()}
  def build_sender_key_payloads(store, group_jid, message_payload)
      when is_binary(group_jid) and is_binary(message_payload) do
    padded_group_payload = Encryption.pad_message(message_payload)
    sender_identity = Account.local_account_sender_key_jid(store)

    if sender_identity == "" do
      {:error, :missing_sender_identity}
    else
      do_build_sender_key_payloads(
        store,
        group_jid,
        sender_identity,
        padded_group_payload
      )
    end
  end

  @doc """
  Builds the participant and local-account JIDs for the group USync query.
  """
  @spec query_jids([term()], term(), String.t(), String.t()) :: [String.t()]
  def query_jids(participant_jids, addressing_mode, own_base_jid, own_lid_jid)
      when is_list(participant_jids) do
    own_jids = own_jids_for_query(addressing_mode, own_base_jid, own_lid_jid)

    (participant_jids ++ own_jids)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&strip_device/1)
    |> Enum.uniq()
  end

  @doc """
  Resolves live and cached sender-key distribution targets.

  Targets incompatible with the group's addressing mode and the current local
  device are excluded.
  """
  @spec distribution_targets(
          [term()],
          map(),
          term(),
          non_neg_integer() | nil,
          String.t(),
          String.t(),
          term(),
          map()
        ) :: {[String.t()], [String.t()]}
  def distribution_targets(
        query_jids,
        device_map,
        addressing_mode,
        own_device_id,
        own_base_jid,
        own_lid_jid,
        store,
        runtime_cfg
      )
      when is_list(query_jids) and is_map(device_map) do
    {live_targets, cached_targets} =
      expand_distribution_targets(query_jids, device_map, store, runtime_cfg)

    live_targets =
      live_targets
      |> JIDUtils.normalize_target_list()
      |> filter_targets_for_addressing_mode(addressing_mode)
      |> Enum.reject(
        &current_local_device_target?(&1, own_device_id, [own_base_jid, own_lid_jid])
      )
      |> Enum.uniq()

    cached_targets =
      cached_targets
      |> JIDUtils.normalize_target_list()
      |> filter_targets_for_addressing_mode(addressing_mode)
      |> Enum.reject(
        &(current_local_device_target?(&1, own_device_id, [own_base_jid, own_lid_jid]) or
            &1 in live_targets)
      )
      |> Enum.uniq()

    {live_targets, cached_targets}
  end

  @doc """
  Selects group distribution targets that need a prekey bootstrap.
  """
  @spec prekey_targets(
          [term()],
          map(),
          SessionStore.t(),
          map(),
          String.t(),
          String.t(),
          non_neg_integer()
        ) :: [String.t()]
  def prekey_targets(
        distribution_targets,
        runtime_cfg,
        signal_sessions,
        lid_mapping,
        own_base_jid,
        own_lid_jid,
        now_ms
      )
      when is_list(distribution_targets) and is_map(lid_mapping) and is_integer(now_ms) do
    session_max_age_ms =
      Config.get(
        runtime_cfg || %{},
        [:signal, :session_max_age_ms],
        :timer.hours(12)
      )

    Prekeys.targets_needing_prekeys(
      signal_sessions,
      distribution_targets,
      own_identity_set(own_base_jid, own_lid_jid),
      lid_mapping,
      session_max_age_ms,
      now_ms
    )
  end

  @doc """
  Normalizes the group session preparation result.
  """
  @spec finalize_sessions_result(
          {:error, term()} | SessionStore.t(),
          map(),
          [String.t()]
        ) ::
          {:error, term()} | {:ok, SessionStore.t(), map(), [String.t()]}
  def finalize_sessions_result({:error, reason}, _prekey_bundles, _distribution_targets),
    do: {:error, reason}

  def finalize_sessions_result(sessions, prekey_bundles, distribution_targets) do
    {:ok, sessions, prekey_bundles, distribution_targets}
  end

  @doc """
  Builds the final encrypted group message node.
  """
  @spec build_encrypted_message_node(
          String.t(),
          String.t(),
          [Binary.Node.t()],
          binary(),
          term(),
          term(),
          boolean()
        ) :: Binary.Node.t()
  def build_encrypted_message_node(
        group_jid,
        message_id,
        participant_nodes,
        skmsg_payload,
        addressing_mode,
        store,
        include_identity
      )
      when is_binary(group_jid) and is_binary(message_id) and is_list(participant_nodes) and
             is_binary(skmsg_payload) and is_boolean(include_identity) do
    attrs =
      %{
        "id" => message_id,
        "to" => strip_device(group_jid),
        "type" => "text"
      }
      |> MessageNode.maybe_put_message_attr(
        "addressing_mode",
        normalize_addressing_mode(addressing_mode)
      )
      |> MessageNode.maybe_put_message_attr(
        "phash",
        participant_nodes
        |> MessageNode.extract_participant_jids()
        |> MessageNode.generate_participant_hash_v2()
      )

    skmsg_node = %Binary.Node{
      tag: "enc",
      attrs: %{"v" => "2", "type" => "skmsg"},
      content: Binary.raw(skmsg_payload)
    }

    content =
      participant_nodes_content(participant_nodes) ++
        identity_content(store, include_identity) ++ [skmsg_node]

    %Binary.Node{tag: "message", attrs: attrs, content: content}
  end

  @doc """
  Builds the IQ node used to request interactive group information.
  """
  @spec build_info_query(String.t(), String.t()) :: Binary.Node.t()
  def build_info_query(group_jid, message_id)
      when is_binary(group_jid) and is_binary(message_id) do
    %Binary.Node{
      tag: "iq",
      attrs: %{
        "id" => message_id,
        "xmlns" => "w:g2",
        "type" => "get",
        "to" => strip_device(group_jid)
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

  @doc """
  Parses the interactive group information response.
  """
  @spec parse_info_response(term(), String.t()) ::
          {:ok, group_info()} | {:error, term()}
  def parse_info_response(
        %Binary.Node{tag: "iq", attrs: %{"type" => "result"}, content: content},
        group_jid
      )
      when is_list(content) and is_binary(group_jid) do
    case find_child(content, "group") do
      nil -> {:error, :missing_group_node}
      group_node -> parse_group_node(group_node, group_jid)
    end
  end

  def parse_info_response(%Binary.Node{attrs: %{"type" => "error"}} = node, _group_jid),
    do: {:error, {:group_info_error, node}}

  def parse_info_response(_response, _group_jid),
    do: {:error, :invalid_group_info_response}

  @spec do_build_sender_key_payloads(
          term(),
          String.t(),
          String.t(),
          binary()
        ) :: {:ok, binary(), binary()} | {:error, term()}
  defp do_build_sender_key_payloads(store, group_jid, sender_identity, padded_payload) do
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

  @spec own_jids_for_query(term(), String.t(), String.t()) :: [String.t()]
  defp own_jids_for_query("lid", _own_base_jid, own_lid_jid), do: [own_lid_jid]
  defp own_jids_for_query(_mode, own_base_jid, _own_lid_jid), do: [own_base_jid]

  @spec expand_distribution_targets([term()], map(), term(), map()) ::
          {[String.t()], [String.t()]}
  defp expand_distribution_targets(query_jids, device_map, store, runtime_cfg) do
    lid_mapping = Account.load_lid_mapping(store)

    Enum.reduce(query_jids, {[], []}, fn participant, {live_acc, cached_acc} ->
      base_participant = strip_device(participant)

      live_targets =
        [
          base_participant
          | DeviceDiscovery.resolve_identity_devices(device_map, base_participant, lid_mapping)
        ]
        |> JIDUtils.normalize_target_list()

      cached_targets =
        DeviceCache.resolve_recent_devices(store, base_participant, runtime_cfg)
        |> Enum.reject(&(&1 in live_targets))

      {live_acc ++ live_targets, cached_acc ++ cached_targets}
    end)
  end

  @spec current_local_device_target?(term(), term(), [String.t()]) :: boolean()
  defp current_local_device_target?(target_jid, own_device_id, own_identities) do
    target_identity = JIDUtils.identity(target_jid)

    own_identity_set =
      own_identities
      |> Enum.map(&JIDUtils.identity/1)
      |> Enum.reject(fn {user, server} -> user == "" or server == "" end)
      |> MapSet.new()

    MapSet.member?(own_identity_set, target_identity) and
      valid_current_device_target?(target_jid, own_device_id)
  end

  @spec valid_current_device_target?(term(), term()) :: boolean()
  defp valid_current_device_target?(jid, own_device_id)
       when is_integer(own_device_id) and own_device_id >= 0,
       do: JIDUtils.current_device_target?(jid, own_device_id)

  defp valid_current_device_target?(_jid, _own_device_id), do: false

  @spec filter_targets_for_addressing_mode([String.t()], term()) :: [String.t()]
  defp filter_targets_for_addressing_mode(targets, "lid") do
    {lid_targets, mismatched_targets} =
      Enum.split_with(targets, fn target_jid ->
        target_jid
        |> strip_device()
        |> JIDUtils.lid_jid?()
      end)

    if mismatched_targets != [] do
      Logger.warning(
        "[SEND] Dropping non-LID targets in lid addressing mode: #{inspect(mismatched_targets)}"
      )
    end

    lid_targets
  end

  defp filter_targets_for_addressing_mode(targets, _), do: targets

  @spec own_identity_set(String.t(), String.t()) ::
          MapSet.t({String.t(), String.t()})
  defp own_identity_set(own_base_jid, own_lid_jid) do
    [own_base_jid, own_lid_jid]
    |> Enum.map(&JIDUtils.identity/1)
    |> Enum.reject(fn {user, server} -> user == "" or server == "" end)
    |> MapSet.new()
  end

  @spec participant_nodes_content([Binary.Node.t()]) :: [Binary.Node.t()]
  defp participant_nodes_content([]), do: []

  defp participant_nodes_content(participant_nodes) do
    [
      %Binary.Node{
        tag: "participants",
        attrs: %{},
        content: participant_nodes
      }
    ]
  end

  @spec identity_content(term(), boolean()) :: [Binary.Node.t()]
  defp identity_content(_store, false), do: []

  defp identity_content(store, true) do
    case Account.get_device_identity_node(store) do
      {:ok, identity_node} -> [identity_node]
      _ -> []
    end
  end

  @spec normalize_addressing_mode(term()) :: String.t() | nil
  defp normalize_addressing_mode(mode) when mode in ["lid", "pn"], do: mode
  defp normalize_addressing_mode(_), do: nil

  @spec parse_group_node(Binary.Node.t(), String.t()) ::
          {:ok, group_info()} | {:error, :empty_group_participants}
  defp parse_group_node(group_node, group_jid) do
    addressing_mode = Map.get(group_node.attrs, "addressing_mode")

    participants =
      (group_node.content || [])
      |> Enum.filter(&match?(%Binary.Node{tag: "participant"}, &1))
      |> Enum.map(&extract_participant_identity(&1, addressing_mode))
      |> Enum.reject(&(&1 == ""))
      |> JIDUtils.normalize_target_list()
      |> Enum.map(&strip_device/1)
      |> Enum.reject(&(&1 == group_jid))
      |> Enum.uniq()

    if participants == [] do
      {:error, :empty_group_participants}
    else
      {:ok, %{participants: participants, addressing_mode: addressing_mode}}
    end
  end

  @spec extract_participant_identity(term(), term()) :: String.t()
  defp extract_participant_identity(%Binary.Node{attrs: attrs}, addressing_mode)
       when is_map(attrs) do
    lid = normalize_jid(attrs["lid"])
    pn = normalize_jid(attrs["jid"] || attrs["pn"] || attrs["phone_number"])

    case addressing_mode do
      "lid" -> if lid != "", do: lid, else: pn
      _ -> if pn != "", do: pn, else: lid
    end
  end

  defp extract_participant_identity(_, _), do: ""

  @spec find_child(term(), String.t()) :: Binary.Node.t() | nil
  defp find_child(content, tag) when is_list(content) do
    Enum.find(content, fn
      %Binary.Node{tag: ^tag} -> true
      _ -> false
    end)
  end

  @spec normalize_jid(term()) :: String.t()
  defp normalize_jid(jid) when is_binary(jid), do: JIDUtils.normalize_with_device(jid)
  defp normalize_jid(%ExWapp.JID{} = jid), do: JIDUtils.normalize_with_device(jid)
  defp normalize_jid(_), do: ""

  @spec strip_device(term()) :: String.t()
  defp strip_device(jid) when is_binary(jid), do: JIDUtils.strip_device(jid)
  defp strip_device(%ExWapp.JID{} = jid), do: JIDUtils.strip_device(jid)
  defp strip_device(_), do: ""
end
