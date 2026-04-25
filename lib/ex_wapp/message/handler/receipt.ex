defmodule ExWapp.Message.Handler.Receipt do
  @moduledoc false

  require Logger

  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.{Ack, Common}

  @spec handle_receipt(Node.t(), pid(), map()) :: {:ok, map()} | {:ok, map(), [term()]}
  def handle_receipt(%Node{attrs: attrs, content: content}, session, state) do
    from_raw = Map.get(attrs, "from", "")
    from = Common.normalize_jid(from_raw)
    id = Map.get(attrs, "id", "")
    type = Map.get(attrs, "type", "delivery")
    participant = Map.get(attrs, "participant")
    recipient = Map.get(attrs, "recipient")

    retry_info = extract_retry_info(content)
    target = Common.chat_target(session, state)
    status = receipt_status(type)

    log_receipt(type, retry_info, from, id)
    maybe_update_receipt_status(target, from, id, status)

    actions = receipt_actions(type, from, id)
    ack_actions = receipt_ack_actions(id, from_raw, participant, recipient, type)

    {:ok, state, actions ++ ack_actions}
  end

  @spec handle_ack(Node.t(), pid(), map()) :: {:ok, map()}
  def handle_ack(%Node{attrs: attrs}, session, state) do
    id = Map.get(attrs, "id", "")
    class = Map.get(attrs, "class", "")
    error = Map.get(attrs, "error", "")
    type = effective_ack_type(Map.get(attrs, "type", ""), error)
    from = Common.normalize_jid(Map.get(attrs, "from", ""))
    to = Common.normalize_jid(Map.get(attrs, "to", ""))

    target = Common.chat_target(session, state)

    log_ack(class, type, id, from, to, error)
    maybe_update_ack_status(target, ack_target_jid(to, from), id, ack_status(type))

    {:ok, state}
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

  defp log_receipt("retry", %{count: count, error: error}, from, id) do
    Logger.warning(
      "[RECEIPT] Retry requested from=#{from} id=#{id} count=#{inspect(count)} error=#{inspect(error)}"
    )
  end

  defp log_receipt("retry", _retry_info, from, id) do
    Logger.warning("[RECEIPT] Retry requested from=#{from} id=#{id}")
  end

  defp log_receipt(type, _retry_info, from, id) do
    Logger.debug("[RECEIPT] type=#{type} from=#{from} id=#{id}")
  end

  defp maybe_update_receipt_status(nil, _from, _id, _status), do: :ok

  defp maybe_update_receipt_status(target, from, id, status),
    do: ExWapp.Chat.update_message_status(target, from, id, status)

  defp receipt_actions("retry", from, id) when from != "" and id != "",
    do: [{:retry_send, from, id}]

  defp receipt_actions(_type, _from, _id), do: []

  defp effective_ack_type(type, error) when type in [nil, ""] and error not in [nil, ""],
    do: "error"

  defp effective_ack_type(type, _error), do: type || ""

  defp log_ack(class, type, id, from, to, error) do
    Logger.debug(
      "[ACK] class=#{class} type=#{type} id=#{id} from=#{from} to=#{to} error=#{inspect(error)}"
    )
  end

  defp ack_status("error"), do: :failed
  defp ack_status(_type), do: :sent
  defp ack_target_jid(to, _from) when to != "", do: to
  defp ack_target_jid(_to, from) when from != "", do: from
  defp ack_target_jid(_to, _from), do: ""
  defp maybe_update_ack_status(nil, _jid, _id, _status), do: :ok

  defp maybe_update_ack_status(target, jid, id, status),
    do: ExWapp.Chat.update_message_status(target, jid, id, status)

  defp receipt_status("read"), do: :read
  defp receipt_status("played"), do: :read
  defp receipt_status("retry"), do: :failed
  defp receipt_status(_), do: :delivered
end
