defmodule ExWapp.PrekeyFetcherProtocolTest do
  use ExUnit.Case, async: true
  alias ExWapp.Binary
  alias ExWapp.Binary.Node
  alias ExWapp.Signal.{Keys, PrekeyFetcher, SessionStore}

  defmodule Directory do
    use GenServer
    def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
    def init(opts), do: {:ok, opts}

    def handle_call({:send_iq, node, id}, _from, opts) do
      send(opts.owner, {:directory_request, Binary.decode!(Binary.encode!(node)), id})

      response =
        case opts.response do
          %Node{} = response -> {:ok, Binary.decode!(Binary.encode!(response))}
          error -> error
        end

      {:reply, response, opts}
    end
  end

  setup do
    identity = Keys.generate_key_pair()
    signed = Keys.generate_signed_prekey(identity, 257)
    prekey = Keys.generate_prekey(65537)
    %{identity: identity, signed: signed, prekey: prekey}
  end

  test "wire bundle establishes a usable Signal session and preserves recipient device", ctx do
    recipient = "15550001111:7@s.whatsapp.net"
    peer = directory(response([user(recipient, ctx)]))
    assert {:ok, bundle} = PrekeyFetcher.fetch_prekeys(peer, recipient)
    assert_receive {:directory_request, request, id}

    assert Map.take(request.attrs, ["id", "type", "xmlns"]) == %{
             "id" => id,
             "type" => "get",
             "xmlns" => "encrypt"
           }

    assert to_string(request.attrs["to"]) == "s.whatsapp.net"
    assert [%Node{tag: "key", content: [%Node{attrs: %{"jid" => target}}]}] = request.content
    assert to_string(target) == recipient
    assert bundle.registration_id == 8193
    assert bundle.signed_prekey.id == 257
    assert bundle.prekey.id == 65537
    alice = Keys.generate_key_pair()

    assert {:ok, ciphertext, :prekey, _} =
             SessionStore.encrypt_message(
               SessionStore.new(),
               recipient,
               "private message",
               alice,
               123,
               bundle
             )

    assert {:ok, "private message", _} =
             SessionStore.decrypt_message(
               SessionStore.new(),
               "15550002222:1@s.whatsapp.net",
               ciphertext,
               true,
               ctx.identity,
               %{signed_prekeys: %{257 => ctx.signed}, prekeys: %{65537 => ctx.prekey}}
             )
  end

  test "batch isolates unavailable devices while retaining usable signed-only bundles", ctx do
    good = user("1555:2@s.whatsapp.net", ctx)

    signed_only = %{
      good
      | attrs: %{"jid" => "1555:3@s.whatsapp.net"},
        content: Enum.reject(good.content, &(&1.tag == "key"))
    }

    bad = %Node{
      tag: "user",
      attrs: %{"jid" => "1555:4@s.whatsapp.net"},
      content: [%Node{tag: "error", attrs: %{"code" => "404"}}]
    }

    peer = directory(response([good, signed_only, bad, %Node{tag: "other"}]))

    assert {:ok, bundles} =
             PrekeyFetcher.fetch_prekeys_batch(peer, [
               "1555:2@s.whatsapp.net",
               "1555:3@s.whatsapp.net",
               "1555:4@s.whatsapp.net"
             ])

    assert map_size(bundles) == 2
    assert bundles["1555:3@s.whatsapp.net"].prekey == nil
    assert bundles["1555:2@s.whatsapp.net"].identity_key == ctx.identity.public
  end

  test "malformed responses and transport failures never produce usable bundles", ctx do
    complete = user("1555@s.whatsapp.net", ctx)

    cases = [
      {%Node{tag: "ack"}, :invalid_response},
      {%Node{tag: "iq", content: [%Node{tag: "other"}]}, :invalid_prekey_response},
      {response([%Node{tag: "other"}]), :no_prekeys_in_response},
      {response([%Node{tag: "user"}]), :invalid_user_node},
      {response([%{complete | content: Enum.reject(complete.content, &(&1.tag == "identity"))}]),
       :incomplete_bundle},
      {{:error, :timeout}, :timeout}
    ]

    for {response, reason} <- cases do
      peer = directory(response)
      assert {:error, ^reason} = PrekeyFetcher.fetch_prekeys(peer, "1555@s.whatsapp.net")
    end

    for {response, reason} <- Enum.take(cases, 2) ++ [{{:error, :disconnected}, :disconnected}] do
      assert {:error, ^reason} =
               PrekeyFetcher.fetch_prekeys_batch(directory(response), ["1555@s.whatsapp.net"])
    end
  end

  defp directory(response),
    do:
      start_supervised!(%{
        id: make_ref(),
        start: {Directory, :start_link, [%{owner: self(), response: response}]}
      })

  defp response(users), do: %Node{tag: "iq", content: [%Node{tag: "list", content: users}]}
  defp raw(tag, bytes), do: %Node{tag: tag, content: Binary.raw(bytes)}

  defp user(jid, ctx) do
    %Node{
      tag: "user",
      attrs: %{"jid" => jid},
      content: [
        raw("registration", <<8193::32>>),
        raw("identity", ctx.identity.public),
        raw("type", <<5>>),
        %Node{
          tag: "skey",
          content: [
            raw("id", <<257::24>>),
            raw("value", ctx.signed.public),
            raw("signature", ctx.signed.signature)
          ]
        },
        %Node{tag: "key", content: [raw("id", <<65537::24>>), raw("value", ctx.prekey.public)]}
      ]
    }
  end
end
