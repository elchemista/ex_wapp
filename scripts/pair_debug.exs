Application.ensure_all_started(:logger)
Logger.configure(level: :debug)
Logger.configure_backend(:console, level: :debug)

store_path = Path.expand("~/.cache/ex_wapp/debug_session.etf")

{:ok, session} =
  ExWapp.start_link(store: {ExWapp.Store.ETS, path: store_path})

Task.start(fn ->
  ExWapp.qr_stream(session)
  |> Enum.each(fn
    {:code, ref} ->
      IO.puts("New QR ref: #{ref}")

    :success ->
      IO.puts("\e[32mPairing successful – credentials persisted in #{store_path}\e[0m")

    {:error, reason} ->
      IO.inspect(reason, label: "pairing_error")
  end)
end)

ExWapp.connect(session)

Process.sleep(:infinity)
