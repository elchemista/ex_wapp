# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PeerDataOperationRequestMessage do
  @moduledoc false
  defstruct peerDataOperationRequestType: nil,
            requestStickerReupload: [],
            requestURLPreview: [],
            historySyncOnDemandRequest: nil,
            placeholderMessageResendRequest: [],
            fullHistorySyncOnDemandRequest: nil,
            syncdCollectionFatalRecoveryRequest: nil,
            historySyncChunkRetryRequest: nil,
            galaxyFlowAction: nil,
            companionCanonicalUserNonceFetchRequest: nil,
            bizBroadcastInsightsContactListRequest: nil,
            bizBroadcastInsightsRefreshRequest: nil,
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
        |> encode_peerDataOperationRequestType(msg)
        |> encode_requestStickerReupload(msg)
        |> encode_requestURLPreview(msg)
        |> encode_historySyncOnDemandRequest(msg)
        |> encode_placeholderMessageResendRequest(msg)
        |> encode_fullHistorySyncOnDemandRequest(msg)
        |> encode_syncdCollectionFatalRecoveryRequest(msg)
        |> encode_historySyncChunkRetryRequest(msg)
        |> encode_galaxyFlowAction(msg)
        |> encode_companionCanonicalUserNonceFetchRequest(msg)
        |> encode_bizBroadcastInsightsContactListRequest(msg)
        |> encode_bizBroadcastInsightsRefreshRequest(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_peerDataOperationRequestType(acc, msg) do
        try do
          case msg.peerDataOperationRequestType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.peerDataOperationRequestType
                |> WAWebProtobufsE2E.PeerDataOperationRequestType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :peerDataOperationRequestType,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_requestStickerReupload(acc, msg) do
        try do
          case msg.requestStickerReupload do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x12", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:requestStickerReupload, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_requestURLPreview(acc, msg) do
        try do
          case msg.requestURLPreview do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x1A", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:requestURLPreview, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_historySyncOnDemandRequest(acc, msg) do
        try do
          case msg.historySyncOnDemandRequest do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_message(msg.historySyncOnDemandRequest)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:historySyncOnDemandRequest, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_placeholderMessageResendRequest(acc, msg) do
        try do
          case msg.placeholderMessageResendRequest do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "*", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :placeholderMessageResendRequest,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_fullHistorySyncOnDemandRequest(acc, msg) do
        try do
          case msg.fullHistorySyncOnDemandRequest do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_message(msg.fullHistorySyncOnDemandRequest)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :fullHistorySyncOnDemandRequest,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_syncdCollectionFatalRecoveryRequest(acc, msg) do
        try do
          case msg.syncdCollectionFatalRecoveryRequest do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_message(msg.syncdCollectionFatalRecoveryRequest)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :syncdCollectionFatalRecoveryRequest,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_historySyncChunkRetryRequest(acc, msg) do
        try do
          case msg.historySyncChunkRetryRequest do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.historySyncChunkRetryRequest)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :historySyncChunkRetryRequest,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_galaxyFlowAction(acc, msg) do
        try do
          case msg.galaxyFlowAction do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_message(msg.galaxyFlowAction)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:galaxyFlowAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_companionCanonicalUserNonceFetchRequest(acc, msg) do
        try do
          case msg.companionCanonicalUserNonceFetchRequest do
            nil ->
              acc

            _ ->
              [
                acc,
                "R",
                Protox.Encode.encode_message(msg.companionCanonicalUserNonceFetchRequest)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :companionCanonicalUserNonceFetchRequest,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_bizBroadcastInsightsContactListRequest(acc, msg) do
        try do
          case msg.bizBroadcastInsightsContactListRequest do
            nil ->
              acc

            _ ->
              [acc, "Z", Protox.Encode.encode_message(msg.bizBroadcastInsightsContactListRequest)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :bizBroadcastInsightsContactListRequest,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_bizBroadcastInsightsRefreshRequest(acc, msg) do
        try do
          case msg.bizBroadcastInsightsRefreshRequest do
            nil -> acc
            _ -> [acc, "b", Protox.Encode.encode_message(msg.bizBroadcastInsightsRefreshRequest)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :bizBroadcastInsightsRefreshRequest,
                      "invalid field value"
                    ),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.PeerDataOperationRequestMessage))
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
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.PeerDataOperationRequestType)

              {[peerDataOperationRequestType: value], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 requestStickerReupload:
                   msg.requestStickerReupload ++
                     [
                       WAWebProtobufsE2E.PeerDataOperationRequestMessage.RequestStickerReupload.decode!(
                         delimited
                       )
                     ]
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 requestURLPreview:
                   msg.requestURLPreview ++
                     [
                       WAWebProtobufsE2E.PeerDataOperationRequestMessage.RequestUrlPreview.decode!(
                         delimited
                       )
                     ]
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 historySyncOnDemandRequest:
                   Protox.MergeMessage.merge(
                     msg.historySyncOnDemandRequest,
                     WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncOnDemandRequest.decode!(
                       delimited
                     )
                   )
               ], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 placeholderMessageResendRequest:
                   msg.placeholderMessageResendRequest ++
                     [
                       WAWebProtobufsE2E.PeerDataOperationRequestMessage.PlaceholderMessageResendRequest.decode!(
                         delimited
                       )
                     ]
               ], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 fullHistorySyncOnDemandRequest:
                   Protox.MergeMessage.merge(
                     msg.fullHistorySyncOnDemandRequest,
                     WAWebProtobufsE2E.PeerDataOperationRequestMessage.FullHistorySyncOnDemandRequest.decode!(
                       delimited
                     )
                   )
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 syncdCollectionFatalRecoveryRequest:
                   Protox.MergeMessage.merge(
                     msg.syncdCollectionFatalRecoveryRequest,
                     WAWebProtobufsE2E.PeerDataOperationRequestMessage.SyncDCollectionFatalRecoveryRequest.decode!(
                       delimited
                     )
                   )
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 historySyncChunkRetryRequest:
                   Protox.MergeMessage.merge(
                     msg.historySyncChunkRetryRequest,
                     WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncChunkRetryRequest.decode!(
                       delimited
                     )
                   )
               ], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 galaxyFlowAction:
                   Protox.MergeMessage.merge(
                     msg.galaxyFlowAction,
                     WAWebProtobufsE2E.PeerDataOperationRequestMessage.GalaxyFlowAction.decode!(
                       delimited
                     )
                   )
               ], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 companionCanonicalUserNonceFetchRequest:
                   Protox.MergeMessage.merge(
                     msg.companionCanonicalUserNonceFetchRequest,
                     WAWebProtobufsE2E.PeerDataOperationRequestMessage.CompanionCanonicalUserNonceFetchRequest.decode!(
                       delimited
                     )
                   )
               ], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 bizBroadcastInsightsContactListRequest:
                   Protox.MergeMessage.merge(
                     msg.bizBroadcastInsightsContactListRequest,
                     WAWebProtobufsE2E.PeerDataOperationRequestMessage.BizBroadcastInsightsContactListRequest.decode!(
                       delimited
                     )
                   )
               ], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 bizBroadcastInsightsRefreshRequest:
                   Protox.MergeMessage.merge(
                     msg.bizBroadcastInsightsRefreshRequest,
                     WAWebProtobufsE2E.PeerDataOperationRequestMessage.BizBroadcastInsightsRefreshRequest.decode!(
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
        WAWebProtobufsE2E.PeerDataOperationRequestMessage,
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
          {:peerDataOperationRequestType, {:scalar, :UPLOAD_STICKER},
           {:enum, WAWebProtobufsE2E.PeerDataOperationRequestType}},
        2 =>
          {:requestStickerReupload, :unpacked,
           {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage.RequestStickerReupload}},
        3 =>
          {:requestURLPreview, :unpacked,
           {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage.RequestUrlPreview}},
        4 =>
          {:historySyncOnDemandRequest, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncOnDemandRequest}},
        5 =>
          {:placeholderMessageResendRequest, :unpacked,
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.PlaceholderMessageResendRequest}},
        6 =>
          {:fullHistorySyncOnDemandRequest, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.FullHistorySyncOnDemandRequest}},
        7 =>
          {:syncdCollectionFatalRecoveryRequest, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.SyncDCollectionFatalRecoveryRequest}},
        8 =>
          {:historySyncChunkRetryRequest, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncChunkRetryRequest}},
        9 =>
          {:galaxyFlowAction, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage.GalaxyFlowAction}},
        10 =>
          {:companionCanonicalUserNonceFetchRequest, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.CompanionCanonicalUserNonceFetchRequest}},
        11 =>
          {:bizBroadcastInsightsContactListRequest, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.BizBroadcastInsightsContactListRequest}},
        12 =>
          {:bizBroadcastInsightsRefreshRequest, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.BizBroadcastInsightsRefreshRequest}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        bizBroadcastInsightsContactListRequest:
          {11, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.BizBroadcastInsightsContactListRequest}},
        bizBroadcastInsightsRefreshRequest:
          {12, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.BizBroadcastInsightsRefreshRequest}},
        companionCanonicalUserNonceFetchRequest:
          {10, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.CompanionCanonicalUserNonceFetchRequest}},
        fullHistorySyncOnDemandRequest:
          {6, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.FullHistorySyncOnDemandRequest}},
        galaxyFlowAction:
          {9, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage.GalaxyFlowAction}},
        historySyncChunkRetryRequest:
          {8, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncChunkRetryRequest}},
        historySyncOnDemandRequest:
          {4, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncOnDemandRequest}},
        peerDataOperationRequestType:
          {1, {:scalar, :UPLOAD_STICKER}, {:enum, WAWebProtobufsE2E.PeerDataOperationRequestType}},
        placeholderMessageResendRequest:
          {5, :unpacked,
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.PlaceholderMessageResendRequest}},
        requestStickerReupload:
          {2, :unpacked,
           {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage.RequestStickerReupload}},
        requestURLPreview:
          {3, :unpacked,
           {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage.RequestUrlPreview}},
        syncdCollectionFatalRecoveryRequest:
          {7, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.PeerDataOperationRequestMessage.SyncDCollectionFatalRecoveryRequest}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "peerDataOperationRequestType",
          kind: {:scalar, :UPLOAD_STICKER},
          label: :optional,
          name: :peerDataOperationRequestType,
          tag: 1,
          type: {:enum, WAWebProtobufsE2E.PeerDataOperationRequestType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "requestStickerReupload",
          kind: :unpacked,
          label: :repeated,
          name: :requestStickerReupload,
          tag: 2,
          type:
            {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage.RequestStickerReupload}
        },
        %{
          __struct__: Protox.Field,
          json_name: "requestURLPreview",
          kind: :unpacked,
          label: :repeated,
          name: :requestURLPreview,
          tag: 3,
          type: {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage.RequestUrlPreview}
        },
        %{
          __struct__: Protox.Field,
          json_name: "historySyncOnDemandRequest",
          kind: {:scalar, nil},
          label: :optional,
          name: :historySyncOnDemandRequest,
          tag: 4,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncOnDemandRequest}
        },
        %{
          __struct__: Protox.Field,
          json_name: "placeholderMessageResendRequest",
          kind: :unpacked,
          label: :repeated,
          name: :placeholderMessageResendRequest,
          tag: 5,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestMessage.PlaceholderMessageResendRequest}
        },
        %{
          __struct__: Protox.Field,
          json_name: "fullHistorySyncOnDemandRequest",
          kind: {:scalar, nil},
          label: :optional,
          name: :fullHistorySyncOnDemandRequest,
          tag: 6,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestMessage.FullHistorySyncOnDemandRequest}
        },
        %{
          __struct__: Protox.Field,
          json_name: "syncdCollectionFatalRecoveryRequest",
          kind: {:scalar, nil},
          label: :optional,
          name: :syncdCollectionFatalRecoveryRequest,
          tag: 7,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestMessage.SyncDCollectionFatalRecoveryRequest}
        },
        %{
          __struct__: Protox.Field,
          json_name: "historySyncChunkRetryRequest",
          kind: {:scalar, nil},
          label: :optional,
          name: :historySyncChunkRetryRequest,
          tag: 8,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncChunkRetryRequest}
        },
        %{
          __struct__: Protox.Field,
          json_name: "galaxyFlowAction",
          kind: {:scalar, nil},
          label: :optional,
          name: :galaxyFlowAction,
          tag: 9,
          type: {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage.GalaxyFlowAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "companionCanonicalUserNonceFetchRequest",
          kind: {:scalar, nil},
          label: :optional,
          name: :companionCanonicalUserNonceFetchRequest,
          tag: 10,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestMessage.CompanionCanonicalUserNonceFetchRequest}
        },
        %{
          __struct__: Protox.Field,
          json_name: "bizBroadcastInsightsContactListRequest",
          kind: {:scalar, nil},
          label: :optional,
          name: :bizBroadcastInsightsContactListRequest,
          tag: 11,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestMessage.BizBroadcastInsightsContactListRequest}
        },
        %{
          __struct__: Protox.Field,
          json_name: "bizBroadcastInsightsRefreshRequest",
          kind: {:scalar, nil},
          label: :optional,
          name: :bizBroadcastInsightsRefreshRequest,
          tag: 12,
          type:
            {:message,
             WAWebProtobufsE2E.PeerDataOperationRequestMessage.BizBroadcastInsightsRefreshRequest}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:peerDataOperationRequestType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "peerDataOperationRequestType",
             kind: {:scalar, :UPLOAD_STICKER},
             label: :optional,
             name: :peerDataOperationRequestType,
             tag: 1,
             type: {:enum, WAWebProtobufsE2E.PeerDataOperationRequestType}
           }}
        end

        def field_def("peerDataOperationRequestType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "peerDataOperationRequestType",
             kind: {:scalar, :UPLOAD_STICKER},
             label: :optional,
             name: :peerDataOperationRequestType,
             tag: 1,
             type: {:enum, WAWebProtobufsE2E.PeerDataOperationRequestType}
           }}
        end

        []
      ),
      (
        def field_def(:requestStickerReupload) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestStickerReupload",
             kind: :unpacked,
             label: :repeated,
             name: :requestStickerReupload,
             tag: 2,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.RequestStickerReupload}
           }}
        end

        def field_def("requestStickerReupload") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestStickerReupload",
             kind: :unpacked,
             label: :repeated,
             name: :requestStickerReupload,
             tag: 2,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.RequestStickerReupload}
           }}
        end

        []
      ),
      (
        def field_def(:requestURLPreview) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestURLPreview",
             kind: :unpacked,
             label: :repeated,
             name: :requestURLPreview,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage.RequestUrlPreview}
           }}
        end

        def field_def("requestURLPreview") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestURLPreview",
             kind: :unpacked,
             label: :repeated,
             name: :requestURLPreview,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage.RequestUrlPreview}
           }}
        end

        []
      ),
      (
        def field_def(:historySyncOnDemandRequest) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "historySyncOnDemandRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :historySyncOnDemandRequest,
             tag: 4,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncOnDemandRequest}
           }}
        end

        def field_def("historySyncOnDemandRequest") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "historySyncOnDemandRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :historySyncOnDemandRequest,
             tag: 4,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncOnDemandRequest}
           }}
        end

        []
      ),
      (
        def field_def(:placeholderMessageResendRequest) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "placeholderMessageResendRequest",
             kind: :unpacked,
             label: :repeated,
             name: :placeholderMessageResendRequest,
             tag: 5,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.PlaceholderMessageResendRequest}
           }}
        end

        def field_def("placeholderMessageResendRequest") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "placeholderMessageResendRequest",
             kind: :unpacked,
             label: :repeated,
             name: :placeholderMessageResendRequest,
             tag: 5,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.PlaceholderMessageResendRequest}
           }}
        end

        []
      ),
      (
        def field_def(:fullHistorySyncOnDemandRequest) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fullHistorySyncOnDemandRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :fullHistorySyncOnDemandRequest,
             tag: 6,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.FullHistorySyncOnDemandRequest}
           }}
        end

        def field_def("fullHistorySyncOnDemandRequest") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fullHistorySyncOnDemandRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :fullHistorySyncOnDemandRequest,
             tag: 6,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.FullHistorySyncOnDemandRequest}
           }}
        end

        []
      ),
      (
        def field_def(:syncdCollectionFatalRecoveryRequest) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "syncdCollectionFatalRecoveryRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :syncdCollectionFatalRecoveryRequest,
             tag: 7,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.SyncDCollectionFatalRecoveryRequest}
           }}
        end

        def field_def("syncdCollectionFatalRecoveryRequest") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "syncdCollectionFatalRecoveryRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :syncdCollectionFatalRecoveryRequest,
             tag: 7,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.SyncDCollectionFatalRecoveryRequest}
           }}
        end

        []
      ),
      (
        def field_def(:historySyncChunkRetryRequest) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "historySyncChunkRetryRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :historySyncChunkRetryRequest,
             tag: 8,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncChunkRetryRequest}
           }}
        end

        def field_def("historySyncChunkRetryRequest") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "historySyncChunkRetryRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :historySyncChunkRetryRequest,
             tag: 8,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.HistorySyncChunkRetryRequest}
           }}
        end

        []
      ),
      (
        def field_def(:galaxyFlowAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "galaxyFlowAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :galaxyFlowAction,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage.GalaxyFlowAction}
           }}
        end

        def field_def("galaxyFlowAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "galaxyFlowAction",
             kind: {:scalar, nil},
             label: :optional,
             name: :galaxyFlowAction,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.PeerDataOperationRequestMessage.GalaxyFlowAction}
           }}
        end

        []
      ),
      (
        def field_def(:companionCanonicalUserNonceFetchRequest) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "companionCanonicalUserNonceFetchRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :companionCanonicalUserNonceFetchRequest,
             tag: 10,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.CompanionCanonicalUserNonceFetchRequest}
           }}
        end

        def field_def("companionCanonicalUserNonceFetchRequest") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "companionCanonicalUserNonceFetchRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :companionCanonicalUserNonceFetchRequest,
             tag: 10,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.CompanionCanonicalUserNonceFetchRequest}
           }}
        end

        []
      ),
      (
        def field_def(:bizBroadcastInsightsContactListRequest) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bizBroadcastInsightsContactListRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :bizBroadcastInsightsContactListRequest,
             tag: 11,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.BizBroadcastInsightsContactListRequest}
           }}
        end

        def field_def("bizBroadcastInsightsContactListRequest") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bizBroadcastInsightsContactListRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :bizBroadcastInsightsContactListRequest,
             tag: 11,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.BizBroadcastInsightsContactListRequest}
           }}
        end

        []
      ),
      (
        def field_def(:bizBroadcastInsightsRefreshRequest) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bizBroadcastInsightsRefreshRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :bizBroadcastInsightsRefreshRequest,
             tag: 12,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.BizBroadcastInsightsRefreshRequest}
           }}
        end

        def field_def("bizBroadcastInsightsRefreshRequest") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bizBroadcastInsightsRefreshRequest",
             kind: {:scalar, nil},
             label: :optional,
             name: :bizBroadcastInsightsRefreshRequest,
             tag: 12,
             type:
               {:message,
                WAWebProtobufsE2E.PeerDataOperationRequestMessage.BizBroadcastInsightsRefreshRequest}
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
    def default(:peerDataOperationRequestType) do
      {:ok, :UPLOAD_STICKER}
    end,
    def default(:requestStickerReupload) do
      {:error, :no_default_value}
    end,
    def default(:requestURLPreview) do
      {:error, :no_default_value}
    end,
    def default(:historySyncOnDemandRequest) do
      {:ok, nil}
    end,
    def default(:placeholderMessageResendRequest) do
      {:error, :no_default_value}
    end,
    def default(:fullHistorySyncOnDemandRequest) do
      {:ok, nil}
    end,
    def default(:syncdCollectionFatalRecoveryRequest) do
      {:ok, nil}
    end,
    def default(:historySyncChunkRetryRequest) do
      {:ok, nil}
    end,
    def default(:galaxyFlowAction) do
      {:ok, nil}
    end,
    def default(:companionCanonicalUserNonceFetchRequest) do
      {:ok, nil}
    end,
    def default(:bizBroadcastInsightsContactListRequest) do
      {:ok, nil}
    end,
    def default(:bizBroadcastInsightsRefreshRequest) do
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

  @type t :: %__MODULE__{}
end
