defmodule ExWapp.PrekeyIdentityRecoveryTest do
  @moduledoc """
  Coverage for the way a one-time prekey id space goes wrong in production.

  Captured from a live session that could neither read nor write to one contact
  for the whole run: every inbound `pkmsg` from that peer named prekey 815 while
  the local store held 811 keys numbered from 1, so each one failed with
  `:prekey_not_found`, and every outbound message to the same peer came back
  `<ack error="463">`. The server was still handing out a key this device had
  advertised and then lost — through an unflushed write, or through the session
  file being restored from an older snapshot.

  Nothing recovers the messages encrypted against a lost key. What these tests
  pin down is that the state cannot get worse: the id is never reissued with new
  material, and a batch is never advertised before it is durable.
  """

  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Prekeys
  alias ExWapp.Session.Worker.ReceiptBuilder
  alias ExWapp.Signal.{Encryption, Keys, SessionStore}
  alias ExWapp.Store
  alias ExWapp.Store.Memory
  alias ExWapp.Test.FlushProbeStore

  @peer_jid "15550007777@s.whatsapp.net"

  describe "ids the server is still serving" do
    test "an unopenable pkmsg reserves the prekey id it names" do
      # The exact shape from the capture: the peer opens a session with a key it
      # drew from the server, and this device has no private half for it. The
      # message is gone, but reissuing 815 later would hand a second peer a
      # public half that does not match the one the first peer holds — and then
      # both sessions are broken instead of one.
      prekey_id = 815
      %{store: store, ciphertext: ciphertext} = peer_opened_session_with_lost_prekey(prekey_id)

      assert {:error, :prekey_not_found} =
               Encryption.decrypt_from_sender_sync(
                 store,
                 SessionStore.new(),
                 @peer_jid,
                 ciphertext,
                 "pkmsg"
               )

      assert Store.load!(store).signal.max_advertised_prekey_id == prekey_id
    end

    test "the reserved id is skipped by the next upload batch" do
      prekey_id = 815
      %{store: store, ciphertext: ciphertext} = peer_opened_session_with_lost_prekey(prekey_id)

      {:error, :prekey_not_found} =
        Encryption.decrypt_from_sender_sync(
          store,
          SessionStore.new(),
          @peer_jid,
          ciphertext,
          "pkmsg"
        )

      assert {:ok, _node, prekeys} = Prekeys.build_prekey_upload(store, count: 2)
      assert Enum.map(prekeys, & &1.key_id) == [816, 817]
    end

    test "a decrypt failure that is not about a missing key reserves nothing" do
      # The watermark only ever moves forward, so moving it on the wrong signal
      # would permanently skip usable ids for no reason.
      store = bob_store(%{}, %{})

      assert {:error, _reason} =
               Encryption.decrypt_from_sender_sync(
                 store,
                 SessionStore.new(),
                 @peer_jid,
                 <<0x33, 0>>,
                 "pkmsg"
               )

      refute Map.has_key?(Store.load!(store).signal, :max_advertised_prekey_id)
    end
  end

  describe "id allocation after the store falls behind" do
    test "a store restored behind its own uploads mints above the watermark" do
      # `next_prekey_id` and the key map both come back from the snapshot, so
      # neither of them knows about the ids uploaded after it was taken. The
      # watermark is the only field that survives the rollback with the truth.
      store =
        signal_store(%{
          prekeys: %{},
          next_prekey_id: 812,
          max_advertised_prekey_id: 815
        })

      assert {:ok, _node, prekeys} = Prekeys.build_prekey_upload(store, count: 3)
      assert Enum.map(prekeys, & &1.key_id) == [816, 817, 818]
    end

    test "an upload batch raises the watermark to cover every id it advertises" do
      store = signal_store(%{prekeys: %{}, next_prekey_id: 1})

      assert {:ok, _node, prekeys} = Prekeys.build_prekey_upload(store, count: 4)
      assert Enum.map(prekeys, & &1.key_id) == [1, 2, 3, 4]
      assert Store.load!(store).signal.max_advertised_prekey_id == 4
    end

    test "reserved-but-unuploaded keys are reused rather than replaced" do
      # Durable reservation exists so an upload that failed mid-flight can be
      # retried with the same key material. The watermark must not turn that
      # into a reason to burn a fresh id every attempt.
      store = signal_store(%{prekeys: %{}, next_prekey_id: 1})

      assert {:ok, _node, first} = Prekeys.build_prekey_upload(store, count: 2)
      assert {:ok, _node, second} = Prekeys.build_prekey_upload(store, count: 2)

      assert Enum.map(first, & &1.key_id) == [1, 2]
      assert Enum.map(second, & &1.key_id) == [1, 2]
      assert Enum.map(first, & &1.public) == Enum.map(second, & &1.public)
    end
  end

  describe "id allocation fenced outside the store" do
    # The watermark lives in the session file, so a store restored from a
    # snapshot brings its ceiling back down with it — below ids the server is
    # already serving. A host that keeps durable state somewhere that cannot roll
    # back closes that gap by allocating the ids there instead.
    test "the allocator's floor wins over the store's own" do
      store = signal_store(%{prekeys: %{}, next_prekey_id: 1})

      assert {:ok, _node, prekeys} =
               Prekeys.build_prekey_upload(store,
                 count: 2,
                 runtime_cfg: %{prekeys: %{id_allocator: allocator_returning(9_000)}}
               )

      assert Enum.map(prekeys, & &1.key_id) == [9_000, 9_001]
      assert Store.load!(store).signal.max_advertised_prekey_id == 9_001
    end

    test "the allocator sees the local floor it has to stay above" do
      store =
        signal_store(%{
          prekeys: %{},
          next_prekey_id: 5,
          max_advertised_prekey_id: 815
        })

      test_pid = self()

      allocator = fn local_floor, count ->
        send(test_pid, {:allocate, local_floor, count})
        {:ok, local_floor}
      end

      assert {:ok, _node, _prekeys} =
               Prekeys.build_prekey_upload(store,
                 count: 3,
                 runtime_cfg: %{prekeys: %{id_allocator: allocator}}
               )

      assert_receive {:allocate, 816, 3}
    end

    test "an allocator that falls behind the store is overruled, not obeyed" do
      # A stale fence handing back an id this store already minted would reissue
      # live key material, which is the failure the fence exists to prevent.
      store = signal_store(%{prekeys: %{}, next_prekey_id: 400})

      assert {:ok, _node, prekeys} =
               Prekeys.build_prekey_upload(store,
                 count: 1,
                 runtime_cfg: %{prekeys: %{id_allocator: allocator_returning(7)}}
               )

      assert Enum.map(prekeys, & &1.key_id) == [400]
    end

    test "nothing is minted when the allocator cannot reserve" do
      # Fail closed: a thinner prekey pool on the server recovers on the next
      # connect, an id space two devices disagree about never does.
      store = signal_store(%{prekeys: %{}, next_prekey_id: 1})

      assert {:error, {:prekey_id_allocation_failed, :database_unavailable}} =
               Prekeys.build_prekey_upload(store,
                 count: 2,
                 runtime_cfg: %{
                   prekeys: %{
                     id_allocator: fn _floor, _count -> {:error, :database_unavailable} end
                   }
                 }
               )

      assert Store.load!(store).signal.prekeys == %{}
    end

    test "an allocator that raises does not take the session down with it" do
      store = signal_store(%{prekeys: %{}, next_prekey_id: 1})

      assert {:error, {:prekey_id_allocation_failed, _error}} =
               Prekeys.build_prekey_upload(store,
                 count: 2,
                 runtime_cfg: %{
                   prekeys: %{id_allocator: fn _floor, _count -> raise "no connection" end}
                 }
               )
    end

    test "a retry receipt draws its key from the same fence" do
      store = signal_store(%{prekeys: %{}, next_prekey_id: 1})

      receipt =
        ReceiptBuilder.build_retry_receipt_ack(
          store,
          @peer_jid,
          "RETRY_FENCED",
          nil,
          "1730000300",
          1,
          0,
          %{force_keys?: true},
          %{runtime_cfg: %{prekeys: %{id_allocator: allocator_returning(9_500)}}}
        )

      assert %Binary.Node{tag: "keys", content: key_children} = List.last(receipt.content)
      assert advertised_prekey_id(key_children) == 9_500
      assert %{private: <<_::binary-size(32)>>} = Store.load!(store).signal.prekeys[9_500]
    end

    test "a retry receipt carries no keys when the fence refuses" do
      store = signal_store(%{prekeys: %{}, next_prekey_id: 1})

      receipt =
        ReceiptBuilder.build_retry_receipt_ack(
          store,
          @peer_jid,
          "RETRY_FENCE_DOWN",
          nil,
          "1730000300",
          1,
          0,
          %{force_keys?: true},
          %{
            runtime_cfg: %{
              prekeys: %{id_allocator: fn _floor, _count -> {:error, :database_unavailable} end}
            }
          }
        )

      assert Enum.map(receipt.content, & &1.tag) == ["retry", "registration"]
      assert Store.load!(store).signal.prekeys == %{}
    end
  end

  describe "durability before advertisement" do
    test "a batch that cannot be persisted is never advertised" do
      # Advertising first and persisting later is how the id space develops holes
      # in the first place: the server starts serving public halves whose private
      # halves only ever existed in memory.
      identity = Keys.generate_key_pair()
      signed_prekey = Keys.generate_signed_prekey(identity, 1)

      store =
        FlushProbeStore.new(
          owner: self(),
          flush_result: {:error, :disk_full},
          initial_data: %{
            signal: %{
              identity_key: identity,
              registration_id: 26_581,
              signed_prekeys: %{1 => signed_prekey},
              prekeys: %{},
              next_prekey_id: 1
            }
          }
        )

      on_exit(fn -> FlushProbeStore.stop(store) end)

      assert {:error, {:prekey_reservation_flush_failed, :disk_full}} =
               Prekeys.build_prekey_upload(store, count: 2)

      assert_receive :retry_store_flushed
    end

    test "a persisted batch keeps its private halves" do
      store = signal_store(%{prekeys: %{}, next_prekey_id: 1})

      assert {:ok, _node, prekeys} = Prekeys.build_prekey_upload(store, count: 2)

      persisted = Store.load!(store).signal.prekeys

      for prekey <- prekeys do
        assert %{private: <<_::binary-size(32)>>, public: public} = persisted[prekey.key_id]
        assert public == prekey.public
      end
    end
  end

  describe "retry receipt key bundles" do
    test "the advertised retry prekey is minted above the watermark and persisted" do
      # The retry receipt is the escape hatch from the whole failure: it hands the
      # peer a key this device definitely holds. It is worth nothing if that key
      # is only in memory, or if it reuses an id the peer may already have.
      store =
        signal_store(%{
          prekeys: %{},
          next_prekey_id: 10,
          max_advertised_prekey_id: 815
        })

      receipt =
        ReceiptBuilder.build_retry_receipt_ack(
          store,
          @peer_jid,
          "RETRY_AFTER_LOST_PREKEY",
          nil,
          "1730000300",
          1,
          0,
          %{force_keys?: true}
        )

      assert %Binary.Node{tag: "keys", content: key_children} = List.last(receipt.content)
      assert advertised_prekey_id(key_children) == 816

      signal = Store.load!(store).signal
      assert %{private: <<_::binary-size(32)>>} = signal.prekeys[816]
      assert signal.max_advertised_prekey_id == 816
    end
  end

  defp peer_opened_session_with_lost_prekey(prekey_id) do
    peer_identity = Keys.generate_key_pair()
    bob_identity = Keys.generate_key_pair()

    signed_prekey_id = 1
    bob_signed_prekey = Keys.generate_signed_prekey(bob_identity, signed_prekey_id)
    lost_prekey = Keys.generate_prekey(prekey_id)

    bundle = %{
      registration_id: 416_037_980,
      identity_key: bob_identity.public,
      signed_prekey: %{
        id: signed_prekey_id,
        public: bob_signed_prekey.public,
        signature: bob_signed_prekey.signature
      },
      prekey: %{id: prekey_id, public: lost_prekey.public}
    }

    {:ok, ciphertext, :prekey, _peer_sessions} =
      SessionStore.encrypt_message(
        SessionStore.new(),
        "own@s.whatsapp.net",
        "ciao",
        peer_identity,
        1001,
        bundle
      )

    # The private half is the part the store lost; everything else survived.
    store =
      bob_store(
        %{signed_prekey_id => bob_signed_prekey},
        %{},
        identity: bob_identity
      )

    %{store: store, ciphertext: ciphertext}
  end

  defp bob_store(signed_prekeys, prekeys, opts \\ []) do
    identity = Keyword.get_lazy(opts, :identity, &Keys.generate_key_pair/0)

    signal_store(%{
      identity_key: identity,
      signed_prekeys: signed_prekeys,
      prekeys: prekeys
    })
  end

  defp signal_store(signal) do
    identity = Map.get_lazy(signal, :identity_key, &Keys.generate_key_pair/0)

    signed_prekeys =
      Map.get_lazy(signal, :signed_prekeys, fn ->
        %{1 => Keys.generate_signed_prekey(identity, 1)}
      end)

    signal =
      signal
      |> Map.put(:identity_key, identity)
      |> Map.put(:signed_prekeys, signed_prekeys)
      |> Map.put_new(:registration_id, 26_581)

    store =
      Memory.new(initial_data: %{signal: signal, pairing: %{device_identity: <<1, 2, 3, 4>>}})

    on_exit(fn -> Memory.stop(store) end)
    store
  end

  defp allocator_returning(first_id), do: fn _local_floor, _count -> {:ok, first_id} end

  defp advertised_prekey_id(key_children) do
    Enum.find_value(key_children, fn
      %Binary.Node{tag: "key", content: content} ->
        Enum.find_value(content, fn
          %Binary.Node{tag: "id", content: %Binary.Raw{data: <<id::big-24>>}} -> id
          _other -> nil
        end)

      _other ->
        nil
    end)
  end
end
