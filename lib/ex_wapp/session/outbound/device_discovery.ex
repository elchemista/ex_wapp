defmodule ExWapp.Session.Outbound.DeviceDiscovery do
  @moduledoc """
  Pure device-discovery decisions for outbound messages.

  The worker remains responsible for USync I/O, cache reads, and logging. This
  module builds query identities and turns those inputs into normalized
  recipient and linked-device target sets.
  """

  alias ExWapp.Session.JIDUtils

  @type resolution_context :: %{
          device_map: map(),
          recipient_base_jid: String.t(),
          recipient_cached_devices: [String.t()],
          own_sender_jid: String.t(),
          own_base_jid: String.t(),
          own_lid_jid: String.t(),
          own_cached_devices: [String.t()],
          own_device_id: integer(),
          lid_mapping: map()
        }

  @type resolution :: %{
          recipient_devices: [String.t()],
          recipient_cached_devices: [String.t()],
          own_devices: [String.t()],
          own_cached_devices: [String.t()],
          all_usync_devices: [String.t()],
          all_device_jids: [String.t()]
        }

  @doc """
  Builds the USync query set for a recipient and all local identity families.
  """
  @spec query_jids(term(), term(), term(), term(), map()) :: [String.t()]
  def query_jids(
        recipient_base_jid,
        own_sender_jid,
        own_base_jid,
        own_lid_jid,
        lid_mapping
      )
      when is_map(lid_mapping) do
    own_query_bases =
      (related_query_bases(own_sender_jid, lid_mapping) ++
         related_query_bases(own_base_jid, lid_mapping) ++
         related_query_bases(own_lid_jid, lid_mapping))
      |> JIDUtils.normalize_target_list()

    recipient_query_bases = related_query_bases(recipient_base_jid, lid_mapping)

    if own_query_bases != [] and recipient_base_jid not in own_query_bases do
      JIDUtils.normalize_target_list(recipient_query_bases ++ own_query_bases)
    else
      JIDUtils.normalize_target_list(recipient_query_bases)
    end
  end

  @doc """
  Selects the preferred local identity for cache and fanout resolution.
  """
  @spec own_preferred_jid(term(), term()) :: String.t()
  def own_preferred_jid(own_base_jid, own_sender_jid) do
    own_sender_jid = JIDUtils.normalize_with_device(own_sender_jid)
    own_base_jid = JIDUtils.normalize_with_device(own_base_jid)

    cond do
      own_sender_jid != "" -> own_sender_jid
      own_base_jid != "" -> own_base_jid
      true -> ""
    end
  end

  @doc """
  Resolves normalized recipient, linked-device, and aggregate device sets.
  """
  @spec resolve(resolution_context()) :: resolution()
  def resolve(%{
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
      when is_map(device_map) and is_list(recipient_cached_devices) and
             is_list(own_cached_devices) and is_map(lid_mapping) do
    recipient_devices =
      [
        recipient_base_jid
        | resolve_identity_devices(device_map, recipient_base_jid, lid_mapping)
      ]
      |> JIDUtils.normalize_target_list()

    recipient_cached_devices =
      recipient_cached_devices
      |> Enum.map(&JIDUtils.map_to_preferred_family(&1, recipient_base_jid, lid_mapping))
      |> JIDUtils.normalize_target_list()
      |> Enum.reject(&(&1 in recipient_devices))

    preferred_own_jid = own_preferred_jid(own_base_jid, own_sender_jid)

    own_devices_all =
      resolve_own_usync_devices(
        device_map,
        [own_sender_jid, preferred_own_jid, own_lid_jid],
        preferred_own_jid,
        lid_mapping
      )
      |> JIDUtils.normalize_target_list()

    own_cached_devices =
      own_cached_devices
      |> Enum.map(&JIDUtils.map_to_preferred_family(&1, preferred_own_jid, lid_mapping))
      |> JIDUtils.normalize_target_list()
      |> Enum.reject(fn device_jid ->
        device_jid in own_devices_all or
          JIDUtils.current_device_target?(device_jid, own_device_id)
      end)

    own_devices =
      Enum.reject(own_devices_all, &JIDUtils.current_device_target?(&1, own_device_id))

    all_usync_devices =
      JIDUtils.normalize_target_list(recipient_devices ++ own_devices_all)

    all_device_jids =
      JIDUtils.normalize_target_list(
        recipient_devices ++ recipient_cached_devices ++ own_devices ++ own_cached_devices
      )
      |> Enum.reject(&JIDUtils.current_device_target?(&1, own_device_id))

    %{
      recipient_devices: recipient_devices,
      recipient_cached_devices: recipient_cached_devices,
      own_devices: own_devices,
      own_cached_devices: own_cached_devices,
      all_usync_devices: all_usync_devices,
      all_device_jids: all_device_jids
    }
  end

  @spec related_query_bases(term(), map()) :: [String.t()]
  defp related_query_bases(base_jid, lid_mapping) do
    JIDUtils.related_bases(base_jid, lid_mapping)
  end

  @doc """
  Resolves USync devices for one identity, preferring its current JID family.
  """
  @spec resolve_identity_devices(map(), term(), map()) :: [String.t()]
  def resolve_identity_devices(device_map, base_jid, lid_mapping) do
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

  @spec resolve_own_usync_devices(map(), [term()], term(), map()) :: [String.t()]
  defp resolve_own_usync_devices(device_map, identity_jids, preferred_jid, lid_mapping) do
    aliases =
      identity_jids
      |> Enum.flat_map(&related_query_bases(&1, lid_mapping))
      |> JIDUtils.normalize_target_list()

    aliases
    |> Enum.flat_map(&Map.get(device_map, &1, []))
    |> Enum.map(&map_own_device_to_preferred_family(&1, preferred_jid, lid_mapping))
    |> JIDUtils.normalize_target_list()
  end

  @spec map_own_device_to_preferred_family(term(), term(), map()) :: String.t()
  defp map_own_device_to_preferred_family(target_jid, preferred_jid, lid_mapping) do
    target_jid = JIDUtils.normalize_with_device(target_jid)

    preferred_jid =
      preferred_jid
      |> JIDUtils.normalize_with_device()
      |> JIDUtils.strip_device()

    mapped_jid = JIDUtils.map_to_preferred_family(target_jid, preferred_jid, lid_mapping)

    if synthesize_preferred_own_device?(target_jid, mapped_jid, preferred_jid) do
      apply_device_to_base(target_jid, preferred_jid)
    else
      mapped_jid
    end
  end

  @spec synthesize_preferred_own_device?(term(), term(), term()) :: boolean()
  defp synthesize_preferred_own_device?(target_jid, mapped_jid, preferred_jid) do
    target_base = JIDUtils.strip_device(target_jid)
    mapped_base = JIDUtils.strip_device(mapped_jid)

    preferred_jid != "" and
      not JIDUtils.lid_jid?(preferred_jid) and
      JIDUtils.lid_jid?(target_base) and
      mapped_base == target_base
  end

  @spec apply_device_to_base(term(), term()) :: String.t()
  defp apply_device_to_base(source_jid, base_jid) do
    base_jid =
      base_jid
      |> JIDUtils.normalize_with_device()
      |> JIDUtils.strip_device()

    case {JIDUtils.device_id(source_jid), String.split(base_jid, "@", parts: 2)} do
      {device_id, [user, server]} when is_integer(device_id) and device_id > 0 ->
        "#{user}:#{device_id}@#{server}"

      {_device_id, [_user, _server]} ->
        base_jid

      _ ->
        JIDUtils.normalize_with_device(source_jid)
    end
  end
end
