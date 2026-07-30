# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.QuickReplyAction do
  @moduledoc false
  defstruct shortcut: nil,
            message: nil,
            keywords: [],
            count: nil,
            deleted: nil,
            associatedLabelIDs: [],
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
        |> encode_shortcut(msg)
        |> encode_message(msg)
        |> encode_keywords(msg)
        |> encode_count(msg)
        |> encode_deleted(msg)
        |> encode_associatedLabelIDs(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_shortcut(acc, msg) do
        try do
          case msg.shortcut do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.shortcut)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:shortcut, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_message(acc, msg) do
        try do
          case msg.message do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.message)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:message, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_keywords(acc, msg) do
        try do
          case msg.keywords do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x1A", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:keywords, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_count(acc, msg) do
        try do
          case msg.count do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_int32(msg.count)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:count, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_deleted(acc, msg) do
        try do
          case msg.deleted do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_bool(msg.deleted)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deleted, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_associatedLabelIDs(acc, msg) do
        try do
          case msg.associatedLabelIDs do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "2", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:associatedLabelIDs, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufSyncAction.QuickReplyAction))
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
              {[shortcut: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[message: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[keywords: msg.keywords ++ [Protox.Decode.validate_string!(delimited)]], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[count: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[deleted: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 associatedLabelIDs:
                   msg.associatedLabelIDs ++ [Protox.Decode.validate_string!(delimited)]
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
        WAWebProtobufSyncAction.QuickReplyAction,
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
        1 => {:shortcut, {:scalar, ""}, :string},
        2 => {:message, {:scalar, ""}, :string},
        3 => {:keywords, :unpacked, :string},
        4 => {:count, {:scalar, 0}, :int32},
        5 => {:deleted, {:scalar, false}, :bool},
        6 => {:associatedLabelIDs, :unpacked, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        associatedLabelIDs: {6, :unpacked, :string},
        count: {4, {:scalar, 0}, :int32},
        deleted: {5, {:scalar, false}, :bool},
        keywords: {3, :unpacked, :string},
        message: {2, {:scalar, ""}, :string},
        shortcut: {1, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "shortcut",
          kind: {:scalar, ""},
          label: :optional,
          name: :shortcut,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "message",
          kind: {:scalar, ""},
          label: :optional,
          name: :message,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "keywords",
          kind: :unpacked,
          label: :repeated,
          name: :keywords,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "count",
          kind: {:scalar, 0},
          label: :optional,
          name: :count,
          tag: 4,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "deleted",
          kind: {:scalar, false},
          label: :optional,
          name: :deleted,
          tag: 5,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "associatedLabelIDs",
          kind: :unpacked,
          label: :repeated,
          name: :associatedLabelIDs,
          tag: 6,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:shortcut) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shortcut",
             kind: {:scalar, ""},
             label: :optional,
             name: :shortcut,
             tag: 1,
             type: :string
           }}
        end

        def field_def("shortcut") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shortcut",
             kind: {:scalar, ""},
             label: :optional,
             name: :shortcut,
             tag: 1,
             type: :string
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
             tag: 2,
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
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:keywords) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "keywords",
             kind: :unpacked,
             label: :repeated,
             name: :keywords,
             tag: 3,
             type: :string
           }}
        end

        def field_def("keywords") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "keywords",
             kind: :unpacked,
             label: :repeated,
             name: :keywords,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:count) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "count",
             kind: {:scalar, 0},
             label: :optional,
             name: :count,
             tag: 4,
             type: :int32
           }}
        end

        def field_def("count") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "count",
             kind: {:scalar, 0},
             label: :optional,
             name: :count,
             tag: 4,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:deleted) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deleted",
             kind: {:scalar, false},
             label: :optional,
             name: :deleted,
             tag: 5,
             type: :bool
           }}
        end

        def field_def("deleted") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deleted",
             kind: {:scalar, false},
             label: :optional,
             name: :deleted,
             tag: 5,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:associatedLabelIDs) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "associatedLabelIDs",
             kind: :unpacked,
             label: :repeated,
             name: :associatedLabelIDs,
             tag: 6,
             type: :string
           }}
        end

        def field_def("associatedLabelIDs") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "associatedLabelIDs",
             kind: :unpacked,
             label: :repeated,
             name: :associatedLabelIDs,
             tag: 6,
             type: :string
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
    def default(:shortcut) do
      {:ok, ""}
    end,
    def default(:message) do
      {:ok, ""}
    end,
    def default(:keywords) do
      {:error, :no_default_value}
    end,
    def default(:count) do
      {:ok, 0}
    end,
    def default(:deleted) do
      {:ok, false}
    end,
    def default(:associatedLabelIDs) do
      {:error, :no_default_value}
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
        go_package: "go.mau.fi/whatsmeow/proto/waSyncAction",
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
