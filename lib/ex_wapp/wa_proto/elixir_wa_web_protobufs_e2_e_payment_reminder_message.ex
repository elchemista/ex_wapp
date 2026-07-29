# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PaymentReminderMessage do
  @moduledoc false
  defstruct reminderID: nil,
            instanceID: nil,
            description: nil,
            frequency: nil,
            status: nil,
            payeeVpa: nil,
            payeeJID: nil,
            payerJID: nil,
            amount: nil,
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
        |> encode_reminderID(msg)
        |> encode_instanceID(msg)
        |> encode_description(msg)
        |> encode_frequency(msg)
        |> encode_status(msg)
        |> encode_payeeVpa(msg)
        |> encode_payeeJID(msg)
        |> encode_payerJID(msg)
        |> encode_amount(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_reminderID(acc, msg) do
        try do
          case msg.reminderID do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.reminderID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:reminderID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_instanceID(acc, msg) do
        try do
          case msg.instanceID do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.instanceID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:instanceID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_description(acc, msg) do
        try do
          case msg.description do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.description)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:description, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_frequency(acc, msg) do
        try do
          case msg.frequency do
            nil ->
              acc

            _ ->
              [
                acc,
                " ",
                msg.frequency
                |> WAWebProtobufsE2E.PaymentReminderMessage.ReminderFrequency.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:frequency, "invalid field value"), __STACKTRACE__
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
                "(",
                msg.status
                |> WAWebProtobufsE2E.PaymentReminderMessage.ReminderStatus.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:status, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_payeeVpa(acc, msg) do
        try do
          case msg.payeeVpa do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.payeeVpa)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:payeeVpa, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_payeeJID(acc, msg) do
        try do
          case msg.payeeJID do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.payeeJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:payeeJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_payerJID(acc, msg) do
        try do
          case msg.payerJID do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg.payerJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:payerJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_amount(acc, msg) do
        try do
          case msg.amount do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_message(msg.amount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:amount, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.PaymentReminderMessage))
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
              {[reminderID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[instanceID: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[description: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.PaymentReminderMessage.ReminderFrequency
                )

              {[frequency: value], rest}

            {5, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.PaymentReminderMessage.ReminderStatus
                )

              {[status: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[payeeVpa: Protox.Decode.validate_string!(delimited)], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[payeeJID: Protox.Decode.validate_string!(delimited)], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[payerJID: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 amount:
                   Protox.MergeMessage.merge(
                     msg.amount,
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
        WAWebProtobufsE2E.PaymentReminderMessage,
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
        1 => {:reminderID, {:scalar, ""}, :string},
        2 => {:instanceID, {:scalar, ""}, :string},
        3 => {:description, {:scalar, ""}, :string},
        4 =>
          {:frequency, {:scalar, :REMINDER_FREQUENCY_UNKNOWN},
           {:enum, WAWebProtobufsE2E.PaymentReminderMessage.ReminderFrequency}},
        5 =>
          {:status, {:scalar, :REMINDER_STATUS_UNKNOWN},
           {:enum, WAWebProtobufsE2E.PaymentReminderMessage.ReminderStatus}},
        6 => {:payeeVpa, {:scalar, ""}, :string},
        7 => {:payeeJID, {:scalar, ""}, :string},
        8 => {:payerJID, {:scalar, ""}, :string},
        9 => {:amount, {:scalar, nil}, {:message, WAWebProtobufsE2E.Money}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        amount: {9, {:scalar, nil}, {:message, WAWebProtobufsE2E.Money}},
        description: {3, {:scalar, ""}, :string},
        frequency:
          {4, {:scalar, :REMINDER_FREQUENCY_UNKNOWN},
           {:enum, WAWebProtobufsE2E.PaymentReminderMessage.ReminderFrequency}},
        instanceID: {2, {:scalar, ""}, :string},
        payeeJID: {7, {:scalar, ""}, :string},
        payeeVpa: {6, {:scalar, ""}, :string},
        payerJID: {8, {:scalar, ""}, :string},
        reminderID: {1, {:scalar, ""}, :string},
        status:
          {5, {:scalar, :REMINDER_STATUS_UNKNOWN},
           {:enum, WAWebProtobufsE2E.PaymentReminderMessage.ReminderStatus}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "reminderID",
          kind: {:scalar, ""},
          label: :optional,
          name: :reminderID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "instanceID",
          kind: {:scalar, ""},
          label: :optional,
          name: :instanceID,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "description",
          kind: {:scalar, ""},
          label: :optional,
          name: :description,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "frequency",
          kind: {:scalar, :REMINDER_FREQUENCY_UNKNOWN},
          label: :optional,
          name: :frequency,
          tag: 4,
          type: {:enum, WAWebProtobufsE2E.PaymentReminderMessage.ReminderFrequency}
        },
        %{
          __struct__: Protox.Field,
          json_name: "status",
          kind: {:scalar, :REMINDER_STATUS_UNKNOWN},
          label: :optional,
          name: :status,
          tag: 5,
          type: {:enum, WAWebProtobufsE2E.PaymentReminderMessage.ReminderStatus}
        },
        %{
          __struct__: Protox.Field,
          json_name: "payeeVpa",
          kind: {:scalar, ""},
          label: :optional,
          name: :payeeVpa,
          tag: 6,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "payeeJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :payeeJID,
          tag: 7,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "payerJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :payerJID,
          tag: 8,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "amount",
          kind: {:scalar, nil},
          label: :optional,
          name: :amount,
          tag: 9,
          type: {:message, WAWebProtobufsE2E.Money}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:reminderID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reminderID",
             kind: {:scalar, ""},
             label: :optional,
             name: :reminderID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("reminderID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reminderID",
             kind: {:scalar, ""},
             label: :optional,
             name: :reminderID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:instanceID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "instanceID",
             kind: {:scalar, ""},
             label: :optional,
             name: :instanceID,
             tag: 2,
             type: :string
           }}
        end

        def field_def("instanceID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "instanceID",
             kind: {:scalar, ""},
             label: :optional,
             name: :instanceID,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:description) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "description",
             kind: {:scalar, ""},
             label: :optional,
             name: :description,
             tag: 3,
             type: :string
           }}
        end

        def field_def("description") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "description",
             kind: {:scalar, ""},
             label: :optional,
             name: :description,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:frequency) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "frequency",
             kind: {:scalar, :REMINDER_FREQUENCY_UNKNOWN},
             label: :optional,
             name: :frequency,
             tag: 4,
             type: {:enum, WAWebProtobufsE2E.PaymentReminderMessage.ReminderFrequency}
           }}
        end

        def field_def("frequency") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "frequency",
             kind: {:scalar, :REMINDER_FREQUENCY_UNKNOWN},
             label: :optional,
             name: :frequency,
             tag: 4,
             type: {:enum, WAWebProtobufsE2E.PaymentReminderMessage.ReminderFrequency}
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
             kind: {:scalar, :REMINDER_STATUS_UNKNOWN},
             label: :optional,
             name: :status,
             tag: 5,
             type: {:enum, WAWebProtobufsE2E.PaymentReminderMessage.ReminderStatus}
           }}
        end

        def field_def("status") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "status",
             kind: {:scalar, :REMINDER_STATUS_UNKNOWN},
             label: :optional,
             name: :status,
             tag: 5,
             type: {:enum, WAWebProtobufsE2E.PaymentReminderMessage.ReminderStatus}
           }}
        end

        []
      ),
      (
        def field_def(:payeeVpa) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "payeeVpa",
             kind: {:scalar, ""},
             label: :optional,
             name: :payeeVpa,
             tag: 6,
             type: :string
           }}
        end

        def field_def("payeeVpa") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "payeeVpa",
             kind: {:scalar, ""},
             label: :optional,
             name: :payeeVpa,
             tag: 6,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:payeeJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "payeeJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :payeeJID,
             tag: 7,
             type: :string
           }}
        end

        def field_def("payeeJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "payeeJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :payeeJID,
             tag: 7,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:payerJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "payerJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :payerJID,
             tag: 8,
             type: :string
           }}
        end

        def field_def("payerJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "payerJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :payerJID,
             tag: 8,
             type: :string
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
             tag: 9,
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
             tag: 9,
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
    def default(:reminderID) do
      {:ok, ""}
    end,
    def default(:instanceID) do
      {:ok, ""}
    end,
    def default(:description) do
      {:ok, ""}
    end,
    def default(:frequency) do
      {:ok, :REMINDER_FREQUENCY_UNKNOWN}
    end,
    def default(:status) do
      {:ok, :REMINDER_STATUS_UNKNOWN}
    end,
    def default(:payeeVpa) do
      {:ok, ""}
    end,
    def default(:payeeJID) do
      {:ok, ""}
    end,
    def default(:payerJID) do
      {:ok, ""}
    end,
    def default(:amount) do
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
