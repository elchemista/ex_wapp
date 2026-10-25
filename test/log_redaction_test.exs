defmodule ExWapp.LogRedactionTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias ExWapp.{Binary, Noise, Store}
  alias ExWapp.Session.Worker.NodeHandler
  alias ExWapp.Session.Worker.Subscribers
  alias ExWapp.Signal.SessionStore
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

  test "Signal session diagnostics fingerprint JIDs without logging them" do
    jid = "15551234567@s.whatsapp.net"

    log =
      capture_log([level: :debug], fn ->
        SessionStore.put_session(SessionStore.new(), jid, %{ratchet: :test})
      end)

    assert log =~ "[redacted:"
    refute log =~ jid
    refute log =~ "15551234567"
  end

  test "attribute redaction filters identifiers, tokens, and arbitrary text" do
    secret = "private-message-text"
    jid = "15551234567@s.whatsapp.net"

    redacted =
      ExWapp.Log.attrs(%{
        "type" => "message",
        "from" => jid,
        "text" => secret,
        "auth" => "token"
      })
      |> inspect()

    assert redacted =~ "message"
    assert redacted =~ "[FILTERED]"
    refute redacted =~ jid
    refute redacted =~ secret
    refute redacted =~ "token"
  end

  test "message publication logs omit JIDs, IDs, session names, and message text" do
    jid = "15551234567@s.whatsapp.net"
    message_id = "3EB0-private-message-id"
    session_id = "private-account-session"
    text = "this message must never appear in logs"

    log =
      capture_log([level: :debug], fn ->
        :ok =
          Subscribers.notify_message_subscribers(
            %{message_subscribers: %{}, session_id: session_id},
            jid,
            %{id: message_id, text: text}
          )
      end)

    assert log =~ "[redacted:"
    refute log =~ jid
    refute log =~ "15551234567"
    refute log =~ message_id
    refute log =~ session_id
    refute log =~ text
  end

  test "nested error terms keep their shape without exposing binary values" do
    jid = "15551234567@s.whatsapp.net"
    payload = :crypto.strong_rand_bytes(32)
    reason = {:decrypt_failed, jid, %Protox.DecodingError{message: "secret", binary: payload}}

    formatted = ExWapp.Log.reason(reason)

    assert formatted =~ ":decrypt_failed"
    assert formatted =~ "Protox.DecodingError"
    refute formatted =~ jid
    refute formatted =~ inspect(payload)
  end

  test "stream-error diagnostics never print raw attributes or children" do
    secret = "stream-error-secret-#{System.unique_integer([:positive])}@s.whatsapp.net"

    node = %Binary.Node{
      tag: "stream:error",
      attrs: %{"code" => "500", "from" => secret},
      content: [
        %Binary.Node{
          tag: "conflict",
          attrs: %{"type" => secret},
          content: Binary.raw(secret)
        }
      ]
    }

    log =
      capture_log([level: :debug], fn ->
        {_state, _actions} =
          NodeHandler.safe_handle_node(node, %{session_id: "redaction-test", stats: %{}})
      end)

    assert log =~ "Stream error children summary"
    assert log =~ "[FILTERED]"
    refute log =~ secret
  end

  test "diagnostic summaries retain sizes without exposing nested or opaque values" do
    alias ExWapp.Log

    secret = "do-not-log-this"
    assert Log.term_summary(secret) == "binary(bytes=#{byte_size(secret)})"
    assert Log.term_summary([secret]) == "list(length=1)"
    assert Log.term_summary(make_ref()) == "term"

    nested = {:error, {:nested, {:again, {:last, {secret, self()}}}}}
    assert {:error, {:nested, {:again, {:last, :redacted_nested_term}}}} = Log.safe_term(nested)

    assert {:resources, :reference, :function, :term} ==
             Log.safe_term({:resources, make_ref(), fn -> secret end, <<1::1>>})

    assert %{
             count: 2,
             offline: true,
             type: "[FILTERED]",
             code: "[binary:65]",
             class: "[FILTERED]"
           } =
             Log.attrs(%{
               count: 2,
               offline: true,
               type: %{secret: secret},
               code: String.duplicate("x", 65),
               class: secret <> " with spaces"
             })

    assert Log.attrs([secret]) == "[FILTERED]"
  end

  test "plaintext diagnostics require an explicit opt-in and can be disabled again" do
    alias ExWapp.Log
    previous = Application.fetch_env(:ex_wapp, :unsafe_plaintext_logs?)

    on_exit(fn ->
      case previous do
        {:ok, value} -> Application.put_env(:ex_wapp, :unsafe_plaintext_logs?, value)
        :error -> Application.delete_env(:ex_wapp, :unsafe_plaintext_logs?)
      end
    end)

    secret = "private-diagnostic-value"
    Application.put_env(:ex_wapp, :unsafe_plaintext_logs?, true)
    assert Log.reference(secret) == "[plain:#{inspect(secret)}]"
    assert Log.attrs(%{auth: secret}) == %{auth: secret}
    assert Log.attrs([secret]) == [secret]

    Application.put_env(:ex_wapp, :unsafe_plaintext_logs?, false)
    refute Log.reference(secret) =~ secret
    assert Log.attrs(%{auth: secret}) == %{auth: "[FILTERED]"}
    assert Log.attrs([secret]) == "[FILTERED]"
  end
end
