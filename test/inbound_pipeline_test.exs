defmodule ExWapp.Message.Handler.Inbound.PipelineTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias ExWapp.Binary.Node
  alias ExWapp.MessageHandler

  defmodule FailingStore do
    @behaviour ExWapp.Store

    defstruct []

    @impl true
    def new(_opts), do: %__MODULE__{}

    @impl true
    def load(_store), do: raise("store unavailable")

    @impl true
    def persist(_store, _data), do: {:error, :store_unavailable}
  end

  test "application persistence failures do not suppress the protocol receipt" do
    node = %Node{
      tag: "message",
      attrs: %{
        "from" => "15550001111@s.whatsapp.net",
        "id" => "message-with-failed-persistence",
        "type" => "text",
        "t" => "1730000000"
      },
      content: [%Node{tag: "body", attrs: %{}, content: "hello"}]
    }

    result =
      capture_log(fn ->
        send(
          self(),
          {:result, MessageHandler.handle_node(node, self(), %{store: %FailingStore{}})}
        )
      end)

    assert result =~ "phase=application_publish failed"

    assert_receive {:result, {:ok, state, actions}}

    assert state.stats == %{errors: 1, messages_received: 1}

    assert actions == [
             {:send_receipt, "15550001111@s.whatsapp.net", "message-with-failed-persistence", nil,
              nil, %{recipient: nil}}
           ]

    refute_received {:new_message, _, _}
  end
end
