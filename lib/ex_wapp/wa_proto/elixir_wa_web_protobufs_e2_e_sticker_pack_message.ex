# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.StickerPackMessage do
  @moduledoc false
  defstruct stickerPackID: nil,
            name: nil,
            publisher: nil,
            stickers: [],
            fileLength: nil,
            fileSHA256: nil,
            fileEncSHA256: nil,
            mediaKey: nil,
            directPath: nil,
            caption: nil,
            contextInfo: nil,
            packDescription: nil,
            mediaKeyTimestamp: nil,
            trayIconFileName: nil,
            thumbnailDirectPath: nil,
            thumbnailSHA256: nil,
            thumbnailEncSHA256: nil,
            thumbnailHeight: nil,
            thumbnailWidth: nil,
            imageDataHash: nil,
            stickerPackSize: nil,
            stickerPackOrigin: nil,
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
        |> encode_stickerPackID(msg)
        |> encode_name(msg)
        |> encode_publisher(msg)
        |> encode_stickers(msg)
        |> encode_fileLength(msg)
        |> encode_fileSHA256(msg)
        |> encode_fileEncSHA256(msg)
        |> encode_mediaKey(msg)
        |> encode_directPath(msg)
        |> encode_caption(msg)
        |> encode_contextInfo(msg)
        |> encode_packDescription(msg)
        |> encode_mediaKeyTimestamp(msg)
        |> encode_trayIconFileName(msg)
        |> encode_thumbnailDirectPath(msg)
        |> encode_thumbnailSHA256(msg)
        |> encode_thumbnailEncSHA256(msg)
        |> encode_thumbnailHeight(msg)
        |> encode_thumbnailWidth(msg)
        |> encode_imageDataHash(msg)
        |> encode_stickerPackSize(msg)
        |> encode_stickerPackOrigin(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_stickerPackID(acc, msg) do
        try do
          case msg.stickerPackID do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.stickerPackID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:stickerPackID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_name(acc, msg) do
        try do
          case msg.name do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.name)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:name, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_publisher(acc, msg) do
        try do
          case msg.publisher do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.publisher)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:publisher, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_stickers(acc, msg) do
        try do
          case msg.stickers do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\"", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:stickers, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileLength(acc, msg) do
        try do
          case msg.fileLength do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_uint64(msg.fileLength)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileLength, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileSHA256(acc, msg) do
        try do
          case msg.fileSHA256 do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_bytes(msg.fileSHA256)]
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
            _ -> [acc, ":", Protox.Encode.encode_bytes(msg.fileEncSHA256)]
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
            _ -> [acc, "B", Protox.Encode.encode_bytes(msg.mediaKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaKey, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_directPath(acc, msg) do
        try do
          case msg.directPath do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_string(msg.directPath)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:directPath, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_caption(acc, msg) do
        try do
          case msg.caption do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_string(msg.caption)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:caption, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_contextInfo(acc, msg) do
        try do
          case msg.contextInfo do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_message(msg.contextInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contextInfo, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_packDescription(acc, msg) do
        try do
          case msg.packDescription do
            nil -> acc
            _ -> [acc, "b", Protox.Encode.encode_string(msg.packDescription)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:packDescription, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_mediaKeyTimestamp(acc, msg) do
        try do
          case msg.mediaKeyTimestamp do
            nil -> acc
            _ -> [acc, "h", Protox.Encode.encode_int64(msg.mediaKeyTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaKeyTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_trayIconFileName(acc, msg) do
        try do
          case msg.trayIconFileName do
            nil -> acc
            _ -> [acc, "r", Protox.Encode.encode_string(msg.trayIconFileName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:trayIconFileName, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailDirectPath(acc, msg) do
        try do
          case msg.thumbnailDirectPath do
            nil -> acc
            _ -> [acc, "z", Protox.Encode.encode_string(msg.thumbnailDirectPath)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailDirectPath, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailSHA256(acc, msg) do
        try do
          case msg.thumbnailSHA256 do
            nil -> acc
            _ -> [acc, "\x82\x01", Protox.Encode.encode_bytes(msg.thumbnailSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailEncSHA256(acc, msg) do
        try do
          case msg.thumbnailEncSHA256 do
            nil -> acc
            _ -> [acc, "\x8A\x01", Protox.Encode.encode_bytes(msg.thumbnailEncSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailEncSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailHeight(acc, msg) do
        try do
          case msg.thumbnailHeight do
            nil -> acc
            _ -> [acc, "\x90\x01", Protox.Encode.encode_uint32(msg.thumbnailHeight)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailHeight, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailWidth(acc, msg) do
        try do
          case msg.thumbnailWidth do
            nil -> acc
            _ -> [acc, "\x98\x01", Protox.Encode.encode_uint32(msg.thumbnailWidth)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailWidth, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_imageDataHash(acc, msg) do
        try do
          case msg.imageDataHash do
            nil -> acc
            _ -> [acc, "\xA2\x01", Protox.Encode.encode_string(msg.imageDataHash)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imageDataHash, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_stickerPackSize(acc, msg) do
        try do
          case msg.stickerPackSize do
            nil -> acc
            _ -> [acc, "\xA8\x01", Protox.Encode.encode_uint64(msg.stickerPackSize)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:stickerPackSize, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_stickerPackOrigin(acc, msg) do
        try do
          case msg.stickerPackOrigin do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xB0\x01",
                msg.stickerPackOrigin
                |> WAWebProtobufsE2E.StickerPackMessage.StickerPackOrigin.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:stickerPackOrigin, "invalid field value"),
                    __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.StickerPackMessage))
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
              {[stickerPackID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[name: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[publisher: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 stickers:
                   msg.stickers ++
                     [WAWebProtobufsE2E.StickerPackMessage.Sticker.decode!(delimited)]
               ], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[fileLength: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fileSHA256: delimited], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fileEncSHA256: delimited], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mediaKey: delimited], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[directPath: Protox.Decode.validate_string!(delimited)], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[caption: Protox.Decode.validate_string!(delimited)], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contextInfo:
                   Protox.MergeMessage.merge(
                     msg.contextInfo,
                     WAWebProtobufsE2E.ContextInfo.decode!(delimited)
                   )
               ], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[packDescription: Protox.Decode.validate_string!(delimited)], rest}

            {13, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[mediaKeyTimestamp: value], rest}

            {14, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[trayIconFileName: Protox.Decode.validate_string!(delimited)], rest}

            {15, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnailDirectPath: Protox.Decode.validate_string!(delimited)], rest}

            {16, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnailSHA256: delimited], rest}

            {17, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnailEncSHA256: delimited], rest}

            {18, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[thumbnailHeight: value], rest}

            {19, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[thumbnailWidth: value], rest}

            {20, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[imageDataHash: Protox.Decode.validate_string!(delimited)], rest}

            {21, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[stickerPackSize: value], rest}

            {22, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.StickerPackMessage.StickerPackOrigin
                )

              {[stickerPackOrigin: value], rest}

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
        WAWebProtobufsE2E.StickerPackMessage,
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
        1 => {:stickerPackID, {:scalar, ""}, :string},
        2 => {:name, {:scalar, ""}, :string},
        3 => {:publisher, {:scalar, ""}, :string},
        4 => {:stickers, :unpacked, {:message, WAWebProtobufsE2E.StickerPackMessage.Sticker}},
        5 => {:fileLength, {:scalar, 0}, :uint64},
        6 => {:fileSHA256, {:scalar, ""}, :bytes},
        7 => {:fileEncSHA256, {:scalar, ""}, :bytes},
        8 => {:mediaKey, {:scalar, ""}, :bytes},
        9 => {:directPath, {:scalar, ""}, :string},
        10 => {:caption, {:scalar, ""}, :string},
        11 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        12 => {:packDescription, {:scalar, ""}, :string},
        13 => {:mediaKeyTimestamp, {:scalar, 0}, :int64},
        14 => {:trayIconFileName, {:scalar, ""}, :string},
        15 => {:thumbnailDirectPath, {:scalar, ""}, :string},
        16 => {:thumbnailSHA256, {:scalar, ""}, :bytes},
        17 => {:thumbnailEncSHA256, {:scalar, ""}, :bytes},
        18 => {:thumbnailHeight, {:scalar, 0}, :uint32},
        19 => {:thumbnailWidth, {:scalar, 0}, :uint32},
        20 => {:imageDataHash, {:scalar, ""}, :string},
        21 => {:stickerPackSize, {:scalar, 0}, :uint64},
        22 =>
          {:stickerPackOrigin, {:scalar, :FIRST_PARTY},
           {:enum, WAWebProtobufsE2E.StickerPackMessage.StickerPackOrigin}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        caption: {10, {:scalar, ""}, :string},
        contextInfo: {11, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        directPath: {9, {:scalar, ""}, :string},
        fileEncSHA256: {7, {:scalar, ""}, :bytes},
        fileLength: {5, {:scalar, 0}, :uint64},
        fileSHA256: {6, {:scalar, ""}, :bytes},
        imageDataHash: {20, {:scalar, ""}, :string},
        mediaKey: {8, {:scalar, ""}, :bytes},
        mediaKeyTimestamp: {13, {:scalar, 0}, :int64},
        name: {2, {:scalar, ""}, :string},
        packDescription: {12, {:scalar, ""}, :string},
        publisher: {3, {:scalar, ""}, :string},
        stickerPackID: {1, {:scalar, ""}, :string},
        stickerPackOrigin:
          {22, {:scalar, :FIRST_PARTY},
           {:enum, WAWebProtobufsE2E.StickerPackMessage.StickerPackOrigin}},
        stickerPackSize: {21, {:scalar, 0}, :uint64},
        stickers: {4, :unpacked, {:message, WAWebProtobufsE2E.StickerPackMessage.Sticker}},
        thumbnailDirectPath: {15, {:scalar, ""}, :string},
        thumbnailEncSHA256: {17, {:scalar, ""}, :bytes},
        thumbnailHeight: {18, {:scalar, 0}, :uint32},
        thumbnailSHA256: {16, {:scalar, ""}, :bytes},
        thumbnailWidth: {19, {:scalar, 0}, :uint32},
        trayIconFileName: {14, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "stickerPackID",
          kind: {:scalar, ""},
          label: :optional,
          name: :stickerPackID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "name",
          kind: {:scalar, ""},
          label: :optional,
          name: :name,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "publisher",
          kind: {:scalar, ""},
          label: :optional,
          name: :publisher,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "stickers",
          kind: :unpacked,
          label: :repeated,
          name: :stickers,
          tag: 4,
          type: {:message, WAWebProtobufsE2E.StickerPackMessage.Sticker}
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileLength",
          kind: {:scalar, 0},
          label: :optional,
          name: :fileLength,
          tag: 5,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileSHA256,
          tag: 6,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileEncSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileEncSHA256,
          tag: 7,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :mediaKey,
          tag: 8,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "directPath",
          kind: {:scalar, ""},
          label: :optional,
          name: :directPath,
          tag: 9,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "caption",
          kind: {:scalar, ""},
          label: :optional,
          name: :caption,
          tag: 10,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "contextInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :contextInfo,
          tag: 11,
          type: {:message, WAWebProtobufsE2E.ContextInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "packDescription",
          kind: {:scalar, ""},
          label: :optional,
          name: :packDescription,
          tag: 12,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKeyTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :mediaKeyTimestamp,
          tag: 13,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "trayIconFileName",
          kind: {:scalar, ""},
          label: :optional,
          name: :trayIconFileName,
          tag: 14,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailDirectPath",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailDirectPath,
          tag: 15,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailSHA256,
          tag: 16,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailEncSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailEncSHA256,
          tag: 17,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailHeight",
          kind: {:scalar, 0},
          label: :optional,
          name: :thumbnailHeight,
          tag: 18,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailWidth",
          kind: {:scalar, 0},
          label: :optional,
          name: :thumbnailWidth,
          tag: 19,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "imageDataHash",
          kind: {:scalar, ""},
          label: :optional,
          name: :imageDataHash,
          tag: 20,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "stickerPackSize",
          kind: {:scalar, 0},
          label: :optional,
          name: :stickerPackSize,
          tag: 21,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "stickerPackOrigin",
          kind: {:scalar, :FIRST_PARTY},
          label: :optional,
          name: :stickerPackOrigin,
          tag: 22,
          type: {:enum, WAWebProtobufsE2E.StickerPackMessage.StickerPackOrigin}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:stickerPackID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerPackID",
             kind: {:scalar, ""},
             label: :optional,
             name: :stickerPackID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("stickerPackID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerPackID",
             kind: {:scalar, ""},
             label: :optional,
             name: :stickerPackID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:name) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "name",
             kind: {:scalar, ""},
             label: :optional,
             name: :name,
             tag: 2,
             type: :string
           }}
        end

        def field_def("name") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "name",
             kind: {:scalar, ""},
             label: :optional,
             name: :name,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:publisher) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "publisher",
             kind: {:scalar, ""},
             label: :optional,
             name: :publisher,
             tag: 3,
             type: :string
           }}
        end

        def field_def("publisher") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "publisher",
             kind: {:scalar, ""},
             label: :optional,
             name: :publisher,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:stickers) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickers",
             kind: :unpacked,
             label: :repeated,
             name: :stickers,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.StickerPackMessage.Sticker}
           }}
        end

        def field_def("stickers") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickers",
             kind: :unpacked,
             label: :repeated,
             name: :stickers,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.StickerPackMessage.Sticker}
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
             tag: 5,
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
             tag: 5,
             type: :uint64
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
             tag: 6,
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
             tag: 6,
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
             tag: 7,
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
             tag: 7,
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
             tag: 8,
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
             tag: 8,
             type: :bytes
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
             tag: 9,
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
             tag: 9,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:caption) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "caption",
             kind: {:scalar, ""},
             label: :optional,
             name: :caption,
             tag: 10,
             type: :string
           }}
        end

        def field_def("caption") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "caption",
             kind: {:scalar, ""},
             label: :optional,
             name: :caption,
             tag: 10,
             type: :string
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
             tag: 11,
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
             tag: 11,
             type: {:message, WAWebProtobufsE2E.ContextInfo}
           }}
        end

        []
      ),
      (
        def field_def(:packDescription) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "packDescription",
             kind: {:scalar, ""},
             label: :optional,
             name: :packDescription,
             tag: 12,
             type: :string
           }}
        end

        def field_def("packDescription") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "packDescription",
             kind: {:scalar, ""},
             label: :optional,
             name: :packDescription,
             tag: 12,
             type: :string
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
             tag: 13,
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
             tag: 13,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:trayIconFileName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "trayIconFileName",
             kind: {:scalar, ""},
             label: :optional,
             name: :trayIconFileName,
             tag: 14,
             type: :string
           }}
        end

        def field_def("trayIconFileName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "trayIconFileName",
             kind: {:scalar, ""},
             label: :optional,
             name: :trayIconFileName,
             tag: 14,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailDirectPath) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailDirectPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailDirectPath,
             tag: 15,
             type: :string
           }}
        end

        def field_def("thumbnailDirectPath") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailDirectPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailDirectPath,
             tag: 15,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailSHA256,
             tag: 16,
             type: :bytes
           }}
        end

        def field_def("thumbnailSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailSHA256,
             tag: 16,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailEncSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailEncSHA256,
             tag: 17,
             type: :bytes
           }}
        end

        def field_def("thumbnailEncSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailEncSHA256,
             tag: 17,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailHeight) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailHeight",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailHeight,
             tag: 18,
             type: :uint32
           }}
        end

        def field_def("thumbnailHeight") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailHeight",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailHeight,
             tag: 18,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailWidth) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailWidth",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailWidth,
             tag: 19,
             type: :uint32
           }}
        end

        def field_def("thumbnailWidth") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailWidth",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailWidth,
             tag: 19,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:imageDataHash) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageDataHash",
             kind: {:scalar, ""},
             label: :optional,
             name: :imageDataHash,
             tag: 20,
             type: :string
           }}
        end

        def field_def("imageDataHash") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageDataHash",
             kind: {:scalar, ""},
             label: :optional,
             name: :imageDataHash,
             tag: 20,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:stickerPackSize) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerPackSize",
             kind: {:scalar, 0},
             label: :optional,
             name: :stickerPackSize,
             tag: 21,
             type: :uint64
           }}
        end

        def field_def("stickerPackSize") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerPackSize",
             kind: {:scalar, 0},
             label: :optional,
             name: :stickerPackSize,
             tag: 21,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:stickerPackOrigin) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerPackOrigin",
             kind: {:scalar, :FIRST_PARTY},
             label: :optional,
             name: :stickerPackOrigin,
             tag: 22,
             type: {:enum, WAWebProtobufsE2E.StickerPackMessage.StickerPackOrigin}
           }}
        end

        def field_def("stickerPackOrigin") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerPackOrigin",
             kind: {:scalar, :FIRST_PARTY},
             label: :optional,
             name: :stickerPackOrigin,
             tag: 22,
             type: {:enum, WAWebProtobufsE2E.StickerPackMessage.StickerPackOrigin}
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
    def default(:stickerPackID) do
      {:ok, ""}
    end,
    def default(:name) do
      {:ok, ""}
    end,
    def default(:publisher) do
      {:ok, ""}
    end,
    def default(:stickers) do
      {:error, :no_default_value}
    end,
    def default(:fileLength) do
      {:ok, 0}
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
    def default(:directPath) do
      {:ok, ""}
    end,
    def default(:caption) do
      {:ok, ""}
    end,
    def default(:contextInfo) do
      {:ok, nil}
    end,
    def default(:packDescription) do
      {:ok, ""}
    end,
    def default(:mediaKeyTimestamp) do
      {:ok, 0}
    end,
    def default(:trayIconFileName) do
      {:ok, ""}
    end,
    def default(:thumbnailDirectPath) do
      {:ok, ""}
    end,
    def default(:thumbnailSHA256) do
      {:ok, ""}
    end,
    def default(:thumbnailEncSHA256) do
      {:ok, ""}
    end,
    def default(:thumbnailHeight) do
      {:ok, 0}
    end,
    def default(:thumbnailWidth) do
      {:ok, 0}
    end,
    def default(:imageDataHash) do
      {:ok, ""}
    end,
    def default(:stickerPackSize) do
      {:ok, 0}
    end,
    def default(:stickerPackOrigin) do
      {:ok, :FIRST_PARTY}
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
