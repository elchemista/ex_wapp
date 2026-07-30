# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.OrderMessage do
  @moduledoc false
  defstruct orderID: nil,
            thumbnail: nil,
            itemCount: nil,
            status: nil,
            surface: nil,
            message: nil,
            orderTitle: nil,
            sellerJID: nil,
            token: nil,
            totalAmount1000: nil,
            totalCurrencyCode: nil,
            messageVersion: nil,
            orderRequestMessageID: nil,
            catalogType: nil,
            contextInfo: nil,
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
        |> encode_orderID(msg)
        |> encode_thumbnail(msg)
        |> encode_itemCount(msg)
        |> encode_status(msg)
        |> encode_surface(msg)
        |> encode_message(msg)
        |> encode_orderTitle(msg)
        |> encode_sellerJID(msg)
        |> encode_token(msg)
        |> encode_totalAmount1000(msg)
        |> encode_totalCurrencyCode(msg)
        |> encode_messageVersion(msg)
        |> encode_orderRequestMessageID(msg)
        |> encode_catalogType(msg)
        |> encode_contextInfo(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_orderID(acc, msg) do
        try do
          case msg.orderID do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.orderID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:orderID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_thumbnail(acc, msg) do
        try do
          case msg.thumbnail do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_bytes(msg.thumbnail)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnail, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_itemCount(acc, msg) do
        try do
          case msg.itemCount do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_int32(msg.itemCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:itemCount, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_status(acc, msg) do
        try do
          case msg.status do
            nil ->
              acc

            _ ->
              [
                acc,
                " ",
                msg.status
                |> WAWebProtobufsE2E.OrderMessage.OrderStatus.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:status, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_surface(acc, msg) do
        try do
          case msg.surface do
            nil ->
              acc

            _ ->
              [
                acc,
                "(",
                msg.surface
                |> WAWebProtobufsE2E.OrderMessage.OrderSurface.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:surface, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_message(acc, msg) do
        try do
          case msg.message do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.message)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:message, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_orderTitle(acc, msg) do
        try do
          case msg.orderTitle do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.orderTitle)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:orderTitle, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_sellerJID(acc, msg) do
        try do
          case msg.sellerJID do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg.sellerJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:sellerJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_token(acc, msg) do
        try do
          case msg.token do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_string(msg.token)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:token, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_totalAmount1000(acc, msg) do
        try do
          case msg.totalAmount1000 do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_int64(msg.totalAmount1000)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:totalAmount1000, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_totalCurrencyCode(acc, msg) do
        try do
          case msg.totalCurrencyCode do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_string(msg.totalCurrencyCode)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:totalCurrencyCode, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageVersion(acc, msg) do
        try do
          case msg.messageVersion do
            nil -> acc
            _ -> [acc, "`", Protox.Encode.encode_int32(msg.messageVersion)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageVersion, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_orderRequestMessageID(acc, msg) do
        try do
          case msg.orderRequestMessageID do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_message(msg.orderRequestMessageID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:orderRequestMessageID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_catalogType(acc, msg) do
        try do
          case msg.catalogType do
            nil -> acc
            _ -> [acc, "z", Protox.Encode.encode_string(msg.catalogType)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:catalogType, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.OrderMessage))
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
              {[orderID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnail: delimited], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[itemCount: value], rest}

            {4, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.OrderMessage.OrderStatus)

              {[status: value], rest}

            {5, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.OrderMessage.OrderSurface)

              {[surface: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[message: Protox.Decode.validate_string!(delimited)], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[orderTitle: Protox.Decode.validate_string!(delimited)], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[sellerJID: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[token: Protox.Decode.validate_string!(delimited)], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[totalAmount1000: value], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[totalCurrencyCode: Protox.Decode.validate_string!(delimited)], rest}

            {12, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[messageVersion: value], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 orderRequestMessageID:
                   Protox.MergeMessage.merge(
                     msg.orderRequestMessageID,
                     WACommon.MessageKey.decode!(delimited)
                   )
               ], rest}

            {15, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[catalogType: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufsE2E.OrderMessage,
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
        1 => {:orderID, {:scalar, ""}, :string},
        2 => {:thumbnail, {:scalar, ""}, :bytes},
        3 => {:itemCount, {:scalar, 0}, :int32},
        4 => {:status, {:scalar, :INQUIRY}, {:enum, WAWebProtobufsE2E.OrderMessage.OrderStatus}},
        5 =>
          {:surface, {:scalar, :CATALOG}, {:enum, WAWebProtobufsE2E.OrderMessage.OrderSurface}},
        6 => {:message, {:scalar, ""}, :string},
        7 => {:orderTitle, {:scalar, ""}, :string},
        8 => {:sellerJID, {:scalar, ""}, :string},
        9 => {:token, {:scalar, ""}, :string},
        10 => {:totalAmount1000, {:scalar, 0}, :int64},
        11 => {:totalCurrencyCode, {:scalar, ""}, :string},
        12 => {:messageVersion, {:scalar, 0}, :int32},
        13 => {:orderRequestMessageID, {:scalar, nil}, {:message, WACommon.MessageKey}},
        15 => {:catalogType, {:scalar, ""}, :string},
        17 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        catalogType: {15, {:scalar, ""}, :string},
        contextInfo: {17, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        itemCount: {3, {:scalar, 0}, :int32},
        message: {6, {:scalar, ""}, :string},
        messageVersion: {12, {:scalar, 0}, :int32},
        orderID: {1, {:scalar, ""}, :string},
        orderRequestMessageID: {13, {:scalar, nil}, {:message, WACommon.MessageKey}},
        orderTitle: {7, {:scalar, ""}, :string},
        sellerJID: {8, {:scalar, ""}, :string},
        status: {4, {:scalar, :INQUIRY}, {:enum, WAWebProtobufsE2E.OrderMessage.OrderStatus}},
        surface: {5, {:scalar, :CATALOG}, {:enum, WAWebProtobufsE2E.OrderMessage.OrderSurface}},
        thumbnail: {2, {:scalar, ""}, :bytes},
        token: {9, {:scalar, ""}, :string},
        totalAmount1000: {10, {:scalar, 0}, :int64},
        totalCurrencyCode: {11, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "orderID",
          kind: {:scalar, ""},
          label: :optional,
          name: :orderID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnail",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnail,
          tag: 2,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "itemCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :itemCount,
          tag: 3,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "status",
          kind: {:scalar, :INQUIRY},
          label: :optional,
          name: :status,
          tag: 4,
          type: {:enum, WAWebProtobufsE2E.OrderMessage.OrderStatus}
        },
        %{
          __struct__: Protox.Field,
          json_name: "surface",
          kind: {:scalar, :CATALOG},
          label: :optional,
          name: :surface,
          tag: 5,
          type: {:enum, WAWebProtobufsE2E.OrderMessage.OrderSurface}
        },
        %{
          __struct__: Protox.Field,
          json_name: "message",
          kind: {:scalar, ""},
          label: :optional,
          name: :message,
          tag: 6,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "orderTitle",
          kind: {:scalar, ""},
          label: :optional,
          name: :orderTitle,
          tag: 7,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "sellerJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :sellerJID,
          tag: 8,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "token",
          kind: {:scalar, ""},
          label: :optional,
          name: :token,
          tag: 9,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "totalAmount1000",
          kind: {:scalar, 0},
          label: :optional,
          name: :totalAmount1000,
          tag: 10,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "totalCurrencyCode",
          kind: {:scalar, ""},
          label: :optional,
          name: :totalCurrencyCode,
          tag: 11,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageVersion",
          kind: {:scalar, 0},
          label: :optional,
          name: :messageVersion,
          tag: 12,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "orderRequestMessageID",
          kind: {:scalar, nil},
          label: :optional,
          name: :orderRequestMessageID,
          tag: 13,
          type: {:message, WACommon.MessageKey}
        },
        %{
          __struct__: Protox.Field,
          json_name: "catalogType",
          kind: {:scalar, ""},
          label: :optional,
          name: :catalogType,
          tag: 15,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "contextInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :contextInfo,
          tag: 17,
          type: {:message, WAWebProtobufsE2E.ContextInfo}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:orderID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "orderID",
             kind: {:scalar, ""},
             label: :optional,
             name: :orderID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("orderID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "orderID",
             kind: {:scalar, ""},
             label: :optional,
             name: :orderID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:thumbnail) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnail",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnail,
             tag: 2,
             type: :bytes
           }}
        end

        def field_def("thumbnail") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnail",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnail,
             tag: 2,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:itemCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "itemCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :itemCount,
             tag: 3,
             type: :int32
           }}
        end

        def field_def("itemCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "itemCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :itemCount,
             tag: 3,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:status) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "status",
             kind: {:scalar, :INQUIRY},
             label: :optional,
             name: :status,
             tag: 4,
             type: {:enum, WAWebProtobufsE2E.OrderMessage.OrderStatus}
           }}
        end

        def field_def("status") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "status",
             kind: {:scalar, :INQUIRY},
             label: :optional,
             name: :status,
             tag: 4,
             type: {:enum, WAWebProtobufsE2E.OrderMessage.OrderStatus}
           }}
        end

        []
      ),
      (
        def field_def(:surface) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "surface",
             kind: {:scalar, :CATALOG},
             label: :optional,
             name: :surface,
             tag: 5,
             type: {:enum, WAWebProtobufsE2E.OrderMessage.OrderSurface}
           }}
        end

        def field_def("surface") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "surface",
             kind: {:scalar, :CATALOG},
             label: :optional,
             name: :surface,
             tag: 5,
             type: {:enum, WAWebProtobufsE2E.OrderMessage.OrderSurface}
           }}
        end

        []
      ),
      (
        def field_def(:message) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "message",
             kind: {:scalar, ""},
             label: :optional,
             name: :message,
             tag: 6,
             type: :string
           }}
        end

        def field_def("message") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "message",
             kind: {:scalar, ""},
             label: :optional,
             name: :message,
             tag: 6,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:orderTitle) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "orderTitle",
             kind: {:scalar, ""},
             label: :optional,
             name: :orderTitle,
             tag: 7,
             type: :string
           }}
        end

        def field_def("orderTitle") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "orderTitle",
             kind: {:scalar, ""},
             label: :optional,
             name: :orderTitle,
             tag: 7,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:sellerJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sellerJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :sellerJID,
             tag: 8,
             type: :string
           }}
        end

        def field_def("sellerJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sellerJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :sellerJID,
             tag: 8,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:token) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "token",
             kind: {:scalar, ""},
             label: :optional,
             name: :token,
             tag: 9,
             type: :string
           }}
        end

        def field_def("token") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "token",
             kind: {:scalar, ""},
             label: :optional,
             name: :token,
             tag: 9,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:totalAmount1000) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "totalAmount1000",
             kind: {:scalar, 0},
             label: :optional,
             name: :totalAmount1000,
             tag: 10,
             type: :int64
           }}
        end

        def field_def("totalAmount1000") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "totalAmount1000",
             kind: {:scalar, 0},
             label: :optional,
             name: :totalAmount1000,
             tag: 10,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:totalCurrencyCode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "totalCurrencyCode",
             kind: {:scalar, ""},
             label: :optional,
             name: :totalCurrencyCode,
             tag: 11,
             type: :string
           }}
        end

        def field_def("totalCurrencyCode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "totalCurrencyCode",
             kind: {:scalar, ""},
             label: :optional,
             name: :totalCurrencyCode,
             tag: 11,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:messageVersion) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageVersion",
             kind: {:scalar, 0},
             label: :optional,
             name: :messageVersion,
             tag: 12,
             type: :int32
           }}
        end

        def field_def("messageVersion") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageVersion",
             kind: {:scalar, 0},
             label: :optional,
             name: :messageVersion,
             tag: 12,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:orderRequestMessageID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "orderRequestMessageID",
             kind: {:scalar, nil},
             label: :optional,
             name: :orderRequestMessageID,
             tag: 13,
             type: {:message, WACommon.MessageKey}
           }}
        end

        def field_def("orderRequestMessageID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "orderRequestMessageID",
             kind: {:scalar, nil},
             label: :optional,
             name: :orderRequestMessageID,
             tag: 13,
             type: {:message, WACommon.MessageKey}
           }}
        end

        []
      ),
      (
        def field_def(:catalogType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "catalogType",
             kind: {:scalar, ""},
             label: :optional,
             name: :catalogType,
             tag: 15,
             type: :string
           }}
        end

        def field_def("catalogType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "catalogType",
             kind: {:scalar, ""},
             label: :optional,
             name: :catalogType,
             tag: 15,
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
    def default(:orderID) do
      {:ok, ""}
    end,
    def default(:thumbnail) do
      {:ok, ""}
    end,
    def default(:itemCount) do
      {:ok, 0}
    end,
    def default(:status) do
      {:ok, :INQUIRY}
    end,
    def default(:surface) do
      {:ok, :CATALOG}
    end,
    def default(:message) do
      {:ok, ""}
    end,
    def default(:orderTitle) do
      {:ok, ""}
    end,
    def default(:sellerJID) do
      {:ok, ""}
    end,
    def default(:token) do
      {:ok, ""}
    end,
    def default(:totalAmount1000) do
      {:ok, 0}
    end,
    def default(:totalCurrencyCode) do
      {:ok, ""}
    end,
    def default(:messageVersion) do
      {:ok, 0}
    end,
    def default(:orderRequestMessageID) do
      {:ok, nil}
    end,
    def default(:catalogType) do
      {:ok, ""}
    end,
    def default(:contextInfo) do
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
