# credo:disable-for-this-file
defmodule WACompanionReg.DeviceProps.HistorySyncConfig do
  @moduledoc false
  defstruct fullSyncDaysLimit: nil,
            fullSyncSizeMbLimit: nil,
            storageQuotaMb: nil,
            inlineInitialPayloadInE2EeMsg: nil,
            recentSyncDaysLimit: nil,
            supportCallLogHistory: nil,
            supportBotUserAgentChatHistory: nil,
            supportCagReactionsAndPolls: nil,
            supportBizHostedMsg: nil,
            supportRecentSyncChunkMessageCountTuning: nil,
            supportHostedGroupMsg: nil,
            supportFbidBotChatHistory: nil,
            supportAddOnHistorySyncMigration: nil,
            supportMessageAssociation: nil,
            supportGroupHistory: nil,
            onDemandReady: nil,
            supportGuestChat: nil,
            completeOnDemandReady: nil,
            thumbnailSyncDaysLimit: nil,
            initialSyncMaxMessagesPerChat: nil,
            supportManusHistory: nil,
            supportHatchHistory: nil,
            supportedBotChannelFbids: [],
            supportInlineContacts: nil,
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
        |> encode_fullSyncDaysLimit(msg)
        |> encode_fullSyncSizeMbLimit(msg)
        |> encode_storageQuotaMb(msg)
        |> encode_inlineInitialPayloadInE2EeMsg(msg)
        |> encode_recentSyncDaysLimit(msg)
        |> encode_supportCallLogHistory(msg)
        |> encode_supportBotUserAgentChatHistory(msg)
        |> encode_supportCagReactionsAndPolls(msg)
        |> encode_supportBizHostedMsg(msg)
        |> encode_supportRecentSyncChunkMessageCountTuning(msg)
        |> encode_supportHostedGroupMsg(msg)
        |> encode_supportFbidBotChatHistory(msg)
        |> encode_supportAddOnHistorySyncMigration(msg)
        |> encode_supportMessageAssociation(msg)
        |> encode_supportGroupHistory(msg)
        |> encode_onDemandReady(msg)
        |> encode_supportGuestChat(msg)
        |> encode_completeOnDemandReady(msg)
        |> encode_thumbnailSyncDaysLimit(msg)
        |> encode_initialSyncMaxMessagesPerChat(msg)
        |> encode_supportManusHistory(msg)
        |> encode_supportHatchHistory(msg)
        |> encode_supportedBotChannelFbids(msg)
        |> encode_supportInlineContacts(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_fullSyncDaysLimit(acc, msg) do
        try do
          case msg.fullSyncDaysLimit do
            nil -> acc
            _ -> [acc, "\b", Protox.Encode.encode_uint32(msg.fullSyncDaysLimit)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fullSyncDaysLimit, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_fullSyncSizeMbLimit(acc, msg) do
        try do
          case msg.fullSyncSizeMbLimit do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_uint32(msg.fullSyncSizeMbLimit)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fullSyncSizeMbLimit, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_storageQuotaMb(acc, msg) do
        try do
          case msg.storageQuotaMb do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_uint32(msg.storageQuotaMb)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:storageQuotaMb, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_inlineInitialPayloadInE2EeMsg(acc, msg) do
        try do
          case msg.inlineInitialPayloadInE2EeMsg do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_bool(msg.inlineInitialPayloadInE2EeMsg)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :inlineInitialPayloadInE2EeMsg,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_recentSyncDaysLimit(acc, msg) do
        try do
          case msg.recentSyncDaysLimit do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_uint32(msg.recentSyncDaysLimit)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:recentSyncDaysLimit, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportCallLogHistory(acc, msg) do
        try do
          case msg.supportCallLogHistory do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_bool(msg.supportCallLogHistory)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportCallLogHistory, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportBotUserAgentChatHistory(acc, msg) do
        try do
          case msg.supportBotUserAgentChatHistory do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_bool(msg.supportBotUserAgentChatHistory)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :supportBotUserAgentChatHistory,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_supportCagReactionsAndPolls(acc, msg) do
        try do
          case msg.supportCagReactionsAndPolls do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_bool(msg.supportCagReactionsAndPolls)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportCagReactionsAndPolls, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportBizHostedMsg(acc, msg) do
        try do
          case msg.supportBizHostedMsg do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_bool(msg.supportBizHostedMsg)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportBizHostedMsg, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportRecentSyncChunkMessageCountTuning(acc, msg) do
        try do
          case msg.supportRecentSyncChunkMessageCountTuning do
            nil ->
              acc

            _ ->
              [acc, "P", Protox.Encode.encode_bool(msg.supportRecentSyncChunkMessageCountTuning)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :supportRecentSyncChunkMessageCountTuning,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_supportHostedGroupMsg(acc, msg) do
        try do
          case msg.supportHostedGroupMsg do
            nil -> acc
            _ -> [acc, "X", Protox.Encode.encode_bool(msg.supportHostedGroupMsg)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportHostedGroupMsg, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportFbidBotChatHistory(acc, msg) do
        try do
          case msg.supportFbidBotChatHistory do
            nil -> acc
            _ -> [acc, "`", Protox.Encode.encode_bool(msg.supportFbidBotChatHistory)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportFbidBotChatHistory, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportAddOnHistorySyncMigration(acc, msg) do
        try do
          case msg.supportAddOnHistorySyncMigration do
            nil -> acc
            _ -> [acc, "h", Protox.Encode.encode_bool(msg.supportAddOnHistorySyncMigration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :supportAddOnHistorySyncMigration,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_supportMessageAssociation(acc, msg) do
        try do
          case msg.supportMessageAssociation do
            nil -> acc
            _ -> [acc, "p", Protox.Encode.encode_bool(msg.supportMessageAssociation)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportMessageAssociation, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportGroupHistory(acc, msg) do
        try do
          case msg.supportGroupHistory do
            nil -> acc
            _ -> [acc, "x", Protox.Encode.encode_bool(msg.supportGroupHistory)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportGroupHistory, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_onDemandReady(acc, msg) do
        try do
          case msg.onDemandReady do
            nil -> acc
            _ -> [acc, "\x80\x01", Protox.Encode.encode_bool(msg.onDemandReady)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:onDemandReady, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportGuestChat(acc, msg) do
        try do
          case msg.supportGuestChat do
            nil -> acc
            _ -> [acc, "\x88\x01", Protox.Encode.encode_bool(msg.supportGuestChat)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportGuestChat, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_completeOnDemandReady(acc, msg) do
        try do
          case msg.completeOnDemandReady do
            nil -> acc
            _ -> [acc, "\x90\x01", Protox.Encode.encode_bool(msg.completeOnDemandReady)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:completeOnDemandReady, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailSyncDaysLimit(acc, msg) do
        try do
          case msg.thumbnailSyncDaysLimit do
            nil -> acc
            _ -> [acc, "\x98\x01", Protox.Encode.encode_uint32(msg.thumbnailSyncDaysLimit)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailSyncDaysLimit, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_initialSyncMaxMessagesPerChat(acc, msg) do
        try do
          case msg.initialSyncMaxMessagesPerChat do
            nil -> acc
            _ -> [acc, "\xA0\x01", Protox.Encode.encode_uint32(msg.initialSyncMaxMessagesPerChat)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :initialSyncMaxMessagesPerChat,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_supportManusHistory(acc, msg) do
        try do
          case msg.supportManusHistory do
            nil -> acc
            _ -> [acc, "\xA8\x01", Protox.Encode.encode_bool(msg.supportManusHistory)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportManusHistory, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportHatchHistory(acc, msg) do
        try do
          case msg.supportHatchHistory do
            nil -> acc
            _ -> [acc, "\xB0\x01", Protox.Encode.encode_bool(msg.supportHatchHistory)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportHatchHistory, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportedBotChannelFbids(acc, msg) do
        try do
          case msg.supportedBotChannelFbids do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xBA\x01", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportedBotChannelFbids, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportInlineContacts(acc, msg) do
        try do
          case msg.supportInlineContacts do
            nil -> acc
            _ -> [acc, "\xC0\x01", Protox.Encode.encode_bool(msg.supportInlineContacts)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportInlineContacts, "invalid field value"),
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
          parse_key_value(bytes, struct(WACompanionReg.DeviceProps.HistorySyncConfig))
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
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[fullSyncDaysLimit: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[fullSyncSizeMbLimit: value], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[storageQuotaMb: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[inlineInitialPayloadInE2EeMsg: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[recentSyncDaysLimit: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportCallLogHistory: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportBotUserAgentChatHistory: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportCagReactionsAndPolls: value], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportBizHostedMsg: value], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportRecentSyncChunkMessageCountTuning: value], rest}

            {11, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportHostedGroupMsg: value], rest}

            {12, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportFbidBotChatHistory: value], rest}

            {13, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportAddOnHistorySyncMigration: value], rest}

            {14, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportMessageAssociation: value], rest}

            {15, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportGroupHistory: value], rest}

            {16, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[onDemandReady: value], rest}

            {17, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportGuestChat: value], rest}

            {18, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[completeOnDemandReady: value], rest}

            {19, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[thumbnailSyncDaysLimit: value], rest}

            {20, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[initialSyncMaxMessagesPerChat: value], rest}

            {21, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportManusHistory: value], rest}

            {22, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportHatchHistory: value], rest}

            {23, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 supportedBotChannelFbids:
                   msg.supportedBotChannelFbids ++ [Protox.Decode.validate_string!(delimited)]
               ], rest}

            {24, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[supportInlineContacts: value], rest}

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
        WACompanionReg.DeviceProps.HistorySyncConfig,
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
        1 => {:fullSyncDaysLimit, {:scalar, 0}, :uint32},
        2 => {:fullSyncSizeMbLimit, {:scalar, 0}, :uint32},
        3 => {:storageQuotaMb, {:scalar, 0}, :uint32},
        4 => {:inlineInitialPayloadInE2EeMsg, {:scalar, false}, :bool},
        5 => {:recentSyncDaysLimit, {:scalar, 0}, :uint32},
        6 => {:supportCallLogHistory, {:scalar, false}, :bool},
        7 => {:supportBotUserAgentChatHistory, {:scalar, false}, :bool},
        8 => {:supportCagReactionsAndPolls, {:scalar, false}, :bool},
        9 => {:supportBizHostedMsg, {:scalar, false}, :bool},
        10 => {:supportRecentSyncChunkMessageCountTuning, {:scalar, false}, :bool},
        11 => {:supportHostedGroupMsg, {:scalar, false}, :bool},
        12 => {:supportFbidBotChatHistory, {:scalar, false}, :bool},
        13 => {:supportAddOnHistorySyncMigration, {:scalar, false}, :bool},
        14 => {:supportMessageAssociation, {:scalar, false}, :bool},
        15 => {:supportGroupHistory, {:scalar, false}, :bool},
        16 => {:onDemandReady, {:scalar, false}, :bool},
        17 => {:supportGuestChat, {:scalar, false}, :bool},
        18 => {:completeOnDemandReady, {:scalar, false}, :bool},
        19 => {:thumbnailSyncDaysLimit, {:scalar, 0}, :uint32},
        20 => {:initialSyncMaxMessagesPerChat, {:scalar, 0}, :uint32},
        21 => {:supportManusHistory, {:scalar, false}, :bool},
        22 => {:supportHatchHistory, {:scalar, false}, :bool},
        23 => {:supportedBotChannelFbids, :unpacked, :string},
        24 => {:supportInlineContacts, {:scalar, false}, :bool}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        completeOnDemandReady: {18, {:scalar, false}, :bool},
        fullSyncDaysLimit: {1, {:scalar, 0}, :uint32},
        fullSyncSizeMbLimit: {2, {:scalar, 0}, :uint32},
        initialSyncMaxMessagesPerChat: {20, {:scalar, 0}, :uint32},
        inlineInitialPayloadInE2EeMsg: {4, {:scalar, false}, :bool},
        onDemandReady: {16, {:scalar, false}, :bool},
        recentSyncDaysLimit: {5, {:scalar, 0}, :uint32},
        storageQuotaMb: {3, {:scalar, 0}, :uint32},
        supportAddOnHistorySyncMigration: {13, {:scalar, false}, :bool},
        supportBizHostedMsg: {9, {:scalar, false}, :bool},
        supportBotUserAgentChatHistory: {7, {:scalar, false}, :bool},
        supportCagReactionsAndPolls: {8, {:scalar, false}, :bool},
        supportCallLogHistory: {6, {:scalar, false}, :bool},
        supportFbidBotChatHistory: {12, {:scalar, false}, :bool},
        supportGroupHistory: {15, {:scalar, false}, :bool},
        supportGuestChat: {17, {:scalar, false}, :bool},
        supportHatchHistory: {22, {:scalar, false}, :bool},
        supportHostedGroupMsg: {11, {:scalar, false}, :bool},
        supportInlineContacts: {24, {:scalar, false}, :bool},
        supportManusHistory: {21, {:scalar, false}, :bool},
        supportMessageAssociation: {14, {:scalar, false}, :bool},
        supportRecentSyncChunkMessageCountTuning: {10, {:scalar, false}, :bool},
        supportedBotChannelFbids: {23, :unpacked, :string},
        thumbnailSyncDaysLimit: {19, {:scalar, 0}, :uint32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "fullSyncDaysLimit",
          kind: {:scalar, 0},
          label: :optional,
          name: :fullSyncDaysLimit,
          tag: 1,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "fullSyncSizeMbLimit",
          kind: {:scalar, 0},
          label: :optional,
          name: :fullSyncSizeMbLimit,
          tag: 2,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "storageQuotaMb",
          kind: {:scalar, 0},
          label: :optional,
          name: :storageQuotaMb,
          tag: 3,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "inlineInitialPayloadInE2EeMsg",
          kind: {:scalar, false},
          label: :optional,
          name: :inlineInitialPayloadInE2EeMsg,
          tag: 4,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "recentSyncDaysLimit",
          kind: {:scalar, 0},
          label: :optional,
          name: :recentSyncDaysLimit,
          tag: 5,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportCallLogHistory",
          kind: {:scalar, false},
          label: :optional,
          name: :supportCallLogHistory,
          tag: 6,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportBotUserAgentChatHistory",
          kind: {:scalar, false},
          label: :optional,
          name: :supportBotUserAgentChatHistory,
          tag: 7,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportCagReactionsAndPolls",
          kind: {:scalar, false},
          label: :optional,
          name: :supportCagReactionsAndPolls,
          tag: 8,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportBizHostedMsg",
          kind: {:scalar, false},
          label: :optional,
          name: :supportBizHostedMsg,
          tag: 9,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportRecentSyncChunkMessageCountTuning",
          kind: {:scalar, false},
          label: :optional,
          name: :supportRecentSyncChunkMessageCountTuning,
          tag: 10,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportHostedGroupMsg",
          kind: {:scalar, false},
          label: :optional,
          name: :supportHostedGroupMsg,
          tag: 11,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportFbidBotChatHistory",
          kind: {:scalar, false},
          label: :optional,
          name: :supportFbidBotChatHistory,
          tag: 12,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportAddOnHistorySyncMigration",
          kind: {:scalar, false},
          label: :optional,
          name: :supportAddOnHistorySyncMigration,
          tag: 13,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportMessageAssociation",
          kind: {:scalar, false},
          label: :optional,
          name: :supportMessageAssociation,
          tag: 14,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportGroupHistory",
          kind: {:scalar, false},
          label: :optional,
          name: :supportGroupHistory,
          tag: 15,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "onDemandReady",
          kind: {:scalar, false},
          label: :optional,
          name: :onDemandReady,
          tag: 16,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportGuestChat",
          kind: {:scalar, false},
          label: :optional,
          name: :supportGuestChat,
          tag: 17,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "completeOnDemandReady",
          kind: {:scalar, false},
          label: :optional,
          name: :completeOnDemandReady,
          tag: 18,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailSyncDaysLimit",
          kind: {:scalar, 0},
          label: :optional,
          name: :thumbnailSyncDaysLimit,
          tag: 19,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "initialSyncMaxMessagesPerChat",
          kind: {:scalar, 0},
          label: :optional,
          name: :initialSyncMaxMessagesPerChat,
          tag: 20,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportManusHistory",
          kind: {:scalar, false},
          label: :optional,
          name: :supportManusHistory,
          tag: 21,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportHatchHistory",
          kind: {:scalar, false},
          label: :optional,
          name: :supportHatchHistory,
          tag: 22,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportedBotChannelFbids",
          kind: :unpacked,
          label: :repeated,
          name: :supportedBotChannelFbids,
          tag: 23,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportInlineContacts",
          kind: {:scalar, false},
          label: :optional,
          name: :supportInlineContacts,
          tag: 24,
          type: :bool
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:fullSyncDaysLimit) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fullSyncDaysLimit",
             kind: {:scalar, 0},
             label: :optional,
             name: :fullSyncDaysLimit,
             tag: 1,
             type: :uint32
           }}
        end

        def field_def("fullSyncDaysLimit") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fullSyncDaysLimit",
             kind: {:scalar, 0},
             label: :optional,
             name: :fullSyncDaysLimit,
             tag: 1,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:fullSyncSizeMbLimit) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fullSyncSizeMbLimit",
             kind: {:scalar, 0},
             label: :optional,
             name: :fullSyncSizeMbLimit,
             tag: 2,
             type: :uint32
           }}
        end

        def field_def("fullSyncSizeMbLimit") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fullSyncSizeMbLimit",
             kind: {:scalar, 0},
             label: :optional,
             name: :fullSyncSizeMbLimit,
             tag: 2,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:storageQuotaMb) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "storageQuotaMb",
             kind: {:scalar, 0},
             label: :optional,
             name: :storageQuotaMb,
             tag: 3,
             type: :uint32
           }}
        end

        def field_def("storageQuotaMb") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "storageQuotaMb",
             kind: {:scalar, 0},
             label: :optional,
             name: :storageQuotaMb,
             tag: 3,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:inlineInitialPayloadInE2EeMsg) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inlineInitialPayloadInE2EeMsg",
             kind: {:scalar, false},
             label: :optional,
             name: :inlineInitialPayloadInE2EeMsg,
             tag: 4,
             type: :bool
           }}
        end

        def field_def("inlineInitialPayloadInE2EeMsg") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inlineInitialPayloadInE2EeMsg",
             kind: {:scalar, false},
             label: :optional,
             name: :inlineInitialPayloadInE2EeMsg,
             tag: 4,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:recentSyncDaysLimit) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recentSyncDaysLimit",
             kind: {:scalar, 0},
             label: :optional,
             name: :recentSyncDaysLimit,
             tag: 5,
             type: :uint32
           }}
        end

        def field_def("recentSyncDaysLimit") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recentSyncDaysLimit",
             kind: {:scalar, 0},
             label: :optional,
             name: :recentSyncDaysLimit,
             tag: 5,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:supportCallLogHistory) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportCallLogHistory",
             kind: {:scalar, false},
             label: :optional,
             name: :supportCallLogHistory,
             tag: 6,
             type: :bool
           }}
        end

        def field_def("supportCallLogHistory") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportCallLogHistory",
             kind: {:scalar, false},
             label: :optional,
             name: :supportCallLogHistory,
             tag: 6,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportBotUserAgentChatHistory) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportBotUserAgentChatHistory",
             kind: {:scalar, false},
             label: :optional,
             name: :supportBotUserAgentChatHistory,
             tag: 7,
             type: :bool
           }}
        end

        def field_def("supportBotUserAgentChatHistory") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportBotUserAgentChatHistory",
             kind: {:scalar, false},
             label: :optional,
             name: :supportBotUserAgentChatHistory,
             tag: 7,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportCagReactionsAndPolls) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportCagReactionsAndPolls",
             kind: {:scalar, false},
             label: :optional,
             name: :supportCagReactionsAndPolls,
             tag: 8,
             type: :bool
           }}
        end

        def field_def("supportCagReactionsAndPolls") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportCagReactionsAndPolls",
             kind: {:scalar, false},
             label: :optional,
             name: :supportCagReactionsAndPolls,
             tag: 8,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportBizHostedMsg) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportBizHostedMsg",
             kind: {:scalar, false},
             label: :optional,
             name: :supportBizHostedMsg,
             tag: 9,
             type: :bool
           }}
        end

        def field_def("supportBizHostedMsg") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportBizHostedMsg",
             kind: {:scalar, false},
             label: :optional,
             name: :supportBizHostedMsg,
             tag: 9,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportRecentSyncChunkMessageCountTuning) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportRecentSyncChunkMessageCountTuning",
             kind: {:scalar, false},
             label: :optional,
             name: :supportRecentSyncChunkMessageCountTuning,
             tag: 10,
             type: :bool
           }}
        end

        def field_def("supportRecentSyncChunkMessageCountTuning") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportRecentSyncChunkMessageCountTuning",
             kind: {:scalar, false},
             label: :optional,
             name: :supportRecentSyncChunkMessageCountTuning,
             tag: 10,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportHostedGroupMsg) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportHostedGroupMsg",
             kind: {:scalar, false},
             label: :optional,
             name: :supportHostedGroupMsg,
             tag: 11,
             type: :bool
           }}
        end

        def field_def("supportHostedGroupMsg") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportHostedGroupMsg",
             kind: {:scalar, false},
             label: :optional,
             name: :supportHostedGroupMsg,
             tag: 11,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportFbidBotChatHistory) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportFbidBotChatHistory",
             kind: {:scalar, false},
             label: :optional,
             name: :supportFbidBotChatHistory,
             tag: 12,
             type: :bool
           }}
        end

        def field_def("supportFbidBotChatHistory") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportFbidBotChatHistory",
             kind: {:scalar, false},
             label: :optional,
             name: :supportFbidBotChatHistory,
             tag: 12,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportAddOnHistorySyncMigration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportAddOnHistorySyncMigration",
             kind: {:scalar, false},
             label: :optional,
             name: :supportAddOnHistorySyncMigration,
             tag: 13,
             type: :bool
           }}
        end

        def field_def("supportAddOnHistorySyncMigration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportAddOnHistorySyncMigration",
             kind: {:scalar, false},
             label: :optional,
             name: :supportAddOnHistorySyncMigration,
             tag: 13,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportMessageAssociation) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportMessageAssociation",
             kind: {:scalar, false},
             label: :optional,
             name: :supportMessageAssociation,
             tag: 14,
             type: :bool
           }}
        end

        def field_def("supportMessageAssociation") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportMessageAssociation",
             kind: {:scalar, false},
             label: :optional,
             name: :supportMessageAssociation,
             tag: 14,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportGroupHistory) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportGroupHistory",
             kind: {:scalar, false},
             label: :optional,
             name: :supportGroupHistory,
             tag: 15,
             type: :bool
           }}
        end

        def field_def("supportGroupHistory") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportGroupHistory",
             kind: {:scalar, false},
             label: :optional,
             name: :supportGroupHistory,
             tag: 15,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:onDemandReady) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "onDemandReady",
             kind: {:scalar, false},
             label: :optional,
             name: :onDemandReady,
             tag: 16,
             type: :bool
           }}
        end

        def field_def("onDemandReady") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "onDemandReady",
             kind: {:scalar, false},
             label: :optional,
             name: :onDemandReady,
             tag: 16,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportGuestChat) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportGuestChat",
             kind: {:scalar, false},
             label: :optional,
             name: :supportGuestChat,
             tag: 17,
             type: :bool
           }}
        end

        def field_def("supportGuestChat") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportGuestChat",
             kind: {:scalar, false},
             label: :optional,
             name: :supportGuestChat,
             tag: 17,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:completeOnDemandReady) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "completeOnDemandReady",
             kind: {:scalar, false},
             label: :optional,
             name: :completeOnDemandReady,
             tag: 18,
             type: :bool
           }}
        end

        def field_def("completeOnDemandReady") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "completeOnDemandReady",
             kind: {:scalar, false},
             label: :optional,
             name: :completeOnDemandReady,
             tag: 18,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailSyncDaysLimit) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailSyncDaysLimit",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailSyncDaysLimit,
             tag: 19,
             type: :uint32
           }}
        end

        def field_def("thumbnailSyncDaysLimit") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailSyncDaysLimit",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailSyncDaysLimit,
             tag: 19,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:initialSyncMaxMessagesPerChat) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "initialSyncMaxMessagesPerChat",
             kind: {:scalar, 0},
             label: :optional,
             name: :initialSyncMaxMessagesPerChat,
             tag: 20,
             type: :uint32
           }}
        end

        def field_def("initialSyncMaxMessagesPerChat") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "initialSyncMaxMessagesPerChat",
             kind: {:scalar, 0},
             label: :optional,
             name: :initialSyncMaxMessagesPerChat,
             tag: 20,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:supportManusHistory) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportManusHistory",
             kind: {:scalar, false},
             label: :optional,
             name: :supportManusHistory,
             tag: 21,
             type: :bool
           }}
        end

        def field_def("supportManusHistory") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportManusHistory",
             kind: {:scalar, false},
             label: :optional,
             name: :supportManusHistory,
             tag: 21,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportHatchHistory) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportHatchHistory",
             kind: {:scalar, false},
             label: :optional,
             name: :supportHatchHistory,
             tag: 22,
             type: :bool
           }}
        end

        def field_def("supportHatchHistory") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportHatchHistory",
             kind: {:scalar, false},
             label: :optional,
             name: :supportHatchHistory,
             tag: 22,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportedBotChannelFbids) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportedBotChannelFbids",
             kind: :unpacked,
             label: :repeated,
             name: :supportedBotChannelFbids,
             tag: 23,
             type: :string
           }}
        end

        def field_def("supportedBotChannelFbids") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportedBotChannelFbids",
             kind: :unpacked,
             label: :repeated,
             name: :supportedBotChannelFbids,
             tag: 23,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:supportInlineContacts) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportInlineContacts",
             kind: {:scalar, false},
             label: :optional,
             name: :supportInlineContacts,
             tag: 24,
             type: :bool
           }}
        end

        def field_def("supportInlineContacts") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportInlineContacts",
             kind: {:scalar, false},
             label: :optional,
             name: :supportInlineContacts,
             tag: 24,
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
    def default(:fullSyncDaysLimit) do
      {:ok, 0}
    end,
    def default(:fullSyncSizeMbLimit) do
      {:ok, 0}
    end,
    def default(:storageQuotaMb) do
      {:ok, 0}
    end,
    def default(:inlineInitialPayloadInE2EeMsg) do
      {:ok, false}
    end,
    def default(:recentSyncDaysLimit) do
      {:ok, 0}
    end,
    def default(:supportCallLogHistory) do
      {:ok, false}
    end,
    def default(:supportBotUserAgentChatHistory) do
      {:ok, false}
    end,
    def default(:supportCagReactionsAndPolls) do
      {:ok, false}
    end,
    def default(:supportBizHostedMsg) do
      {:ok, false}
    end,
    def default(:supportRecentSyncChunkMessageCountTuning) do
      {:ok, false}
    end,
    def default(:supportHostedGroupMsg) do
      {:ok, false}
    end,
    def default(:supportFbidBotChatHistory) do
      {:ok, false}
    end,
    def default(:supportAddOnHistorySyncMigration) do
      {:ok, false}
    end,
    def default(:supportMessageAssociation) do
      {:ok, false}
    end,
    def default(:supportGroupHistory) do
      {:ok, false}
    end,
    def default(:onDemandReady) do
      {:ok, false}
    end,
    def default(:supportGuestChat) do
      {:ok, false}
    end,
    def default(:completeOnDemandReady) do
      {:ok, false}
    end,
    def default(:thumbnailSyncDaysLimit) do
      {:ok, 0}
    end,
    def default(:initialSyncMaxMessagesPerChat) do
      {:ok, 0}
    end,
    def default(:supportManusHistory) do
      {:ok, false}
    end,
    def default(:supportHatchHistory) do
      {:ok, false}
    end,
    def default(:supportedBotChannelFbids) do
      {:error, :no_default_value}
    end,
    def default(:supportInlineContacts) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waCompanionReg",
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
