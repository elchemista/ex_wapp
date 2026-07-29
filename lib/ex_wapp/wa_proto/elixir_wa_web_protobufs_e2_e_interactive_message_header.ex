# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.InteractiveMessage.Header do
  @moduledoc false
  defstruct title: nil,
            subtitle: nil,
            media: nil,
            hasMediaAttachment: nil,
            bloksWidget: nil,
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
        |> encode_media(msg)
        |> encode_title(msg)
        |> encode_subtitle(msg)
        |> encode_hasMediaAttachment(msg)
        |> encode_bloksWidget(msg)
        |> encode_unknown_fields(msg)
      end
    )

    [
      defp encode_media(acc, msg) do
        case msg.media do
          nil -> acc
          {:documentMessage, _field_value} -> encode_documentMessage(acc, msg)
          {:imageMessage, _field_value} -> encode_imageMessage(acc, msg)
          {:JPEGThumbnail, _field_value} -> encode_JPEGThumbnail(acc, msg)
          {:videoMessage, _field_value} -> encode_videoMessage(acc, msg)
          {:locationMessage, _field_value} -> encode_locationMessage(acc, msg)
          {:productMessage, _field_value} -> encode_productMessage(acc, msg)
        end
      end
    ]

    [
      defp encode_title(acc, msg) do
        try do
          case msg.title do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.title)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:title, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_subtitle(acc, msg) do
        try do
          case msg.subtitle do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.subtitle)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:subtitle, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_documentMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.media
          [acc, "\x1A", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:documentMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_imageMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.media
          [acc, "\"", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imageMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_hasMediaAttachment(acc, msg) do
        try do
          case msg.hasMediaAttachment do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_bool(msg.hasMediaAttachment)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:hasMediaAttachment, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_JPEGThumbnail(acc, msg) do
        try do
          {_, child_field_value} = msg.media
          [acc, "2", Protox.Encode.encode_bytes(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:JPEGThumbnail, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_videoMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.media
          [acc, ":", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:videoMessage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_locationMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.media
          [acc, "B", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:locationMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_productMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.media
          [acc, "J", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:productMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_bloksWidget(acc, msg) do
        try do
          case msg.bloksWidget do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_message(msg.bloksWidget)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:bloksWidget, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.InteractiveMessage.Header))
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
              {[title: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[subtitle: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.media do
                   {:documentMessage, previous_value} ->
                     {:media,
                      {:documentMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.DocumentMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:media,
                      {:documentMessage, WAWebProtobufsE2E.DocumentMessage.decode!(delimited)}}
                 end
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.media do
                   {:imageMessage, previous_value} ->
                     {:media,
                      {:imageMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.ImageMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:media, {:imageMessage, WAWebProtobufsE2E.ImageMessage.decode!(delimited)}}
                 end
               ], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[hasMediaAttachment: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[media: {:JPEGThumbnail, delimited}], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.media do
                   {:videoMessage, previous_value} ->
                     {:media,
                      {:videoMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.VideoMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:media, {:videoMessage, WAWebProtobufsE2E.VideoMessage.decode!(delimited)}}
                 end
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.media do
                   {:locationMessage, previous_value} ->
                     {:media,
                      {:locationMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.LocationMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:media,
                      {:locationMessage, WAWebProtobufsE2E.LocationMessage.decode!(delimited)}}
                 end
               ], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.media do
                   {:productMessage, previous_value} ->
                     {:media,
                      {:productMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.ProductMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:media,
                      {:productMessage, WAWebProtobufsE2E.ProductMessage.decode!(delimited)}}
                 end
               ], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 bloksWidget:
                   Protox.MergeMessage.merge(
                     msg.bloksWidget,
                     WAWebProtobufsE2E.InteractiveMessage.BloksWidget.decode!(delimited)
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
        WAWebProtobufsE2E.InteractiveMessage.Header,
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
        1 => {:title, {:scalar, ""}, :string},
        2 => {:subtitle, {:scalar, ""}, :string},
        3 => {:documentMessage, {:oneof, :media}, {:message, WAWebProtobufsE2E.DocumentMessage}},
        4 => {:imageMessage, {:oneof, :media}, {:message, WAWebProtobufsE2E.ImageMessage}},
        5 => {:hasMediaAttachment, {:scalar, false}, :bool},
        6 => {:JPEGThumbnail, {:oneof, :media}, :bytes},
        7 => {:videoMessage, {:oneof, :media}, {:message, WAWebProtobufsE2E.VideoMessage}},
        8 => {:locationMessage, {:oneof, :media}, {:message, WAWebProtobufsE2E.LocationMessage}},
        9 => {:productMessage, {:oneof, :media}, {:message, WAWebProtobufsE2E.ProductMessage}},
        10 =>
          {:bloksWidget, {:scalar, nil},
           {:message, WAWebProtobufsE2E.InteractiveMessage.BloksWidget}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        JPEGThumbnail: {6, {:oneof, :media}, :bytes},
        bloksWidget:
          {10, {:scalar, nil}, {:message, WAWebProtobufsE2E.InteractiveMessage.BloksWidget}},
        documentMessage: {3, {:oneof, :media}, {:message, WAWebProtobufsE2E.DocumentMessage}},
        hasMediaAttachment: {5, {:scalar, false}, :bool},
        imageMessage: {4, {:oneof, :media}, {:message, WAWebProtobufsE2E.ImageMessage}},
        locationMessage: {8, {:oneof, :media}, {:message, WAWebProtobufsE2E.LocationMessage}},
        productMessage: {9, {:oneof, :media}, {:message, WAWebProtobufsE2E.ProductMessage}},
        subtitle: {2, {:scalar, ""}, :string},
        title: {1, {:scalar, ""}, :string},
        videoMessage: {7, {:oneof, :media}, {:message, WAWebProtobufsE2E.VideoMessage}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "title",
          kind: {:scalar, ""},
          label: :optional,
          name: :title,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "subtitle",
          kind: {:scalar, ""},
          label: :optional,
          name: :subtitle,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "documentMessage",
          kind: {:oneof, :media},
          label: :optional,
          name: :documentMessage,
          tag: 3,
          type: {:message, WAWebProtobufsE2E.DocumentMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "imageMessage",
          kind: {:oneof, :media},
          label: :optional,
          name: :imageMessage,
          tag: 4,
          type: {:message, WAWebProtobufsE2E.ImageMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "hasMediaAttachment",
          kind: {:scalar, false},
          label: :optional,
          name: :hasMediaAttachment,
          tag: 5,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "JPEGThumbnail",
          kind: {:oneof, :media},
          label: :optional,
          name: :JPEGThumbnail,
          tag: 6,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "videoMessage",
          kind: {:oneof, :media},
          label: :optional,
          name: :videoMessage,
          tag: 7,
          type: {:message, WAWebProtobufsE2E.VideoMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "locationMessage",
          kind: {:oneof, :media},
          label: :optional,
          name: :locationMessage,
          tag: 8,
          type: {:message, WAWebProtobufsE2E.LocationMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "productMessage",
          kind: {:oneof, :media},
          label: :optional,
          name: :productMessage,
          tag: 9,
          type: {:message, WAWebProtobufsE2E.ProductMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "bloksWidget",
          kind: {:scalar, nil},
          label: :optional,
          name: :bloksWidget,
          tag: 10,
          type: {:message, WAWebProtobufsE2E.InteractiveMessage.BloksWidget}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:title) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "title",
             kind: {:scalar, ""},
             label: :optional,
             name: :title,
             tag: 1,
             type: :string
           }}
        end

        def field_def("title") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "title",
             kind: {:scalar, ""},
             label: :optional,
             name: :title,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:subtitle) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "subtitle",
             kind: {:scalar, ""},
             label: :optional,
             name: :subtitle,
             tag: 2,
             type: :string
           }}
        end

        def field_def("subtitle") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "subtitle",
             kind: {:scalar, ""},
             label: :optional,
             name: :subtitle,
             tag: 2,
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
             kind: {:oneof, :media},
             label: :optional,
             name: :documentMessage,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.DocumentMessage}
           }}
        end

        def field_def("documentMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "documentMessage",
             kind: {:oneof, :media},
             label: :optional,
             name: :documentMessage,
             tag: 3,
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
             kind: {:oneof, :media},
             label: :optional,
             name: :imageMessage,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.ImageMessage}
           }}
        end

        def field_def("imageMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageMessage",
             kind: {:oneof, :media},
             label: :optional,
             name: :imageMessage,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.ImageMessage}
           }}
        end

        []
      ),
      (
        def field_def(:hasMediaAttachment) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hasMediaAttachment",
             kind: {:scalar, false},
             label: :optional,
             name: :hasMediaAttachment,
             tag: 5,
             type: :bool
           }}
        end

        def field_def("hasMediaAttachment") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hasMediaAttachment",
             kind: {:scalar, false},
             label: :optional,
             name: :hasMediaAttachment,
             tag: 5,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:JPEGThumbnail) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "JPEGThumbnail",
             kind: {:oneof, :media},
             label: :optional,
             name: :JPEGThumbnail,
             tag: 6,
             type: :bytes
           }}
        end

        def field_def("JPEGThumbnail") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "JPEGThumbnail",
             kind: {:oneof, :media},
             label: :optional,
             name: :JPEGThumbnail,
             tag: 6,
             type: :bytes
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
             kind: {:oneof, :media},
             label: :optional,
             name: :videoMessage,
             tag: 7,
             type: {:message, WAWebProtobufsE2E.VideoMessage}
           }}
        end

        def field_def("videoMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoMessage",
             kind: {:oneof, :media},
             label: :optional,
             name: :videoMessage,
             tag: 7,
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
             kind: {:oneof, :media},
             label: :optional,
             name: :locationMessage,
             tag: 8,
             type: {:message, WAWebProtobufsE2E.LocationMessage}
           }}
        end

        def field_def("locationMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "locationMessage",
             kind: {:oneof, :media},
             label: :optional,
             name: :locationMessage,
             tag: 8,
             type: {:message, WAWebProtobufsE2E.LocationMessage}
           }}
        end

        []
      ),
      (
        def field_def(:productMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "productMessage",
             kind: {:oneof, :media},
             label: :optional,
             name: :productMessage,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.ProductMessage}
           }}
        end

        def field_def("productMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "productMessage",
             kind: {:oneof, :media},
             label: :optional,
             name: :productMessage,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.ProductMessage}
           }}
        end

        []
      ),
      (
        def field_def(:bloksWidget) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bloksWidget",
             kind: {:scalar, nil},
             label: :optional,
             name: :bloksWidget,
             tag: 10,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.BloksWidget}
           }}
        end

        def field_def("bloksWidget") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bloksWidget",
             kind: {:scalar, nil},
             label: :optional,
             name: :bloksWidget,
             tag: 10,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.BloksWidget}
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
    def default(:title) do
      {:ok, ""}
    end,
    def default(:subtitle) do
      {:ok, ""}
    end,
    def default(:documentMessage) do
      {:error, :no_default_value}
    end,
    def default(:imageMessage) do
      {:error, :no_default_value}
    end,
    def default(:hasMediaAttachment) do
      {:ok, false}
    end,
    def default(:JPEGThumbnail) do
      {:error, :no_default_value}
    end,
    def default(:videoMessage) do
      {:error, :no_default_value}
    end,
    def default(:locationMessage) do
      {:error, :no_default_value}
    end,
    def default(:productMessage) do
      {:error, :no_default_value}
    end,
    def default(:bloksWidget) do
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
