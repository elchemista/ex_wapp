defmodule ExWapp.Session.Worker.PostAuthOrderingTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Binary, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Session.Worker
  alias ExWapp.Session.Worker.NodeHandler
  alias ExWapp.Test.SignalDevice

  setup do
    device = SignalDevice.new()

    store =
      Store.Memory.new(
        initial_data: %{
          signal:
            Map.merge(device.local_prekeys, %{
              identity_key: device.identity,
              registration_id: device.bundle.registration_id
            })
        }
      )

    on_exit(fn -> Store.Memory.stop(store) end)

    state = %Worker{
      store: store,
      pairing: %{store: store},
      runtime_cfg: %{prekeys: %{initial_prekey_count: 8, refill_prekey_count: 4}}
    }

    %{state: state, store: store}
  end

  for order <- [
        [:passive, :count, :upload],
        [:count, :passive, :upload],
        [:count, :upload, :passive]
      ],
      count <- [0, 2],
      upload_type <- ["result", "error"] do
    @order order
    @count count
    @upload_type upload_type

    test "activates once for #{inspect(order)}, inventory #{count}, upload #{upload_type}", ctx do
      {state, startup_actions} = handle(%Node{tag: "success"}, ctx.state)

      {state, actions, responses, uploaded_ids} =
        Enum.reduce(@order, {state, startup_actions, [], []}, fn step,
                                                                 {state, actions, responses, ids} ->
          node = response(step, state, @count, @upload_type)
          {state, next_actions} = handle(node, state)

          ids =
            if step == :count,
              do: Enum.map(state.pending_prekey_upload, & &1.key_id),
              else: ids

          {state, actions ++ next_actions, responses ++ [node], ids}
        end)

      assert state.post_auth_phase == :complete
      assert state.prekey_count_query_id == nil
      assert state.prekey_upload_iq_id == nil
      assert state.passive_iq_id == nil
      assert state.pending_prekey_upload == []
      assert Enum.count(actions, &(&1 == :mark_authenticated)) == 1
      assert count_nodes(actions, "iq", "passive") == 1
      assert count_nodes(actions, "ib") == 1

      assert length(uploaded_ids) == if(@count == 0, do: 8, else: 4)
      prekeys = Store.get(ctx.store, :signal).prekeys

      for id <- uploaded_ids do
        assert byte_size(prekeys[id].private) == 32
        assert prekeys[id].uploaded == (@upload_type == "result")
      end

      # Duplicate or delayed responses must not reopen an already completed flow.
      for node <- responses do
        assert {^state, []} = handle(node, state)
      end
    end
  end

  for order <- [
        [:passive, :count, :upload, :digest],
        [:passive, :count, :digest, :upload],
        [:passive, :digest, :count, :upload]
      ] do
    @order order

    test "preserves opt-in digest activation for #{inspect(order)}", ctx do
      state = %{
        ctx.state
        | runtime_cfg:
            Map.put(ctx.state.runtime_cfg, :protocol, %{post_auth_digest_enabled: true})
      }

      {state, startup_actions} = handle(%Node{tag: "success"}, state)

      {state, actions} =
        Enum.reduce(@order, {state, startup_actions}, fn step, {state, actions} ->
          {state, next_actions} = handle(response(step, state, 0, "result"), state)

          if step != :digest and state.digest_iq_id != nil do
            assert state.post_auth_phase == :awaiting_digest
            refute :mark_authenticated in next_actions
          end

          {state, actions ++ next_actions}
        end)

      assert state.post_auth_phase == :complete
      assert state.passive_iq_id == nil
      assert state.digest_iq_id == nil
      assert state.prekey_upload_iq_id == nil
      assert Enum.count(actions, &(&1 == :mark_authenticated)) == 1
      assert count_nodes(actions, "iq", "passive") == 1
      assert count_nodes(actions, "ib") == 1

      assert Enum.count(actions, fn
               {:send_node, %Node{content: [%Node{tag: "digest"}]}} -> true
               _ -> false
             end) == 1
    end
  end

  test "a healthy inventory response leaves the pending digest in charge of activation", ctx do
    state = %{
      ctx.state
      | runtime_cfg: Map.put(ctx.state.runtime_cfg, :protocol, %{post_auth_digest_enabled: true})
    }

    {state, _startup_actions} = handle(%Node{tag: "success"}, state)
    {state, _digest_query} = handle(response(:passive, state, 10, "result"), state)
    digest_id = state.digest_iq_id
    assert is_binary(digest_id)

    {state, []} = handle(response(:count, state, 10, "result"), state)
    assert state.post_auth_phase == :awaiting_digest
    assert state.digest_iq_id == digest_id
    assert state.passive_iq_id == nil

    {state, [{:send_node, %Node{tag: "ib"}}, :mark_authenticated]} =
      handle(response(:digest, state, 10, "result"), state)

    assert state.post_auth_phase == :complete
  end

  test "a new success resets activation tracking after a completed connection", ctx do
    {state, _startup_actions} = handle(%Node{tag: "success"}, ctx.state)
    first_passive = response(:passive, state, 10, "result")
    {state, _ready_actions} = handle(first_passive, state)
    {state, []} = handle(response(:count, state, 10, "result"), state)
    assert state.post_auth_phase == :complete

    {state, startup_actions} = handle(%Node{tag: "success"}, state)
    assert count_nodes(startup_actions, "iq", "passive") == 1
    assert state.passive_iq_id != first_passive.attrs["id"]
    assert {^state, []} = handle(first_passive, state)
    {state, []} = handle(response(:count, state, 10, "result"), state)

    {state, [{:send_node, %Node{tag: "ib"}}, :mark_authenticated]} =
      handle(response(:passive, state, 10, "result"), state)

    assert state.post_auth_phase == :complete
  end

  defp response(:count, state, count, _type) do
    %Node{
      tag: "iq",
      attrs: %{"id" => state.prekey_count_query_id, "type" => "result"},
      content: [%Node{tag: "count", attrs: %{"value" => to_string(count)}}]
    }
  end

  defp response(:upload, state, _count, type),
    do: %Node{tag: "iq", attrs: %{"id" => state.prekey_upload_iq_id, "type" => type}}

  defp response(:passive, state, _count, _type),
    do: %Node{tag: "iq", attrs: %{"id" => state.passive_iq_id, "type" => "result"}}

  defp response(:digest, state, _count, _type) do
    %Node{
      tag: "iq",
      attrs: %{"id" => state.digest_iq_id, "type" => "result"},
      content: [%Node{tag: "digest"}]
    }
  end

  defp handle(node, state) do
    node |> Binary.encode!() |> Binary.decode!() |> NodeHandler.safe_handle_node(state)
  end

  defp count_nodes(actions, tag, xmlns \\ nil) do
    Enum.count(actions, fn
      {:send_node, %Node{tag: ^tag, attrs: attrs}} ->
        xmlns == nil or attrs["xmlns"] == xmlns

      _ ->
        false
    end)
  end
end
