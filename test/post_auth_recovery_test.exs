defmodule ExWapp.PostAuthRecoveryTest do
  use ExUnit.Case, async: true
  alias ExWapp.{Binary, JID, Prekeys, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Session.Worker.PostAuth
  alias ExWapp.Test.{FaultStore, SignalDevice}

  setup do
    device = SignalDevice.new()

    store =
      FaultStore.new(
        initial_data: %{
          signal:
            Map.merge(device.local_prekeys, %{identity_key: device.identity, registration_id: 123})
        }
      )

    state = %{
      store: store,
      runtime_cfg: %{prekeys: %{initial_prekey_count: 8, refill_prekey_count: 4}},
      passive_iq_id: "active",
      prekey_upload_iq_id: nil,
      post_auth_phase: :awaiting_prekey_count
    }

    %{store: store, state: state}
  end

  test "success LID aliases persist in both directions without losing other mappings", ctx do
    Store.put(ctx.store, :client_info, %{jid: "123@whatsapp.net"})
    Store.put(ctx.store, :lid_mapping, %{{:pn_to_lid, "456@s.whatsapp.net"} => "789@lid"})
    assert PostAuth.persist_lid_and_mapping(ctx.state, " 999@lid ") == ctx.state
    assert Store.get(ctx.store, :client_info).lid == " 999@lid "
    mappings = Store.get(ctx.store, :lid_mapping)
    assert mappings[{:pn_to_lid, "123@s.whatsapp.net"}] == "999@lid"
    assert mappings[{:lid_to_pn, "999@lid"}] == "123@s.whatsapp.net"
    Store.put(ctx.store, :client_info, %{})
    PostAuth.persist_lid_and_mapping(ctx.state, "111@lid")
    assert Store.get(ctx.store, :lid_mapping) == mappings
    assert PostAuth.persist_lid_and_mapping(ctx.state, :invalid) == ctx.state
  end

  test "wire-decoded success LID persists with account aliases independent of device", ctx do
    pn = JID.new("15550009999", "s.whatsapp.net") |> JID.with_device(7)
    lid = JID.new("90000000099", "lid") |> JID.with_device(7)
    Store.put(ctx.store, :pairing, %{device: %{"jid" => pn}})
    Store.put(ctx.store, :client_info, %{jid: pn, device_name: "test"})

    success =
      %Node{tag: "success", attrs: %{"lid" => lid}}
      |> Binary.encode!()
      |> Binary.decode!()

    assert %JID{} = success.attrs["lid"]
    assert PostAuth.persist_lid_and_mapping(ctx.state, success.attrs["lid"]) == ctx.state

    assert %{lid: "90000000099:7@lid", device_name: "test"} =
             Store.get(ctx.store, :client_info)

    mappings = Store.get(ctx.store, :lid_mapping)
    assert mappings[{:pn_to_lid, "15550009999@s.whatsapp.net"}] == "90000000099@lid"
    assert mappings[{:lid_to_pn, "90000000099@lid"}] == "15550009999@s.whatsapp.net"
  end

  test "healthy server inventory retains unacknowledged private keys until a refill is needed",
       ctx do
    {:ok, _, keys} = Prekeys.build_prekey_upload(ctx.store, count: 4)

    Store.update(ctx.store, :signal, %{}, fn signal ->
      put_in(signal.prekeys[999], %{public: <<1>>, private: nil})
    end)

    before = Store.get(ctx.store, :signal)
    {ready, []} = PostAuth.handle_prekey_count_response(count(100), ctx.state, &passive/0)
    assert ready.post_auth_phase == :awaiting_passive_ack
    assert Store.get(ctx.store, :signal) == before

    {uploading, [{:send_node, node}]} =
      PostAuth.handle_prekey_count_response(count(2), ready, &passive/0)

    assert node.attrs["xmlns"] == "encrypt"
    assert Enum.map(uploading.pending_prekey_upload, & &1.key_id) == Enum.map(keys, & &1.key_id)

    for key <- keys,
        do: assert(Store.get(ctx.store, :signal).prekeys[key.key_id].private == key.private)
  end

  test "failed acknowledgement storage leaves a durable batch reusable", ctx do
    {:ok, _, keys} = Prekeys.build_prekey_upload(ctx.store, count: 4)
    state = Map.put(ctx.state, :pending_prekey_upload, keys)
    FaultStore.arm(ctx.store, :update, {:return, {:error, :disk_full}})

    {ready, []} =
      PostAuth.handle_prekey_upload_response(%Node{tag: "iq"}, "result", state, &passive/0)

    assert ready.pending_prekey_upload == []
    for key <- keys, do: refute(Store.get(ctx.store, :signal).prekeys[key.key_id].uploaded)
    assert {:ok, _, ^keys} = Prekeys.build_prekey_upload(ctx.store, count: 4)
    PostAuth.handle_prekey_upload_response(%Node{tag: "iq"}, "result", state, &passive/0)
    for key <- keys, do: assert(Store.get(ctx.store, :signal).prekeys[key.key_id].uploaded)
  end

  test "reservation failure does not transmit keys or stall passive activation", ctx do
    for operation <- [:count, :notification] do
      before = Store.get(ctx.store, :signal)
      FaultStore.arm(ctx.store, :get_and_update, :raise)

      {state, []} =
        case operation do
          :count -> PostAuth.handle_prekey_count_response(count(0), ctx.state, &passive/0)
          :notification -> PostAuth.refill_from_notification(ctx.state, 0)
        end

      assert state.prekey_upload_iq_id == nil
      assert Store.get(ctx.store, :signal) == before
    end
  end

  test "optional passive and digest failures still complete authentication", ctx do
    state =
      Map.put(
        ctx.state,
        :runtime_cfg,
        Map.put(ctx.state.runtime_cfg, :protocol, %{post_auth_digest_enabled: true})
      )

    {waiting, [{:send_node, %Node{attrs: %{"id" => "digest"}}}]} =
      PostAuth.handle_passive_response(
        %Node{tag: "iq"},
        "error",
        state,
        fn -> %Node{tag: "iq", attrs: %{"id" => "digest"}} end,
        &unified/0
      )

    for {type, content} <- [{"error", nil}, {"result", [%Node{tag: "unrelated"}]}] do
      {complete, [{:send_node, node}, :mark_authenticated]} =
        PostAuth.handle_digest_response(
          %Node{tag: "iq", content: content},
          type,
          waiting,
          &unified/0
        )

      assert node == unified()
      assert complete.post_auth_phase == :complete
      assert complete.digest_iq_id == nil
    end
  end

  defp count(value),
    do: %Node{tag: "iq", content: [%Node{tag: "count", attrs: %{"value" => to_string(value)}}]}

  defp passive, do: %Node{tag: "iq", attrs: %{"id" => "active"}}
  defp unified, do: %Node{tag: "ib", content: [%Node{tag: "unified_session"}]}
end
