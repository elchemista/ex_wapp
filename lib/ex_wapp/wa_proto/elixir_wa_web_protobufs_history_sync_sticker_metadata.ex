# credo:disable-for-this-file
defmodule WAWebProtobufsHistorySync.StickerMetadata do
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
            weight: nil,
            lastStickerSentTS: nil,
            isLottie: nil,
            imageHash: nil,
            isAvatarSticker: nil,
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
        |> encode_URL(msg)
        |> encode_fileSHA256(msg)
        |> encode_fileEncSHA256(msg)
        |> encode_mediaKey(msg)
        |> encode_mimetype(msg)
        |> encode_height(msg)
        |> encode_width(msg)
        |> encode_directPath(msg)
        |> encode_fileLength(msg)
        |> encode_weight(msg)
        |> encode_lastStickerSentTS(msg)
        |> encode_isLottie(msg)
        |> encode_imageHash(msg)
        |> encode_isAvatarSticker(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

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
      defp encode_weight(acc, msg) do
        try do
          case msg.weight do
            nil -> acc
            _ -> [acc, "U", Protox.Encode.encode_float(msg.weight)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:weight, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_lastStickerSentTS(acc, msg) do
        try do
          case msg.lastStickerSentTS do
            nil -> acc
            _ -> [acc, "X", Protox.Encode.encode_int64(msg.lastStickerSentTS)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lastStickerSentTS, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isLottie(acc, msg) do
        try do
          case msg.isLottie do
            nil -> acc
            _ -> [acc, "`", Protox.Encode.encode_bool(msg.isLottie)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isLottie, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_imageHash(acc, msg) do
        try do
          case msg.imageHash do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_string(msg.imageHash)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imageHash, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isAvatarSticker(acc, msg) do
        try do
          case msg.isAvatarSticker do
            nil -> acc
            _ -> [acc, "p", Protox.Encode.encode_bool(msg.isAvatarSticker)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isAvatarSticker, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsHistorySync.StickerMetadata))
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
              {value, rest} = Protox.Decode.parse_float(bytes)
              {[weight: value], rest}

            {11, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[lastStickerSentTS: value], rest}

            {12, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isLottie: value], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[imageHash: Protox.Decode.validate_string!(delimited)], rest}

            {14, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isAvatarSticker: value], rest}

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
        WAWebProtobufsHistorySync.StickerMetadata,
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
        10 => {:weight, {:scalar, 0.0}, :float},
        11 => {:lastStickerSentTS, {:scalar, 0}, :int64},
        12 => {:isLottie, {:scalar, false}, :bool},
        13 => {:imageHash, {:scalar, ""}, :string},
        14 => {:isAvatarSticker, {:scalar, false}, :bool}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        URL: {1, {:scalar, ""}, :string},
        directPath: {8, {:scalar, ""}, :string},
        fileEncSHA256: {3, {:scalar, ""}, :bytes},
        fileLength: {9, {:scalar, 0}, :uint64},
        fileSHA256: {2, {:scalar, ""}, :bytes},
        height: {6, {:scalar, 0}, :uint32},
        imageHash: {13, {:scalar, ""}, :string},
        isAvatarSticker: {14, {:scalar, false}, :bool},
        isLottie: {12, {:scalar, false}, :bool},
        lastStickerSentTS: {11, {:scalar, 0}, :int64},
        mediaKey: {4, {:scalar, ""}, :bytes},
        mimetype: {5, {:scalar, ""}, :string},
        weight: {10, {:scalar, 0.0}, :float},
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
          json_name: "weight",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :weight,
          tag: 10,
          type: :float
        },
        %{
          __struct__: Protox.Field,
          json_name: "lastStickerSentTS",
          kind: {:scalar, 0},
          label: :optional,
          name: :lastStickerSentTS,
          tag: 11,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "isLottie",
          kind: {:scalar, false},
          label: :optional,
          name: :isLottie,
          tag: 12,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "imageHash",
          kind: {:scalar, ""},
          label: :optional,
          name: :imageHash,
          tag: 13,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "isAvatarSticker",
          kind: {:scalar, false},
          label: :optional,
          name: :isAvatarSticker,
          tag: 14,
          type: :bool
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
        def field_def(:weight) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "weight",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :weight,
             tag: 10,
             type: :float
           }}
        end

        def field_def("weight") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "weight",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :weight,
             tag: 10,
             type: :float
           }}
        end

        []
      ),
      (
        def field_def(:lastStickerSentTS) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lastStickerSentTS",
             kind: {:scalar, 0},
             label: :optional,
             name: :lastStickerSentTS,
             tag: 11,
             type: :int64
           }}
        end

        def field_def("lastStickerSentTS") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lastStickerSentTS",
             kind: {:scalar, 0},
             label: :optional,
             name: :lastStickerSentTS,
             tag: 11,
             type: :int64
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
             tag: 12,
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
             tag: 12,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:imageHash) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageHash",
             kind: {:scalar, ""},
             label: :optional,
             name: :imageHash,
             tag: 13,
             type: :string
           }}
        end

        def field_def("imageHash") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageHash",
             kind: {:scalar, ""},
             label: :optional,
             name: :imageHash,
             tag: 13,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:isAvatarSticker) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isAvatarSticker",
             kind: {:scalar, false},
             label: :optional,
             name: :isAvatarSticker,
             tag: 14,
             type: :bool
           }}
        end

        def field_def("isAvatarSticker") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isAvatarSticker",
             kind: {:scalar, false},
             label: :optional,
             name: :isAvatarSticker,
             tag: 14,
             type: :bool
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
    def default(:weight) do
      {:ok, 0.0}
    end,
    def default(:lastStickerSentTS) do
      {:ok, 0}
    end,
    def default(:isLottie) do
      {:ok, false}
    end,
    def default(:imageHash) do
      {:ok, ""}
    end,
    def default(:isAvatarSticker) do
      {:ok, false}
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
        go_package: "go.mau.fi/whatsmeow/proto/waHistorySync",
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
end
