# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotUnifiedResponseMutation.MediaDetailsMetadata do
  @moduledoc false
  defstruct ID: nil, highResMedia: nil, previewMedia: nil, __uf__: []

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
        |> encode_ID(msg)
        |> encode_highResMedia(msg)
        |> encode_previewMedia(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_ID(acc, msg) do
        try do
          case msg."ID" do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg."ID")]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_highResMedia(acc, msg) do
        try do
          case msg.highResMedia do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_message(msg.highResMedia)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:highResMedia, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_previewMedia(acc, msg) do
        try do
          case msg.previewMedia do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_message(msg.previewMedia)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:previewMedia, "invalid field value"), __STACKTRACE__
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
          parse_key_value(
            bytes,
            struct(WAWebProtobufsAICommon.BotUnifiedResponseMutation.MediaDetailsMetadata)
          )
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
              {[ID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 highResMedia:
                   Protox.MergeMessage.merge(
                     msg.highResMedia,
                     WAWebProtobufsAICommon.BotMediaMetadata.decode!(delimited)
                   )
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 previewMedia:
                   Protox.MergeMessage.merge(
                     msg.previewMedia,
                     WAWebProtobufsAICommon.BotMediaMetadata.decode!(delimited)
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
        WAWebProtobufsAICommon.BotUnifiedResponseMutation.MediaDetailsMetadata,
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
        1 => {:ID, {:scalar, ""}, :string},
        2 => {:highResMedia, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotMediaMetadata}},
        3 => {:previewMedia, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotMediaMetadata}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        ID: {1, {:scalar, ""}, :string},
        highResMedia: {2, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotMediaMetadata}},
        previewMedia: {3, {:scalar, nil}, {:message, WAWebProtobufsAICommon.BotMediaMetadata}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "ID",
          kind: {:scalar, ""},
          label: :optional,
          name: :ID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "highResMedia",
          kind: {:scalar, nil},
          label: :optional,
          name: :highResMedia,
          tag: 2,
          type: {:message, WAWebProtobufsAICommon.BotMediaMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "previewMedia",
          kind: {:scalar, nil},
          label: :optional,
          name: :previewMedia,
          tag: 3,
          type: {:message, WAWebProtobufsAICommon.BotMediaMetadata}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:ID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ID",
             kind: {:scalar, ""},
             label: :optional,
             name: :ID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("ID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ID",
             kind: {:scalar, ""},
             label: :optional,
             name: :ID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:highResMedia) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "highResMedia",
             kind: {:scalar, nil},
             label: :optional,
             name: :highResMedia,
             tag: 2,
             type: {:message, WAWebProtobufsAICommon.BotMediaMetadata}
           }}
        end

        def field_def("highResMedia") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "highResMedia",
             kind: {:scalar, nil},
             label: :optional,
             name: :highResMedia,
             tag: 2,
             type: {:message, WAWebProtobufsAICommon.BotMediaMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:previewMedia) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "previewMedia",
             kind: {:scalar, nil},
             label: :optional,
             name: :previewMedia,
             tag: 3,
             type: {:message, WAWebProtobufsAICommon.BotMediaMetadata}
           }}
        end

        def field_def("previewMedia") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "previewMedia",
             kind: {:scalar, nil},
             label: :optional,
             name: :previewMedia,
             tag: 3,
             type: {:message, WAWebProtobufsAICommon.BotMediaMetadata}
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
    def default(:ID) do
      {:ok, ""}
    end,
    def default(:highResMedia) do
      {:ok, nil}
    end,
    def default(:previewMedia) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waAICommon",
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
