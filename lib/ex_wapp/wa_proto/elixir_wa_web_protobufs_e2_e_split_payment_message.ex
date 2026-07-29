# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.SplitPaymentMessage do
  @moduledoc false
  defstruct splitID: nil,
            totalAmount: nil,
            description: nil,
            requesterJID: nil,
            participants: [],
            createdAtMS: nil,
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
        |> encode_splitID(msg)
        |> encode_totalAmount(msg)
        |> encode_description(msg)
        |> encode_requesterJID(msg)
        |> encode_participants(msg)
        |> encode_createdAtMS(msg)
        |> encode_contextInfo(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_splitID(acc, msg) do
        try do
          case msg.splitID do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.splitID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:splitID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_totalAmount(acc, msg) do
        try do
          case msg.totalAmount do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_message(msg.totalAmount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:totalAmount, "invalid field value"), __STACKTRACE__
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
      defp encode_requesterJID(acc, msg) do
        try do
          case msg.requesterJID do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.requesterJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:requesterJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_participants(acc, msg) do
        try do
          case msg.participants do
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
            reraise Protox.EncodingError.new(:participants, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_createdAtMS(acc, msg) do
        try do
          case msg.createdAtMS do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_int64(msg.createdAtMS)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:createdAtMS, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.SplitPaymentMessage))
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
              {[splitID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 totalAmount:
                   Protox.MergeMessage.merge(
                     msg.totalAmount,
                     WAWebProtobufsE2E.Money.decode!(delimited)
                   )
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[description: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[requesterJID: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 participants:
                   msg.participants ++
                     [WAWebProtobufsE2E.SplitPaymentParticipant.decode!(delimited)]
               ], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[createdAtMS: value], rest}

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
        WAWebProtobufsE2E.SplitPaymentMessage,
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
        1 => {:splitID, {:scalar, ""}, :string},
        2 => {:totalAmount, {:scalar, nil}, {:message, WAWebProtobufsE2E.Money}},
        3 => {:description, {:scalar, ""}, :string},
        4 => {:requesterJID, {:scalar, ""}, :string},
        5 => {:participants, :unpacked, {:message, WAWebProtobufsE2E.SplitPaymentParticipant}},
        6 => {:createdAtMS, {:scalar, 0}, :int64},
        17 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        contextInfo: {17, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        createdAtMS: {6, {:scalar, 0}, :int64},
        description: {3, {:scalar, ""}, :string},
        participants: {5, :unpacked, {:message, WAWebProtobufsE2E.SplitPaymentParticipant}},
        requesterJID: {4, {:scalar, ""}, :string},
        splitID: {1, {:scalar, ""}, :string},
        totalAmount: {2, {:scalar, nil}, {:message, WAWebProtobufsE2E.Money}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "splitID",
          kind: {:scalar, ""},
          label: :optional,
          name: :splitID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "totalAmount",
          kind: {:scalar, nil},
          label: :optional,
          name: :totalAmount,
          tag: 2,
          type: {:message, WAWebProtobufsE2E.Money}
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
          json_name: "requesterJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :requesterJID,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "participants",
          kind: :unpacked,
          label: :repeated,
          name: :participants,
          tag: 5,
          type: {:message, WAWebProtobufsE2E.SplitPaymentParticipant}
        },
        %{
          __struct__: Protox.Field,
          json_name: "createdAtMS",
          kind: {:scalar, 0},
          label: :optional,
          name: :createdAtMS,
          tag: 6,
          type: :int64
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
        def field_def(:splitID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "splitID",
             kind: {:scalar, ""},
             label: :optional,
             name: :splitID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("splitID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "splitID",
             kind: {:scalar, ""},
             label: :optional,
             name: :splitID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:totalAmount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "totalAmount",
             kind: {:scalar, nil},
             label: :optional,
             name: :totalAmount,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.Money}
           }}
        end

        def field_def("totalAmount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "totalAmount",
             kind: {:scalar, nil},
             label: :optional,
             name: :totalAmount,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.Money}
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
        def field_def(:requesterJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requesterJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :requesterJID,
             tag: 4,
             type: :string
           }}
        end

        def field_def("requesterJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "requesterJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :requesterJID,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:participants) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "participants",
             kind: :unpacked,
             label: :repeated,
             name: :participants,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.SplitPaymentParticipant}
           }}
        end

        def field_def("participants") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "participants",
             kind: :unpacked,
             label: :repeated,
             name: :participants,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.SplitPaymentParticipant}
           }}
        end

        []
      ),
      (
        def field_def(:createdAtMS) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "createdAtMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :createdAtMS,
             tag: 6,
             type: :int64
           }}
        end

        def field_def("createdAtMS") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "createdAtMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :createdAtMS,
             tag: 6,
             type: :int64
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
    def default(:splitID) do
      {:ok, ""}
    end,
    def default(:totalAmount) do
      {:ok, nil}
    end,
    def default(:description) do
      {:ok, ""}
    end,
    def default(:requesterJID) do
      {:ok, ""}
    end,
    def default(:participants) do
      {:error, :no_default_value}
    end,
    def default(:createdAtMS) do
      {:ok, 0}
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
end
