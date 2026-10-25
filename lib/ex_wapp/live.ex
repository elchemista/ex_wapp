defmodule ExWapp.Live do
  @moduledoc """
  Manual integration helper for running a real WhatsApp Web session in IEx.

  This module is intentionally side-effectful and focused on debugging:
  - connect + pair (QR saved to disk)
  - send messages
  - list chats and groups
  - read stored chat messages
  - wait for new incoming messages from the running session
  """

  alias ExWapp.Session.Supervisor, as: SessionSupervisor
  alias ExWapp.Store

  @default_store_path "/tmp/ex_wapp/live_test_session.etf"
  @default_qr_path "/tmp/whatsapp_qr.svg"
  @default_multi_store_dir "/tmp/ex_wapp/sessions"
  @default_multi_qr_dir "/tmp/ex_wapp/qr"
  @default_pair_timeout_ms 15_000
  @default_connect_timeout_ms 15_000
  @default_sync_wait_ms 15_000
  @default_session_name ExWapp.Live.Session

  @doc """
  Runs a live session flow (connect + pair if needed), then returns
  the session and currently known chats/groups.

  Options:
  - `:store_path` persisted store path (default: `#{@default_store_path}`)
  - `:qr_path` rendered QR output path (default: `#{@default_qr_path}`)
  - `:qr_renderer` module implementing `ExWapp.QR.Renderer`, defaults to
    `config :ex_wapp, :qr_renderer` (required when pairing is needed)
  - `:qr_options` options passed to the renderer (default: `[]`)
  - `:pair_timeout_ms` QR pairing timeout (default: `#{@default_pair_timeout_ms}`)
  - `:connect_timeout_ms` connect timeout (default: `#{@default_connect_timeout_ms}`)
  - `:sync_wait_ms` wait after connect before reading chats (default: `#{@default_sync_wait_ms}`)
  - `:name` optional GenServer name (default: `#{inspect(@default_session_name)}`)
  - `:replace_existing` stop existing named session before start (default: `true`)

  To run multiple sessions safely, use `run_session/2`.
  """
  @spec run(keyword()) :: {:ok, map()} | {:error, term()}
  def run(opts \\ []) do
    case Keyword.fetch(opts, :session_id) do
      {:ok, session_id} ->
        run_session(session_id, Keyword.delete(opts, :session_id))

      :error ->
        run_single_session(opts)
    end
  end

  @doc """
  Runs a supervised multi-session flow keyed by `session_id`.

  This is the preferred way to run multiple sessions concurrently.
  Each session should use a unique store file to avoid stream conflicts.

  Options:
  - `:store_path` defaults to `#{@default_multi_store_dir}/<session_id>.etf`
  - `:qr_path` defaults to `#{@default_multi_qr_dir}/<session_id>.svg`
  - `:qr_renderer` module implementing `ExWapp.QR.Renderer`, defaults to
    `config :ex_wapp, :qr_renderer` (required when pairing is needed)
  - `:qr_options` options passed to the renderer (default: `[]`)
  - `:pair_timeout_ms` QR pairing timeout (default: `#{@default_pair_timeout_ms}`)
  - `:connect_timeout_ms` connect timeout (default: `#{@default_connect_timeout_ms}`)
  - `:sync_wait_ms` wait after connect before reading chats (default: `#{@default_sync_wait_ms}`)
  - `:replace_existing` stop existing session with same `session_id` before start (default: `true`)
  """
  @spec run_session(term(), keyword()) :: {:ok, map()} | {:error, term()}
  def run_session(session_id, opts \\ []) do
    store_path =
      opts
      |> Keyword.get(:store_path, default_session_store_path(session_id))
      |> expand_path()

    qr_path =
      opts
      |> Keyword.get(:qr_path, default_session_qr_path(session_id))
      |> expand_path()

    pair_timeout_ms = Keyword.get(opts, :pair_timeout_ms, @default_pair_timeout_ms)
    connect_timeout_ms = Keyword.get(opts, :connect_timeout_ms, @default_connect_timeout_ms)
    sync_wait_ms = Keyword.get(opts, :sync_wait_ms, @default_sync_wait_ms)
    replace_existing = Keyword.get(opts, :replace_existing, true)

    File.mkdir_p!(Path.dirname(store_path))
    File.mkdir_p!(Path.dirname(qr_path))
    IO.puts("Session ID: #{inspect(session_id)}")
    IO.puts("Store path: #{store_path}")
    IO.puts("QR path: #{qr_path}")

    with :ok <- maybe_stop_existing_supervised_session(session_id, replace_existing),
         :ok <- ensure_store_path_available(store_path, session_id),
         {:ok, session} <- start_supervised_session(session_id, store_path),
         :ok <- ExWapp.connect(session),
         :ok <- maybe_wait_for_pairing(session, qr_output(qr_path, opts), pair_timeout_ms),
         :ok <- wait_until_connected(session, connect_timeout_ms) do
      if sync_wait_ms > 0 do
        Process.sleep(sync_wait_ms)
      end

      with :ok <- ensure_session_connected(session) do
        chats = list_chats(session)
        groups = ExWapp.list_groups(session)
        print_chats(chats)
        print_groups(groups)

        {:ok,
         %{
           session_id: session_id,
           session: session,
           store_path: store_path,
           qr_path: qr_path,
           chats: chats,
           groups: groups
         }}
      end
    end
  end

  @doc """
  Stops a supervised session started with `run_session/2`.
  """
  @spec stop_session(term()) :: :ok | {:error, :not_found}
  def stop_session(session_id), do: SessionSupervisor.stop_session(session_id)

  @doc """
  Lists supervised session IDs and their PIDs.
  """
  @spec list_sessions() :: [{term(), pid()}]
  def list_sessions, do: SessionSupervisor.list_sessions()

  defp run_single_session(opts) do
    store_path = opts |> Keyword.get(:store_path, @default_store_path) |> expand_path()
    qr_path = opts |> Keyword.get(:qr_path, @default_qr_path) |> expand_path()
    pair_timeout_ms = Keyword.get(opts, :pair_timeout_ms, @default_pair_timeout_ms)
    connect_timeout_ms = Keyword.get(opts, :connect_timeout_ms, @default_connect_timeout_ms)
    sync_wait_ms = Keyword.get(opts, :sync_wait_ms, @default_sync_wait_ms)
    name = Keyword.get(opts, :name, @default_session_name)
    replace_existing = Keyword.get(opts, :replace_existing, true)

    File.mkdir_p!(Path.dirname(store_path))
    File.mkdir_p!(Path.dirname(qr_path))
    IO.puts("Store path: #{store_path}")
    IO.puts("QR path: #{qr_path}")

    with :ok <- maybe_stop_existing_named_session(name, replace_existing),
         {:ok, session} <- start_live_session(store_path, name),
         :ok <- ExWapp.connect(session),
         :ok <- maybe_wait_for_pairing(session, qr_output(qr_path, opts), pair_timeout_ms),
         :ok <- wait_until_connected(session, connect_timeout_ms) do
      if sync_wait_ms > 0 do
        Process.sleep(sync_wait_ms)
      end

      with :ok <- ensure_session_connected(session) do
        chats = list_chats(session)
        groups = ExWapp.list_groups(session)
        print_chats(chats)
        print_groups(groups)

        {:ok,
         %{
           session: session,
           session_name: name,
           store_path: store_path,
           qr_path: qr_path,
           chats: chats,
           groups: groups
         }}
      end
    end
  end

  @doc """
  Sends a text message to a user or group JID.
  """
  @spec send_message(pid(), String.t(), iodata()) :: {:ok, String.t()} | {:error, term()}
  def send_message(session, jid, text) when is_pid(session) and is_binary(jid) do
    ExWapp.send_message(session, jid, IO.iodata_to_binary(text))
  end

  @doc """
  Returns currently known chats from local storage.
  """
  @spec list_chats(pid()) :: [ExWapp.Chat.chat()]
  def list_chats(session) when is_pid(session), do: ExWapp.list_chats(session)

  @doc """
  Returns currently known groups from local chat storage for this session.
  """
  @spec list_groups(pid()) :: [ExWapp.Chat.chat()]
  def list_groups(session) when is_pid(session), do: ExWapp.list_groups(session)

  @doc """
  Returns the locally stored call log for this session, newest first.
  """
  @spec list_calls(pid(), keyword()) :: [ExWapp.Call.t()]
  def list_calls(session, opts \\ []) when is_pid(session), do: ExWapp.list_calls(session, opts)

  @doc """
  Returns stored messages for a specific chat JID.
  """
  @spec get_messages(pid(), String.t(), keyword()) :: [ExWapp.Chat.message()]
  def get_messages(session, jid, opts \\ []) when is_pid(session) and is_binary(jid) do
    ExWapp.get_messages(session, jid, opts)
  end

  defp qr_output(path, opts) do
    %{
      path: path,
      renderer: Keyword.get(opts, :qr_renderer, Application.get_env(:ex_wapp, :qr_renderer)),
      options: Keyword.get(opts, :qr_options, [])
    }
  end

  defp maybe_wait_for_pairing(session, qr_output, timeout_ms) do
    if paired?(session) do
      IO.puts("Stored pairing found, skipping QR wait.")
      :ok
    else
      wait_for_pairing(session, qr_output, timeout_ms)
    end
  end

  defp wait_for_pairing(session, qr_output, timeout_ms) do
    started_at = System.monotonic_time(:millisecond)

    session
    |> ExWapp.qr_stream()
    |> Enum.reduce_while(:waiting, fn event, _acc ->
      elapsed = System.monotonic_time(:millisecond) - started_at
      handle_pairing_event(event, elapsed, timeout_ms, qr_output)
    end)
  end

  defp handle_pairing_event(_event, elapsed, timeout_ms, _qr_path) when elapsed >= timeout_ms do
    {:halt, {:error, :pair_timeout}}
  end

  defp handle_pairing_event({:code, code}, _elapsed, _timeout_ms, qr_output) do
    case save_qr(code, qr_output) do
      :ok ->
        IO.puts("QR updated: #{qr_output.path} (exists? #{File.exists?(qr_output.path)})")
        {:cont, :waiting}

      {:error, _reason} = error ->
        {:halt, error}
    end
  end

  defp handle_pairing_event(:success, _elapsed, _timeout_ms, _qr_path) do
    IO.puts("Pairing complete.")
    {:halt, :ok}
  end

  defp handle_pairing_event({:error, reason}, _elapsed, _timeout_ms, _qr_path) do
    {:halt, {:error, reason}}
  end

  defp wait_until_connected(session, timeout_ms) do
    started_at = System.monotonic_time(:millisecond)
    do_wait_until_connected(session, timeout_ms, started_at)
  end

  defp do_wait_until_connected(session, timeout_ms, started_at) do
    case ExWapp.state(session) do
      :connected ->
        :ok

      state ->
        elapsed = System.monotonic_time(:millisecond) - started_at

        if elapsed >= timeout_ms do
          {:error, {:connect_timeout, state}}
        else
          Process.sleep(500)
          do_wait_until_connected(session, timeout_ms, started_at)
        end
    end
  end

  defp ensure_session_connected(session) do
    case ExWapp.state(session) do
      :connected ->
        :ok

      :idle ->
        {:error, :session_invalid_or_logged_out}

      status ->
        {:error, {:session_not_connected, status}}
    end
  end

  defp paired?(session) do
    store = GenServer.call(session, :get_store)
    data = Store.load!(store)

    case ExWapp.MapPath.get(data, ["pairing", "device", "jid"]) do
      nil -> false
      _jid -> true
    end
  rescue
    _ -> false
  end

  defp print_chats([]) do
    IO.puts("No chats found in local store yet.")
    :ok
  end

  defp print_chats(chats) do
    IO.puts("Chats:")

    chats
    |> Enum.with_index(1)
    |> Enum.each(fn {chat, idx} ->
      label = chat.name || chat.jid
      unread = chat.unread_count || 0
      IO.puts("#{idx}. #{label} (unread: #{unread})")
    end)

    :ok
  end

  defp print_groups([]) do
    IO.puts("No groups found in local chat store yet.")
    :ok
  end

  defp print_groups(groups) do
    IO.puts("Groups:")

    groups
    |> Enum.with_index(1)
    |> Enum.each(fn {group, idx} ->
      label = group.name || "(no subject)"
      IO.puts("#{idx}. #{label} [#{group.jid}]")
    end)

    :ok
  end

  defp save_qr(_code, %{renderer: nil}), do: {:error, :qr_renderer_not_configured}

  defp save_qr(code, %{renderer: renderer, options: opts, path: path}) when is_binary(code) do
    if is_atom(renderer) and Code.ensure_loaded?(renderer) and
         function_exported?(renderer, :render, 2) do
      write_qr(renderer.render(code, opts), path)
    else
      {:error, {:invalid_qr_renderer, renderer}}
    end
  rescue
    exception -> {:error, exception}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp write_qr({:ok, data}, path) do
    binary = IO.iodata_to_binary(data)
    File.write(path, binary)
  rescue
    ArgumentError -> {:error, :invalid_qr_renderer_response}
  end

  defp write_qr({:error, _reason} = error, _path), do: error
  defp write_qr(_other, _path), do: {:error, :invalid_qr_renderer_response}

  defp maybe_stop_existing_named_session(name, true) when is_atom(name) do
    case Process.whereis(name) do
      nil ->
        :ok

      pid ->
        try do
          ExWapp.disconnect(pid)
        catch
          _, _ -> :ok
        end

        try do
          GenServer.stop(pid, :normal, 5_000)
        catch
          _, _ -> :ok
        end

        :ok
    end
  end

  defp maybe_stop_existing_named_session(_name, _replace_existing), do: :ok

  defp start_live_session(store_path, name) do
    opts = [store: {ExWapp.Store.Ets, path: store_path}]
    opts = if name, do: Keyword.put(opts, :name, name), else: opts

    case ExWapp.start_link(opts) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      other ->
        other
    end
  end

  defp maybe_stop_existing_supervised_session(session_id, true) do
    case SessionSupervisor.get_session(session_id) do
      {:ok, pid} ->
        try do
          ExWapp.disconnect(pid)
        catch
          _, _ -> :ok
        end

        SessionSupervisor.stop_session(session_id)

      :error ->
        :ok
    end
  end

  defp maybe_stop_existing_supervised_session(_session_id, _replace_existing), do: :ok

  defp start_supervised_session(session_id, store_path) do
    case SessionSupervisor.start_session(session_id, store: {ExWapp.Store.Ets, path: store_path}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      other -> other
    end
  end

  defp ensure_store_path_available(store_path, current_session_id) do
    normalized = Path.expand(store_path)

    conflict =
      SessionSupervisor.list_sessions()
      |> Enum.find(fn {session_id, pid} ->
        session_id != current_session_id and session_store_path(pid) == normalized
      end)

    case conflict do
      {session_id, _pid} ->
        {:error, {:store_path_in_use, normalized, session_id}}

      nil ->
        :ok
    end
  end

  defp session_store_path(pid) when is_pid(pid) do
    store = GenServer.call(pid, :get_store)

    case store do
      %ExWapp.Store.Ets{path: path} when is_binary(path) -> Path.expand(path)
      _ -> nil
    end
  rescue
    _ -> nil
  catch
    :exit, _ -> nil
  end

  defp default_session_store_path(session_id) do
    Path.join(@default_multi_store_dir, "#{session_slug(session_id)}.etf")
  end

  defp default_session_qr_path(session_id) do
    Path.join(@default_multi_qr_dir, "#{session_slug(session_id)}.svg")
  end

  defp session_slug(session_id) do
    session_id
    |> inspect()
    |> String.replace(~r/[^a-zA-Z0-9._-]/u, "_")
  end

  defp expand_path(path) when is_binary(path) do
    if Path.type(path) == :absolute do
      path
    else
      Path.expand(path, File.cwd!())
    end
  end
end
