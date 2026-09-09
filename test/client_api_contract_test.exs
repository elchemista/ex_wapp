defmodule ExWapp.ClientAPIContractTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Client, Error, Event, Media, Message}

  defmodule Adapter do
    @behaviour ExWapp.Client.Transport

    @impl true
    def connect(client), do: reply(client, :connect, [])
    @impl true
    def pair(client), do: reply(client, :pair, [])
    @impl true
    def disconnect(client), do: reply(client, :disconnect, [])
    @impl true
    def send_message(client, message), do: reply(client, :send_message, [message])
    @impl true
    def receive_message(client, payload, opts),
      do: reply(client, :receive_message, [payload, opts])

    @impl true
    def list_contacts(client), do: reply(client, :list_contacts, [])
    @impl true
    def delete_contact(client, jid), do: reply(client, :delete_contact, [jid])
    @impl true
    def download_media(client, ref, opts), do: reply(client, :download_media, [ref, opts])

    defp reply(client, operation, args) do
      send(client.metadata.owner, {:adapter, operation, args})
      client.metadata.reply
    end
  end

  defmodule Events do
    @behaviour ExWapp.Events
    @impl true
    def emit(client, event) do
      send(client.metadata.owner, {:event, event})
      Map.get(client.metadata, :event_result, :ok)
    end
  end

  defp client(reply) do
    ExWapp.new(
      store: ExWapp.Store.Memory,
      transport: Adapter,
      events: Events,
      metadata: %{owner: self(), reply: reply}
    )
  end

  test "connect preserves the adapter's connecting status and returned metadata" do
    initial = client(nil)

    adapter_client = %{
      initial
      | status: :connecting,
        metadata: Map.put(initial.metadata, :socket, 7)
    }

    initial = put_in(initial.metadata.reply, {:ok, adapter_client})

    assert {:ok, connected} = ExWapp.connect(initial)
    assert connected.status == :connecting
    assert connected.metadata.socket == 7
    assert [%{operation: :connect} | _] = connected.trace
    assert_receive {:event, %Event{type: :status, payload: :connecting}}
  end

  for {operation, args} <- [
        pair: [],
        disconnect: [],
        list_contacts: [],
        delete_contact: ["15550001111@s.whatsapp.net"],
        receive_message: [<<1, 2>>, []]
      ] do
    test "#{operation} preserves the transport error in client diagnostics" do
      operation = unquote(operation)
      initial = client({:error, :unavailable})

      args = unquote(Macro.escape(args))

      assert {:error, %Error{} = error, failed} = apply(ExWapp, operation, [initial | args])
      assert error.operation == operation
      assert error.phase == :transport
      assert error.reason == :unavailable
      assert failed.status == :error
      assert ExWapp.diagnostics(failed).last_error == error
      assert [%{operation: ^operation} | _] = failed.trace
      refute_receive {:event, _}
    end
  end

  test "disconnect accepts both successful callback forms" do
    initial = client(:ok)
    assert {:ok, %Client{status: :disconnected}} = ExWapp.disconnect(initial)

    adapter_client = put_in(initial.metadata[:closed], true)
    initial = put_in(initial.metadata.reply, {:ok, adapter_client})
    assert {:ok, disconnected} = ExWapp.disconnect(initial)
    assert disconnected.status == :disconnected
    assert disconnected.metadata.closed
  end

  test "short send replies preserve caller IDs and tolerate a failing event sink" do
    initial =
      client({:ok, "chosen-id"})
      |> put_in([Access.key(:metadata), :event_result], {:error, :sink_down})

    assert {:ok, updated, "chosen-id"} =
             ExWapp.send_message(initial,
               to: "15550001111@s.whatsapp.net",
               text: "hello",
               id: "chosen-id"
             )

    assert_receive {:adapter, :send_message, [%Message{id: "chosen-id", body: "hello"}]}
    assert_receive {:event, %Event{type: :message_sent, payload: %{id: "chosen-id"}}}
    assert hd(updated.trace).metadata.message_id == "chosen-id"
  end

  test "failed sends retain an adapter's updated session state" do
    initial = client(nil)
    adapter_client = put_in(initial.metadata[:recovered_session], :new_session)
    initial = put_in(initial.metadata.reply, {:error, adapter_client, :not_connected})

    assert {:error, %Error{operation: :send_message, reason: :not_connected}, failed} =
             ExWapp.send_message(initial, to: "15550001111@s.whatsapp.net", text: "hello")

    assert failed.metadata.recovered_session == :new_session
    refute_receive {:event, %Event{type: :message_sent}}
  end

  test "short inbound replies emit each event and record their count" do
    events = [Event.new(:status, :connected), Event.new(:message_received, %{text: "hi"})]
    initial = client({:ok, events})

    assert {:ok, updated, ^events} = ExWapp.receive_message(initial, "payload", source: :socket)
    assert_receive {:adapter, :receive_message, ["payload", [source: :socket]]}
    for event <- events, do: assert_receive({:event, ^event})
    assert hd(updated.trace).metadata.event_count == 2
  end

  test "optional read and mutation callbacks return structured unsupported errors" do
    initial = client(nil)

    for {operation, args} <- [list_calls: [[]], sync_contacts: []] do
      assert {:error, %Error{reason: :unsupported_operation, operation: ^operation}, failed} =
               apply(ExWapp, operation, [initial | args])

      assert failed.status == :error
    end
  end

  test "a successful short mutation reply emits its event and adds a trace" do
    assert {:ok, updated} = ExWapp.delete_contact(client(:ok), "15550001111@s.whatsapp.net")
    assert_receive {:event, %Event{type: :contact_deleted}}
    assert hd(updated.trace).operation == :delete_contact
  end

  test "download accepts both success forms without losing reference or metadata" do
    ref = %Media.Ref{type: :image, mimetype: "image/png"}
    download = %Media.Download{ref: ref, bytes: <<0, 255>>, mimetype: ref.mimetype}
    initial = client({:ok, download})

    assert {:ok, updated, ^download} = ExWapp.download_media(initial, ref, cache: false)
    assert_receive {:adapter, :download_media, [^ref, [cache: false]]}
    assert hd(updated.trace).operation == :download_media

    adapter_client = put_in(initial.metadata[:cached], true)
    initial = put_in(initial.metadata.reply, {:ok, adapter_client, download})
    assert {:ok, updated, ^download} = ExWapp.download_media(initial, ref)
    assert updated.metadata.cached
  end

  test "download failure and missing callback use the same structured error contract" do
    ref = %Media.Ref{type: :image}
    initial = client({:error, :invalid_media_hmac})
    assert {:error, %Error{reason: :invalid_media_hmac}, _} = ExWapp.download_media(initial, ref)

    assert {:error, %Error{reason: :unsupported_operation}, _} =
             ExWapp.download_media(%{initial | transport: ExWapp.Events.Noop}, ref)
  end

  test "document, location, contact and event APIs retain their typed payloads" do
    initial = client({:ok, "media-id"})
    jid = "15550001111@s.whatsapp.net"

    for {operation, args, type} <- [
          {:send_document, [jid, {:bytes, "pdf"}, [file_name: "report.pdf"]], :document},
          {:send_location, [jid, 45.0, 9.0, [name: "Office"]], :location},
          {:send_contact, [jid, "Alice", "BEGIN:VCARD\nEND:VCARD", []], :contact},
          {:send_event, [jid, "Meeting", 1_800_000_000, []], :event}
        ] do
      assert {:ok, updated, "media-id"} = apply(ExWapp, operation, [initial | args])
      assert_receive {:adapter, :send_message, [%Message{to: ^jid, type: ^type} = message]}
      assert message.body != nil
      assert hd(updated.trace).operation == operation
    end
  end
end
