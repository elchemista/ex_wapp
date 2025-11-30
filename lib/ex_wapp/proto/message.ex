# credo:disable-for-this-file
defmodule ExWapp.Proto.Message do
  import Bitwise

  @moduledoc """
  WhatsApp E2E Message protobuf.

  This is a minimal implementation covering the essential message types.
  Based on WAWebProtobufsE2E.Message from whatsmeow.

  ## Field Numbers
  - 1: conversation (string)
  - 6: extendedTextMessage
  - 12: protocolMessage
  """

  defstruct conversation: nil,
            extendedTextMessage: nil,
            protocolMessage: nil,
            __uf__: []

  @spec encode(struct()) :: {:ok, binary()} | {:error, any()}
  def encode(msg) do
    try do
      {:ok, encode!(msg)}
    rescue
      e -> {:error, e}
    end
  end

  @spec encode!(struct()) :: binary()
  def encode!(msg) do
    []
    |> encode_conversation(msg)
    |> encode_extended_text_message(msg)
    |> encode_protocol_message(msg)
    |> IO.iodata_to_binary()
  end

  # Field 1: conversation (string) - tag 0x0a (field 1, wire type 2)
  defp encode_conversation(acc, %{conversation: nil}), do: acc

  defp encode_conversation(acc, %{conversation: value}) when is_binary(value) do
    len = byte_size(value)
    [acc, <<0x0A, len::8>>, value]
  end

  # Field 6: extendedTextMessage - tag 0x32 (field 6, wire type 2)
  defp encode_extended_text_message(acc, %{extendedTextMessage: nil}), do: acc

  defp encode_extended_text_message(acc, %{extendedTextMessage: value}) do
    encoded = ExWapp.Proto.ExtendedTextMessage.encode!(value)
    len = byte_size(encoded)
    [acc, <<0x32>>, encode_varint(len), encoded]
  end

  # Field 12: protocolMessage - tag 0x62 (field 12, wire type 2)
  defp encode_protocol_message(acc, %{protocolMessage: nil}), do: acc

  defp encode_protocol_message(acc, %{protocolMessage: value}) do
    encoded = ExWapp.Proto.ProtocolMessage.encode!(value)
    len = byte_size(encoded)
    [acc, <<0x62>>, encode_varint(len), encoded]
  end

  defp encode_varint(n) when n < 128, do: <<n::8>>

  defp encode_varint(n) do
    <<1::1, n::7, encode_varint(n >>> 7)::binary>>
  end
end

defmodule ExWapp.Proto.ExtendedTextMessage do
  import Bitwise

  @moduledoc """
  Extended text message with rich formatting and context.
  """

  defstruct text: nil,
            contextInfo: nil,
            __uf__: []

  @spec encode!(struct()) :: binary()
  def encode!(msg) do
    []
    |> encode_text(msg)
    |> encode_context_info(msg)
    |> IO.iodata_to_binary()
  end

  # Field 1: text (string)
  defp encode_text(acc, %{text: nil}), do: acc

  defp encode_text(acc, %{text: value}) when is_binary(value) do
    len = byte_size(value)
    [acc, <<0x0A>>, encode_varint(len), value]
  end

  # Field 17: contextInfo
  defp encode_context_info(acc, %{contextInfo: nil}), do: acc

  defp encode_context_info(acc, %{contextInfo: value}) do
    encoded = ExWapp.Proto.ContextInfo.encode!(value)
    len = byte_size(encoded)
    [acc, <<0x8A, 0x01>>, encode_varint(len), encoded]
  end

  defp encode_varint(n) when n < 128, do: <<n::8>>

  defp encode_varint(n) do
    <<1::1, n::7, encode_varint(n >>> 7)::binary>>
  end
end

defmodule ExWapp.Proto.ContextInfo do
  import Bitwise

  @moduledoc """
  Context information for messages (quotes, mentions, etc).
  """

  defstruct stanzaID: nil,
            participant: nil,
            mentionedJID: [],
            isForwarded: nil,
            __uf__: []

  @spec encode!(struct()) :: binary()
  def encode!(msg) do
    []
    |> encode_stanza_id(msg)
    |> encode_participant(msg)
    |> encode_mentioned_jid(msg)
    |> encode_is_forwarded(msg)
    |> IO.iodata_to_binary()
  end

  # Field 1: stanzaID (string)
  defp encode_stanza_id(acc, %{stanzaID: nil}), do: acc

  defp encode_stanza_id(acc, %{stanzaID: value}) when is_binary(value) do
    len = byte_size(value)
    [acc, <<0x0A>>, encode_varint(len), value]
  end

  # Field 2: participant (string)
  defp encode_participant(acc, %{participant: nil}), do: acc

  defp encode_participant(acc, %{participant: value}) when is_binary(value) do
    len = byte_size(value)
    [acc, <<0x12>>, encode_varint(len), value]
  end

  # Field 15: mentionedJID (repeated string)
  defp encode_mentioned_jid(acc, %{mentionedJID: []}), do: acc

  defp encode_mentioned_jid(acc, %{mentionedJID: values}) do
    Enum.reduce(values, acc, fn v, a ->
      len = byte_size(v)
      [a, <<0x7A>>, encode_varint(len), v]
    end)
  end

  # Field 18: isForwarded (bool)
  defp encode_is_forwarded(acc, %{isForwarded: nil}), do: acc
  defp encode_is_forwarded(acc, %{isForwarded: true}), do: [acc, <<0x90, 0x01, 0x01>>]
  defp encode_is_forwarded(acc, %{isForwarded: false}), do: [acc, <<0x90, 0x01, 0x00>>]

  defp encode_varint(n) when n < 128, do: <<n::8>>

  defp encode_varint(n) do
    <<1::1, n::7, encode_varint(n >>> 7)::binary>>
  end
end

defmodule ExWapp.Proto.ProtocolMessage do
  import Bitwise

  @moduledoc """
  Protocol-level messages (receipts, edits, deletes, etc).
  """

  defstruct key: nil,
            type: nil,
            __uf__: []

  @spec encode!(struct()) :: binary()
  def encode!(msg) do
    []
    |> encode_key(msg)
    |> encode_type(msg)
    |> IO.iodata_to_binary()
  end

  # Field 1: key (MessageKey)
  defp encode_key(acc, %{key: nil}), do: acc

  defp encode_key(acc, %{key: value}) do
    encoded = ExWapp.Proto.MessageKey.encode!(value)
    len = byte_size(encoded)
    [acc, <<0x0A>>, encode_varint(len), encoded]
  end

  # Field 2: type (enum)
  defp encode_type(acc, %{type: nil}), do: acc

  defp encode_type(acc, %{type: value}) do
    int_val = type_to_int(value)
    [acc, <<0x10>>, encode_varint(int_val)]
  end

  defp type_to_int(:REVOKE), do: 0
  defp type_to_int(:EPHEMERAL_SETTING), do: 3
  defp type_to_int(:MESSAGE_EDIT), do: 14
  defp type_to_int(_), do: 0

  defp encode_varint(n) when n < 128, do: <<n::8>>

  defp encode_varint(n) do
    <<1::1, n::7, encode_varint(n >>> 7)::binary>>
  end
end

defmodule ExWapp.Proto.MessageKey do
  import Bitwise

  @moduledoc """
  Unique identifier for a message.
  """

  defstruct remoteJID: nil,
            fromMe: nil,
            id: nil,
            participant: nil,
            __uf__: []

  @spec encode!(struct()) :: binary()
  def encode!(msg) do
    []
    |> encode_remote_jid(msg)
    |> encode_from_me(msg)
    |> encode_id(msg)
    |> encode_participant(msg)
    |> IO.iodata_to_binary()
  end

  # Field 1: remoteJID (string)
  defp encode_remote_jid(acc, %{remoteJID: nil}), do: acc

  defp encode_remote_jid(acc, %{remoteJID: value}) when is_binary(value) do
    len = byte_size(value)
    [acc, <<0x0A>>, encode_varint(len), value]
  end

  # Field 2: fromMe (bool)
  defp encode_from_me(acc, %{fromMe: nil}), do: acc
  defp encode_from_me(acc, %{fromMe: true}), do: [acc, <<0x10, 0x01>>]
  defp encode_from_me(acc, %{fromMe: false}), do: [acc, <<0x10, 0x00>>]

  # Field 3: id (string)
  defp encode_id(acc, %{id: nil}), do: acc

  defp encode_id(acc, %{id: value}) when is_binary(value) do
    len = byte_size(value)
    [acc, <<0x1A>>, encode_varint(len), value]
  end

  # Field 4: participant (string)
  defp encode_participant(acc, %{participant: nil}), do: acc

  defp encode_participant(acc, %{participant: value}) when is_binary(value) do
    len = byte_size(value)
    [acc, <<0x22>>, encode_varint(len), value]
  end

  defp encode_varint(n) when n < 128, do: <<n::8>>

  defp encode_varint(n) do
    <<1::1, n::7, encode_varint(n >>> 7)::binary>>
  end
end
