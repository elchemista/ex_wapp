defmodule ExWappTest do
  use ExUnit.Case, async: true

  test "qr stream relays pairing events" do
    {:ok, session} = ExWapp.start_link()

    task =
      Task.async(fn ->
        ExWapp.qr_stream(session)
        |> Enum.take(1)
      end)

    Process.sleep(10)
    send(session, {:notify_qr, {:code, "dummy"}})

    assert Task.await(task, 1_000) == [{:code, "dummy"}]

    GenServer.stop(session)
  end
end
