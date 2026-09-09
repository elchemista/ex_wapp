defmodule ExWapp.SenderKeyMigrationTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias ExWapp.{JID, Store}
  alias ExWapp.Signal.SenderKey
  @group "123@g.us"
  @sender "456@s.whatsapp.net"
  @moduletag capture_log: true

  setup do
    sender = Store.Memory.new()
    receiver = Store.Memory.new()
    {:ok, distribution} = SenderKey.create_outbound_distribution_message(sender, @group, @sender)

    {:ok, 1} =
      SenderKey.process_distributions_from_plaintext(receiver, @group, @sender, distribution)

    %{sender: sender, receiver: receiver, distribution: distribution}
  end

  test "legacy sender-key records survive restart with out-of-order message keys", ctx do
    {:ok, first} = SenderKey.encrypt_outbound_group_message(ctx.sender, @group, @sender, "first")

    {:ok, second} =
      SenderKey.encrypt_outbound_group_message(ctx.sender, @group, @sender, "second")

    record = Store.get(ctx.receiver, :signal).sender_keys[{@group, @sender}]
    legacy = record.states[record.current_id]
    Store.put(ctx.receiver, :signal, %{sender_keys: %{{@group, @sender} => legacy}})

    assert {:ok, "second"} =
             SenderKey.decrypt_group_message(ctx.receiver, @group, @sender, second)

    assert {:ok, "first"} = SenderKey.decrypt_group_message(ctx.receiver, @group, @sender, first)
    assert {:error, _} = SenderKey.decrypt_group_message(ctx.receiver, @group, @sender, first)
  end

  test "invalid persisted cache entries do not prevent authentic messages from decrypting", ctx do
    record = Store.get(ctx.receiver, :signal).sender_keys[{@group, @sender}]
    state = record.states[record.current_id]

    for cache <- [:invalid, %{nil => nil, "bad" => %{cipher_key: <<>>}}] do
      stored = %{
        record
        | states: %{record.current_id => Map.put(state, :message_keys, cache), :bad => nil}
      }

      Store.put(ctx.receiver, :signal, %{sender_keys: %{{@group, @sender} => stored}})

      {:ok, encrypted} =
        SenderKey.encrypt_outbound_group_message(ctx.sender, @group, @sender, "recover")

      assert {:ok, "recover"} =
               SenderKey.decrypt_group_message(ctx.receiver, @group, @sender, encrypted)
    end
  end

  test "primary-device rotations keep the companion signing key and a bounded key history", ctx do
    original = Store.get(ctx.sender, :signal).sender_keys[{@group, @sender}].current_id

    for _ <- 1..7 do
      primary = Store.Memory.new()

      {:ok, distribution} =
        SenderKey.create_outbound_distribution_message(primary, @group, @sender)

      assert {:ok, 1} =
               SenderKey.process_distributions_from_plaintext(
                 ctx.sender,
                 @group,
                 @sender,
                 distribution
               )
    end

    record = Store.get(ctx.sender, :signal).sender_keys[{@group, @sender}]
    assert record.current_id == original
    assert length(record.state_ids) == 5
    assert original in record.state_ids

    assert {:ok, encrypted} =
             SenderKey.encrypt_outbound_group_message(
               ctx.sender,
               @group,
               @sender,
               "companion survives"
             )

    assert {:ok, "companion survives"} =
             SenderKey.decrypt_group_message(ctx.receiver, @group, @sender, encrypted)
  end

  test "unknown protobuf fields are skipped without exposing group plaintext in diagnostics",
       ctx do
    level = Logger.level()
    Logger.configure(level: :debug)
    on_exit(fn -> Logger.configure(level: level) end)
    {:ok, group} = JID.parse(@group)
    {:ok, sender} = JID.parse(@sender)
    # Independent protobuf encodings: unknown varint, fixed64, and fixed32 fields.
    unknown = <<160, 1, 42, 169, 1, 0::64, 181, 1, 0::32>>

    logs =
      capture_log(fn ->
        assert {:ok, 1} =
                 SenderKey.process_distributions_from_plaintext(
                   ctx.receiver,
                   group,
                   sender,
                   unknown <> ctx.distribution
                 )

        {:ok, encrypted} =
          SenderKey.encrypt_outbound_group_message(
            ctx.sender,
            group,
            sender,
            "private group body"
          )

        assert {:ok, "private group body"} =
                 SenderKey.decrypt_group_message(ctx.receiver, group, sender, encrypted)
      end)

    assert logs =~ "Stored distribution"
    refute logs =~ "private group body"
    refute logs =~ @sender
  end

  test "truncated and wrong-wire-type distributions cannot replace a trusted key", ctx do
    original = Store.load!(ctx.receiver)

    malformed = [
      <<>>,
      <<18, 127, 1>>,
      <<18, 1, 0>>,
      <<8>>,
      <<11>>,
      <<9, 0>>,
      <<13, 0>>,
      :binary.copy(<<128>>, 12)
    ]

    for payload <- malformed do
      assert {:ok, 0} =
               SenderKey.process_distributions_from_plaintext(
                 ctx.receiver,
                 @group,
                 @sender,
                 payload
               )

      assert Store.load!(ctx.receiver) == original
    end

    inner = [
      <<>>,
      <<0>>,
      <<51>>,
      <<51, 8, 1>>,
      <<51, 10, 0>>,
      <<51, 8, 1, 18, 0>>,
      <<51, 8, 1, 16, 0, 24, 1>>,
      <<51, 8, 1, 16, 0, 26, 32, 0::256, 34, 1, 0>>
    ]

    for axolotl <- inner do
      payload =
        WAWebProtobufsE2E.Message.encode!(%WAWebProtobufsE2E.Message{
          senderKeyDistributionMessage: %WAWebProtobufsE2E.SenderKeyDistributionMessage{
            groupID: @group,
            axolotlSenderKeyDistributionMessage: axolotl
          }
        })
        |> IO.iodata_to_binary()

      assert {:ok, 0} =
               SenderKey.process_distributions_from_plaintext(
                 ctx.receiver,
                 @group,
                 @sender,
                 payload
               )

      assert Store.load!(ctx.receiver) == original
    end

    {:ok, encrypted} =
      SenderKey.encrypt_outbound_group_message(ctx.sender, @group, @sender, "still valid")

    assert {:ok, "still valid"} =
             SenderKey.decrypt_group_message(ctx.receiver, @group, @sender, encrypted)
  end

  test "invalid addresses and missing ciphertext fail without mutating the store", ctx do
    original = Store.load!(ctx.receiver)

    for address <- [nil, "", <<255>>, 1] do
      assert {:error, :invalid_group_jid} =
               SenderKey.create_outbound_distribution_message(ctx.receiver, address, @sender)

      assert {:error, :invalid_group_jid} =
               SenderKey.decrypt_group_message(ctx.receiver, address, @sender, <<1>>)

      assert {:error, :invalid_sender_jid} =
               SenderKey.decrypt_group_message(ctx.receiver, @group, address, <<1>>)
    end

    assert {:error, :missing_store} =
             SenderKey.process_distributions_from_plaintext(
               nil,
               @group,
               @sender,
               ctx.distribution
             )

    assert {:error, :invalid_plaintext} =
             SenderKey.process_distributions_from_plaintext(ctx.receiver, @group, @sender, nil)

    assert {:error, :invalid_ciphertext} =
             SenderKey.decrypt_group_message(ctx.receiver, @group, @sender, nil)

    assert {:error, :invalid_plaintext} =
             SenderKey.encrypt_outbound_group_message(ctx.receiver, @group, @sender, nil)

    assert Store.load!(ctx.receiver) == original
  end
end
