defmodule ExWapp.Transport do
  @moduledoc """
  Behaviour for wire-level WhatsApp protocol transports.

  A protocol transport owns socket lifecycle and raw node/frame exchange below
  the session engine. It must not build high-level message types or bypass
  Signal/fanout. `ExWapp.Conn` is the production implementation.

  Do not confuse this layer with `ExWapp.Client.Transport`, whose historical
  name describes a high-level client runtime adapter.
  """

  @type wa_node :: term()

  @callback start_link(keyword()) :: GenServer.on_start()
  @callback send_node(pid(), wa_node()) :: :ok | {:error, term()}
  @callback restart_stream(pid()) :: :ok | {:error, term()}
end
