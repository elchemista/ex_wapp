defmodule ExWapp.SessionHelpersTest do
  use ExUnit.Case, async: false

  defmodule FlushStore do
    @behaviour ExWapp.Store

    defstruct [:agent, :test_pid]

    def new(opts) do
      {:ok, agent} = Agent.start_link(fn -> Keyword.get(opts, :initial_data, %{}) end)
      %__MODULE__{agent: agent, test_pid: Keyword.get(opts, :test_pid)}
    end

    def load(%__MODULE__{agent: agent}), do: {:ok, Agent.get(agent, & &1)}

    def persist(%__MODULE__{agent: agent}, data) when is_map(data) do
      Agent.update(agent, fn _ -> data end)
    end

    def clear(%__MODULE__{agent: agent}) do
      Agent.update(agent, fn _ -> %{} end)
    end

    def flush(%__MODULE__{test_pid: pid}) when is_pid(pid) do
      send(pid, :store_flushed)
      :ok
    end

    def flush(%__MODULE__{}), do: :ok
  end

  defmodule TypingTransport do
    def send_node(pid, node) when is_pid(pid) do
      send(pid, {:sent_node, node})
      :ok
    end
  end

  setup do
    ensure_runtime_started()
    :ok
  end

  test "export_snapshot flushes the store and returns data blob and checksum" do
    session_id = "snapshot_#{System.unique_integer([:positive])}"
    store = FlushStore.new(test_pid: self(), initial_data: %{client_info: %{jid: "a@b"}})

    {:ok, pid} =
      ExWapp.Session.Supervisor.start_session(session_id,
        store: store,
        reconnect: false
      )

    on_exit(fn -> ExWapp.Session.Supervisor.stop_all_sessions(session_id) end)

    assert {:ok, snapshot} = ExWapp.Session.export_snapshot(pid)
    assert_receive :store_flushed
    assert snapshot.data == %{client_info: %{jid: "a@b"}}
    assert is_binary(snapshot.blob)
    assert snapshot.checksum == sha256(snapshot.blob)
  end

  test "flush_store returns the store adapter flush result" do
    session_id = "flush_#{System.unique_integer([:positive])}"
    store = FlushStore.new(test_pid: self())

    {:ok, pid} =
      ExWapp.Session.Supervisor.start_session(session_id,
        store: store,
        reconnect: false
      )

    on_exit(fn -> ExWapp.Session.Supervisor.stop_all_sessions(session_id) end)

    assert :ok = ExWapp.Session.flush_store(pid)
    assert_receive :store_flushed
  end

  test "session worker does not expose app-facing public API wrappers" do
    assert Code.ensure_loaded?(ExWapp.Session.Worker)

    refute function_exported?(ExWapp.Session.Worker, :connect, 1)
    refute function_exported?(ExWapp.Session.Worker, :send_text, 3)
    refute function_exported?(ExWapp.Session.Worker, :send_text, 4)
    refute function_exported?(ExWapp.Session.Worker, :send_image, 4)
    refute function_exported?(ExWapp.Session.Worker, :send_typing, 3)
    refute function_exported?(ExWapp.Session.Worker, :export_snapshot, 1)
  end

  test "send_typing sends chatstate when connected and reports not connected otherwise" do
    session_id = "typing_#{System.unique_integer([:positive])}"

    {:ok, pid} =
      ExWapp.Session.Supervisor.start_session(session_id,
        store:
          {ExWapp.Store.Memory,
           initial_data: %{
             client_info: %{
               jid: "15550009999:4@s.whatsapp.net",
               lid: "999900001111:4@lid"
             }
           }},
        transport: TypingTransport,
        reconnect: false
      )

    on_exit(fn -> ExWapp.Session.Supervisor.stop_all_sessions(session_id) end)

    assert {:error, {:not_connected, :idle}} =
             ExWapp.send_typing(pid, "15550001111@s.whatsapp.net")

    test_pid = self()
    :sys.replace_state(pid, fn state -> %{state | status: :connected, conn: test_pid} end)

    assert :ok = ExWapp.send_typing(pid, "15550001111@s.whatsapp.net")

    assert_receive {:sent_node,
                    %ExWapp.Binary.Node{
                      tag: "chatstate",
                      attrs: %{
                        "from" => "15550009999:4@s.whatsapp.net",
                        "to" => "15550001111@s.whatsapp.net"
                      },
                      content: [%ExWapp.Binary.Node{tag: "composing"}]
                    }}

    assert :ok = ExWapp.send_typing(pid, "777700001111@lid")

    assert_receive {:sent_node,
                    %ExWapp.Binary.Node{
                      tag: "chatstate",
                      attrs: %{
                        "from" => "999900001111:4@lid",
                        "to" => "777700001111@lid"
                      },
                      content: [%ExWapp.Binary.Node{tag: "composing"}]
                    }}
  end

  test "send_typing refuses to emit a chatstate without the local identity" do
    session_id = "typing_missing_identity_#{System.unique_integer([:positive])}"

    {:ok, pid} =
      ExWapp.Session.Supervisor.start_session(session_id,
        store: ExWapp.Store.Memory,
        transport: TypingTransport,
        reconnect: false
      )

    on_exit(fn -> ExWapp.Session.Supervisor.stop_all_sessions(session_id) end)

    test_pid = self()
    :sys.replace_state(pid, fn state -> %{state | status: :connected, conn: test_pid} end)

    assert {:error, :local_identity_unavailable} =
             ExWapp.send_typing(pid, "15550001111@s.whatsapp.net")

    refute_receive {:sent_node, _node}
  end

  test "supervisor live-session helpers handle zero and one runtime" do
    session_id = "owned_#{System.unique_integer([:positive])}"

    assert [] = ExWapp.Session.Supervisor.get_live_sessions(session_id)
    assert :ok = ExWapp.Session.Supervisor.stop_all_sessions(session_id)

    {:ok, pid} =
      ExWapp.Session.Supervisor.start_session(session_id,
        store: ExWapp.Store.Memory,
        reconnect: false
      )

    assert ExWapp.Session.Supervisor.get_live_sessions(session_id) == [pid]
    assert :ok = ExWapp.Session.Supervisor.stop_all_sessions(session_id)
    refute Process.alive?(pid)
    assert [] = ExWapp.Session.Supervisor.get_live_sessions(session_id)
  end

  test "lifecycle event contract stays as raw ExWapp facts" do
    session_id = "events_#{System.unique_integer([:positive])}"
    topic = "ex_wapp:session:#{session_id}"

    :ok = Phoenix.PubSub.subscribe(ExWapp.PubSub, topic)

    events = [
      {:ex_wapp_session, :transport_ready, %{runtime_ref: self()}},
      {:ex_wapp_session, :connected, %{runtime_ref: self()}},
      {:ex_wapp_session, :post_auth_ready, %{runtime_ref: self()}},
      {:ex_wapp_session, :initial_sync, :started, %{collection_names: ["regular_high"]}},
      {:ex_wapp_session, :initial_sync, :progress,
       %{collection_name: "regular_high", index: 1, total_count: 1, status: :completed}},
      {:ex_wapp_session, :initial_sync, :completed, %{success_count: 1}},
      {:ex_wapp_session, :initial_sync, :failed, :boom, %{failures: []}},
      {:ex_wapp_session, :disconnected, :network, %{runtime_ref: self()}},
      {:ex_wapp_session, :error, :logged_out},
      {:ex_wapp_session, :terminated, :normal, %{runtime_ref: self()}}
    ]

    Enum.each(events, fn event ->
      Phoenix.PubSub.broadcast(ExWapp.PubSub, topic, event)
    end)

    for event <- events do
      assert_receive ^event
    end
  end

  defp sha256(blob) do
    :crypto.hash(:sha256, blob)
    |> Base.encode16(case: :lower)
  end

  defp ensure_runtime_started do
    if is_nil(Process.whereis(ExWapp.PubSub)) do
      start_supervised!({Phoenix.PubSub, name: ExWapp.PubSub})
    end

    if is_nil(Process.whereis(ExWapp.Session.Registry)) do
      start_supervised!({Registry, keys: :unique, name: ExWapp.Session.Registry})
    end

    if is_nil(Process.whereis(ExWapp.Session.Supervisor)) do
      start_supervised!(ExWapp.Session.Supervisor)
    end
  end
end
