defmodule ExWapp.Session.Outbound.GroupTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Session.Outbound.Group

  test "builds group USync JIDs with the addressing-mode local identity" do
    assert Group.query_jids(
             ["15550001111:5@s.whatsapp.net", nil, ""],
             "lid",
             "15550009999@s.whatsapp.net",
             "90000000001:32@lid"
           ) == [
             "15550001111@s.whatsapp.net",
             "90000000001@lid"
           ]
  end

  test "builds the interactive group information query" do
    node = Group.build_info_query("15550000000:3@g.us", "request-id")

    assert %Binary.Node{
             tag: "iq",
             attrs: %{
               "id" => "request-id",
               "to" => "15550000000@g.us",
               "type" => "get",
               "xmlns" => "w:g2"
             },
             content: [
               %Binary.Node{
                 tag: "query",
                 attrs: %{"request" => "interactive"},
                 content: nil
               }
             ]
           } = node
  end

  test "parses group participants using the response addressing mode" do
    group_jid = "15550000000@g.us"

    response = %Binary.Node{
      tag: "iq",
      attrs: %{"type" => "result"},
      content: [
        %Binary.Node{
          tag: "group",
          attrs: %{"addressing_mode" => "lid"},
          content: [
            %Binary.Node{
              tag: "participant",
              attrs: %{
                "jid" => "15550001111@s.whatsapp.net",
                "lid" => "90000000001:5@lid"
              },
              content: nil
            },
            %Binary.Node{
              tag: "participant",
              attrs: %{"jid" => group_jid},
              content: nil
            }
          ]
        }
      ]
    }

    assert Group.parse_info_response(response, group_jid) ==
             {:ok,
              %{
                participants: ["90000000001@lid"],
                addressing_mode: "lid"
              }}
  end

  test "builds a group message with participants, phash, and skmsg payload" do
    participant = %Binary.Node{
      tag: "to",
      attrs: %{"jid" => "15550001111:5@s.whatsapp.net"},
      content: []
    }

    node =
      Group.build_encrypted_message_node(
        "15550000000:3@g.us",
        "message-id",
        [participant],
        <<1, 2, 3>>,
        "pn",
        :unused_store,
        false
      )

    assert %Binary.Node{
             tag: "message",
             attrs: %{
               "id" => "message-id",
               "to" => "15550000000@g.us",
               "type" => "text",
               "addressing_mode" => "pn",
               "phash" => "2:" <> _
             },
             content: [
               %Binary.Node{tag: "participants", content: [^participant]},
               %Binary.Node{
                 tag: "enc",
                 attrs: %{"v" => "2", "type" => "skmsg"}
               }
             ]
           } = node
  end
end
