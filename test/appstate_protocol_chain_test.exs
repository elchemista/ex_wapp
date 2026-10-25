defmodule ExWapp.AppState.ProtocolChainTest do
  use ExUnit.Case, async: true

  alias ExWapp.AppState.{Engine, LTHash}
  alias ExWapp.AppState.Engine.Codec
  alias ExWapp.Binary.Node
  alias WAWebProtobufsServerSync.SyncdPatch
  alias ExWapp.Store

  setup do
    key_id = :crypto.strong_rand_bytes(16)
    key_data = :crypto.strong_rand_bytes(32)
    key_hex = Base.encode16(key_id, case: :lower)

    %{
      key_id: key_id,
      key_data: key_data,
      key_store: %{key_hex => %{data: key_data, timestamp: 1}},
      initial_state: %{version: 0, hash: LTHash.new()}
    }
  end

  test "two authenticated patches thread version, LTHash and mutation MAC state", ctx do
    first = Engine.build_pin("15550001111@s.whatsapp.net", true)
    second = Engine.build_pin("15550001111@s.whatsapp.net", false)

    {:ok, first_binary, encoded_state_1, encoded_macs_1} =
      Engine.encode_patch(first, ctx.key_id, ctx.key_data, ctx.initial_state, %{})

    {:ok, second_binary, encoded_state_2, encoded_macs_2} =
      Engine.encode_patch(second, ctx.key_id, ctx.key_data, encoded_state_1, encoded_macs_1)

    {:ok, first_patch} = SyncdPatch.decode(first_binary)
    {:ok, second_patch} = SyncdPatch.decode(second_binary)

    assert {:ok, [first_decoded], decoded_state_1, decoded_macs_1} =
             Engine.decode_patch(
               first_patch,
               "regular_low",
               ctx.initial_state,
               %{},
               ctx.key_store
             )

    assert first_decoded.action.pinAction.pinned == true
    assert decoded_state_1 == encoded_state_1
    assert decoded_macs_1 == encoded_macs_1

    assert {:ok, [second_decoded], decoded_state_2, decoded_macs_2} =
             Engine.decode_patch(
               second_patch,
               "regular_low",
               decoded_state_1,
               decoded_macs_1,
               ctx.key_store
             )

    assert second_decoded.action.pinAction.pinned == false
    assert decoded_state_2 == encoded_state_2
    assert decoded_macs_2 == encoded_macs_2
    assert decoded_state_2.version == 2
  end

  test "SET followed by REMOVE returns the collection hash and index map to base", ctx do
    set = Engine.build_contact("15550001111@s.whatsapp.net", "Alice")
    remove = Engine.build_delete_contact("15550001111@s.whatsapp.net")

    {:ok, set_binary, state_1, macs_1} =
      Engine.encode_patch(set, ctx.key_id, ctx.key_data, ctx.initial_state, %{})

    {:ok, remove_binary, encoded_final_state, encoded_final_macs} =
      Engine.encode_patch(remove, ctx.key_id, ctx.key_data, state_1, macs_1)

    assert encoded_final_state.hash == LTHash.new()
    assert encoded_final_macs == %{}

    {:ok, set_patch} = SyncdPatch.decode(set_binary)
    {:ok, remove_patch} = SyncdPatch.decode(remove_binary)

    {:ok, _set, decoded_state_1, decoded_macs_1} =
      Engine.decode_patch(
        set_patch,
        "critical_unblock_low",
        ctx.initial_state,
        %{},
        ctx.key_store
      )

    assert {:ok, [_remove], decoded_final_state, decoded_final_macs} =
             Engine.decode_patch(
               remove_patch,
               "critical_unblock_low",
               decoded_state_1,
               decoded_macs_1,
               ctx.key_store
             )

    assert decoded_final_state.hash == LTHash.new()
    assert decoded_final_macs == %{}
  end

  test "rejects tampered snapshot, patch, content and index MACs", ctx do
    {:ok, encoded, _state, _macs} =
      Engine.encode_patch(
        Engine.build_pin("15550001111@s.whatsapp.net", true),
        ctx.key_id,
        ctx.key_data,
        ctx.initial_state,
        %{}
      )

    {:ok, patch} = SyncdPatch.decode(encoded)

    assert {:error, :mismatching_snapshot_mac} =
             patch
             |> Map.put(:snapshotMAC, flip_first(patch.snapshotMAC))
             |> decode_patch(ctx, "regular_low")

    assert {:error, :mismatching_patch_mac} =
             patch
             |> Map.put(:patchMAC, flip_first(patch.patchMAC))
             |> decode_patch(ctx, "regular_low")

    [mutation] = patch.mutations
    bad_value = put_in(mutation.record.value.blob, flip_first(mutation.record.value.blob))

    assert {:error, :mismatching_content_mac} =
             patch
             |> Map.put(:mutations, [bad_value])
             |> decode_patch(ctx, "regular_low")

    bad_index = put_in(mutation.record.index.blob, flip_first(mutation.record.index.blob))

    assert {:error, :mismatching_index_mac} =
             patch
             |> Map.put(:mutations, [bad_index])
             |> decode_patch(ctx, "regular_low")
  end

  test "missing app-state keys fail explicitly and do not advance state", ctx do
    {:ok, encoded, _state, _macs} =
      Engine.encode_patch(
        Engine.build_pin("15550001111@s.whatsapp.net", true),
        ctx.key_id,
        ctx.key_data,
        ctx.initial_state,
        %{}
      )

    {:ok, patch} = SyncdPatch.decode(encoded)
    key_hex = Base.encode16(ctx.key_id, case: :lower)

    assert {:error, {:key_not_found, ^key_hex}} =
             Engine.decode_patch(patch, "regular_low", ctx.initial_state, %{}, %{})
  end

  test "a corrupt trailing patch cannot partially apply an earlier valid patch", ctx do
    first = Engine.build_contact("15550001111@s.whatsapp.net", "Alice")
    second = Engine.build_contact("15550002222@s.whatsapp.net", "Bob")

    {:ok, first_binary, state_1, macs_1} =
      Engine.encode_patch(first, ctx.key_id, ctx.key_data, ctx.initial_state, %{})

    {:ok, second_binary, _state_2, _macs_2} =
      Engine.encode_patch(second, ctx.key_id, ctx.key_data, state_1, macs_1)

    {:ok, second_patch} = SyncdPatch.decode(second_binary)

    corrupt_second =
      second_patch
      |> Map.put(:patchMAC, flip_first(second_patch.patchMAC))
      |> SyncdPatch.encode!()
      |> IO.iodata_to_binary()

    store =
      Store.Memory.new(
        initial_data: %{
          app_state_keys: ctx.key_store,
          app_state_versions: %{},
          app_state_mutation_macs: %{}
        }
      )

    response = collection_response("critical_unblock_low", [first_binary, corrupt_second])

    assert {:error, {:apply_patch_failed, :mismatching_patch_mac}} =
             Engine.apply_collection_response(store, "critical_unblock_low", response)

    assert ExWapp.Contact.get(store, "15550001111@s.whatsapp.net") == nil
    assert ExWapp.Contact.get(store, "15550002222@s.whatsapp.net") == nil

    assert {:ok, %{version: 0, hash: hash}, %{}} =
             Engine.get_collection_state(store, "critical_unblock_low")

    assert hash == LTHash.new()
  end

  test "modular codec follows the same authenticated patch contract", ctx do
    patch_info = Engine.build_pin("15550001111@s.whatsapp.net", true)

    assert {:ok, encoded, encoded_state, encoded_macs} =
             Codec.encode_patch(patch_info, ctx.key_id, ctx.key_data, ctx.initial_state, %{})

    assert {:ok, patch} = SyncdPatch.decode(encoded)

    assert {:ok, [decoded], ^encoded_state, ^encoded_macs} =
             Engine.decode_patch(
               patch,
               "regular_low",
               ctx.initial_state,
               %{},
               ctx.key_store
             )

    assert decoded.action.pinAction.pinned == true
  end

  defp decode_patch(patch, ctx, collection) do
    Engine.decode_patch(patch, collection, ctx.initial_state, %{}, ctx.key_store)
  end

  defp collection_response(name, patch_binaries) do
    patch_nodes =
      Enum.map(patch_binaries, fn patch ->
        %Node{tag: "patch", attrs: %{}, content: ExWapp.Binary.raw(patch)}
      end)

    %Node{
      tag: "iq",
      attrs: %{"type" => "result"},
      content: [
        %Node{
          tag: "sync",
          attrs: %{},
          content: [
            %Node{
              tag: "collection",
              attrs: %{"name" => name, "version" => "0"},
              content: [%Node{tag: "patches", attrs: %{}, content: patch_nodes}]
            }
          ]
        }
      ]
    }
  end

  defp flip_first(<<first, rest::binary>>), do: <<Bitwise.bxor(first, 1), rest::binary>>
end
