defmodule ExWapp.Message.Handler.Wire do
  @moduledoc """
  Compatibility façade for inbound XML-envelope and protobuf wire helpers.

  XML envelope extraction remains here. Generic protobuf primitives live in
  `Wire.Fields`; supported WhatsApp content decoding lives in
  `Wire.ContentDecoder`.
  """

  alias ExWapp.Binary.Node
  alias ExWapp.Message.Handler.Common
  alias ExWapp.Message.Handler.Wire.{ContentDecoder, Fields}

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

  @doc false
  @spec classify_decrypted_content(binary(), non_neg_integer()) ::
          {:protocol | :user_message, binary() | nil}
  def classify_decrypted_content(payload, sender_key_distribution_count) do
    ContentDecoder.classify_decrypted_content(payload, sender_key_distribution_count)
  end

  @doc false
  @spec decode_wire_fields_safe(binary()) :: {:ok, [Fields.wire_field()]} | {:error, term()}
  def decode_wire_fields_safe(binary), do: Fields.decode_safe(binary)

  @doc false
  @spec find_first_ld_field([Fields.wire_field()], non_neg_integer()) :: binary() | nil
  def find_first_ld_field(fields, field_num), do: Fields.first_length_delimited(fields, field_num)

  @doc false
  @spec find_all_ld_fields([Fields.wire_field()], non_neg_integer()) :: [binary()]
  def find_all_ld_fields(fields, field_num), do: Fields.all_length_delimited(fields, field_num)

  @doc false
  @spec find_first_varint_field([Fields.wire_field()], non_neg_integer()) :: integer() | nil
  def find_first_varint_field(fields, field_num), do: Fields.first_varint(fields, field_num)

  @doc false
  @spec find_length_delimited_field(binary(), non_neg_integer()) ::
          {:ok, binary()} | {:error, term()}
  def find_length_delimited_field(binary, field_num),
    do: Fields.find_length_delimited(binary, field_num)

  @doc false
  @spec field_bytes(binary(), non_neg_integer()) :: binary() | nil
  def field_bytes(payload, field), do: Fields.bytes(payload, field)

  @doc false
  @spec field_varint(binary(), non_neg_integer()) :: integer() | nil
  def field_varint(payload, field), do: Fields.varint(payload, field)

  @doc false
  @spec field_bool(binary(), non_neg_integer()) :: boolean() | nil
  def field_bool(payload, field), do: Fields.bool(payload, field)

  @doc false
  @spec field_double(binary(), non_neg_integer()) :: float() | nil
  def field_double(payload, field), do: Fields.double(payload, field)

  @doc false
  @spec field_float(binary(), non_neg_integer()) :: float() | nil
  def field_float(payload, field), do: Fields.float(payload, field)

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
