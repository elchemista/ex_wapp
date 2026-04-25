defmodule ExWapp.ExamplesTest do
  use ExUnit.Case, async: false

  test "GenServer session example compiles and exercises high-level client API" do
    Code.compile_file("examples/gen_server_session.ex")
    module = ExWapp.Examples.GenServerSession

    {:ok, pid} =
      apply(module, :start_link, [
        [
          session_id: "example_account",
          store: ExWapp.Store.Memory,
          transport: Module.concat(module, Transport)
        ]
      ])

    assert :ok = apply(module, :connect, [pid])
    assert {:ok, "example-qr-payload"} = apply(module, :pair, [pid])

    assert {:ok, message_id} =
             apply(module, :send_text, [
               pid,
               "15550001111@s.whatsapp.net",
               "hello from example"
             ])

    assert is_binary(message_id)

    assert {:ok, [%ExWapp.Event{type: :message_received}]} =
             apply(module, :receive_payload, [
               pid,
               %{
                 from: "15550001111@s.whatsapp.net",
                 text: "hi"
               }
             ])

    diagnostics = apply(module, :diagnostics, [pid])
    assert diagnostics.status == :pairing
    assert :connect in diagnostics.transport_log
    assert {:pair, "example-qr-payload"} in diagnostics.transport_log
    assert Enum.any?(diagnostics.events, &(&1.type == :message_received))

    GenServer.stop(pid)
  end
end
