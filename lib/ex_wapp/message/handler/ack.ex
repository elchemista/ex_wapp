defmodule ExWapp.Message.Handler.Ack do
  @moduledoc false

  alias ExWapp.Binary.Node

  @immediate_ack_classes ["message", "call"]

  @doc """
  Builds the transport-level ACK that must be queued before expensive inbound
  message/call processing.

  Returning `:ignore` for malformed stanzas keeps the transport boundary from
  emitting acknowledgements that cannot be correlated by the server.
  """
  @spec build_immediate_ack(Node.t()) :: {:ok, Node.t()} | :ignore
  def build_immediate_ack(%Node{tag: stanza_class, attrs: attrs, content: content})
      when stanza_class in @immediate_ack_classes and is_map(attrs) do
    from = Map.get(attrs, "from", "")
    child = first_child(content)
    id = immediate_ack_id(stanza_class, attrs, child)

    if non_empty_binary?(from) and non_empty_binary?(id) do
      type = immediate_ack_type(stanza_class, attrs, child)

      {:ok,
       build_stanza_ack(
         stanza_class,
         from,
         id,
         Map.get(attrs, "participant") || child_attr(child, "participant"),
         Map.get(attrs, "recipient") || child_attr(child, "recipient"),
         type
       )}
    else
      :ignore
    end
  end

  def build_immediate_ack(_node), do: :ignore

  defp immediate_ack_id("call", attrs, child) do
    first_non_empty([
      Map.get(attrs, "id"),
      child_attr(child, "id"),
      child_attr(child, "call-id")
    ])
  end

  defp immediate_ack_id(_stanza_class, attrs, _child), do: Map.get(attrs, "id", "")

  defp immediate_ack_type("call", attrs, child) do
    first_non_empty([Map.get(attrs, "type"), child_tag(child)])
  end

  defp immediate_ack_type(_stanza_class, _attrs, _child), do: ""

  defp first_child([%Node{} = child | _rest]), do: child
  defp first_child(_content), do: nil

  defp child_attr(%Node{attrs: attrs}, key) when is_map(attrs), do: Map.get(attrs, key)
  defp child_attr(_child, _key), do: nil

  defp child_tag(%Node{tag: tag}) when is_binary(tag), do: tag
  defp child_tag(_child), do: nil

  defp first_non_empty(values), do: Enum.find(values, "", &non_empty_binary?/1)

  @spec build_notification_ack(binary(), binary(), term(), binary()) :: Node.t()
  def build_notification_ack(from, id, participant, type) do
    build_stanza_ack("notification", from, id, participant, nil, type)
  end

  @spec build_receipt_node_ack(binary(), binary(), term(), term(), binary()) :: Node.t()
  def build_receipt_node_ack(from, id, participant, recipient, type) do
    build_stanza_ack("receipt", from, id, participant, recipient, type)
  end

  @spec build_stanza_ack(binary(), binary(), binary(), term(), term(), term()) :: Node.t()
  def build_stanza_ack(stanza_class, from, id, participant, recipient, type) do
    attrs = %{"id" => id, "to" => from, "class" => stanza_class}
    attrs = if non_empty_binary?(type), do: Map.put(attrs, "type", type), else: attrs

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

  defp non_empty_binary?(value), do: is_binary(value) and value != ""
end
