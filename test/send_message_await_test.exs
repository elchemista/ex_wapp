defmodule ExWapp.SendMessageAwaitTest do
  use ExUnit.Case, async: true

  alias ExWapp.Error.Ack

  defmodule SessionStub do
    use GenServer
    def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

    @impl true
    def init(opts) do
      if opts.session_id, do: Registry.register(ExWapp.Session.Registry, opts.session_id, nil)
      {:ok, opts}
    end

    @impl true
    def handle_call({:send_message, message}, _from, state) do
      send(state.owner, {:outbound, message})
      for event <- state.events, do: Phoenix.PubSub.broadcast(ExWapp.PubSub, state.topic, event)
      {:reply, state.reply, state}
    end
  end

  for registered <- [true, false], status <- [:sent, :failed] do
    test "waits for #{status} on the #{if registered, do: "registered", else: "global"} delivery topic" do
      error = Ack.classify("403")
      event = {:ex_wapp_delivery, "wire-id", unquote(status), %{error: error}}
      session_id = unquote(registered) && "await-#{System.unique_integer([:positive])}"
      session_id = session_id || nil
      topic = if session_id, do: "ex_wapp:delivery:#{session_id}", else: "ex_wapp:delivery"
      event = if session_id, do: event, else: {"remote-session", event}

      events = [
        {:ex_wapp_delivery, "unrelated", :sent, %{}},
        {"other-session", {:ex_wapp_delivery, "other", :sent, %{}}},
        event
      ]

      session =
        start_supervised!(
          {SessionStub,
           %{
             owner: self(),
             session_id: session_id,
             topic: topic,
             events: events,
             reply: {:ok, "wire-id"}
           }}
        )

      send(self(), :unrelated_mail)
      result = ExWapp.send_message_await(session, "15550001111@s.whatsapp.net", "hello", 500)

      expected =
        if unquote(status) == :sent, do: {:ok, "wire-id"}, else: {:error, {:rejected, error}}

      assert result == expected
      assert_receive {:outbound, %ExWapp.Message{to: "15550001111@s.whatsapp.net", body: "hello"}}
      assert_receive :unrelated_mail
      refute_receive {:ex_wapp_delivery, _, _, _}
      refute_receive {_, {:ex_wapp_delivery, _, _, _}}

      Phoenix.PubSub.broadcast(ExWapp.PubSub, topic, :after_unsubscribe)
      refute_receive :after_unsubscribe
    end
  end

  for {reply, expected} <- [
        {{:ok, "wire-id"}, {:error, :ack_timeout}},
        {{:error, :not_connected}, {:error, :not_connected}}
      ] do
    test "#{inspect(reply)} without a verdict returns #{inspect(expected)} and releases the subscription" do
      session_id = "await-empty-#{System.unique_integer([:positive])}"
      topic = "ex_wapp:delivery:#{session_id}"

      session =
        start_supervised!(
          {SessionStub,
           %{
             owner: self(),
             session_id: session_id,
             topic: topic,
             events: [],
             reply: unquote(Macro.escape(reply))
           }}
        )

      assert ExWapp.send_message_await(session, "15550001111@s.whatsapp.net", "hello", 0) ==
               unquote(Macro.escape(expected))

      Phoenix.PubSub.broadcast(ExWapp.PubSub, topic, :after_unsubscribe)
      refute_receive :after_unsubscribe
    end
  end
end
