Application.ensure_all_started(:logger)
Logger.configure(level: :debug)
Logger.configure_backend(:console, level: :debug)

{:ok, session} = ExWapp.start_link(store: {ExWapp.Store.ETS, path: Path.expand("~/.cache/ex_wapp/debug_session.etf")})

ExWapp.connect(session)

Process.sleep(:infinity)
