defmodule ExWapp.Store.CodecTest do
  use ExUnit.Case, async: true

  alias ExWapp.{Chat, Contact, JID}
  alias ExWapp.Store.Codec
  alias ExWapp.Proto.SyncAction

  test "roundtrips nested store data with structs, tuples, atoms, and binaries" do
    payload = %{
      client_info: %{
        jid: %JID{user: "12025550123", device: 7, server: "s.whatsapp.net"},
        push_name: "Alice"
      },
      signal: %{
        identity_key: <<0, 255, 10, 42>>,
        account_type: :primary
      },
      chats: %{
        "12025550123@s.whatsapp.net" => %Chat{
          jid: "12025550123@s.whatsapp.net",
          name: "Alice",
          messages: [
            %{
              id: "wamid-1",
              from_me: false,
              timestamp: 1_773_760_867,
              text: "hello",
              status: :received,
              raw: %{binary: <<1, 2, 3, 4>>}
            }
          ]
        }
      },
      contacts: %{
        "12025550123@s.whatsapp.net" => %Contact{
          jid: "12025550123@s.whatsapp.net",
          full_name: "Alice Example"
        }
      },
      lid_mapping: %{
        {:pn, "12025550123@s.whatsapp.net"} => {:lid, "123456789@lid"}
      },
      adv: %WAAdv.ADVSignedDeviceIdentity{
        details: <<4, 5, 6>>,
        accountSignatureKey: <<7, 8>>,
        accountSignature: <<9, 10>>,
        deviceSignature: <<11, 12>>
      },
      sync: %SyncAction.ContactAction{
        full_name: "Alice Example",
        first_name: "Alice"
      }
    }

    assert {:ok, blob} = Codec.encode(payload)
    assert true == Codec.encoded?(blob)
    assert {:ok, decoded} = Codec.decode(blob)
    assert decoded == payload
  end

  test "returns unknown_codec for non-codec blobs" do
    assert {:error, :unknown_codec} = Codec.decode(:erlang.term_to_binary(%{legacy: true}))
  end

  test "rejects corrupted codec blobs" do
    assert {:ok, blob} = Codec.encode(%{foo: "bar"})
    corrupted = binary_part(blob, 0, byte_size(blob) - 3) <> <<0, 1, 2>>
    assert {:error, :invalid_store_blob} = Codec.decode(corrupted)
  end
end
