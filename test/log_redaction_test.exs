defmodule ExWapp.LogRedactionTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias ExWapp.{Binary, Noise, Store}
  alias ExWapp.Session.Worker.NodeHandler
  alias ExWapp.Store.Memory

  setup do
    previous_level = Logger.level()
    Logger.configure(level: :debug)
    on_exit(fn -> Logger.configure(level: previous_level) end)
    :ok
  end

  test "QR actions log only payload size" do
    secret = "qr-secret-#{System.unique_integer([:positive])}"

    log =
      capture_log([level: :debug], fn ->
        :ok =
          NodeHandler.safe_handle_action(
            {:qr, secret},
            %{session_id: "redaction-test", qr_subscribers: %{}}
          )
      end)

    assert log =~ "bytes: #{byte_size(secret)}"
    refute log =~ secret
  end

  test "connection-message logs omit node values and filter sensitive attrs" do
    secret = "media-auth-secret-#{System.unique_integer([:positive])}"
    {:ok, session} = ExWapp.start_link(store: Memory)

    node = %Binary.Node{
      tag: "redaction-probe",
      attrs: %{"auth" => secret, "companion_enc_static" => secret},
      content: nil
    }

    log =
      capture_log([level: :debug], fn ->
        send(session, {:connection_event, {:connection_message, node}})
        Process.sleep(100)
      end)

    assert log =~ "[FILTERED]"
    refute log =~ secret

    GenServer.stop(session)
  end

  test "Noise initialization never logs the private static key" do
    store = Memory.new()

    log =
      capture_log([level: :debug], fn ->
        assert {:ok, _client_hello, _noise} = Noise.init(store: store)
      end)

    private_key = store |> Store.load!() |> get_in([:noise, :static_private])

    assert is_binary(private_key)
    refute log =~ inspect(private_key)
    refute log =~ Base.encode16(private_key, case: :lower)
  end
end
