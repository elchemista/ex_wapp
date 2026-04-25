defmodule ExWapp.Examples.GenServerSession do
  @moduledoc """
  Example of embedding the runtime-neutral ExWapp client in an application-owned
  GenServer.

  By default this example uses the built-in `ExWapp.Client.Transport.Session`,
  so real WhatsApp communication goes through the full session engine. Tests can
  still pass a custom transport to keep the example deterministic.
  """

  use GenServer

  defmodule Transport do
    @moduledoc false
    @behaviour ExWapp.Client.Transport

    @impl true
    def connect(client) do
      send(client.metadata.owner, {:whatsapp_transport, :connect})
      {:ok, client}
    end

    @impl true
    def pair(client) do
      qr_payload = "example-qr-payload"
      send(client.metadata.owner, {:whatsapp_transport, {:pair, qr_payload}})
      {:ok, client, qr_payload}
    end

    @impl true
    def disconnect(client) do
      send(client.metadata.owner, {:whatsapp_transport, :disconnect})
      {:ok, client}
    end

    @impl true
    def send_message(client, %ExWapp.Message{} = message) do
      send(client.metadata.owner, {:whatsapp_transport, {:send_message, message}})
      {:ok, client, message.id}
    end

    @impl true
    def receive_message(client, payload, _opts) do
      event =
        ExWapp.Event.new(:message_received, payload,
          session_id: client.session_id,
          metadata: %{source: __MODULE__}
        )

      {:ok, client, [event]}
    end
  end

  defmodule Events do
    @moduledoc false
    @behaviour ExWapp.Events

    @impl true
    def emit(client, event) do
      send(client.metadata.owner, {:whatsapp_event, event})
      :ok
    end
  end

  @doc """
  Starts the example GenServer.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
  end

  @doc """
  Connects the WhatsApp client.
  """
  @spec connect(GenServer.server()) :: :ok | {:error, ExWapp.Error.t()}
  def connect(server), do: GenServer.call(server, :connect)

  @doc """
  Starts pairing and returns the QR payload produced by the adapter.
  """
  @spec pair(GenServer.server()) :: {:ok, term()} | {:error, ExWapp.Error.t()}
  def pair(server), do: GenServer.call(server, :pair)

  @doc """
  Sends a text message through the embedded ExWapp client.
  """
  @spec send_text(GenServer.server(), String.t(), iodata()) ::
          {:ok, String.t()} | {:error, ExWapp.Error.t()}
  def send_text(server, to, text) do
    GenServer.call(server, {:send_text, to, IO.iodata_to_binary(text)})
  end

  @doc """
  Pushes an inbound payload into the embedded ExWapp client.
  """
  @spec receive_payload(GenServer.server(), term()) ::
          {:ok, [ExWapp.Event.t()]} | {:error, ExWapp.Error.t()}
  def receive_payload(server, payload), do: GenServer.call(server, {:receive_payload, payload})

  @doc """
  Returns the current client diagnostics.
  """
  @spec diagnostics(GenServer.server()) :: map()
  def diagnostics(server), do: GenServer.call(server, :diagnostics)

  @impl true
  def init(opts) do
    client =
      opts
      |> Keyword.put_new(:store, ExWapp.Store.Memory)
      |> Keyword.put_new(:transport, ExWapp.Client.Transport.Session)
      |> Keyword.put_new(:events, Events)
      |> Keyword.update(:metadata, %{owner: self()}, &Map.put(&1, :owner, self()))
      |> ExWapp.new()

    {:ok, %{client: client, transport_log: [], events: []}}
  end

  @impl true
  def handle_call(:connect, _from, state) do
    case ExWapp.connect(state.client) do
      {:ok, client} -> {:reply, :ok, %{state | client: client}}
      {:error, error, client} -> {:reply, {:error, error}, %{state | client: client}}
    end
  end

  def handle_call(:pair, _from, state) do
    case ExWapp.pair(state.client) do
      {:ok, client, qr_payload} -> {:reply, {:ok, qr_payload}, %{state | client: client}}
      {:error, error, client} -> {:reply, {:error, error}, %{state | client: client}}
    end
  end

  def handle_call({:send_text, to, text}, _from, state) do
    case ExWapp.send_message(state.client, to: to, text: text) do
      {:ok, client, message_id} -> {:reply, {:ok, message_id}, %{state | client: client}}
      {:error, error, client} -> {:reply, {:error, error}, %{state | client: client}}
    end
  end

  def handle_call({:receive_payload, payload}, _from, state) do
    case ExWapp.receive_message(state.client, payload) do
      {:ok, client, events} -> {:reply, {:ok, events}, %{state | client: client}}
      {:error, error, client} -> {:reply, {:error, error}, %{state | client: client}}
    end
  end

  def handle_call(:diagnostics, _from, state) do
    diagnostics =
      state.client
      |> ExWapp.diagnostics()
      |> Map.put(:transport_log, Enum.reverse(state.transport_log))
      |> Map.put(:events, Enum.reverse(state.events))

    {:reply, diagnostics, state}
  end

  @impl true
  def handle_info({:whatsapp_transport, entry}, state) do
    {:noreply, %{state | transport_log: [entry | state.transport_log]}}
  end

  def handle_info({:whatsapp_event, event}, state) do
    {:noreply, %{state | events: [event | state.events]}}
  end
end
