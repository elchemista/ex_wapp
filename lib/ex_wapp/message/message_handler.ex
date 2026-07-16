defmodule ExWapp.MessageHandler do
  @moduledoc """
  High-level router for incoming WhatsApp nodes.

  The heavy parsing, decryption, sync ingestion, and receipt logic now lives in
  `ExWapp.Message.Handler.*` modules under `lib/ex_wapp/message/handler/`.
  This module stays focused on dispatching node tags to the right domain
  handler.
  """

  require Logger

  alias ExWapp.Binary.Node
  alias ExWapp.Log
  alias ExWapp.Message.Handler.{Inbound, Notification, Receipt, Status}

  @type handler_result :: {:ok, map()} | {:ok, map(), [term()]} | {:error, term()}

  @doc """
  Handles an incoming node and updates session state.
  """
  @spec handle_node(Node.t(), pid(), map()) :: handler_result()
  def handle_node(%Node{tag: "message"} = node, session, state),
    do: Inbound.handle_message(node, session, state)

  def handle_node(%Node{tag: "notification"} = node, session, state),
    do: Notification.handle_notification(node, session, state)

  def handle_node(%Node{tag: "receipt"} = node, session, state),
    do: Receipt.handle_receipt(node, session, state)

  def handle_node(%Node{tag: "ack"} = node, session, state),
    do: Receipt.handle_ack(node, session, state)

  def handle_node(%Node{tag: "call"} = node, _session, state) do
    Logger.debug("Ignoring call node: #{inspect(Log.attrs(node.attrs))}")
    {:ok, state}
  end

  def handle_node(%Node{tag: "presence"} = node, _session, state),
    do: Status.handle_presence(node, state)

  def handle_node(%Node{tag: "chatstate"} = node, _session, state),
    do: Status.handle_chatstate(node, state)

  def handle_node(_node, _session, state), do: {:ok, state}
end
