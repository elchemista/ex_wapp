defmodule ExWapp.LinkCodePairingTest do
  use ExUnit.Case, async: false

  alias ExWapp.{Binary, Config, MessageHandler, Noise, Pairing, Store}
  alias ExWapp.Binary.{Node, Raw}
  alias ExWapp.Noise.ClientPayload, as: NoiseClientPayload
  alias ExWapp.Pairing.LinkCode
  alias ExWapp.Session.OutboundQueue
  alias ExWapp.Signal.Keys
  alias WAWebProtobufsWa6.ClientPayload, as: ClientPayloadProto

  defmodule TestTransport do
    def send_node(test_pid, node) when is_pid(test_pid) do
      send(test_pid, {:transport_send, node})
      :ok
    end

    def restart_stream(_test_pid), do: :ok
  end

  test "Crockford encoding and PBKDF2 match external protocol vectors" do
    assert LinkCode.crockford_encode(<<0, 1, 2, 3, 4>>) == "111H51R5"

    salt = :binary.copy(<<7>>, 32)

    expected =
      Base.decode16!("53F722816410C86D5216D645032297D9F368F24AC925C8B9911B995A789B1EF0")

    assert LinkCode.derive_pairing_code_key("ABCD2345", salt) == expected
  end

  test "request frames companion_hello and wraps the persisted ephemeral key" do
    {store, credentials} = credential_store()

    assert {:ok, request} =
             LinkCode.request(
               store,
               "+1 (555) 123-4567",
               [custom_code: "ABCD2345"],
               Config.defaults()
             )

    assert request.code == "ABCD2345"
    assert request.jid == "15551234567@s.whatsapp.net"
    assert request.node.tag == "iq"

    assert Map.take(request.node.attrs, ["to", "type", "xmlns", "id"]) == %{
             "to" => "s.whatsapp.net",
             "type" => "set",
             "xmlns" => "md",
             "id" => request.request_id
           }

    registration = child!(request.node, "link_code_companion_reg")

    assert registration.attrs == %{
             "jid" => request.jid,
             "stage" => "companion_hello",
             "should_show_push_notification" => "true"
           }

    wrapped = child_content!(registration, "link_code_pairing_wrapped_companion_ephemeral_pub")
    assert byte_size(wrapped) == 80

    assert child_content!(registration, "companion_server_auth_key_pub") ==
             credentials.noise.public

    assert child_content!(registration, "companion_platform_id") == "3"
    assert child_content!(registration, "companion_platform_display") == "Firefox (Linux x86_64)"
    assert child_content!(registration, "link_code_pairing_nonce") == "0"

    persisted = Store.load!(store)
    pending = persisted.link_code_pairing
    assert pending.status == :pending
    assert pending.code == "ABCD2345"
    assert pending.jid == request.jid
    assert pending.request_id == request.request_id
    assert persisted.identity == credentials.identity

    <<salt::binary-size(32), iv::binary-size(16), ciphertext::binary-size(32)>> = wrapped
    key = LinkCode.derive_pairing_code_key(request.code, salt)
    unwrapped = :crypto.crypto_one_time(:aes_256_ctr, key, iv, ciphertext, false)
    assert unwrapped == pending.ephemeral_key.public
  end

  test "random request codes use the exact eight-character WhatsApp alphabet" do
    {store, _credentials} = credential_store()
    assert {:ok, %{code: code}} = LinkCode.request(store, "15551234567")
    assert byte_size(code) == 8
    assert code =~ ~r/^[123456789ABCDEFGHJKLMNPQRSTVWXYZ]{8}$/
  end

  test "custom code, phone, and already-paired validation fail before wire state changes" do
    {store, _credentials} = credential_store()

    assert {:error, :custom_pairing_code_must_be_8_chars} =
             LinkCode.request(store, "15551234567", custom_code: "SHORT")

    assert {:error, :custom_pairing_code_must_be_8_chars} =
             LinkCode.request(store, "15551234567", custom_code: "TOO-LONG9")

    assert {:error, :invalid_phone_number} =
             LinkCode.request(store, "not-a-number", custom_code: "ABCD2345")

    assert Map.get(Store.load!(store), :link_code_pairing) == nil

    paired =
      Store.load!(store)
      |> Map.put(:client_info, %{jid: "15550000000@s.whatsapp.net"})

    :ok = Store.persist(store, paired)

    assert {:error, :already_paired} =
             LinkCode.request(store, "15551234567", custom_code: "ABCD2345")
  end

  test "notification completes the cryptographic flow, rotates ADV and emits finish after ack" do
    {store, credentials} = credential_store()

    assert {:ok, request} =
             LinkCode.request(store, "15551234567", custom_code: "ABCD2345")

    pending = Store.load!(store).link_code_pairing
    primary_identity = Keys.generate_key_pair()
    phone_ephemeral = Keys.generate_key_pair()

    notification =
      finish_notification(
        request.code,
        primary_identity.public,
        phone_ephemeral.public,
        "pair-ref-123"
      )

    state = %{
      store: store,
      pairing: Pairing.mark_waiting_for_code(Pairing.new(store), request.request_id)
    }

    assert {:ok, next_state,
            [
              {:send_node, %Node{tag: "ack"}},
              {:send_node, %Node{tag: "iq"} = finish},
              {:status, :success},
              {:pairing_success, :link_code, "15551234567@s.whatsapp.net"}
            ]} = MessageHandler.handle_node(notification, self(), state)

    assert next_state.pairing.status == :paired
    assert finish.attrs["xmlns"] == "md"
    assert finish.attrs["type"] == "set"
    assert finish.attrs["to"] == "s.whatsapp.net"

    registration = child!(finish, "link_code_companion_reg")
    assert registration.attrs["stage"] == "companion_finish"
    assert registration.attrs["jid"] == request.jid
    assert child_content!(registration, "link_code_pairing_ref") == "pair-ref-123"

    assert child_content!(registration, "companion_identity_public") ==
             credentials.identity.public

    encrypted_bundle = child_content!(registration, "link_code_pairing_wrapped_key_bundle")
    assert byte_size(encrypted_bundle) == 156

    companion_shared =
      :crypto.compute_key(
        :ecdh,
        pending.ephemeral_key.public,
        phone_ephemeral.private,
        :x25519
      )

    <<bundle_salt::binary-size(32), bundle_iv::binary-size(12), ciphertext::binary-size(96),
      tag::binary-size(16)>> = encrypted_bundle

    bundle_key =
      LinkCode.hkdf_sha256(
        companion_shared,
        bundle_salt,
        "link_code_pairing_key_bundle_encryption_key",
        32
      )

    assert plaintext =
             :crypto.crypto_one_time_aead(
               :aes_256_gcm,
               bundle_key,
               bundle_iv,
               ciphertext,
               <<>>,
               tag,
               false
             )

    assert <<identity_public::binary-size(32), received_primary::binary-size(32),
             random::binary-size(32)>> = plaintext

    assert identity_public == credentials.identity.public
    assert received_primary == primary_identity.public

    identity_shared =
      :crypto.compute_key(
        :ecdh,
        credentials.identity.public,
        primary_identity.private,
        :x25519
      )

    expected_adv =
      LinkCode.hkdf_sha256(
        companion_shared <> identity_shared <> random,
        <<>>,
        "adv_secret",
        32
      )

    persisted = Store.load!(store)
    assert persisted.adv_secret == expected_adv
    assert persisted.adv_secret != credentials.adv_secret
    assert persisted.client_info.jid == request.jid
    assert persisted.pairing.device.jid == request.jid
    assert persisted.pairing.via == :link_code
    assert persisted.link_code_pairing.status == :registered
    refute Map.has_key?(persisted.link_code_pairing, :code)
    refute Map.has_key?(persisted.link_code_pairing, :ephemeral_key)

    assert {:ok, reconnect_payload, _updated_data} =
             NoiseClientPayload.build(%Noise{store: store}, Config.defaults())

    assert {:ok, decoded_reconnect} = ClientPayloadProto.decode(reconnect_payload)
    assert decoded_reconnect.username == 15_551_234_567
    assert decoded_reconnect.device == 0
    assert decoded_reconnect.passive == true
    assert decoded_reconnect.devicePairingData == nil
  end

  test "a fieldless link-code notification is acknowledged and skipped without mutation" do
    {store, _credentials} = credential_store()
    assert {:ok, request} = LinkCode.request(store, "15551234567")
    before = Store.load!(store)

    notification = %Node{
      tag: "notification",
      attrs: %{
        "type" => "link_code_companion_reg",
        "id" => "fieldless-1",
        "from" => "s.whatsapp.net"
      },
      content: [%Node{tag: "link_code_companion_reg", attrs: %{}, content: nil}]
    }

    state = %{
      store: store,
      pairing: Pairing.mark_waiting_for_code(Pairing.new(store), request.request_id)
    }

    assert {:ok, ^state, [{:send_node, %Node{tag: "ack"}}]} =
             MessageHandler.handle_node(notification, self(), state)

    assert Store.load!(store) == before
  end

  test "malformed wrapped primary key is reported without rotating credentials" do
    {store, credentials} = credential_store()
    assert {:ok, request} = LinkCode.request(store, "15551234567")

    notification = %Node{
      tag: "notification",
      attrs: %{
        "type" => "link_code_companion_reg",
        "id" => "bad-wrap-1",
        "from" => "s.whatsapp.net"
      },
      content: [
        %Node{
          tag: "link_code_companion_reg",
          attrs: %{},
          content: [
            raw_child("link_code_pairing_ref", "ref"),
            raw_child("primary_identity_pub", Keys.generate_key_pair().public),
            raw_child(
              "link_code_pairing_wrapped_primary_ephemeral_pub",
              :crypto.strong_rand_bytes(79)
            )
          ]
        }
      ]
    }

    state = %{
      store: store,
      pairing: Pairing.mark_waiting_for_code(Pairing.new(store), request.request_id)
    }

    assert {:ok, ^state,
            [
              {:send_node, %Node{tag: "ack"}},
              {:error, {:link_code_pairing, {:invalid_length, :wrapped_primary_ephemeral}}}
            ]} = MessageHandler.handle_node(notification, self(), state)

    persisted = Store.load!(store)
    assert persisted.adv_secret == credentials.adv_secret
    assert persisted.link_code_pairing.status == :pending
  end

  test "public Session API queues hello and publishes the pairing code event" do
    {:ok, session} =
      GenServer.start(ExWapp.Session.Worker,
        store: ExWapp.Store.Memory,
        transport: TestTransport,
        runtime: [health: [check_interval_ms: 60_000]]
      )

    on_exit(fn -> safe_stop(session) end)

    store = GenServer.call(session, :get_store)
    credentials = credentials()
    :ok = Store.persist(store, credentials.data)

    state = :sys.get_state(session)
    OutboundQueue.set_conn(state.outbound_queue, self())
    _queue_state = :sys.get_state(state.outbound_queue)

    :sys.replace_state(session, fn worker_state ->
      %{
        worker_state
        | status: :handshaking,
          transport_ready?: true,
          conn: self()
      }
    end)

    assert {:ok, subscription} = ExWapp.Session.subscribe_qr(session)

    assert {:ok, "ABCD2345"} =
             ExWapp.request_pairing_code(
               session,
               "+1 (555) 123-4567",
               custom_code: "ABCD2345"
             )

    assert_receive {:ex_wapp_qr, ^subscription, {:pairing_code, "ABCD2345"}}

    assert_receive {:transport_send,
                    %Node{
                      tag: "iq",
                      content: [
                        %Node{
                          tag: "link_code_companion_reg",
                          attrs: %{
                            "jid" => "15551234567@s.whatsapp.net",
                            "stage" => "companion_hello"
                          }
                        }
                      ]
                    }},
                   1_000

    assert :sys.get_state(session).pairing.status == :waiting_for_code
  end

  test "public Session API refuses pairing before transport authentication is ready" do
    {:ok, session} = ExWapp.start_link(store: ExWapp.Store.Memory)
    on_exit(fn -> safe_stop(session) end)

    assert {:error, {:pairing_not_ready, :idle}} =
             ExWapp.request_pairing_code(session, "15551234567")
  end

  defp credential_store do
    credentials = credentials()
    {Store.Memory.new(initial_data: credentials.data), credentials}
  end

  defp credentials do
    identity = Keys.generate_key_pair()
    noise = Keys.generate_key_pair()
    adv_secret = :crypto.strong_rand_bytes(32)

    %{
      identity: identity,
      noise: noise,
      adv_secret: adv_secret,
      data: %{
        signal: %{identity_key: identity},
        noise: %{static_public: noise.public, static_private: noise.private},
        adv_secret: adv_secret
      }
    }
  end

  defp finish_notification(code, primary_identity_public, phone_ephemeral_public, ref) do
    salt = :crypto.strong_rand_bytes(32)
    iv = :crypto.strong_rand_bytes(16)
    key = LinkCode.derive_pairing_code_key(code, salt)

    wrapped =
      salt <>
        iv <>
        :crypto.crypto_one_time(
          :aes_256_ctr,
          key,
          iv,
          phone_ephemeral_public,
          true
        )

    %Node{
      tag: "notification",
      attrs: %{
        "type" => "link_code_companion_reg",
        "id" => "link-finish-1",
        "from" => "s.whatsapp.net"
      },
      content: [
        %Node{
          tag: "link_code_companion_reg",
          attrs: %{},
          content: [
            raw_child("link_code_pairing_ref", ref),
            raw_child("primary_identity_pub", primary_identity_public),
            raw_child("link_code_pairing_wrapped_primary_ephemeral_pub", wrapped)
          ]
        }
      ]
    }
  end

  defp raw_child(tag, content),
    do: %Node{tag: tag, attrs: %{}, content: Binary.raw(content)}

  defp child!(%Node{content: children}, tag) when is_list(children) do
    Enum.find(children, &match?(%Node{tag: ^tag}, &1)) || flunk("missing child #{tag}")
  end

  defp child_content!(node, tag) do
    case child!(node, tag).content do
      %Raw{data: data} -> IO.iodata_to_binary(data)
      data when is_binary(data) -> data
    end
  end

  defp safe_stop(pid) do
    if Process.alive?(pid), do: GenServer.stop(pid)
  catch
    :exit, _reason -> :ok
  end
end
