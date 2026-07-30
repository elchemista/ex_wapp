# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.InteractiveAnnotation do
  @moduledoc false
  defstruct polygonVertices: [],
            action: nil,
            shouldSkipConfirmation: nil,
            embeddedContent: nil,
            statusLinkType: nil,
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
        |> encode_action(msg)
        |> encode_polygonVertices(msg)
        |> encode_shouldSkipConfirmation(msg)
        |> encode_embeddedContent(msg)
        |> encode_statusLinkType(msg)
        |> encode_unknown_fields(msg)
      end
    )

    [
      defp encode_action(acc, msg) do
        case msg.action do
          nil -> acc
          {:location, _field_value} -> encode_location(acc, msg)
          {:newsletter, _field_value} -> encode_newsletter(acc, msg)
          {:embeddedAction, _field_value} -> encode_embeddedAction(acc, msg)
          {:tapAction, _field_value} -> encode_tapAction(acc, msg)
        end
      end
    ]

    [
      defp encode_polygonVertices(acc, msg) do
        try do
          case msg.polygonVertices do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\n", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:polygonVertices, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_location(acc, msg) do
        try do
          {_, child_field_value} = msg.action
          [acc, "\x12", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:location, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_newsletter(acc, msg) do
        try do
          {_, child_field_value} = msg.action
          [acc, "\x1A", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:newsletter, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_shouldSkipConfirmation(acc, msg) do
        try do
          case msg.shouldSkipConfirmation do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_bool(msg.shouldSkipConfirmation)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:shouldSkipConfirmation, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_embeddedContent(acc, msg) do
        try do
          case msg.embeddedContent do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_message(msg.embeddedContent)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:embeddedContent, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_embeddedAction(acc, msg) do
        try do
          {_, child_field_value} = msg.action
          [acc, "0", Protox.Encode.encode_bool(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:embeddedAction, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_tapAction(acc, msg) do
        try do
          {_, child_field_value} = msg.action
          [acc, ":", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:tapAction, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_statusLinkType(acc, msg) do
        try do
          case msg.statusLinkType do
            nil ->
              acc

            _ ->
              [
                acc,
                "@",
                msg.statusLinkType
                |> WAWebProtobufsE2E.InteractiveAnnotation.StatusLinkType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusLinkType, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.InteractiveAnnotation))
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
                 polygonVertices:
                   msg.polygonVertices ++ [WAWebProtobufsE2E.Point.decode!(delimited)]
               ], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.action do
                   {:location, previous_value} ->
                     {:action,
                      {:location,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.Location.decode!(delimited)
                       )}}

                   _ ->
                     {:action, {:location, WAWebProtobufsE2E.Location.decode!(delimited)}}
                 end
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.action do
                   {:newsletter, previous_value} ->
                     {:action,
                      {:newsletter,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo.decode!(
                           delimited
                         )
                       )}}

                   _ ->
                     {:action,
                      {:newsletter,
                       WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo.decode!(
                         delimited
                       )}}
                 end
               ], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[shouldSkipConfirmation: value], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 embeddedContent:
                   Protox.MergeMessage.merge(
                     msg.embeddedContent,
                     WAWebProtobufsE2E.EmbeddedContent.decode!(delimited)
                   )
               ], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[action: {:embeddedAction, value}], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.action do
                   {:tapAction, previous_value} ->
                     {:action,
                      {:tapAction,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.TapLinkAction.decode!(delimited)
                       )}}

                   _ ->
                     {:action, {:tapAction, WAWebProtobufsE2E.TapLinkAction.decode!(delimited)}}
                 end
               ], rest}

            {8, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.InteractiveAnnotation.StatusLinkType
                )

              {[statusLinkType: value], rest}

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
        WAWebProtobufsE2E.InteractiveAnnotation,
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
        1 => {:polygonVertices, :unpacked, {:message, WAWebProtobufsE2E.Point}},
        2 => {:location, {:oneof, :action}, {:message, WAWebProtobufsE2E.Location}},
        3 =>
          {:newsletter, {:oneof, :action},
           {:message, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo}},
        4 => {:shouldSkipConfirmation, {:scalar, false}, :bool},
        5 => {:embeddedContent, {:scalar, nil}, {:message, WAWebProtobufsE2E.EmbeddedContent}},
        6 => {:embeddedAction, {:oneof, :action}, :bool},
        7 => {:tapAction, {:oneof, :action}, {:message, WAWebProtobufsE2E.TapLinkAction}},
        8 =>
          {:statusLinkType, {:scalar, :RASTERIZED_LINK_PREVIEW},
           {:enum, WAWebProtobufsE2E.InteractiveAnnotation.StatusLinkType}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        embeddedAction: {6, {:oneof, :action}, :bool},
        embeddedContent: {5, {:scalar, nil}, {:message, WAWebProtobufsE2E.EmbeddedContent}},
        location: {2, {:oneof, :action}, {:message, WAWebProtobufsE2E.Location}},
        newsletter:
          {3, {:oneof, :action},
           {:message, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo}},
        polygonVertices: {1, :unpacked, {:message, WAWebProtobufsE2E.Point}},
        shouldSkipConfirmation: {4, {:scalar, false}, :bool},
        statusLinkType:
          {8, {:scalar, :RASTERIZED_LINK_PREVIEW},
           {:enum, WAWebProtobufsE2E.InteractiveAnnotation.StatusLinkType}},
        tapAction: {7, {:oneof, :action}, {:message, WAWebProtobufsE2E.TapLinkAction}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "polygonVertices",
          kind: :unpacked,
          label: :repeated,
          name: :polygonVertices,
          tag: 1,
          type: {:message, WAWebProtobufsE2E.Point}
        },
        %{
          __struct__: Protox.Field,
          json_name: "location",
          kind: {:oneof, :action},
          label: :optional,
          name: :location,
          tag: 2,
          type: {:message, WAWebProtobufsE2E.Location}
        },
        %{
          __struct__: Protox.Field,
          json_name: "newsletter",
          kind: {:oneof, :action},
          label: :optional,
          name: :newsletter,
          tag: 3,
          type: {:message, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "shouldSkipConfirmation",
          kind: {:scalar, false},
          label: :optional,
          name: :shouldSkipConfirmation,
          tag: 4,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "embeddedContent",
          kind: {:scalar, nil},
          label: :optional,
          name: :embeddedContent,
          tag: 5,
          type: {:message, WAWebProtobufsE2E.EmbeddedContent}
        },
        %{
          __struct__: Protox.Field,
          json_name: "embeddedAction",
          kind: {:oneof, :action},
          label: :optional,
          name: :embeddedAction,
          tag: 6,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "tapAction",
          kind: {:oneof, :action},
          label: :optional,
          name: :tapAction,
          tag: 7,
          type: {:message, WAWebProtobufsE2E.TapLinkAction}
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusLinkType",
          kind: {:scalar, :RASTERIZED_LINK_PREVIEW},
          label: :optional,
          name: :statusLinkType,
          tag: 8,
          type: {:enum, WAWebProtobufsE2E.InteractiveAnnotation.StatusLinkType}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:polygonVertices) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "polygonVertices",
             kind: :unpacked,
             label: :repeated,
             name: :polygonVertices,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.Point}
           }}
        end

        def field_def("polygonVertices") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "polygonVertices",
             kind: :unpacked,
             label: :repeated,
             name: :polygonVertices,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.Point}
           }}
        end

        []
      ),
      (
        def field_def(:location) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "location",
             kind: {:oneof, :action},
             label: :optional,
             name: :location,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.Location}
           }}
        end

        def field_def("location") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "location",
             kind: {:oneof, :action},
             label: :optional,
             name: :location,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.Location}
           }}
        end

        []
      ),
      (
        def field_def(:newsletter) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletter",
             kind: {:oneof, :action},
             label: :optional,
             name: :newsletter,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo}
           }}
        end

        def field_def("newsletter") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletter",
             kind: {:oneof, :action},
             label: :optional,
             name: :newsletter,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo}
           }}
        end

        []
      ),
      (
        def field_def(:shouldSkipConfirmation) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shouldSkipConfirmation",
             kind: {:scalar, false},
             label: :optional,
             name: :shouldSkipConfirmation,
             tag: 4,
             type: :bool
           }}
        end

        def field_def("shouldSkipConfirmation") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shouldSkipConfirmation",
             kind: {:scalar, false},
             label: :optional,
             name: :shouldSkipConfirmation,
             tag: 4,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:embeddedContent) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "embeddedContent",
             kind: {:scalar, nil},
             label: :optional,
             name: :embeddedContent,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.EmbeddedContent}
           }}
        end

        def field_def("embeddedContent") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "embeddedContent",
             kind: {:scalar, nil},
             label: :optional,
             name: :embeddedContent,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.EmbeddedContent}
           }}
        end

        []
      ),
      (
        def field_def(:embeddedAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "embeddedAction",
             kind: {:oneof, :action},
             label: :optional,
             name: :embeddedAction,
             tag: 6,
             type: :bool
           }}
        end

        def field_def("embeddedAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "embeddedAction",
             kind: {:oneof, :action},
             label: :optional,
             name: :embeddedAction,
             tag: 6,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:tapAction) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tapAction",
             kind: {:oneof, :action},
             label: :optional,
             name: :tapAction,
             tag: 7,
             type: {:message, WAWebProtobufsE2E.TapLinkAction}
           }}
        end

        def field_def("tapAction") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tapAction",
             kind: {:oneof, :action},
             label: :optional,
             name: :tapAction,
             tag: 7,
             type: {:message, WAWebProtobufsE2E.TapLinkAction}
           }}
        end

        []
      ),
      (
        def field_def(:statusLinkType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusLinkType",
             kind: {:scalar, :RASTERIZED_LINK_PREVIEW},
             label: :optional,
             name: :statusLinkType,
             tag: 8,
             type: {:enum, WAWebProtobufsE2E.InteractiveAnnotation.StatusLinkType}
           }}
        end

        def field_def("statusLinkType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusLinkType",
             kind: {:scalar, :RASTERIZED_LINK_PREVIEW},
             label: :optional,
             name: :statusLinkType,
             tag: 8,
             type: {:enum, WAWebProtobufsE2E.InteractiveAnnotation.StatusLinkType}
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
    def default(:polygonVertices) do
      {:error, :no_default_value}
    end,
    def default(:location) do
      {:error, :no_default_value}
    end,
    def default(:newsletter) do
      {:error, :no_default_value}
    end,
    def default(:shouldSkipConfirmation) do
      {:ok, false}
    end,
    def default(:embeddedContent) do
      {:ok, nil}
    end,
    def default(:embeddedAction) do
      {:error, :no_default_value}
    end,
    def default(:tapAction) do
      {:error, :no_default_value}
    end,
    def default(:statusLinkType) do
      {:ok, :RASTERIZED_LINK_PREVIEW}
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
