defmodule ExWapp.Session.Outbound.Fanout do
  @moduledoc """
  Resolves direct-message fanout targets.

  This module owns the pure decision layer for recipient devices, linked
  devices, self-chat payload selection, and soft cached targets. Store reads,
  cache eviction, logging, encryption, and transport remain at the worker
  boundary.
  """

  alias ExWapp.Session.{JIDUtils, Targets}
  alias ExWapp.Signal.SessionStore

  @type payload_kind :: :recipient | :own
  @type target_spec :: %{jid: String.t(), payload_kind: payload_kind()}

  @type context :: %{
          signal_sessions: SessionStore.t() | nil,
          jid: String.t(),
          prekey_bundles: term(),
          target_hints: map(),
          own_base_jid: String.t(),
          own_lid_jid: String.t(),
          own_device_id: integer(),
          lid_mapping: map(),
          self_chat_mode: term()
        }

  @type resolution :: %{
          target_specs: [target_spec()],
          recipient_targets: [String.t()],
          own_targets: [String.t()],
          all_usync_devices: term(),
          cached_eviction_batches: [[String.t()]],
          self_chat?: boolean()
        }

  @doc """
  Resolves all encrypted target specifications from a prepared session context.

  Cached-only targets are included only when a prekey bundle proves them
  reachable. Unreachable cached targets are returned as eviction batches so
  the worker can apply the storage effect after this pure decision.
  """
  @spec resolve(context()) :: resolution()
  def resolve(%{
        signal_sessions: signal_sessions,
        jid: jid,
        prekey_bundles: prekey_bundles,
        target_hints: hints,
        own_base_jid: own_base_jid,
        own_lid_jid: own_lid_jid,
        own_device_id: own_device_id,
        lid_mapping: lid_mapping,
        self_chat_mode: self_chat_mode
      })
      when is_map(hints) and is_map(lid_mapping) do
    prekey_bundles = if is_map(prekey_bundles), do: prekey_bundles, else: %{}

    {recipient_targets_hint, recipient_evictions} =
      resolve_soft_targets(
        signal_sessions,
        prekey_bundles,
        Map.get(hints, :recipient_devices, []),
        Map.get(hints, :recipient_cached_devices, []),
        lid_mapping
      )

    recipient_prekey_bundles =
      Targets.filter_prekey_bundles_for_identity(prekey_bundles, jid)

    recipient_targets =
      Targets.resolve_encryption_targets(
        signal_sessions,
        jid,
        recipient_prekey_bundles,
        recipient_targets_hint
      )

    own_sender_jid = Map.get(hints, :own_identity_jid, own_base_jid)

    {own_targets_hint, own_evictions} =
      resolve_soft_targets(
        signal_sessions,
        prekey_bundles,
        Map.get(hints, :own_devices, []),
        Map.get(hints, :own_cached_devices, []),
        lid_mapping
      )

    own_targets =
      own_targets_hint
      |> JIDUtils.normalize_target_list()
      |> Enum.reject(&JIDUtils.current_device_target?(&1, own_device_id))

    self_chat? =
      self_chat_destination?(jid, own_sender_jid, own_base_jid, own_lid_jid)

    recipient_targets =
      maybe_drop_current_self_chat_target(recipient_targets, self_chat?, own_device_id)

    target_specs =
      build_target_specs(
        recipient_targets,
        own_targets,
        jid,
        self_chat?,
        self_chat_mode
      )

    %{
      target_specs: target_specs,
      recipient_targets: recipient_targets,
      own_targets: own_targets,
      all_usync_devices: Map.get(hints, :all_usync_devices, []),
      cached_eviction_batches: Enum.reject([recipient_evictions, own_evictions], &(&1 == [])),
      self_chat?: self_chat?
    }
  end

  @doc """
  Returns whether the destination belongs to the local account identity.

  Both phone-number and LID identities are considered.
  """
  @spec self_chat_destination?(term(), term(), term(), term()) :: boolean()
  def self_chat_destination?(jid, own_sender_jid, own_base_jid, own_lid_jid) do
    own_user_parts =
      [own_base_jid, own_sender_jid, own_lid_jid]
      |> Enum.map(&JIDUtils.user_part/1)
      |> Enum.reject(&(&1 == ""))
      |> MapSet.new()

    destination_user = JIDUtils.user_part(jid)

    destination_user != "" and MapSet.member?(own_user_parts, destination_user)
  end

  @doc """
  Resolves live and cached target candidates without applying cache effects.

  The second tuple element contains cached targets that the caller should
  evict. Returning that decision keeps persistence outside this module.
  """
  @spec resolve_soft_targets(
          SessionStore.t() | nil,
          term(),
          term(),
          term(),
          term()
        ) :: {[String.t()], [String.t()]}
  def resolve_soft_targets(
        signal_sessions,
        prekey_bundles,
        live_targets,
        cached_targets,
        lid_mapping
      ) do
    prekey_bundles = if is_map(prekey_bundles), do: prekey_bundles, else: %{}
    lid_mapping = if is_map(lid_mapping), do: lid_mapping, else: %{}

    if SessionStore.store?(signal_sessions) do
      live_targets = JIDUtils.normalize_target_list(live_targets)
      cached_targets = JIDUtils.normalize_target_list(cached_targets)

      {reachable_cached_targets, unreachable_cached_targets} =
        cached_targets
        |> Enum.reject(&(&1 in live_targets))
        |> split_reachable_cached_targets(prekey_bundles, lid_mapping)

      {
        JIDUtils.normalize_target_list(live_targets ++ reachable_cached_targets),
        unreachable_cached_targets
      }
    else
      {JIDUtils.normalize_target_list(live_targets), []}
    end
  end

  @spec split_reachable_cached_targets([String.t()], map(), map()) ::
          {[String.t()], [String.t()]}
  defp split_reachable_cached_targets(targets, prekey_bundles, lid_mapping) do
    Enum.split_with(targets, fn target_jid ->
      signal_jid = JIDUtils.resolve_signal_encryption_jid(target_jid, lid_mapping)

      Map.has_key?(prekey_bundles, target_jid) or
        Map.has_key?(prekey_bundles, signal_jid)
    end)
  end

  @spec maybe_drop_current_self_chat_target([String.t()], boolean(), term()) ::
          [String.t()]
  defp maybe_drop_current_self_chat_target(recipient_targets, true, own_device_id) do
    recipient_targets
    |> JIDUtils.normalize_target_list()
    |> Enum.reject(&JIDUtils.current_device_target?(&1, own_device_id))
  end

  defp maybe_drop_current_self_chat_target(recipient_targets, false, _own_device_id),
    do: recipient_targets

  @spec build_target_specs([String.t()], [String.t()], String.t(), boolean(), term()) ::
          [target_spec()]
  defp build_target_specs(
         recipient_targets,
         own_targets,
         jid,
         true,
         :recipient_primary
       ) do
    JIDUtils.build_self_chat_fallback_target_specs(recipient_targets, own_targets, jid)
  end

  defp build_target_specs(recipient_targets, own_targets, jid, true, _self_chat_mode) do
    JIDUtils.build_self_chat_target_specs(recipient_targets, own_targets, jid)
  end

  defp build_target_specs(recipient_targets, own_targets, _jid, false, _self_chat_mode) do
    JIDUtils.build_dm_target_specs(recipient_targets, own_targets)
  end
end
