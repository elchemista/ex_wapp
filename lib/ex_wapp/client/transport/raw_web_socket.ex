defmodule ExWapp.Client.Transport.RawWebSocket do
  @moduledoc """
  Diagnostic client adapter backed directly by the low-level WebSocket transport.

  This adapter exposes connection and raw transport events to a caller-owned
  process. It intentionally cannot send high-level `ExWapp.Message` values,
  because doing so would bypass session synchronization, device fanout, Signal
  encryption, sender keys, retries, and persistence.

  Use `ExWapp.Client.Transport.Session` for production messaging. Advanced
  protocol tooling can call `WebSocket.send_node/2` with
  already-prepared nodes.
  """

  @behaviour ExWapp.Client.Transport

  alias ExWapp.{Client, Message}
  alias ExWapp.Transport.WebSocket

  @impl true
  @doc """
  Starts the low-level WebSocket/Noise process and stores its pid on the client.
  """
  @spec connect(Client.t()) :: {:ok, Client.t()} | {:error, term()}
  def connect(%Client{} = client) do
    opts = Map.get(client.metadata, :websocket, [])
    owner = Map.get(client.metadata, :owner, self())

    case WebSocket.start_link(client, Keyword.put_new(opts, :owner, owner)) do
      {:ok, pid} ->
        {:ok, put_in(client.metadata[:transport_pid], pid)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  @doc """
  Stops the caller-owned raw WebSocket process.
  """
  @spec disconnect(Client.t()) :: {:ok, Client.t()}
  def disconnect(%Client{} = client) do
    case get_in(client.metadata, [:transport_pid]) do
      pid when is_pid(pid) -> WebSockex.cast(pid, :stop)
      _ -> :ok
    end

    {:ok, update_in(client.metadata, &Map.delete(&1, :transport_pid))}
  end

  @impl true
  @doc """
  Rejects high-level messages so they cannot bypass the complete session pipeline.
  """
  @spec send_message(Client.t(), Message.t()) :: {:error, atom()}
  def send_message(%Client{}, %Message{}) do
    {:error, :raw_websocket_cannot_send_high_level_messages}
  end
end
