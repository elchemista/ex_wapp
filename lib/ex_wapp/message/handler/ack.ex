defmodule ExWapp.Message.Handler.Ack do
  @moduledoc false

  alias ExWapp.Binary.Node

  @spec build_notification_ack(binary(), binary(), term(), binary()) :: Node.t()
  def build_notification_ack(from, id, participant, type) do
    build_stanza_ack("notification", from, id, participant, nil, type)
  end

  @spec build_receipt_node_ack(binary(), binary(), term(), term(), binary()) :: Node.t()
  def build_receipt_node_ack(from, id, participant, recipient, type) do
    build_stanza_ack("receipt", from, id, participant, recipient, type)
  end

  defp build_stanza_ack(stanza_class, from, id, participant, recipient, type) do
    attrs = %{"id" => id, "to" => from, "class" => stanza_class}
    attrs = if type != "", do: Map.put(attrs, "type", type), else: attrs

    attrs =
      case participant do
        p when is_binary(p) and p != "" -> Map.put(attrs, "participant", p)
        _ -> attrs
      end

    attrs =
      case recipient do
        r when is_binary(r) and r != "" -> Map.put(attrs, "recipient", r)
        _ -> attrs
      end

    %Node{tag: "ack", attrs: attrs, content: nil}
  end
end
