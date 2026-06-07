defmodule ExWapp.Session.Worker.NodeHandlerTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Session.Worker.NodeHandler

  test "success node starts post-auth with prekey count, passive iq, and presence" do
    state = %{
      store: ExWapp.Store.Memory.new(initial_data: %{}),
      runtime_cfg: %{},
      pending_iqs: %{},
      stats: %{messages_received: 0, errors: 0},
      prekey_count_query_id: nil,
      prekey_upload_iq_id: nil,
      pending_prekey_upload: [],
      passive_iq_id: nil,
      digest_iq_id: nil,
      post_auth_phase: :idle
    }

    {next_state, actions} =
      NodeHandler.safe_handle_node(%Binary.Node{tag: "success", attrs: %{}, content: nil}, state)

    assert is_binary(next_state.prekey_count_query_id)
    assert is_binary(next_state.passive_iq_id)
    assert next_state.post_auth_phase == :awaiting_prekey_count

    assert [
             :mark_auth_connected,
             {:send_node,
              %Binary.Node{
                tag: "iq",
                attrs: count_attrs
              }},
             {:send_node,
              %Binary.Node{
                tag: "iq",
                attrs: passive_attrs,
                content: [%Binary.Node{tag: "active"}]
              }},
             {:send_node,
              %Binary.Node{
                tag: "presence",
                attrs: %{"type" => "available"},
                content: nil
              }}
           ] = actions

    assert Map.take(count_attrs, ["type", "xmlns", "to"]) == %{
             "type" => "get",
             "xmlns" => "encrypt",
             "to" => "s.whatsapp.net"
           }

    assert Map.take(passive_attrs, ["type", "xmlns", "to"]) == %{
             "type" => "set",
             "xmlns" => "passive",
             "to" => "s.whatsapp.net"
           }
  end

  test "post-auth high-count path does not send a duplicate passive iq" do
    state = %{
      store: ExWapp.Store.Memory.new(initial_data: %{}),
      runtime_cfg: %{},
      pending_iqs: %{},
      stats: %{messages_received: 0, errors: 0},
      prekey_count_query_id: "count-1",
      prekey_upload_iq_id: nil,
      pending_prekey_upload: [],
      passive_iq_id: "passive-1",
      digest_iq_id: nil,
      post_auth_phase: :awaiting_prekey_count,
      pairing: %{store: nil}
    }

    {after_count, count_actions} =
      NodeHandler.safe_handle_node(
        %Binary.Node{
          tag: "iq",
          attrs: %{"type" => "result", "id" => "count-1"},
          content: [%Binary.Node{tag: "count", attrs: %{"value" => "10"}, content: nil}]
        },
        state
      )

    assert after_count.prekey_count_query_id == nil
    assert after_count.post_auth_phase == :awaiting_passive_ack
    assert after_count.passive_iq_id == "passive-1"
    assert count_actions == []

    {after_passive, passive_actions} =
      NodeHandler.safe_handle_node(
        %Binary.Node{
          tag: "iq",
          attrs: %{"type" => "result", "id" => "passive-1"},
          content: nil
        },
        after_count
      )

    assert after_passive.passive_iq_id == nil
    assert after_passive.digest_iq_id == nil
    assert after_passive.post_auth_phase == :complete

    assert [
             {:send_node,
              %Binary.Node{
                tag: "ib",
                content: [%Binary.Node{tag: "unified_session", attrs: %{"id" => id}}]
              }},
             :mark_authenticated
           ] = passive_actions

    assert is_binary(id)
  end

  test "post-auth digest stays opt-in" do
    state = %{
      store: ExWapp.Store.Memory.new(initial_data: %{}),
      runtime_cfg: %{protocol: %{post_auth_digest_enabled: true}},
      pending_iqs: %{},
      stats: %{messages_received: 0, errors: 0},
      prekey_count_query_id: nil,
      prekey_upload_iq_id: nil,
      pending_prekey_upload: [],
      passive_iq_id: "passive-1",
      digest_iq_id: nil,
      post_auth_phase: :awaiting_passive_ack,
      pairing: %{store: nil}
    }

    {after_passive, passive_actions} =
      NodeHandler.safe_handle_node(
        %Binary.Node{
          tag: "iq",
          attrs: %{"type" => "result", "id" => "passive-1"},
          content: nil
        },
        state
      )

    assert is_binary(after_passive.digest_iq_id)
    assert after_passive.post_auth_phase == :awaiting_digest

    assert [
             {:send_node,
              %Binary.Node{
                tag: "iq",
                attrs: %{"type" => "get", "xmlns" => "encrypt", "to" => "s.whatsapp.net"},
                content: [%Binary.Node{tag: "digest"}]
              }}
           ] = passive_actions

    digest_id = after_passive.digest_iq_id

    {after_digest, digest_actions} =
      NodeHandler.safe_handle_node(
        %Binary.Node{
          tag: "iq",
          attrs: %{"type" => "result", "id" => digest_id},
          content: [%Binary.Node{tag: "digest", attrs: %{}, content: nil}]
        },
        after_passive
      )

    assert after_digest.digest_iq_id == nil
    assert after_digest.post_auth_phase == :complete

    assert [
             {:send_node,
              %Binary.Node{
                tag: "ib",
                content: [%Binary.Node{tag: "unified_session", attrs: %{"id" => id}}]
              }},
             :mark_authenticated
           ] = digest_actions

    assert is_binary(id)
  end
end
