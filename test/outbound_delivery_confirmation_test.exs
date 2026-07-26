defmodule ExWapp.OutboundDeliveryConfirmationTest do
  @moduledoc """
  Regression coverage for the two ways an accepted-or-rejected outbound message
  can be misreported as neither.

  Callers decide whether a send succeeded by watching the stored message status
  move off `:pending`. Anything that silently fails to move it turns an
  accepted message into a spurious timeout, and a rejected one into an infinite
  retry — both of which have shipped from this module before.
  """

  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Error.Ack
  alias ExWapp.Message.Handler.Receipt
  alias ExWapp.Session.Outbound.Direct
  alias ExWapp.Session.Worker
  alias ExWapp.Store
  alias ExWapp.Store.Memory

  # Synthetic stand-ins shaped like a production capture: this contact is
  # LID-migrated, so the two addressing families below are the same human.
  @lid "70000004444@lid"
  @pn "15550004444@s.whatsapp.net"

  defp ack(attrs), do: %Binary.Node{tag: "ack", attrs: Map.put(attrs, "class", "message")}

  defp store_with_pending(jid, ids) do
    store = Memory.new([])

    messages =
      ids
      |> Enum.with_index(1)
      |> Enum.map(fn {id, index} ->
        %{id: id, timestamp: index, status: :pending, from_me: true}
      end)

    :ok = Store.upsert_messages(store, jid, messages)
    store
  end

  describe "server acknowledgement matching" do
    test "an ack carrying only `from` confirms the message" do
      # The server's ack for an outbound message does not echo `to`; the chat it
      # refers to arrives in `from`. Requiring `to` would drop every real ack.
      store = store_with_pending(@lid, ["MSG_FROM_ONLY"])

      assert {:ok, _state} =
               Receipt.handle_ack(
                 ack(%{"id" => "MSG_FROM_ONLY", "from" => @lid}),
                 self(),
                 %{store: store}
               )

      assert %{status: :sent} = Store.find_message(store, @lid, "MSG_FROM_ONLY")
    end

    test "an ack addressed in the peer's other family still confirms the message" do
      # The regression. A LID-addressed send may be acked against the contact's
      # phone JID. Scoping the status update to that JID alone matches nothing,
      # returns :ok anyway, and leaves the message :pending forever — which the
      # transport reads as "the server never answered" on a delivered message.
      store = store_with_pending(@lid, ["MSG_CROSS_FAMILY"])

      assert {:ok, _state} =
               Receipt.handle_ack(
                 ack(%{"id" => "MSG_CROSS_FAMILY", "from" => @pn}),
                 self(),
                 %{store: store}
               )

      assert %{status: :sent} = Store.find_message(store, @lid, "MSG_CROSS_FAMILY")
    end

    test "an ack from a specific device confirms the chat-level message" do
      # Acks arrive from a device-suffixed JID while chats are keyed bare.
      store = store_with_pending(@lid, ["MSG_DEVICE_SUFFIX"])

      assert {:ok, _state} =
               Receipt.handle_ack(
                 ack(%{"id" => "MSG_DEVICE_SUFFIX", "from" => "70000004444:6@lid"}),
                 self(),
                 %{store: store}
               )

      assert %{status: :sent} = Store.find_message(store, @lid, "MSG_DEVICE_SUFFIX")
    end

    test "a rejection is recorded even when the ack family differs" do
      # 463 is the rejection this client actually receives for a wrong-family
      # send. Losing it is worse than losing a success: the caller cannot tell
      # the message was refused and retries until it is rate limited.
      store = store_with_pending(@lid, ["MSG_REJECTED"])

      assert {:ok, _state} =
               Receipt.handle_ack(
                 ack(%{"id" => "MSG_REJECTED", "from" => @pn, "error" => "463"}),
                 self(),
                 %{store: store}
               )

      assert %{status: :failed} = Store.find_message(store, @lid, "MSG_REJECTED")
    end

    test "confirming across families does not disturb other chats" do
      # The cross-family lookup is ID-wide, so it must stay surgical: an ack for
      # one conversation may not touch a same-status message in another.
      store = store_with_pending(@lid, ["MSG_MINE"])
      other = "393406036570@s.whatsapp.net"

      :ok =
        Store.upsert_messages(store, other, [%{id: "MSG_THEIRS", timestamp: 1, status: :pending}])

      assert {:ok, _state} =
               Receipt.handle_ack(
                 ack(%{"id" => "MSG_MINE", "from" => @pn}),
                 self(),
                 %{store: store}
               )

      assert %{status: :sent} = Store.find_message(store, @lid, "MSG_MINE")
      assert %{status: :pending} = Store.find_message(store, other, "MSG_THEIRS")
    end

    test "an ack for an unknown message leaves every stored status alone" do
      store = store_with_pending(@lid, ["MSG_KNOWN"])

      assert {:ok, _state} =
               Receipt.handle_ack(
                 ack(%{"id" => "MSG_NEVER_SENT", "from" => @pn}),
                 self(),
                 %{store: store}
               )

      assert %{status: :pending} = Store.find_message(store, @lid, "MSG_KNOWN")
    end

    test "an ack with no correlatable id is ignored" do
      store = store_with_pending(@lid, ["MSG_UNTOUCHED"])

      assert {:ok, _state} =
               Receipt.handle_ack(ack(%{"id" => "", "from" => @pn}), self(), %{store: store})

      assert %{status: :pending} = Store.find_message(store, @lid, "MSG_UNTOUCHED")
    end
  end

  describe "delivery broadcast" do
    # The session observes the server's verdict; the caller cannot. Publishing
    # it is what lets a sender await an outcome instead of polling stored status
    # and guessing what silence meant.
    setup do
      session_id = "delivery-test-#{System.unique_integer([:positive])}"
      Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:delivery:#{session_id}")
      {:ok, session_id: session_id}
    end

    test "an accepted message is announced as sent", %{session_id: session_id} do
      store = store_with_pending(@lid, ["MSG_OK"])

      Receipt.handle_ack(
        ack(%{"id" => "MSG_OK", "from" => @lid}),
        self(),
        %{store: store, session_id: session_id}
      )

      assert_receive {:ex_wapp_delivery, "MSG_OK", :sent, %{jid: @lid}}
    end

    test "a rejection is announced with a classified reason", %{session_id: session_id} do
      store = store_with_pending(@lid, ["MSG_403"])

      Receipt.handle_ack(
        ack(%{"id" => "MSG_403", "from" => @lid, "error" => "403"}),
        self(),
        %{store: store, session_id: session_id}
      )

      assert_receive {:ex_wapp_delivery, "MSG_403", :failed, %{error: error}}
      assert %Ack{code: "403", category: :permanent, retriable?: false} = error
    end

    test "a session rejection goes to repair instead of straight to the caller",
         %{session_id: session_id} do
      # 463 means the peer could not decrypt what this session encrypted. The
      # library repairs that itself, so announcing the failure here would hand
      # the caller a verdict on a send that is about to be made again — and a
      # caller that retries on it duplicates the repair.
      store = store_with_pending(@lid, ["MSG_463"])

      Receipt.handle_ack(
        ack(%{"id" => "MSG_463", "from" => @lid, "error" => "463"}),
        self(),
        %{store: store, session_id: session_id}
      )

      assert_receive {:ack_session_rejection, "MSG_463", @lid,
                      %Ack{code: "463", category: :session}}

      refute_receive {:ex_wapp_delivery, "MSG_463", _, _}, 50
    end

    test "a session rejection with nothing to correlate on is still announced",
         %{session_id: session_id} do
      # No ID means no payload to resend and no way for a caller to match a
      # verdict; withholding it would strand whoever is waiting.
      store = store_with_pending(@lid, ["MSG_ORPHAN"])

      Receipt.handle_ack(
        ack(%{"id" => "MSG_ORPHAN", "from" => "", "to" => "", "error" => "463"}),
        self(),
        %{store: store, session_id: session_id}
      )

      refute_receive {:ack_session_rejection, _, _, _}, 50
      assert_receive {:ex_wapp_delivery, "MSG_ORPHAN", :failed, _meta}
    end

    test "an accepted message is announced even when the store lost the record",
         %{session_id: session_id} do
      # Bounded histories evict. Delivery is a fact about the server, not about
      # what we still happen to have on disk, so it must not depend on storage.
      store = Memory.new([])

      Receipt.handle_ack(
        ack(%{"id" => "MSG_EVICTED", "from" => @lid}),
        self(),
        %{store: store, session_id: session_id}
      )

      assert_receive {:ex_wapp_delivery, "MSG_EVICTED", :sent, _meta}
    end

    test "receipt-class acks stay off the delivery topic", %{session_id: session_id} do
      store = store_with_pending(@lid, ["MSG_QUIET"])

      Receipt.handle_ack(
        %Binary.Node{
          tag: "ack",
          attrs: %{"id" => "MSG_QUIET", "from" => @lid, "class" => "receipt"}
        },
        self(),
        %{store: store, session_id: session_id}
      )

      refute_receive {:ex_wapp_delivery, _, _, _}, 50
    end
  end

  describe "session repair after a rejection" do
    # `Receipt` withholds the delivery event for a session rejection because the
    # session process is expected to resend. Every path where it does not resend
    # therefore owes the caller the verdict it withheld, or `send_message_await/4`
    # blocks until its timeout on a message the server already refused.
    setup do
      session_id = "repair-test-#{System.unique_integer([:positive])}"
      Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:delivery:#{session_id}")
      {:ok, session_id: session_id, ack: Ack.classify("463")}
    end

    test "reports the rejection when there is nothing left to resend",
         %{session_id: session_id, ack: ack} do
      state = %Worker{session_id: session_id, store: nil}

      assert {:noreply, _state} =
               Worker.handle_info({:ack_session_rejection, "MSG_GONE", @lid, ack}, state)

      assert_receive {:ex_wapp_delivery, "MSG_GONE", :failed, %{jid: @lid, error: ^ack}}
    end

    test "reports the rejection when no worker can be started",
         %{session_id: session_id, ack: ack} do
      # The payload is here, but nothing can run the send: a repair that cannot
      # start is indistinguishable from no repair as far as the caller is concerned.
      state = %Worker{
        session_id: session_id,
        store: nil,
        send_worker_sup: nil,
        outgoing_retry_payloads: %{"MSG_STUCK" => %{jid: @lid, text: "ciao"}}
      }

      assert {:noreply, _state} =
               Worker.handle_info({:ack_session_rejection, "MSG_STUCK", @lid, ack}, state)

      assert_receive {:ex_wapp_delivery, "MSG_STUCK", :failed, %{error: ^ack}}
    end

    test "resends under a fresh session and stays quiet until that send is answered",
         %{session_id: session_id, ack: ack} do
      sup = start_supervised!({Task.Supervisor, name: :"repair_sup_#{session_id}"})

      state = %Worker{
        session_id: session_id,
        store: nil,
        send_worker_sup: sup,
        outgoing_retry_payloads: %{"MSG_RETRY" => %{jid: @lid, text: "ciao"}}
      }

      assert {:noreply, new_state} =
               Worker.handle_info({:ack_session_rejection, "MSG_RETRY", @lid, ack}, state)

      assert new_state.retry_counters == %{"session_repair|#{@lid}|MSG_RETRY" => 1}
      refute_receive {:ex_wapp_delivery, "MSG_RETRY", :failed, _}, 50
    end

    test "a normal outbound retry does not consume the session repair budget",
         %{session_id: session_id, ack: ack} do
      sup = start_supervised!({Task.Supervisor, name: :"repair_sup_scoped_#{session_id}"})

      state = %Worker{
        session_id: session_id,
        store: nil,
        send_worker_sup: sup,
        retry_counters: %{"outbound_retry|#{@lid}|MSG_SCOPED" => 1},
        outgoing_retry_payloads: %{"MSG_SCOPED" => %{jid: @lid, text: "ciao"}}
      }

      assert {:noreply, new_state} =
               Worker.handle_info({:ack_session_rejection, "MSG_SCOPED", @lid, ack}, state)

      assert new_state.retry_counters == %{
               "outbound_retry|#{@lid}|MSG_SCOPED" => 1,
               "session_repair|#{@lid}|MSG_SCOPED" => 1
             }

      refute_receive {:ex_wapp_delivery, "MSG_SCOPED", :failed, _}, 50
    end

    test "a second rejection waits instead of resending immediately",
         %{session_id: session_id, ack: ack} do
      # A repair that renegotiated from a freshly fetched bundle and was refused
      # again has already ruled out the stale-session explanation. In the capture
      # this comes from, the identical payload went through on the next attempt
      # seconds later, so the second repair is worth making — just not at once,
      # and not while the caller is being told anything.
      sup = start_supervised!({Task.Supervisor, name: :"repair_sup_twice_#{session_id}"})

      state = %Worker{
        session_id: session_id,
        store: nil,
        send_worker_sup: sup,
        runtime_cfg: %{
          send: %{max_session_repair_attempts: 2, session_repair_backoff_ms: [0, 30]}
        },
        retry_counters: %{"session_repair|#{@lid}|MSG_AGAIN" => 1},
        outgoing_retry_payloads: %{"MSG_AGAIN" => %{jid: @lid, text: "ciao"}}
      }

      assert {:noreply, waiting} =
               Worker.handle_info({:ack_session_rejection, "MSG_AGAIN", @lid, ack}, state)

      assert waiting.retry_counters == %{"session_repair|#{@lid}|MSG_AGAIN" => 1}
      refute_receive {:ex_wapp_delivery, "MSG_AGAIN", _, _}, 20

      assert_receive {:session_repair_due, "MSG_AGAIN", @lid, ^ack}, 200

      assert {:noreply, resent} =
               Worker.handle_info({:session_repair_due, "MSG_AGAIN", @lid, ack}, waiting)

      assert resent.retry_counters == %{"session_repair|#{@lid}|MSG_AGAIN" => 2}
      refute_receive {:ex_wapp_delivery, "MSG_AGAIN", _, _}, 20
    end

    test "the rejection is reported once the repair budget is spent",
         %{session_id: session_id, ack: ack} do
      # The budget has to end somewhere: without a terminal verdict the pair
      # volleys a message between rejection and resend for as long as the server
      # keeps refusing it, and the caller waits through all of it.
      sup = start_supervised!({Task.Supervisor, name: :"repair_sup_spent_#{session_id}"})

      state = %Worker{
        session_id: session_id,
        store: nil,
        send_worker_sup: sup,
        runtime_cfg: %{
          send: %{max_session_repair_attempts: 2, session_repair_backoff_ms: [0, 30]}
        },
        retry_counters: %{"session_repair|#{@lid}|MSG_SPENT" => 2},
        outgoing_retry_payloads: %{"MSG_SPENT" => %{jid: @lid, text: "ciao"}}
      }

      assert {:noreply, new_state} =
               Worker.handle_info({:ack_session_rejection, "MSG_SPENT", @lid, ack}, state)

      assert new_state.retry_counters == %{"session_repair|#{@lid}|MSG_SPENT" => 2}
      assert_receive {:ex_wapp_delivery, "MSG_SPENT", :failed, %{error: ^ack}}
      refute_receive {:session_repair_due, "MSG_SPENT", _, _}, 50
    end

    test "the repair budget is counted per message, not per rejection JID",
         %{session_id: session_id, ack: ack} do
      # The counter is keyed by the JID the payload is resent to, while the
      # rejection arrives on whichever family the server chose to answer in.
      # Reading the count through the JID would restart the budget on every
      # cross-family ack and make it unbounded.
      sup = start_supervised!({Task.Supervisor, name: :"repair_sup_family_#{session_id}"})

      state = %Worker{
        session_id: session_id,
        store: nil,
        send_worker_sup: sup,
        runtime_cfg: %{
          send: %{max_session_repair_attempts: 2, session_repair_backoff_ms: [0, 30]}
        },
        retry_counters: %{"session_repair|#{@lid}|MSG_FAMILY" => 2},
        outgoing_retry_payloads: %{"MSG_FAMILY" => %{jid: @lid, text: "ciao"}}
      }

      assert {:noreply, _state} =
               Worker.handle_info({:ack_session_rejection, "MSG_FAMILY", @pn, ack}, state)

      assert_receive {:ex_wapp_delivery, "MSG_FAMILY", :failed, %{error: ^ack}}
    end
  end

  describe "outbound direct message envelope" do
    # WhatsApp answers a message it accepts with an <ack> and says *nothing* for
    # one it drops, so an unexpected attribute on this node costs a silent,
    # undiagnosable delivery failure. That is not hypothetical: adding
    # `peer_recipient_pn` here made every direct send vanish, and the test of
    # the day passed because it asserted the attributes the code produced
    # rather than the ones the protocol accepts.
    #
    # Pinning the exact key set is deliberate. A new attribute must fail here
    # and be justified against a live send, not merely be absorbed.
    @allowed_attrs ["id", "to", "type"]

    defp participant(jid),
      do: %Binary.Node{tag: "to", attrs: %{"jid" => jid}, content: []}

    test "carries no attribute beyond id/to/type for a phone destination" do
      node =
        Direct.build_encrypted_message_node(
          "15550001111:7@s.whatsapp.net",
          "message-id",
          [participant("15550001111:5@s.whatsapp.net")],
          Memory.new(),
          false
        )

      assert Enum.sort(Map.keys(node.attrs)) == @allowed_attrs
    end

    test "carries no attribute beyond id/to/type for a LID destination" do
      node =
        Direct.build_encrypted_message_node(
          @lid,
          "message-id",
          [participant("70000004444:6@lid")],
          Memory.new(),
          false
        )

      assert Enum.sort(Map.keys(node.attrs)) == @allowed_attrs
      assert node.attrs["to"] == @lid
    end

    test "a known privacy token travels as a child, never as an attribute" do
      # The PN is reachable from the LID here, which is exactly the state that
      # previously tempted the encoder into stamping it onto the envelope.
      store =
        Memory.new(
          initial_data: %{
            lid_mapping: %{{:pn_to_lid, @pn} => @lid, {:lid_to_pn, @lid} => @pn},
            tctokens: %{@pn => %{token: <<1, 2, 3, 4>>, timestamp: System.system_time(:second)}}
          }
        )

      node = Direct.build_encrypted_message_node(@lid, "message-id", [], store, false)

      assert Enum.sort(Map.keys(node.attrs)) == @allowed_attrs

      assert %Binary.Node{tag: "tctoken", content: %Binary.Raw{data: <<1, 2, 3, 4>>}} =
               List.last(node.content)
    end

    test "including the device identity does not change the attribute set" do
      node =
        Direct.build_encrypted_message_node(
          @lid,
          "message-id",
          [participant("70000004444:6@lid")],
          Memory.new(),
          true
        )

      assert Enum.sort(Map.keys(node.attrs)) == @allowed_attrs
    end
  end
end
