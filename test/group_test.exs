defmodule ExWapp.Session.Outbound.GroupTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Session.Outbound.Group
  alias ExWapp.Store.Memory

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

  test "expands every PN group participant and local identity to all devices" do
    store = Memory.new(initial_data: %{})
    own_base_jid = "15550009999@s.whatsapp.net"
    own_lid_jid = "90000009999@lid"
    own_current_device_jid = "15550009999:5@s.whatsapp.net"
    own_linked_device_jid = "15550009999:91@s.whatsapp.net"
    first_participant = "15550001111@s.whatsapp.net"
    first_linked_device = "15550001111:17@s.whatsapp.net"
    second_participant = "15550002222@s.whatsapp.net"
    second_linked_device = "15550002222:45@s.whatsapp.net"

    query_jids = [first_participant, second_participant, own_base_jid]

    device_map = %{
      first_participant => [first_participant, first_linked_device],
      second_participant => [second_participant, second_linked_device],
      own_base_jid => [own_base_jid, own_current_device_jid, own_linked_device_jid]
    }

    assert {live_targets, []} =
             Group.distribution_targets(
               query_jids,
               device_map,
               "pn",
               5,
               own_base_jid,
               own_lid_jid,
               store,
               %{}
             )

    assert Enum.sort(live_targets) ==
             Enum.sort([
               first_participant,
               first_linked_device,
               second_participant,
               second_linked_device,
               own_base_jid,
               own_linked_device_jid
             ])

    refute own_current_device_jid in live_targets
  end

  test "expands every LID group participant and local identity to all devices" do
    store = Memory.new(initial_data: %{})
    own_base_jid = "15550009999@s.whatsapp.net"
    own_lid_jid = "90000009999@lid"
    own_current_device_jid = "90000009999:5@lid"
    own_linked_device_jid = "90000009999:91@lid"
    first_participant = "90000001111@lid"
    first_linked_device = "90000001111:17@lid"
    second_participant = "90000002222@lid"
    second_linked_device = "90000002222:45@lid"

    query_jids = [first_participant, second_participant, own_lid_jid]

    device_map = %{
      first_participant => [first_participant, first_linked_device],
      second_participant => [second_participant, second_linked_device],
      own_lid_jid => [own_lid_jid, own_current_device_jid, own_linked_device_jid]
    }

    assert {live_targets, []} =
             Group.distribution_targets(
               query_jids,
               device_map,
               "lid",
               5,
               own_base_jid,
               own_lid_jid,
               store,
               %{}
             )

    assert Enum.sort(live_targets) ==
             Enum.sort([
               first_participant,
               first_linked_device,
               second_participant,
               second_linked_device,
               own_lid_jid,
               own_linked_device_jid
             ])

    refute own_current_device_jid in live_targets
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
