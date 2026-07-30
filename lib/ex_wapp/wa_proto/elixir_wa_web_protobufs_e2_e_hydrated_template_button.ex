# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.HydratedTemplateButton do
  @moduledoc false
  defstruct hydratedButton: nil, index: nil, __uf__: []

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
        [] |> encode_hydratedButton(msg) |> encode_index(msg) |> encode_unknown_fields(msg)
      end
    )

    [
      defp encode_hydratedButton(acc, msg) do
        case msg.hydratedButton do
          nil -> acc
          {:quickReplyButton, _field_value} -> encode_quickReplyButton(acc, msg)
          {:urlButton, _field_value} -> encode_urlButton(acc, msg)
          {:callButton, _field_value} -> encode_callButton(acc, msg)
        end
      end
    ]

    [
      defp encode_quickReplyButton(acc, msg) do
        try do
          {_, child_field_value} = msg.hydratedButton
          [acc, "\n", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:quickReplyButton, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_urlButton(acc, msg) do
        try do
          {_, child_field_value} = msg.hydratedButton
          [acc, "\x12", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:urlButton, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_callButton(acc, msg) do
        try do
          {_, child_field_value} = msg.hydratedButton
          [acc, "\x1A", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callButton, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_index(acc, msg) do
        try do
          case msg.index do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_uint32(msg.index)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:index, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.HydratedTemplateButton))
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
                 case msg.hydratedButton do
                   {:quickReplyButton, previous_value} ->
                     {:hydratedButton,
                      {:quickReplyButton,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.HydratedTemplateButton.HydratedQuickReplyButton.decode!(
                           delimited
                         )
                       )}}

                   _ ->
                     {:hydratedButton,
                      {:quickReplyButton,
                       WAWebProtobufsE2E.HydratedTemplateButton.HydratedQuickReplyButton.decode!(
                         delimited
                       )}}
                 end
               ], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.hydratedButton do
                   {:urlButton, previous_value} ->
                     {:hydratedButton,
                      {:urlButton,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.HydratedTemplateButton.HydratedURLButton.decode!(
                           delimited
                         )
                       )}}

                   _ ->
                     {:hydratedButton,
                      {:urlButton,
                       WAWebProtobufsE2E.HydratedTemplateButton.HydratedURLButton.decode!(
                         delimited
                       )}}
                 end
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.hydratedButton do
                   {:callButton, previous_value} ->
                     {:hydratedButton,
                      {:callButton,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.HydratedTemplateButton.HydratedCallButton.decode!(
                           delimited
                         )
                       )}}

                   _ ->
                     {:hydratedButton,
                      {:callButton,
                       WAWebProtobufsE2E.HydratedTemplateButton.HydratedCallButton.decode!(
                         delimited
                       )}}
                 end
               ], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[index: value], rest}

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
        WAWebProtobufsE2E.HydratedTemplateButton,
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
          {:quickReplyButton, {:oneof, :hydratedButton},
           {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedQuickReplyButton}},
        2 =>
          {:urlButton, {:oneof, :hydratedButton},
           {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedURLButton}},
        3 =>
          {:callButton, {:oneof, :hydratedButton},
           {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedCallButton}},
        4 => {:index, {:scalar, 0}, :uint32}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        callButton:
          {3, {:oneof, :hydratedButton},
           {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedCallButton}},
        index: {4, {:scalar, 0}, :uint32},
        quickReplyButton:
          {1, {:oneof, :hydratedButton},
           {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedQuickReplyButton}},
        urlButton:
          {2, {:oneof, :hydratedButton},
           {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedURLButton}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "quickReplyButton",
          kind: {:oneof, :hydratedButton},
          label: :optional,
          name: :quickReplyButton,
          tag: 1,
          type: {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedQuickReplyButton}
        },
        %{
          __struct__: Protox.Field,
          json_name: "urlButton",
          kind: {:oneof, :hydratedButton},
          label: :optional,
          name: :urlButton,
          tag: 2,
          type: {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedURLButton}
        },
        %{
          __struct__: Protox.Field,
          json_name: "callButton",
          kind: {:oneof, :hydratedButton},
          label: :optional,
          name: :callButton,
          tag: 3,
          type: {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedCallButton}
        },
        %{
          __struct__: Protox.Field,
          json_name: "index",
          kind: {:scalar, 0},
          label: :optional,
          name: :index,
          tag: 4,
          type: :uint32
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:quickReplyButton) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quickReplyButton",
             kind: {:oneof, :hydratedButton},
             label: :optional,
             name: :quickReplyButton,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedQuickReplyButton}
           }}
        end

        def field_def("quickReplyButton") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "quickReplyButton",
             kind: {:oneof, :hydratedButton},
             label: :optional,
             name: :quickReplyButton,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedQuickReplyButton}
           }}
        end

        []
      ),
      (
        def field_def(:urlButton) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "urlButton",
             kind: {:oneof, :hydratedButton},
             label: :optional,
             name: :urlButton,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedURLButton}
           }}
        end

        def field_def("urlButton") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "urlButton",
             kind: {:oneof, :hydratedButton},
             label: :optional,
             name: :urlButton,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedURLButton}
           }}
        end

        []
      ),
      (
        def field_def(:callButton) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callButton",
             kind: {:oneof, :hydratedButton},
             label: :optional,
             name: :callButton,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedCallButton}
           }}
        end

        def field_def("callButton") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callButton",
             kind: {:oneof, :hydratedButton},
             label: :optional,
             name: :callButton,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.HydratedTemplateButton.HydratedCallButton}
           }}
        end

        []
      ),
      (
        def field_def(:index) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "index",
             kind: {:scalar, 0},
             label: :optional,
             name: :index,
             tag: 4,
             type: :uint32
           }}
        end

        def field_def("index") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "index",
             kind: {:scalar, 0},
             label: :optional,
             name: :index,
             tag: 4,
             type: :uint32
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
    def default(:quickReplyButton) do
      {:error, :no_default_value}
    end,
    def default(:urlButton) do
      {:error, :no_default_value}
    end,
    def default(:callButton) do
      {:error, :no_default_value}
    end,
    def default(:index) do
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
