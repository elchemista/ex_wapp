# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.MarketingMessageAction do
  @moduledoc false
  defstruct name: nil,
            message: nil,
            type: nil,
            createdAt: nil,
            lastSentAt: nil,
            isDeleted: nil,
            mediaID: nil,
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
        |> encode_name(msg)
        |> encode_message(msg)
        |> encode_type(msg)
        |> encode_createdAt(msg)
        |> encode_lastSentAt(msg)
        |> encode_isDeleted(msg)
        |> encode_mediaID(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_name(acc, msg) do
        try do
          case msg.name do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.name)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:name, "invalid field value"), __STACKTRACE__
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
      defp encode_type(acc, msg) do
        try do
          case msg.type do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x18",
                msg.type
                |> WAWebProtobufSyncAction.MarketingMessageAction.MarketingMessagePrototypeType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:type, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_createdAt(acc, msg) do
        try do
          case msg.createdAt do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_int64(msg.createdAt)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:createdAt, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_lastSentAt(acc, msg) do
        try do
          case msg.lastSentAt do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_int64(msg.lastSentAt)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lastSentAt, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isDeleted(acc, msg) do
        try do
          case msg.isDeleted do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_bool(msg.isDeleted)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isDeleted, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaID(acc, msg) do
        try do
          case msg.mediaID do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.mediaID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaID, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufSyncAction.MarketingMessageAction))
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
              {[name: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[message: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufSyncAction.MarketingMessageAction.MarketingMessagePrototypeType
                )

              {[type: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[createdAt: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[lastSentAt: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isDeleted: value], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mediaID: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufSyncAction.MarketingMessageAction,
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
        1 => {:name, {:scalar, ""}, :string},
        2 => {:message, {:scalar, ""}, :string},
        3 =>
          {:type, {:scalar, :PERSONALIZED},
           {:enum, WAWebProtobufSyncAction.MarketingMessageAction.MarketingMessagePrototypeType}},
        4 => {:createdAt, {:scalar, 0}, :int64},
        5 => {:lastSentAt, {:scalar, 0}, :int64},
        6 => {:isDeleted, {:scalar, false}, :bool},
        7 => {:mediaID, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        createdAt: {4, {:scalar, 0}, :int64},
        isDeleted: {6, {:scalar, false}, :bool},
        lastSentAt: {5, {:scalar, 0}, :int64},
        mediaID: {7, {:scalar, ""}, :string},
        message: {2, {:scalar, ""}, :string},
        name: {1, {:scalar, ""}, :string},
        type:
          {3, {:scalar, :PERSONALIZED},
           {:enum, WAWebProtobufSyncAction.MarketingMessageAction.MarketingMessagePrototypeType}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "name",
          kind: {:scalar, ""},
          label: :optional,
          name: :name,
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
          json_name: "type",
          kind: {:scalar, :PERSONALIZED},
          label: :optional,
          name: :type,
          tag: 3,
          type:
            {:enum, WAWebProtobufSyncAction.MarketingMessageAction.MarketingMessagePrototypeType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "createdAt",
          kind: {:scalar, 0},
          label: :optional,
          name: :createdAt,
          tag: 4,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "lastSentAt",
          kind: {:scalar, 0},
          label: :optional,
          name: :lastSentAt,
          tag: 5,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "isDeleted",
          kind: {:scalar, false},
          label: :optional,
          name: :isDeleted,
          tag: 6,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaID",
          kind: {:scalar, ""},
          label: :optional,
          name: :mediaID,
          tag: 7,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:name) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "name",
             kind: {:scalar, ""},
             label: :optional,
             name: :name,
             tag: 1,
             type: :string
           }}
        end

        def field_def("name") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "name",
             kind: {:scalar, ""},
             label: :optional,
             name: :name,
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
        def field_def(:type) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, :PERSONALIZED},
             label: :optional,
             name: :type,
             tag: 3,
             type:
               {:enum,
                WAWebProtobufSyncAction.MarketingMessageAction.MarketingMessagePrototypeType}
           }}
        end

        def field_def("type") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, :PERSONALIZED},
             label: :optional,
             name: :type,
             tag: 3,
             type:
               {:enum,
                WAWebProtobufSyncAction.MarketingMessageAction.MarketingMessagePrototypeType}
           }}
        end

        []
      ),
      (
        def field_def(:createdAt) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "createdAt",
             kind: {:scalar, 0},
             label: :optional,
             name: :createdAt,
             tag: 4,
             type: :int64
           }}
        end

        def field_def("createdAt") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "createdAt",
             kind: {:scalar, 0},
             label: :optional,
             name: :createdAt,
             tag: 4,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:lastSentAt) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lastSentAt",
             kind: {:scalar, 0},
             label: :optional,
             name: :lastSentAt,
             tag: 5,
             type: :int64
           }}
        end

        def field_def("lastSentAt") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lastSentAt",
             kind: {:scalar, 0},
             label: :optional,
             name: :lastSentAt,
             tag: 5,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:isDeleted) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isDeleted",
             kind: {:scalar, false},
             label: :optional,
             name: :isDeleted,
             tag: 6,
             type: :bool
           }}
        end

        def field_def("isDeleted") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isDeleted",
             kind: {:scalar, false},
             label: :optional,
             name: :isDeleted,
             tag: 6,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:mediaID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaID",
             kind: {:scalar, ""},
             label: :optional,
             name: :mediaID,
             tag: 7,
             type: :string
           }}
        end

        def field_def("mediaID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaID",
             kind: {:scalar, ""},
             label: :optional,
             name: :mediaID,
             tag: 7,
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
    def default(:name) do
      {:ok, ""}
    end,
    def default(:message) do
      {:ok, ""}
    end,
    def default(:type) do
      {:ok, :PERSONALIZED}
    end,
    def default(:createdAt) do
      {:ok, 0}
    end,
    def default(:lastSentAt) do
      {:ok, 0}
    end,
    def default(:isDeleted) do
      {:ok, false}
    end,
    def default(:mediaID) do
      {:ok, ""}
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
