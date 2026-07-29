# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.RequestPaymentMessage do
  @moduledoc false
  defstruct currencyCodeIso4217: nil,
            amount1000: nil,
            requestFrom: nil,
            noteMessage: nil,
            expiryTimestamp: nil,
            amount: nil,
            background: nil,
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
        |> encode_currencyCodeIso4217(msg)
        |> encode_amount1000(msg)
        |> encode_requestFrom(msg)
        |> encode_noteMessage(msg)
        |> encode_expiryTimestamp(msg)
        |> encode_amount(msg)
        |> encode_background(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_currencyCodeIso4217(acc, msg) do
        try do
          case msg.currencyCodeIso4217 do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.currencyCodeIso4217)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:currencyCodeIso4217, "invalid field value"),
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
      defp encode_requestFrom(acc, msg) do
        try do
          case msg.requestFrom do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.requestFrom)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:requestFrom, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_noteMessage(acc, msg) do
        try do
          case msg.noteMessage do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_message(msg.noteMessage)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:noteMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_expiryTimestamp(acc, msg) do
        try do
          case msg.expiryTimestamp do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_int64(msg.expiryTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:expiryTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_amount(acc, msg) do
        try do
          case msg.amount do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_message(msg.amount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:amount, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_background(acc, msg) do
        try do
          case msg.background do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_message(msg.background)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:background, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.RequestPaymentMessage))
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
              {[currencyCodeIso4217: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[amount1000: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[requestFrom: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 noteMessage:
                   Protox.MergeMessage.merge(
                     msg.noteMessage,
                     WAWebProtobufsE2E.Message.decode!(delimited)
                   )
               ], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[expiryTimestamp: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 amount:
                   Protox.MergeMessage.merge(
                     msg.amount,
                     WAWebProtobufsE2E.Money.decode!(delimited)
                   )
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 background:
                   Protox.MergeMessage.merge(
                     msg.background,
                     WAWebProtobufsE2E.PaymentBackground.decode!(delimited)
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
        WAWebProtobufsE2E.RequestPaymentMessage,
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
        1 => {:currencyCodeIso4217, {:scalar, ""}, :string},
        2 => {:amount1000, {:scalar, 0}, :uint64},
        3 => {:requestFrom, {:scalar, ""}, :string},
        4 => {:noteMessage, {:scalar, nil}, {:message, WAWebProtobufsE2E.Message}},
        5 => {:expiryTimestamp, {:scalar, 0}, :int64},
        6 => {:amount, {:scalar, nil}, {:message, WAWebProtobufsE2E.Money}},
        7 => {:background, {:scalar, nil}, {:message, WAWebProtobufsE2E.PaymentBackground}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        amount: {6, {:scalar, nil}, {:message, WAWebProtobufsE2E.Money}},
        amount1000: {2, {:scalar, 0}, :uint64},
        background: {7, {:scalar, nil}, {:message, WAWebProtobufsE2E.PaymentBackground}},
        currencyCodeIso4217: {1, {:scalar, ""}, :string},
        expiryTimestamp: {5, {:scalar, 0}, :int64},
        noteMessage: {4, {:scalar, nil}, {:message, WAWebProtobufsE2E.Message}},
        requestFrom: {3, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "currencyCodeIso4217",
          kind: {:scalar, ""},
          label: :optional,
          name: :currencyCodeIso4217,
          tag: 1,
          type: :string
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
          json_name: "requestFrom",
          kind: {:scalar, ""},
          label: :optional,
          name: :requestFrom,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "noteMessage",
          kind: {:scalar, nil},
          label: :optional,
          name: :noteMessage,
          tag: 4,
          type: {:message, WAWebProtobufsE2E.Message}
        },
        %{
          __struct__: Protox.Field,
          json_name: "expiryTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :expiryTimestamp,
          tag: 5,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "amount",
          kind: {:scalar, nil},
          label: :optional,
          name: :amount,
          tag: 6,
          type: {:message, WAWebProtobufsE2E.Money}
        },
        %{
          __struct__: Protox.Field,
          json_name: "background",
          kind: {:scalar, nil},
          label: :optional,
          name: :background,
          tag: 7,
          type: {:message, WAWebProtobufsE2E.PaymentBackground}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:currencyCodeIso4217) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "currencyCodeIso4217",
             kind: {:scalar, ""},
             label: :optional,
             name: :currencyCodeIso4217,
             tag: 1,
             type: :string
           }}
        end

        def field_def("currencyCodeIso4217") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "currencyCodeIso4217",
             kind: {:scalar, ""},
             label: :optional,
             name: :currencyCodeIso4217,
             tag: 1,
             type: :string
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
        def field_def(:requestFrom) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestFrom",
             kind: {:scalar, ""},
             label: :optional,
             name: :requestFrom,
             tag: 3,
             type: :string
           }}
        end

        def field_def("requestFrom") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requestFrom",
             kind: {:scalar, ""},
             label: :optional,
             name: :requestFrom,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:noteMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "noteMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :noteMessage,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.Message}
           }}
        end

        def field_def("noteMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "noteMessage",
             kind: {:scalar, nil},
             label: :optional,
             name: :noteMessage,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.Message}
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
             tag: 5,
             type: :int64
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
             tag: 5,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:amount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "amount",
             kind: {:scalar, nil},
             label: :optional,
             name: :amount,
             tag: 6,
             type: {:message, WAWebProtobufsE2E.Money}
           }}
        end

        def field_def("amount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "amount",
             kind: {:scalar, nil},
             label: :optional,
             name: :amount,
             tag: 6,
             type: {:message, WAWebProtobufsE2E.Money}
           }}
        end

        []
      ),
      (
        def field_def(:background) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "background",
             kind: {:scalar, nil},
             label: :optional,
             name: :background,
             tag: 7,
             type: {:message, WAWebProtobufsE2E.PaymentBackground}
           }}
        end

        def field_def("background") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "background",
             kind: {:scalar, nil},
             label: :optional,
             name: :background,
             tag: 7,
             type: {:message, WAWebProtobufsE2E.PaymentBackground}
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
    def default(:currencyCodeIso4217) do
      {:ok, ""}
    end,
    def default(:amount1000) do
      {:ok, 0}
    end,
    def default(:requestFrom) do
      {:ok, ""}
    end,
    def default(:noteMessage) do
      {:ok, nil}
    end,
    def default(:expiryTimestamp) do
      {:ok, 0}
    end,
    def default(:amount) do
      {:ok, nil}
    end,
    def default(:background) do
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
