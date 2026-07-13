defmodule ExWapp.Client.Transport.WebSocket do
  @moduledoc """
  Deprecated compatibility name for `ExWapp.Client.Transport.RawWebSocket`.

  This adapter is diagnostic and cannot send high-level messages. Use
  `ExWapp.Client.Transport.Session` for the complete production path, or use
  `ExWapp.Transport.WebSocket` directly for low-level node/frame tooling.
  """

  @behaviour ExWapp.Client.Transport

  alias ExWapp.{Client, Message}
  alias ExWapp.Client.Transport.RawWebSocket

  @impl true
  @doc false
  @deprecated "use ExWapp.Client.Transport.RawWebSocket for diagnostics or Session for messaging"
  @spec connect(Client.t()) :: {:ok, Client.t()} | {:error, term()}
  def connect(%Client{} = client), do: RawWebSocket.connect(client)

  @impl true
  @doc false
  @deprecated "use ExWapp.Client.Transport.RawWebSocket for diagnostics or Session for messaging"
  @spec disconnect(Client.t()) :: {:ok, Client.t()}
  def disconnect(%Client{} = client), do: RawWebSocket.disconnect(client)

  @impl true
  @doc false
  @deprecated "high-level sending requires ExWapp.Client.Transport.Session"
  @spec send_message(Client.t(), Message.t()) :: {:error, atom()}
  def send_message(%Client{} = client, %Message{} = message) do
    RawWebSocket.send_message(client, message)
  end
end
