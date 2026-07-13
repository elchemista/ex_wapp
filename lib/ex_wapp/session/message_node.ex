defmodule ExWapp.Session.MessageNode do
  @moduledoc """
  Builders/parsers for encrypted message participant nodes.
  """

  alias ExWapp.Binary

  @doc false
  @spec enc_type_to_wire(atom() | String.t()) :: String.t()
  def enc_type_to_wire(:prekey), do: "pkmsg"
  def enc_type_to_wire(:whisper), do: "msg"
  def enc_type_to_wire("prekey"), do: "pkmsg"
  def enc_type_to_wire("pkmsg"), do: "pkmsg"
  def enc_type_to_wire("msg"), do: "msg"
  def enc_type_to_wire(_), do: "msg"

  @doc false
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

  @doc false
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

  @doc false
  @spec generate_participant_hash_v2(list()) :: String.t() | nil
  def generate_participant_hash_v2([]), do: nil

  def generate_participant_hash_v2(participants) when is_list(participants) do
    normalized =
      participants
      |> Enum.map(&jid_to_ad_string/1)
      |> Enum.sort()

    <<first_6_bytes::binary-size(6), _rest::binary>> =
      normalized
      |> Enum.join("")
      |> then(&:crypto.hash(:sha256, &1))

    "2:" <> Base.encode64(first_6_bytes, padding: false)
  end

  @doc """
  Converts a JID string to ADString format matching whatsmeow/whatsapp-rust.

  Format: `user.agent:device@server`
  Example: `1234567890@s.whatsapp.net` → `1234567890.0:0@s.whatsapp.net`
  Example: `1234567890:37@s.whatsapp.net` → `1234567890.0:37@s.whatsapp.net`
  """
  @spec jid_to_ad_string(term()) :: String.t()
  def jid_to_ad_string(jid) when is_binary(jid) do
    case String.split(jid, "@", parts: 2) do
      [user_part, server] ->
        {user, device} = parse_ad_user_and_device(user_part)

        "#{user}.0:#{device}@#{server}"

      _ ->
        jid
    end
  end

  def jid_to_ad_string(jid), do: to_string(jid)

  @spec parse_ad_user_and_device(String.t()) :: {String.t(), non_neg_integer()}
  defp parse_ad_user_and_device(user_part) do
    case String.split(user_part, ":", parts: 2) do
      [user, device_str] ->
        case Integer.parse(device_str) do
          {device_id, ""} -> {user, device_id}
          _ -> {user_part, 0}
        end

      _ ->
        {user_part, 0}
    end
  end

  @doc """
  Applies the stanza options shared by encrypted direct and group messages.

  Message type remains a stanza attribute. Media type is attached to each
  encrypted payload, and additional metadata nodes are appended after the
  encrypted content.
  """
  @spec apply_outbound_options(Binary.Node.t(), keyword()) :: Binary.Node.t()
  def apply_outbound_options(%Binary.Node{} = node, opts) when is_list(opts) do
    attrs = Map.put(node.attrs, "type", Keyword.get(opts, :message_node_type, "text"))
    node = %{node | attrs: Map.delete(attrs, "mediatype")}

    node
    |> put_encrypted_mediatype(Keyword.get(opts, :mediatype))
    |> append_additional_nodes(Keyword.get(opts, :additional_message_nodes, []))
  end

  @doc false
  @spec maybe_put_message_attr(map(), String.t(), term()) :: map()
  def maybe_put_message_attr(attrs, _key, nil), do: attrs
  def maybe_put_message_attr(attrs, key, value), do: Map.put(attrs, key, value)

  @spec put_encrypted_mediatype(Binary.Node.t(), term()) :: Binary.Node.t()
  defp put_encrypted_mediatype(%Binary.Node{} = node, mediatype)
       when is_binary(mediatype) and mediatype != "" do
    updated_content =
      if direct_encrypted_content?(node.content) do
        Enum.map(node.content, &put_direct_encrypted_mediatype(&1, mediatype))
      else
        Enum.map(node.content, &put_participant_encrypted_mediatype(&1, mediatype))
      end

    %{node | content: updated_content}
  end

  defp put_encrypted_mediatype(%Binary.Node{} = node, _mediatype), do: node

  @spec direct_encrypted_content?([term()]) :: boolean()
  defp direct_encrypted_content?(content) do
    Enum.any?(content, &match?(%Binary.Node{tag: "enc"}, &1))
  end

  @spec put_direct_encrypted_mediatype(term(), String.t()) :: term()
  defp put_direct_encrypted_mediatype(%Binary.Node{tag: "enc"} = node, mediatype) do
    %{node | attrs: Map.put(node.attrs || %{}, "mediatype", mediatype)}
  end

  defp put_direct_encrypted_mediatype(node, _mediatype), do: node

  @spec put_participant_encrypted_mediatype(term(), String.t()) :: term()
  defp put_participant_encrypted_mediatype(
         %Binary.Node{tag: "participants", content: participants} = node,
         mediatype
       )
       when is_list(participants) do
    updated_participants =
      Enum.map(participants, fn
        %Binary.Node{tag: "to", content: encrypted_nodes} = participant
        when is_list(encrypted_nodes) ->
          updated_nodes =
            Enum.map(encrypted_nodes, &put_direct_encrypted_mediatype(&1, mediatype))

          %{participant | content: updated_nodes}

        participant ->
          participant
      end)

    %{node | content: updated_participants}
  end

  defp put_participant_encrypted_mediatype(node, _mediatype), do: node

  @spec append_additional_nodes(Binary.Node.t(), term()) :: Binary.Node.t()
  defp append_additional_nodes(%Binary.Node{} = node, additional_nodes)
       when is_list(additional_nodes) do
    %{node | content: node.content ++ additional_nodes}
  end

  defp append_additional_nodes(%Binary.Node{} = node, _additional_nodes), do: node
end
