# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult do
  @moduledoc false
  defstruct mediaUploadResult: nil,
            stickerMessage: nil,
            linkPreviewResponse: nil,
            placeholderMessageResendResponse: nil,
            waffleNonceFetchRequestResponse: nil,
            fullHistorySyncOnDemandRequestResponse: nil,
            companionMetaNonceFetchRequestResponse: nil,
            syncdSnapshotFatalRecoveryResponse: nil,
            companionCanonicalUserNonceFetchRequestResponse: nil,
            historySyncChunkRetryResponse: nil,
            flowResponsesCsvBundle: nil,
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
        |> encode_mediaUploadResult(msg)
        |> encode_stickerMessage(msg)
        |> encode_linkPreviewResponse(msg)
        |> encode_placeholderMessageResendResponse(msg)
        |> encode_waffleNonceFetchRequestResponse(msg)
        |> encode_fullHistorySyncOnDemandRequestResponse(msg)
        |> encode_companionMetaNonceFetchRequestResponse(msg)
        |> encode_syncdSnapshotFatalRecoveryResponse(msg)
        |> encode_companionCanonicalUserNonceFetchRequestResponse(msg)
        |> encode_historySyncChunkRetryResponse(msg)
        |> encode_flowResponsesCsvBundle(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_mediaUploadResult(acc, msg) do
        try do
          case msg.mediaUploadResult do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.mediaUploadResult
                |> WAMmsRetry.MediaRetryNotification.ResultType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaUploadResult, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_stickerMessage(acc, msg) do
        try do
          case msg.stickerMessage do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_message(msg.stickerMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:stickerMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_linkPreviewResponse(acc, msg) do
        try do
          case msg.linkPreviewResponse do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_message(msg.linkPreviewResponse)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:linkPreviewResponse, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_placeholderMessageResendResponse(acc, msg) do
        try do
          case msg.placeholderMessageResendResponse do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_message(msg.placeholderMessageResendResponse)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :placeholderMessageResendResponse,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_waffleNonceFetchRequestResponse(acc, msg) do
        try do
          case msg.waffleNonceFetchRequestResponse do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_message(msg.waffleNonceFetchRequestResponse)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :waffleNonceFetchRequestResponse,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_fullHistorySyncOnDemandRequestResponse(acc, msg) do
        try do
          case msg.fullHistorySyncOnDemandRequestResponse do
            nil ->
              acc

            _ ->
              [acc, "2", Protox.Encode.encode_message(msg.fullHistorySyncOnDemandRequestResponse)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :fullHistorySyncOnDemandRequestResponse,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_companionMetaNonceFetchRequestResponse(acc, msg) do
        try do
          case msg.companionMetaNonceFetchRequestResponse do
            nil ->
              acc

            _ ->
              [acc, ":", Protox.Encode.encode_message(msg.companionMetaNonceFetchRequestResponse)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :companionMetaNonceFetchRequestResponse,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_syncdSnapshotFatalRecoveryResponse(acc, msg) do
        try do
          case msg.syncdSnapshotFatalRecoveryResponse do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.syncdSnapshotFatalRecoveryResponse)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :syncdSnapshotFatalRecoveryResponse,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_companionCanonicalUserNonceFetchRequestResponse(acc, msg) do
        try do
          case msg.companionCanonicalUserNonceFetchRequestResponse do
            nil ->
              acc

            _ ->
              [
                acc,
                "J",
                Protox.Encode.encode_message(msg.companionCanonicalUserNonceFetchRequestResponse)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :companionCanonicalUserNonceFetchRequestResponse,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_historySyncChunkRetryResponse(acc, msg) do
        try do
          case msg.historySyncChunkRetryResponse do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_message(msg.historySyncChunkRetryResponse)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :historySyncChunkRetryResponse,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_flowResponsesCsvBundle(acc, msg) do
        try do
          case msg.flowResponsesCsvBundle do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_message(msg.flowResponsesCsvBundle)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:flowResponsesCsvBundle, "invalid field value"),
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
          parse_key_value(
            bytes,
            struct(
              WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult
            )
          )
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
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAMmsRetry.MediaRetryNotification.ResultType)

              {[mediaUploadResult: value], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 stickerMessage:
                   Protox.MergeMessage.merge(
                     msg.stickerMessage,
                     WAWebProtobufsE2E.StickerMessage.decode!(delimited)
                   )
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 linkPreviewResponse:
                   Protox.MergeMessage.merge(
                     msg.linkPreviewResponse,
                     WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.LinkPreviewResponse.decode!(
                       delimited
                     )
                   )
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 placeholderMessageResendResponse:
                   Protox.MergeMessage.merge(
                     msg.placeholderMessageResendResponse,
                     WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.PlaceholderMessageResendResponse.decode!(
                       delimited
                     )
                   )
               ], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 waffleNonceFetchRequestResponse:
                   Protox.MergeMessage.merge(
                     msg.waffleNonceFetchRequestResponse,
                     WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.WaffleNonceFetchResponse.decode!(
                       delimited
                     )
                   )
               ], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 fullHistorySyncOnDemandRequestResponse:
                   Protox.MergeMessage.merge(
                     msg.fullHistorySyncOnDemandRequestResponse,
                     WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FullHistorySyncOnDemandRequestResponse.decode!(
                       delimited
                     )
                   )
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 companionMetaNonceFetchRequestResponse:
                   Protox.MergeMessage.merge(
                     msg.companionMetaNonceFetchRequestResponse,
                     WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.CompanionMetaNonceFetchResponse.decode!(
                       delimited
                     )
                   )
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 syncdSnapshotFatalRecoveryResponse:
                   Protox.MergeMessage.merge(
                     msg.syncdSnapshotFatalRecoveryResponse,
                     WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.SyncDSnapshotFatalRecoveryResponse.decode!(
                       delimited
                     )
                   )
               ], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 companionCanonicalUserNonceFetchRequestResponse:
                   Protox.MergeMessage.merge(
                     msg.companionCanonicalUserNonceFetchRequestResponse,
                     WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.CompanionCanonicalUserNonceFetchResponse.decode!(
                       delimited
                     )
                   )
               ], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 historySyncChunkRetryResponse:
                   Protox.MergeMessage.merge(
                     msg.historySyncChunkRetryResponse,
                     WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponse.decode!(
                       delimited
                     )
                   )
               ], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 flowResponsesCsvBundle:
                   Protox.MergeMessage.merge(
                     msg.flowResponsesCsvBundle,
                     WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FlowResponsesCsvBundle.decode!(
                       delimited
                     )
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
        WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult,
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
        1 =>
          {:mediaUploadResult, {:scalar, :GENERAL_ERROR},
           {:enum, WAMmsRetry.MediaRetryNotification.ResultType}},
        2 => {:stickerMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.StickerMessage}},
        3 =>
          {:linkPreviewResponse, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.LinkPreviewResponse}},
        4 =>
          {:placeholderMessageResendResponse, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.PlaceholderMessageResendResponse}},
        5 =>
          {:waffleNonceFetchRequestResponse, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.WaffleNonceFetchResponse}},
        6 =>
          {:fullHistorySyncOnDemandRequestResponse, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FullHistorySyncOnDemandRequestResponse}},
        7 =>
          {:companionMetaNonceFetchRequestResponse, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.CompanionMetaNonceFetchResponse}},
        8 =>
          {:syncdSnapshotFatalRecoveryResponse, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.SyncDSnapshotFatalRecoveryResponse}},
        9 =>
          {:companionCanonicalUserNonceFetchRequestResponse, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.CompanionCanonicalUserNonceFetchResponse}},
        10 =>
          {:historySyncChunkRetryResponse, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponse}},
        11 =>
          {:flowResponsesCsvBundle, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FlowResponsesCsvBundle}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        companionCanonicalUserNonceFetchRequestResponse:
          {9, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.CompanionCanonicalUserNonceFetchResponse}},
        companionMetaNonceFetchRequestResponse:
          {7, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.CompanionMetaNonceFetchResponse}},
        flowResponsesCsvBundle:
          {11, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FlowResponsesCsvBundle}},
        fullHistorySyncOnDemandRequestResponse:
          {6, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FullHistorySyncOnDemandRequestResponse}},
        historySyncChunkRetryResponse:
          {10, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponse}},
        linkPreviewResponse:
          {3, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.LinkPreviewResponse}},
        mediaUploadResult:
          {1, {:scalar, :GENERAL_ERROR}, {:enum, WAMmsRetry.MediaRetryNotification.ResultType}},
        placeholderMessageResendResponse:
          {4, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.PlaceholderMessageResendResponse}},
        stickerMessage: {2, {:scalar, nil}, {:message, WAWebProtobufsE2E.StickerMessage}},
        syncdSnapshotFatalRecoveryResponse:
          {8, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.SyncDSnapshotFatalRecoveryResponse}},
        waffleNonceFetchRequestResponse:
          {5, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.WaffleNonceFetchResponse}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "mediaUploadResult",
          kind: {:scalar, :GENERAL_ERROR},
          label: :optional,
          name: :mediaUploadResult,
          tag: 1,
          type: {:enum, WAMmsRetry.MediaRetryNotification.ResultType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "stickerMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :stickerMessage,
          tag: 2,
          type: {:message, WAWebProtobufsE2E.StickerMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "linkPreviewResponse",
          kind: {:scalar, nil},
          label: :optional,
          name: :linkPreviewResponse,
          tag: 3,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.LinkPreviewResponse}
        },
        %{
          __struct__: Protox.Field,
          json_name: "placeholderMessageResendResponse",
          kind: {:scalar, nil},
          label: :optional,
          name: :placeholderMessageResendResponse,
          tag: 4,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.PlaceholderMessageResendResponse}
        },
        %{
          __struct__: Protox.Field,
          json_name: "waffleNonceFetchRequestResponse",
          kind: {:scalar, nil},
          label: :optional,
          name: :waffleNonceFetchRequestResponse,
          tag: 5,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.WaffleNonceFetchResponse}
        },
        %{
          __struct__: Protox.Field,
          json_name: "fullHistorySyncOnDemandRequestResponse",
          kind: {:scalar, nil},
          label: :optional,
          name: :fullHistorySyncOnDemandRequestResponse,
          tag: 6,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FullHistorySyncOnDemandRequestResponse}
        },
        %{
          __struct__: Protox.Field,
          json_name: "companionMetaNonceFetchRequestResponse",
          kind: {:scalar, nil},
          label: :optional,
          name: :companionMetaNonceFetchRequestResponse,
          tag: 7,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.CompanionMetaNonceFetchResponse}
        },
        %{
          __struct__: Protox.Field,
          json_name: "syncdSnapshotFatalRecoveryResponse",
          kind: {:scalar, nil},
          label: :optional,
          name: :syncdSnapshotFatalRecoveryResponse,
          tag: 8,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.SyncDSnapshotFatalRecoveryResponse}
        },
        %{
          __struct__: Protox.Field,
          json_name: "companionCanonicalUserNonceFetchRequestResponse",
          kind: {:scalar, nil},
          label: :optional,
          name: :companionCanonicalUserNonceFetchRequestResponse,
          tag: 9,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.CompanionCanonicalUserNonceFetchResponse}
        },
        %{
          __struct__: Protox.Field,
          json_name: "historySyncChunkRetryResponse",
          kind: {:scalar, nil},
          label: :optional,
          name: :historySyncChunkRetryResponse,
          tag: 10,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponse}
        },
        %{
          __struct__: Protox.Field,
          json_name: "flowResponsesCsvBundle",
          kind: {:scalar, nil},
          label: :optional,
          name: :flowResponsesCsvBundle,
          tag: 11,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FlowResponsesCsvBundle}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:mediaUploadResult) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaUploadResult",
             kind: {:scalar, :GENERAL_ERROR},
             label: :optional,
             name: :mediaUploadResult,
             tag: 1,
             type: {:enum, WAMmsRetry.MediaRetryNotification.ResultType}
           }}
        end

        def field_def("mediaUploadResult") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaUploadResult",
             kind: {:scalar, :GENERAL_ERROR},
             label: :optional,
             name: :mediaUploadResult,
             tag: 1,
             type: {:enum, WAMmsRetry.MediaRetryNotification.ResultType}
           }}
        end

        []
      ),
      (
        def field_def(:stickerMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :stickerMessage,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.StickerMessage}
           }}
        end

        def field_def("stickerMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stickerMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :stickerMessage,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.StickerMessage}
           }}
        end

        []
      ),
      (
        def field_def(:linkPreviewResponse) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "linkPreviewResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :linkPreviewResponse,
             tag: 3,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.LinkPreviewResponse}
           }}
        end

        def field_def("linkPreviewResponse") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "linkPreviewResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :linkPreviewResponse,
             tag: 3,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.LinkPreviewResponse}
           }}
        end

        []
      ),
      (
        def field_def(:placeholderMessageResendResponse) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "placeholderMessageResendResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :placeholderMessageResendResponse,
             tag: 4,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.PlaceholderMessageResendResponse}
           }}
        end

        def field_def("placeholderMessageResendResponse") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "placeholderMessageResendResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :placeholderMessageResendResponse,
             tag: 4,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.PlaceholderMessageResendResponse}
           }}
        end

        []
      ),
      (
        def field_def(:waffleNonceFetchRequestResponse) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "waffleNonceFetchRequestResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :waffleNonceFetchRequestResponse,
             tag: 5,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.WaffleNonceFetchResponse}
           }}
        end

        def field_def("waffleNonceFetchRequestResponse") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "waffleNonceFetchRequestResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :waffleNonceFetchRequestResponse,
             tag: 5,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.WaffleNonceFetchResponse}
           }}
        end

        []
      ),
      (
        def field_def(:fullHistorySyncOnDemandRequestResponse) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fullHistorySyncOnDemandRequestResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :fullHistorySyncOnDemandRequestResponse,
             tag: 6,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FullHistorySyncOnDemandRequestResponse}
           }}
        end

        def field_def("fullHistorySyncOnDemandRequestResponse") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fullHistorySyncOnDemandRequestResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :fullHistorySyncOnDemandRequestResponse,
             tag: 6,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FullHistorySyncOnDemandRequestResponse}
           }}
        end

        []
      ),
      (
        def field_def(:companionMetaNonceFetchRequestResponse) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "companionMetaNonceFetchRequestResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :companionMetaNonceFetchRequestResponse,
             tag: 7,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.CompanionMetaNonceFetchResponse}
           }}
        end

        def field_def("companionMetaNonceFetchRequestResponse") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "companionMetaNonceFetchRequestResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :companionMetaNonceFetchRequestResponse,
             tag: 7,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.CompanionMetaNonceFetchResponse}
           }}
        end

        []
      ),
      (
        def field_def(:syncdSnapshotFatalRecoveryResponse) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "syncdSnapshotFatalRecoveryResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :syncdSnapshotFatalRecoveryResponse,
             tag: 8,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.SyncDSnapshotFatalRecoveryResponse}
           }}
        end

        def field_def("syncdSnapshotFatalRecoveryResponse") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "syncdSnapshotFatalRecoveryResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :syncdSnapshotFatalRecoveryResponse,
             tag: 8,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.SyncDSnapshotFatalRecoveryResponse}
           }}
        end

        []
      ),
      (
        def field_def(:companionCanonicalUserNonceFetchRequestResponse) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "companionCanonicalUserNonceFetchRequestResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :companionCanonicalUserNonceFetchRequestResponse,
             tag: 9,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.CompanionCanonicalUserNonceFetchResponse}
           }}
        end

        def field_def("companionCanonicalUserNonceFetchRequestResponse") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "companionCanonicalUserNonceFetchRequestResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :companionCanonicalUserNonceFetchRequestResponse,
             tag: 9,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.CompanionCanonicalUserNonceFetchResponse}
           }}
        end

        []
      ),
      (
        def field_def(:historySyncChunkRetryResponse) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "historySyncChunkRetryResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :historySyncChunkRetryResponse,
             tag: 10,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponse}
           }}
        end

        def field_def("historySyncChunkRetryResponse") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "historySyncChunkRetryResponse",
             kind: {:scalar, nil},
             label: :optional,
             name: :historySyncChunkRetryResponse,
             tag: 10,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.HistorySyncChunkRetryResponse}
           }}
        end

        []
      ),
      (
        def field_def(:flowResponsesCsvBundle) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "flowResponsesCsvBundle",
             kind: {:scalar, nil},
             label: :optional,
             name: :flowResponsesCsvBundle,
             tag: 11,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FlowResponsesCsvBundle}
           }}
        end

        def field_def("flowResponsesCsvBundle") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "flowResponsesCsvBundle",
             kind: {:scalar, nil},
             label: :optional,
             name: :flowResponsesCsvBundle,
             tag: 11,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestResponseMessage.PeerDataOperationResult.FlowResponsesCsvBundle}
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
    def default(:mediaUploadResult) do
      {:ok, :GENERAL_ERROR}
    end,
    def default(:stickerMessage) do
      {:ok, nil}
    end,
    def default(:linkPreviewResponse) do
      {:ok, nil}
    end,
    def default(:placeholderMessageResendResponse) do
      {:ok, nil}
    end,
    def default(:waffleNonceFetchRequestResponse) do
      {:ok, nil}
    end,
    def default(:fullHistorySyncOnDemandRequestResponse) do
      {:ok, nil}
    end,
    def default(:companionMetaNonceFetchRequestResponse) do
      {:ok, nil}
    end,
    def default(:syncdSnapshotFatalRecoveryResponse) do
      {:ok, nil}
    end,
    def default(:companionCanonicalUserNonceFetchRequestResponse) do
      {:ok, nil}
    end,
    def default(:historySyncChunkRetryResponse) do
      {:ok, nil}
    end,
    def default(:flowResponsesCsvBundle) do
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
