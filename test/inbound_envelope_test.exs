defmodule ExWapp.Message.Handler.Inbound.EnvelopeTest do
  use ExUnit.Case, async: true

  alias ExWapp.Message.Handler.Inbound.Envelope
  alias ExWapp.Signal.SessionStore
  alias ExWapp.Store
  alias ExWapp.Store.Memory

  test "orders local payloads first and synthesizes cross-family sender devices" do
    local_jid = "15550009999@s.whatsapp.net"
    pn_sender = "15550001111@s.whatsapp.net"
    lid_device = "90000000001:5@lid"

    non_matching_payload = %{
      ciphertext: <<1>>,
      to_jid: "15550008888@s.whatsapp.net"
    }

    matching_payload = %{
      ciphertext: <<2>>,
      to_jid: local_jid
    }

    context =
      Envelope.decrypt_context(
        %{enc_candidates: [non_matching_payload, matching_payload]},
        %{store: nil, signal_sessions: SessionStore.new()},
        pn_sender,
        lid_device,
        %{"sender_pn" => pn_sender, "to" => local_jid}
      )

    assert context.decryptable_payloads == [matching_payload, non_matching_payload]
    assert lid_device in context.sender_candidates
    assert "15550001111:5@s.whatsapp.net" in context.sender_candidates
  end

  test "persists PN and LID pairs observed on the envelope" do
    store = Memory.new()

    state = %{store: store}
    lid = "90000000001@lid"
    pn = "15550001111@s.whatsapp.net"

    assert Envelope.persist_lid_mappings(
             state,
             %{"sender_lid" => lid, "sender_pn" => pn},
             lid,
             nil
           ) == state

    data = Store.load!(store)

    assert data.lid_mapping[{:pn_to_lid, pn}] == lid
    assert data.lid_mapping[{:lid_to_pn, lid}] == pn
  end

  test "honors explicit from_me envelope values" do
    assert Envelope.from_me?(
             %{"from_me" => "1"},
             "15550001111@s.whatsapp.net",
             %{store: nil},
             %{}
           )
  end

  test "uses participant_pn for a group LID sender without an addressing_mode hint" do
    store = Memory.new()
    on_exit(fn -> Memory.stop(store) end)
    state = %{store: store, signal_sessions: SessionStore.new()}
    group = "120363000000000000@g.us"
    lid = "90000000001:5@lid"
    pn = "15550001111@s.whatsapp.net"
    attrs = %{"participant_pn" => pn}

    assert Envelope.persist_lid_mappings(state, attrs, group, lid) == state
    mapping = Store.load!(store).lid_mapping
    assert mapping[{:lid_to_pn, "90000000001@lid"}] == pn

    context = Envelope.decrypt_context(%{ciphertext: <<1>>}, state, group, lid, attrs)
    assert pn in context.sender_candidates
    assert "15550001111:5@s.whatsapp.net" in context.sender_candidates
  end

  test "authorizes self-only protocol senders from PN, LID, and group participant" do
    own_pn = "15550009999@s.whatsapp.net"
    own_lid = "90000000099@lid"
    own_device = "15550009999:7@s.whatsapp.net"
    other = "15550001111@s.whatsapp.net"

    store =
      Memory.new(
        initial_data: %{
          pairing: %{device: %{jid: own_pn}},
          client_info: %{jid: own_pn, lid: own_lid}
        }
      )

    state = %{store: store}
    direct_attrs = %{"to" => own_pn}

    assert Envelope.own_sender?(direct_attrs, own_pn, nil, state)
    assert Envelope.own_sender?(direct_attrs, own_device, nil, state)
    assert Envelope.own_sender?(%{"to" => own_lid}, own_lid, nil, state)

    group_attrs = %{"to" => own_pn, "from" => "12000000000@g.us"}
    assert Envelope.own_sender?(group_attrs, "12000000000@g.us", own_pn, state)

    refute Envelope.own_sender?(direct_attrs, other, nil, state)
    refute Envelope.own_sender?(group_attrs, "12000000000@g.us", other, state)

    refute Envelope.own_sender?(
             %{"to" => own_pn, "recipient" => other},
             other,
             nil,
             state
           )

    refute Envelope.own_sender?(%{"to" => other}, other, nil, %{store: nil})
    refute Envelope.own_sender?(direct_attrs, "invalid", nil, state)
  end
end
