# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.CloudAPIThreadControlNotification do
  @moduledoc false
  defstruct status: nil,
            senderNotificationTimestampMS: nil,
            consumerLid: nil,
            consumerPhoneNumber: nil,
            notificationContent: nil,
            shouldSuppressNotification: nil,
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
        |> encode_status(msg)
        |> encode_senderNotificationTimestampMS(msg)
        |> encode_consumerLid(msg)
        |> encode_consumerPhoneNumber(msg)
        |> encode_notificationContent(msg)
        |> encode_shouldSuppressNotification(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_status(acc, msg) do
        try do
          case msg.status do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.status
                |> WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControl.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:status, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_senderNotificationTimestampMS(acc, msg) do
        try do
          case msg.senderNotificationTimestampMS do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_int64(msg.senderNotificationTimestampMS)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :senderNotificationTimestampMS,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_consumerLid(acc, msg) do
        try do
          case msg.consumerLid do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.consumerLid)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:consumerLid, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_consumerPhoneNumber(acc, msg) do
        try do
          case msg.consumerPhoneNumber do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.consumerPhoneNumber)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:consumerPhoneNumber, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_notificationContent(acc, msg) do
        try do
          case msg.notificationContent do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_message(msg.notificationContent)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:notificationContent, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_shouldSuppressNotification(acc, msg) do
        try do
          case msg.shouldSuppressNotification do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_bool(msg.shouldSuppressNotification)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:shouldSuppressNotification, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.CloudAPIThreadControlNotification))
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
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControl
                )

              {[status: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[senderNotificationTimestampMS: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[consumerLid: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[consumerPhoneNumber: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 notificationContent:
                   Protox.MergeMessage.merge(
                     msg.notificationContent,
                     WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControlNotificationContent.decode!(
                       delimited
                     )
                   )
               ], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[shouldSuppressNotification: value], rest}

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
        WAWebProtobufsE2E.CloudAPIThreadControlNotification,
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
          {:status, {:scalar, :UNKNOWN},
           {:enum, WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControl}},
        2 => {:senderNotificationTimestampMS, {:scalar, 0}, :int64},
        3 => {:consumerLid, {:scalar, ""}, :string},
        4 => {:consumerPhoneNumber, {:scalar, ""}, :string},
        5 =>
          {:notificationContent, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControlNotificationContent}},
        6 => {:shouldSuppressNotification, {:scalar, false}, :bool}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        consumerLid: {3, {:scalar, ""}, :string},
        consumerPhoneNumber: {4, {:scalar, ""}, :string},
        notificationContent:
          {5, {:scalar, nil},
           {:message,
            WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControlNotificationContent}},
        senderNotificationTimestampMS: {2, {:scalar, 0}, :int64},
        shouldSuppressNotification: {6, {:scalar, false}, :bool},
        status:
          {1, {:scalar, :UNKNOWN},
           {:enum, WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControl}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "status",
          kind: {:scalar, :UNKNOWN},
          label: :optional,
          name: :status,
          tag: 1,
          type: {:enum, WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControl}
        },
        %{
          __struct__: Protox.Field,
          json_name: "senderNotificationTimestampMS",
          kind: {:scalar, 0},
          label: :optional,
          name: :senderNotificationTimestampMS,
          tag: 2,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "consumerLid",
          kind: {:scalar, ""},
          label: :optional,
          name: :consumerLid,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "consumerPhoneNumber",
          kind: {:scalar, ""},
          label: :optional,
          name: :consumerPhoneNumber,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "notificationContent",
          kind: {:scalar, nil},
          label: :optional,
          name: :notificationContent,
          tag: 5,
          type:
            {:message,
             WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControlNotificationContent}
        },
        %{
          __struct__: Protox.Field,
          json_name: "shouldSuppressNotification",
          kind: {:scalar, false},
          label: :optional,
          name: :shouldSuppressNotification,
          tag: 6,
          type: :bool
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:status) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "status",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :status,
             tag: 1,
             type:
               {:enum, WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControl}
           }}
        end

        def field_def("status") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "status",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :status,
             tag: 1,
             type:
               {:enum, WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControl}
           }}
        end

        []
      ),
      (
        def field_def(:senderNotificationTimestampMS) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderNotificationTimestampMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :senderNotificationTimestampMS,
             tag: 2,
             type: :int64
           }}
        end

        def field_def("senderNotificationTimestampMS") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "senderNotificationTimestampMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :senderNotificationTimestampMS,
             tag: 2,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:consumerLid) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "consumerLid",
             kind: {:scalar, ""},
             label: :optional,
             name: :consumerLid,
             tag: 3,
             type: :string
           }}
        end

        def field_def("consumerLid") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "consumerLid",
             kind: {:scalar, ""},
             label: :optional,
             name: :consumerLid,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:consumerPhoneNumber) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "consumerPhoneNumber",
             kind: {:scalar, ""},
             label: :optional,
             name: :consumerPhoneNumber,
             tag: 4,
             type: :string
           }}
        end

        def field_def("consumerPhoneNumber") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "consumerPhoneNumber",
             kind: {:scalar, ""},
             label: :optional,
             name: :consumerPhoneNumber,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:notificationContent) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "notificationContent",
             kind: {:scalar, nil},
             label: :optional,
             name: :notificationContent,
             tag: 5,
             type:
               {:message,
                WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControlNotificationContent}
           }}
        end

        def field_def("notificationContent") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "notificationContent",
             kind: {:scalar, nil},
             label: :optional,
             name: :notificationContent,
             tag: 5,
             type:
               {:message,
                WAWebProtobufsE2E.CloudAPIThreadControlNotification.CloudAPIThreadControlNotificationContent}
           }}
        end

        []
      ),
      (
        def field_def(:shouldSuppressNotification) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shouldSuppressNotification",
             kind: {:scalar, false},
             label: :optional,
             name: :shouldSuppressNotification,
             tag: 6,
             type: :bool
           }}
        end

        def field_def("shouldSuppressNotification") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shouldSuppressNotification",
             kind: {:scalar, false},
             label: :optional,
             name: :shouldSuppressNotification,
             tag: 6,
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
    def default(:status) do
      {:ok, :UNKNOWN}
    end,
    def default(:senderNotificationTimestampMS) do
      {:ok, 0}
    end,
    def default(:consumerLid) do
      {:ok, ""}
    end,
    def default(:consumerPhoneNumber) do
      {:ok, ""}
    end,
    def default(:notificationContent) do
      {:ok, nil}
    end,
    def default(:shouldSuppressNotification) do
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
