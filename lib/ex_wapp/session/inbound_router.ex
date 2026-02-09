defmodule ExWapp.Session.InboundRouter do
  @moduledoc """
  Decouples transport ingestion from session node processing.

  Connection events may arrive in bursts; routing through this process keeps the
  transport callback lightweight and makes inbound handling easier to instrument.
  """

  use GenServer

  defstruct session: nil

  @type t :: %__MODULE__{session: pid() | nil}

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec route(pid(), ExWapp.Binary.Node.t()) :: :ok
  def route(pid, node) do
    GenServer.cast(pid, {:route, node})
  end

  @impl true
  @spec init(keyword()) :: {:ok, t()}
  def init(opts) do
    {:ok, %__MODULE__{session: Keyword.fetch!(opts, :session)}}
  end

  @impl true
  @spec handle_cast({:route, ExWapp.Binary.Node.t()}, t()) :: {:noreply, t()}
  def handle_cast({:route, node}, %{session: session} = state) do
    send(session, {:inbound_node, node})
    {:noreply, state}
  end
end
