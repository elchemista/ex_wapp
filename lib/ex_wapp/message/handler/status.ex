defmodule ExWapp.Message.Handler.Status do
  @moduledoc false

  require Logger

  alias ExWapp.Binary.Node

  @spec handle_presence(Node.t(), map()) :: {:ok, map()}
  def handle_presence(%Node{attrs: attrs}, state) do
    from = Map.get(attrs, "from", "")
    type = Map.get(attrs, "type", "available")

    Logger.debug("Presence from=#{from} type=#{type}")
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

    Logger.debug("Chatstate from=#{from} state=#{chatstate}")
    {:ok, state}
  end
end
