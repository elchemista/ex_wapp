defmodule ExWapp.StatusProtocolTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias ExWapp.{Binary, JID, MessageHandler}
  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.Ack

  test "wire-decoded newsletter status retains its ACK and redacts the channel address" do
    node =
      %Node{
        tag: "status",
        attrs: %{"from" => "120363000000001@newsletter", "id" => "newsletter-status"},
        content: [%Node{tag: "picture"}]
      }
      |> Binary.encode!()
      |> Binary.decode!()

    assert %JID{} = node.attrs["from"]
    state = %{stats: %{messages_received: 2}}

    log =
      capture_log(fn ->
        assert {:ok, ^state} = MessageHandler.handle_node(node, self(), state)
      end)

    assert log =~ "newsletter?=true"
    assert log =~ "picture"
    refute log =~ "120363000000001"
    refute log =~ "newsletter-status"
    assert {:ok, %Node{tag: "ack", attrs: attrs}} = Ack.build_immediate_ack(node)
    assert attrs["class"] == "status"
    assert attrs["id"] == node.attrs["id"]
    assert attrs["to"] == JID.to_string(node.attrs["from"])
  end

  test "status without child nodes is recorded without changing application state" do
    node = %Node{tag: "status", attrs: %{"from" => "status@broadcast"}}
    state = %{stats: %{}}

    log =
      capture_log(fn ->
        assert {:ok, ^state} = MessageHandler.handle_node(node, self(), state)
      end)

    assert log =~ "newsletter?=false"
    assert log =~ "children=[]"
  end

  test "presence and chatstate accept decoded JIDs and preserve session state" do
    state = %{stats: %{messages_received: 3}}

    for {tag, content, expected} <- [
          {"presence", nil, "type=available"},
          {"chatstate", [%Node{tag: "composing"}], "state=typing"},
          {"chatstate", [%Node{tag: "paused"}], "state=stopped"},
          {"chatstate", nil, "state=unknown"}
        ] do
      node =
        %Node{tag: tag, attrs: %{"from" => "70000001111@lid"}, content: content}
        |> Binary.encode!()
        |> Binary.decode!()

      log =
        capture_log(fn ->
          assert {:ok, ^state} = MessageHandler.handle_node(node, self(), state)
        end)

      assert log =~ expected
      refute log =~ "70000001111"
    end
  end
end
