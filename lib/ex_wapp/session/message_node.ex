defmodule ExWapp.Session.MessageNode do
  @moduledoc """
  Builders/parsers for encrypted message participant nodes.
  """

  alias ExWapp.Binary

  @spec enc_type_to_wire(atom() | String.t()) :: String.t()
  def enc_type_to_wire(:prekey), do: "pkmsg"
  def enc_type_to_wire(:whisper), do: "msg"
  def enc_type_to_wire("prekey"), do: "pkmsg"
  def enc_type_to_wire("pkmsg"), do: "pkmsg"
  def enc_type_to_wire("msg"), do: "msg"
  def enc_type_to_wire(_), do: "msg"

  @spec build_participant_encrypted_node(String.t(), binary(), atom() | String.t()) ::
          Binary.Node.t()
  def build_participant_encrypted_node(jid, ciphertext, enc_type) do
    %Binary.Node{
      tag: "to",
      attrs: %{"jid" => jid},
      content: [
        %Binary.Node{
          tag: "enc",
          attrs: %{
            "v" => "2",
            "type" => enc_type_to_wire(enc_type)
          },
          content: Binary.raw(ciphertext)
        }
      ]
    }
  end

  @spec extract_participant_jids(term()) :: [String.t()]
  def extract_participant_jids(participant_nodes) when is_list(participant_nodes) do
    participant_nodes
    |> Enum.map(fn
      %Binary.Node{attrs: attrs} -> Map.get(attrs, "jid", "")
      _ -> ""
    end)
    |> Enum.reject(&(&1 == ""))
  end

  def extract_participant_jids(_), do: []

  @spec generate_participant_hash_v2(list()) :: String.t() | nil
  def generate_participant_hash_v2([]), do: nil

  def generate_participant_hash_v2(participants) when is_list(participants) do
    normalized =
      participants
      |> Enum.map(&to_string/1)
      |> Enum.sort()

    <<first_6_bytes::binary-size(6), _rest::binary>> =
      normalized
      |> Enum.join("")
      |> then(&:crypto.hash(:sha256, &1))

    "2:" <> Base.encode64(first_6_bytes, padding: false)
  end

  @spec maybe_put_message_attr(map(), String.t(), term()) :: map()
  def maybe_put_message_attr(attrs, _key, nil), do: attrs
  def maybe_put_message_attr(attrs, key, value), do: Map.put(attrs, key, value)
end
