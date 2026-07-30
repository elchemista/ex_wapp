defmodule ExWapp.KeyMaterialAnnouncementTest do
  @moduledoc """
  Coverage for telling the host when its archive has fallen behind.

  A host that keeps the session file on a disk it can lose archives that file on
  a timer. Between two archives, this client can hand WhatsApp — or a peer
  directly — public halves whose private halves exist only in the live store. If
  the process dies inside that window, the archive comes back advertising keys
  nothing can decrypt with, and every peer that draws one is locked out of a
  session with no way to recover it.

  The interval cannot be tuned narrow enough to make that safe, because the
  window opens on an event, not on a schedule. So the event is published and the
  host can archive on it.
  """

  use ExUnit.Case, async: true

  alias ExWapp.Binary
  alias ExWapp.Session.Worker.{PostAuth, ReceiptBuilder}
  alias ExWapp.Signal.Keys
  alias ExWapp.Store.Memory

  setup do
    session_id = "key-material-#{System.unique_integer([:positive])}"
    Phoenix.PubSub.subscribe(ExWapp.PubSub, "ex_wapp:session:#{session_id}")
    {:ok, session_id: session_id}
  end

  test "a retry receipt's fresh key is announced", %{session_id: session_id} do
    # This key never went through the server: it is handed straight to the peer
    # inside the receipt, so the peer can be using it before anything durable
    # knows it exists.
    store = store_with_keys()

    receipt =
      ReceiptBuilder.build_retry_receipt_ack(
        store,
        %{
          to: "15550007777@s.whatsapp.net",
          id: "RETRY_ANNOUNCED",
          participant: nil,
          message_t: "1730000300",
          retry_count: 1,
          error_code: 0,
          retry_meta: %{force_keys?: true}
        },
        %{session_id: session_id}
      )

    assert %Binary.Node{tag: "keys"} = List.last(receipt.content)

    assert_receive {:ex_wapp_session, :key_material_advertised,
                    %{reason: :retry_prekey, highest_prekey_id: id}}

    assert is_integer(id)
  end

  test "no announcement when the receipt carries no keys", %{session_id: session_id} do
    store = store_with_keys()

    ReceiptBuilder.build_retry_receipt_ack(
      store,
      %{
        to: "15550007777@s.whatsapp.net",
        id: "RETRY_PLAIN",
        participant: nil,
        message_t: "1730000300",
        retry_count: 1,
        error_code: 0,
        retry_meta: %{}
      },
      %{session_id: session_id}
    )

    refute_receive {:ex_wapp_session, :key_material_advertised, _meta}, 50
  end

  test "an accepted prekey upload is announced", %{session_id: session_id} do
    # The server starts serving these to any peer that asks the moment it
    # answers, which is the moment the gap opens.
    state = %{
      session_id: session_id,
      store: Memory.new([]),
      pending_prekey_upload: [
        %{key_id: 41, public: <<0>>, private: <<0>>},
        %{key_id: 42, public: <<0>>, private: <<0>>}
      ],
      post_auth_phase: :awaiting_prekey_upload,
      passive_iq_id: nil
    }

    PostAuth.handle_prekey_upload_response(
      %Binary.Node{tag: "iq", attrs: %{}},
      "result",
      state,
      &passive_iq/0
    )

    assert_receive {:ex_wapp_session, :key_material_advertised,
                    %{reason: :prekey_upload, highest_prekey_id: 42, count: 2}}
  end

  test "a rejected prekey upload is not announced", %{session_id: session_id} do
    # Nothing was advertised, so nothing is at risk and the host has no reason to
    # spend an archive write.
    state = %{
      session_id: session_id,
      store: Memory.new([]),
      pending_prekey_upload: [%{key_id: 41, public: <<0>>, private: <<0>>}],
      post_auth_phase: :awaiting_prekey_upload,
      passive_iq_id: nil
    }

    PostAuth.handle_prekey_upload_response(
      %Binary.Node{tag: "iq", attrs: %{"type" => "error"}},
      "error",
      state,
      &passive_iq/0
    )

    refute_receive {:ex_wapp_session, :key_material_advertised, _meta}, 50
  end

  defp store_with_keys do
    identity = Keys.generate_key_pair()
    signed_prekey = Keys.generate_signed_prekey(identity, 1)

    store =
      Memory.new(
        initial_data: %{
          pairing: %{device_identity: <<1, 2, 3, 4>>},
          signal: %{
            identity_key: identity,
            registration_id: 26_581,
            signed_prekeys: %{1 => signed_prekey},
            prekeys: %{},
            next_prekey_id: 1
          }
        }
      )

    on_exit(fn -> Memory.stop(store) end)
    store
  end

  defp passive_iq, do: %Binary.Node{tag: "iq", attrs: %{"id" => "passive"}, content: nil}
end
