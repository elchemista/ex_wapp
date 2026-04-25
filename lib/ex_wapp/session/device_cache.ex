defmodule ExWapp.Session.DeviceCache do
  @moduledoc """
  Persists recently observed multi-device fanout targets.

  Live USync remains the primary source of truth. The cache is used only as a
  fallback when a transient USync response is incomplete. Cached-only targets
  should be treated as soft candidates by callers.
  """

  alias ExWapp.{Config, Store}
  alias ExWapp.Session.Account
  alias ExWapp.Session.JIDUtils

  @default_max_age_ms :timer.hours(24 * 14)
  @default_touch_throttle_ms :timer.minutes(1)

  @spec persist_usync_map(term(), map()) :: :ok
  def persist_usync_map(nil, _device_map), do: :ok
  def persist_usync_map(_store, device_map) when not is_map(device_map), do: :ok

  def persist_usync_map(store, device_map) do
    now_ms = System.system_time(:millisecond)
    lid_mapping = Account.load_lid_mapping(store)
    cache = Store.load_device_cache(store)
    touch_throttle_ms = @default_touch_throttle_ms

    updated_cache =
      Enum.reduce(device_map, cache, fn {base_jid, devices}, acc ->
        put_devices(acc, base_jid, devices, lid_mapping, now_ms, touch_throttle_ms)
      end)

    persist_if_changed(store, cache, updated_cache)
  rescue
    _ -> :ok
  end

  @spec persist_observed_device(term(), term()) :: :ok
  def persist_observed_device(nil, _jid), do: :ok

  def persist_observed_device(store, jid) do
    normalized_jid = JIDUtils.normalize_with_device(jid)

    if normalized_jid == "" do
      :ok
    else
      now_ms = System.system_time(:millisecond)
      lid_mapping = Account.load_lid_mapping(store)
      cache = Store.load_device_cache(store)
      base_jid = JIDUtils.strip_device(normalized_jid)

      updated_cache =
        put_devices(
          cache,
          base_jid,
          [normalized_jid],
          lid_mapping,
          now_ms,
          @default_touch_throttle_ms
        )

      persist_if_changed(store, cache, updated_cache)
    end
  rescue
    _ -> :ok
  end

  @spec resolve_recent_devices(term(), term(), map()) :: [String.t()]
  def resolve_recent_devices(nil, _base_jid, _runtime_cfg), do: []

  def resolve_recent_devices(store, base_jid, runtime_cfg) do
    lid_mapping = Account.load_lid_mapping(store)
    cache = Store.load_device_cache(store)
    now_ms = System.system_time(:millisecond)

    max_age_ms =
      Config.get(runtime_cfg || %{}, [:signal, :device_cache_max_age_ms], @default_max_age_ms)

    aliases = JIDUtils.related_bases(base_jid, lid_mapping)

    aliases
    |> Enum.flat_map(fn alias_base ->
      cache
      |> Map.get(alias_base, %{})
      |> Map.get(:devices, %{})
      |> Enum.flat_map(fn {device_jid, seen_at_ms} ->
        if is_integer(seen_at_ms) and now_ms - seen_at_ms < max_age_ms do
          [JIDUtils.map_to_preferred_family(device_jid, base_jid, lid_mapping)]
        else
          []
        end
      end)
    end)
    |> JIDUtils.normalize_target_list()
  rescue
    _ -> []
  end

  @spec evict_devices(term(), [term()]) :: :ok
  def evict_devices(nil, _target_jids), do: :ok
  def evict_devices(_store, target_jids) when not is_list(target_jids), do: :ok

  def evict_devices(store, target_jids) do
    normalized_targets =
      target_jids
      |> Enum.map(&JIDUtils.normalize_with_device/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    if normalized_targets == [] do
      :ok
    else
      lid_mapping = Account.load_lid_mapping(store)
      cache = Store.load_device_cache(store)

      updated_cache =
        Enum.reduce(normalized_targets, cache, fn target_jid, acc ->
          evict_target(acc, target_jid, lid_mapping)
        end)

      persist_if_changed(store, cache, updated_cache)
    end
  rescue
    _ -> :ok
  end

  defp put_devices(cache, base_jid, devices, lid_mapping, now_ms, touch_throttle_ms) do
    base_jid = JIDUtils.normalize_with_device(base_jid) |> JIDUtils.strip_device()

    devices =
      devices
      |> Enum.map(&JIDUtils.normalize_with_device/1)
      |> Enum.reject(&(&1 == ""))

    related_bases = JIDUtils.related_bases(base_jid, lid_mapping)

    Enum.reduce(related_bases, cache, fn related_base, acc ->
      existing_entry = Map.get(acc, related_base, %{})
      existing_devices = Map.get(existing_entry, :devices, %{})

      updated_devices =
        Enum.reduce(devices, existing_devices, fn device_jid, device_acc ->
          preferred_jid = JIDUtils.map_to_preferred_family(device_jid, related_base, lid_mapping)
          maybe_touch_device(device_acc, preferred_jid, now_ms, touch_throttle_ms)
        end)

      if updated_devices == existing_devices do
        acc
      else
        Map.put(acc, related_base, %{
          existing_entry
          | devices: updated_devices,
            updated_at_ms: now_ms
        })
      end
    end)
  end

  defp maybe_touch_device(device_acc, device_jid, now_ms, touch_throttle_ms)
       when is_binary(device_jid) and device_jid != "" do
    case Map.get(device_acc, device_jid) do
      seen_at_ms when is_integer(seen_at_ms) and now_ms - seen_at_ms < touch_throttle_ms ->
        device_acc

      _ ->
        Map.put(device_acc, device_jid, now_ms)
    end
  end

  defp maybe_touch_device(device_acc, _device_jid, _now_ms, _touch_throttle_ms), do: device_acc

  defp persist_if_changed(_store, cache, cache), do: :ok

  defp persist_if_changed(store, _old_cache, updated_cache),
    do: Store.persist_device_cache(store, updated_cache)

  defp evict_target(cache, target_jid, lid_mapping) do
    base_jid = JIDUtils.strip_device(target_jid)
    related_bases = JIDUtils.related_bases(base_jid, lid_mapping)

    Enum.reduce(related_bases, cache, fn related_base, acc ->
      mapped_target = JIDUtils.map_to_preferred_family(target_jid, related_base, lid_mapping)
      entry = Map.get(acc, related_base, %{})
      devices = Map.get(entry, :devices, %{}) |> Map.delete(mapped_target)

      cond do
        devices == %{} and entry == %{} ->
          acc

        devices == %{} ->
          Map.delete(acc, related_base)

        true ->
          Map.put(acc, related_base, %{entry | devices: devices})
      end
    end)
  end
end
