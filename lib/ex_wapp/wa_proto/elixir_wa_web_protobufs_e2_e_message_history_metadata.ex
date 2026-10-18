# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.MessageHistoryMetadata do
  @moduledoc false
  defstruct historyReceivers: [],
            oldestMessageTimestampInWindow: nil,
            messageCount: nil,
            nonHistoryReceivers: [],
            oldestMessageTimestampInBundle: nil,
            includesChatTheme: nil,
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
        |> encode_historyReceivers(msg)
        |> encode_oldestMessageTimestampInWindow(msg)
        |> encode_messageCount(msg)
        |> encode_nonHistoryReceivers(msg)
        |> encode_oldestMessageTimestampInBundle(msg)
        |> encode_includesChatTheme(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_historyReceivers(acc, msg) do
        try do
          case msg.historyReceivers do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\n", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:historyReceivers, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_oldestMessageTimestampInWindow(acc, msg) do
        try do
          case msg.oldestMessageTimestampInWindow do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_int64(msg.oldestMessageTimestampInWindow)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :oldestMessageTimestampInWindow,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_messageCount(acc, msg) do
        try do
          case msg.messageCount do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_int64(msg.messageCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageCount, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_nonHistoryReceivers(acc, msg) do
        try do
          case msg.nonHistoryReceivers do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\"", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:nonHistoryReceivers, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_oldestMessageTimestampInBundle(acc, msg) do
        try do
          case msg.oldestMessageTimestampInBundle do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_int64(msg.oldestMessageTimestampInBundle)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :oldestMessageTimestampInBundle,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_includesChatTheme(acc, msg) do
        try do
          case msg.includesChatTheme do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_bool(msg.includesChatTheme)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:includesChatTheme, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.MessageHistoryMetadata))
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
                 historyReceivers:
                   msg.historyReceivers ++ [Protox.Decode.validate_string!(delimited)]
               ], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[oldestMessageTimestampInWindow: value], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[messageCount: value], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 nonHistoryReceivers:
                   msg.nonHistoryReceivers ++ [Protox.Decode.validate_string!(delimited)]
               ], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[oldestMessageTimestampInBundle: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[includesChatTheme: value], rest}

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
        WAWebProtobufsE2E.MessageHistoryMetadata,
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
        1 => {:historyReceivers, :unpacked, :string},
        2 => {:oldestMessageTimestampInWindow, {:scalar, 0}, :int64},
        3 => {:messageCount, {:scalar, 0}, :int64},
        4 => {:nonHistoryReceivers, :unpacked, :string},
        5 => {:oldestMessageTimestampInBundle, {:scalar, 0}, :int64},
        6 => {:includesChatTheme, {:scalar, false}, :bool}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        historyReceivers: {1, :unpacked, :string},
        includesChatTheme: {6, {:scalar, false}, :bool},
        messageCount: {3, {:scalar, 0}, :int64},
        nonHistoryReceivers: {4, :unpacked, :string},
        oldestMessageTimestampInBundle: {5, {:scalar, 0}, :int64},
        oldestMessageTimestampInWindow: {2, {:scalar, 0}, :int64}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "historyReceivers",
          kind: :unpacked,
          label: :repeated,
          name: :historyReceivers,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "oldestMessageTimestampInWindow",
          kind: {:scalar, 0},
          label: :optional,
          name: :oldestMessageTimestampInWindow,
          tag: 2,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :messageCount,
          tag: 3,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "nonHistoryReceivers",
          kind: :unpacked,
          label: :repeated,
          name: :nonHistoryReceivers,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "oldestMessageTimestampInBundle",
          kind: {:scalar, 0},
          label: :optional,
          name: :oldestMessageTimestampInBundle,
          tag: 5,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "includesChatTheme",
          kind: {:scalar, false},
          label: :optional,
          name: :includesChatTheme,
          tag: 6,
          type: :bool
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:historyReceivers) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "historyReceivers",
             kind: :unpacked,
             label: :repeated,
             name: :historyReceivers,
             tag: 1,
             type: :string
           }}
        end

        def field_def("historyReceivers") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "historyReceivers",
             kind: :unpacked,
             label: :repeated,
             name: :historyReceivers,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:oldestMessageTimestampInWindow) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldestMessageTimestampInWindow",
             kind: {:scalar, 0},
             label: :optional,
             name: :oldestMessageTimestampInWindow,
             tag: 2,
             type: :int64
           }}
        end

        def field_def("oldestMessageTimestampInWindow") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldestMessageTimestampInWindow",
             kind: {:scalar, 0},
             label: :optional,
             name: :oldestMessageTimestampInWindow,
             tag: 2,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:messageCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :messageCount,
             tag: 3,
             type: :int64
           }}
        end

        def field_def("messageCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :messageCount,
             tag: 3,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:nonHistoryReceivers) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nonHistoryReceivers",
             kind: :unpacked,
             label: :repeated,
             name: :nonHistoryReceivers,
             tag: 4,
             type: :string
           }}
        end

        def field_def("nonHistoryReceivers") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nonHistoryReceivers",
             kind: :unpacked,
             label: :repeated,
             name: :nonHistoryReceivers,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:oldestMessageTimestampInBundle) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldestMessageTimestampInBundle",
             kind: {:scalar, 0},
             label: :optional,
             name: :oldestMessageTimestampInBundle,
             tag: 5,
             type: :int64
           }}
        end

        def field_def("oldestMessageTimestampInBundle") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldestMessageTimestampInBundle",
             kind: {:scalar, 0},
             label: :optional,
             name: :oldestMessageTimestampInBundle,
             tag: 5,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:includesChatTheme) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "includesChatTheme",
             kind: {:scalar, false},
             label: :optional,
             name: :includesChatTheme,
             tag: 6,
             type: :bool
           }}
        end

        def field_def("includesChatTheme") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "includesChatTheme",
             kind: {:scalar, false},
             label: :optional,
             name: :includesChatTheme,
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
    def default(:historyReceivers) do
      {:error, :no_default_value}
    end,
    def default(:oldestMessageTimestampInWindow) do
      {:ok, 0}
    end,
    def default(:messageCount) do
      {:ok, 0}
    end,
    def default(:nonHistoryReceivers) do
      {:error, :no_default_value}
    end,
    def default(:oldestMessageTimestampInBundle) do
      {:ok, 0}
    end,
    def default(:includesChatTheme) do
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

  @type t :: %__MODULE__{}
end
