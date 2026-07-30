# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.BusinessBroadcastInsightsAction do
  @moduledoc false
  defstruct recipientCount: nil,
            deliveredCount: nil,
            readCount: nil,
            repliedCount: nil,
            quickReplyCount: nil,
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
        |> encode_recipientCount(msg)
        |> encode_deliveredCount(msg)
        |> encode_readCount(msg)
        |> encode_repliedCount(msg)
        |> encode_quickReplyCount(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_recipientCount(acc, msg) do
        try do
          case msg.recipientCount do
            nil -> acc
            _ -> [acc, "\b", Protox.Encode.encode_int32(msg.recipientCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:recipientCount, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_deliveredCount(acc, msg) do
        try do
          case msg.deliveredCount do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_int32(msg.deliveredCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deliveredCount, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_readCount(acc, msg) do
        try do
          case msg.readCount do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_int32(msg.readCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:readCount, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_repliedCount(acc, msg) do
        try do
          case msg.repliedCount do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_int32(msg.repliedCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:repliedCount, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_quickReplyCount(acc, msg) do
        try do
          case msg.quickReplyCount do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_int32(msg.quickReplyCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:quickReplyCount, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufSyncAction.BusinessBroadcastInsightsAction))
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
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[recipientCount: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[deliveredCount: value], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[readCount: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[repliedCount: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[quickReplyCount: value], rest}

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
        WAWebProtobufSyncAction.BusinessBroadcastInsightsAction,
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
        1 => {:recipientCount, {:scalar, 0}, :int32},
        2 => {:deliveredCount, {:scalar, 0}, :int32},
        3 => {:readCount, {:scalar, 0}, :int32},
        4 => {:repliedCount, {:scalar, 0}, :int32},
        5 => {:quickReplyCount, {:scalar, 0}, :int32}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        deliveredCount: {2, {:scalar, 0}, :int32},
        quickReplyCount: {5, {:scalar, 0}, :int32},
        readCount: {3, {:scalar, 0}, :int32},
        recipientCount: {1, {:scalar, 0}, :int32},
        repliedCount: {4, {:scalar, 0}, :int32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "recipientCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :recipientCount,
          tag: 1,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "deliveredCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :deliveredCount,
          tag: 2,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "readCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :readCount,
          tag: 3,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "repliedCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :repliedCount,
          tag: 4,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "quickReplyCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :quickReplyCount,
          tag: 5,
          type: :int32
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:recipientCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recipientCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :recipientCount,
             tag: 1,
             type: :int32
           }}
        end

        def field_def("recipientCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "recipientCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :recipientCount,
             tag: 1,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:deliveredCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deliveredCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :deliveredCount,
             tag: 2,
             type: :int32
           }}
        end

        def field_def("deliveredCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deliveredCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :deliveredCount,
             tag: 2,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:readCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "readCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :readCount,
             tag: 3,
             type: :int32
           }}
        end

        def field_def("readCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "readCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :readCount,
             tag: 3,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:repliedCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "repliedCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :repliedCount,
             tag: 4,
             type: :int32
           }}
        end

        def field_def("repliedCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "repliedCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :repliedCount,
             tag: 4,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:quickReplyCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quickReplyCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :quickReplyCount,
             tag: 5,
             type: :int32
           }}
        end

        def field_def("quickReplyCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quickReplyCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :quickReplyCount,
             tag: 5,
             type: :int32
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
    def default(:recipientCount) do
      {:ok, 0}
    end,
    def default(:deliveredCount) do
      {:ok, 0}
    end,
    def default(:readCount) do
      {:ok, 0}
    end,
    def default(:repliedCount) do
      {:ok, 0}
    end,
    def default(:quickReplyCount) do
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
