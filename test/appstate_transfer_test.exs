defmodule ExWapp.AppStateTransferTest do
  use ExUnit.Case, async: true
  alias ExWapp.{Binary, Chat, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.AppState.{Engine, LTHash}
  alias ExWapp.AppState.Engine.Codec
  alias ExWapp.Test.{LocalHTTP, ProtocolPeer}

  alias WAWebProtobufsServerSync.{
    ExternalBlobReference,
    SyncdMutations,
    SyncdPatch,
    SyncdSnapshot,
    SyncdVersion
  }

  @collection "regular_low"
  @jid "15550001111@s.whatsapp.net"

  defmodule IQPeer do
    use GenServer
    def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
    def init(opts), do: {:ok, opts}

    def handle_call({:send_iq, request, _id}, _from, state) do
      send(state.owner, {:iq_request, request})

      case state.responses do
        [reply | rest] -> {:reply, reply, %{state | responses: rest}}
        [] -> {:reply, {:error, :end_of_exchange}, state}
      end
    end
  end

  setup do
    key_id = :crypto.strong_rand_bytes(16)
    key = :crypto.strong_rand_bytes(32)
    keys = %{Base.encode16(key_id, case: :lower) => %{data: key, timestamp: 1}}
    store = Store.Memory.new()
    :ok = Store.put(store, :app_state_keys, keys)
    initial = %{version: 0, hash: LTHash.new()}

    {:ok, binary, state1, macs1} =
      Engine.encode_patch(Engine.build_pin(@jid, true), key_id, key, initial)

    {:ok, next, state2, macs2} =
      Engine.encode_patch(Engine.build_pin(@jid, false), key_id, key, state1, macs1)

    %{
      store: store,
      key: key,
      key_id: key_id,
      keys: keys,
      first: SyncdPatch.decode!(binary),
      second: SyncdPatch.decode!(next),
      state1: state1,
      state2: state2,
      macs1: macs1,
      macs2: macs2
    }
  end

  test "snapshot authenticates records and continues with a paginated patch chain", ctx do
    snapshot = snapshot(ctx)
    first = response([raw("snapshot", snapshot)], %{"has_more_patches" => "true"})
    second = response([raw("patch", ctx.second)])
    session = peer([{:ok, first}, {:ok, second}])
    assert :ok = Engine.fetch_collection(session, ctx.store, @collection)
    assert_receive {:iq_request, request1}
    assert_receive {:iq_request, request2}
    assert collection(request1).attrs["return_snapshot"] == "true"
    assert collection(request2).attrs["return_snapshot"] == "false"
    assert collection(request2).attrs["version"] == "1"
    assert match?({:ok, %{pinned: false}}, Chat.get(ctx.store, @jid))
    assert {:ok, ctx.state2, ctx.macs2} == Engine.get_collection_state(ctx.store, @collection)
  end

  test "invalid snapshot falls back to a verified patch and pagination cannot loop forever",
       ctx do
    bad = %{snapshot(ctx) | mac: <<0::256>>}

    session =
      peer([{:ok, response([raw("snapshot", bad)])}, {:ok, response([raw("patch", ctx.first)])}])

    assert :ok = Engine.fetch_collection(session, ctx.store, @collection)
    assert match?({:ok, %{pinned: true}}, Chat.get(ctx.store, @jid))
    assert_receive {:iq_request, _}
    assert_receive {:iq_request, retry}
    assert collection(retry).attrs["return_snapshot"] == "false"
    stalled = peer([{:ok, response([], %{"has_more_patches" => "yes"})}])

    assert {:error, {:app_state_pagination_stalled, @collection, 1, 1}} =
             Engine.fetch_collection(stalled, ctx.store, @collection)
  end

  test "valid snapshot survives an obsolete trailing patch but rejects corrupted snapshot records",
       ctx do
    bad_patch = %{ctx.second | snapshotMAC: <<0::256>>}

    assert {:ok, 1} =
             Engine.apply_collection_response(
               ctx.store,
               @collection,
               response([raw("snapshot", snapshot(ctx)), raw("patch", bad_patch)])
             )

    assert {:ok, ctx.state1, ctx.macs1} == Engine.get_collection_state(ctx.store, @collection)
    assert match?({:ok, %{pinned: true}}, Chat.get(ctx.store, @jid))
    store = Store.Memory.new()
    :ok = Store.put(store, :app_state_keys, ctx.keys)
    [record] = snapshot(ctx).records
    corrupt = %{snapshot(ctx) | records: [%{record | value: %{record.value | blob: <<1, 2, 3>>}}]}

    assert {:error, {:apply_snapshot_failed, :invalid_record_value}} =
             Engine.apply_collection_response(
               store,
               @collection,
               response([raw("snapshot", corrupt)])
             )

    assert {:error, :not_found} == Chat.get(store, @jid)
    assert {:ok, %{version: 0}, %{}} = Engine.get_collection_state(store, @collection)
  end

  test "downloads and authenticates external mutations over HTTP and caches media discovery",
       ctx do
    plaintext = ProtocolPeer.encode(%SyncdMutations{mutations: ctx.first.mutations})
    media_key = :crypto.strong_rand_bytes(32)
    body = encrypt_blob(media_key, plaintext)
    server = http(200, body)

    ref = %ExternalBlobReference{
      directPath: LocalHTTP.url(server) <> "/mutations",
      mediaKey: media_key
    }

    patch = %{ctx.first | mutations: [], externalMutations: ref}

    session =
      peer([
        {:ok,
         %Node{
           tag: "iq",
           content: [
             %Node{
               tag: "media_conn",
               content: [
                 %Node{tag: "host", attrs: %{"hostname" => "local-only"}},
                 %Node{tag: "host", attrs: %{}},
                 %Node{tag: "other"}
               ]
             }
           ]
         }}
      ])

    for _ <- 1..2 do
      store = Store.Memory.new()
      :ok = Store.put(store, :app_state_keys, ctx.keys)

      assert {:ok, 1} =
               Engine.apply_collection_response(
                 store,
                 @collection,
                 response([raw("patch", patch)]),
                 session
               )

      assert match?({:ok, %{pinned: true}}, Chat.get(store, @jid))
      assert {:ok, ctx.state1, ctx.macs1} == Engine.get_collection_state(store, @collection)
      assert_receive {:http_request, {:http_request, :GET, {:abs_path, "/mutations"}, _}, headers}
      assert headers["origin"] == "https://web.whatsapp.com"
    end

    assert_receive {:iq_request, %{attrs: %{"xmlns" => "w:m"}}}
    refute_receive {:iq_request, _}
  end

  test "external mutation failures leave both chat and collection state unchanged", ctx do
    plaintext = ProtocolPeer.encode(%SyncdMutations{mutations: ctx.first.mutations})
    key = :crypto.strong_rand_bytes(32)
    ciphertext = encrypt_blob(key, plaintext)

    cases = [
      {200, <<0>>, key, :external_blob_payload_too_short},
      {200, ciphertext <> <<0>>, key, :invalid_external_blob_mac},
      {200, ciphertext, <<>>, :invalid_external_blob_key},
      {503, "unavailable", key, {:http_status, 503, 11}}
    ]

    for {status, body, key, reason} <- cases do
      server = http(status, body)

      patch = %{
        ctx.first
        | mutations: [],
          externalMutations: %ExternalBlobReference{
            directPath: LocalHTTP.url(server) <> "/blob",
            mediaKey: key
          }
      }

      assert {:error, {:apply_patch_failed, ^reason}} =
               Engine.apply_collection_response(
                 ctx.store,
                 @collection,
                 response([raw("patch", patch)])
               )

      assert {:error, :not_found} == Chat.get(ctx.store, @jid)
      assert {:ok, %{version: 0}, %{}} = Engine.get_collection_state(ctx.store, @collection)
    end

    patch = %{ctx.first | externalMutations: %ExternalBlobReference{directPath: " "}}

    assert {:error, {:apply_patch_failed, :missing_external_blob_path}} =
             Engine.apply_collection_response(
               ctx.store,
               @collection,
               response([raw("patch", patch)])
             )
  end

  test "plain external mutation payloads remain supported", ctx do
    server = http(200, ProtocolPeer.encode(%SyncdMutations{mutations: ctx.first.mutations}))

    patch = %{
      ctx.first
      | mutations: [],
        externalMutations: %ExternalBlobReference{directPath: LocalHTTP.url(server) <> "/plain"}
    }

    assert {:ok, 1} =
             Engine.apply_collection_response(
               ctx.store,
               @collection,
               response([raw("patch", patch)])
             )

    assert match?({:ok, %{pinned: true}}, Chat.get(ctx.store, @jid))
  end

  test "conflict response advances the chain before retrying the user's change", ctx do
    conflict =
      response([%Node{tag: "error", attrs: %{"code" => "409"}}, raw("patch", ctx.first)], %{
        "type" => "error"
      })

    session =
      peer([{:ok, response([])}, {:ok, conflict}, {:ok, response([])}, {:ok, response([])}])

    assert {:ok, %{version: 2}, _} =
             Engine.send_mutation(session, Engine.build_pin(@jid, false), ctx.store)

    assert_receive {:iq_request, _fetch}
    assert_receive {:iq_request, original}
    assert_receive {:iq_request, retried}
    assert collection(original).attrs["version"] == "0"
    assert collection(retried).attrs["version"] == "1"
    [%Node{content: %Binary.Raw{data: bytes}}] = collection(retried).content

    assert {:ok, [mutation], next_state, _} =
             Codec.decode_patch(
               SyncdPatch.decode!(bytes),
               @collection,
               ctx.state1,
               ctx.macs1,
               ctx.keys
             )

    assert next_state.version == 2
    assert mutation.action.pinAction.pinned == false
    assert match?({:ok, %{pinned: false}}, Chat.get(ctx.store, @jid))
    assert_receive {:iq_request, refresh}, 1000
    assert collection(refresh).attrs["version"] == "2"
  end

  test "failed acknowledgements never optimistically apply outgoing changes", ctx do
    for {reply, expected} <- [
          {{:error, :timeout}, {:iq_failed, :timeout}},
          {{:ok,
            response([%Node{tag: "error", attrs: %{"code" => "500"}}], %{"type" => "error"})},
           {:app_state_update_failed, {:server_error, 500}}},
          {{:ok, %Node{tag: "iq"}}, {:app_state_update_failed, :collection_not_found}}
        ] do
      session = peer([{:ok, response([])}, reply])

      assert {:error, ^expected} =
               Engine.send_mutation(session, Engine.build_pin(@jid, true), ctx.store)

      assert {:error, :not_found} == Chat.get(ctx.store, @jid)
      assert {:ok, %{version: 0}, %{}} = Engine.get_collection_state(ctx.store, @collection)
    end
  end

  test "external snapshot references download a verified initial state", ctx do
    body = ProtocolPeer.encode(snapshot(ctx))
    server = http(200, body)
    ref = %ExternalBlobReference{directPath: LocalHTTP.url(server) <> "/snapshot"}

    assert {:ok, 1} =
             Engine.apply_collection_response(
               ctx.store,
               @collection,
               response([raw("snapshot", ref)])
             )

    assert_receive {:http_request, {:http_request, :GET, {:abs_path, "/snapshot"}, _}, _}, 1000
    assert {:ok, ctx.state1, ctx.macs1} == Engine.get_collection_state(ctx.store, @collection)
    assert {:ok, %Chat{pinned: true}} = Chat.get(ctx.store, @jid)
  end

  test "pagination accepts legacy boolean encodings and ignores non-patch extensions", ctx do
    for value <- [true, 1, "1"] do
      store = Store.Memory.new(initial_data: %{app_state_keys: ctx.keys})

      session =
        peer([
          {:ok, response([raw("patch", ctx.first)], %{"has_more_patches" => value})},
          {:ok,
           response(
             [
               %Node{
                 tag: "patches",
                 content: [%Node{tag: "extension"}, %Node{tag: "patch"}, raw("patch", ctx.second)]
               },
               %Node{tag: "patch"}
             ],
             %{"has_more_patches" => "0"}
           )}
        ])

      assert :ok = Engine.fetch_collection(session, store, @collection)
      assert {:ok, ctx.state2, ctx.macs2} == Engine.get_collection_state(store, @collection)
      assert {:ok, %Chat{pinned: false}} = Chat.get(store, @jid)
    end

    for value <- [false, 0, "no", "unexpected"] do
      session = peer([{:ok, response([], %{"has_more_patches" => value})}])
      assert :ok = Engine.fetch_collection(session, ctx.store, @collection)
    end
  end

  test "malformed collection replies and error codes leave changes uncommitted", ctx do
    for {reply, reason} <- [
          {:invalid, :invalid_collection_response},
          {%Node{tag: "iq"}, :collection_not_found}
        ] do
      assert {:error, ^reason} = Engine.apply_collection_response(ctx.store, @collection, reply)
    end

    for {reply, reason} <- [
          {:invalid, :invalid_collection_response},
          {response([], %{"type" => "error"}), {:server_error, :unknown}},
          {response(
             [%Node{tag: "extension"}, %Node{tag: "error", attrs: %{"code" => "invalid"}}],
             %{"type" => "error"}
           ), {:server_error, :unknown}},
          {response([%Node{tag: "error", attrs: %{"code" => nil}}], %{"type" => "error"}),
           {:server_error, :unknown}},
          {response([%Node{tag: "error", attrs: %{"code" => 503}}], %{"type" => "error"}),
           {:server_error, 503}}
        ] do
      session = peer([{:ok, response([])}, {:ok, reply}])

      assert {:error, {:app_state_update_failed, ^reason}} =
               Engine.send_mutation(session, Engine.build_pin(@jid, true), ctx.store)

      assert {:error, :not_found} = Chat.get(ctx.store, @jid)
      assert {:ok, %{version: 0}, %{}} = Engine.get_collection_state(ctx.store, @collection)
    end
  end

  test "authenticated malformed mutation values are rejected before state application", ctx do
    alias ExWapp.AppState.Crypto
    keys = Crypto.expand_keys(ctx.key)
    [mutation] = ctx.first.mutations
    iv = <<0::128>>

    bad_padding =
      :crypto.crypto_one_time(:aes_256_cbc, keys.value_encryption, iv, <<0::128>>, true)

    {_, invalid_proto} = Crypto.encrypt_cbc(<<255>>, keys.value_encryption, iv)

    for {encrypted, expected} <- [
          {<<1>>, :encrypted_content_too_short},
          {iv <> bad_padding, :decrypt_failed},
          {iv <> invalid_proto, :decode_sync_action_data_failed}
        ] do
      mac = Crypto.compute_content_mac(0, encrypted, ctx.key_id, keys.value_mac)
      record = %{mutation.record | value: %{mutation.record.value | blob: encrypted <> mac}}
      assert {:error, reason} = Codec.decode_mutations([%{mutation | record: record}], ctx.keys)
      assert reason == expected or (is_tuple(reason) and elem(reason, 0) == expected)
      assert {:error, :not_found} = Chat.get(ctx.store, @jid)
    end
  end

  test "missing patch metadata and invalid stored keys cannot pass authentication", ctx do
    initial = %{version: 0, hash: LTHash.new()}

    for {patch, reason} <- [
          {%{ctx.first | keyID: nil}, :missing_patch_key_id},
          {%{ctx.first | version: -1}, :invalid_patch_version},
          {%{ctx.first | snapshotMAC: nil}, :invalid_snapshot_mac},
          {%{ctx.first | patchMAC: nil}, :invalid_patch_mac}
        ] do
      assert {:error, ^reason} = Codec.decode_patch(patch, @collection, initial, %{}, ctx.keys)
    end

    [mutation] = ctx.first.mutations

    assert {:error, :invalid_key_store_or_id} =
             Codec.decode_mutations([%{mutation | record: nil}], ctx.keys)

    assert {:error, :invalid_record_value} =
             Codec.decode_mutations(
               [%{mutation | record: %{mutation.record | value: nil}}],
               ctx.keys
             )

    bad_keys = Map.new(ctx.keys, fn {id, _} -> {id, %{data: <<1>>}} end)
    assert {:error, {:invalid_key_entry, _}} = Codec.decode_mutations([mutation], bad_keys)
    Store.put(ctx.store, :app_state_keys, %{"invalid-hex" => %{data: ctx.key}})
    assert {:error, {:invalid_key_id_hex, "invalid-hex"}} = Codec.latest_app_state_key(ctx.store)
  end

  test "snapshots inherit a collection key or resolve it from their records", ctx do
    original = snapshot(ctx)
    inherited = %{original | records: Enum.map(original.records, &%{&1 | keyID: nil})}
    assert {:ok, mutations} = Codec.decode_snapshot_mutations(inherited, ctx.keys)
    assert length(mutations) == 1

    assert {:ok, hash, macs} =
             Codec.verify_snapshot(%{original | keyID: nil}, mutations, 1, @collection, ctx.keys)

    assert hash == ctx.state1.hash
    assert macs == ctx.macs1

    assert {:error, {:encode_patch_failed, _}} =
             Codec.encode_patch(Engine.build_pin(@jid, true), ctx.key_id, ctx.key, %{
               version: 0,
               hash: <<1>>
             })
  end

  test "unsupported snapshots retry once using patches", ctx do
    unsupported = %SyncdSnapshot{version: %SyncdVersion{version: 0}, records: [], mac: <<0::256>>}

    session =
      peer([
        {:ok, response([raw("snapshot", unsupported)])},
        {:ok, response([raw("patch", ctx.first)])}
      ])

    assert :ok = Engine.fetch_collection(session, ctx.store, @collection)
    assert_receive {:iq_request, first}
    assert_receive {:iq_request, second}
    assert collection(first).attrs["return_snapshot"] == "true"
    assert collection(second).attrs["return_snapshot"] == "false"
    assert {:ok, %Chat{pinned: true}} = Chat.get(ctx.store, @jid)
  end

  test "absolute external blob URLs remain usable when media host discovery fails", ctx do
    server = http(200, ProtocolPeer.encode(%SyncdMutations{mutations: ctx.first.mutations}))

    patch = %{
      ctx.first
      | mutations: [],
        externalMutations: %ExternalBlobReference{
          directPath: LocalHTTP.url(server) <> "/independent-blob"
        }
    }

    for reply <- [
          {:error, :timeout},
          {:ok, :invalid},
          {:ok, %Node{tag: "iq"}},
          {:ok, %Node{tag: "iq", content: [%Node{tag: "media_conn", content: []}]}}
        ] do
      session = peer([reply])
      store = Store.Memory.new(initial_data: %{app_state_keys: ctx.keys})

      assert {:ok, 1} =
               Engine.apply_collection_response(
                 store,
                 @collection,
                 response([raw("patch", patch)]),
                 session
               )

      assert {:ok, %Chat{pinned: true}} = Chat.get(store, @jid)
      assert {:ok, ctx.state1, ctx.macs1} == Engine.get_collection_state(store, @collection)
    end
  end

  defp peer(responses),
    do:
      start_supervised!(%{
        id: make_ref(),
        start: {IQPeer, :start_link, [%{owner: self(), responses: responses}]}
      })

  defp http(status, body),
    do:
      start_supervised!(%{
        id: make_ref(),
        start: {LocalHTTP, :start_link, [%{owner: self(), response: {status, body}}]}
      })

  defp snapshot(ctx),
    do: %SyncdSnapshot{
      version: %SyncdVersion{version: 1},
      records: Enum.map(ctx.first.mutations, & &1.record),
      mac: ctx.first.snapshotMAC,
      keyID: ctx.first.keyID
    }

  defp raw(tag, protobuf), do: %Node{tag: tag, content: Binary.raw(ProtocolPeer.encode(protobuf))}

  defp response(children, attrs \\ %{}),
    do: %Node{
      tag: "iq",
      content: [
        %Node{
          tag: "sync",
          content: [
            %Node{
              tag: "collection",
              attrs: Map.merge(%{"name" => @collection}, attrs),
              content: children
            }
          ]
        }
      ]
    }

  defp collection(%Node{tag: "collection"} = node), do: node

  defp collection(%Node{content: nodes}) when is_list(nodes),
    do: Enum.find_value(nodes, &collection/1)

  defp collection(_), do: nil

  defp encrypt_blob(key, plaintext) do
    prk = :crypto.mac(:hmac, :sha256, <<0::256>>, key)

    {blocks, _} =
      Enum.map_reduce(1..4, <<>>, fn i, previous ->
        block = :crypto.mac(:hmac, :sha256, prk, [previous, "WhatsApp App State Keys", <<i>>])
        {block, block}
      end)

    <<iv::binary-size(16), cipher_key::binary-size(32), mac_key::binary-size(32), _::binary>> =
      IO.iodata_to_binary(blocks)

    padding = 16 - rem(byte_size(plaintext), 16)

    encrypted =
      :crypto.crypto_one_time(
        :aes_256_cbc,
        cipher_key,
        iv,
        plaintext <> :binary.copy(<<padding>>, padding),
        true
      )

    mac = :crypto.mac(:hmac, :sha256, mac_key, iv <> encrypted) |> binary_part(0, 10)
    encrypted <> mac
  end
end
