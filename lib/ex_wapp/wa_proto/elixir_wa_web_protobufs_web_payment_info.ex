# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.PaymentInfo do
  @moduledoc false
  defstruct currencyDeprecated: nil,
            amount1000: nil,
            receiverJID: nil,
            status: nil,
            transactionTimestamp: nil,
            requestMessageKey: nil,
            expiryTimestamp: nil,
            futureproofed: nil,
            currency: nil,
            txnStatus: nil,
            useNoviFiatFormat: nil,
            primaryAmount: nil,
            exchangeAmount: nil,
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
        |> encode_currencyDeprecated(msg)
        |> encode_amount1000(msg)
        |> encode_receiverJID(msg)
        |> encode_status(msg)
        |> encode_transactionTimestamp(msg)
        |> encode_requestMessageKey(msg)
        |> encode_expiryTimestamp(msg)
        |> encode_futureproofed(msg)
        |> encode_currency(msg)
        |> encode_txnStatus(msg)
        |> encode_useNoviFiatFormat(msg)
        |> encode_primaryAmount(msg)
        |> encode_exchangeAmount(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_currencyDeprecated(acc, msg) do
        try do
          case msg.currencyDeprecated do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.currencyDeprecated
                |> WAWebProtobufsWeb.PaymentInfo.Currency.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:currencyDeprecated, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_amount1000(acc, msg) do
        try do
          case msg.amount1000 do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_uint64(msg.amount1000)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:amount1000, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_receiverJID(acc, msg) do
        try do
          case msg.receiverJID do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.receiverJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:receiverJID, "invalid field value"), __STACKTRACE__
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
                |> WAWebProtobufsWeb.PaymentInfo.Status.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:status, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_transactionTimestamp(acc, msg) do
        try do
          case msg.transactionTimestamp do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_uint64(msg.transactionTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:transactionTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_requestMessageKey(acc, msg) do
        try do
          case msg.requestMessageKey do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_message(msg.requestMessageKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:requestMessageKey, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_expiryTimestamp(acc, msg) do
        try do
          case msg.expiryTimestamp do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_uint64(msg.expiryTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:expiryTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_futureproofed(acc, msg) do
        try do
          case msg.futureproofed do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_bool(msg.futureproofed)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:futureproofed, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_currency(acc, msg) do
        try do
          case msg.currency do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_string(msg.currency)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:currency, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_txnStatus(acc, msg) do
        try do
          case msg.txnStatus do
            nil ->
              acc

            _ ->
              [
                acc,
                "P",
                msg.txnStatus
                |> WAWebProtobufsWeb.PaymentInfo.TxnStatus.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:txnStatus, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_useNoviFiatFormat(acc, msg) do
        try do
          case msg.useNoviFiatFormat do
            nil -> acc
            _ -> [acc, "X", Protox.Encode.encode_bool(msg.useNoviFiatFormat)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:useNoviFiatFormat, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_primaryAmount(acc, msg) do
        try do
          case msg.primaryAmount do
            nil -> acc
            _ -> [acc, "b", Protox.Encode.encode_message(msg.primaryAmount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:primaryAmount, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_exchangeAmount(acc, msg) do
        try do
          case msg.exchangeAmount do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_message(msg.exchangeAmount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:exchangeAmount, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsWeb.PaymentInfo))
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
                Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.PaymentInfo.Currency)

              {[currencyDeprecated: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[amount1000: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[receiverJID: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.PaymentInfo.Status)

              {[status: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[transactionTimestamp: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 requestMessageKey:
                   Protox.MergeMessage.merge(
                     msg.requestMessageKey,
                     WACommon.MessageKey.decode!(delimited)
                   )
               ], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[expiryTimestamp: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[futureproofed: value], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[currency: Protox.Decode.validate_string!(delimited)], rest}

            {10, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsWeb.PaymentInfo.TxnStatus)

              {[txnStatus: value], rest}

            {11, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[useNoviFiatFormat: value], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 primaryAmount:
                   Protox.MergeMessage.merge(
                     msg.primaryAmount,
                     WAWebProtobufsE2E.Money.decode!(delimited)
                   )
               ], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 exchangeAmount:
                   Protox.MergeMessage.merge(
                     msg.exchangeAmount,
                     WAWebProtobufsE2E.Money.decode!(delimited)
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
        WAWebProtobufsWeb.PaymentInfo,
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
          {:currencyDeprecated, {:scalar, :UNKNOWN_CURRENCY},
           {:enum, WAWebProtobufsWeb.PaymentInfo.Currency}},
        2 => {:amount1000, {:scalar, 0}, :uint64},
        3 => {:receiverJID, {:scalar, ""}, :string},
        4 => {:status, {:scalar, :UNKNOWN_STATUS}, {:enum, WAWebProtobufsWeb.PaymentInfo.Status}},
        5 => {:transactionTimestamp, {:scalar, 0}, :uint64},
        6 => {:requestMessageKey, {:scalar, nil}, {:message, WACommon.MessageKey}},
        7 => {:expiryTimestamp, {:scalar, 0}, :uint64},
        8 => {:futureproofed, {:scalar, false}, :bool},
        9 => {:currency, {:scalar, ""}, :string},
        10 => {:txnStatus, {:scalar, :UNKNOWN}, {:enum, WAWebProtobufsWeb.PaymentInfo.TxnStatus}},
        11 => {:useNoviFiatFormat, {:scalar, false}, :bool},
        12 => {:primaryAmount, {:scalar, nil}, {:message, WAWebProtobufsE2E.Money}},
        13 => {:exchangeAmount, {:scalar, nil}, {:message, WAWebProtobufsE2E.Money}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        amount1000: {2, {:scalar, 0}, :uint64},
        currency: {9, {:scalar, ""}, :string},
        currencyDeprecated:
          {1, {:scalar, :UNKNOWN_CURRENCY}, {:enum, WAWebProtobufsWeb.PaymentInfo.Currency}},
        exchangeAmount: {13, {:scalar, nil}, {:message, WAWebProtobufsE2E.Money}},
        expiryTimestamp: {7, {:scalar, 0}, :uint64},
        futureproofed: {8, {:scalar, false}, :bool},
        primaryAmount: {12, {:scalar, nil}, {:message, WAWebProtobufsE2E.Money}},
        receiverJID: {3, {:scalar, ""}, :string},
        requestMessageKey: {6, {:scalar, nil}, {:message, WACommon.MessageKey}},
        status: {4, {:scalar, :UNKNOWN_STATUS}, {:enum, WAWebProtobufsWeb.PaymentInfo.Status}},
        transactionTimestamp: {5, {:scalar, 0}, :uint64},
        txnStatus: {10, {:scalar, :UNKNOWN}, {:enum, WAWebProtobufsWeb.PaymentInfo.TxnStatus}},
        useNoviFiatFormat: {11, {:scalar, false}, :bool}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "currencyDeprecated",
          kind: {:scalar, :UNKNOWN_CURRENCY},
          label: :optional,
          name: :currencyDeprecated,
          tag: 1,
          type: {:enum, WAWebProtobufsWeb.PaymentInfo.Currency}
        },
        %{
          __struct__: Protox.Field,
          json_name: "amount1000",
          kind: {:scalar, 0},
          label: :optional,
          name: :amount1000,
          tag: 2,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "receiverJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :receiverJID,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "status",
          kind: {:scalar, :UNKNOWN_STATUS},
          label: :optional,
          name: :status,
          tag: 4,
          type: {:enum, WAWebProtobufsWeb.PaymentInfo.Status}
        },
        %{
          __struct__: Protox.Field,
          json_name: "transactionTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :transactionTimestamp,
          tag: 5,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "requestMessageKey",
          kind: {:scalar, nil},
          label: :optional,
          name: :requestMessageKey,
          tag: 6,
          type: {:message, WACommon.MessageKey}
        },
        %{
          __struct__: Protox.Field,
          json_name: "expiryTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :expiryTimestamp,
          tag: 7,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "futureproofed",
          kind: {:scalar, false},
          label: :optional,
          name: :futureproofed,
          tag: 8,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "currency",
          kind: {:scalar, ""},
          label: :optional,
          name: :currency,
          tag: 9,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "txnStatus",
          kind: {:scalar, :UNKNOWN},
          label: :optional,
          name: :txnStatus,
          tag: 10,
          type: {:enum, WAWebProtobufsWeb.PaymentInfo.TxnStatus}
        },
        %{
          __struct__: Protox.Field,
          json_name: "useNoviFiatFormat",
          kind: {:scalar, false},
          label: :optional,
          name: :useNoviFiatFormat,
          tag: 11,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "primaryAmount",
          kind: {:scalar, nil},
          label: :optional,
          name: :primaryAmount,
          tag: 12,
          type: {:message, WAWebProtobufsE2E.Money}
        },
        %{
          __struct__: Protox.Field,
          json_name: "exchangeAmount",
          kind: {:scalar, nil},
          label: :optional,
          name: :exchangeAmount,
          tag: 13,
          type: {:message, WAWebProtobufsE2E.Money}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:currencyDeprecated) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "currencyDeprecated",
             kind: {:scalar, :UNKNOWN_CURRENCY},
             label: :optional,
             name: :currencyDeprecated,
             tag: 1,
             type: {:enum, WAWebProtobufsWeb.PaymentInfo.Currency}
           }}
        end

        def field_def("currencyDeprecated") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "currencyDeprecated",
             kind: {:scalar, :UNKNOWN_CURRENCY},
             label: :optional,
             name: :currencyDeprecated,
             tag: 1,
             type: {:enum, WAWebProtobufsWeb.PaymentInfo.Currency}
           }}
        end

        []
      ),
      (
        def field_def(:amount1000) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "amount1000",
             kind: {:scalar, 0},
             label: :optional,
             name: :amount1000,
             tag: 2,
             type: :uint64
           }}
        end

        def field_def("amount1000") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "amount1000",
             kind: {:scalar, 0},
             label: :optional,
             name: :amount1000,
             tag: 2,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:receiverJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "receiverJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :receiverJID,
             tag: 3,
             type: :string
           }}
        end

        def field_def("receiverJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "receiverJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :receiverJID,
             tag: 3,
             type: :string
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
             kind: {:scalar, :UNKNOWN_STATUS},
             label: :optional,
             name: :status,
             tag: 4,
             type: {:enum, WAWebProtobufsWeb.PaymentInfo.Status}
           }}
        end

        def field_def("status") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "status",
             kind: {:scalar, :UNKNOWN_STATUS},
             label: :optional,
             name: :status,
             tag: 4,
             type: {:enum, WAWebProtobufsWeb.PaymentInfo.Status}
           }}
        end

        []
      ),
      (
        def field_def(:transactionTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "transactionTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :transactionTimestamp,
             tag: 5,
             type: :uint64
           }}
        end

        def field_def("transactionTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "transactionTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :transactionTimestamp,
             tag: 5,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:requestMessageKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestMessageKey",
             kind: {:scalar, nil},
             label: :optional,
             name: :requestMessageKey,
             tag: 6,
             type: {:message, WACommon.MessageKey}
           }}
        end

        def field_def("requestMessageKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestMessageKey",
             kind: {:scalar, nil},
             label: :optional,
             name: :requestMessageKey,
             tag: 6,
             type: {:message, WACommon.MessageKey}
           }}
        end

        []
      ),
      (
        def field_def(:expiryTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "expiryTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :expiryTimestamp,
             tag: 7,
             type: :uint64
           }}
        end

        def field_def("expiryTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "expiryTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :expiryTimestamp,
             tag: 7,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:futureproofed) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "futureproofed",
             kind: {:scalar, false},
             label: :optional,
             name: :futureproofed,
             tag: 8,
             type: :bool
           }}
        end

        def field_def("futureproofed") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "futureproofed",
             kind: {:scalar, false},
             label: :optional,
             name: :futureproofed,
             tag: 8,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:currency) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "currency",
             kind: {:scalar, ""},
             label: :optional,
             name: :currency,
             tag: 9,
             type: :string
           }}
        end

        def field_def("currency") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "currency",
             kind: {:scalar, ""},
             label: :optional,
             name: :currency,
             tag: 9,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:txnStatus) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "txnStatus",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :txnStatus,
             tag: 10,
             type: {:enum, WAWebProtobufsWeb.PaymentInfo.TxnStatus}
           }}
        end

        def field_def("txnStatus") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "txnStatus",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :txnStatus,
             tag: 10,
             type: {:enum, WAWebProtobufsWeb.PaymentInfo.TxnStatus}
           }}
        end

        []
      ),
      (
        def field_def(:useNoviFiatFormat) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "useNoviFiatFormat",
             kind: {:scalar, false},
             label: :optional,
             name: :useNoviFiatFormat,
             tag: 11,
             type: :bool
           }}
        end

        def field_def("useNoviFiatFormat") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "useNoviFiatFormat",
             kind: {:scalar, false},
             label: :optional,
             name: :useNoviFiatFormat,
             tag: 11,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:primaryAmount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "primaryAmount",
             kind: {:scalar, nil},
             label: :optional,
             name: :primaryAmount,
             tag: 12,
             type: {:message, WAWebProtobufsE2E.Money}
           }}
        end

        def field_def("primaryAmount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "primaryAmount",
             kind: {:scalar, nil},
             label: :optional,
             name: :primaryAmount,
             tag: 12,
             type: {:message, WAWebProtobufsE2E.Money}
           }}
        end

        []
      ),
      (
        def field_def(:exchangeAmount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "exchangeAmount",
             kind: {:scalar, nil},
             label: :optional,
             name: :exchangeAmount,
             tag: 13,
             type: {:message, WAWebProtobufsE2E.Money}
           }}
        end

        def field_def("exchangeAmount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "exchangeAmount",
             kind: {:scalar, nil},
             label: :optional,
             name: :exchangeAmount,
             tag: 13,
             type: {:message, WAWebProtobufsE2E.Money}
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
    def default(:currencyDeprecated) do
      {:ok, :UNKNOWN_CURRENCY}
    end,
    def default(:amount1000) do
      {:ok, 0}
    end,
    def default(:receiverJID) do
      {:ok, ""}
    end,
    def default(:status) do
      {:ok, :UNKNOWN_STATUS}
    end,
    def default(:transactionTimestamp) do
      {:ok, 0}
    end,
    def default(:requestMessageKey) do
      {:ok, nil}
    end,
    def default(:expiryTimestamp) do
      {:ok, 0}
    end,
    def default(:futureproofed) do
      {:ok, false}
    end,
    def default(:currency) do
      {:ok, ""}
    end,
    def default(:txnStatus) do
      {:ok, :UNKNOWN}
    end,
    def default(:useNoviFiatFormat) do
      {:ok, false}
    end,
    def default(:primaryAmount) do
      {:ok, nil}
    end,
    def default(:exchangeAmount) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waWeb",
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
