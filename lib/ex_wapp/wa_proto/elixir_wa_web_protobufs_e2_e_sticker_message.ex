# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.StickerMessage do
  @moduledoc false
  defstruct URL: nil,
            fileSHA256: nil,
            fileEncSHA256: nil,
            mediaKey: nil,
            mimetype: nil,
            height: nil,
            width: nil,
            directPath: nil,
            fileLength: nil,
            mediaKeyTimestamp: nil,
            firstFrameLength: nil,
            firstFrameSidecar: nil,
            isAnimated: nil,
            pngThumbnail: nil,
            contextInfo: nil,
            stickerSentTS: nil,
            isAvatar: nil,
            isAiSticker: nil,
            isLottie: nil,
            accessibilityLabel: nil,
            premium: nil,
            emojis: nil,
            audio: nil,
            __uf__: []

  (
    (
      @spec encode(struct) :: {:ok, iodata} | {:error, any}
      def encode(msg) do
        try do
          {:ok, encode!(msg)}
        rescue
          e in [Protox.EncodingError, Protox.RequiredFieldsError] -> {:error, e}
        end
      end

      @spec encode!(struct) :: iodata | no_return
      def encode!(msg) do
        []
        |> encode_audio(msg)
        |> encode_URL(msg)
        |> encode_fileSHA256(msg)
        |> encode_fileEncSHA256(msg)
        |> encode_mediaKey(msg)
        |> encode_mimetype(msg)
        |> encode_height(msg)
        |> encode_width(msg)
        |> encode_directPath(msg)
        |> encode_fileLength(msg)
        |> encode_mediaKeyTimestamp(msg)
        |> encode_firstFrameLength(msg)
        |> encode_firstFrameSidecar(msg)
        |> encode_isAnimated(msg)
        |> encode_pngThumbnail(msg)
        |> encode_contextInfo(msg)
        |> encode_stickerSentTS(msg)
        |> encode_isAvatar(msg)
        |> encode_isAiSticker(msg)
        |> encode_isLottie(msg)
        |> encode_accessibilityLabel(msg)
        |> encode_premium(msg)
        |> encode_emojis(msg)
        |> encode_unknown_fields(msg)
      end
    )

    [
      defp encode_audio(acc, msg) do
        case msg.audio do
          nil -> acc
          {:audioMessage, _field_value} -> encode_audioMessage(acc, msg)
        end
      end
    ]

    [
      defp encode_URL(acc, msg) do
        try do
          case msg."URL" do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg."URL")]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:URL, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileSHA256(acc, msg) do
        try do
          case msg.fileSHA256 do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_bytes(msg.fileSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileSHA256, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileEncSHA256(acc, msg) do
        try do
          case msg.fileEncSHA256 do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_bytes(msg.fileEncSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileEncSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_mediaKey(acc, msg) do
        try do
          case msg.mediaKey do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_bytes(msg.mediaKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaKey, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mimetype(acc, msg) do
        try do
          case msg.mimetype do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.mimetype)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mimetype, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_height(acc, msg) do
        try do
          case msg.height do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_uint32(msg.height)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:height, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_width(acc, msg) do
        try do
          case msg.width do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_uint32(msg.width)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:width, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_directPath(acc, msg) do
        try do
          case msg.directPath do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg.directPath)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:directPath, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileLength(acc, msg) do
        try do
          case msg.fileLength do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_uint64(msg.fileLength)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileLength, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaKeyTimestamp(acc, msg) do
        try do
          case msg.mediaKeyTimestamp do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_int64(msg.mediaKeyTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaKeyTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_firstFrameLength(acc, msg) do
        try do
          case msg.firstFrameLength do
            nil -> acc
            _ -> [acc, "X", Protox.Encode.encode_uint32(msg.firstFrameLength)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:firstFrameLength, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_firstFrameSidecar(acc, msg) do
        try do
          case msg.firstFrameSidecar do
            nil -> acc
            _ -> [acc, "b", Protox.Encode.encode_bytes(msg.firstFrameSidecar)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:firstFrameSidecar, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isAnimated(acc, msg) do
        try do
          case msg.isAnimated do
            nil -> acc
            _ -> [acc, "h", Protox.Encode.encode_bool(msg.isAnimated)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isAnimated, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pngThumbnail(acc, msg) do
        try do
          case msg.pngThumbnail do
            nil -> acc
            _ -> [acc, "\x82\x01", Protox.Encode.encode_bytes(msg.pngThumbnail)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pngThumbnail, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_contextInfo(acc, msg) do
        try do
          case msg.contextInfo do
            nil -> acc
            _ -> [acc, "\x8A\x01", Protox.Encode.encode_message(msg.contextInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contextInfo, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_stickerSentTS(acc, msg) do
        try do
          case msg.stickerSentTS do
            nil -> acc
            _ -> [acc, "\x90\x01", Protox.Encode.encode_int64(msg.stickerSentTS)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:stickerSentTS, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isAvatar(acc, msg) do
        try do
          case msg.isAvatar do
            nil -> acc
            _ -> [acc, "\x98\x01", Protox.Encode.encode_bool(msg.isAvatar)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isAvatar, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isAiSticker(acc, msg) do
        try do
          case msg.isAiSticker do
            nil -> acc
            _ -> [acc, "\xA0\x01", Protox.Encode.encode_bool(msg.isAiSticker)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isAiSticker, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isLottie(acc, msg) do
        try do
          case msg.isLottie do
            nil -> acc
            _ -> [acc, "\xA8\x01", Protox.Encode.encode_bool(msg.isLottie)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isLottie, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_accessibilityLabel(acc, msg) do
        try do
          case msg.accessibilityLabel do
            nil -> acc
            _ -> [acc, "\xB2\x01", Protox.Encode.encode_string(msg.accessibilityLabel)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:accessibilityLabel, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_premium(acc, msg) do
        try do
          case msg.premium do
            nil -> acc
            _ -> [acc, "\xC0\x01", Protox.Encode.encode_int32(msg.premium)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:premium, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_emojis(acc, msg) do
        try do
          case msg.emojis do
            nil -> acc
            _ -> [acc, "\xCA\x01", Protox.Encode.encode_string(msg.emojis)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:emojis, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_audioMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.audio
          [acc, "\xD2\x01", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:audioMessage, "invalid field value"), __STACKTRACE__
        end
      end
    ]

    defp encode_unknown_fields(acc, msg) do
      Enum.reduce(msg.__struct__.unknown_fields(msg), acc, fn {tag, wire_type, bytes}, acc ->
        case wire_type do
          0 ->
            [acc, Protox.Encode.make_key_bytes(tag, :int32), bytes]

          1 ->
            [acc, Protox.Encode.make_key_bytes(tag, :double), bytes]

          2 ->
            len_bytes = bytes |> byte_size() |> Protox.Varint.encode()
            [acc, Protox.Encode.make_key_bytes(tag, :packed), len_bytes, bytes]

          5 ->
            [acc, Protox.Encode.make_key_bytes(tag, :float), bytes]
        end
      end)
    end
  )

  (
    (
      @spec decode(binary) :: {:ok, struct} | {:error, any}
      def decode(bytes) do
        try do
          {:ok, decode!(bytes)}
        rescue
          e in [Protox.DecodingError, Protox.IllegalTagError, Protox.RequiredFieldsError] ->
            {:error, e}
        end
      end

      (
        @spec decode!(binary) :: struct | no_return
        def decode!(bytes) do
          parse_key_value(bytes, struct(WAWebProtobufsE2E.StickerMessage))
        end
      )
    )

    (
      @spec parse_key_value(binary, struct) :: struct
      defp parse_key_value(<<>>, msg) do
        msg
      end

      defp parse_key_value(bytes, msg) do
        {field, rest} =
          case Protox.Decode.parse_key(bytes) do
            {0, _, _} ->
              raise %Protox.IllegalTagError{}

            {1, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[URL: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fileSHA256: delimited], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fileEncSHA256: delimited], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mediaKey: delimited], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mimetype: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[height: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[width: value], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[directPath: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[fileLength: value], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[mediaKeyTimestamp: value], rest}

            {11, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[firstFrameLength: value], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[firstFrameSidecar: delimited], rest}

            {13, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isAnimated: value], rest}

            {16, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[pngThumbnail: delimited], rest}

            {17, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contextInfo:
                   Protox.MergeMessage.merge(
                     msg.contextInfo,
                     WAWebProtobufsE2E.ContextInfo.decode!(delimited)
                   )
               ], rest}

            {18, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[stickerSentTS: value], rest}

            {19, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isAvatar: value], rest}

            {20, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isAiSticker: value], rest}

            {21, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isLottie: value], rest}

            {22, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[accessibilityLabel: Protox.Decode.validate_string!(delimited)], rest}

            {24, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[premium: value], rest}

            {25, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[emojis: Protox.Decode.validate_string!(delimited)], rest}

            {26, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.audio do
                   {:audioMessage, previous_value} ->
                     {:audio,
                      {:audioMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.AudioMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:audio, {:audioMessage, WAWebProtobufsE2E.AudioMessage.decode!(delimited)}}
                 end
               ], rest}

            {tag, wire_type, rest} ->
              {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

              {[
                 {msg.__struct__.unknown_fields_name(),
                  [value | msg.__struct__.unknown_fields(msg)]}
               ], rest}
          end

        msg_updated = struct(msg, field)
        parse_key_value(rest, msg_updated)
      end
    )

    []
  )

  (
    @spec json_decode(iodata(), keyword()) :: {:ok, struct()} | {:error, any()}
    def json_decode(input, opts \\ []) do
      try do
        {:ok, json_decode!(input, opts)}
      rescue
        e in Protox.JsonDecodingError -> {:error, e}
      end
    end

    @spec json_decode!(iodata(), keyword()) :: struct() | no_return()
    def json_decode!(input, opts \\ []) do
      {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :decode)

      Protox.JsonDecode.decode!(
        input,
        WAWebProtobufsE2E.StickerMessage,
        &json_library_wrapper.decode!(json_library, &1)
      )
    end

    @spec json_encode(struct(), keyword()) :: {:ok, iodata()} | {:error, any()}
    def json_encode(msg, opts \\ []) do
      try do
        {:ok, json_encode!(msg, opts)}
      rescue
        e in Protox.JsonEncodingError -> {:error, e}
      end
    end

    @spec json_encode!(struct(), keyword()) :: iodata() | no_return()
    def json_encode!(msg, opts \\ []) do
      {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :encode)
      Protox.JsonEncode.encode!(msg, &json_library_wrapper.encode!(json_library, &1))
    end
  )

  (
    @deprecated "Use fields_defs()/0 instead"
    @spec defs() :: %{
            required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs() do
      %{
        1 => {:URL, {:scalar, ""}, :string},
        2 => {:fileSHA256, {:scalar, ""}, :bytes},
        3 => {:fileEncSHA256, {:scalar, ""}, :bytes},
        4 => {:mediaKey, {:scalar, ""}, :bytes},
        5 => {:mimetype, {:scalar, ""}, :string},
        6 => {:height, {:scalar, 0}, :uint32},
        7 => {:width, {:scalar, 0}, :uint32},
        8 => {:directPath, {:scalar, ""}, :string},
        9 => {:fileLength, {:scalar, 0}, :uint64},
        10 => {:mediaKeyTimestamp, {:scalar, 0}, :int64},
        11 => {:firstFrameLength, {:scalar, 0}, :uint32},
        12 => {:firstFrameSidecar, {:scalar, ""}, :bytes},
        13 => {:isAnimated, {:scalar, false}, :bool},
        16 => {:pngThumbnail, {:scalar, ""}, :bytes},
        17 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        18 => {:stickerSentTS, {:scalar, 0}, :int64},
        19 => {:isAvatar, {:scalar, false}, :bool},
        20 => {:isAiSticker, {:scalar, false}, :bool},
        21 => {:isLottie, {:scalar, false}, :bool},
        22 => {:accessibilityLabel, {:scalar, ""}, :string},
        24 => {:premium, {:scalar, 0}, :int32},
        25 => {:emojis, {:scalar, ""}, :string},
        26 => {:audioMessage, {:oneof, :audio}, {:message, WAWebProtobufsE2E.AudioMessage}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        URL: {1, {:scalar, ""}, :string},
        accessibilityLabel: {22, {:scalar, ""}, :string},
        audioMessage: {26, {:oneof, :audio}, {:message, WAWebProtobufsE2E.AudioMessage}},
        contextInfo: {17, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        directPath: {8, {:scalar, ""}, :string},
        emojis: {25, {:scalar, ""}, :string},
        fileEncSHA256: {3, {:scalar, ""}, :bytes},
        fileLength: {9, {:scalar, 0}, :uint64},
        fileSHA256: {2, {:scalar, ""}, :bytes},
        firstFrameLength: {11, {:scalar, 0}, :uint32},
        firstFrameSidecar: {12, {:scalar, ""}, :bytes},
        height: {6, {:scalar, 0}, :uint32},
        isAiSticker: {20, {:scalar, false}, :bool},
        isAnimated: {13, {:scalar, false}, :bool},
        isAvatar: {19, {:scalar, false}, :bool},
        isLottie: {21, {:scalar, false}, :bool},
        mediaKey: {4, {:scalar, ""}, :bytes},
        mediaKeyTimestamp: {10, {:scalar, 0}, :int64},
        mimetype: {5, {:scalar, ""}, :string},
        pngThumbnail: {16, {:scalar, ""}, :bytes},
        premium: {24, {:scalar, 0}, :int32},
        stickerSentTS: {18, {:scalar, 0}, :int64},
        width: {7, {:scalar, 0}, :uint32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "URL",
          kind: {:scalar, ""},
          label: :optional,
          name: :URL,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileSHA256,
          tag: 2,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileEncSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileEncSHA256,
          tag: 3,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :mediaKey,
          tag: 4,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "mimetype",
          kind: {:scalar, ""},
          label: :optional,
          name: :mimetype,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "height",
          kind: {:scalar, 0},
          label: :optional,
          name: :height,
          tag: 6,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "width",
          kind: {:scalar, 0},
          label: :optional,
          name: :width,
          tag: 7,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "directPath",
          kind: {:scalar, ""},
          label: :optional,
          name: :directPath,
          tag: 8,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileLength",
          kind: {:scalar, 0},
          label: :optional,
          name: :fileLength,
          tag: 9,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKeyTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :mediaKeyTimestamp,
          tag: 10,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "firstFrameLength",
          kind: {:scalar, 0},
          label: :optional,
          name: :firstFrameLength,
          tag: 11,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "firstFrameSidecar",
          kind: {:scalar, ""},
          label: :optional,
          name: :firstFrameSidecar,
          tag: 12,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "isAnimated",
          kind: {:scalar, false},
          label: :optional,
          name: :isAnimated,
          tag: 13,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "pngThumbnail",
          kind: {:scalar, ""},
          label: :optional,
          name: :pngThumbnail,
          tag: 16,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "contextInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :contextInfo,
          tag: 17,
          type: {:message, WAWebProtobufsE2E.ContextInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "stickerSentTS",
          kind: {:scalar, 0},
          label: :optional,
          name: :stickerSentTS,
          tag: 18,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "isAvatar",
          kind: {:scalar, false},
          label: :optional,
          name: :isAvatar,
          tag: 19,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isAiSticker",
          kind: {:scalar, false},
          label: :optional,
          name: :isAiSticker,
          tag: 20,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isLottie",
          kind: {:scalar, false},
          label: :optional,
          name: :isLottie,
          tag: 21,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "accessibilityLabel",
          kind: {:scalar, ""},
          label: :optional,
          name: :accessibilityLabel,
          tag: 22,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "premium",
          kind: {:scalar, 0},
          label: :optional,
          name: :premium,
          tag: 24,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "emojis",
          kind: {:scalar, ""},
          label: :optional,
          name: :emojis,
          tag: 25,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "audioMessage",
          kind: {:oneof, :audio},
          label: :optional,
          name: :audioMessage,
          tag: 26,
          type: {:message, WAWebProtobufsE2E.AudioMessage}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:URL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "URL",
             kind: {:scalar, ""},
             label: :optional,
             name: :URL,
             tag: 1,
             type: :string
           }}
        end

        def field_def("URL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "URL",
             kind: {:scalar, ""},
             label: :optional,
             name: :URL,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:fileSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileSHA256,
             tag: 2,
             type: :bytes
           }}
        end

        def field_def("fileSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileSHA256,
             tag: 2,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:fileEncSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileEncSHA256,
             tag: 3,
             type: :bytes
           }}
        end

        def field_def("fileEncSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileEncSHA256,
             tag: 3,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:mediaKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :mediaKey,
             tag: 4,
             type: :bytes
           }}
        end

        def field_def("mediaKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :mediaKey,
             tag: 4,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:mimetype) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mimetype",
             kind: {:scalar, ""},
             label: :optional,
             name: :mimetype,
             tag: 5,
             type: :string
           }}
        end

        def field_def("mimetype") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mimetype",
             kind: {:scalar, ""},
             label: :optional,
             name: :mimetype,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:height) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "height",
             kind: {:scalar, 0},
             label: :optional,
             name: :height,
             tag: 6,
             type: :uint32
           }}
        end

        def field_def("height") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "height",
             kind: {:scalar, 0},
             label: :optional,
             name: :height,
             tag: 6,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:width) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "width",
             kind: {:scalar, 0},
             label: :optional,
             name: :width,
             tag: 7,
             type: :uint32
           }}
        end

        def field_def("width") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "width",
             kind: {:scalar, 0},
             label: :optional,
             name: :width,
             tag: 7,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:directPath) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "directPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :directPath,
             tag: 8,
             type: :string
           }}
        end

        def field_def("directPath") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "directPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :directPath,
             tag: 8,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:fileLength) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileLength",
             kind: {:scalar, 0},
             label: :optional,
             name: :fileLength,
             tag: 9,
             type: :uint64
           }}
        end

        def field_def("fileLength") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileLength",
             kind: {:scalar, 0},
             label: :optional,
             name: :fileLength,
             tag: 9,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:mediaKeyTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaKeyTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :mediaKeyTimestamp,
             tag: 10,
             type: :int64
           }}
        end

        def field_def("mediaKeyTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaKeyTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :mediaKeyTimestamp,
             tag: 10,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:firstFrameLength) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "firstFrameLength",
             kind: {:scalar, 0},
             label: :optional,
             name: :firstFrameLength,
             tag: 11,
             type: :uint32
           }}
        end

        def field_def("firstFrameLength") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "firstFrameLength",
             kind: {:scalar, 0},
             label: :optional,
             name: :firstFrameLength,
             tag: 11,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:firstFrameSidecar) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "firstFrameSidecar",
             kind: {:scalar, ""},
             label: :optional,
             name: :firstFrameSidecar,
             tag: 12,
             type: :bytes
           }}
        end

        def field_def("firstFrameSidecar") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "firstFrameSidecar",
             kind: {:scalar, ""},
             label: :optional,
             name: :firstFrameSidecar,
             tag: 12,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:isAnimated) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isAnimated",
             kind: {:scalar, false},
             label: :optional,
             name: :isAnimated,
             tag: 13,
             type: :bool
           }}
        end

        def field_def("isAnimated") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isAnimated",
             kind: {:scalar, false},
             label: :optional,
             name: :isAnimated,
             tag: 13,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:pngThumbnail) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pngThumbnail",
             kind: {:scalar, ""},
             label: :optional,
             name: :pngThumbnail,
             tag: 16,
             type: :bytes
           }}
        end

        def field_def("pngThumbnail") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pngThumbnail",
             kind: {:scalar, ""},
             label: :optional,
             name: :pngThumbnail,
             tag: 16,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:contextInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contextInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :contextInfo,
             tag: 17,
             type: {:message, WAWebProtobufsE2E.ContextInfo}
           }}
        end

        def field_def("contextInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contextInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :contextInfo,
             tag: 17,
             type: {:message, WAWebProtobufsE2E.ContextInfo}
           }}
        end

        []
      ),
      (
        def field_def(:stickerSentTS) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerSentTS",
             kind: {:scalar, 0},
             label: :optional,
             name: :stickerSentTS,
             tag: 18,
             type: :int64
           }}
        end

        def field_def("stickerSentTS") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerSentTS",
             kind: {:scalar, 0},
             label: :optional,
             name: :stickerSentTS,
             tag: 18,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:isAvatar) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isAvatar",
             kind: {:scalar, false},
             label: :optional,
             name: :isAvatar,
             tag: 19,
             type: :bool
           }}
        end

        def field_def("isAvatar") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isAvatar",
             kind: {:scalar, false},
             label: :optional,
             name: :isAvatar,
             tag: 19,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isAiSticker) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isAiSticker",
             kind: {:scalar, false},
             label: :optional,
             name: :isAiSticker,
             tag: 20,
             type: :bool
           }}
        end

        def field_def("isAiSticker") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isAiSticker",
             kind: {:scalar, false},
             label: :optional,
             name: :isAiSticker,
             tag: 20,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isLottie) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isLottie",
             kind: {:scalar, false},
             label: :optional,
             name: :isLottie,
             tag: 21,
             type: :bool
           }}
        end

        def field_def("isLottie") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isLottie",
             kind: {:scalar, false},
             label: :optional,
             name: :isLottie,
             tag: 21,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:accessibilityLabel) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accessibilityLabel",
             kind: {:scalar, ""},
             label: :optional,
             name: :accessibilityLabel,
             tag: 22,
             type: :string
           }}
        end

        def field_def("accessibilityLabel") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accessibilityLabel",
             kind: {:scalar, ""},
             label: :optional,
             name: :accessibilityLabel,
             tag: 22,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:premium) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "premium",
             kind: {:scalar, 0},
             label: :optional,
             name: :premium,
             tag: 24,
             type: :int32
           }}
        end

        def field_def("premium") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "premium",
             kind: {:scalar, 0},
             label: :optional,
             name: :premium,
             tag: 24,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:emojis) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "emojis",
             kind: {:scalar, ""},
             label: :optional,
             name: :emojis,
             tag: 25,
             type: :string
           }}
        end

        def field_def("emojis") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "emojis",
             kind: {:scalar, ""},
             label: :optional,
             name: :emojis,
             tag: 25,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:audioMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "audioMessage",
             kind: {:oneof, :audio},
             label: :optional,
             name: :audioMessage,
             tag: 26,
             type: {:message, WAWebProtobufsE2E.AudioMessage}
           }}
        end

        def field_def("audioMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "audioMessage",
             kind: {:oneof, :audio},
             label: :optional,
             name: :audioMessage,
             tag: 26,
             type: {:message, WAWebProtobufsE2E.AudioMessage}
           }}
        end

        []
      ),
      def field_def(_) do
        {:error, :no_such_field}
      end
    ]
  )

  (
    @spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
    def unknown_fields(msg) do
      msg.__uf__
    end

    @spec unknown_fields_name() :: :__uf__
    def unknown_fields_name() do
      :__uf__
    end

    @spec clear_unknown_fields(struct) :: struct
    def clear_unknown_fields(msg) do
      struct!(msg, [{unknown_fields_name(), []}])
    end
  )

  (
    @spec required_fields() :: []
    def required_fields() do
      []
    end
  )

  (
    @spec syntax() :: atom()
    def syntax() do
      :proto2
    end
  )

  [
    @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
    def default(:URL) do
      {:ok, ""}
    end,
    def default(:fileSHA256) do
      {:ok, ""}
    end,
    def default(:fileEncSHA256) do
      {:ok, ""}
    end,
    def default(:mediaKey) do
      {:ok, ""}
    end,
    def default(:mimetype) do
      {:ok, ""}
    end,
    def default(:height) do
      {:ok, 0}
    end,
    def default(:width) do
      {:ok, 0}
    end,
    def default(:directPath) do
      {:ok, ""}
    end,
    def default(:fileLength) do
      {:ok, 0}
    end,
    def default(:mediaKeyTimestamp) do
      {:ok, 0}
    end,
    def default(:firstFrameLength) do
      {:ok, 0}
    end,
    def default(:firstFrameSidecar) do
      {:ok, ""}
    end,
    def default(:isAnimated) do
      {:ok, false}
    end,
    def default(:pngThumbnail) do
      {:ok, ""}
    end,
    def default(:contextInfo) do
      {:ok, nil}
    end,
    def default(:stickerSentTS) do
      {:ok, 0}
    end,
    def default(:isAvatar) do
      {:ok, false}
    end,
    def default(:isAiSticker) do
      {:ok, false}
    end,
    def default(:isLottie) do
      {:ok, false}
    end,
    def default(:accessibilityLabel) do
      {:ok, ""}
    end,
    def default(:premium) do
      {:ok, 0}
    end,
    def default(:emojis) do
      {:ok, ""}
    end,
    def default(:audioMessage) do
      {:error, :no_default_value}
    end,
    def default(_) do
      {:error, :no_such_field}
    end
  ]

  (
    @spec file_options() :: struct()
    def file_options() do
      file_options = %{
        __struct__: Protox.Google.Protobuf.FileOptions,
        __uf__: [],
        cc_enable_arenas: nil,
        cc_generic_services: nil,
        csharp_namespace: nil,
        deprecated: nil,
        go_package: "go.mau.fi/whatsmeow/proto/waE2E",
        java_generate_equals_and_hash: nil,
        java_generic_services: nil,
        java_multiple_files: nil,
        java_outer_classname: nil,
        java_package: nil,
        java_string_check_utf8: nil,
        objc_class_prefix: nil,
        optimize_for: nil,
        php_class_prefix: nil,
        php_generic_services: nil,
        php_metadata_namespace: nil,
        php_namespace: nil,
        py_generic_services: nil,
        ruby_package: nil,
        swift_prefix: nil,
        uninterpreted_option: []
      }

      case function_exported?(Google.Protobuf.FileOptions, :decode!, 1) do
        true ->
          bytes =
            file_options |> Protox.Google.Protobuf.FileOptions.encode!() |> :binary.list_to_bin()

          apply(Google.Protobuf.FileOptions, :decode!, [bytes])

        false ->
          file_options
      end
    end
  )

  @type t :: %__MODULE__{}
end
