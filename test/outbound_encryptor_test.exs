defmodule ExWapp.Session.Outbound.EncryptorTest do
  use ExUnit.Case, async: true

  alias ExWapp.Session.MessageNode
  alias ExWapp.Session.Outbound.Encryptor

  test "returns only target devices without an encrypted participant node" do
    primary = %{jid: "15550001111@s.whatsapp.net", payload_kind: :recipient}
    companion = %{jid: "15550001111:8@s.whatsapp.net", payload_kind: :recipient}

    participant_nodes = [
      MessageNode.build_participant_encrypted_node(primary.jid, <<1, 2, 3>>, :whisper)
    ]

    assert [^companion] =
             Encryptor.missing_expected_targets(
               [primary, companion],
               participant_nodes
             )
  end

  test "returns no missing targets when every target has a participant node" do
    targets = [
      %{jid: "15550001111@s.whatsapp.net", payload_kind: :recipient},
      %{jid: "15550001111:8@s.whatsapp.net", payload_kind: :recipient}
    ]

    participant_nodes =
      Enum.map(targets, fn target ->
        MessageNode.build_participant_encrypted_node(target.jid, <<4, 5, 6>>, :prekey)
      end)

    assert [] = Encryptor.missing_expected_targets(targets, participant_nodes)
  end

  test "ignores malformed target JIDs at the defensive boundary" do
    targets = [
      %{jid: nil, payload_kind: :recipient},
      %{payload_kind: :recipient}
    ]

    assert [] = Encryptor.missing_expected_targets(targets, [])
  end
end
