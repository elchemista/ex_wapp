Logger.configure(level: :debug)

Code.compile_string(~S"""
defmodule PairOnce do
  @store_path Path.expand("~/.cache/ex_wapp/example_session.etf")

  def run do
    {:ok, session} =
      ExWapp.start_link(store: {ExWapp.Store.ETS, path: @store_path})

    qr_task =
      Task.async(fn ->
        ExWapp.qr_stream(session)
        |> Enum.reduce_while(:ok, fn event, acc ->
          case event do
            {:code, ref} ->
              render_qr(ref)
              {:cont, acc}

            :success ->
              IO.puts("\n\e[32mPaired successfully!\e[0m")
              {:halt, :ok}

            {:error, reason} ->
              IO.inspect(reason, label: "pairing_error")
              {:halt, {:error, reason}}
          end
        end)
      end)

    ExWapp.connect(session)
    Task.await(qr_task, :infinity)
  end

  defp render_qr(ref) do
    IO.write("\e[2J\e[H")
    IO.puts("Scan this code in WhatsApp > Linked Devices:\n")

    ref
    |> EQRCode.encode()
    |> EQRCode.Render.render()
  end
end
""")

case PairOnce.run() do
  :ok -> :ok
  {:error, reason} -> IO.puts("Pairing failed: ") && IO.inspect(reason)
end
