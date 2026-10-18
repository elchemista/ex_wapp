defmodule ExWapp.Message.Handler.Receipt do
  @moduledoc """
  Handles inbound delivery/read receipts and message acknowledgements.

  It updates persisted chat status, emits receipt acknowledgements, and translates
  retry or server errors into session actions without decoding message content.
  """

  require Logger

  alias ExWapp.Binary.Node
  alias ExWapp.Chat
  alias ExWapp.Log
  alias ExWapp.Message.Handler.{Ack, Common}
  alias ExWapp.Session.Worker.Subscribers

  @spec handle_receipt(Node.t(), pid(), map()) :: {:ok, map()} | {:ok, map(), [term()]}
  def handle_receipt(%Node{attrs: attrs, content: content} = node, session, state) do
    from_raw = Map.get(attrs, "from", "")
    from = Common.normalize_jid(from_raw)
    id = Map.get(attrs, "id", "")
    type = Map.get(attrs, "type", "delivery")
    participant = Map.get(attrs, "participant")
    recipient = Map.get(attrs, "recipient")

    retry_info = extract_retry_info(content)
    target = Common.chat_target(session, state)

    log_receipt(type, retry_info, from, id)

    node
    |> parse_receipts()
    |> Enum.each(fn receipt ->
      Enum.each(receipt.message_ids, fn message_id ->
        maybe_update_receipt_status(target, receipt.from, message_id, receipt.status)
      end)
    end)

    ack_actions = receipt_ack_actions(id, from_raw, participant, recipient, type)

    actions =
      case retry_request(type, from, id, retry_info, attrs, ack_actions) do
        nil -> ack_actions
        retry_action -> [retry_action]
      end

    {:ok, state, actions}
  end

  @doc "Expands a receipt stanza into one entry per normal or grouped participant receipt."
  @spec parse_receipts(Node.t()) :: [map()]
  def parse_receipts(%Node{attrs: attrs, content: content}) do
    type = Map.get(attrs, "type", "delivery")
    status = receipt_status(type)
    from = Common.normalize_jid(Map.get(attrs, "from", ""))
    grouped = child_nodes(content, "participants")

    if grouped == [] do
      [
        %{
          message_ids: normal_message_ids(attrs, content),
          from: from,
          participant: normalize_optional_jid(Map.get(attrs, "participant")),
          status: status,
          timestamp: receipt_timestamp(Map.get(attrs, "t"))
        }
      ]
    else
      grouped_receipts(grouped, from, status)
    end
  end

  @spec handle_ack(Node.t(), pid(), map()) :: {:ok, map()}
  def handle_ack(%Node{attrs: attrs}, session, state) do
    id = Map.get(attrs, "id", "")
    class = Map.get(attrs, "class", "")
    error = Map.get(attrs, "error", "")
    type = effective_ack_type(Map.get(attrs, "type", ""), error)
    from = Common.normalize_jid(Map.get(attrs, "from", ""))
    to = Common.normalize_jid(Map.get(attrs, "to", ""))

    jid = ack_target_jid(to, from)
    target = Common.chat_target(session, state)
    status = ack_status(type)

    log_ack(class, type, id, from, to, error)
    # Receipts (including media retries), calls and notifications can reuse a
    # message ID. Only a message ACK carries a verdict for the stored message.
    if class == "message", do: maybe_update_ack_status(target, jid, id, status)

    if session_repair_requested?(session, class, id, jid, status, error) do
      :ok
    else
      maybe_broadcast_delivery(state, class, id, jid, status, error)
    end

    {:ok, state}
  end

  # A rejection the library can act on is not a verdict yet. What the server
  # refused here is the Signal session the message was encrypted under, so the
  # send goes back to the session process, which drops that session and resends
  # the retained payload under a fresh one. The delivery event is withheld until
  # that attempt produces an ack of its own, so a caller blocked in
  # `send_message_await/4` sees one outcome instead of a failure followed by a
  # success it never asked for. When the session process cannot repair — no
  # retained payload, retry budget spent, no connection — it broadcasts the
  # failure itself, so withholding here never loses the verdict.
  @spec session_repair_requested?(pid(), String.t(), String.t(), String.t(), atom(), term()) ::
          boolean()
  defp session_repair_requested?(session, "message", id, jid, :failed, error)
       when is_pid(session) and id != "" and jid != "" do
    ack = ExWapp.Error.Ack.classify(error)

    if ack.category == :session do
      send(session, {:ack_session_rejection, id, jid, ack})
      true
    else
      false
    end
  end

  defp session_repair_requested?(_session, _class, _id, _jid, _status, _error), do: false

  # Only message acks carry a delivery verdict; receipt/notification acks are
  # transport bookkeeping and would be noise on this topic.
  defp maybe_broadcast_delivery(_state, class, _id, _jid, _status, _error)
       when class != "message",
       do: :ok

  defp maybe_broadcast_delivery(_state, _class, "", _jid, _status, _error), do: :ok

  defp maybe_broadcast_delivery(state, _class, id, jid, status, error) do
    meta = %{jid: jid}

    meta =
      if status == :failed,
        do: Map.put(meta, :error, ExWapp.Error.Ack.classify(error)),
        else: meta

    Subscribers.broadcast_delivery(Map.get(state, :session_id), id, status, meta)
  end

  defp receipt_ack_actions(id, from, participant, recipient, type) do
    if id != "" and from != "" do
      [{:send_node, Ack.build_receipt_node_ack(from, id, participant, recipient, type)}]
    else
      []
    end
  end

  defp extract_retry_info(content) when is_list(content) do
    case Common.find_child_node(content, "retry") do
      %Node{attrs: retry_attrs} ->
        %{
          count: Map.get(retry_attrs, "count"),
          error: Map.get(retry_attrs, "error"),
          id: Map.get(retry_attrs, "id"),
          timestamp: Map.get(retry_attrs, "t")
        }

      _ ->
        nil
    end
  end

  defp extract_retry_info(_), do: nil

  defp grouped_receipts(groups, from, status) do
    Enum.flat_map(groups, &grouped_receipt(&1, from, status))
  end

  defp grouped_receipt(%Node{attrs: attrs, content: users}, from, status) do
    case non_empty_binary(Map.get(attrs, "key")) do
      nil ->
        []

      message_id ->
        users
        |> child_nodes("user")
        |> Enum.flat_map(&participant_receipt(&1, message_id, from, status))
    end
  end

  defp grouped_receipt(_node, _from, _status), do: []

  defp participant_receipt(%Node{attrs: attrs}, message_id, from, status) do
    case normalize_optional_jid(Map.get(attrs, "jid")) do
      nil ->
        []

      participant ->
        [
          %{
            message_ids: [message_id],
            from: from,
            participant: participant,
            status: status,
            timestamp: receipt_timestamp(Map.get(attrs, "t"))
          }
        ]
    end
  end

  defp normal_message_ids(attrs, content) do
    primary = non_empty_binary(Map.get(attrs, "id"))

    batched =
      content
      |> child_nodes("list")
      |> Enum.flat_map(fn %Node{content: items} ->
        items
        |> child_nodes("item")
        |> Enum.map(fn %Node{attrs: item_attrs} ->
          non_empty_binary(Map.get(item_attrs, "id"))
        end)
      end)

    [primary | batched]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp child_nodes(content, tag) when is_list(content) do
    Enum.filter(content, &match?(%Node{tag: ^tag}, &1))
  end

  defp child_nodes(_content, _tag), do: []

  defp normalize_optional_jid(value) do
    case Common.normalize_jid(value) do
      "" -> nil
      jid -> if(String.contains?(jid, "@"), do: jid, else: nil)
    end
  end

  defp non_empty_binary(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp non_empty_binary(_value), do: nil

  defp receipt_timestamp(value) when is_integer(value) and value >= 0, do: value

  defp receipt_timestamp(value) when is_binary(value) do
    case Integer.parse(value) do
      {timestamp, ""} when timestamp >= 0 -> timestamp
      _ -> nil
    end
  end

  defp receipt_timestamp(_value), do: nil

  defp log_receipt("retry", %{count: count, error: error}, from, id) do
    Logger.warning(
      "[RECEIPT] Retry requested from=#{Log.reference(from)} id=#{Log.reference(id)} count=#{inspect(count)} error=#{Log.reason(error)}"
    )
  end

  defp log_receipt("retry", _retry_info, from, id) do
    Logger.warning(
      "[RECEIPT] Retry requested from=#{Log.reference(from)} id=#{Log.reference(id)}"
    )
  end

  defp log_receipt(type, _retry_info, from, id) do
    Logger.debug("[RECEIPT] type=#{type} from=#{Log.reference(from)} id=#{Log.reference(id)}")
  end

  defp maybe_update_receipt_status(nil, _from, _id, _status), do: :ok

  defp maybe_update_receipt_status(target, from, id, status),
    do: ExWapp.Chat.update_message_status(target, from, id, status)

  # A retry receipt is the peer saying it could not decrypt our message, so the
  # retained payload is re-encrypted and sent again under the same ID (the
  # session owns that: `Session.Worker` handles `{:retry_outgoing_message, ...}`
  # through `SendRecovery`). The stanza ack rides inside the request instead of
  # being emitted here: the session acknowledges the receipt only once the
  # resend has been dispatched or ruled out, so a session that dies in between
  # has the receipt delivered again rather than losing the request — whatsmeow
  # acks retry receipts from inside its retry handler for the same reason.
  #
  # The message ID comes from the `<retry id=...>` child when present; the
  # receipt's own `id` is the same value in practice, but the child is what the
  # retry protocol defines.
  defp retry_request("retry", from, id, retry_info, attrs, ack_actions) when from != "" do
    case retry_message_id(retry_info, id) do
      "" ->
        nil

      message_id ->
        retry_meta =
          %{}
          |> put_retry_meta(:retry_count, parse_retry_count(retry_info))
          |> put_retry_meta(:error, retry_info_field(retry_info, :error))
          |> put_retry_meta(:participant, Map.get(attrs, "participant"))
          |> put_retry_meta(:recipient, Map.get(attrs, "recipient"))
          |> put_retry_ack(ack_actions)

        {:retry_outgoing_message, from, message_id, retry_meta}
    end
  end

  defp retry_request(_type, _from, _id, _retry_info, _attrs, _ack_actions), do: nil

  defp retry_message_id(retry_info, id) do
    case retry_info_field(retry_info, :id) do
      nil -> id || ""
      retry_id -> retry_id
    end
  end

  defp retry_info_field(%{} = retry_info, key) do
    case Map.get(retry_info, key) do
      value when is_binary(value) and value != "" -> value
      _ -> nil
    end
  end

  defp retry_info_field(_retry_info, _key), do: nil

  defp parse_retry_count(retry_info) do
    case retry_info_field(retry_info, :count) do
      nil -> nil
      raw -> parse_integer(raw)
    end
  end

  defp parse_integer(raw) do
    case Integer.parse(raw) do
      {count, ""} -> count
      _ -> nil
    end
  end

  defp put_retry_meta(meta, key, value) when is_binary(value) and value != "",
    do: Map.put(meta, key, value)

  defp put_retry_meta(meta, key, value) when is_integer(value), do: Map.put(meta, key, value)
  defp put_retry_meta(meta, _key, _value), do: meta

  defp put_retry_ack(meta, [{:send_node, %Node{tag: "ack"} = ack} | _rest]),
    do: Map.put(meta, :ack_node, ack)

  defp put_retry_ack(meta, _ack_actions), do: meta

  defp effective_ack_type(type, error) when type in [nil, ""] and error not in [nil, ""],
    do: "error"

  defp effective_ack_type(type, _error), do: type || ""

  defp log_ack(class, type, id, from, to, error) do
    message =
      "[ACK] class=#{class} type=#{type} id=#{Log.reference(id)} from=#{Log.reference(from)} " <>
        "to=#{Log.reference(to)} error=#{Log.reason(error)}#{ack_error_code_log(error)}"

    if type == "error", do: Logger.warning(message), else: Logger.debug(message)
  end

  defp ack_error_code_log(error) when is_binary(error) do
    if Regex.match?(~r/^\d{3}$/, error), do: " error_code=#{error}", else: ""
  end

  defp ack_error_code_log(_error), do: ""

  defp ack_status("error"), do: :failed
  defp ack_status(_type), do: :sent
  defp ack_target_jid(to, _from) when to != "", do: to
  defp ack_target_jid(_to, from) when from != "", do: from
  defp ack_target_jid(_to, _from), do: ""
  defp maybe_update_ack_status(nil, _jid, _id, _status), do: :ok
  defp maybe_update_ack_status(_target, _jid, "", _status), do: :ok

  # The server does not always acknowledge a message under the same addressing
  # family the chat is keyed by: a LID-addressed send can come back acked
  # against the peer's phone JID, and vice versa. A JID-scoped update silently
  # matches nothing in that case, so the message stays `:pending` forever and
  # every caller that waits on the ack concludes the send was dropped even
  # though the server accepted it. Fall back to an ID-wide update, which is
  # safe because WhatsApp message IDs are unique per account.
  defp maybe_update_ack_status(target, jid, id, status) do
    if jid != "" and Chat.find_message(target, jid, id) do
      Chat.update_message_status(target, jid, id, status)
    else
      Chat.update_message_status_by_id(target, id, status)
    end
  end

  defp receipt_status("read"), do: :read
  defp receipt_status("read-self"), do: :read
  defp receipt_status("played"), do: :read
  defp receipt_status("sender"), do: :sent
  defp receipt_status("retry"), do: :failed
  defp receipt_status(_), do: :delivered
end
