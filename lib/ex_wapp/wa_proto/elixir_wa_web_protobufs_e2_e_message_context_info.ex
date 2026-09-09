# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.MessageContextInfo do
  @moduledoc false
  defstruct deviceListMetadata: nil,
            deviceListMetadataVersion: nil,
            messageSecret: nil,
            paddingBytes: nil,
            messageAddOnDurationInSecs: nil,
            botMessageSecret: nil,
            botMetadata: nil,
            reportingTokenVersion: nil,
            messageAddOnExpiryType: nil,
            messageAssociation: nil,
            capiCreatedGroup: nil,
            supportPayload: nil,
            limitSharing: nil,
            limitSharingV2: nil,
            threadID: [],
            weblinkRenderConfig: nil,
            teeBotMetadata: nil,
            accountEncryptionAttestation: nil,
            associatedPrimaryIdentityKey: nil,
            teeContextAnchorMessageID: nil,
            acp2Setting: nil,
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
        |> encode_deviceListMetadata(msg)
        |> encode_deviceListMetadataVersion(msg)
        |> encode_messageSecret(msg)
        |> encode_paddingBytes(msg)
        |> encode_messageAddOnDurationInSecs(msg)
        |> encode_botMessageSecret(msg)
        |> encode_botMetadata(msg)
        |> encode_reportingTokenVersion(msg)
        |> encode_messageAddOnExpiryType(msg)
        |> encode_messageAssociation(msg)
        |> encode_capiCreatedGroup(msg)
        |> encode_supportPayload(msg)
        |> encode_limitSharing(msg)
        |> encode_limitSharingV2(msg)
        |> encode_threadID(msg)
        |> encode_weblinkRenderConfig(msg)
        |> encode_teeBotMetadata(msg)
        |> encode_accountEncryptionAttestation(msg)
        |> encode_associatedPrimaryIdentityKey(msg)
        |> encode_teeContextAnchorMessageID(msg)
        |> encode_acp2Setting(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_deviceListMetadata(acc, msg) do
        try do
          case msg.deviceListMetadata do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_message(msg.deviceListMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deviceListMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_deviceListMetadataVersion(acc, msg) do
        try do
          case msg.deviceListMetadataVersion do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_int32(msg.deviceListMetadataVersion)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deviceListMetadataVersion, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageSecret(acc, msg) do
        try do
          case msg.messageSecret do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_bytes(msg.messageSecret)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageSecret, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_paddingBytes(acc, msg) do
        try do
          case msg.paddingBytes do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_bytes(msg.paddingBytes)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:paddingBytes, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_messageAddOnDurationInSecs(acc, msg) do
        try do
          case msg.messageAddOnDurationInSecs do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_uint32(msg.messageAddOnDurationInSecs)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageAddOnDurationInSecs, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botMessageSecret(acc, msg) do
        try do
          case msg.botMessageSecret do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_bytes(msg.botMessageSecret)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botMessageSecret, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_botMetadata(acc, msg) do
        try do
          case msg.botMetadata do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_message(msg.botMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:botMetadata, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_reportingTokenVersion(acc, msg) do
        try do
          case msg.reportingTokenVersion do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_int32(msg.reportingTokenVersion)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:reportingTokenVersion, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageAddOnExpiryType(acc, msg) do
        try do
          case msg.messageAddOnExpiryType do
            nil ->
              acc

            _ ->
              [
                acc,
                "H",
                msg.messageAddOnExpiryType
                |> WAWebProtobufsE2E.MessageContextInfo.MessageAddonExpiryType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageAddOnExpiryType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageAssociation(acc, msg) do
        try do
          case msg.messageAssociation do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_message(msg.messageAssociation)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageAssociation, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_capiCreatedGroup(acc, msg) do
        try do
          case msg.capiCreatedGroup do
            nil -> acc
            _ -> [acc, "X", Protox.Encode.encode_bool(msg.capiCreatedGroup)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:capiCreatedGroup, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_supportPayload(acc, msg) do
        try do
          case msg.supportPayload do
            nil -> acc
            _ -> [acc, "b", Protox.Encode.encode_string(msg.supportPayload)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:supportPayload, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_limitSharing(acc, msg) do
        try do
          case msg.limitSharing do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_message(msg.limitSharing)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:limitSharing, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_limitSharingV2(acc, msg) do
        try do
          case msg.limitSharingV2 do
            nil -> acc
            _ -> [acc, "r", Protox.Encode.encode_message(msg.limitSharingV2)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:limitSharingV2, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_threadID(acc, msg) do
        try do
          case msg.threadID do
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
            reraise Protox.EncodingError.new(:threadID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_weblinkRenderConfig(acc, msg) do
        try do
          case msg.weblinkRenderConfig do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x80\x01",
                msg.weblinkRenderConfig
                |> WAWebProtobufsE2E.WebLinkRenderConfig.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:weblinkRenderConfig, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_teeBotMetadata(acc, msg) do
        try do
          case msg.teeBotMetadata do
            nil -> acc
            _ -> [acc, "\x8A\x01", Protox.Encode.encode_bytes(msg.teeBotMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:teeBotMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_accountEncryptionAttestation(acc, msg) do
        try do
          case msg.accountEncryptionAttestation do
            nil -> acc
            _ -> [acc, "\x92\x01", Protox.Encode.encode_message(msg.accountEncryptionAttestation)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :accountEncryptionAttestation,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_associatedPrimaryIdentityKey(acc, msg) do
        try do
          case msg.associatedPrimaryIdentityKey do
            nil -> acc
            _ -> [acc, "\x9A\x01", Protox.Encode.encode_bytes(msg.associatedPrimaryIdentityKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :associatedPrimaryIdentityKey,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_teeContextAnchorMessageID(acc, msg) do
        try do
          case msg.teeContextAnchorMessageID do
            nil -> acc
            _ -> [acc, "\xA2\x01", Protox.Encode.encode_string(msg.teeContextAnchorMessageID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:teeContextAnchorMessageID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_acp2Setting(acc, msg) do
        try do
          case msg.acp2Setting do
            nil -> acc
            _ -> [acc, "\xAA\x01", Protox.Encode.encode_message(msg.acp2Setting)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:acp2Setting, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.MessageContextInfo))
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

              {[
                 deviceListMetadata:
                   Protox.MergeMessage.merge(
                     msg.deviceListMetadata,
                     WAWebProtobufsE2E.DeviceListMetadata.decode!(delimited)
                   )
               ], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[deviceListMetadataVersion: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[messageSecret: delimited], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[paddingBytes: delimited], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[messageAddOnDurationInSecs: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[botMessageSecret: delimited], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 botMetadata:
                   Protox.MergeMessage.merge(
                     msg.botMetadata,
                     WAWebProtobufsAICommon.BotMetadata.decode!(delimited)
                   )
               ], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[reportingTokenVersion: value], rest}

            {9, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.MessageContextInfo.MessageAddonExpiryType
                )

              {[messageAddOnExpiryType: value], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 messageAssociation:
                   Protox.MergeMessage.merge(
                     msg.messageAssociation,
                     WAWebProtobufsE2E.MessageAssociation.decode!(delimited)
                   )
               ], rest}

            {11, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[capiCreatedGroup: value], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[supportPayload: Protox.Decode.validate_string!(delimited)], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 limitSharing:
                   Protox.MergeMessage.merge(
                     msg.limitSharing,
                     WACommon.LimitSharing.decode!(delimited)
                   )
               ], rest}

            {14, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 limitSharingV2:
                   Protox.MergeMessage.merge(
                     msg.limitSharingV2,
                     WACommon.LimitSharing.decode!(delimited)
                   )
               ], rest}

            {15, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[threadID: msg.threadID ++ [WAWebProtobufsE2E.ThreadID.decode!(delimited)]], rest}

            {16, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.WebLinkRenderConfig)

              {[weblinkRenderConfig: value], rest}

            {17, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[teeBotMetadata: delimited], rest}

            {18, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 accountEncryptionAttestation:
                   Protox.MergeMessage.merge(
                     msg.accountEncryptionAttestation,
                     WAWebProtobufsAea.NonE2EEAttestation.decode!(delimited)
                   )
               ], rest}

            {19, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[associatedPrimaryIdentityKey: delimited], rest}

            {20, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[teeContextAnchorMessageID: Protox.Decode.validate_string!(delimited)], rest}

            {21, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 acp2Setting:
                   Protox.MergeMessage.merge(
                     msg.acp2Setting,
                     WACommon.ACP2Setting.decode!(delimited)
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
        WAWebProtobufsE2E.MessageContextInfo,
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
          {:deviceListMetadata, {:scalar, nil}, {:message, WAWebProtobufsE2E.DeviceListMetadata}},
        2 => {:deviceListMetadataVersion, {:scalar, 0}, :int32},
        3 => {:messageSecret, {:scalar, ""}, :bytes},
        4 => {:paddingBytes, {:scalar, ""}, :bytes},
        5 => {:messageAddOnDurationInSecs, {:scalar, 0}, :uint32},
        6 => {:botMessageSecret, {:scalar, ""}, :bytes},
        7 => {:botMetadata, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotMetadata}},
        8 => {:reportingTokenVersion, {:scalar, 0}, :int32},
        9 =>
          {:messageAddOnExpiryType, {:scalar, :STATIC},
           {:enum, WAWebProtobufsE2E.MessageContextInfo.MessageAddonExpiryType}},
        10 =>
          {:messageAssociation, {:scalar, nil}, {:message, WAWebProtobufsE2E.MessageAssociation}},
        11 => {:capiCreatedGroup, {:scalar, false}, :bool},
        12 => {:supportPayload, {:scalar, ""}, :string},
        13 => {:limitSharing, {:scalar, nil}, {:message, WACommon.LimitSharing}},
        14 => {:limitSharingV2, {:scalar, nil}, {:message, WACommon.LimitSharing}},
        15 => {:threadID, :unpacked, {:message, WAWebProtobufsE2E.ThreadID}},
        16 =>
          {:weblinkRenderConfig, {:scalar, :WEBVIEW},
           {:enum, WAWebProtobufsE2E.WebLinkRenderConfig}},
        17 => {:teeBotMetadata, {:scalar, ""}, :bytes},
        18 =>
          {:accountEncryptionAttestation, {:scalar, nil},
           {:message, WAWebProtobufsAea.NonE2EEAttestation}},
        19 => {:associatedPrimaryIdentityKey, {:scalar, ""}, :bytes},
        20 => {:teeContextAnchorMessageID, {:scalar, ""}, :string},
        21 => {:acp2Setting, {:scalar, nil}, {:message, WACommon.ACP2Setting}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        accountEncryptionAttestation:
          {18, {:scalar, nil}, {:message, WAWebProtobufsAea.NonE2EEAttestation}},
        acp2Setting: {21, {:scalar, nil}, {:message, WACommon.ACP2Setting}},
        associatedPrimaryIdentityKey: {19, {:scalar, ""}, :bytes},
        botMessageSecret: {6, {:scalar, ""}, :bytes},
        botMetadata: {7, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotMetadata}},
        capiCreatedGroup: {11, {:scalar, false}, :bool},
        deviceListMetadata: {1, {:scalar, nil}, {:message, WAWebProtobufsE2E.DeviceListMetadata}},
        deviceListMetadataVersion: {2, {:scalar, 0}, :int32},
        limitSharing: {13, {:scalar, nil}, {:message, WACommon.LimitSharing}},
        limitSharingV2: {14, {:scalar, nil}, {:message, WACommon.LimitSharing}},
        messageAddOnDurationInSecs: {5, {:scalar, 0}, :uint32},
        messageAddOnExpiryType:
          {9, {:scalar, :STATIC},
           {:enum, WAWebProtobufsE2E.MessageContextInfo.MessageAddonExpiryType}},
        messageAssociation:
          {10, {:scalar, nil}, {:message, WAWebProtobufsE2E.MessageAssociation}},
        messageSecret: {3, {:scalar, ""}, :bytes},
        paddingBytes: {4, {:scalar, ""}, :bytes},
        reportingTokenVersion: {8, {:scalar, 0}, :int32},
        supportPayload: {12, {:scalar, ""}, :string},
        teeBotMetadata: {17, {:scalar, ""}, :bytes},
        teeContextAnchorMessageID: {20, {:scalar, ""}, :string},
        threadID: {15, :unpacked, {:message, WAWebProtobufsE2E.ThreadID}},
        weblinkRenderConfig:
          {16, {:scalar, :WEBVIEW}, {:enum, WAWebProtobufsE2E.WebLinkRenderConfig}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "deviceListMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :deviceListMetadata,
          tag: 1,
          type: {:message, WAWebProtobufsE2E.DeviceListMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "deviceListMetadataVersion",
          kind: {:scalar, 0},
          label: :optional,
          name: :deviceListMetadataVersion,
          tag: 2,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageSecret",
          kind: {:scalar, ""},
          label: :optional,
          name: :messageSecret,
          tag: 3,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "paddingBytes",
          kind: {:scalar, ""},
          label: :optional,
          name: :paddingBytes,
          tag: 4,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageAddOnDurationInSecs",
          kind: {:scalar, 0},
          label: :optional,
          name: :messageAddOnDurationInSecs,
          tag: 5,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "botMessageSecret",
          kind: {:scalar, ""},
          label: :optional,
          name: :botMessageSecret,
          tag: 6,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "botMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :botMetadata,
          tag: 7,
          type: {:message, WAWebProtobufsAICommon.BotMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "reportingTokenVersion",
          kind: {:scalar, 0},
          label: :optional,
          name: :reportingTokenVersion,
          tag: 8,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageAddOnExpiryType",
          kind: {:scalar, :STATIC},
          label: :optional,
          name: :messageAddOnExpiryType,
          tag: 9,
          type: {:enum, WAWebProtobufsE2E.MessageContextInfo.MessageAddonExpiryType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageAssociation",
          kind: {:scalar, nil},
          label: :optional,
          name: :messageAssociation,
          tag: 10,
          type: {:message, WAWebProtobufsE2E.MessageAssociation}
        },
        %{
          __struct__: Protox.Field,
          json_name: "capiCreatedGroup",
          kind: {:scalar, false},
          label: :optional,
          name: :capiCreatedGroup,
          tag: 11,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "supportPayload",
          kind: {:scalar, ""},
          label: :optional,
          name: :supportPayload,
          tag: 12,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "limitSharing",
          kind: {:scalar, nil},
          label: :optional,
          name: :limitSharing,
          tag: 13,
          type: {:message, WACommon.LimitSharing}
        },
        %{
          __struct__: Protox.Field,
          json_name: "limitSharingV2",
          kind: {:scalar, nil},
          label: :optional,
          name: :limitSharingV2,
          tag: 14,
          type: {:message, WACommon.LimitSharing}
        },
        %{
          __struct__: Protox.Field,
          json_name: "threadID",
          kind: :unpacked,
          label: :repeated,
          name: :threadID,
          tag: 15,
          type: {:message, WAWebProtobufsE2E.ThreadID}
        },
        %{
          __struct__: Protox.Field,
          json_name: "weblinkRenderConfig",
          kind: {:scalar, :WEBVIEW},
          label: :optional,
          name: :weblinkRenderConfig,
          tag: 16,
          type: {:enum, WAWebProtobufsE2E.WebLinkRenderConfig}
        },
        %{
          __struct__: Protox.Field,
          json_name: "teeBotMetadata",
          kind: {:scalar, ""},
          label: :optional,
          name: :teeBotMetadata,
          tag: 17,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "accountEncryptionAttestation",
          kind: {:scalar, nil},
          label: :optional,
          name: :accountEncryptionAttestation,
          tag: 18,
          type: {:message, WAWebProtobufsAea.NonE2EEAttestation}
        },
        %{
          __struct__: Protox.Field,
          json_name: "associatedPrimaryIdentityKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :associatedPrimaryIdentityKey,
          tag: 19,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "teeContextAnchorMessageID",
          kind: {:scalar, ""},
          label: :optional,
          name: :teeContextAnchorMessageID,
          tag: 20,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "acp2Setting",
          kind: {:scalar, nil},
          label: :optional,
          name: :acp2Setting,
          tag: 21,
          type: {:message, WACommon.ACP2Setting}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:deviceListMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceListMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :deviceListMetadata,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.DeviceListMetadata}
           }}
        end

        def field_def("deviceListMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceListMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :deviceListMetadata,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.DeviceListMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:deviceListMetadataVersion) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceListMetadataVersion",
             kind: {:scalar, 0},
             label: :optional,
             name: :deviceListMetadataVersion,
             tag: 2,
             type: :int32
           }}
        end

        def field_def("deviceListMetadataVersion") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceListMetadataVersion",
             kind: {:scalar, 0},
             label: :optional,
             name: :deviceListMetadataVersion,
             tag: 2,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:messageSecret) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageSecret",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageSecret,
             tag: 3,
             type: :bytes
           }}
        end

        def field_def("messageSecret") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageSecret",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageSecret,
             tag: 3,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:paddingBytes) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paddingBytes",
             kind: {:scalar, ""},
             label: :optional,
             name: :paddingBytes,
             tag: 4,
             type: :bytes
           }}
        end

        def field_def("paddingBytes") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paddingBytes",
             kind: {:scalar, ""},
             label: :optional,
             name: :paddingBytes,
             tag: 4,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:messageAddOnDurationInSecs) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageAddOnDurationInSecs",
             kind: {:scalar, 0},
             label: :optional,
             name: :messageAddOnDurationInSecs,
             tag: 5,
             type: :uint32
           }}
        end

        def field_def("messageAddOnDurationInSecs") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageAddOnDurationInSecs",
             kind: {:scalar, 0},
             label: :optional,
             name: :messageAddOnDurationInSecs,
             tag: 5,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:botMessageSecret) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botMessageSecret",
             kind: {:scalar, ""},
             label: :optional,
             name: :botMessageSecret,
             tag: 6,
             type: :bytes
           }}
        end

        def field_def("botMessageSecret") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botMessageSecret",
             kind: {:scalar, ""},
             label: :optional,
             name: :botMessageSecret,
             tag: 6,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:botMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botMetadata,
             tag: 7,
             type: {:message, WAWebProtobufsAICommon.BotMetadata}
           }}
        end

        def field_def("botMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "botMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :botMetadata,
             tag: 7,
             type: {:message, WAWebProtobufsAICommon.BotMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:reportingTokenVersion) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reportingTokenVersion",
             kind: {:scalar, 0},
             label: :optional,
             name: :reportingTokenVersion,
             tag: 8,
             type: :int32
           }}
        end

        def field_def("reportingTokenVersion") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reportingTokenVersion",
             kind: {:scalar, 0},
             label: :optional,
             name: :reportingTokenVersion,
             tag: 8,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:messageAddOnExpiryType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageAddOnExpiryType",
             kind: {:scalar, :STATIC},
             label: :optional,
             name: :messageAddOnExpiryType,
             tag: 9,
             type: {:enum, WAWebProtobufsE2E.MessageContextInfo.MessageAddonExpiryType}
           }}
        end

        def field_def("messageAddOnExpiryType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageAddOnExpiryType",
             kind: {:scalar, :STATIC},
             label: :optional,
             name: :messageAddOnExpiryType,
             tag: 9,
             type: {:enum, WAWebProtobufsE2E.MessageContextInfo.MessageAddonExpiryType}
           }}
        end

        []
      ),
      (
        def field_def(:messageAssociation) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageAssociation",
             kind: {:scalar, nil},
             label: :optional,
             name: :messageAssociation,
             tag: 10,
             type: {:message, WAWebProtobufsE2E.MessageAssociation}
           }}
        end

        def field_def("messageAssociation") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageAssociation",
             kind: {:scalar, nil},
             label: :optional,
             name: :messageAssociation,
             tag: 10,
             type: {:message, WAWebProtobufsE2E.MessageAssociation}
           }}
        end

        []
      ),
      (
        def field_def(:capiCreatedGroup) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "capiCreatedGroup",
             kind: {:scalar, false},
             label: :optional,
             name: :capiCreatedGroup,
             tag: 11,
             type: :bool
           }}
        end

        def field_def("capiCreatedGroup") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "capiCreatedGroup",
             kind: {:scalar, false},
             label: :optional,
             name: :capiCreatedGroup,
             tag: 11,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:supportPayload) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportPayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :supportPayload,
             tag: 12,
             type: :string
           }}
        end

        def field_def("supportPayload") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "supportPayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :supportPayload,
             tag: 12,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:limitSharing) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharing",
             kind: {:scalar, nil},
             label: :optional,
             name: :limitSharing,
             tag: 13,
             type: {:message, WACommon.LimitSharing}
           }}
        end

        def field_def("limitSharing") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharing",
             kind: {:scalar, nil},
             label: :optional,
             name: :limitSharing,
             tag: 13,
             type: {:message, WACommon.LimitSharing}
           }}
        end

        []
      ),
      (
        def field_def(:limitSharingV2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharingV2",
             kind: {:scalar, nil},
             label: :optional,
             name: :limitSharingV2,
             tag: 14,
             type: {:message, WACommon.LimitSharing}
           }}
        end

        def field_def("limitSharingV2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharingV2",
             kind: {:scalar, nil},
             label: :optional,
             name: :limitSharingV2,
             tag: 14,
             type: {:message, WACommon.LimitSharing}
           }}
        end

        []
      ),
      (
        def field_def(:threadID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "threadID",
             kind: :unpacked,
             label: :repeated,
             name: :threadID,
             tag: 15,
             type: {:message, WAWebProtobufsE2E.ThreadID}
           }}
        end

        def field_def("threadID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "threadID",
             kind: :unpacked,
             label: :repeated,
             name: :threadID,
             tag: 15,
             type: {:message, WAWebProtobufsE2E.ThreadID}
           }}
        end

        []
      ),
      (
        def field_def(:weblinkRenderConfig) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "weblinkRenderConfig",
             kind: {:scalar, :WEBVIEW},
             label: :optional,
             name: :weblinkRenderConfig,
             tag: 16,
             type: {:enum, WAWebProtobufsE2E.WebLinkRenderConfig}
           }}
        end

        def field_def("weblinkRenderConfig") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "weblinkRenderConfig",
             kind: {:scalar, :WEBVIEW},
             label: :optional,
             name: :weblinkRenderConfig,
             tag: 16,
             type: {:enum, WAWebProtobufsE2E.WebLinkRenderConfig}
           }}
        end

        []
      ),
      (
        def field_def(:teeBotMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "teeBotMetadata",
             kind: {:scalar, ""},
             label: :optional,
             name: :teeBotMetadata,
             tag: 17,
             type: :bytes
           }}
        end

        def field_def("teeBotMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "teeBotMetadata",
             kind: {:scalar, ""},
             label: :optional,
             name: :teeBotMetadata,
             tag: 17,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:accountEncryptionAttestation) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accountEncryptionAttestation",
             kind: {:scalar, nil},
             label: :optional,
             name: :accountEncryptionAttestation,
             tag: 18,
             type: {:message, WAWebProtobufsAea.NonE2EEAttestation}
           }}
        end

        def field_def("accountEncryptionAttestation") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accountEncryptionAttestation",
             kind: {:scalar, nil},
             label: :optional,
             name: :accountEncryptionAttestation,
             tag: 18,
             type: {:message, WAWebProtobufsAea.NonE2EEAttestation}
           }}
        end

        []
      ),
      (
        def field_def(:associatedPrimaryIdentityKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "associatedPrimaryIdentityKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :associatedPrimaryIdentityKey,
             tag: 19,
             type: :bytes
           }}
        end

        def field_def("associatedPrimaryIdentityKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "associatedPrimaryIdentityKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :associatedPrimaryIdentityKey,
             tag: 19,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:teeContextAnchorMessageID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "teeContextAnchorMessageID",
             kind: {:scalar, ""},
             label: :optional,
             name: :teeContextAnchorMessageID,
             tag: 20,
             type: :string
           }}
        end

        def field_def("teeContextAnchorMessageID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "teeContextAnchorMessageID",
             kind: {:scalar, ""},
             label: :optional,
             name: :teeContextAnchorMessageID,
             tag: 20,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:acp2Setting) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "acp2Setting",
             kind: {:scalar, nil},
             label: :optional,
             name: :acp2Setting,
             tag: 21,
             type: {:message, WACommon.ACP2Setting}
           }}
        end

        def field_def("acp2Setting") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "acp2Setting",
             kind: {:scalar, nil},
             label: :optional,
             name: :acp2Setting,
             tag: 21,
             type: {:message, WACommon.ACP2Setting}
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
    def default(:deviceListMetadata) do
      {:ok, nil}
    end,
    def default(:deviceListMetadataVersion) do
      {:ok, 0}
    end,
    def default(:messageSecret) do
      {:ok, ""}
    end,
    def default(:paddingBytes) do
      {:ok, ""}
    end,
    def default(:messageAddOnDurationInSecs) do
      {:ok, 0}
    end,
    def default(:botMessageSecret) do
      {:ok, ""}
    end,
    def default(:botMetadata) do
      {:ok, nil}
    end,
    def default(:reportingTokenVersion) do
      {:ok, 0}
    end,
    def default(:messageAddOnExpiryType) do
      {:ok, :STATIC}
    end,
    def default(:messageAssociation) do
      {:ok, nil}
    end,
    def default(:capiCreatedGroup) do
      {:ok, false}
    end,
    def default(:supportPayload) do
      {:ok, ""}
    end,
    def default(:limitSharing) do
      {:ok, nil}
    end,
    def default(:limitSharingV2) do
      {:ok, nil}
    end,
    def default(:threadID) do
      {:error, :no_default_value}
    end,
    def default(:weblinkRenderConfig) do
      {:ok, :WEBVIEW}
    end,
    def default(:teeBotMetadata) do
      {:ok, ""}
    end,
    def default(:accountEncryptionAttestation) do
      {:ok, nil}
    end,
    def default(:associatedPrimaryIdentityKey) do
      {:ok, ""}
    end,
    def default(:teeContextAnchorMessageID) do
      {:ok, ""}
    end,
    def default(:acp2Setting) do
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
