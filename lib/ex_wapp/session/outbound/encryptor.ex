defmodule ExWapp.Session.Outbound.Encryptor do
  @moduledoc """
  Encrypts one outbound payload for all resolved target devices.

  This module owns Signal JID aliases, target accumulation, prekey wire
  diagnostics, fanout coverage checks, and retry-session invalidation. It does
  not build message payloads, send transport nodes, or persist chat state.
  """

  require Logger

  alias ExWapp.{Binary, Store}
  alias ExWapp.Session.{Account, JIDUtils, MessageNode}
  alias ExWapp.Session.Outbound.Direct
  alias ExWapp.Signal.{Encryption, SessionStore, WireFormat}

  @type target_spec :: %{
          required(:jid) => String.t(),
          required(:payload_kind) => atom()
        }

  @type encrypted_payloads ::
          Direct.payloads() | %{required(:recipient) => binary()}

  @type prekey_bundle_map :: %{optional(String.t()) => map()}

  @typep encryption_acc :: %{
           required(:nodes) => [Binary.Node.t()],
           required(:sessions) => SessionStore.t(),
           required(:include_identity) => boolean(),
           required(:errors) => [{String.t(), term()}]
         }

  @type result ::
          {:ok, [Binary.Node.t()], SessionStore.t(), boolean()}
          | {:error, {:no_encrypted_targets, [{String.t(), term()}]}}

  @doc """
  Encrypts the selected payload independently for every target device.
  """
  @spec encrypt_for_targets(
          Store.t(),
          SessionStore.t(),
          [target_spec()],
          encrypted_payloads(),
          prekey_bundle_map()
        ) :: result()
  def encrypt_for_targets(store, signal_sessions, target_specs, payloads, prekey_bundles) do
    lid_mapping = Account.load_lid_mapping(store)
    initial = %{nodes: [], sessions: signal_sessions, include_identity: false, errors: []}

    result =
      Enum.reduce(target_specs, initial, fn spec, acc ->
        encrypt_single_target(store, acc, spec, payloads, prekey_bundles, lid_mapping)
      end)

    if result.nodes == [] do
      {:error, {:no_encrypted_targets, Enum.reverse(result.errors)}}
    else
      {:ok, Enum.reverse(result.nodes), result.sessions, result.include_identity}
    end
  end

  @doc """
  Returns target specs that do not have a corresponding encrypted participant node.
  """
  @spec missing_expected_targets([target_spec()], [Binary.Node.t()]) :: [target_spec()]
  def missing_expected_targets(target_specs, participant_nodes) do
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

  @doc """
  Clears cached Signal sessions for retry targets and their PN/LID aliases.
  """
  @spec clear_sessions_for_targets(
          SessionStore.t(),
          list(target_spec() | String.t()),
          Store.t()
        ) :: SessionStore.t()
  def clear_sessions_for_targets(signal_sessions, targets, store) do
    if SessionStore.store?(signal_sessions) do
      lid_mapping = Account.load_lid_mapping(store)

      targets
      |> Enum.map(&target_jid/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.reduce(signal_sessions, &SessionStore.delete_sessions_for_user(&2, &1, lid_mapping))
    else
      signal_sessions
    end
  end

  @spec encrypt_single_target(
          Store.t(),
          encryption_acc(),
          target_spec(),
          encrypted_payloads(),
          prekey_bundle_map(),
          map()
        ) :: encryption_acc()
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

  @spec do_encrypt_and_accumulate(
          Store.t(),
          encryption_acc(),
          SessionStore.t(),
          String.t(),
          String.t(),
          binary(),
          map()
        ) :: encryption_acc()
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

  @spec encrypt_for_target_with_fallback(
          Store.t(),
          SessionStore.t(),
          String.t(),
          String.t(),
          binary(),
          map()
        ) ::
          {:ok, binary(), :prekey | :whisper, SessionStore.t()} | {:error, term()}
  defp encrypt_for_target_with_fallback(store, sessions, target_jid, signal_jid, payload, bundle) do
    case Encryption.encrypt_for_recipient_sync(store, sessions, signal_jid, payload, bundle) do
      {:error, :missing_bundle} when signal_jid != target_jid ->
        Logger.debug("[SEND] No session for signal_jid=#{signal_jid}, retrying with wire jid")
        Encryption.encrypt_for_recipient_sync(store, sessions, target_jid, payload, bundle)

      other ->
        other
    end
  end

  @spec accumulate_encrypted_target(
          encryption_acc(),
          String.t(),
          String.t(),
          binary(),
          :prekey | :whisper,
          SessionStore.t()
        ) :: encryption_acc()
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

  @spec maybe_log_prekey_wire_fields(String.t(), :prekey | :whisper, binary()) :: :ok
  defp maybe_log_prekey_wire_fields(_target_jid, enc_type, _ciphertext) when enc_type != :prekey,
    do: :ok

  defp maybe_log_prekey_wire_fields(target_jid, :prekey, ciphertext) do
    case WireFormat.parse_prekey_signal_message(ciphertext) do
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

  @spec ensure_signal_session_alias(SessionStore.t(), String.t(), String.t()) ::
          SessionStore.t()
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

  @spec target_jid(target_spec() | String.t() | term()) :: String.t()
  defp target_jid(%{jid: jid}), do: jid
  defp target_jid(jid) when is_binary(jid), do: jid
  defp target_jid(_target), do: ""

  @spec normalize_jid_with_device(term()) :: String.t()
  defp normalize_jid_with_device(jid), do: JIDUtils.normalize_with_device(jid)
end
