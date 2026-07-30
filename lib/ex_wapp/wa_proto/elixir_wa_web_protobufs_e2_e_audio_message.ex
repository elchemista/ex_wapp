# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.AudioMessage do
  @moduledoc false
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
            backgroundArgb: nil,
            viewOnce: nil,
            accessibilityLabel: nil,
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
        |> encode_mimetype(msg)
        |> encode_fileSHA256(msg)
        |> encode_fileLength(msg)
        |> encode_seconds(msg)
        |> encode_PTT(msg)
        |> encode_mediaKey(msg)
        |> encode_fileEncSHA256(msg)
        |> encode_directPath(msg)
        |> encode_mediaKeyTimestamp(msg)
        |> encode_contextInfo(msg)
        |> encode_streamingSidecar(msg)
        |> encode_waveform(msg)
        |> encode_backgroundArgb(msg)
        |> encode_viewOnce(msg)
        |> encode_accessibilityLabel(msg)
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
      defp encode_mimetype(acc, msg) do
        try do
          case msg.mimetype do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.mimetype)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mimetype, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileSHA256(acc, msg) do
        try do
          case msg.fileSHA256 do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_bytes(msg.fileSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileSHA256, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileLength(acc, msg) do
        try do
          case msg.fileLength do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_uint64(msg.fileLength)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileLength, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_seconds(acc, msg) do
        try do
          case msg.seconds do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_uint32(msg.seconds)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:seconds, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_PTT(acc, msg) do
        try do
          case msg."PTT" do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_bool(msg."PTT")]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:PTT, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaKey(acc, msg) do
        try do
          case msg.mediaKey do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_bytes(msg.mediaKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaKey, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileEncSHA256(acc, msg) do
        try do
          case msg.fileEncSHA256 do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_bytes(msg.fileEncSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileEncSHA256, "invalid field value"),
                    __STACKTRACE__
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
      defp encode_streamingSidecar(acc, msg) do
        try do
          case msg.streamingSidecar do
            nil -> acc
            _ -> [acc, "\x92\x01", Protox.Encode.encode_bytes(msg.streamingSidecar)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:streamingSidecar, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_waveform(acc, msg) do
        try do
          case msg.waveform do
            nil -> acc
            _ -> [acc, "\x9A\x01", Protox.Encode.encode_bytes(msg.waveform)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:waveform, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_backgroundArgb(acc, msg) do
        try do
          case msg.backgroundArgb do
            nil -> acc
            _ -> [acc, "\xA5\x01", Protox.Encode.encode_fixed32(msg.backgroundArgb)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:backgroundArgb, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_viewOnce(acc, msg) do
        try do
          case msg.viewOnce do
            nil -> acc
            _ -> [acc, "\xA8\x01", Protox.Encode.encode_bool(msg.viewOnce)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:viewOnce, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.AudioMessage))
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
              {[mimetype: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fileSHA256: delimited], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[fileLength: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[seconds: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[PTT: value], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mediaKey: delimited], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fileEncSHA256: delimited], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[directPath: Protox.Decode.validate_string!(delimited)], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[mediaKeyTimestamp: value], rest}

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
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[streamingSidecar: delimited], rest}

            {19, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[waveform: delimited], rest}

            {20, _, bytes} ->
              {value, rest} = Protox.Decode.parse_fixed32(bytes)
              {[backgroundArgb: value], rest}

            {21, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[viewOnce: value], rest}

            {22, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[accessibilityLabel: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufsE2E.AudioMessage,
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
        2 => {:mimetype, {:scalar, ""}, :string},
        3 => {:fileSHA256, {:scalar, ""}, :bytes},
        4 => {:fileLength, {:scalar, 0}, :uint64},
        5 => {:seconds, {:scalar, 0}, :uint32},
        6 => {:PTT, {:scalar, false}, :bool},
        7 => {:mediaKey, {:scalar, ""}, :bytes},
        8 => {:fileEncSHA256, {:scalar, ""}, :bytes},
        9 => {:directPath, {:scalar, ""}, :string},
        10 => {:mediaKeyTimestamp, {:scalar, 0}, :int64},
        17 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        18 => {:streamingSidecar, {:scalar, ""}, :bytes},
        19 => {:waveform, {:scalar, ""}, :bytes},
        20 => {:backgroundArgb, {:scalar, 0}, :fixed32},
        21 => {:viewOnce, {:scalar, false}, :bool},
        22 => {:accessibilityLabel, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        PTT: {6, {:scalar, false}, :bool},
        URL: {1, {:scalar, ""}, :string},
        accessibilityLabel: {22, {:scalar, ""}, :string},
        backgroundArgb: {20, {:scalar, 0}, :fixed32},
        contextInfo: {17, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        directPath: {9, {:scalar, ""}, :string},
        fileEncSHA256: {8, {:scalar, ""}, :bytes},
        fileLength: {4, {:scalar, 0}, :uint64},
        fileSHA256: {3, {:scalar, ""}, :bytes},
        mediaKey: {7, {:scalar, ""}, :bytes},
        mediaKeyTimestamp: {10, {:scalar, 0}, :int64},
        mimetype: {2, {:scalar, ""}, :string},
        seconds: {5, {:scalar, 0}, :uint32},
        streamingSidecar: {18, {:scalar, ""}, :bytes},
        viewOnce: {21, {:scalar, false}, :bool},
        waveform: {19, {:scalar, ""}, :bytes}
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
          json_name: "mimetype",
          kind: {:scalar, ""},
          label: :optional,
          name: :mimetype,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileSHA256,
          tag: 3,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileLength",
          kind: {:scalar, 0},
          label: :optional,
          name: :fileLength,
          tag: 4,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "seconds",
          kind: {:scalar, 0},
          label: :optional,
          name: :seconds,
          tag: 5,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "PTT",
          kind: {:scalar, false},
          label: :optional,
          name: :PTT,
          tag: 6,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :mediaKey,
          tag: 7,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileEncSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileEncSHA256,
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
          json_name: "mediaKeyTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :mediaKeyTimestamp,
          tag: 10,
          type: :int64
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
          json_name: "streamingSidecar",
          kind: {:scalar, ""},
          label: :optional,
          name: :streamingSidecar,
          tag: 18,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "waveform",
          kind: {:scalar, ""},
          label: :optional,
          name: :waveform,
          tag: 19,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "backgroundArgb",
          kind: {:scalar, 0},
          label: :optional,
          name: :backgroundArgb,
          tag: 20,
          type: :fixed32
        },
        %{
          __struct__: Protox.Field,
          json_name: "viewOnce",
          kind: {:scalar, false},
          label: :optional,
          name: :viewOnce,
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
        def field_def(:mimetype) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mimetype",
             kind: {:scalar, ""},
             label: :optional,
             name: :mimetype,
             tag: 2,
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
             tag: 2,
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
             tag: 3,
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
             tag: 3,
             type: :bytes
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
             tag: 4,
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
             tag: 4,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:seconds) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "seconds",
             kind: {:scalar, 0},
             label: :optional,
             name: :seconds,
             tag: 5,
             type: :uint32
           }}
        end

        def field_def("seconds") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "seconds",
             kind: {:scalar, 0},
             label: :optional,
             name: :seconds,
             tag: 5,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:PTT) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "PTT",
             kind: {:scalar, false},
             label: :optional,
             name: :PTT,
             tag: 6,
             type: :bool
           }}
        end

        def field_def("PTT") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "PTT",
             kind: {:scalar, false},
             label: :optional,
             name: :PTT,
             tag: 6,
             type: :bool
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
             tag: 7,
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
             tag: 7,
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
             tag: 8,
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
        def field_def(:streamingSidecar) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "streamingSidecar",
             kind: {:scalar, ""},
             label: :optional,
             name: :streamingSidecar,
             tag: 18,
             type: :bytes
           }}
        end

        def field_def("streamingSidecar") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "streamingSidecar",
             kind: {:scalar, ""},
             label: :optional,
             name: :streamingSidecar,
             tag: 18,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:waveform) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "waveform",
             kind: {:scalar, ""},
             label: :optional,
             name: :waveform,
             tag: 19,
             type: :bytes
           }}
        end

        def field_def("waveform") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "waveform",
             kind: {:scalar, ""},
             label: :optional,
             name: :waveform,
             tag: 19,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:backgroundArgb) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "backgroundArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :backgroundArgb,
             tag: 20,
             type: :fixed32
           }}
        end

        def field_def("backgroundArgb") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "backgroundArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :backgroundArgb,
             tag: 20,
             type: :fixed32
           }}
        end

        []
      ),
      (
        def field_def(:viewOnce) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "viewOnce",
             kind: {:scalar, false},
             label: :optional,
             name: :viewOnce,
             tag: 21,
             type: :bool
           }}
        end

        def field_def("viewOnce") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "viewOnce",
             kind: {:scalar, false},
             label: :optional,
             name: :viewOnce,
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
    def default(:mimetype) do
      {:ok, ""}
    end,
    def default(:fileSHA256) do
      {:ok, ""}
    end,
    def default(:fileLength) do
      {:ok, 0}
    end,
    def default(:seconds) do
      {:ok, 0}
    end,
    def default(:PTT) do
      {:ok, false}
    end,
    def default(:mediaKey) do
      {:ok, ""}
    end,
    def default(:fileEncSHA256) do
      {:ok, ""}
    end,
    def default(:directPath) do
      {:ok, ""}
    end,
    def default(:mediaKeyTimestamp) do
      {:ok, 0}
    end,
    def default(:contextInfo) do
      {:ok, nil}
    end,
    def default(:streamingSidecar) do
      {:ok, ""}
    end,
    def default(:waveform) do
      {:ok, ""}
    end,
    def default(:backgroundArgb) do
      {:ok, 0}
    end,
    def default(:viewOnce) do
      {:ok, false}
    end,
    def default(:accessibilityLabel) do
      {:ok, ""}
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
