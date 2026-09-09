defmodule ExWapp.ClientSessionLifecycleTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Call, Client, Contact, Event, Media, Store}
  alias ExWapp.Client.Transport.Session

  @jid "15550001111@s.whatsapp.net"

  defmodule SessionStub do
    use GenServer
    def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
    @impl true
    def init(opts), do: {:ok, opts}

    @impl true
    def handle_call({:subscribe_qr, owner}, _from, state) do
      ref = make_ref()

      case state.qr do
        :pending -> :ok
        :closed -> send(owner, {:ex_wapp_qr_closed, ref})
        payload -> send(owner, {:ex_wapp_qr, ref, payload})
      end

      send(state.owner, {:qr_subscription, ref})
      {:reply, {:ok, ref}, state}
    end

    def handle_call({:app_state_mutation, patch}, _from, state) do
      send(state.owner, {:contact_patch, patch})
      {:reply, {:ok, %{}, %{}}, state}
    end

    def handle_call(:sync_contacts, _from, state), do: {:reply, :ok, state}

    def handle_call({:download_media, ref, opts}, _from, state) do
      send(state.owner, {:download_options, opts})
      {:reply, {:ok, %Media.Download{ref: ref, bytes: "download"}}, state}
    end

    @impl true
    def handle_cast(message, state) do
      send(state.owner, {:session_cast, message})
      {:noreply, state}
    end
  end

  defp client(qr \\ :pending) do
    session = start_supervised!({SessionStub, %{owner: self(), qr: qr}})

    ExWapp.new(
      store: Store.Memory,
      transport: Session,
      metadata: %{session_pid: session, pair_timeout: 0}
    )
  end

  test "connect and disconnect retain and use the existing session" do
    initial = client()
    assert {:ok, connected} = ExWapp.connect(initial)
    assert connected.status == :connecting
    assert connected.metadata.session_pid == initial.metadata.session_pid
    assert_receive {:session_cast, :connect}
    assert {:ok, %Client{status: :disconnected}} = ExWapp.disconnect(connected)
    assert_receive {:session_cast, :disconnect}

    assert {:ok, _} = Session.disconnect(%{initial | metadata: %{}})
  end

  for {qr, expected} <- [{"qr-payload", "qr-payload"}, {:pending, :pending}] do
    test "pairing #{inspect(qr)} releases its subscription" do
      initial = client(unquote(qr))
      assert {:ok, %Client{status: :pairing}, unquote(expected)} = ExWapp.pair(initial)
      assert_receive {:qr_subscription, ref}
      assert_receive {:session_cast, :connect}
      assert_receive {:session_cast, {:unsubscribe_qr, ^ref}}
    end
  end

  test "closed pairing produces a client error" do
    assert {:error, %ExWapp.Error{reason: :pairing_closed}, _} = ExWapp.pair(client(:closed))
  end

  test "message event formats preserve the configured session identity" do
    initial = %{client() | session_id: "configured"}
    message = %{id: "message", text: "hello"}

    for payload <- [
          {:ex_wapp_message, make_ref(), @jid, message},
          {:ex_wapp_message, "incoming-session", @jid, message}
        ] do
      assert {:ok, _,
              [%Event{session_id: "configured", payload: %{jid: @jid, message: ^message}}]} =
               ExWapp.receive_message(initial, payload)
    end

    assert {:ok, _, [%Event{session_id: "incoming-session"}]} =
             ExWapp.receive_message(
               %{initial | session_id: nil},
               {:ex_wapp_message, "incoming-session", @jid, message}
             )

    assert {:ok, _, []} = ExWapp.receive_message(initial, :unrelated)
  end

  test "contact and call queries use the client's store without starting a session" do
    initial = ExWapp.new(store: Store.Memory, transport: Session)
    :ok = Contact.put(initial.store, @jid, %Contact{jid: @jid, full_name: "Alice"})

    {:ok, _} =
      Call.upsert(initial.store, %Call{
        id: "call",
        chat_jid: @jid,
        status: :missed,
        start_time: 100
      })

    assert {:ok, [%Contact{full_name: "Alice"}]} = ExWapp.list_contacts(initial)
    assert {:ok, %Contact{jid: @jid}} = ExWapp.get_contact(initial, @jid)
    assert {:ok, nil} = ExWapp.get_contact(initial, "unknown@s.whatsapp.net")
    assert {:ok, [%Call{id: "call"}]} = ExWapp.list_calls(initial, status: :missed)
    assert {:ok, %Call{id: "call"}} = ExWapp.get_call(initial, "call")
    assert {:error, %ExWapp.Error{reason: :not_found}, _} = ExWapp.get_call(initial, "absent")
    refute Map.has_key?(initial.metadata, :session_pid)
  end

  test "message history can be streamed and selectively deleted through the public client" do
    initial = ExWapp.new(store: Store.Memory, transport: Session)
    ExWapp.Chat.get_or_create(initial.store, @jid)

    :ok =
      Store.upsert_messages(initial.store, @jid, [
        %{id: "old", timestamp: 1, text: "one", from_me: false},
        %{id: "new", timestamp: 2, text: "two", from_me: true}
      ])

    assert {:ok, [%{id: "new"}]} = ExWapp.get_messages(initial, @jid, limit: 1)
    assert {:ok, stream} = ExWapp.stream_messages(initial, @jid)
    assert Enum.map(stream, & &1.id) == ["old", "new"]
    assert {:ok, updated} = ExWapp.delete_messages(initial, @jid, ["old"])
    assert {:ok, [%{id: "new"}]} = ExWapp.get_messages(updated, @jid)
    assert {:ok, [_chat]} = ExWapp.list_chats(updated)
    assert {:ok, []} = ExWapp.list_groups(updated)
    assert {:ok, _chat} = ExWapp.get_chat(updated, @jid)
  end

  test "contact changes and media downloads flow through the active session" do
    initial = client()
    assert {:ok, _} = ExWapp.sync_contacts(initial)
    assert {:ok, _} = ExWapp.create_contact(initial, @jid, "Alice")
    assert_receive {:contact_patch, %{}}
    assert {:ok, _} = ExWapp.delete_contact(initial, @jid)
    assert_receive {:contact_patch, %{}}

    for attrs <- [[full_name: "Alice"], %{"push_name" => "Alice"}] do
      assert {:ok, _} = Session.update_contact(initial, @jid, attrs)
      assert_receive {:contact_patch, %{}}
    end

    assert {:error, :missing_contact_name} = Session.update_contact(initial, @jid, nil)

    ref = %Media.Ref{type: :image}

    assert {:ok, _, %Media.Download{ref: ^ref, bytes: "download"}} =
             ExWapp.download_media(initial, ref, timeout: 100)

    assert_receive {:download_options, [timeout: 100]}
  end
end
