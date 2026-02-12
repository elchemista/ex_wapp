defmodule ExWapp.Session.Targets do
  @moduledoc """
  Target resolution helpers for direct-message fanout.
  """

  alias ExWapp.Session.JIDUtils

  @spec list_session_targets_for_jid(map() | nil, String.t()) :: [String.t()]
  def list_session_targets_for_jid(signal_sessions, jid) do
    target_identity = JIDUtils.identity(jid)
    sessions = Map.get(signal_sessions || %{}, :sessions, %{})

    sessions
    |> Map.keys()
    |> Enum.filter(fn candidate -> JIDUtils.identity(candidate) == target_identity end)
  end

  @spec drop_base_alias_targets(term()) :: [String.t()]
  def drop_base_alias_targets(targets) when is_list(targets) do
    if Enum.any?(targets, &JIDUtils.has_explicit_device?/1) do
      Enum.filter(targets, &JIDUtils.has_explicit_device?/1)
    else
      targets
    end
  end

  def drop_base_alias_targets(_), do: []

  @spec resolve_encryption_targets(map() | nil, String.t(), map(), list() | nil) ::
          [String.t()]
  def resolve_encryption_targets(signal_sessions, jid, prekey_bundles, hinted_targets) do
    targets =
      cond do
        is_list(hinted_targets) and hinted_targets != [] ->
          hinted_targets

        is_map(prekey_bundles) and map_size(prekey_bundles) > 0 ->
          Map.keys(prekey_bundles)

        true ->
          list_session_targets_for_jid(signal_sessions, jid)
      end

    targets =
      if targets == [] do
        [jid]
      else
        targets
      end

    normalized_targets = JIDUtils.normalize_target_list(targets)

    if is_list(hinted_targets) and hinted_targets != [] do
      normalized_targets
    else
      drop_base_alias_targets(normalized_targets)
    end
  end

  @spec filter_prekey_bundles_for_identity(map(), String.t()) :: map()
  def filter_prekey_bundles_for_identity(prekey_bundles, jid)
      when is_map(prekey_bundles) and map_size(prekey_bundles) > 0 do
    identity = JIDUtils.identity(jid)

    prekey_bundles
    |> Enum.filter(fn {candidate, _bundle} -> JIDUtils.identity(candidate) == identity end)
    |> Map.new()
  end

  def filter_prekey_bundles_for_identity(_prekey_bundles, _jid), do: %{}

  @spec resolve_own_device_targets(map() | nil, String.t(), integer(), list() | nil) ::
          [String.t()]
  def resolve_own_device_targets(signal_sessions, own_base_jid, own_device_id, hinted_targets) do
    if own_base_jid == "" do
      []
    else
      targets =
        if is_list(hinted_targets) and hinted_targets != [] do
          hinted_targets
        else
          list_session_targets_for_jid(signal_sessions, own_base_jid)
        end

      targets
      |> JIDUtils.normalize_target_list()
      |> Enum.uniq()
      |> Enum.reject(&JIDUtils.current_device_target?(&1, own_device_id))
    end
  end
end
