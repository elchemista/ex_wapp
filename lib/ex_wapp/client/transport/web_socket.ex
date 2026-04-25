defmodule ExWapp.Client.Transport.WebSocket do
  @moduledoc """
  High-level client transport that starts the optional WebSocket process.

  The process is owned by the caller supplied in client metadata:

      ExWapp.new(
        transport: ExWapp.Client.Transport.WebSocket,
        metadata: %{owner: self()}
      )

  WebSocket events are delivered as `{:ex_wapp_transport, event}` messages.
  """

  @behaviour ExWapp.Client.Transport

  alias ExWapp.{Client, Message}

  @impl true
  @spec connect(Client.t()) :: {:ok, Client.t()} | {:error, term()}
  def connect(%Client{} = client) do
    opts = Map.get(client.metadata, :websocket, [])
    owner = Map.get(client.metadata, :owner, self())

    case ExWapp.Transport.WebSocket.start_link(client, Keyword.put_new(opts, :owner, owner)) do
      {:ok, pid} ->
        {:ok, put_in(client.metadata[:transport_pid], pid)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  @spec disconnect(Client.t()) :: {:ok, Client.t()}
  def disconnect(%Client{} = client) do
    case get_in(client.metadata, [:transport_pid]) do
      pid when is_pid(pid) -> Process.exit(pid, :normal)
      _ -> :ok
    end

    {:ok, update_in(client.metadata, &Map.delete(&1, :transport_pid))}
  end

  @impl true
  @spec send_message(Client.t(), Message.t()) :: {:ok, Client.t(), String.t()} | {:error, term()}
  def send_message(%Client{} = client, %Message{} = message) do
    case get_in(client.metadata, [:transport_pid]) do
      pid when is_pid(pid) ->
        node = build_unencrypted_node(message)
        :ok = ExWapp.Transport.WebSocket.send_node(pid, node)
        {:ok, client, message.id}

      _ ->
        {:error, :not_connected}
    end
  end

  @spec build_unencrypted_node(Message.t()) :: ExWapp.Binary.binary_node()
  defp build_unencrypted_node(%Message{type: :text, to: to, body: text, id: id, opts: opts}) do
    timestamp = System.system_time(:second)
    proto = ExWapp.Messages.build_text_proto(text, opts)
    {:ok, payload} = ExWapp.Proto.Message.encode(proto)
    ExWapp.Messages.build_message_node(to, id, IO.iodata_to_binary(payload), timestamp, opts)
  end

  defp build_unencrypted_node(%Message{type: :typing, to: to, body: composing}) do
    ExWapp.Messages.build_typing(to, composing)
  end

  defp build_unencrypted_node(%Message{type: :read_receipt, to: to, body: ids}) do
    ExWapp.Messages.build_receipt_node(to, ids, "read")
  end
end
