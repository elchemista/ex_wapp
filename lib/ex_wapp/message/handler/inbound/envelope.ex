defmodule ExWapp.Message.Handler.Inbound.Envelope do
  @moduledoc """
  Inbound envelope normalization and sender/payload candidate resolution.

  This boundary owns PN/LID envelope mappings, observed-device persistence,
  local-recipient matching, and deterministic decrypt candidate construction.
  Signal decryption and message-content decoding remain outside this module.
  """

  require Logger

  alias ExWapp.{MapPath, Store}
  alias ExWapp.Message.Handler.Common
  alias ExWapp.Session.{Account, DeviceCache, JIDUtils}
  alias ExWapp.Signal.SessionStore

  @type payload_candidate :: %{
          optional(:enc_type) => term(),
          optional(:enc_version) => term(),
          optional(:enc_count) => term(),
          optional(:ciphertext) => term(),
          optional(:to_jid) => term()
        }

  @type decrypt_context :: %{
          sender_candidates: [String.t()],
          payload_candidates: [payload_candidate()],
          decryptable_payloads: [payload_candidate()]
        }

  @doc """
  Persists PN/LID pairs observed on an inbound message envelope.
  """
  @spec persist_lid_mappings(map(), map(), term(), term()) :: map()
  def persist_lid_mappings(state, attrs, from, participant)
      when is_map(state) and is_map(attrs) do
    case {Map.get(state, :store), normalize_envelope_lid_mappings(attrs, from, participant)} do
      {nil, _} ->
        state

      {_store, []} ->
        state

      {store, normalized_mappings} ->
        persist_normalized_lid_mappings(store, normalized_mappings)
        state
    end
  rescue
    error ->
      Logger.warning("[DECRYPT] Failed storing envelope LID mappings: #{inspect(error)}")
      state
  end

  def persist_lid_mappings(state, _attrs, _from, _participant), do: state

  @doc """
  Persists device JIDs observed in the inbound envelope.
  """
  @spec persist_observed_devices(map(), map(), term(), term()) :: :ok
  def persist_observed_devices(state, attrs, from, participant)
      when is_map(state) and is_map(attrs) do
    store = Map.get(state, :store)

    [
      from,
      participant,
      Map.get(attrs, "sender_lid"),
      Map.get(attrs, "sender_pn"),
      Map.get(attrs, "participant_lid"),
      Map.get(attrs, "participant_pn")
    ]
    |> Enum.map(&Common.normalize_jid_with_device/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.each(&DeviceCache.persist_observed_device(store, &1))

    :ok
  end

  def persist_observed_devices(_state, _attrs, _from, _participant), do: :ok

  @doc """
  Builds ordered sender and encrypted-payload candidates for Signal decrypt.
  """
  @spec decrypt_context(map(), map(), term(), term(), map()) :: decrypt_context()
  def decrypt_context(message_data, state, from, participant, attrs)
      when is_map(message_data) and is_map(state) and is_map(attrs) do
    sender_candidates = sender_jids(from, participant, attrs, state)
    payload_candidates = encrypted_payload_candidates(message_data)

    decryptable_payloads =
      payload_candidates
      |> prioritize_payload_candidates(state, attrs)
      |> Enum.filter(&is_binary(&1.ciphertext))

    %{
      sender_candidates: sender_candidates,
      payload_candidates: payload_candidates,
      decryptable_payloads: decryptable_payloads
    }
  end

  @doc """
  Determines whether an inbound envelope represents a local outgoing message.
  """
  @spec from_me?(map(), term(), map(), map()) :: boolean()
  def from_me?(attrs, from, state, message_data)
      when is_map(attrs) and is_map(state) and is_map(message_data) do
    explicit_from_me?(Map.get(attrs, "from_me")) or
      Map.get(message_data, :from_me, false) == true or
      from_matches_local_identity?(from, state, attrs)
  end

  def from_me?(_attrs, _from, _state, _message_data), do: false

  @doc """
  Returns whether a server-attested envelope sender belongs to the local account.

  Group stanzas use `participant` as the actual sender; direct stanzas fall back
  to `from`. Both PN and LID identities, with or without a device suffix, are
  accepted. This predicate deliberately ignores message payload claims such as
  `from_me` because self-only protocol messages must be authorized from envelope
  metadata before their contents are applied.
  """
  @spec own_sender?(map(), term(), term(), map()) :: boolean()
  def own_sender?(attrs, from, participant, state)
      when is_map(attrs) and is_map(state) do
    normalized_participant = Common.normalize_jid_with_device(participant)

    sender =
      if normalized_participant == "" do
        Common.normalize_jid_with_device(from)
      else
        normalized_participant
      end

    sender_base = Common.strip_device_from_jid(sender)
    local_jids = local_recipient_jids(state, %{})

    sender != "" and (sender in local_jids or sender_base in local_jids)
  end

  def own_sender?(_attrs, _from, _participant, _state), do: false

  @spec persist_normalized_lid_mappings(term(), [{String.t(), String.t()}]) :: :ok
  defp persist_normalized_lid_mappings(store, normalized_mappings) do
    data = Store.load!(store)
    existing_mappings = Map.get(data, :lid_mapping, %{})

    updated_mappings =
      Enum.reduce(normalized_mappings, existing_mappings, fn {lid, pn}, acc ->
        acc
        |> Map.put({:pn_to_lid, pn}, lid)
        |> Map.put({:lid_to_pn, lid}, pn)
      end)

    if updated_mappings != existing_mappings do
      Store.persist(store, Map.put(data, :lid_mapping, updated_mappings))
    end

    :ok
  end

  @spec normalize_envelope_lid_mappings(map(), term(), term()) ::
          [{String.t(), String.t()}]
  defp normalize_envelope_lid_mappings(attrs, from, participant) do
    [
      {from, Map.get(attrs, "sender_pn")},
      {Map.get(attrs, "sender_lid"), Map.get(attrs, "sender_pn")},
      {participant, Map.get(attrs, "participant_pn")},
      {Map.get(attrs, "participant_lid"), Map.get(attrs, "participant_pn")}
    ]
    |> Enum.reduce([], fn {left, right}, acc ->
      case normalize_lid_mapping_pair(left, right) do
        nil -> acc
        mapping -> [mapping | acc]
      end
    end)
    |> Enum.uniq()
  end

  @spec normalize_lid_mapping_pair(term(), term()) :: {String.t(), String.t()} | nil
  defp normalize_lid_mapping_pair(left, right) do
    left = Common.normalize_jid(left)
    right = Common.normalize_jid(right)

    cond do
      left == "" or right == "" -> nil
      Common.lid_jid?(left) and not Common.lid_jid?(right) -> {left, right}
      Common.lid_jid?(right) and not Common.lid_jid?(left) -> {right, left}
      true -> nil
    end
  end

  @spec sender_jids(term(), term(), map(), map()) :: [String.t()]
  defp sender_jids(from, participant, attrs, state) do
    raw_candidates = [
      participant,
      from,
      Map.get(attrs, "sender_lid"),
      Map.get(attrs, "sender_pn"),
      Map.get(attrs, "participant_lid"),
      Map.get(attrs, "participant_pn")
    ]

    with_device =
      raw_candidates
      |> Enum.map(&Common.normalize_jid_with_device/1)
      |> Enum.reject(&(&1 == ""))

    cross_family_device_aliases = synthesize_cross_family_device_candidates(with_device)

    without_device =
      (with_device ++ cross_family_device_aliases)
      |> Enum.map(&Common.strip_device_from_jid/1)
      |> Enum.reject(&(&1 == ""))

    base_candidates =
      (with_device ++ cross_family_device_aliases ++ without_device)
      |> Enum.uniq()

    mapped_candidates = resolve_lid_mapping_candidates(base_candidates, state)

    stored_session_candidates =
      resolve_stored_session_candidates(base_candidates ++ mapped_candidates, state)

    (base_candidates ++ mapped_candidates ++ stored_session_candidates)
    |> Enum.uniq()
  end

  @spec resolve_stored_session_candidates([String.t()], map()) :: [String.t()]
  defp resolve_stored_session_candidates(candidates, state) do
    signal_sessions = Map.get(state, :signal_sessions)

    if SessionStore.store?(signal_sessions) do
      lid_mapping = Account.load_lid_mapping(Map.get(state, :store))

      related_bases =
        candidates
        |> Enum.flat_map(&JIDUtils.related_bases(&1, lid_mapping))
        |> Enum.reject(&(&1 == ""))
        |> MapSet.new()

      signal_sessions
      |> SessionStore.list_sessions()
      |> Enum.filter(fn session_jid ->
        JIDUtils.has_explicit_device?(session_jid) and
          MapSet.member?(related_bases, JIDUtils.strip_device(session_jid))
      end)
      |> Enum.sort_by(fn session_jid ->
        {explicit_candidate_rank(session_jid, candidates),
         -(SessionStore.session_touched_at(signal_sessions, session_jid) || 0)}
      end)
    else
      []
    end
  rescue
    _ -> []
  end

  @spec explicit_candidate_rank(String.t(), [String.t()]) :: non_neg_integer()
  defp explicit_candidate_rank(session_jid, candidates) do
    session_base = JIDUtils.strip_device(session_jid)

    Enum.find_index(candidates, fn candidate ->
      normalized_candidate = Common.normalize_jid_with_device(candidate)

      normalized_candidate == session_jid or
        Common.strip_device_from_jid(normalized_candidate) == session_base
    end) || length(candidates)
  end

  @spec synthesize_cross_family_device_candidates([String.t()]) :: [String.t()]
  defp synthesize_cross_family_device_candidates(candidates) do
    explicit_device_candidates = Enum.filter(candidates, &JIDUtils.has_explicit_device?/1)
    base_candidates = Enum.reject(candidates, &JIDUtils.has_explicit_device?/1)

    Enum.flat_map(explicit_device_candidates, fn explicit_jid ->
      synthesize_for_explicit_candidate(explicit_jid, base_candidates)
    end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  @spec synthesize_for_explicit_candidate(String.t(), [String.t()]) :: [String.t()]
  defp synthesize_for_explicit_candidate(explicit_jid, base_candidates) do
    case JIDUtils.device_id(explicit_jid) do
      nil ->
        []

      device_id ->
        base_candidates
        |> Enum.filter(&cross_family?(explicit_jid, &1))
        |> Enum.map(&apply_device_to_base_jid(&1, device_id))
    end
  end

  @spec cross_family?(String.t(), String.t()) :: boolean()
  defp cross_family?(left, right) do
    JIDUtils.lid_jid?(left) != JIDUtils.lid_jid?(right)
  end

  @spec apply_device_to_base_jid(String.t(), non_neg_integer()) :: String.t()
  defp apply_device_to_base_jid(base_jid, device_id)
       when is_binary(base_jid) and is_integer(device_id) and device_id > 0 do
    case String.split(Common.strip_device_from_jid(base_jid), "@", parts: 2) do
      [user, server] when user != "" and server != "" -> "#{user}:#{device_id}@#{server}"
      _ -> ""
    end
  end

  defp apply_device_to_base_jid(_base_jid, _device_id), do: ""

  @spec resolve_lid_mapping_candidates([String.t()], map()) :: [String.t()]
  defp resolve_lid_mapping_candidates(candidates, state) do
    case Map.get(state, :store) do
      nil -> []
      store -> do_resolve_lid_mappings(candidates, store)
    end
  rescue
    _ -> []
  end

  @spec do_resolve_lid_mappings([String.t()], term()) :: [String.t()]
  defp do_resolve_lid_mappings(candidates, store) do
    data = Store.load!(store)
    lid_mapping = Map.get(data, :lid_mapping, %{})

    if map_size(lid_mapping) == 0 do
      []
    else
      candidates
      |> Enum.flat_map(&mapped_lid_candidates(&1, lid_mapping))
      |> Enum.reject(&(&1 == ""))
    end
  end

  @spec mapped_lid_candidates(String.t(), map()) :: [String.t()]
  defp mapped_lid_candidates(jid, lid_mapping) do
    normalized = Common.strip_device_from_jid(jid)

    mapped =
      [
        Map.get(lid_mapping, {:pn_to_lid, normalized}),
        Map.get(lid_mapping, {:lid_to_pn, normalized})
      ]
      |> Enum.reject(&is_nil/1)

    mapped ++ Enum.map(mapped, &Common.strip_device_from_jid/1)
  end

  @spec encrypted_payload_candidates(map()) :: [payload_candidate()]
  defp encrypted_payload_candidates(message_data) do
    candidates = Map.get(message_data, :enc_candidates, [])

    if is_list(candidates) and candidates != [] do
      candidates
    else
      [
        %{
          enc_type: Map.get(message_data, :enc_type, "msg"),
          enc_version: Map.get(message_data, :enc_version),
          enc_count: Map.get(message_data, :enc_count),
          ciphertext: Map.get(message_data, :ciphertext),
          to_jid: nil
        }
      ]
    end
  end

  @spec prioritize_payload_candidates([payload_candidate()], map(), map()) ::
          [payload_candidate()]
  defp prioritize_payload_candidates(payload_candidates, state, attrs) do
    local_jids = local_recipient_jids(state, attrs)

    if local_jids == [] do
      payload_candidates
    else
      {matching, non_matching} =
        Enum.split_with(payload_candidates, fn payload ->
          payload_to = Map.get(payload, :to_jid)

          payload_to in local_jids or
            Common.strip_device_from_jid(payload_to) in local_jids
        end)

      if matching == [], do: payload_candidates, else: matching ++ non_matching
    end
  end

  @spec explicit_from_me?(term()) :: boolean()
  defp explicit_from_me?(value) when value in [true, 1, "1", "true"], do: true
  defp explicit_from_me?(_value), do: false

  @spec from_matches_local_identity?(term(), map(), map()) :: boolean()
  defp from_matches_local_identity?(from, state, attrs) do
    normalized_from_with_device = Common.normalize_jid_with_device(from)
    normalized_from = Common.normalize_jid(from)
    local_jids = local_recipient_jids(state, attrs)

    normalized_from_with_device != "" and
      (normalized_from_with_device in local_jids or normalized_from in local_jids)
  end

  @doc """
  Returns normalized local PN/LID recipient identities from state and envelope attributes.
  """
  @spec local_recipient_jids(map(), map()) :: [String.t()]
  def local_recipient_jids(state, attrs) do
    from_store =
      case Map.get(state, :store) do
        nil ->
          []

        store ->
          data = Store.load!(store)

          [
            MapPath.first(data, [["pairing", "device", "jid"], ["client_info", "jid"]]),
            MapPath.get(data, ["client_info", "wid"]),
            MapPath.get(data, ["client_info", "lid"])
          ]
      end

    from_attrs = [
      Map.get(attrs, "to"),
      Map.get(attrs, "recipient"),
      Map.get(attrs, "recipient_lid"),
      Map.get(attrs, "recipient_pn")
    ]

    normalized_with_device =
      (from_store ++ from_attrs)
      |> Enum.map(&Common.normalize_jid_with_device/1)
      |> Enum.reject(&(&1 == ""))

    normalized_without_device =
      normalized_with_device
      |> Enum.map(&Common.strip_device_from_jid/1)
      |> Enum.reject(&(&1 == ""))

    Enum.uniq(normalized_with_device ++ normalized_without_device)
  end
end
