defmodule ExWapp.Transport do
  @moduledoc """
  Behaviour for WhatsApp transport adapters.

  A transport adapter owns the socket connection and raw frame exchange.
  `ExWapp.Conn` is the default implementation.
  """

  @type wa_node :: term()

  @callback start_link(keyword()) :: GenServer.on_start()
  @callback send_node(pid(), wa_node()) :: :ok | {:error, term()}
  @callback restart_stream(pid()) :: :ok | {:error, term()}
end
