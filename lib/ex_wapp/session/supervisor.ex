defmodule ExWapp.Session.Supervisor do
  @moduledoc """
  DynamicSupervisor for managing multiple WhatsApp sessions.

  This supervisor can start, stop, and manage multiple sessions dynamically.
  Each session is identified by a unique session ID and can be looked up
  via the built-in Registry.

  ## Starting the Supervisor

  Add to your application supervision tree:

      children = [
        ExWapp.Session.Supervisor
      ]

      Supervisor.start_link(children, strategy: :one_for_one)

  Or start manually:

      {:ok, _pid} = ExWapp.Session.Supervisor.start_link()

  ## Managing Sessions

      # Start a new session
      {:ok, session} = ExWapp.Session.Supervisor.start_session("user_123",
        store: {ExWapp.Store.Ets, path: "/data/user_123.etf"}
      )

      # Look up an existing session
      {:ok, session} = ExWapp.Session.Supervisor.get_session("user_123")

      # List all sessions
      sessions = ExWapp.Session.Supervisor.list_sessions()
      #=> [{"user_123", #PID<0.234.0>}, {"user_456", #PID<0.267.0>}]

      # Stop a session
      :ok = ExWapp.Session.Supervisor.stop_session("user_123")

  ## Session IDs

  Session IDs can be any term but strings are recommended. Common patterns:
  - User ID: `"user_123"`
  - Phone number: `"+1234567890"`
  - UUID: `"550e8400-e29b-41d4-a716-446655440000"`
  """

  use DynamicSupervisor

  alias ExWapp.Session.Options

  @registry ExWapp.Session.Registry
  @supervisor __MODULE__

  # Supervisor lifecycle

  @doc """
  Starts the session supervisor.

  This also starts the Registry for session lookup.
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, @supervisor)
    DynamicSupervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Returns the child specification for use in a supervision tree.
  """
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  # Starting and locating sessions

  @doc """
  Starts a new session with the given ID.

  Returns `{:ok, pid}` if successful, or `{:error, reason}` if the session
  could not be started or already exists.

  ## Options

    * `:store` - Storage adapter (see `ExWapp.Store`)
    * `:auto_connect` - Connect automatically on start (default: false)
    * `:reconnect` - Enable automatic reconnection (default: true)
    * `:runtime` - Runtime hardening config override for this session

  ## Examples

      {:ok, session} = ExWapp.Session.Supervisor.start_session("user_123",
        store: {ExWapp.Store.Ets, path: "/data/sessions/user_123.etf"}
      )

      # With auto-connect
      {:ok, session} = ExWapp.Session.Supervisor.start_session("user_456",
        store: ExWapp.Store.Memory,
        auto_connect: true
      )
  """
  @spec start_session(term(), keyword() | Options.t()) :: {:ok, pid()} | {:error, term()}
  def start_session(session_id, opts \\ []) do
    case get_session(session_id) do
      {:ok, pid} ->
        {:error, {:already_started, pid}}

      :error ->
        with {:ok, options} <- Options.with_session_id(opts, session_id) do
          start_session_child(session_id, options)
        end
    end
  end

  defp start_session_child(session_id, options) do
    child_spec = %{
      id: session_id,
      start: {ExWapp.Session, :start_link, [options]},
      restart: :transient
    }

    DynamicSupervisor.start_child(@supervisor, child_spec)
  end

  @doc """
  Stops a session by ID.

  Returns `:ok` if the session was stopped, or `{:error, :not_found}` if
  no session with that ID exists.
  """
  @spec stop_session(term()) :: :ok | {:error, :not_found}
  def stop_session(session_id) do
    case get_session(session_id) do
      {:ok, pid} ->
        DynamicSupervisor.terminate_child(@supervisor, pid)
        :ok

      :error ->
        {:error, :not_found}
    end
  end

  @doc """
  Stops all live sessions for the given ID.
  """
  @spec stop_all_sessions(term()) :: :ok
  def stop_all_sessions(session_id) do
    session_id
    |> get_live_sessions()
    |> Enum.each(&DynamicSupervisor.terminate_child(@supervisor, &1))

    :ok
  end

  @doc """
  Looks up a session by ID.

  Returns `{:ok, pid}` if found, or `:error` if not found.
  """
  @spec get_session(term()) :: {:ok, pid()} | :error
  def get_session(session_id) do
    case Registry.lookup(@registry, session_id) do
      [{pid, _}] when is_pid(pid) ->
        if Process.alive?(pid), do: {:ok, pid}, else: :error

      [] ->
        :error
    end
  end

  @doc """
  Returns all live session pids matching a session ID.
  """
  @spec get_live_sessions(term()) :: [pid()]
  def get_live_sessions(session_id) do
    @registry
    |> Registry.lookup(session_id)
    |> Enum.map(fn {pid, _} -> pid end)
    |> Enum.filter(&Process.alive?/1)
  end

  @doc """
  Returns a list of all active sessions.

  Returns a list of `{session_id, pid}` tuples.
  """
  @spec list_sessions() :: [{term(), pid()}]
  def list_sessions do
    @registry
    |> Registry.select([{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
    |> Enum.filter(fn {_id, pid} -> Process.alive?(pid) end)
  end

  @doc """
  Returns the count of active sessions.
  """
  @spec count_sessions() :: non_neg_integer()
  def count_sessions do
    DynamicSupervisor.count_children(@supervisor).active
  end

  @doc """
  Checks if a session exists.
  """
  @spec session_exists?(term()) :: boolean()
  def session_exists?(session_id) do
    case get_session(session_id) do
      {:ok, _} -> true
      :error -> false
    end
  end
end
