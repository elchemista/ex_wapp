# credo:disable-for-this-file
defmodule WAWebProtobufsHistorySync.HistorySync do
  @moduledoc false
  defstruct syncType: nil,
            conversations: [],
            statusV3Messages: [],
            chunkOrder: nil,
            progress: nil,
            pushnames: [],
            globalSettings: nil,
            threadIDUserSecret: nil,
            threadDsTimeframeOffset: nil,
            recentStickers: [],
            pastParticipants: [],
            callLogRecords: [],
            aiWaitListState: nil,
            phoneNumberToLidMappings: [],
            companionMetaNonce: nil,
            shareableChatIdentifierEncryptionKey: nil,
            accounts: [],
            nctSalt: nil,
            inlineContacts: [],
            inlineContactsProvided: nil,
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
        |> encode_syncType(msg)
        |> encode_conversations(msg)
        |> encode_statusV3Messages(msg)
        |> encode_chunkOrder(msg)
        |> encode_progress(msg)
        |> encode_pushnames(msg)
        |> encode_globalSettings(msg)
        |> encode_threadIDUserSecret(msg)
        |> encode_threadDsTimeframeOffset(msg)
        |> encode_recentStickers(msg)
        |> encode_pastParticipants(msg)
        |> encode_callLogRecords(msg)
        |> encode_aiWaitListState(msg)
        |> encode_phoneNumberToLidMappings(msg)
        |> encode_companionMetaNonce(msg)
        |> encode_shareableChatIdentifierEncryptionKey(msg)
        |> encode_accounts(msg)
        |> encode_nctSalt(msg)
        |> encode_inlineContacts(msg)
        |> encode_inlineContactsProvided(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_syncType(acc, msg) do
        try do
          case msg.syncType do
            nil ->
              raise Protox.RequiredFieldsError.new([:syncType])

            _ ->
              [
                acc,
                "\b",
                msg.syncType
                |> WAWebProtobufsHistorySync.HistorySync.HistorySyncType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:syncType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_conversations(acc, msg) do
        try do
          case msg.conversations do
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
            reraise Protox.EncodingError.new(:conversations, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_statusV3Messages(acc, msg) do
        try do
          case msg.statusV3Messages do
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
            reraise Protox.EncodingError.new(:statusV3Messages, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_chunkOrder(acc, msg) do
        try do
          case msg.chunkOrder do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_uint32(msg.chunkOrder)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:chunkOrder, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_progress(acc, msg) do
        try do
          case msg.progress do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_uint32(msg.progress)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:progress, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pushnames(acc, msg) do
        try do
          case msg.pushnames do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, ":", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pushnames, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_globalSettings(acc, msg) do
        try do
          case msg.globalSettings do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.globalSettings)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:globalSettings, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_threadIDUserSecret(acc, msg) do
        try do
          case msg.threadIDUserSecret do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_bytes(msg.threadIDUserSecret)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:threadIDUserSecret, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_threadDsTimeframeOffset(acc, msg) do
        try do
          case msg.threadDsTimeframeOffset do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_uint32(msg.threadDsTimeframeOffset)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:threadDsTimeframeOffset, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_recentStickers(acc, msg) do
        try do
          case msg.recentStickers do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "Z", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:recentStickers, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pastParticipants(acc, msg) do
        try do
          case msg.pastParticipants do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "b", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pastParticipants, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_callLogRecords(acc, msg) do
        try do
          case msg.callLogRecords do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "j", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callLogRecords, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_aiWaitListState(acc, msg) do
        try do
          case msg.aiWaitListState do
            nil ->
              acc

            _ ->
              [
                acc,
                "p",
                msg.aiWaitListState
                |> WAWebProtobufsHistorySync.HistorySync.BotAIWaitListState.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:aiWaitListState, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_phoneNumberToLidMappings(acc, msg) do
        try do
          case msg.phoneNumberToLidMappings do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "z", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:phoneNumberToLidMappings, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_companionMetaNonce(acc, msg) do
        try do
          case msg.companionMetaNonce do
            nil -> acc
            _ -> [acc, "\x82\x01", Protox.Encode.encode_string(msg.companionMetaNonce)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:companionMetaNonce, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_shareableChatIdentifierEncryptionKey(acc, msg) do
        try do
          case msg.shareableChatIdentifierEncryptionKey do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x8A\x01",
                Protox.Encode.encode_bytes(msg.shareableChatIdentifierEncryptionKey)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :shareableChatIdentifierEncryptionKey,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_accounts(acc, msg) do
        try do
          case msg.accounts do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x92\x01", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:accounts, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_nctSalt(acc, msg) do
        try do
          case msg.nctSalt do
            nil -> acc
            _ -> [acc, "\x9A\x01", Protox.Encode.encode_bytes(msg.nctSalt)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:nctSalt, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_inlineContacts(acc, msg) do
        try do
          case msg.inlineContacts do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xA2\x01", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:inlineContacts, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_inlineContactsProvided(acc, msg) do
        try do
          case msg.inlineContactsProvided do
            nil -> acc
            _ -> [acc, "\xA8\x01", Protox.Encode.encode_bool(msg.inlineContactsProvided)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:inlineContactsProvided, "invalid field value"),
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
          {msg, set_fields} =
            parse_key_value([], bytes, struct(WAWebProtobufsHistorySync.HistorySync))

          case [:syncType] -- set_fields do
            [] -> msg
            missing_fields -> raise Protox.RequiredFieldsError.new(missing_fields)
          end
        end
      )
    )

    (
      @spec parse_key_value([atom], binary, struct) :: {struct, [atom]}
      defp parse_key_value(set_fields, <<>>, msg) do
        {msg, set_fields}
      end

      defp parse_key_value(set_fields, bytes, msg) do
        {new_set_fields, field, rest} =
          case Protox.Decode.parse_key(bytes) do
            {0, _, _} ->
              raise %Protox.IllegalTagError{}

            {1, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsHistorySync.HistorySync.HistorySyncType
                )

              {[:syncType | set_fields], [syncType: value], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:conversations | set_fields],
               [
                 conversations:
                   msg.conversations ++
                     [WAWebProtobufsHistorySync.Conversation.decode!(delimited)]
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:statusV3Messages | set_fields],
               [
                 statusV3Messages:
                   msg.statusV3Messages ++ [WAWebProtobufsWeb.WebMessageInfo.decode!(delimited)]
               ], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[:chunkOrder | set_fields], [chunkOrder: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[:progress | set_fields], [progress: value], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:pushnames | set_fields],
               [
                 pushnames:
                   msg.pushnames ++ [WAWebProtobufsHistorySync.Pushname.decode!(delimited)]
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:globalSettings | set_fields],
               [
                 globalSettings:
                   Protox.MergeMessage.merge(
                     msg.globalSettings,
                     WAWebProtobufsHistorySync.GlobalSettings.decode!(delimited)
                   )
               ], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:threadIDUserSecret | set_fields], [threadIDUserSecret: delimited], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[:threadDsTimeframeOffset | set_fields], [threadDsTimeframeOffset: value], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:recentStickers | set_fields],
               [
                 recentStickers:
                   msg.recentStickers ++
                     [WAWebProtobufsHistorySync.StickerMetadata.decode!(delimited)]
               ], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:pastParticipants | set_fields],
               [
                 pastParticipants:
                   msg.pastParticipants ++
                     [WAWebProtobufsHistorySync.PastParticipants.decode!(delimited)]
               ], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:callLogRecords | set_fields],
               [
                 callLogRecords:
                   msg.callLogRecords ++
                     [WAWebProtobufSyncAction.CallLogRecord.decode!(delimited)]
               ], rest}

            {14, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsHistorySync.HistorySync.BotAIWaitListState
                )

              {[:aiWaitListState | set_fields], [aiWaitListState: value], rest}

            {15, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:phoneNumberToLidMappings | set_fields],
               [
                 phoneNumberToLidMappings:
                   msg.phoneNumberToLidMappings ++
                     [WAWebProtobufsHistorySync.PhoneNumberToLIDMapping.decode!(delimited)]
               ], rest}

            {16, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:companionMetaNonce | set_fields],
               [companionMetaNonce: Protox.Decode.validate_string!(delimited)], rest}

            {17, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:shareableChatIdentifierEncryptionKey | set_fields],
               [shareableChatIdentifierEncryptionKey: delimited], rest}

            {18, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:accounts | set_fields],
               [accounts: msg.accounts ++ [WAWebProtobufsHistorySync.Account.decode!(delimited)]],
               rest}

            {19, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:nctSalt | set_fields], [nctSalt: delimited], rest}

            {20, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:inlineContacts | set_fields],
               [
                 inlineContacts:
                   msg.inlineContacts ++
                     [WAWebProtobufsHistorySync.InlineContact.decode!(delimited)]
               ], rest}

            {21, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:inlineContactsProvided | set_fields], [inlineContactsProvided: value], rest}

            {tag, wire_type, rest} ->
              {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

              {set_fields,
               [
                 {msg.__struct__.unknown_fields_name(),
                  [value | msg.__struct__.unknown_fields(msg)]}
               ], rest}
          end

        msg_updated = struct(msg, field)
        parse_key_value(new_set_fields, rest, msg_updated)
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
        WAWebProtobufsHistorySync.HistorySync,
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
          {:syncType, {:scalar, :INITIAL_BOOTSTRAP},
           {:enum, WAWebProtobufsHistorySync.HistorySync.HistorySyncType}},
        2 => {:conversations, :unpacked, {:message, WAWebProtobufsHistorySync.Conversation}},
        3 => {:statusV3Messages, :unpacked, {:message, WAWebProtobufsWeb.WebMessageInfo}},
        5 => {:chunkOrder, {:scalar, 0}, :uint32},
        6 => {:progress, {:scalar, 0}, :uint32},
        7 => {:pushnames, :unpacked, {:message, WAWebProtobufsHistorySync.Pushname}},
        8 =>
          {:globalSettings, {:scalar, nil}, {:message, WAWebProtobufsHistorySync.GlobalSettings}},
        9 => {:threadIDUserSecret, {:scalar, ""}, :bytes},
        10 => {:threadDsTimeframeOffset, {:scalar, 0}, :uint32},
        11 => {:recentStickers, :unpacked, {:message, WAWebProtobufsHistorySync.StickerMetadata}},
        12 =>
          {:pastParticipants, :unpacked, {:message, WAWebProtobufsHistorySync.PastParticipants}},
        13 => {:callLogRecords, :unpacked, {:message, WAWebProtobufSyncAction.CallLogRecord}},
        14 =>
          {:aiWaitListState, {:scalar, :IN_WAITLIST},
           {:enum, WAWebProtobufsHistorySync.HistorySync.BotAIWaitListState}},
        15 =>
          {:phoneNumberToLidMappings, :unpacked,
           {:message, WAWebProtobufsHistorySync.PhoneNumberToLIDMapping}},
        16 => {:companionMetaNonce, {:scalar, ""}, :string},
        17 => {:shareableChatIdentifierEncryptionKey, {:scalar, ""}, :bytes},
        18 => {:accounts, :unpacked, {:message, WAWebProtobufsHistorySync.Account}},
        19 => {:nctSalt, {:scalar, ""}, :bytes},
        20 => {:inlineContacts, :unpacked, {:message, WAWebProtobufsHistorySync.InlineContact}},
        21 => {:inlineContactsProvided, {:scalar, false}, :bool}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        accounts: {18, :unpacked, {:message, WAWebProtobufsHistorySync.Account}},
        aiWaitListState:
          {14, {:scalar, :IN_WAITLIST},
           {:enum, WAWebProtobufsHistorySync.HistorySync.BotAIWaitListState}},
        callLogRecords: {13, :unpacked, {:message, WAWebProtobufSyncAction.CallLogRecord}},
        chunkOrder: {5, {:scalar, 0}, :uint32},
        companionMetaNonce: {16, {:scalar, ""}, :string},
        conversations: {2, :unpacked, {:message, WAWebProtobufsHistorySync.Conversation}},
        globalSettings: {8, {:scalar, nil}, {:message, WAWebProtobufsHistorySync.GlobalSettings}},
        inlineContacts: {20, :unpacked, {:message, WAWebProtobufsHistorySync.InlineContact}},
        inlineContactsProvided: {21, {:scalar, false}, :bool},
        nctSalt: {19, {:scalar, ""}, :bytes},
        pastParticipants: {12, :unpacked, {:message, WAWebProtobufsHistorySync.PastParticipants}},
        phoneNumberToLidMappings:
          {15, :unpacked, {:message, WAWebProtobufsHistorySync.PhoneNumberToLIDMapping}},
        progress: {6, {:scalar, 0}, :uint32},
        pushnames: {7, :unpacked, {:message, WAWebProtobufsHistorySync.Pushname}},
        recentStickers: {11, :unpacked, {:message, WAWebProtobufsHistorySync.StickerMetadata}},
        shareableChatIdentifierEncryptionKey: {17, {:scalar, ""}, :bytes},
        statusV3Messages: {3, :unpacked, {:message, WAWebProtobufsWeb.WebMessageInfo}},
        syncType:
          {1, {:scalar, :INITIAL_BOOTSTRAP},
           {:enum, WAWebProtobufsHistorySync.HistorySync.HistorySyncType}},
        threadDsTimeframeOffset: {10, {:scalar, 0}, :uint32},
        threadIDUserSecret: {9, {:scalar, ""}, :bytes}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "syncType",
          kind: {:scalar, :INITIAL_BOOTSTRAP},
          label: :required,
          name: :syncType,
          tag: 1,
          type: {:enum, WAWebProtobufsHistorySync.HistorySync.HistorySyncType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "conversations",
          kind: :unpacked,
          label: :repeated,
          name: :conversations,
          tag: 2,
          type: {:message, WAWebProtobufsHistorySync.Conversation}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusV3Messages",
          kind: :unpacked,
          label: :repeated,
          name: :statusV3Messages,
          tag: 3,
          type: {:message, WAWebProtobufsWeb.WebMessageInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "chunkOrder",
          kind: {:scalar, 0},
          label: :optional,
          name: :chunkOrder,
          tag: 5,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "progress",
          kind: {:scalar, 0},
          label: :optional,
          name: :progress,
          tag: 6,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "pushnames",
          kind: :unpacked,
          label: :repeated,
          name: :pushnames,
          tag: 7,
          type: {:message, WAWebProtobufsHistorySync.Pushname}
        },
        %{
          __struct__: Protox.Field,
          json_name: "globalSettings",
          kind: {:scalar, nil},
          label: :optional,
          name: :globalSettings,
          tag: 8,
          type: {:message, WAWebProtobufsHistorySync.GlobalSettings}
        },
        %{
          __struct__: Protox.Field,
          json_name: "threadIDUserSecret",
          kind: {:scalar, ""},
          label: :optional,
          name: :threadIDUserSecret,
          tag: 9,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "threadDsTimeframeOffset",
          kind: {:scalar, 0},
          label: :optional,
          name: :threadDsTimeframeOffset,
          tag: 10,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "recentStickers",
          kind: :unpacked,
          label: :repeated,
          name: :recentStickers,
          tag: 11,
          type: {:message, WAWebProtobufsHistorySync.StickerMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pastParticipants",
          kind: :unpacked,
          label: :repeated,
          name: :pastParticipants,
          tag: 12,
          type: {:message, WAWebProtobufsHistorySync.PastParticipants}
        },
        %{
          __struct__: Protox.Field,
          json_name: "callLogRecords",
          kind: :unpacked,
          label: :repeated,
          name: :callLogRecords,
          tag: 13,
          type: {:message, WAWebProtobufSyncAction.CallLogRecord}
        },
        %{
          __struct__: Protox.Field,
          json_name: "aiWaitListState",
          kind: {:scalar, :IN_WAITLIST},
          label: :optional,
          name: :aiWaitListState,
          tag: 14,
          type: {:enum, WAWebProtobufsHistorySync.HistorySync.BotAIWaitListState}
        },
        %{
          __struct__: Protox.Field,
          json_name: "phoneNumberToLidMappings",
          kind: :unpacked,
          label: :repeated,
          name: :phoneNumberToLidMappings,
          tag: 15,
          type: {:message, WAWebProtobufsHistorySync.PhoneNumberToLIDMapping}
        },
        %{
          __struct__: Protox.Field,
          json_name: "companionMetaNonce",
          kind: {:scalar, ""},
          label: :optional,
          name: :companionMetaNonce,
          tag: 16,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "shareableChatIdentifierEncryptionKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :shareableChatIdentifierEncryptionKey,
          tag: 17,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "accounts",
          kind: :unpacked,
          label: :repeated,
          name: :accounts,
          tag: 18,
          type: {:message, WAWebProtobufsHistorySync.Account}
        },
        %{
          __struct__: Protox.Field,
          json_name: "nctSalt",
          kind: {:scalar, ""},
          label: :optional,
          name: :nctSalt,
          tag: 19,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "inlineContacts",
          kind: :unpacked,
          label: :repeated,
          name: :inlineContacts,
          tag: 20,
          type: {:message, WAWebProtobufsHistorySync.InlineContact}
        },
        %{
          __struct__: Protox.Field,
          json_name: "inlineContactsProvided",
          kind: {:scalar, false},
          label: :optional,
          name: :inlineContactsProvided,
          tag: 21,
          type: :bool
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:syncType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "syncType",
             kind: {:scalar, :INITIAL_BOOTSTRAP},
             label: :required,
             name: :syncType,
             tag: 1,
             type: {:enum, WAWebProtobufsHistorySync.HistorySync.HistorySyncType}
           }}
        end

        def field_def("syncType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "syncType",
             kind: {:scalar, :INITIAL_BOOTSTRAP},
             label: :required,
             name: :syncType,
             tag: 1,
             type: {:enum, WAWebProtobufsHistorySync.HistorySync.HistorySyncType}
           }}
        end

        []
      ),
      (
        def field_def(:conversations) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversations",
             kind: :unpacked,
             label: :repeated,
             name: :conversations,
             tag: 2,
             type: {:message, WAWebProtobufsHistorySync.Conversation}
           }}
        end

        def field_def("conversations") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversations",
             kind: :unpacked,
             label: :repeated,
             name: :conversations,
             tag: 2,
             type: {:message, WAWebProtobufsHistorySync.Conversation}
           }}
        end

        []
      ),
      (
        def field_def(:statusV3Messages) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusV3Messages",
             kind: :unpacked,
             label: :repeated,
             name: :statusV3Messages,
             tag: 3,
             type: {:message, WAWebProtobufsWeb.WebMessageInfo}
           }}
        end

        def field_def("statusV3Messages") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusV3Messages",
             kind: :unpacked,
             label: :repeated,
             name: :statusV3Messages,
             tag: 3,
             type: {:message, WAWebProtobufsWeb.WebMessageInfo}
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
             tag: 5,
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
             tag: 5,
             type: :uint32
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
             tag: 6,
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
             tag: 6,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:pushnames) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pushnames",
             kind: :unpacked,
             label: :repeated,
             name: :pushnames,
             tag: 7,
             type: {:message, WAWebProtobufsHistorySync.Pushname}
           }}
        end

        def field_def("pushnames") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pushnames",
             kind: :unpacked,
             label: :repeated,
             name: :pushnames,
             tag: 7,
             type: {:message, WAWebProtobufsHistorySync.Pushname}
           }}
        end

        []
      ),
      (
        def field_def(:globalSettings) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "globalSettings",
             kind: {:scalar, nil},
             label: :optional,
             name: :globalSettings,
             tag: 8,
             type: {:message, WAWebProtobufsHistorySync.GlobalSettings}
           }}
        end

        def field_def("globalSettings") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "globalSettings",
             kind: {:scalar, nil},
             label: :optional,
             name: :globalSettings,
             tag: 8,
             type: {:message, WAWebProtobufsHistorySync.GlobalSettings}
           }}
        end

        []
      ),
      (
        def field_def(:threadIDUserSecret) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "threadIDUserSecret",
             kind: {:scalar, ""},
             label: :optional,
             name: :threadIDUserSecret,
             tag: 9,
             type: :bytes
           }}
        end

        def field_def("threadIDUserSecret") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "threadIDUserSecret",
             kind: {:scalar, ""},
             label: :optional,
             name: :threadIDUserSecret,
             tag: 9,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:threadDsTimeframeOffset) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "threadDsTimeframeOffset",
             kind: {:scalar, 0},
             label: :optional,
             name: :threadDsTimeframeOffset,
             tag: 10,
             type: :uint32
           }}
        end

        def field_def("threadDsTimeframeOffset") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "threadDsTimeframeOffset",
             kind: {:scalar, 0},
             label: :optional,
             name: :threadDsTimeframeOffset,
             tag: 10,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:recentStickers) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recentStickers",
             kind: :unpacked,
             label: :repeated,
             name: :recentStickers,
             tag: 11,
             type: {:message, WAWebProtobufsHistorySync.StickerMetadata}
           }}
        end

        def field_def("recentStickers") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recentStickers",
             kind: :unpacked,
             label: :repeated,
             name: :recentStickers,
             tag: 11,
             type: {:message, WAWebProtobufsHistorySync.StickerMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:pastParticipants) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pastParticipants",
             kind: :unpacked,
             label: :repeated,
             name: :pastParticipants,
             tag: 12,
             type: {:message, WAWebProtobufsHistorySync.PastParticipants}
           }}
        end

        def field_def("pastParticipants") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pastParticipants",
             kind: :unpacked,
             label: :repeated,
             name: :pastParticipants,
             tag: 12,
             type: {:message, WAWebProtobufsHistorySync.PastParticipants}
           }}
        end

        []
      ),
      (
        def field_def(:callLogRecords) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callLogRecords",
             kind: :unpacked,
             label: :repeated,
             name: :callLogRecords,
             tag: 13,
             type: {:message, WAWebProtobufSyncAction.CallLogRecord}
           }}
        end

        def field_def("callLogRecords") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callLogRecords",
             kind: :unpacked,
             label: :repeated,
             name: :callLogRecords,
             tag: 13,
             type: {:message, WAWebProtobufSyncAction.CallLogRecord}
           }}
        end

        []
      ),
      (
        def field_def(:aiWaitListState) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiWaitListState",
             kind: {:scalar, :IN_WAITLIST},
             label: :optional,
             name: :aiWaitListState,
             tag: 14,
             type: {:enum, WAWebProtobufsHistorySync.HistorySync.BotAIWaitListState}
           }}
        end

        def field_def("aiWaitListState") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiWaitListState",
             kind: {:scalar, :IN_WAITLIST},
             label: :optional,
             name: :aiWaitListState,
             tag: 14,
             type: {:enum, WAWebProtobufsHistorySync.HistorySync.BotAIWaitListState}
           }}
        end

        []
      ),
      (
        def field_def(:phoneNumberToLidMappings) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "phoneNumberToLidMappings",
             kind: :unpacked,
             label: :repeated,
             name: :phoneNumberToLidMappings,
             tag: 15,
             type: {:message, WAWebProtobufsHistorySync.PhoneNumberToLIDMapping}
           }}
        end

        def field_def("phoneNumberToLidMappings") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "phoneNumberToLidMappings",
             kind: :unpacked,
             label: :repeated,
             name: :phoneNumberToLidMappings,
             tag: 15,
             type: {:message, WAWebProtobufsHistorySync.PhoneNumberToLIDMapping}
           }}
        end

        []
      ),
      (
        def field_def(:companionMetaNonce) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "companionMetaNonce",
             kind: {:scalar, ""},
             label: :optional,
             name: :companionMetaNonce,
             tag: 16,
             type: :string
           }}
        end

        def field_def("companionMetaNonce") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "companionMetaNonce",
             kind: {:scalar, ""},
             label: :optional,
             name: :companionMetaNonce,
             tag: 16,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:shareableChatIdentifierEncryptionKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shareableChatIdentifierEncryptionKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :shareableChatIdentifierEncryptionKey,
             tag: 17,
             type: :bytes
           }}
        end

        def field_def("shareableChatIdentifierEncryptionKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shareableChatIdentifierEncryptionKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :shareableChatIdentifierEncryptionKey,
             tag: 17,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:accounts) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accounts",
             kind: :unpacked,
             label: :repeated,
             name: :accounts,
             tag: 18,
             type: {:message, WAWebProtobufsHistorySync.Account}
           }}
        end

        def field_def("accounts") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accounts",
             kind: :unpacked,
             label: :repeated,
             name: :accounts,
             tag: 18,
             type: {:message, WAWebProtobufsHistorySync.Account}
           }}
        end

        []
      ),
      (
        def field_def(:nctSalt) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nctSalt",
             kind: {:scalar, ""},
             label: :optional,
             name: :nctSalt,
             tag: 19,
             type: :bytes
           }}
        end

        def field_def("nctSalt") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nctSalt",
             kind: {:scalar, ""},
             label: :optional,
             name: :nctSalt,
             tag: 19,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:inlineContacts) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inlineContacts",
             kind: :unpacked,
             label: :repeated,
             name: :inlineContacts,
             tag: 20,
             type: {:message, WAWebProtobufsHistorySync.InlineContact}
           }}
        end

        def field_def("inlineContacts") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inlineContacts",
             kind: :unpacked,
             label: :repeated,
             name: :inlineContacts,
             tag: 20,
             type: {:message, WAWebProtobufsHistorySync.InlineContact}
           }}
        end

        []
      ),
      (
        def field_def(:inlineContactsProvided) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inlineContactsProvided",
             kind: {:scalar, false},
             label: :optional,
             name: :inlineContactsProvided,
             tag: 21,
             type: :bool
           }}
        end

        def field_def("inlineContactsProvided") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inlineContactsProvided",
             kind: {:scalar, false},
             label: :optional,
             name: :inlineContactsProvided,
             tag: 21,
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
    @spec required_fields() :: [:syncType]
    def required_fields() do
      [:syncType]
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
    def default(:syncType) do
      {:ok, :INITIAL_BOOTSTRAP}
    end,
    def default(:conversations) do
      {:error, :no_default_value}
    end,
    def default(:statusV3Messages) do
      {:error, :no_default_value}
    end,
    def default(:chunkOrder) do
      {:ok, 0}
    end,
    def default(:progress) do
      {:ok, 0}
    end,
    def default(:pushnames) do
      {:error, :no_default_value}
    end,
    def default(:globalSettings) do
      {:ok, nil}
    end,
    def default(:threadIDUserSecret) do
      {:ok, ""}
    end,
    def default(:threadDsTimeframeOffset) do
      {:ok, 0}
    end,
    def default(:recentStickers) do
      {:error, :no_default_value}
    end,
    def default(:pastParticipants) do
      {:error, :no_default_value}
    end,
    def default(:callLogRecords) do
      {:error, :no_default_value}
    end,
    def default(:aiWaitListState) do
      {:ok, :IN_WAITLIST}
    end,
    def default(:phoneNumberToLidMappings) do
      {:error, :no_default_value}
    end,
    def default(:companionMetaNonce) do
      {:ok, ""}
    end,
    def default(:shareableChatIdentifierEncryptionKey) do
      {:ok, ""}
    end,
    def default(:accounts) do
      {:error, :no_default_value}
    end,
    def default(:nctSalt) do
      {:ok, ""}
    end,
    def default(:inlineContacts) do
      {:error, :no_default_value}
    end,
    def default(:inlineContactsProvided) do
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
