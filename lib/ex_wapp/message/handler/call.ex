defmodule ExWapp.Message.Handler.Call do
  @moduledoc """
  Turns inbound `<call>` stanzas into call-log records and live call events.

  WhatsApp delivers call signalling as a `<call>` stanza with one child naming
  the phase: `offer`/`offer_notice` (ringing), `accept` (a device answered),
  `terminate` (ended, with a `reason` attribute), or `reject`. Each phase is
  merged into the persistent call log (`ExWapp.Call`) and forwarded to the
  session worker as `{:call_event, %ExWapp.Call{}}` so subscribers can react
  in real time. VoIP negotiation children (`preaccept`, `transport`,
  `relaylatency`, ...) carry no log-worthy information and are skipped.

  Outcome semantics for `terminate`:
  - a call with a known accept (or a positive `duration` attribute) ends `:connected`
  - an unanswered outgoing call ends `:cancelled`
  - any other unanswered call ends `:missed` — WhatsApp uses `reason="timeout"`
    for a ring-out, but a caller hang-up is still a missed call for the callee

  The raw terminate reason is preserved in `end_reason`. Duration comes from
  the stanza's `duration` attribute when present, otherwise from the delta
  between the observed accept and terminate timestamps.
  """

  require Logger

  alias ExWapp.Binary.Node
  alias ExWapp.Call, as: CallRecord
  alias ExWapp.Config
  alias ExWapp.Log
  alias ExWapp.Message.Handler.Common
  alias ExWapp.Message.Handler.Inbound.Envelope

  @log_children ["offer", "offer_notice", "accept", "terminate", "reject"]
  @transient_children ["preaccept", "transport", "relaylatency", "mute", "unmute", "enc_rekey"]

  @doc """
  Handles one inbound `<call>` stanza.

  Always returns `{:ok, state}`: call stanzas never produce outbound actions
  here (the transport ACK is already handled at the connection boundary).
  """
  @spec handle_call_node(Node.t(), pid() | term(), map()) :: {:ok, map()}
  def handle_call_node(%Node{tag: "call"} = node, session, state) do
    case first_child(node) do
      %Node{tag: tag} = child when tag in @log_children ->
        ingest_call_child(node, child, session, state)

      %Node{tag: tag} when tag in @transient_children ->
        :ok

      %Node{tag: tag} ->
        Logger.debug(
          "[CALL] Unhandled call child tag=#{tag} attrs=#{inspect(Log.attrs(node.attrs))}"
        )

      nil ->
        Logger.debug("[CALL] Call stanza without child attrs=#{inspect(Log.attrs(node.attrs))}")
    end

    {:ok, state}
  end

  defp ingest_call_child(node, child, session, state) do
    case call_meta(node, child, state) do
      %{id: nil} ->
        Logger.debug("[CALL] Call child without call-id tag=#{child.tag}")

      meta ->
        target = Common.chat_target(session, state)
        call = build_call(child.tag, meta, existing_call(target, meta.id))
        stored = persist_call(target, call, state)
        publish_call(session, stored)
    end
  end

  defp call_meta(%Node{attrs: outer}, %Node{attrs: child_attrs} = child, state) do
    creator = optional_jid(Map.get(child_attrs, "call-creator"))
    group_jid = optional_jid(Map.get(child_attrs, "group-jid"))

    %{
      id: optional_text(Map.get(child_attrs, "call-id") || Map.get(child_attrs, "id")),
      timestamp: parse_positive_int(Map.get(outer, "t")),
      creator_jid: creator,
      group_jid: group_jid,
      chat_jid: group_jid || optional_jid(Map.get(outer, "from")),
      is_incoming: incoming?(creator, state),
      reason: optional_text(Map.get(child_attrs, "reason")),
      media: optional_text(Map.get(child_attrs, "media")),
      group_type?: Map.get(child_attrs, "type") == "group",
      duration_attr: parse_positive_int(Map.get(child_attrs, "duration")),
      video_child?: has_child?(child, "video")
    }
  end

  defp build_call("offer", meta, _existing) do
    %{base_call(meta) | status: :ringing, start_time: meta.timestamp, is_video: meta.video_child?}
  end

  defp build_call("offer_notice", meta, _existing) do
    %{
      base_call(meta)
      | status: :ringing,
        start_time: meta.timestamp,
        is_video: media_video?(meta.media)
    }
  end

  defp build_call("accept", meta, _existing) do
    %{base_call(meta) | status: :ongoing, accepted_at: meta.timestamp}
  end

  defp build_call("reject", meta, _existing) do
    %{base_call(meta) | status: :rejected, ended_at: meta.timestamp, end_reason: meta.reason}
  end

  defp build_call("terminate", meta, existing) do
    accepted_at = existing && existing.accepted_at

    connected? =
      is_integer(accepted_at) or (is_integer(meta.duration_attr) and meta.duration_attr > 0)

    status =
      cond do
        connected? -> :connected
        resolve_incoming(meta, existing) == false -> :cancelled
        true -> :missed
      end

    %{
      base_call(meta)
      | status: status,
        ended_at: meta.timestamp,
        end_reason: meta.reason,
        duration: meta.duration_attr
    }
  end

  defp base_call(meta) do
    %CallRecord{
      id: meta.id,
      chat_jid: meta.chat_jid,
      creator_jid: meta.creator_jid,
      group_jid: meta.group_jid,
      is_incoming: meta.is_incoming,
      is_group: meta.group_type? or meta.group_jid != nil,
      source: :live
    }
  end

  defp existing_call(target, call_id) do
    case CallRecord.get(target, call_id) do
      {:ok, call} -> call
      {:error, :not_found} -> nil
    end
  end

  defp persist_call(target, call, state) do
    case CallRecord.upsert(target, call, call_log_opts(state)) do
      {:ok, stored} ->
        stored

      {:error, reason} ->
        Logger.warning(
          "[CALL] Failed to store call record id=#{Log.reference(call.id)} reason=#{Log.reason(reason)}"
        )

        call
    end
  end

  defp call_log_opts(state) do
    case Config.get(Map.get(state, :runtime_cfg, %{}), [:calls, :max_records]) do
      max when is_integer(max) and max > 0 -> [max_records: max]
      _unset -> []
    end
  end

  defp publish_call(session, %CallRecord{} = call) when is_pid(session) do
    send(session, {:call_event, call})
    :ok
  end

  defp publish_call(_session, _call), do: :ok

  defp resolve_incoming(%{is_incoming: incoming}, _existing) when is_boolean(incoming),
    do: incoming

  defp resolve_incoming(_meta, %CallRecord{is_incoming: incoming}) when is_boolean(incoming),
    do: incoming

  defp resolve_incoming(_meta, _existing), do: nil

  # `call-creator` identifies the calling account; when the local identities
  # are unknown (no store yet) the direction stays nil instead of guessing.
  defp incoming?(nil, _state), do: nil

  defp incoming?(creator, state) do
    case Envelope.local_recipient_jids(state, %{}) do
      [] -> nil
      local_jids -> creator not in local_jids
    end
  end

  defp first_child(%Node{content: content}) when is_list(content),
    do: Enum.find(content, &match?(%Node{}, &1))

  defp first_child(_node), do: nil

  defp has_child?(%Node{content: content}, tag) when is_list(content),
    do: Enum.any?(content, &match?(%Node{tag: ^tag}, &1))

  defp has_child?(_node, _tag), do: false

  defp media_video?("video"), do: true
  defp media_video?("audio"), do: false
  defp media_video?(_media), do: nil

  defp optional_jid(value) do
    case Common.normalize_jid(value) do
      "" -> nil
      jid -> jid
    end
  end

  defp optional_text(value) when is_binary(value) and value != "", do: value
  defp optional_text(_value), do: nil

  defp parse_positive_int(value) when is_integer(value) and value > 0, do: value

  defp parse_positive_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed > 0 -> parsed
      _invalid -> nil
    end
  end

  defp parse_positive_int(_value), do: nil
end
