defmodule ExWapp.Session.JIDUtils do
  @moduledoc """
  Pure JID helpers used by session send/decrypt flows.

  Keeping these helpers isolated makes the session orchestration code easier
  to reason about and test.
  """

  alias ExWapp.JID

  @spec normalize_for_signal(term()) :: String.t()
  def normalize_for_signal(jid) when is_binary(jid) do
    jid
    |> normalize_with_device()
    |> strip_device()
  end

  def normalize_for_signal(_), do: ""

  @spec normalize_with_device(term()) :: String.t()
  def normalize_with_device(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
  end

  def normalize_with_device(%JID{} = jid),
    do: JID.to_string(jid) |> normalize_with_device()

  def normalize_with_device(_), do: ""

  @spec strip_device(term()) :: String.t()
  def strip_device(jid) when is_binary(jid) do
    String.replace(jid, ~r/:(\d+)@/, "@")
  end

  def strip_device(%JID{} = jid), do: jid |> JID.to_string() |> strip_device()
  def strip_device(_), do: ""

  @spec has_explicit_device?(term()) :: boolean()
  def has_explicit_device?(jid) when is_binary(jid) do
    case String.split(jid, "@", parts: 2) do
      [user, _server] -> String.contains?(user, ":")
      _ -> false
    end
  end

  def has_explicit_device?(_), do: false

  @spec identity(term()) :: {String.t(), String.t()}
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

  @spec user_part(term()) :: String.t()
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

  @spec device_id(term()) :: non_neg_integer() | nil
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

  def device_id(%JID{device: device}) when is_integer(device), do: device
  def device_id(_), do: nil

  @spec current_device_target?(term(), integer()) :: boolean()
  def current_device_target?(jid, own_device_id)
      when is_integer(own_device_id) and own_device_id >= 0 do
    case device_id(jid) do
      nil -> own_device_id == 0
      target_device_id -> target_device_id == own_device_id
    end
  end

  def current_device_target?(_jid, _own_device_id), do: false

  @spec lid_jid?(term()) :: boolean()
  def lid_jid?(jid) when is_binary(jid) do
    String.ends_with?(jid, "@lid") or String.ends_with?(jid, "@hosted.lid")
  end

  def lid_jid?(_), do: false

  @spec resolve_signal_encryption_jid(term(), map() | nil) :: String.t()
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

  @spec normalize_target_list(term()) :: [String.t()]
  def normalize_target_list(targets) when is_list(targets) do
    targets
    |> Enum.map(&normalize_with_device/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  def normalize_target_list(_), do: []

  @spec build_dm_target_specs([String.t()], [String.t()]) ::
          [%{jid: String.t(), payload_kind: :recipient | :own}]
  def build_dm_target_specs(recipient_targets, own_targets) do
    specs =
      Enum.map(recipient_targets, &%{jid: &1, payload_kind: :recipient}) ++
        Enum.map(own_targets, &%{jid: &1, payload_kind: :own})

    {order, payload_kinds} =
      Enum.reduce(specs, {[], %{}}, fn %{jid: jid, payload_kind: payload_kind}, {order, kinds} ->
        {
          maybe_prepend_order(order, kinds, jid),
          Map.update(kinds, jid, payload_kind, &merge_payload_kind(&1, payload_kind))
        }
      end)

    order
    |> Enum.reverse()
    |> Enum.map(fn jid -> %{jid: jid, payload_kind: Map.fetch!(payload_kinds, jid)} end)
  end

  @doc """
  Builds target specs for self-chat fanout.

  WhatsMeow parity: for self-chat, every non-current target gets the DSM payload.
  There is no plain "recipient payload" branch in self-chat fanout.
  """
  @spec build_self_chat_target_specs([String.t()], [String.t()], String.t()) ::
          [%{jid: String.t(), payload_kind: :recipient | :own}]
  def build_self_chat_target_specs(recipient_targets, own_targets, destination_jid) do
    _destination_jid = destination_jid
    all_targets = normalize_target_list(recipient_targets ++ own_targets)

    Enum.map(all_targets, fn target ->
      %{jid: target, payload_kind: :own}
    end)
  end

  @doc """
  Fallback self-chat strategy used when a DSM-only send appears silently dropped.

  It keeps one primary target as `:recipient` payload and uses `:own` payload for
  the remaining fanout targets.
  """
  @spec build_self_chat_fallback_target_specs([String.t()], [String.t()], String.t()) ::
          [%{jid: String.t(), payload_kind: :recipient | :own}]
  def build_self_chat_fallback_target_specs(recipient_targets, own_targets, destination_jid) do
    recipient_targets = normalize_target_list(recipient_targets)
    all_targets = normalize_target_list(recipient_targets ++ own_targets)
    normalized_destination = normalize_with_device(destination_jid)

    primary_target =
      cond do
        normalized_destination != "" and normalized_destination in all_targets ->
          normalized_destination

        recipient_targets != [] ->
          hd(recipient_targets)

        all_targets != [] ->
          hd(all_targets)

        true ->
          ""
      end

    Enum.map(all_targets, fn target ->
      if target == primary_target do
        %{jid: target, payload_kind: :recipient}
      else
        %{jid: target, payload_kind: :own}
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

  defp maybe_prepend_order(order, kinds, jid) do
    if Map.has_key?(kinds, jid), do: order, else: [jid | order]
  end

  defp merge_payload_kind(:own, _new_kind), do: :own
  defp merge_payload_kind(_existing_kind, :own), do: :own
  defp merge_payload_kind(_existing_kind, _new_kind), do: :recipient
end
