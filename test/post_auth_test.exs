defmodule ExWapp.Session.Worker.PostAuthTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Binary, Prekeys, Signal, Store}
  alias ExWapp.Session.Worker.PostAuth
  alias ExWapp.Store.Memory

  test "prekeys are durably reserved before upload and only marked uploaded after acknowledgement" do
    store = Memory.new(initial_data: %{})
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

    reserved_signal = store |> Store.load!() |> Map.fetch!(:signal)
    reserved_ids = Enum.map(after_count.pending_prekey_upload, &Map.fetch!(&1, :key_id))

    assert map_size(reserved_signal.prekeys) ==
             initial_prekey_count + length(after_count.pending_prekey_upload)

    assert Enum.all?(reserved_ids, fn id ->
             get_in(reserved_signal, [:prekeys, id, :uploaded]) == false
           end)

    assert reserved_signal.next_prekey_id == Enum.max(reserved_ids) + 1

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

    acknowledged_signal = store |> Store.load!() |> Map.fetch!(:signal)

    assert map_size(acknowledged_signal.prekeys) == map_size(reserved_signal.prekeys)

    assert Enum.all?(reserved_ids, fn id ->
             get_in(acknowledged_signal, [:prekeys, id, :uploaded]) == true
           end)
  end

  test "an unacknowledged durable batch is reused instead of regenerating key IDs" do
    store = Memory.new(initial_data: %{})
    {:ok, _signal_info, signal_state} = Signal.bootstrap(%{})
    :ok = Store.persist(store, %{signal: signal_state})

    assert {:ok, _first_node, first_batch} = Prekeys.build_prekey_upload(store, count: 3)
    signal_after_first = store |> Store.load!() |> Map.fetch!(:signal)

    assert {:ok, _second_node, second_batch} = Prekeys.build_prekey_upload(store, count: 3)
    signal_after_second = store |> Store.load!() |> Map.fetch!(:signal)

    assert Enum.map(first_batch, & &1.key_id) == Enum.map(second_batch, & &1.key_id)
    assert map_size(signal_after_second.prekeys) == map_size(signal_after_first.prekeys)
    assert signal_after_second.next_prekey_id == signal_after_first.next_prekey_id

    assert :ok = Prekeys.mark_uploaded(store, second_batch)
    assert {:ok, _third_node, third_batch} = Prekeys.build_prekey_upload(store, count: 3)

    refute MapSet.new(Enum.map(first_batch, & &1.key_id)) ==
             MapSet.new(Enum.map(third_batch, & &1.key_id))
  end
end
