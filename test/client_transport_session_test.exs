defmodule ExWapp.ClientTransportSessionTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Client, Message}
  alias ExWapp.Client.Transport.Session

  defmodule SessionStub do
    use GenServer

    def start_link(owner), do: GenServer.start_link(__MODULE__, owner)

    @impl true
    def init(owner), do: {:ok, owner}

    @impl true
    def handle_call({:send_message, message}, _from, owner) do
      send(owner, {:session_send_message, message})
      {:reply, {:ok, message.id}, owner}
    end
  end

  test "preserves a high-level text message ID through the session adapter" do
    session = start_supervised!({SessionStub, self()})
    message_id = "client-message-id"

    client = %Client{
      session_id: "client-session",
      store: ExWapp.Store.Memory.new(),
      transport: Session,
      events: ExWapp.Events.Noop,
      runtime: %{},
      status: :connected,
      metadata: %{session_pid: session}
    }

    message = Message.text("15550001111@s.whatsapp.net", "hello", id: message_id)

    assert {:ok, ^client, ^message_id} = Session.send_message(client, message)

    assert_receive {:session_send_message, ^message}
  end
end
