# credo:disable-for-this-file
defmodule ExWapp.Proto.Message do
  import Bitwise

  @moduledoc """
  WhatsApp E2E Message protobuf.

  This is a minimal implementation covering the essential message types.
  Based on WAWebProtobufsE2E.Message from whatsmeow.

  ## Field Numbers
  - 1: conversation (string)
  - 3: imageMessage
  - 6: extendedTextMessage
  - 8: audioMessage
  - 12: protocolMessage
  - 31: deviceSentMessage
  """

  defstruct conversation: nil,
            imageMessage: nil,
            extendedTextMessage: nil,
            audioMessage: nil,
            protocolMessage: nil,
            deviceSentMessage: nil,
            __uf__: []

  @type t :: %__MODULE__{
          conversation: binary() | nil,
          imageMessage: ExWapp.Proto.ImageMessage.t() | nil,
          extendedTextMessage: ExWapp.Proto.ExtendedTextMessage.t() | nil,
          audioMessage: ExWapp.Proto.AudioMessage.t() | nil,
          protocolMessage: ExWapp.Proto.ProtocolMessage.t() | nil,
          deviceSentMessage: ExWapp.Proto.DeviceSentMessage.t() | nil,
          __uf__: list()
        }

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
    |> encode_image_message(msg)
    |> encode_extended_text_message(msg)
    |> encode_audio_message(msg)
    |> encode_protocol_message(msg)
    |> encode_device_sent_message(msg)
    |> IO.iodata_to_binary()
  end

  # Field 1: conversation (string) - tag 0x0a (field 1, wire type 2)
  defp encode_conversation(acc, %{conversation: nil}), do: acc

  defp encode_conversation(acc, %{conversation: value}) when is_binary(value) do
    len = byte_size(value)
    [acc, <<0x0A>>, encode_varint(len), value]
  end

  # Field 3: imageMessage - tag 0x1a (field 3, wire type 2)
  defp encode_image_message(acc, %{imageMessage: nil}), do: acc

  defp encode_image_message(acc, %{imageMessage: value}) do
    encoded = ExWapp.Proto.ImageMessage.encode!(value)
    len = byte_size(encoded)
    [acc, <<0x1A>>, encode_varint(len), encoded]
  end

  # Field 6: extendedTextMessage - tag 0x32 (field 6, wire type 2)
  defp encode_extended_text_message(acc, %{extendedTextMessage: nil}), do: acc

  defp encode_extended_text_message(acc, %{extendedTextMessage: value}) do
    encoded = ExWapp.Proto.ExtendedTextMessage.encode!(value)
    len = byte_size(encoded)
    [acc, <<0x32>>, encode_varint(len), encoded]
  end

  # Field 8: audioMessage - tag 0x42 (field 8, wire type 2)
  defp encode_audio_message(acc, %{audioMessage: nil}), do: acc

  defp encode_audio_message(acc, %{audioMessage: value}) do
    encoded = ExWapp.Proto.AudioMessage.encode!(value)
    len = byte_size(encoded)
    [acc, <<0x42>>, encode_varint(len), encoded]
  end

  # Field 12: protocolMessage - tag 0x62 (field 12, wire type 2)
  defp encode_protocol_message(acc, %{protocolMessage: nil}), do: acc

  defp encode_protocol_message(acc, %{protocolMessage: value}) do
    encoded = ExWapp.Proto.ProtocolMessage.encode!(value)
    len = byte_size(encoded)
    [acc, <<0x62>>, encode_varint(len), encoded]
  end

  # Field 31: deviceSentMessage - tag 0xFA 0x01 (field 31, wire type 2)
  defp encode_device_sent_message(acc, %{deviceSentMessage: nil}), do: acc

  defp encode_device_sent_message(acc, %{deviceSentMessage: value}) do
    encoded = ExWapp.Proto.DeviceSentMessage.encode!(value)
    len = byte_size(encoded)
    [acc, <<0xFA, 0x01>>, encode_varint(len), encoded]
  end

  defp encode_varint(n) when n < 128, do: <<n::8>>

  defp encode_varint(n) do
    <<1::1, n::7, encode_varint(n >>> 7)::binary>>
  end
end

defmodule ExWapp.Proto.ImageMessage do
  import Bitwise

  @moduledoc """
  WhatsApp image message attachment metadata.
  """

  defstruct URL: nil,
            mimetype: nil,
            caption: nil,
            fileSHA256: nil,
            fileLength: nil,
            height: nil,
            width: nil,
            mediaKey: nil,
            fileEncSHA256: nil,
            directPath: nil,
            mediaKeyTimestamp: nil,
            JPEGThumbnail: nil,
            contextInfo: nil,
            __uf__: []

  @type t :: %__MODULE__{
          URL: binary() | nil,
          mimetype: binary() | nil,
          caption: binary() | nil,
          fileSHA256: binary() | nil,
          fileLength: non_neg_integer() | nil,
          height: non_neg_integer() | nil,
          width: non_neg_integer() | nil,
          mediaKey: binary() | nil,
          fileEncSHA256: binary() | nil,
          directPath: binary() | nil,
          mediaKeyTimestamp: integer() | nil,
          JPEGThumbnail: binary() | nil,
          contextInfo: ExWapp.Proto.ContextInfo.t() | nil,
          __uf__: list()
        }

  @spec encode!(struct()) :: binary()
  def encode!(msg) do
    []
    |> encode_string(1, Map.get(msg, :URL))
    |> encode_string(2, msg.mimetype)
    |> encode_string(3, msg.caption)
    |> encode_bytes(4, msg.fileSHA256)
    |> encode_varint_field(5, msg.fileLength)
    |> encode_varint_field(6, msg.height)
    |> encode_varint_field(7, msg.width)
    |> encode_bytes(8, msg.mediaKey)
    |> encode_bytes(9, msg.fileEncSHA256)
    |> encode_string(11, msg.directPath)
    |> encode_varint_field(12, msg.mediaKeyTimestamp)
    |> encode_bytes(16, Map.get(msg, :JPEGThumbnail))
    |> encode_context_info(17, msg.contextInfo)
    |> IO.iodata_to_binary()
  end

  defp encode_context_info(acc, _field, nil), do: acc

  defp encode_context_info(acc, field, value) do
    encoded = ExWapp.Proto.ContextInfo.encode!(value)
    [acc, encode_key(field, 2), encode_varint(byte_size(encoded)), encoded]
  end

  defp encode_string(acc, _field, nil), do: acc
  defp encode_string(acc, field, value) when is_binary(value), do: encode_bytes(acc, field, value)

  defp encode_bytes(acc, _field, nil), do: acc

  defp encode_bytes(acc, field, value) when is_binary(value),
    do: [acc, encode_key(field, 2), encode_varint(byte_size(value)), value]

  defp encode_varint_field(acc, _field, nil), do: acc

  defp encode_varint_field(acc, field, value) when is_integer(value),
    do: [acc, encode_key(field, 0), encode_varint(value)]

  defp encode_key(field, wire_type), do: encode_varint(field <<< 3 ||| wire_type)
  defp encode_varint(n) when n < 128, do: <<n::8>>
  defp encode_varint(n), do: <<1::1, n::7, encode_varint(n >>> 7)::binary>>
end

defmodule ExWapp.Proto.AudioMessage do
  import Bitwise

  @moduledoc """
  WhatsApp audio message attachment metadata.
  """

  defstruct URL: nil,
            mimetype: nil,
            fileSHA256: nil,
            fileLength: nil,
            seconds: nil,
            PTT: nil,
            mediaKey: nil,
            fileEncSHA256: nil,
            directPath: nil,
            mediaKeyTimestamp: nil,
            contextInfo: nil,
            streamingSidecar: nil,
            waveform: nil,
            __uf__: []

  @type t :: %__MODULE__{
          URL: binary() | nil,
          mimetype: binary() | nil,
          fileSHA256: binary() | nil,
          fileLength: non_neg_integer() | nil,
          seconds: non_neg_integer() | nil,
          PTT: boolean() | nil,
          mediaKey: binary() | nil,
          fileEncSHA256: binary() | nil,
          directPath: binary() | nil,
          mediaKeyTimestamp: integer() | nil,
          contextInfo: ExWapp.Proto.ContextInfo.t() | nil,
          streamingSidecar: binary() | nil,
          waveform: binary() | nil,
          __uf__: list()
        }

  @spec encode!(struct()) :: binary()
  def encode!(msg) do
    []
    |> encode_string(1, Map.get(msg, :URL))
    |> encode_string(2, msg.mimetype)
    |> encode_bytes(3, msg.fileSHA256)
    |> encode_varint_field(4, msg.fileLength)
    |> encode_varint_field(5, msg.seconds)
    |> encode_bool(6, Map.get(msg, :PTT))
    |> encode_bytes(7, msg.mediaKey)
    |> encode_bytes(8, msg.fileEncSHA256)
    |> encode_string(9, msg.directPath)
    |> encode_varint_field(10, msg.mediaKeyTimestamp)
    |> encode_context_info(17, msg.contextInfo)
    |> encode_bytes(18, msg.streamingSidecar)
    |> encode_bytes(19, msg.waveform)
    |> IO.iodata_to_binary()
  end

  defp encode_context_info(acc, _field, nil), do: acc

  defp encode_context_info(acc, field, value) do
    encoded = ExWapp.Proto.ContextInfo.encode!(value)
    [acc, encode_key(field, 2), encode_varint(byte_size(encoded)), encoded]
  end

  defp encode_string(acc, _field, nil), do: acc
  defp encode_string(acc, field, value) when is_binary(value), do: encode_bytes(acc, field, value)

  defp encode_bytes(acc, _field, nil), do: acc

  defp encode_bytes(acc, field, value) when is_binary(value),
    do: [acc, encode_key(field, 2), encode_varint(byte_size(value)), value]

  defp encode_varint_field(acc, _field, nil), do: acc

  defp encode_varint_field(acc, field, value) when is_integer(value),
    do: [acc, encode_key(field, 0), encode_varint(value)]

  defp encode_bool(acc, _field, nil), do: acc

  defp encode_bool(acc, field, value) when is_boolean(value),
    do: [acc, encode_key(field, 0), if(value, do: <<1>>, else: <<0>>)]

  defp encode_key(field, wire_type), do: encode_varint(field <<< 3 ||| wire_type)
  defp encode_varint(n) when n < 128, do: <<n::8>>
  defp encode_varint(n), do: <<1::1, n::7, encode_varint(n >>> 7)::binary>>
end

defmodule ExWapp.Proto.ExtendedTextMessage do
  import Bitwise

  @moduledoc """
  Extended text message with rich formatting and context.
  """

  defstruct text: nil,
            contextInfo: nil,
            __uf__: []

  @type t :: %__MODULE__{
          text: binary() | nil,
          contextInfo: ExWapp.Proto.ContextInfo.t() | nil,
          __uf__: list()
        }

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

  @type t :: %__MODULE__{
          stanzaID: binary() | nil,
          participant: binary() | nil,
          mentionedJID: [binary()],
          isForwarded: boolean() | nil,
          __uf__: list()
        }

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

defmodule ExWapp.Proto.DeviceSentMessage do
  import Bitwise

  @moduledoc """
  Wrapper used when fanning out direct messages to the sender's other devices.
  """

  defstruct destinationJid: nil,
            message: nil,
            phash: nil,
            __uf__: []

  @type t :: %__MODULE__{
          destinationJid: binary() | nil,
          message: ExWapp.Proto.Message.t() | nil,
          phash: binary() | nil,
          __uf__: list()
        }

  @spec encode!(struct()) :: binary()
  def encode!(msg) do
    []
    |> encode_destination_jid(msg)
    |> encode_message(msg)
    |> encode_phash(msg)
    |> IO.iodata_to_binary()
  end

  # Field 1: destinationJid (string)
  defp encode_destination_jid(acc, %{destinationJid: nil}), do: acc

  defp encode_destination_jid(acc, %{destinationJid: value}) when is_binary(value) do
    len = byte_size(value)
    [acc, <<0x0A>>, encode_varint(len), value]
  end

  # Field 2: message (Message)
  defp encode_message(acc, %{message: nil}), do: acc

  defp encode_message(acc, %{message: value}) do
    encoded = ExWapp.Proto.Message.encode!(value)
    len = byte_size(encoded)
    [acc, <<0x12>>, encode_varint(len), encoded]
  end

  # Field 3: phash (string)
  defp encode_phash(acc, %{phash: nil}), do: acc

  defp encode_phash(acc, %{phash: value}) when is_binary(value) do
    len = byte_size(value)
    [acc, <<0x1A>>, encode_varint(len), value]
  end

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
            peerDataOperationRequestMessage: nil,
            __uf__: []

  @type t :: %__MODULE__{
          key: ExWapp.Proto.MessageKey.t() | nil,
          type: atom() | nil,
          peerDataOperationRequestMessage: ExWapp.Proto.PeerDataOperationRequestMessage.t() | nil,
          __uf__: list()
        }

  @spec encode!(struct()) :: binary()
  def encode!(msg) do
    []
    |> encode_key(msg)
    |> encode_type(msg)
    |> encode_peer_data_operation_request_message(msg)
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
  defp type_to_int(:PEER_DATA_OPERATION_REQUEST_MESSAGE), do: 16
  defp type_to_int(_), do: 0

  # Field 16: peerDataOperationRequestMessage
  defp encode_peer_data_operation_request_message(
         acc,
         %{peerDataOperationRequestMessage: nil}
       ),
       do: acc

  defp encode_peer_data_operation_request_message(
         acc,
         %{peerDataOperationRequestMessage: value}
       ) do
    encoded = ExWapp.Proto.PeerDataOperationRequestMessage.encode!(value)
    len = byte_size(encoded)
    [acc, <<0x82, 0x01>>, encode_varint(len), encoded]
  end

  defp encode_varint(n) when n < 128, do: <<n::8>>

  defp encode_varint(n) do
    <<1::1, n::7, encode_varint(n >>> 7)::binary>>
  end
end

defmodule ExWapp.Proto.PeerDataOperationRequestMessage do
  import Bitwise

  @moduledoc """
  Peer-data operation request message.

  This currently covers the placeholder-message resend request used to ask the
  primary device for a copy of an undecryptable placeholder/ciphertext message.
  """

  defstruct peerDataOperationRequestType: nil,
            placeholderMessageResendRequest: [],
            __uf__: []

  @type t :: %__MODULE__{
          peerDataOperationRequestType: atom() | nil,
          placeholderMessageResendRequest: [ExWapp.Proto.PlaceholderMessageResendRequest.t()],
          __uf__: list()
        }

  @spec encode!(struct()) :: binary()
  def encode!(msg) do
    []
    |> encode_peer_data_operation_request_type(msg)
    |> encode_placeholder_message_resend_request(msg)
    |> IO.iodata_to_binary()
  end

  # Field 1: peerDataOperationRequestType
  defp encode_peer_data_operation_request_type(acc, %{peerDataOperationRequestType: nil}),
    do: acc

  defp encode_peer_data_operation_request_type(acc, %{peerDataOperationRequestType: value}) do
    [acc, <<0x08>>, encode_varint(peer_data_operation_request_type_to_int(value))]
  end

  # Field 5: repeated placeholderMessageResendRequest
  defp encode_placeholder_message_resend_request(acc, %{placeholderMessageResendRequest: values})
       when is_list(values) do
    Enum.reduce(values, acc, fn value, encoded_acc ->
      encoded = ExWapp.Proto.PlaceholderMessageResendRequest.encode!(value)
      len = byte_size(encoded)
      [encoded_acc, <<0x2A>>, encode_varint(len), encoded]
    end)
  end

  defp encode_placeholder_message_resend_request(acc, _), do: acc

  defp peer_data_operation_request_type_to_int(:PLACEHOLDER_MESSAGE_RESEND), do: 4
  defp peer_data_operation_request_type_to_int(_), do: 0

  defp encode_varint(n) when n < 128, do: <<n::8>>

  defp encode_varint(n) do
    <<1::1, n::7, encode_varint(n >>> 7)::binary>>
  end
end

defmodule ExWapp.Proto.PlaceholderMessageResendRequest do
  import Bitwise

  @moduledoc """
  Placeholder-message resend request wrapper.
  """

  defstruct messageKey: nil,
            __uf__: []

  @type t :: %__MODULE__{
          messageKey: ExWapp.Proto.MessageKey.t() | nil,
          __uf__: list()
        }

  @spec encode!(struct()) :: binary()
  def encode!(msg) do
    []
    |> encode_message_key(msg)
    |> IO.iodata_to_binary()
  end

  # Field 1: messageKey
  defp encode_message_key(acc, %{messageKey: nil}), do: acc

  defp encode_message_key(acc, %{messageKey: value}) do
    encoded = ExWapp.Proto.MessageKey.encode!(value)
    len = byte_size(encoded)
    [acc, <<0x0A>>, encode_varint(len), encoded]
  end

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

  @type t :: %__MODULE__{
          remoteJID: binary() | nil,
          fromMe: boolean() | nil,
          id: binary() | nil,
          participant: binary() | nil,
          __uf__: list()
        }

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
