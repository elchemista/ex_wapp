# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.InteractiveMessage do
  @moduledoc false
  defstruct header: nil,
            body: nil,
            footer: nil,
            interactiveMessage: nil,
            bloksWidget: nil,
            contextInfo: nil,
            urlTrackingMap: nil,
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
        |> encode_interactiveMessage(msg)
        |> encode_header(msg)
        |> encode_body(msg)
        |> encode_footer(msg)
        |> encode_bloksWidget(msg)
        |> encode_contextInfo(msg)
        |> encode_urlTrackingMap(msg)
        |> encode_unknown_fields(msg)
      end
    )

    [
      defp encode_interactiveMessage(acc, msg) do
        case msg.interactiveMessage do
          nil -> acc
          {:shopStorefrontMessage, _field_value} -> encode_shopStorefrontMessage(acc, msg)
          {:collectionMessage, _field_value} -> encode_collectionMessage(acc, msg)
          {:nativeFlowMessage, _field_value} -> encode_nativeFlowMessage(acc, msg)
          {:carouselMessage, _field_value} -> encode_carouselMessage(acc, msg)
        end
      end
    ]

    [
      defp encode_header(acc, msg) do
        try do
          case msg.header do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_message(msg.header)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:header, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_body(acc, msg) do
        try do
          case msg.body do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_message(msg.body)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:body, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_footer(acc, msg) do
        try do
          case msg.footer do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_message(msg.footer)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:footer, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_shopStorefrontMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.interactiveMessage
          [acc, "\"", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:shopStorefrontMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_collectionMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.interactiveMessage
          [acc, "*", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:collectionMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_nativeFlowMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.interactiveMessage
          [acc, "2", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:nativeFlowMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_carouselMessage(acc, msg) do
        try do
          {_, child_field_value} = msg.interactiveMessage
          [acc, ":", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:carouselMessage, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_bloksWidget(acc, msg) do
        try do
          case msg.bloksWidget do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.bloksWidget)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:bloksWidget, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_contextInfo(acc, msg) do
        try do
          case msg.contextInfo do
            nil -> acc
            _ -> [acc, "z", Protox.Encode.encode_message(msg.contextInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contextInfo, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_urlTrackingMap(acc, msg) do
        try do
          case msg.urlTrackingMap do
            nil -> acc
            _ -> [acc, "\x82\x01", Protox.Encode.encode_message(msg.urlTrackingMap)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:urlTrackingMap, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.InteractiveMessage))
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
                 header:
                   Protox.MergeMessage.merge(
                     msg.header,
                     WAWebProtobufsE2E.InteractiveMessage.Header.decode!(delimited)
                   )
               ], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 body:
                   Protox.MergeMessage.merge(
                     msg.body,
                     WAWebProtobufsE2E.InteractiveMessage.Body.decode!(delimited)
                   )
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 footer:
                   Protox.MergeMessage.merge(
                     msg.footer,
                     WAWebProtobufsE2E.InteractiveMessage.Footer.decode!(delimited)
                   )
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.interactiveMessage do
                   {:shopStorefrontMessage, previous_value} ->
                     {:interactiveMessage,
                      {:shopStorefrontMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.InteractiveMessage.ShopMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:interactiveMessage,
                      {:shopStorefrontMessage,
                       WAWebProtobufsE2E.InteractiveMessage.ShopMessage.decode!(delimited)}}
                 end
               ], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.interactiveMessage do
                   {:collectionMessage, previous_value} ->
                     {:interactiveMessage,
                      {:collectionMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.InteractiveMessage.CollectionMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:interactiveMessage,
                      {:collectionMessage,
                       WAWebProtobufsE2E.InteractiveMessage.CollectionMessage.decode!(delimited)}}
                 end
               ], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.interactiveMessage do
                   {:nativeFlowMessage, previous_value} ->
                     {:interactiveMessage,
                      {:nativeFlowMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.InteractiveMessage.NativeFlowMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:interactiveMessage,
                      {:nativeFlowMessage,
                       WAWebProtobufsE2E.InteractiveMessage.NativeFlowMessage.decode!(delimited)}}
                 end
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.interactiveMessage do
                   {:carouselMessage, previous_value} ->
                     {:interactiveMessage,
                      {:carouselMessage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.InteractiveMessage.CarouselMessage.decode!(delimited)
                       )}}

                   _ ->
                     {:interactiveMessage,
                      {:carouselMessage,
                       WAWebProtobufsE2E.InteractiveMessage.CarouselMessage.decode!(delimited)}}
                 end
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 bloksWidget:
                   Protox.MergeMessage.merge(
                     msg.bloksWidget,
                     WAWebProtobufsE2E.InteractiveMessage.BloksWidget.decode!(delimited)
                   )
               ], rest}

            {15, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contextInfo:
                   Protox.MergeMessage.merge(
                     msg.contextInfo,
                     WAWebProtobufsE2E.ContextInfo.decode!(delimited)
                   )
               ], rest}

            {16, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 urlTrackingMap:
                   Protox.MergeMessage.merge(
                     msg.urlTrackingMap,
                     WAWebProtobufsE2E.UrlTrackingMap.decode!(delimited)
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
        WAWebProtobufsE2E.InteractiveMessage,
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
        1 => {:header, {:scalar, nil}, {:message, WAWebProtobufsE2E.InteractiveMessage.Header}},
        2 => {:body, {:scalar, nil}, {:message, WAWebProtobufsE2E.InteractiveMessage.Body}},
        3 => {:footer, {:scalar, nil}, {:message, WAWebProtobufsE2E.InteractiveMessage.Footer}},
        4 =>
          {:shopStorefrontMessage, {:oneof, :interactiveMessage},
           {:message, WAWebProtobufsE2E.InteractiveMessage.ShopMessage}},
        5 =>
          {:collectionMessage, {:oneof, :interactiveMessage},
           {:message, WAWebProtobufsE2E.InteractiveMessage.CollectionMessage}},
        6 =>
          {:nativeFlowMessage, {:oneof, :interactiveMessage},
           {:message, WAWebProtobufsE2E.InteractiveMessage.NativeFlowMessage}},
        7 =>
          {:carouselMessage, {:oneof, :interactiveMessage},
           {:message, WAWebProtobufsE2E.InteractiveMessage.CarouselMessage}},
        8 =>
          {:bloksWidget, {:scalar, nil},
           {:message, WAWebProtobufsE2E.InteractiveMessage.BloksWidget}},
        15 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        16 => {:urlTrackingMap, {:scalar, nil}, {:message, WAWebProtobufsE2E.UrlTrackingMap}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        bloksWidget:
          {8, {:scalar, nil}, {:message, WAWebProtobufsE2E.InteractiveMessage.BloksWidget}},
        body: {2, {:scalar, nil}, {:message, WAWebProtobufsE2E.InteractiveMessage.Body}},
        carouselMessage:
          {7, {:oneof, :interactiveMessage},
           {:message, WAWebProtobufsE2E.InteractiveMessage.CarouselMessage}},
        collectionMessage:
          {5, {:oneof, :interactiveMessage},
           {:message, WAWebProtobufsE2E.InteractiveMessage.CollectionMessage}},
        contextInfo: {15, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        footer: {3, {:scalar, nil}, {:message, WAWebProtobufsE2E.InteractiveMessage.Footer}},
        header: {1, {:scalar, nil}, {:message, WAWebProtobufsE2E.InteractiveMessage.Header}},
        nativeFlowMessage:
          {6, {:oneof, :interactiveMessage},
           {:message, WAWebProtobufsE2E.InteractiveMessage.NativeFlowMessage}},
        shopStorefrontMessage:
          {4, {:oneof, :interactiveMessage},
           {:message, WAWebProtobufsE2E.InteractiveMessage.ShopMessage}},
        urlTrackingMap: {16, {:scalar, nil}, {:message, WAWebProtobufsE2E.UrlTrackingMap}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "header",
          kind: {:scalar, nil},
          label: :optional,
          name: :header,
          tag: 1,
          type: {:message, WAWebProtobufsE2E.InteractiveMessage.Header}
        },
        %{
          __struct__: Protox.Field,
          json_name: "body",
          kind: {:scalar, nil},
          label: :optional,
          name: :body,
          tag: 2,
          type: {:message, WAWebProtobufsE2E.InteractiveMessage.Body}
        },
        %{
          __struct__: Protox.Field,
          json_name: "footer",
          kind: {:scalar, nil},
          label: :optional,
          name: :footer,
          tag: 3,
          type: {:message, WAWebProtobufsE2E.InteractiveMessage.Footer}
        },
        %{
          __struct__: Protox.Field,
          json_name: "shopStorefrontMessage",
          kind: {:oneof, :interactiveMessage},
          label: :optional,
          name: :shopStorefrontMessage,
          tag: 4,
          type: {:message, WAWebProtobufsE2E.InteractiveMessage.ShopMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "collectionMessage",
          kind: {:oneof, :interactiveMessage},
          label: :optional,
          name: :collectionMessage,
          tag: 5,
          type: {:message, WAWebProtobufsE2E.InteractiveMessage.CollectionMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "nativeFlowMessage",
          kind: {:oneof, :interactiveMessage},
          label: :optional,
          name: :nativeFlowMessage,
          tag: 6,
          type: {:message, WAWebProtobufsE2E.InteractiveMessage.NativeFlowMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "carouselMessage",
          kind: {:oneof, :interactiveMessage},
          label: :optional,
          name: :carouselMessage,
          tag: 7,
          type: {:message, WAWebProtobufsE2E.InteractiveMessage.CarouselMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "bloksWidget",
          kind: {:scalar, nil},
          label: :optional,
          name: :bloksWidget,
          tag: 8,
          type: {:message, WAWebProtobufsE2E.InteractiveMessage.BloksWidget}
        },
        %{
          __struct__: Protox.Field,
          json_name: "contextInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :contextInfo,
          tag: 15,
          type: {:message, WAWebProtobufsE2E.ContextInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "urlTrackingMap",
          kind: {:scalar, nil},
          label: :optional,
          name: :urlTrackingMap,
          tag: 16,
          type: {:message, WAWebProtobufsE2E.UrlTrackingMap}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:header) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "header",
             kind: {:scalar, nil},
             label: :optional,
             name: :header,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.Header}
           }}
        end

        def field_def("header") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "header",
             kind: {:scalar, nil},
             label: :optional,
             name: :header,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.Header}
           }}
        end

        []
      ),
      (
        def field_def(:body) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "body",
             kind: {:scalar, nil},
             label: :optional,
             name: :body,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.Body}
           }}
        end

        def field_def("body") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "body",
             kind: {:scalar, nil},
             label: :optional,
             name: :body,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.Body}
           }}
        end

        []
      ),
      (
        def field_def(:footer) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "footer",
             kind: {:scalar, nil},
             label: :optional,
             name: :footer,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.Footer}
           }}
        end

        def field_def("footer") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "footer",
             kind: {:scalar, nil},
             label: :optional,
             name: :footer,
             tag: 3,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.Footer}
           }}
        end

        []
      ),
      (
        def field_def(:shopStorefrontMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shopStorefrontMessage",
             kind: {:oneof, :interactiveMessage},
             label: :optional,
             name: :shopStorefrontMessage,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.ShopMessage}
           }}
        end

        def field_def("shopStorefrontMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shopStorefrontMessage",
             kind: {:oneof, :interactiveMessage},
             label: :optional,
             name: :shopStorefrontMessage,
             tag: 4,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.ShopMessage}
           }}
        end

        []
      ),
      (
        def field_def(:collectionMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "collectionMessage",
             kind: {:oneof, :interactiveMessage},
             label: :optional,
             name: :collectionMessage,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.CollectionMessage}
           }}
        end

        def field_def("collectionMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "collectionMessage",
             kind: {:oneof, :interactiveMessage},
             label: :optional,
             name: :collectionMessage,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.CollectionMessage}
           }}
        end

        []
      ),
      (
        def field_def(:nativeFlowMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nativeFlowMessage",
             kind: {:oneof, :interactiveMessage},
             label: :optional,
             name: :nativeFlowMessage,
             tag: 6,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.NativeFlowMessage}
           }}
        end

        def field_def("nativeFlowMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "nativeFlowMessage",
             kind: {:oneof, :interactiveMessage},
             label: :optional,
             name: :nativeFlowMessage,
             tag: 6,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.NativeFlowMessage}
           }}
        end

        []
      ),
      (
        def field_def(:carouselMessage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "carouselMessage",
             kind: {:oneof, :interactiveMessage},
             label: :optional,
             name: :carouselMessage,
             tag: 7,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.CarouselMessage}
           }}
        end

        def field_def("carouselMessage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "carouselMessage",
             kind: {:oneof, :interactiveMessage},
             label: :optional,
             name: :carouselMessage,
             tag: 7,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.CarouselMessage}
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
             tag: 8,
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
             tag: 8,
             type: {:message, WAWebProtobufsE2E.InteractiveMessage.BloksWidget}
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
             tag: 15,
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
             tag: 15,
             type: {:message, WAWebProtobufsE2E.ContextInfo}
           }}
        end

        []
      ),
      (
        def field_def(:urlTrackingMap) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "urlTrackingMap",
             kind: {:scalar, nil},
             label: :optional,
             name: :urlTrackingMap,
             tag: 16,
             type: {:message, WAWebProtobufsE2E.UrlTrackingMap}
           }}
        end

        def field_def("urlTrackingMap") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "urlTrackingMap",
             kind: {:scalar, nil},
             label: :optional,
             name: :urlTrackingMap,
             tag: 16,
             type: {:message, WAWebProtobufsE2E.UrlTrackingMap}
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
    def default(:header) do
      {:ok, nil}
    end,
    def default(:body) do
      {:ok, nil}
    end,
    def default(:footer) do
      {:ok, nil}
    end,
    def default(:shopStorefrontMessage) do
      {:error, :no_default_value}
    end,
    def default(:collectionMessage) do
      {:error, :no_default_value}
    end,
    def default(:nativeFlowMessage) do
      {:error, :no_default_value}
    end,
    def default(:carouselMessage) do
      {:error, :no_default_value}
    end,
    def default(:bloksWidget) do
      {:ok, nil}
    end,
    def default(:contextInfo) do
      {:ok, nil}
    end,
    def default(:urlTrackingMap) do
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
