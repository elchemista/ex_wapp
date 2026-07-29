# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ButtonsMessage do
  @moduledoc false
  defstruct header: nil,
            contentText: nil,
            footerText: nil,
            contextInfo: nil,
            buttons: [],
            headerType: nil,
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
        |> encode_header(msg)
        |> encode_contentText(msg)
        |> encode_footerText(msg)
        |> encode_contextInfo(msg)
        |> encode_buttons(msg)
        |> encode_headerType(msg)
        |> encode_unknown_fields(msg)
      end
    )

    [
      defp encode_header(acc, msg) do
        case msg.header do
          nil -> acc
          {:text, _field_value} -> encode_text(acc, msg)
          {:documentMessage, _field_value} -> encode_documentMessage(acc, msg)
          {:imageMessage, _field_value} -> encode_imageMessage(acc, msg)
          {:videoMessage, _field_value} -> encode_videoMessage(acc, msg)
          {:locationMessage, _field_value} -> encode_locationMessage(acc, msg)
        end
      end
    ]

    [
      defp encode_text(acc, msg) do
        try do
          {_, child_field_value} = msg.header
          [acc, "\n", Protox.Encode.encode_string(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:text, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_documentMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.header
          [acc, "\x12", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:documentMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_imageMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.header
          [acc, "\x1A", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imageMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_videoMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.header
          [acc, "\"", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:videoMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_locationMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.header
          [acc, "*", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:locationMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_contentText(acc, msg) do
        try do
          case msg.contentText do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.contentText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contentText, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_footerText(acc, msg) do
        try do
          case msg.footerText do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.footerText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:footerText, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_contextInfo(acc, msg) do
        try do
          case msg.contextInfo do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.contextInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contextInfo, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_buttons(acc, msg) do
        try do
          case msg.buttons do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "J", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:buttons, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_headerType(acc, msg) do
        try do
          case msg.headerType do
            nil ->
              acc

            _ ->
              [
                acc,
                "P",
                msg.headerType
                |> WAWebProtobufsE2E.ButtonsMessage.HeaderType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:headerType, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.ButtonsMessage))
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
              {[header: {:text, Protox.Decode.validate_string!(delimited)}], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.header do
                   {:documentMessage, previous_value} ->
                     {:header,
                      {:documentMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.DocumentMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:header,
                      {:documentMessage, WAWebProtobufsE2E.DocumentMessage.decode!(delimited)}}
                 end
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.header do
                   {:imageMessage, previous_value} ->
                     {:header,
                      {:imageMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.ImageMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:header, {:imageMessage, WAWebProtobufsE2E.ImageMessage.decode!(delimited)}}
                 end
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.header do
                   {:videoMessage, previous_value} ->
                     {:header,
                      {:videoMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.VideoMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:header, {:videoMessage, WAWebProtobufsE2E.VideoMessage.decode!(delimited)}}
                 end
               ], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.header do
                   {:locationMessage, previous_value} ->
                     {:header,
                      {:locationMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.LocationMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:header,
                      {:locationMessage, WAWebProtobufsE2E.LocationMessage.decode!(delimited)}}
                 end
               ], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[contentText: Protox.Decode.validate_string!(delimited)], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[footerText: Protox.Decode.validate_string!(delimited)], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contextInfo:
                   Protox.MergeMessage.merge(
                     msg.contextInfo,
                     WAWebProtobufsE2E.ContextInfo.decode!(delimited)
                   )
               ], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 buttons:
                   msg.buttons ++ [WAWebProtobufsE2E.ButtonsMessage.Button.decode!(delimited)]
               ], rest}

            {10, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.ButtonsMessage.HeaderType)

              {[headerType: value], rest}

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
        WAWebProtobufsE2E.ButtonsMessage,
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
        1 => {:text, {:oneof, :header}, :string},
        2 => {:documentMessage, {:oneof, :header}, {:message, WAWebProtobufsE2E.DocumentMessage}},
        3 => {:imageMessage, {:oneof, :header}, {:message, WAWebProtobufsE2E.ImageMessage}},
        4 => {:videoMessage, {:oneof, :header}, {:message, WAWebProtobufsE2E.VideoMessage}},
        5 => {:locationMessage, {:oneof, :header}, {:message, WAWebProtobufsE2E.LocationMessage}},
        6 => {:contentText, {:scalar, ""}, :string},
        7 => {:footerText, {:scalar, ""}, :string},
        8 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        9 => {:buttons, :unpacked, {:message, WAWebProtobufsE2E.ButtonsMessage.Button}},
        10 =>
          {:headerType, {:scalar, :UNKNOWN}, {:enum, WAWebProtobufsE2E.ButtonsMessage.HeaderType}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        buttons: {9, :unpacked, {:message, WAWebProtobufsE2E.ButtonsMessage.Button}},
        contentText: {6, {:scalar, ""}, :string},
        contextInfo: {8, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        documentMessage: {2, {:oneof, :header}, {:message, WAWebProtobufsE2E.DocumentMessage}},
        footerText: {7, {:scalar, ""}, :string},
        headerType:
          {10, {:scalar, :UNKNOWN}, {:enum, WAWebProtobufsE2E.ButtonsMessage.HeaderType}},
        imageMessage: {3, {:oneof, :header}, {:message, WAWebProtobufsE2E.ImageMessage}},
        locationMessage: {5, {:oneof, :header}, {:message, WAWebProtobufsE2E.LocationMessage}},
        text: {1, {:oneof, :header}, :string},
        videoMessage: {4, {:oneof, :header}, {:message, WAWebProtobufsE2E.VideoMessage}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "text",
          kind: {:oneof, :header},
          label: :optional,
          name: :text,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "documentMessage",
          kind: {:oneof, :header},
          label: :optional,
          name: :documentMessage,
          tag: 2,
          type: {:message, WAWebProtobufsE2E.DocumentMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "imageMessage",
          kind: {:oneof, :header},
          label: :optional,
          name: :imageMessage,
          tag: 3,
          type: {:message, WAWebProtobufsE2E.ImageMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "videoMessage",
          kind: {:oneof, :header},
          label: :optional,
          name: :videoMessage,
          tag: 4,
          type: {:message, WAWebProtobufsE2E.VideoMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "locationMessage",
          kind: {:oneof, :header},
          label: :optional,
          name: :locationMessage,
          tag: 5,
          type: {:message, WAWebProtobufsE2E.LocationMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "contentText",
          kind: {:scalar, ""},
          label: :optional,
          name: :contentText,
          tag: 6,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "footerText",
          kind: {:scalar, ""},
          label: :optional,
          name: :footerText,
          tag: 7,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "contextInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :contextInfo,
          tag: 8,
          type: {:message, WAWebProtobufsE2E.ContextInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "buttons",
          kind: :unpacked,
          label: :repeated,
          name: :buttons,
          tag: 9,
          type: {:message, WAWebProtobufsE2E.ButtonsMessage.Button}
        },
        %{
          __struct__: Protox.Field,
          json_name: "headerType",
          kind: {:scalar, :UNKNOWN},
          label: :optional,
          name: :headerType,
          tag: 10,
          type: {:enum, WAWebProtobufsE2E.ButtonsMessage.HeaderType}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:text) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "text",
             kind: {:oneof, :header},
             label: :optional,
             name: :text,
             tag: 1,
             type: :string
           }}
        end

        def field_def("text") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "text",
             kind: {:oneof, :header},
             label: :optional,
             name: :text,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:documentMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "documentMessage",
             kind: {:oneof, :header},
             label: :optional,
             name: :documentMessage,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.DocumentMessage}
           }}
        end

        def field_def("documentMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "documentMessage",
             kind: {:oneof, :header},
             label: :optional,
             name: :documentMessage,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.DocumentMessage}
           }}
        end

        []
      ),
      (
        def field_def(:imageMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageMessage",
             kind: {:oneof, :header},
             label: :optional,
             name: :imageMessage,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.ImageMessage}
           }}
        end

        def field_def("imageMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageMessage",
             kind: {:oneof, :header},
             label: :optional,
             name: :imageMessage,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.ImageMessage}
           }}
        end

        []
      ),
      (
        def field_def(:videoMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoMessage",
             kind: {:oneof, :header},
             label: :optional,
             name: :videoMessage,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.VideoMessage}
           }}
        end

        def field_def("videoMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoMessage",
             kind: {:oneof, :header},
             label: :optional,
             name: :videoMessage,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.VideoMessage}
           }}
        end

        []
      ),
      (
        def field_def(:locationMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "locationMessage",
             kind: {:oneof, :header},
             label: :optional,
             name: :locationMessage,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.LocationMessage}
           }}
        end

        def field_def("locationMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "locationMessage",
             kind: {:oneof, :header},
             label: :optional,
             name: :locationMessage,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.LocationMessage}
           }}
        end

        []
      ),
      (
        def field_def(:contentText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contentText",
             kind: {:scalar, ""},
             label: :optional,
             name: :contentText,
             tag: 6,
             type: :string
           }}
        end

        def field_def("contentText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contentText",
             kind: {:scalar, ""},
             label: :optional,
             name: :contentText,
             tag: 6,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:footerText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "footerText",
             kind: {:scalar, ""},
             label: :optional,
             name: :footerText,
             tag: 7,
             type: :string
           }}
        end

        def field_def("footerText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "footerText",
             kind: {:scalar, ""},
             label: :optional,
             name: :footerText,
             tag: 7,
             type: :string
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
             tag: 8,
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
             tag: 8,
             type: {:message, WAWebProtobufsE2E.ContextInfo}
           }}
        end

        []
      ),
      (
        def field_def(:buttons) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "buttons",
             kind: :unpacked,
             label: :repeated,
             name: :buttons,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.ButtonsMessage.Button}
           }}
        end

        def field_def("buttons") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "buttons",
             kind: :unpacked,
             label: :repeated,
             name: :buttons,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.ButtonsMessage.Button}
           }}
        end

        []
      ),
      (
        def field_def(:headerType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "headerType",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :headerType,
             tag: 10,
             type: {:enum, WAWebProtobufsE2E.ButtonsMessage.HeaderType}
           }}
        end

        def field_def("headerType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "headerType",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :headerType,
             tag: 10,
             type: {:enum, WAWebProtobufsE2E.ButtonsMessage.HeaderType}
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
    def default(:text) do
      {:error, :no_default_value}
    end,
    def default(:documentMessage) do
      {:error, :no_default_value}
    end,
    def default(:imageMessage) do
      {:error, :no_default_value}
    end,
    def default(:videoMessage) do
      {:error, :no_default_value}
    end,
    def default(:locationMessage) do
      {:error, :no_default_value}
    end,
    def default(:contentText) do
      {:ok, ""}
    end,
    def default(:footerText) do
      {:ok, ""}
    end,
    def default(:contextInfo) do
      {:ok, nil}
    end,
    def default(:buttons) do
      {:error, :no_default_value}
    end,
    def default(:headerType) do
      {:ok, :UNKNOWN}
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
