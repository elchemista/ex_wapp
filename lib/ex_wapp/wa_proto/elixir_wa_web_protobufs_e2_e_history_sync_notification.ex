# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.HistorySyncNotification do
  @moduledoc false
  defstruct fileSHA256: nil,
            fileLength: nil,
            mediaKey: nil,
            fileEncSHA256: nil,
            directPath: nil,
            syncType: nil,
            chunkOrder: nil,
            originalMessageID: nil,
            progress: nil,
            oldestMsgInChunkTimestampSec: nil,
            initialHistBootstrapInlinePayload: nil,
            peerDataRequestSessionID: nil,
            fullHistorySyncOnDemandRequestMetadata: nil,
            encHandle: nil,
            messageAccessStatus: nil,
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
        |> encode_fileSHA256(msg)
        |> encode_fileLength(msg)
        |> encode_mediaKey(msg)
        |> encode_fileEncSHA256(msg)
        |> encode_directPath(msg)
        |> encode_syncType(msg)
        |> encode_chunkOrder(msg)
        |> encode_originalMessageID(msg)
        |> encode_progress(msg)
        |> encode_oldestMsgInChunkTimestampSec(msg)
        |> encode_initialHistBootstrapInlinePayload(msg)
        |> encode_peerDataRequestSessionID(msg)
        |> encode_fullHistorySyncOnDemandRequestMetadata(msg)
        |> encode_encHandle(msg)
        |> encode_messageAccessStatus(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_fileSHA256(acc, msg) do
        try do
          case msg.fileSHA256 do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_bytes(msg.fileSHA256)]
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
            _ -> [acc, "\x10", Protox.Encode.encode_uint64(msg.fileLength)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileLength, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaKey(acc, msg) do
        try do
          case msg.mediaKey do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_bytes(msg.mediaKey)]
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
            _ -> [acc, "\"", Protox.Encode.encode_bytes(msg.fileEncSHA256)]
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
            _ -> [acc, "*", Protox.Encode.encode_string(msg.directPath)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:directPath, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_syncType(acc, msg) do
        try do
          case msg.syncType do
            nil ->
              acc

            _ ->
              [
                acc,
                "0",
                msg.syncType
                |> WAWebProtobufsE2E.HistorySyncType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:syncType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_chunkOrder(acc, msg) do
        try do
          case msg.chunkOrder do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_uint32(msg.chunkOrder)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:chunkOrder, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_originalMessageID(acc, msg) do
        try do
          case msg.originalMessageID do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg.originalMessageID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:originalMessageID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_progress(acc, msg) do
        try do
          case msg.progress do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_uint32(msg.progress)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:progress, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_oldestMsgInChunkTimestampSec(acc, msg) do
        try do
          case msg.oldestMsgInChunkTimestampSec do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_int64(msg.oldestMsgInChunkTimestampSec)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :oldestMsgInChunkTimestampSec,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_initialHistBootstrapInlinePayload(acc, msg) do
        try do
          case msg.initialHistBootstrapInlinePayload do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_bytes(msg.initialHistBootstrapInlinePayload)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :initialHistBootstrapInlinePayload,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_peerDataRequestSessionID(acc, msg) do
        try do
          case msg.peerDataRequestSessionID do
            nil -> acc
            _ -> [acc, "b", Protox.Encode.encode_string(msg.peerDataRequestSessionID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:peerDataRequestSessionID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_fullHistorySyncOnDemandRequestMetadata(acc, msg) do
        try do
          case msg.fullHistorySyncOnDemandRequestMetadata do
            nil ->
              acc

            _ ->
              [acc, "j", Protox.Encode.encode_message(msg.fullHistorySyncOnDemandRequestMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :fullHistorySyncOnDemandRequestMetadata,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_encHandle(acc, msg) do
        try do
          case msg.encHandle do
            nil -> acc
            _ -> [acc, "r", Protox.Encode.encode_string(msg.encHandle)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:encHandle, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_messageAccessStatus(acc, msg) do
        try do
          case msg.messageAccessStatus do
            nil -> acc
            _ -> [acc, "z", Protox.Encode.encode_message(msg.messageAccessStatus)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageAccessStatus, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.HistorySyncNotification))
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
              {[fileSHA256: delimited], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[fileLength: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mediaKey: delimited], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fileEncSHA256: delimited], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[directPath: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.HistorySyncType)
              {[syncType: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[chunkOrder: value], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[originalMessageID: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[progress: value], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[oldestMsgInChunkTimestampSec: value], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[initialHistBootstrapInlinePayload: delimited], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[peerDataRequestSessionID: Protox.Decode.validate_string!(delimited)], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 fullHistorySyncOnDemandRequestMetadata:
                   Protox.MergeMessage.merge(
                     msg.fullHistorySyncOnDemandRequestMetadata,
                     WAWebProtobufsE2E.FullHistorySyncOnDemandRequestMetadata.decode!(delimited)
                   )
               ], rest}

            {14, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[encHandle: Protox.Decode.validate_string!(delimited)], rest}

            {15, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 messageAccessStatus:
                   Protox.MergeMessage.merge(
                     msg.messageAccessStatus,
                     WAWebProtobufsE2E.HistorySyncMessageAccessStatus.decode!(delimited)
                   )
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
        WAWebProtobufsE2E.HistorySyncNotification,
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
        1 => {:fileSHA256, {:scalar, ""}, :bytes},
        2 => {:fileLength, {:scalar, 0}, :uint64},
        3 => {:mediaKey, {:scalar, ""}, :bytes},
        4 => {:fileEncSHA256, {:scalar, ""}, :bytes},
        5 => {:directPath, {:scalar, ""}, :string},
        6 =>
          {:syncType, {:scalar, :INITIAL_BOOTSTRAP}, {:enum, WAWebProtobufsE2E.HistorySyncType}},
        7 => {:chunkOrder, {:scalar, 0}, :uint32},
        8 => {:originalMessageID, {:scalar, ""}, :string},
        9 => {:progress, {:scalar, 0}, :uint32},
        10 => {:oldestMsgInChunkTimestampSec, {:scalar, 0}, :int64},
        11 => {:initialHistBootstrapInlinePayload, {:scalar, ""}, :bytes},
        12 => {:peerDataRequestSessionID, {:scalar, ""}, :string},
        13 =>
          {:fullHistorySyncOnDemandRequestMetadata, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FullHistorySyncOnDemandRequestMetadata}},
        14 => {:encHandle, {:scalar, ""}, :string},
        15 =>
          {:messageAccessStatus, {:scalar, nil},
           {:message, WAWebProtobufsE2E.HistorySyncMessageAccessStatus}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        chunkOrder: {7, {:scalar, 0}, :uint32},
        directPath: {5, {:scalar, ""}, :string},
        encHandle: {14, {:scalar, ""}, :string},
        fileEncSHA256: {4, {:scalar, ""}, :bytes},
        fileLength: {2, {:scalar, 0}, :uint64},
        fileSHA256: {1, {:scalar, ""}, :bytes},
        fullHistorySyncOnDemandRequestMetadata:
          {13, {:scalar, nil},
           {:message, WAWebProtobufsE2E.FullHistorySyncOnDemandRequestMetadata}},
        initialHistBootstrapInlinePayload: {11, {:scalar, ""}, :bytes},
        mediaKey: {3, {:scalar, ""}, :bytes},
        messageAccessStatus:
          {15, {:scalar, nil}, {:message, WAWebProtobufsE2E.HistorySyncMessageAccessStatus}},
        oldestMsgInChunkTimestampSec: {10, {:scalar, 0}, :int64},
        originalMessageID: {8, {:scalar, ""}, :string},
        peerDataRequestSessionID: {12, {:scalar, ""}, :string},
        progress: {9, {:scalar, 0}, :uint32},
        syncType: {6, {:scalar, :INITIAL_BOOTSTRAP}, {:enum, WAWebProtobufsE2E.HistorySyncType}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "fileSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileSHA256,
          tag: 1,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileLength",
          kind: {:scalar, 0},
          label: :optional,
          name: :fileLength,
          tag: 2,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :mediaKey,
          tag: 3,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileEncSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileEncSHA256,
          tag: 4,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "directPath",
          kind: {:scalar, ""},
          label: :optional,
          name: :directPath,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "syncType",
          kind: {:scalar, :INITIAL_BOOTSTRAP},
          label: :optional,
          name: :syncType,
          tag: 6,
          type: {:enum, WAWebProtobufsE2E.HistorySyncType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "chunkOrder",
          kind: {:scalar, 0},
          label: :optional,
          name: :chunkOrder,
          tag: 7,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "originalMessageID",
          kind: {:scalar, ""},
          label: :optional,
          name: :originalMessageID,
          tag: 8,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "progress",
          kind: {:scalar, 0},
          label: :optional,
          name: :progress,
          tag: 9,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "oldestMsgInChunkTimestampSec",
          kind: {:scalar, 0},
          label: :optional,
          name: :oldestMsgInChunkTimestampSec,
          tag: 10,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "initialHistBootstrapInlinePayload",
          kind: {:scalar, ""},
          label: :optional,
          name: :initialHistBootstrapInlinePayload,
          tag: 11,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "peerDataRequestSessionID",
          kind: {:scalar, ""},
          label: :optional,
          name: :peerDataRequestSessionID,
          tag: 12,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "fullHistorySyncOnDemandRequestMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :fullHistorySyncOnDemandRequestMetadata,
          tag: 13,
          type: {:message, WAWebProtobufsE2E.FullHistorySyncOnDemandRequestMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "encHandle",
          kind: {:scalar, ""},
          label: :optional,
          name: :encHandle,
          tag: 14,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageAccessStatus",
          kind: {:scalar, nil},
          label: :optional,
          name: :messageAccessStatus,
          tag: 15,
          type: {:message, WAWebProtobufsE2E.HistorySyncMessageAccessStatus}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:fileSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileSHA256,
             tag: 1,
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
             tag: 1,
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
             tag: 2,
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
             tag: 2,
             type: :uint64
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
             tag: 3,
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
             tag: 3,
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
             tag: 4,
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
             tag: 4,
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
             tag: 5,
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
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:syncType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "syncType",
             kind: {:scalar, :INITIAL_BOOTSTRAP},
             label: :optional,
             name: :syncType,
             tag: 6,
             type: {:enum, WAWebProtobufsE2E.HistorySyncType}
           }}
        end

        def field_def("syncType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "syncType",
             kind: {:scalar, :INITIAL_BOOTSTRAP},
             label: :optional,
             name: :syncType,
             tag: 6,
             type: {:enum, WAWebProtobufsE2E.HistorySyncType}
           }}
        end

        []
      ),
      (
        def field_def(:chunkOrder) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chunkOrder",
             kind: {:scalar, 0},
             label: :optional,
             name: :chunkOrder,
             tag: 7,
             type: :uint32
           }}
        end

        def field_def("chunkOrder") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chunkOrder",
             kind: {:scalar, 0},
             label: :optional,
             name: :chunkOrder,
             tag: 7,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:originalMessageID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "originalMessageID",
             kind: {:scalar, ""},
             label: :optional,
             name: :originalMessageID,
             tag: 8,
             type: :string
           }}
        end

        def field_def("originalMessageID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "originalMessageID",
             kind: {:scalar, ""},
             label: :optional,
             name: :originalMessageID,
             tag: 8,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:progress) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "progress",
             kind: {:scalar, 0},
             label: :optional,
             name: :progress,
             tag: 9,
             type: :uint32
           }}
        end

        def field_def("progress") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "progress",
             kind: {:scalar, 0},
             label: :optional,
             name: :progress,
             tag: 9,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:oldestMsgInChunkTimestampSec) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldestMsgInChunkTimestampSec",
             kind: {:scalar, 0},
             label: :optional,
             name: :oldestMsgInChunkTimestampSec,
             tag: 10,
             type: :int64
           }}
        end

        def field_def("oldestMsgInChunkTimestampSec") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldestMsgInChunkTimestampSec",
             kind: {:scalar, 0},
             label: :optional,
             name: :oldestMsgInChunkTimestampSec,
             tag: 10,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:initialHistBootstrapInlinePayload) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "initialHistBootstrapInlinePayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :initialHistBootstrapInlinePayload,
             tag: 11,
             type: :bytes
           }}
        end

        def field_def("initialHistBootstrapInlinePayload") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "initialHistBootstrapInlinePayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :initialHistBootstrapInlinePayload,
             tag: 11,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:peerDataRequestSessionID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "peerDataRequestSessionID",
             kind: {:scalar, ""},
             label: :optional,
             name: :peerDataRequestSessionID,
             tag: 12,
             type: :string
           }}
        end

        def field_def("peerDataRequestSessionID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "peerDataRequestSessionID",
             kind: {:scalar, ""},
             label: :optional,
             name: :peerDataRequestSessionID,
             tag: 12,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:fullHistorySyncOnDemandRequestMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fullHistorySyncOnDemandRequestMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :fullHistorySyncOnDemandRequestMetadata,
             tag: 13,
             type: {:message, WAWebProtobufsE2E.FullHistorySyncOnDemandRequestMetadata}
           }}
        end

        def field_def("fullHistorySyncOnDemandRequestMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fullHistorySyncOnDemandRequestMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :fullHistorySyncOnDemandRequestMetadata,
             tag: 13,
             type: {:message, WAWebProtobufsE2E.FullHistorySyncOnDemandRequestMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:encHandle) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "encHandle",
             kind: {:scalar, ""},
             label: :optional,
             name: :encHandle,
             tag: 14,
             type: :string
           }}
        end

        def field_def("encHandle") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "encHandle",
             kind: {:scalar, ""},
             label: :optional,
             name: :encHandle,
             tag: 14,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:messageAccessStatus) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageAccessStatus",
             kind: {:scalar, nil},
             label: :optional,
             name: :messageAccessStatus,
             tag: 15,
             type: {:message, WAWebProtobufsE2E.HistorySyncMessageAccessStatus}
           }}
        end

        def field_def("messageAccessStatus") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageAccessStatus",
             kind: {:scalar, nil},
             label: :optional,
             name: :messageAccessStatus,
             tag: 15,
             type: {:message, WAWebProtobufsE2E.HistorySyncMessageAccessStatus}
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
    def default(:fileSHA256) do
      {:ok, ""}
    end,
    def default(:fileLength) do
      {:ok, 0}
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
    def default(:syncType) do
      {:ok, :INITIAL_BOOTSTRAP}
    end,
    def default(:chunkOrder) do
      {:ok, 0}
    end,
    def default(:originalMessageID) do
      {:ok, ""}
    end,
    def default(:progress) do
      {:ok, 0}
    end,
    def default(:oldestMsgInChunkTimestampSec) do
      {:ok, 0}
    end,
    def default(:initialHistBootstrapInlinePayload) do
      {:ok, ""}
    end,
    def default(:peerDataRequestSessionID) do
      {:ok, ""}
    end,
    def default(:fullHistorySyncOnDemandRequestMetadata) do
      {:ok, nil}
    end,
    def default(:encHandle) do
      {:ok, ""}
    end,
    def default(:messageAccessStatus) do
      {:ok, nil}
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
end
