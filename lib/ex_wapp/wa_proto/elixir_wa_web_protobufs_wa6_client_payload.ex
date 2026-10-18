# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload do
  @moduledoc false
  defstruct username: nil,
            passive: nil,
            userAgent: nil,
            webInfo: nil,
            pushName: nil,
            sessionID: nil,
            shortConnect: nil,
            connectType: nil,
            connectReason: nil,
            shards: [],
            dnsSource: nil,
            connectAttemptCount: nil,
            device: nil,
            devicePairingData: nil,
            product: nil,
            fbCat: nil,
            fbUserAgent: nil,
            oc: nil,
            lc: nil,
            iosAppExtension: nil,
            fbAppID: nil,
            fbDeviceID: nil,
            pull: nil,
            paddingBytes: nil,
            yearClass: nil,
            memClass: nil,
            interopData: nil,
            trafficAnonymization: nil,
            lidDbMigrated: nil,
            accountType: nil,
            connectionSequenceInfo: nil,
            paaLink: nil,
            preacksCount: nil,
            processingQueueSize: nil,
            pairedPeripherals: [],
            testIsolationID: nil,
            messageSts: nil,
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
        |> encode_username(msg)
        |> encode_passive(msg)
        |> encode_userAgent(msg)
        |> encode_webInfo(msg)
        |> encode_pushName(msg)
        |> encode_sessionID(msg)
        |> encode_shortConnect(msg)
        |> encode_connectType(msg)
        |> encode_connectReason(msg)
        |> encode_shards(msg)
        |> encode_dnsSource(msg)
        |> encode_connectAttemptCount(msg)
        |> encode_device(msg)
        |> encode_devicePairingData(msg)
        |> encode_product(msg)
        |> encode_fbCat(msg)
        |> encode_fbUserAgent(msg)
        |> encode_oc(msg)
        |> encode_lc(msg)
        |> encode_iosAppExtension(msg)
        |> encode_fbAppID(msg)
        |> encode_fbDeviceID(msg)
        |> encode_pull(msg)
        |> encode_paddingBytes(msg)
        |> encode_yearClass(msg)
        |> encode_memClass(msg)
        |> encode_interopData(msg)
        |> encode_trafficAnonymization(msg)
        |> encode_lidDbMigrated(msg)
        |> encode_accountType(msg)
        |> encode_connectionSequenceInfo(msg)
        |> encode_paaLink(msg)
        |> encode_preacksCount(msg)
        |> encode_processingQueueSize(msg)
        |> encode_pairedPeripherals(msg)
        |> encode_testIsolationID(msg)
        |> encode_messageSts(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_username(acc, msg) do
        try do
          case msg.username do
            nil -> acc
            _ -> [acc, "\b", Protox.Encode.encode_uint64(msg.username)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:username, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_passive(acc, msg) do
        try do
          case msg.passive do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_bool(msg.passive)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:passive, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_userAgent(acc, msg) do
        try do
          case msg.userAgent do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_message(msg.userAgent)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:userAgent, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_webInfo(acc, msg) do
        try do
          case msg.webInfo do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_message(msg.webInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:webInfo, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pushName(acc, msg) do
        try do
          case msg.pushName do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.pushName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pushName, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_sessionID(acc, msg) do
        try do
          case msg.sessionID do
            nil -> acc
            _ -> [acc, "M", Protox.Encode.encode_sfixed32(msg.sessionID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:sessionID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_shortConnect(acc, msg) do
        try do
          case msg.shortConnect do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_bool(msg.shortConnect)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:shortConnect, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_connectType(acc, msg) do
        try do
          case msg.connectType do
            nil ->
              acc

            _ ->
              [
                acc,
                "`",
                msg.connectType
                |> WAWebProtobufsWa6.ClientPayload.ConnectType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:connectType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_connectReason(acc, msg) do
        try do
          case msg.connectReason do
            nil ->
              acc

            _ ->
              [
                acc,
                "h",
                msg.connectReason
                |> WAWebProtobufsWa6.ClientPayload.ConnectReason.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:connectReason, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_shards(acc, msg) do
        try do
          case msg.shards do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "p", Protox.Encode.encode_int32(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:shards, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_dnsSource(acc, msg) do
        try do
          case msg.dnsSource do
            nil -> acc
            _ -> [acc, "z", Protox.Encode.encode_message(msg.dnsSource)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:dnsSource, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_connectAttemptCount(acc, msg) do
        try do
          case msg.connectAttemptCount do
            nil -> acc
            _ -> [acc, "\x80\x01", Protox.Encode.encode_uint32(msg.connectAttemptCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:connectAttemptCount, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_device(acc, msg) do
        try do
          case msg.device do
            nil -> acc
            _ -> [acc, "\x90\x01", Protox.Encode.encode_uint32(msg.device)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:device, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_devicePairingData(acc, msg) do
        try do
          case msg.devicePairingData do
            nil -> acc
            _ -> [acc, "\x9A\x01", Protox.Encode.encode_message(msg.devicePairingData)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:devicePairingData, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_product(acc, msg) do
        try do
          case msg.product do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xA0\x01",
                msg.product
                |> WAWebProtobufsWa6.ClientPayload.Product.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:product, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fbCat(acc, msg) do
        try do
          case msg.fbCat do
            nil -> acc
            _ -> [acc, "\xAA\x01", Protox.Encode.encode_bytes(msg.fbCat)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fbCat, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fbUserAgent(acc, msg) do
        try do
          case msg.fbUserAgent do
            nil -> acc
            _ -> [acc, "\xB2\x01", Protox.Encode.encode_bytes(msg.fbUserAgent)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fbUserAgent, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_oc(acc, msg) do
        try do
          case msg.oc do
            nil -> acc
            _ -> [acc, "\xB8\x01", Protox.Encode.encode_bool(msg.oc)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:oc, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_lc(acc, msg) do
        try do
          case msg.lc do
            nil -> acc
            _ -> [acc, "\xC0\x01", Protox.Encode.encode_int32(msg.lc)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lc, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_iosAppExtension(acc, msg) do
        try do
          case msg.iosAppExtension do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xF0\x01",
                msg.iosAppExtension
                |> WAWebProtobufsWa6.ClientPayload.IOSAppExtension.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:iosAppExtension, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_fbAppID(acc, msg) do
        try do
          case msg.fbAppID do
            nil -> acc
            _ -> [acc, "\xF8\x01", Protox.Encode.encode_uint64(msg.fbAppID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fbAppID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fbDeviceID(acc, msg) do
        try do
          case msg.fbDeviceID do
            nil -> acc
            _ -> [acc, "\x82\x02", Protox.Encode.encode_bytes(msg.fbDeviceID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fbDeviceID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pull(acc, msg) do
        try do
          case msg.pull do
            nil -> acc
            _ -> [acc, "\x88\x02", Protox.Encode.encode_bool(msg.pull)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pull, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_paddingBytes(acc, msg) do
        try do
          case msg.paddingBytes do
            nil -> acc
            _ -> [acc, "\x92\x02", Protox.Encode.encode_bytes(msg.paddingBytes)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:paddingBytes, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_yearClass(acc, msg) do
        try do
          case msg.yearClass do
            nil -> acc
            _ -> [acc, "\xA0\x02", Protox.Encode.encode_int32(msg.yearClass)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:yearClass, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_memClass(acc, msg) do
        try do
          case msg.memClass do
            nil -> acc
            _ -> [acc, "\xA8\x02", Protox.Encode.encode_int32(msg.memClass)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:memClass, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_interopData(acc, msg) do
        try do
          case msg.interopData do
            nil -> acc
            _ -> [acc, "\xB2\x02", Protox.Encode.encode_message(msg.interopData)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:interopData, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_trafficAnonymization(acc, msg) do
        try do
          case msg.trafficAnonymization do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xC0\x02",
                msg.trafficAnonymization
                |> WAWebProtobufsWa6.ClientPayload.TrafficAnonymization.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:trafficAnonymization, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_lidDbMigrated(acc, msg) do
        try do
          case msg.lidDbMigrated do
            nil -> acc
            _ -> [acc, "\xC8\x02", Protox.Encode.encode_bool(msg.lidDbMigrated)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lidDbMigrated, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_accountType(acc, msg) do
        try do
          case msg.accountType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xD0\x02",
                msg.accountType
                |> WAWebProtobufsWa6.ClientPayload.AccountType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:accountType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_connectionSequenceInfo(acc, msg) do
        try do
          case msg.connectionSequenceInfo do
            nil -> acc
            _ -> [acc, "\xDD\x02", Protox.Encode.encode_sfixed32(msg.connectionSequenceInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:connectionSequenceInfo, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_paaLink(acc, msg) do
        try do
          case msg.paaLink do
            nil -> acc
            _ -> [acc, "\xE0\x02", Protox.Encode.encode_bool(msg.paaLink)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:paaLink, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_preacksCount(acc, msg) do
        try do
          case msg.preacksCount do
            nil -> acc
            _ -> [acc, "\xE8\x02", Protox.Encode.encode_int32(msg.preacksCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:preacksCount, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_processingQueueSize(acc, msg) do
        try do
          case msg.processingQueueSize do
            nil -> acc
            _ -> [acc, "\xF0\x02", Protox.Encode.encode_int32(msg.processingQueueSize)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:processingQueueSize, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pairedPeripherals(acc, msg) do
        try do
          case msg.pairedPeripherals do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xFA\x02", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pairedPeripherals, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_testIsolationID(acc, msg) do
        try do
          case msg.testIsolationID do
            nil -> acc
            _ -> [acc, "\x82\x03", Protox.Encode.encode_bytes(msg.testIsolationID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:testIsolationID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageSts(acc, msg) do
        try do
          case msg.messageSts do
            nil -> acc
            _ -> [acc, "\x88\x03", Protox.Encode.encode_int64(msg.messageSts)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageSts, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsWa6.ClientPayload))
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
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[username: value], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[passive: value], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 userAgent:
                   Protox.MergeMessage.merge(
                     msg.userAgent,
                     WAWebProtobufsWa6.ClientPayload.UserAgent.decode!(delimited)
                   )
               ], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 webInfo:
                   Protox.MergeMessage.merge(
                     msg.webInfo,
                     WAWebProtobufsWa6.ClientPayload.WebInfo.decode!(delimited)
                   )
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[pushName: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_sfixed32(bytes)
              {[sessionID: value], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[shortConnect: value], rest}

            {12, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsWa6.ClientPayload.ConnectType)

              {[connectType: value], rest}

            {13, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsWa6.ClientPayload.ConnectReason)

              {[connectReason: value], rest}

            {14, 2, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[shards: msg.shards ++ Protox.Decode.parse_repeated_int32([], delimited)], rest}

            {14, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[shards: msg.shards ++ [value]], rest}

            {15, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 dnsSource:
                   Protox.MergeMessage.merge(
                     msg.dnsSource,
                     WAWebProtobufsWa6.ClientPayload.DNSSource.decode!(delimited)
                   )
               ], rest}

            {16, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[connectAttemptCount: value], rest}

            {18, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[device: value], rest}

            {19, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 devicePairingData:
                   Protox.MergeMessage.merge(
                     msg.devicePairingData,
                     WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData.decode!(
                       delimited
                     )
                   )
               ], rest}

            {20, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsWa6.ClientPayload.Product)

              {[product: value], rest}

            {21, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fbCat: delimited], rest}

            {22, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fbUserAgent: delimited], rest}

            {23, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[oc: value], rest}

            {24, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[lc: value], rest}

            {30, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsWa6.ClientPayload.IOSAppExtension)

              {[iosAppExtension: value], rest}

            {31, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[fbAppID: value], rest}

            {32, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fbDeviceID: delimited], rest}

            {33, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[pull: value], rest}

            {34, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[paddingBytes: delimited], rest}

            {36, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[yearClass: value], rest}

            {37, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[memClass: value], rest}

            {38, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 interopData:
                   Protox.MergeMessage.merge(
                     msg.interopData,
                     WAWebProtobufsWa6.ClientPayload.InteropData.decode!(delimited)
                   )
               ], rest}

            {40, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsWa6.ClientPayload.TrafficAnonymization
                )

              {[trafficAnonymization: value], rest}

            {41, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[lidDbMigrated: value], rest}

            {42, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsWa6.ClientPayload.AccountType)

              {[accountType: value], rest}

            {43, _, bytes} ->
              {value, rest} = Protox.Decode.parse_sfixed32(bytes)
              {[connectionSequenceInfo: value], rest}

            {44, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[paaLink: value], rest}

            {45, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[preacksCount: value], rest}

            {46, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[processingQueueSize: value], rest}

            {47, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 pairedPeripherals:
                   msg.pairedPeripherals ++ [Protox.Decode.validate_string!(delimited)]
               ], rest}

            {48, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[testIsolationID: delimited], rest}

            {49, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[messageSts: value], rest}

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
        WAWebProtobufsWa6.ClientPayload,
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
        1 => {:username, {:scalar, 0}, :uint64},
        3 => {:passive, {:scalar, false}, :bool},
        5 => {:userAgent, {:scalar, nil}, {:message, WAWebProtobufsWa6.ClientPayload.UserAgent}},
        6 => {:webInfo, {:scalar, nil}, {:message, WAWebProtobufsWa6.ClientPayload.WebInfo}},
        7 => {:pushName, {:scalar, ""}, :string},
        9 => {:sessionID, {:scalar, 0}, :sfixed32},
        10 => {:shortConnect, {:scalar, false}, :bool},
        12 =>
          {:connectType, {:scalar, :CELLULAR_UNKNOWN},
           {:enum, WAWebProtobufsWa6.ClientPayload.ConnectType}},
        13 =>
          {:connectReason, {:scalar, :PUSH},
           {:enum, WAWebProtobufsWa6.ClientPayload.ConnectReason}},
        14 => {:shards, :unpacked, :int32},
        15 => {:dnsSource, {:scalar, nil}, {:message, WAWebProtobufsWa6.ClientPayload.DNSSource}},
        16 => {:connectAttemptCount, {:scalar, 0}, :uint32},
        18 => {:device, {:scalar, 0}, :uint32},
        19 =>
          {:devicePairingData, {:scalar, nil},
           {:message, WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData}},
        20 => {:product, {:scalar, :WHATSAPP}, {:enum, WAWebProtobufsWa6.ClientPayload.Product}},
        21 => {:fbCat, {:scalar, ""}, :bytes},
        22 => {:fbUserAgent, {:scalar, ""}, :bytes},
        23 => {:oc, {:scalar, false}, :bool},
        24 => {:lc, {:scalar, 0}, :int32},
        30 =>
          {:iosAppExtension, {:scalar, :SHARE_EXTENSION},
           {:enum, WAWebProtobufsWa6.ClientPayload.IOSAppExtension}},
        31 => {:fbAppID, {:scalar, 0}, :uint64},
        32 => {:fbDeviceID, {:scalar, ""}, :bytes},
        33 => {:pull, {:scalar, false}, :bool},
        34 => {:paddingBytes, {:scalar, ""}, :bytes},
        36 => {:yearClass, {:scalar, 0}, :int32},
        37 => {:memClass, {:scalar, 0}, :int32},
        38 =>
          {:interopData, {:scalar, nil}, {:message, WAWebProtobufsWa6.ClientPayload.InteropData}},
        40 =>
          {:trafficAnonymization, {:scalar, :OFF},
           {:enum, WAWebProtobufsWa6.ClientPayload.TrafficAnonymization}},
        41 => {:lidDbMigrated, {:scalar, false}, :bool},
        42 =>
          {:accountType, {:scalar, :DEFAULT},
           {:enum, WAWebProtobufsWa6.ClientPayload.AccountType}},
        43 => {:connectionSequenceInfo, {:scalar, 0}, :sfixed32},
        44 => {:paaLink, {:scalar, false}, :bool},
        45 => {:preacksCount, {:scalar, 0}, :int32},
        46 => {:processingQueueSize, {:scalar, 0}, :int32},
        47 => {:pairedPeripherals, :unpacked, :string},
        48 => {:testIsolationID, {:scalar, ""}, :bytes},
        49 => {:messageSts, {:scalar, 0}, :int64}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        accountType:
          {42, {:scalar, :DEFAULT}, {:enum, WAWebProtobufsWa6.ClientPayload.AccountType}},
        connectAttemptCount: {16, {:scalar, 0}, :uint32},
        connectReason:
          {13, {:scalar, :PUSH}, {:enum, WAWebProtobufsWa6.ClientPayload.ConnectReason}},
        connectType:
          {12, {:scalar, :CELLULAR_UNKNOWN}, {:enum, WAWebProtobufsWa6.ClientPayload.ConnectType}},
        connectionSequenceInfo: {43, {:scalar, 0}, :sfixed32},
        device: {18, {:scalar, 0}, :uint32},
        devicePairingData:
          {19, {:scalar, nil},
           {:message, WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData}},
        dnsSource: {15, {:scalar, nil}, {:message, WAWebProtobufsWa6.ClientPayload.DNSSource}},
        fbAppID: {31, {:scalar, 0}, :uint64},
        fbCat: {21, {:scalar, ""}, :bytes},
        fbDeviceID: {32, {:scalar, ""}, :bytes},
        fbUserAgent: {22, {:scalar, ""}, :bytes},
        interopData:
          {38, {:scalar, nil}, {:message, WAWebProtobufsWa6.ClientPayload.InteropData}},
        iosAppExtension:
          {30, {:scalar, :SHARE_EXTENSION},
           {:enum, WAWebProtobufsWa6.ClientPayload.IOSAppExtension}},
        lc: {24, {:scalar, 0}, :int32},
        lidDbMigrated: {41, {:scalar, false}, :bool},
        memClass: {37, {:scalar, 0}, :int32},
        messageSts: {49, {:scalar, 0}, :int64},
        oc: {23, {:scalar, false}, :bool},
        paaLink: {44, {:scalar, false}, :bool},
        paddingBytes: {34, {:scalar, ""}, :bytes},
        pairedPeripherals: {47, :unpacked, :string},
        passive: {3, {:scalar, false}, :bool},
        preacksCount: {45, {:scalar, 0}, :int32},
        processingQueueSize: {46, {:scalar, 0}, :int32},
        product: {20, {:scalar, :WHATSAPP}, {:enum, WAWebProtobufsWa6.ClientPayload.Product}},
        pull: {33, {:scalar, false}, :bool},
        pushName: {7, {:scalar, ""}, :string},
        sessionID: {9, {:scalar, 0}, :sfixed32},
        shards: {14, :unpacked, :int32},
        shortConnect: {10, {:scalar, false}, :bool},
        testIsolationID: {48, {:scalar, ""}, :bytes},
        trafficAnonymization:
          {40, {:scalar, :OFF}, {:enum, WAWebProtobufsWa6.ClientPayload.TrafficAnonymization}},
        userAgent: {5, {:scalar, nil}, {:message, WAWebProtobufsWa6.ClientPayload.UserAgent}},
        username: {1, {:scalar, 0}, :uint64},
        webInfo: {6, {:scalar, nil}, {:message, WAWebProtobufsWa6.ClientPayload.WebInfo}},
        yearClass: {36, {:scalar, 0}, :int32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "username",
          kind: {:scalar, 0},
          label: :optional,
          name: :username,
          tag: 1,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "passive",
          kind: {:scalar, false},
          label: :optional,
          name: :passive,
          tag: 3,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "userAgent",
          kind: {:scalar, nil},
          label: :optional,
          name: :userAgent,
          tag: 5,
          type: {:message, WAWebProtobufsWa6.ClientPayload.UserAgent}
        },
        %{
          __struct__: Protox.Field,
          json_name: "webInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :webInfo,
          tag: 6,
          type: {:message, WAWebProtobufsWa6.ClientPayload.WebInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pushName",
          kind: {:scalar, ""},
          label: :optional,
          name: :pushName,
          tag: 7,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "sessionID",
          kind: {:scalar, 0},
          label: :optional,
          name: :sessionID,
          tag: 9,
          type: :sfixed32
        },
        %{
          __struct__: Protox.Field,
          json_name: "shortConnect",
          kind: {:scalar, false},
          label: :optional,
          name: :shortConnect,
          tag: 10,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "connectType",
          kind: {:scalar, :CELLULAR_UNKNOWN},
          label: :optional,
          name: :connectType,
          tag: 12,
          type: {:enum, WAWebProtobufsWa6.ClientPayload.ConnectType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "connectReason",
          kind: {:scalar, :PUSH},
          label: :optional,
          name: :connectReason,
          tag: 13,
          type: {:enum, WAWebProtobufsWa6.ClientPayload.ConnectReason}
        },
        %{
          __struct__: Protox.Field,
          json_name: "shards",
          kind: :unpacked,
          label: :repeated,
          name: :shards,
          tag: 14,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "dnsSource",
          kind: {:scalar, nil},
          label: :optional,
          name: :dnsSource,
          tag: 15,
          type: {:message, WAWebProtobufsWa6.ClientPayload.DNSSource}
        },
        %{
          __struct__: Protox.Field,
          json_name: "connectAttemptCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :connectAttemptCount,
          tag: 16,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "device",
          kind: {:scalar, 0},
          label: :optional,
          name: :device,
          tag: 18,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "devicePairingData",
          kind: {:scalar, nil},
          label: :optional,
          name: :devicePairingData,
          tag: 19,
          type: {:message, WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData}
        },
        %{
          __struct__: Protox.Field,
          json_name: "product",
          kind: {:scalar, :WHATSAPP},
          label: :optional,
          name: :product,
          tag: 20,
          type: {:enum, WAWebProtobufsWa6.ClientPayload.Product}
        },
        %{
          __struct__: Protox.Field,
          json_name: "fbCat",
          kind: {:scalar, ""},
          label: :optional,
          name: :fbCat,
          tag: 21,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "fbUserAgent",
          kind: {:scalar, ""},
          label: :optional,
          name: :fbUserAgent,
          tag: 22,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "oc",
          kind: {:scalar, false},
          label: :optional,
          name: :oc,
          tag: 23,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "lc",
          kind: {:scalar, 0},
          label: :optional,
          name: :lc,
          tag: 24,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "iosAppExtension",
          kind: {:scalar, :SHARE_EXTENSION},
          label: :optional,
          name: :iosAppExtension,
          tag: 30,
          type: {:enum, WAWebProtobufsWa6.ClientPayload.IOSAppExtension}
        },
        %{
          __struct__: Protox.Field,
          json_name: "fbAppID",
          kind: {:scalar, 0},
          label: :optional,
          name: :fbAppID,
          tag: 31,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "fbDeviceID",
          kind: {:scalar, ""},
          label: :optional,
          name: :fbDeviceID,
          tag: 32,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "pull",
          kind: {:scalar, false},
          label: :optional,
          name: :pull,
          tag: 33,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "paddingBytes",
          kind: {:scalar, ""},
          label: :optional,
          name: :paddingBytes,
          tag: 34,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "yearClass",
          kind: {:scalar, 0},
          label: :optional,
          name: :yearClass,
          tag: 36,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "memClass",
          kind: {:scalar, 0},
          label: :optional,
          name: :memClass,
          tag: 37,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "interopData",
          kind: {:scalar, nil},
          label: :optional,
          name: :interopData,
          tag: 38,
          type: {:message, WAWebProtobufsWa6.ClientPayload.InteropData}
        },
        %{
          __struct__: Protox.Field,
          json_name: "trafficAnonymization",
          kind: {:scalar, :OFF},
          label: :optional,
          name: :trafficAnonymization,
          tag: 40,
          type: {:enum, WAWebProtobufsWa6.ClientPayload.TrafficAnonymization}
        },
        %{
          __struct__: Protox.Field,
          json_name: "lidDbMigrated",
          kind: {:scalar, false},
          label: :optional,
          name: :lidDbMigrated,
          tag: 41,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "accountType",
          kind: {:scalar, :DEFAULT},
          label: :optional,
          name: :accountType,
          tag: 42,
          type: {:enum, WAWebProtobufsWa6.ClientPayload.AccountType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "connectionSequenceInfo",
          kind: {:scalar, 0},
          label: :optional,
          name: :connectionSequenceInfo,
          tag: 43,
          type: :sfixed32
        },
        %{
          __struct__: Protox.Field,
          json_name: "paaLink",
          kind: {:scalar, false},
          label: :optional,
          name: :paaLink,
          tag: 44,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "preacksCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :preacksCount,
          tag: 45,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "processingQueueSize",
          kind: {:scalar, 0},
          label: :optional,
          name: :processingQueueSize,
          tag: 46,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "pairedPeripherals",
          kind: :unpacked,
          label: :repeated,
          name: :pairedPeripherals,
          tag: 47,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "testIsolationID",
          kind: {:scalar, ""},
          label: :optional,
          name: :testIsolationID,
          tag: 48,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageSts",
          kind: {:scalar, 0},
          label: :optional,
          name: :messageSts,
          tag: 49,
          type: :int64
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:username) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "username",
             kind: {:scalar, 0},
             label: :optional,
             name: :username,
             tag: 1,
             type: :uint64
           }}
        end

        def field_def("username") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "username",
             kind: {:scalar, 0},
             label: :optional,
             name: :username,
             tag: 1,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:passive) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "passive",
             kind: {:scalar, false},
             label: :optional,
             name: :passive,
             tag: 3,
             type: :bool
           }}
        end

        def field_def("passive") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "passive",
             kind: {:scalar, false},
             label: :optional,
             name: :passive,
             tag: 3,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:userAgent) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "userAgent",
             kind: {:scalar, nil},
             label: :optional,
             name: :userAgent,
             tag: 5,
             type: {:message, WAWebProtobufsWa6.ClientPayload.UserAgent}
           }}
        end

        def field_def("userAgent") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "userAgent",
             kind: {:scalar, nil},
             label: :optional,
             name: :userAgent,
             tag: 5,
             type: {:message, WAWebProtobufsWa6.ClientPayload.UserAgent}
           }}
        end

        []
      ),
      (
        def field_def(:webInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "webInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :webInfo,
             tag: 6,
             type: {:message, WAWebProtobufsWa6.ClientPayload.WebInfo}
           }}
        end

        def field_def("webInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "webInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :webInfo,
             tag: 6,
             type: {:message, WAWebProtobufsWa6.ClientPayload.WebInfo}
           }}
        end

        []
      ),
      (
        def field_def(:pushName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pushName",
             kind: {:scalar, ""},
             label: :optional,
             name: :pushName,
             tag: 7,
             type: :string
           }}
        end

        def field_def("pushName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pushName",
             kind: {:scalar, ""},
             label: :optional,
             name: :pushName,
             tag: 7,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:sessionID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sessionID",
             kind: {:scalar, 0},
             label: :optional,
             name: :sessionID,
             tag: 9,
             type: :sfixed32
           }}
        end

        def field_def("sessionID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sessionID",
             kind: {:scalar, 0},
             label: :optional,
             name: :sessionID,
             tag: 9,
             type: :sfixed32
           }}
        end

        []
      ),
      (
        def field_def(:shortConnect) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shortConnect",
             kind: {:scalar, false},
             label: :optional,
             name: :shortConnect,
             tag: 10,
             type: :bool
           }}
        end

        def field_def("shortConnect") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shortConnect",
             kind: {:scalar, false},
             label: :optional,
             name: :shortConnect,
             tag: 10,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:connectType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "connectType",
             kind: {:scalar, :CELLULAR_UNKNOWN},
             label: :optional,
             name: :connectType,
             tag: 12,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.ConnectType}
           }}
        end

        def field_def("connectType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "connectType",
             kind: {:scalar, :CELLULAR_UNKNOWN},
             label: :optional,
             name: :connectType,
             tag: 12,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.ConnectType}
           }}
        end

        []
      ),
      (
        def field_def(:connectReason) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "connectReason",
             kind: {:scalar, :PUSH},
             label: :optional,
             name: :connectReason,
             tag: 13,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.ConnectReason}
           }}
        end

        def field_def("connectReason") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "connectReason",
             kind: {:scalar, :PUSH},
             label: :optional,
             name: :connectReason,
             tag: 13,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.ConnectReason}
           }}
        end

        []
      ),
      (
        def field_def(:shards) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shards",
             kind: :unpacked,
             label: :repeated,
             name: :shards,
             tag: 14,
             type: :int32
           }}
        end

        def field_def("shards") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shards",
             kind: :unpacked,
             label: :repeated,
             name: :shards,
             tag: 14,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:dnsSource) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "dnsSource",
             kind: {:scalar, nil},
             label: :optional,
             name: :dnsSource,
             tag: 15,
             type: {:message, WAWebProtobufsWa6.ClientPayload.DNSSource}
           }}
        end

        def field_def("dnsSource") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "dnsSource",
             kind: {:scalar, nil},
             label: :optional,
             name: :dnsSource,
             tag: 15,
             type: {:message, WAWebProtobufsWa6.ClientPayload.DNSSource}
           }}
        end

        []
      ),
      (
        def field_def(:connectAttemptCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "connectAttemptCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :connectAttemptCount,
             tag: 16,
             type: :uint32
           }}
        end

        def field_def("connectAttemptCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "connectAttemptCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :connectAttemptCount,
             tag: 16,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:device) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "device",
             kind: {:scalar, 0},
             label: :optional,
             name: :device,
             tag: 18,
             type: :uint32
           }}
        end

        def field_def("device") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "device",
             kind: {:scalar, 0},
             label: :optional,
             name: :device,
             tag: 18,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:devicePairingData) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "devicePairingData",
             kind: {:scalar, nil},
             label: :optional,
             name: :devicePairingData,
             tag: 19,
             type: {:message, WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData}
           }}
        end

        def field_def("devicePairingData") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "devicePairingData",
             kind: {:scalar, nil},
             label: :optional,
             name: :devicePairingData,
             tag: 19,
             type: {:message, WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData}
           }}
        end

        []
      ),
      (
        def field_def(:product) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "product",
             kind: {:scalar, :WHATSAPP},
             label: :optional,
             name: :product,
             tag: 20,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.Product}
           }}
        end

        def field_def("product") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "product",
             kind: {:scalar, :WHATSAPP},
             label: :optional,
             name: :product,
             tag: 20,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.Product}
           }}
        end

        []
      ),
      (
        def field_def(:fbCat) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fbCat",
             kind: {:scalar, ""},
             label: :optional,
             name: :fbCat,
             tag: 21,
             type: :bytes
           }}
        end

        def field_def("fbCat") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fbCat",
             kind: {:scalar, ""},
             label: :optional,
             name: :fbCat,
             tag: 21,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:fbUserAgent) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fbUserAgent",
             kind: {:scalar, ""},
             label: :optional,
             name: :fbUserAgent,
             tag: 22,
             type: :bytes
           }}
        end

        def field_def("fbUserAgent") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fbUserAgent",
             kind: {:scalar, ""},
             label: :optional,
             name: :fbUserAgent,
             tag: 22,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:oc) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oc",
             kind: {:scalar, false},
             label: :optional,
             name: :oc,
             tag: 23,
             type: :bool
           }}
        end

        def field_def("oc") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oc",
             kind: {:scalar, false},
             label: :optional,
             name: :oc,
             tag: 23,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:lc) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lc",
             kind: {:scalar, 0},
             label: :optional,
             name: :lc,
             tag: 24,
             type: :int32
           }}
        end

        def field_def("lc") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lc",
             kind: {:scalar, 0},
             label: :optional,
             name: :lc,
             tag: 24,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:iosAppExtension) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "iosAppExtension",
             kind: {:scalar, :SHARE_EXTENSION},
             label: :optional,
             name: :iosAppExtension,
             tag: 30,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.IOSAppExtension}
           }}
        end

        def field_def("iosAppExtension") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "iosAppExtension",
             kind: {:scalar, :SHARE_EXTENSION},
             label: :optional,
             name: :iosAppExtension,
             tag: 30,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.IOSAppExtension}
           }}
        end

        []
      ),
      (
        def field_def(:fbAppID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fbAppID",
             kind: {:scalar, 0},
             label: :optional,
             name: :fbAppID,
             tag: 31,
             type: :uint64
           }}
        end

        def field_def("fbAppID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fbAppID",
             kind: {:scalar, 0},
             label: :optional,
             name: :fbAppID,
             tag: 31,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:fbDeviceID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fbDeviceID",
             kind: {:scalar, ""},
             label: :optional,
             name: :fbDeviceID,
             tag: 32,
             type: :bytes
           }}
        end

        def field_def("fbDeviceID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fbDeviceID",
             kind: {:scalar, ""},
             label: :optional,
             name: :fbDeviceID,
             tag: 32,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:pull) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pull",
             kind: {:scalar, false},
             label: :optional,
             name: :pull,
             tag: 33,
             type: :bool
           }}
        end

        def field_def("pull") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pull",
             kind: {:scalar, false},
             label: :optional,
             name: :pull,
             tag: 33,
             type: :bool
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
             tag: 34,
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
             tag: 34,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:yearClass) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "yearClass",
             kind: {:scalar, 0},
             label: :optional,
             name: :yearClass,
             tag: 36,
             type: :int32
           }}
        end

        def field_def("yearClass") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "yearClass",
             kind: {:scalar, 0},
             label: :optional,
             name: :yearClass,
             tag: 36,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:memClass) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "memClass",
             kind: {:scalar, 0},
             label: :optional,
             name: :memClass,
             tag: 37,
             type: :int32
           }}
        end

        def field_def("memClass") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "memClass",
             kind: {:scalar, 0},
             label: :optional,
             name: :memClass,
             tag: 37,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:interopData) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interopData",
             kind: {:scalar, nil},
             label: :optional,
             name: :interopData,
             tag: 38,
             type: {:message, WAWebProtobufsWa6.ClientPayload.InteropData}
           }}
        end

        def field_def("interopData") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interopData",
             kind: {:scalar, nil},
             label: :optional,
             name: :interopData,
             tag: 38,
             type: {:message, WAWebProtobufsWa6.ClientPayload.InteropData}
           }}
        end

        []
      ),
      (
        def field_def(:trafficAnonymization) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "trafficAnonymization",
             kind: {:scalar, :OFF},
             label: :optional,
             name: :trafficAnonymization,
             tag: 40,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.TrafficAnonymization}
           }}
        end

        def field_def("trafficAnonymization") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "trafficAnonymization",
             kind: {:scalar, :OFF},
             label: :optional,
             name: :trafficAnonymization,
             tag: 40,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.TrafficAnonymization}
           }}
        end

        []
      ),
      (
        def field_def(:lidDbMigrated) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lidDbMigrated",
             kind: {:scalar, false},
             label: :optional,
             name: :lidDbMigrated,
             tag: 41,
             type: :bool
           }}
        end

        def field_def("lidDbMigrated") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lidDbMigrated",
             kind: {:scalar, false},
             label: :optional,
             name: :lidDbMigrated,
             tag: 41,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:accountType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accountType",
             kind: {:scalar, :DEFAULT},
             label: :optional,
             name: :accountType,
             tag: 42,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.AccountType}
           }}
        end

        def field_def("accountType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accountType",
             kind: {:scalar, :DEFAULT},
             label: :optional,
             name: :accountType,
             tag: 42,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.AccountType}
           }}
        end

        []
      ),
      (
        def field_def(:connectionSequenceInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "connectionSequenceInfo",
             kind: {:scalar, 0},
             label: :optional,
             name: :connectionSequenceInfo,
             tag: 43,
             type: :sfixed32
           }}
        end

        def field_def("connectionSequenceInfo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "connectionSequenceInfo",
             kind: {:scalar, 0},
             label: :optional,
             name: :connectionSequenceInfo,
             tag: 43,
             type: :sfixed32
           }}
        end

        []
      ),
      (
        def field_def(:paaLink) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paaLink",
             kind: {:scalar, false},
             label: :optional,
             name: :paaLink,
             tag: 44,
             type: :bool
           }}
        end

        def field_def("paaLink") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paaLink",
             kind: {:scalar, false},
             label: :optional,
             name: :paaLink,
             tag: 44,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:preacksCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "preacksCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :preacksCount,
             tag: 45,
             type: :int32
           }}
        end

        def field_def("preacksCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "preacksCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :preacksCount,
             tag: 45,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:processingQueueSize) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "processingQueueSize",
             kind: {:scalar, 0},
             label: :optional,
             name: :processingQueueSize,
             tag: 46,
             type: :int32
           }}
        end

        def field_def("processingQueueSize") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "processingQueueSize",
             kind: {:scalar, 0},
             label: :optional,
             name: :processingQueueSize,
             tag: 46,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:pairedPeripherals) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pairedPeripherals",
             kind: :unpacked,
             label: :repeated,
             name: :pairedPeripherals,
             tag: 47,
             type: :string
           }}
        end

        def field_def("pairedPeripherals") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pairedPeripherals",
             kind: :unpacked,
             label: :repeated,
             name: :pairedPeripherals,
             tag: 47,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:testIsolationID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "testIsolationID",
             kind: {:scalar, ""},
             label: :optional,
             name: :testIsolationID,
             tag: 48,
             type: :bytes
           }}
        end

        def field_def("testIsolationID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "testIsolationID",
             kind: {:scalar, ""},
             label: :optional,
             name: :testIsolationID,
             tag: 48,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:messageSts) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageSts",
             kind: {:scalar, 0},
             label: :optional,
             name: :messageSts,
             tag: 49,
             type: :int64
           }}
        end

        def field_def("messageSts") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageSts",
             kind: {:scalar, 0},
             label: :optional,
             name: :messageSts,
             tag: 49,
             type: :int64
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
    def default(:username) do
      {:ok, 0}
    end,
    def default(:passive) do
      {:ok, false}
    end,
    def default(:userAgent) do
      {:ok, nil}
    end,
    def default(:webInfo) do
      {:ok, nil}
    end,
    def default(:pushName) do
      {:ok, ""}
    end,
    def default(:sessionID) do
      {:ok, 0}
    end,
    def default(:shortConnect) do
      {:ok, false}
    end,
    def default(:connectType) do
      {:ok, :CELLULAR_UNKNOWN}
    end,
    def default(:connectReason) do
      {:ok, :PUSH}
    end,
    def default(:shards) do
      {:error, :no_default_value}
    end,
    def default(:dnsSource) do
      {:ok, nil}
    end,
    def default(:connectAttemptCount) do
      {:ok, 0}
    end,
    def default(:device) do
      {:ok, 0}
    end,
    def default(:devicePairingData) do
      {:ok, nil}
    end,
    def default(:product) do
      {:ok, :WHATSAPP}
    end,
    def default(:fbCat) do
      {:ok, ""}
    end,
    def default(:fbUserAgent) do
      {:ok, ""}
    end,
    def default(:oc) do
      {:ok, false}
    end,
    def default(:lc) do
      {:ok, 0}
    end,
    def default(:iosAppExtension) do
      {:ok, :SHARE_EXTENSION}
    end,
    def default(:fbAppID) do
      {:ok, 0}
    end,
    def default(:fbDeviceID) do
      {:ok, ""}
    end,
    def default(:pull) do
      {:ok, false}
    end,
    def default(:paddingBytes) do
      {:ok, ""}
    end,
    def default(:yearClass) do
      {:ok, 0}
    end,
    def default(:memClass) do
      {:ok, 0}
    end,
    def default(:interopData) do
      {:ok, nil}
    end,
    def default(:trafficAnonymization) do
      {:ok, :OFF}
    end,
    def default(:lidDbMigrated) do
      {:ok, false}
    end,
    def default(:accountType) do
      {:ok, :DEFAULT}
    end,
    def default(:connectionSequenceInfo) do
      {:ok, 0}
    end,
    def default(:paaLink) do
      {:ok, false}
    end,
    def default(:preacksCount) do
      {:ok, 0}
    end,
    def default(:processingQueueSize) do
      {:ok, 0}
    end,
    def default(:pairedPeripherals) do
      {:error, :no_default_value}
    end,
    def default(:testIsolationID) do
      {:ok, ""}
    end,
    def default(:messageSts) do
      {:ok, 0}
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
        go_package: "go.mau.fi/whatsmeow/proto/waWa6",
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
