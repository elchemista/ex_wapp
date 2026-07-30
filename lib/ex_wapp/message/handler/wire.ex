defmodule ExWapp.Message.Handler.Wire do
  @moduledoc """
  Compatibility façade for inbound XML-envelope and protobuf wire helpers.

  XML envelope extraction remains here; supported WhatsApp content decoding
  lives in `Wire.ContentDecoder`, which works on the generated protos.
  """

  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.Common
  alias ExWapp.Message.Handler.Wire.ContentDecoder

  @typep enc_candidate :: %{
           enc_type: binary(),
           enc_version: term(),
           enc_count: non_neg_integer() | nil,
           ciphertext: binary() | nil,
           to_jid: binary()
         }

  @doc false
  @spec extract_message_content(term(), term()) :: map()
  def extract_message_content(nil, _type), do: %{text: nil, media: nil}

  def extract_message_content(content, _type) when is_binary(content),
    do: %{text: content, media: nil}

  def extract_message_content(content, _type) when is_list(content) do
    enc_candidates = extract_enc_candidates(content)
    extract_list_message_content(content, enc_candidates)
  end

  def extract_message_content(_, _), do: %{text: nil, media: nil}

  @doc false
  @spec apply_media_from_plaintext(map(), binary()) :: map()
  def apply_media_from_plaintext(message_data, plaintext) do
    ContentDecoder.apply_media_from_plaintext(message_data, plaintext)
  end

  @spec extract_list_message_content(term(), [enc_candidate()]) :: map()
  defp extract_list_message_content(
         _content,
         [%{enc_type: enc_type, enc_version: enc_version, ciphertext: ciphertext} | _] =
           enc_candidates
       ) do
    %{
      text: "(encrypted: #{enc_type})",
      media: nil,
      encrypted: true,
      enc_type: enc_type,
      enc_version: enc_version,
      enc_count: Map.get(List.first(enc_candidates) || %{}, :enc_count),
      ciphertext: ciphertext,
      enc_candidates: enc_candidates
    }
  end

  defp extract_list_message_content(content, []) do
    case Common.find_child_node(content, "unavailable") do
      %Node{} = unavailable_node ->
        %{
          text: nil,
          media: nil,
          placeholder_unavailable: true,
          unavailable_type: Common.node_attr(unavailable_node, "type")
        }

      _ ->
        extract_plain_body_content(content)
    end
  end

  @spec extract_plain_body_content(term()) :: map()
  defp extract_plain_body_content(content) do
    case Common.find_child_node(content, "body") do
      %Node{content: body} when is_binary(body) -> %{text: body, media: nil}
      _ -> %{text: nil, media: nil}
    end
  end

  @spec extract_enc_candidates(list()) :: [enc_candidate()]
  defp extract_enc_candidates(content) when is_list(content) do
    do_extract_enc_candidates(content, nil, [])
    |> Enum.reverse()
  end

  @spec do_extract_enc_candidates(list(), term(), [enc_candidate()]) :: [enc_candidate()]
  defp do_extract_enc_candidates([], _current_to_jid, acc), do: acc

  defp do_extract_enc_candidates([node | rest], current_to_jid, acc) do
    acc =
      case node do
        %Node{tag: "enc", attrs: enc_attrs, content: enc_content} ->
          [
            %{
              enc_type: Map.get(enc_attrs, "type", "msg"),
              enc_version: Common.parse_enc_version(Map.get(enc_attrs, "v")),
              enc_count: Common.parse_non_neg_integer(Map.get(enc_attrs, "count")),
              ciphertext: Common.normalize_content(enc_content),
              to_jid: Common.normalize_jid_with_device(current_to_jid)
            }
            | acc
          ]

        %Node{tag: "to", attrs: to_attrs, content: nested} when is_list(nested) ->
          do_extract_enc_candidates(nested, Map.get(to_attrs, "jid"), acc)

        %Node{content: nested} when is_list(nested) ->
          do_extract_enc_candidates(nested, current_to_jid, acc)

        _ ->
          acc
      end

    do_extract_enc_candidates(rest, current_to_jid, acc)
  end
end
