defmodule ExWapp.Session.JIDUtils do
  @moduledoc """
  Pure JID helpers used by session send/decrypt flows.

  Keeping these helpers isolated makes the session orchestration code easier
  to reason about and test.
  """

  def normalize_for_signal(jid) when is_binary(jid) do
    jid
    |> normalize_with_device()
    |> strip_device()
  end

  def normalize_for_signal(_), do: ""

  def normalize_with_device(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
  end

  def normalize_with_device(%ExWapp.JID{} = jid),
    do: ExWapp.JID.to_string(jid) |> normalize_with_device()

  def normalize_with_device(_), do: ""

  def strip_device(jid) when is_binary(jid) do
    String.replace(jid, ~r/:(\d+)@/, "@")
  end

  def strip_device(%ExWapp.JID{} = jid), do: jid |> ExWapp.JID.to_string() |> strip_device()
  def strip_device(_), do: ""

  def has_explicit_device?(jid) when is_binary(jid) do
    case String.split(jid, "@", parts: 2) do
      [user, _server] -> String.contains?(user, ":")
      _ -> false
    end
  end

  def has_explicit_device?(_), do: false

  def identity(jid) do
    jid =
      jid
      |> normalize_with_device()
      |> strip_device()

    case String.split(jid, "@", parts: 2) do
      [user, server] when user != "" and server != "" -> {user, server}
      _ -> {"", ""}
    end
  end

  def user_part(jid) when is_binary(jid) do
    jid
    |> normalize_with_device()
    |> strip_device()
    |> String.split("@", parts: 2)
    |> case do
      [user, _server] when user != "" -> user
      _ -> ""
    end
  end

  def user_part(_), do: ""

  def device_id(jid) when is_binary(jid) do
    case Regex.run(~r/^[^@]+:(\d+)@/, jid) do
      [_, value] ->
        case Integer.parse(value) do
          {device_id, ""} -> device_id
          _ -> nil
        end

      _ ->
        nil
    end
  end

  def device_id(%ExWapp.JID{device: device}) when is_integer(device), do: device
  def device_id(_), do: nil

  def current_device_target?(jid, own_device_id)
      when is_integer(own_device_id) and own_device_id >= 0 do
    case device_id(jid) do
      nil -> own_device_id == 0
      target_device_id -> target_device_id == own_device_id
    end
  end

  def current_device_target?(_jid, _own_device_id), do: false

  def lid_jid?(jid) when is_binary(jid) do
    String.ends_with?(jid, "@lid") or String.ends_with?(jid, "@hosted.lid")
  end

  def lid_jid?(_), do: false

  def resolve_signal_encryption_jid(target_jid, lid_mapping) do
    target_jid = normalize_with_device(target_jid)
    base_target_jid = strip_device(target_jid)

    cond do
      target_jid == "" ->
        ""

      lid_jid?(base_target_jid) ->
        target_jid

      true ->
        mapped_lid =
          Map.get(lid_mapping || %{}, {:pn_to_lid, base_target_jid})
          |> normalize_with_device()

        if mapped_lid == "" do
          target_jid
        else
          maybe_apply_device_to_mapped_jid(target_jid, mapped_lid)
        end
    end
  end

  def normalize_target_list(targets) when is_list(targets) do
    targets
    |> Enum.map(&normalize_with_device/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  def normalize_target_list(_), do: []

  def build_dm_target_specs(recipient_targets, own_targets) do
    specs =
      Enum.map(recipient_targets, &%{jid: &1, payload_kind: :recipient}) ++
        Enum.map(own_targets, &%{jid: &1, payload_kind: :own})

    Enum.reduce(specs, [], fn %{jid: jid, payload_kind: payload_kind} = spec, acc ->
      case Enum.find_index(acc, fn existing -> existing.jid == jid end) do
        nil ->
          acc ++ [spec]

        idx when payload_kind == :own ->
          existing = Enum.at(acc, idx)

          if existing.payload_kind == :own,
            do: acc,
            else: List.replace_at(acc, idx, %{existing | payload_kind: :own})

        _ ->
          acc
      end
    end)
  end

  defp maybe_apply_device_to_mapped_jid(source_jid, mapped_jid) do
    case {device_id(source_jid), String.split(mapped_jid, "@", parts: 2)} do
      {device_id, [user, server]} when is_integer(device_id) and device_id > 0 ->
        base_user = Regex.replace(~r/:\d+$/, user, "")
        "#{base_user}:#{device_id}@#{server}"

      _ ->
        mapped_jid
    end
  end
end
