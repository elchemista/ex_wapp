# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.TemplateMessage do
  @moduledoc false
  defstruct format: nil, contextInfo: nil, hydratedTemplate: nil, templateID: nil, __uf__: []

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
        |> encode_format(msg)
        |> encode_contextInfo(msg)
        |> encode_hydratedTemplate(msg)
        |> encode_templateID(msg)
        |> encode_unknown_fields(msg)
      end
    )

    [
      defp encode_format(acc, msg) do
        case msg.format do
          nil ->
            acc

          {:fourRowTemplate, _field_value} ->
            encode_fourRowTemplate(acc, msg)

          {:hydratedFourRowTemplate, _field_value} ->
            encode_hydratedFourRowTemplate(acc, msg)

          {:interactiveMessageTemplate, _field_value} ->
            encode_interactiveMessageTemplate(acc, msg)
        end
      end
    ]

    [
      defp encode_fourRowTemplate(acc, msg) do
        try do
          {_, child_field_value} = msg.format
          [acc, "\n", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fourRowTemplate, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_hydratedFourRowTemplate(acc, msg) do
        try do
          {_, child_field_value} = msg.format
          [acc, "\x12", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:hydratedFourRowTemplate, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_contextInfo(acc, msg) do
        try do
          case msg.contextInfo do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_message(msg.contextInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contextInfo, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_hydratedTemplate(acc, msg) do
        try do
          case msg.hydratedTemplate do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_message(msg.hydratedTemplate)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:hydratedTemplate, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_interactiveMessageTemplate(acc, msg) do
        try do
          {_, child_field_value} = msg.format
          [acc, "*", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:interactiveMessageTemplate, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_templateID(acc, msg) do
        try do
          case msg.templateID do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_string(msg.templateID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:templateID, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.TemplateMessage))
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
                 case msg.format do
                   {:fourRowTemplate, previous_value} ->
                     {:format,
                      {:fourRowTemplate,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.TemplateMessage.FourRowTemplate.decode!(delimited)
                       )}}

                   _ ->
                     {:format,
                      {:fourRowTemplate,
                       WAWebProtobufsE2E.TemplateMessage.FourRowTemplate.decode!(delimited)}}
                 end
               ], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.format do
                   {:hydratedFourRowTemplate, previous_value} ->
                     {:format,
                      {:hydratedFourRowTemplate,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.TemplateMessage.HydratedFourRowTemplate.decode!(
                           delimited
                         )
                       )}}

                   _ ->
                     {:format,
                      {:hydratedFourRowTemplate,
                       WAWebProtobufsE2E.TemplateMessage.HydratedFourRowTemplate.decode!(
                         delimited
                       )}}
                 end
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contextInfo:
                   Protox.MergeMessage.merge(
                     msg.contextInfo,
                     WAWebProtobufsE2E.ContextInfo.decode!(delimited)
                   )
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 hydratedTemplate:
                   Protox.MergeMessage.merge(
                     msg.hydratedTemplate,
                     WAWebProtobufsE2E.TemplateMessage.HydratedFourRowTemplate.decode!(delimited)
                   )
               ], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.format do
                   {:interactiveMessageTemplate, previous_value} ->
                     {:format,
                      {:interactiveMessageTemplate,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.InteractiveMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:format,
                      {:interactiveMessageTemplate,
                       WAWebProtobufsE2E.InteractiveMessage.decode!(delimited)}}
                 end
               ], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[templateID: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufsE2E.TemplateMessage,
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
          {:fourRowTemplate, {:oneof, :format},
           {:message, WAWebProtobufsE2E.TemplateMessage.FourRowTemplate}},
        2 =>
          {:hydratedFourRowTemplate, {:oneof, :format},
           {:message, WAWebProtobufsE2E.TemplateMessage.HydratedFourRowTemplate}},
        3 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        4 =>
          {:hydratedTemplate, {:scalar, nil},
           {:message, WAWebProtobufsE2E.TemplateMessage.HydratedFourRowTemplate}},
        5 =>
          {:interactiveMessageTemplate, {:oneof, :format},
           {:message, WAWebProtobufsE2E.InteractiveMessage}},
        9 => {:templateID, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        contextInfo: {3, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        fourRowTemplate:
          {1, {:oneof, :format}, {:message, WAWebProtobufsE2E.TemplateMessage.FourRowTemplate}},
        hydratedFourRowTemplate:
          {2, {:oneof, :format},
           {:message, WAWebProtobufsE2E.TemplateMessage.HydratedFourRowTemplate}},
        hydratedTemplate:
          {4, {:scalar, nil},
           {:message, WAWebProtobufsE2E.TemplateMessage.HydratedFourRowTemplate}},
        interactiveMessageTemplate:
          {5, {:oneof, :format}, {:message, WAWebProtobufsE2E.InteractiveMessage}},
        templateID: {9, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "fourRowTemplate",
          kind: {:oneof, :format},
          label: :optional,
          name: :fourRowTemplate,
          tag: 1,
          type: {:message, WAWebProtobufsE2E.TemplateMessage.FourRowTemplate}
        },
        %{
          __struct__: Protox.Field,
          json_name: "hydratedFourRowTemplate",
          kind: {:oneof, :format},
          label: :optional,
          name: :hydratedFourRowTemplate,
          tag: 2,
          type: {:message, WAWebProtobufsE2E.TemplateMessage.HydratedFourRowTemplate}
        },
        %{
          __struct__: Protox.Field,
          json_name: "contextInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :contextInfo,
          tag: 3,
          type: {:message, WAWebProtobufsE2E.ContextInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "hydratedTemplate",
          kind: {:scalar, nil},
          label: :optional,
          name: :hydratedTemplate,
          tag: 4,
          type: {:message, WAWebProtobufsE2E.TemplateMessage.HydratedFourRowTemplate}
        },
        %{
          __struct__: Protox.Field,
          json_name: "interactiveMessageTemplate",
          kind: {:oneof, :format},
          label: :optional,
          name: :interactiveMessageTemplate,
          tag: 5,
          type: {:message, WAWebProtobufsE2E.InteractiveMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "templateID",
          kind: {:scalar, ""},
          label: :optional,
          name: :templateID,
          tag: 9,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:fourRowTemplate) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fourRowTemplate",
             kind: {:oneof, :format},
             label: :optional,
             name: :fourRowTemplate,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.TemplateMessage.FourRowTemplate}
           }}
        end

        def field_def("fourRowTemplate") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fourRowTemplate",
             kind: {:oneof, :format},
             label: :optional,
             name: :fourRowTemplate,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.TemplateMessage.FourRowTemplate}
           }}
        end

        []
      ),
      (
        def field_def(:hydratedFourRowTemplate) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hydratedFourRowTemplate",
             kind: {:oneof, :format},
             label: :optional,
             name: :hydratedFourRowTemplate,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.TemplateMessage.HydratedFourRowTemplate}
           }}
        end

        def field_def("hydratedFourRowTemplate") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hydratedFourRowTemplate",
             kind: {:oneof, :format},
             label: :optional,
             name: :hydratedFourRowTemplate,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.TemplateMessage.HydratedFourRowTemplate}
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
             tag: 3,
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
             tag: 3,
             type: {:message, WAWebProtobufsE2E.ContextInfo}
           }}
        end

        []
      ),
      (
        def field_def(:hydratedTemplate) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hydratedTemplate",
             kind: {:scalar, nil},
             label: :optional,
             name: :hydratedTemplate,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.TemplateMessage.HydratedFourRowTemplate}
           }}
        end

        def field_def("hydratedTemplate") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hydratedTemplate",
             kind: {:scalar, nil},
             label: :optional,
             name: :hydratedTemplate,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.TemplateMessage.HydratedFourRowTemplate}
           }}
        end

        []
      ),
      (
        def field_def(:interactiveMessageTemplate) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interactiveMessageTemplate",
             kind: {:oneof, :format},
             label: :optional,
             name: :interactiveMessageTemplate,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage}
           }}
        end

        def field_def("interactiveMessageTemplate") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interactiveMessageTemplate",
             kind: {:oneof, :format},
             label: :optional,
             name: :interactiveMessageTemplate,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage}
           }}
        end

        []
      ),
      (
        def field_def(:templateID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "templateID",
             kind: {:scalar, ""},
             label: :optional,
             name: :templateID,
             tag: 9,
             type: :string
           }}
        end

        def field_def("templateID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "templateID",
             kind: {:scalar, ""},
             label: :optional,
             name: :templateID,
             tag: 9,
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
    def default(:fourRowTemplate) do
      {:error, :no_default_value}
    end,
    def default(:hydratedFourRowTemplate) do
      {:error, :no_default_value}
    end,
    def default(:contextInfo) do
      {:ok, nil}
    end,
    def default(:hydratedTemplate) do
      {:ok, nil}
    end,
    def default(:interactiveMessageTemplate) do
      {:error, :no_default_value}
    end,
    def default(:templateID) do
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
