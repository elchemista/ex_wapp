defmodule ExWapp.ValueBoundariesTest do
  use ExUnit.Case, async: true

  alias ExWapp.Client.Transport.Noop
  alias ExWapp.Domains.Media.Source
  alias ExWapp.Noise.HandshakeSecrets
  alias ExWapp.{Client, Error, Event, Media, Message}

  test "structured errors retain context and render with or without a phase" do
    error =
      Error.new(:send_message, :store, :disk_full,
        message_id: "message-1",
        trace_id: "trace-1",
        metadata: %{retryable: true}
      )

    assert error.message_id == "message-1"
    assert error.trace_id == "trace-1"
    assert error.metadata == %{retryable: true}
    assert Exception.message(error) == "ex_wapp send_message store failed: :disk_full"

    assert "ex_wapp connect failed: :timeout" ==
             :connect |> Error.new(nil, :timeout) |> Exception.message()
  end

  test "events accept an explicit clock value and application metadata" do
    at = ~U[2026-08-26 10:00:00Z]

    assert %Event{
             type: :status,
             payload: :connected,
             session_id: "account-1",
             at: ^at,
             metadata: %{source: :test}
           } =
             Event.new(:status, :connected,
               session_id: "account-1",
               at: at,
               metadata: %{source: :test}
             )

    assert %DateTime{} = Event.new(:status, :connected).at
  end

  test "handshake secrets normalize binary-compatible values" do
    attrs = %{
      write_key: "write",
      read_key: ~c"read",
      handshake_hash: "hash",
      handshake_salt: "salt",
      server_static: "static",
      server_certificate: "certificate"
    }

    assert %HandshakeSecrets{read_key: "read", write_key: "write"} =
             HandshakeSecrets.new(attrs)

    assert %HandshakeSecrets{} = HandshakeSecrets.new(Map.to_list(attrs))
  end

  test "handshake secrets reject missing and incompatible fields" do
    valid = [
      write_key: "write",
      read_key: "read",
      handshake_hash: "hash",
      handshake_salt: "salt",
      server_static: "static",
      server_certificate: "certificate"
    ]

    assert_raise KeyError, fn -> HandshakeSecrets.new(Keyword.delete(valid, :read_key)) end

    assert_raise ArgumentError, ~r/expected binary-compatible/, fn ->
      HandshakeSecrets.new(Keyword.put(valid, :write_key, 123))
    end
  end

  @tag :tmp_dir
  test "media sources distinguish bytes, paths, and already uploaded data", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "payload.bin")
    File.write!(path, "from-file")

    assert {:ok, "inline"} = Source.read({:bytes, "inline"})
    assert {:ok, "from-file"} = Source.read({:path, path})
    assert {:error, :already_uploaded} = Source.read(%Media.Upload{})
    assert {:error, {:unsupported_media_source, :invalid}} = Source.read(:invalid)
  end

  test "the default client transport rejects network operations explicitly" do
    client = %Client{}
    message = Message.text("15550001111@s.whatsapp.net", "hello")

    assert {:error, :missing_transport} = Noop.connect(client)
    assert {:error, :missing_transport} = Noop.send_message(client, message)
  end
end
