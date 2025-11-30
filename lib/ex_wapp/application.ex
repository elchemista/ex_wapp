defmodule ExWapp.Application do
  @moduledoc """
  OTP Application for ExWapp.

  Starts the session supervisor and registry for managing multiple
  WhatsApp sessions.

  ## Starting Automatically

  Add `:ex_wapp` to your application's extra_applications in mix.exs:

      def application do
        [
          extra_applications: [:logger],
          mod: {ExWapp.Application, []}
        ]
      end

  ## Starting Manually

  If you prefer to manage the supervision tree yourself:

      # In your application supervisor
      children = [
        {Registry, keys: :unique, name: ExWapp.Session.Registry},
        ExWapp.Session.Supervisor
      ]

  ## Usage After Starting

      # Start a session
      {:ok, session} = ExWapp.Session.Supervisor.start_session("user_123",
        store: {ExWapp.Store.Ets, path: "/data/user_123.etf"}
      )

      # Connect
      ExWapp.connect(session)
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Registry for session lookup by ID
      {Registry, keys: :unique, name: ExWapp.Session.Registry},
      # DynamicSupervisor for managing session processes
      ExWapp.Session.Supervisor
    ]

    opts = [strategy: :one_for_one, name: ExWapp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
