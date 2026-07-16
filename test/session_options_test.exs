defmodule ExWapp.Session.OptionsTest do
  use ExUnit.Case, async: true

  alias ExWapp.Session.Options

  defmodule Transport do
  end

  test "projects static client configuration without retaining the client" do
    client =
      ExWapp.new(
        session_id: "options-session",
        store: ExWapp.Store.Memory,
        transport: ExWapp.Client.Transport.Session,
        runtime: [iq: [default_timeout_ms: 1_234]]
      )

    assert {:ok, options} =
             Options.from_client(client,
               transport: Transport,
               auto_connect: true,
               reconnect: false,
               noise: [test_pid: self()],
               runtime: [iq: [prekey_timeout_ms: 5_678]]
             )

    assert %Options{
             session_id: "options-session",
             store: store,
             transport: Transport,
             auto_connect: true,
             reconnect: false,
             noise: [test_pid: test_pid]
           } = options

    assert store == client.store
    assert test_pid == self()
    assert get_in(options.runtime, [:iq, :default_timeout_ms]) == 1_234
    assert get_in(options.runtime, [:iq, :prekey_timeout_ms]) == 5_678
    assert get_in(options.runtime, [:reconnect, :enabled]) == false
    assert get_in(options.runtime, [:canary, :recipients]) == []
    refute Map.has_key?(options, :client)
  end

  test "normalizes legacy session start options once" do
    assert {:ok, options} =
             Options.from_start_options(
               session_id: "legacy-session",
               store: ExWapp.Store.Memory,
               transport: Transport,
               reconnect: false,
               runtime: [health: [check_interval_ms: 12_345]]
             )

    assert options.session_id == "legacy-session"
    assert options.store == ExWapp.Store.Memory
    assert options.transport == Transport
    assert options.reconnect == false
    assert get_in(options.runtime, [:reconnect, :enabled]) == false
    assert get_in(options.runtime, [:health, :check_interval_ms]) == 12_345
  end
end
