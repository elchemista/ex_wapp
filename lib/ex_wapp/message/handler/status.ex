defmodule ExWapp.Message.Handler.Status do
  @moduledoc false

  require Logger

  alias ExWapp.Binary.Node
  alias ExWapp.Log
  alias ExWapp.Message.Handler.Common

  @spec handle_presence(Node.t(), map()) :: {:ok, map()}
  def handle_presence(%Node{attrs: attrs}, state) do
    from = Map.get(attrs, "from", "")
    type = Map.get(attrs, "type", "available")

    Logger.debug("Presence from=#{Log.reference(from)} type=#{type}")
    {:ok, state}
  end

  @doc """
  Handles a `<status>` stanza.

  WhatsApp delivers newsletter status updates on this tag, unencrypted. The
  transport ack is already queued at the connection boundary
  (`ExWapp.Message.Handler.Ack.build_immediate_ack/1`), so what is left here is
  to record the stanza; newsletter content itself is not decoded yet.
  """
  @spec handle_status_update(Node.t(), map()) :: {:ok, map()}
  def handle_status_update(%Node{attrs: attrs, content: content}, state) do
    from = attrs |> Map.get("from", "") |> Common.normalize_jid_with_device()
    id = Map.get(attrs, "id", "")

    child_tags =
      case content do
        children when is_list(children) -> Enum.map(children, & &1.tag)
        _ -> []
      end

    Logger.debug(
      "[STATUS] from=#{Log.reference(from)} id=#{Log.reference(id)} " <>
        "newsletter?=#{String.ends_with?(from, "@newsletter")} children=#{inspect(child_tags)}"
    )

    {:ok, state}
  end

  @spec handle_chatstate(Node.t(), map()) :: {:ok, map()}
  def handle_chatstate(%Node{attrs: attrs, content: content}, state) do
    from = Map.get(attrs, "from", "")

    chatstate =
      case content do
        [%Node{tag: "composing"}] -> :typing
        [%Node{tag: "paused"}] -> :stopped
        _ -> :unknown
      end

    Logger.debug("Chatstate from=#{Log.reference(from)} state=#{chatstate}")
    {:ok, state}
  end
end
