defmodule ExWapp.Session.Worker.PostAuthTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Binary, Signal, Store}
  alias ExWapp.Session.Worker.PostAuth

  test "prekeys are only persisted after the upload is acknowledged" do
    store = ExWapp.Store.Memory.new(initial_data: %{})
    {:ok, _signal_info, signal_state} = Signal.bootstrap(%{})
    :ok = Store.persist(store, %{signal: signal_state})

    initial_prekey_count =
      store
      |> Store.load!()
      |> get_in([:signal, :prekeys])
      |> map_size()

    state = %{
      store: store,
      runtime_cfg: %{},
      prekey_count_query_id: "count-1",
      prekey_upload_iq_id: nil,
      pending_prekey_upload: [],
      passive_iq_id: "passive-1",
      digest_iq_id: nil,
      post_auth_phase: :awaiting_prekey_count
    }

    build_passive_iq = fn ->
      %Binary.Node{
        tag: "iq",
        attrs: %{
          "id" => "passive-1",
          "xmlns" => "passive",
          "type" => "set",
          "to" => "s.whatsapp.net"
        },
        content: [%Binary.Node{tag: "active", attrs: %{}, content: nil}]
      }
    end

    {after_count, count_actions} =
      PostAuth.handle_prekey_count_response(
        %Binary.Node{
          tag: "iq",
          attrs: %{"type" => "result", "id" => "count-1"},
          content: [%Binary.Node{tag: "count", attrs: %{"value" => "0"}, content: nil}]
        },
        state,
        build_passive_iq
      )

    assert [
             {:send_node,
              %Binary.Node{
                tag: "iq",
                attrs: %{"type" => "set", "xmlns" => "encrypt", "to" => "s.whatsapp.net"}
              }}
           ] = count_actions

    assert is_binary(after_count.prekey_upload_iq_id)
    assert after_count.passive_iq_id == "passive-1"
    assert length(after_count.pending_prekey_upload) > 100

    assert store
           |> Store.load!()
           |> get_in([:signal, :prekeys])
           |> map_size() == initial_prekey_count

    {after_upload, upload_actions} =
      PostAuth.handle_prekey_upload_response(
        %Binary.Node{
          tag: "iq",
          attrs: %{"type" => "result", "id" => after_count.prekey_upload_iq_id},
          content: nil
        },
        "result",
        after_count,
        build_passive_iq
      )

    assert upload_actions == []
    assert after_upload.pending_prekey_upload == []
    assert after_upload.prekey_upload_iq_id == nil
    assert after_upload.passive_iq_id == "passive-1"
    assert after_upload.post_auth_phase == :awaiting_passive_ack

    assert store
           |> Store.load!()
           |> get_in([:signal, :prekeys])
           |> map_size() > initial_prekey_count
  end
end
