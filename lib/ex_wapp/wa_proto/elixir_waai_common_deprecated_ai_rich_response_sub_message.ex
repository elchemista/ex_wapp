# credo:disable-for-this-file
defmodule WAAICommonDeprecated.AIRichResponseSubMessage do
  @moduledoc false
  defstruct messageType: nil,
            gridImageMetadata: nil,
            messageText: nil,
            imageMetadata: nil,
            codeMetadata: nil,
            tableMetadata: nil,
            dynamicMetadata: nil,
            latexMetadata: nil,
            mapMetadata: nil,
            contentItemsMetadata: nil,
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
        |> encode_messageType(msg)
        |> encode_gridImageMetadata(msg)
        |> encode_messageText(msg)
        |> encode_imageMetadata(msg)
        |> encode_codeMetadata(msg)
        |> encode_tableMetadata(msg)
        |> encode_dynamicMetadata(msg)
        |> encode_latexMetadata(msg)
        |> encode_mapMetadata(msg)
        |> encode_contentItemsMetadata(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_messageType(acc, msg) do
        try do
          case msg.messageType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.messageType
                |> WAAICommonDeprecated.AIRichResponseSubMessageType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_gridImageMetadata(acc, msg) do
        try do
          case msg.gridImageMetadata do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_message(msg.gridImageMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:gridImageMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messageText(acc, msg) do
        try do
          case msg.messageText do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.messageText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageText, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_imageMetadata(acc, msg) do
        try do
          case msg.imageMetadata do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_message(msg.imageMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imageMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_codeMetadata(acc, msg) do
        try do
          case msg.codeMetadata do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_message(msg.codeMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:codeMetadata, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_tableMetadata(acc, msg) do
        try do
          case msg.tableMetadata do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_message(msg.tableMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:tableMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_dynamicMetadata(acc, msg) do
        try do
          case msg.dynamicMetadata do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_message(msg.dynamicMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:dynamicMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_latexMetadata(acc, msg) do
        try do
          case msg.latexMetadata do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.latexMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:latexMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_mapMetadata(acc, msg) do
        try do
          case msg.mapMetadata do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_message(msg.mapMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mapMetadata, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_contentItemsMetadata(acc, msg) do
        try do
          case msg.contentItemsMetadata do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_message(msg.contentItemsMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contentItemsMetadata, "invalid field value"),
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
          parse_key_value(bytes, struct(WAAICommonDeprecated.AIRichResponseSubMessage))
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
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAAICommonDeprecated.AIRichResponseSubMessageType)

              {[messageType: value], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 gridImageMetadata:
                   Protox.MergeMessage.merge(
                     msg.gridImageMetadata,
                     WAAICommonDeprecated.AIRichResponseGridImageMetadata.decode!(delimited)
                   )
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[messageText: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 imageMetadata:
                   Protox.MergeMessage.merge(
                     msg.imageMetadata,
                     WAAICommonDeprecated.AIRichResponseInlineImageMetadata.decode!(delimited)
                   )
               ], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 codeMetadata:
                   Protox.MergeMessage.merge(
                     msg.codeMetadata,
                     WAAICommonDeprecated.AIRichResponseCodeMetadata.decode!(delimited)
                   )
               ], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 tableMetadata:
                   Protox.MergeMessage.merge(
                     msg.tableMetadata,
                     WAAICommonDeprecated.AIRichResponseTableMetadata.decode!(delimited)
                   )
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 dynamicMetadata:
                   Protox.MergeMessage.merge(
                     msg.dynamicMetadata,
                     WAAICommonDeprecated.AIRichResponseDynamicMetadata.decode!(delimited)
                   )
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 latexMetadata:
                   Protox.MergeMessage.merge(
                     msg.latexMetadata,
                     WAAICommonDeprecated.AIRichResponseLatexMetadata.decode!(delimited)
                   )
               ], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 mapMetadata:
                   Protox.MergeMessage.merge(
                     msg.mapMetadata,
                     WAAICommonDeprecated.AIRichResponseMapMetadata.decode!(delimited)
                   )
               ], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contentItemsMetadata:
                   Protox.MergeMessage.merge(
                     msg.contentItemsMetadata,
                     WAAICommonDeprecated.AIRichResponseContentItemsMetadata.decode!(delimited)
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
        WAAICommonDeprecated.AIRichResponseSubMessage,
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
          {:messageType, {:scalar, :AI_RICH_RESPONSE_UNKNOWN},
           {:enum, WAAICommonDeprecated.AIRichResponseSubMessageType}},
        2 =>
          {:gridImageMetadata, {:scalar, nil},
           {:message, WAAICommonDeprecated.AIRichResponseGridImageMetadata}},
        3 => {:messageText, {:scalar, ""}, :string},
        4 =>
          {:imageMetadata, {:scalar, nil},
           {:message, WAAICommonDeprecated.AIRichResponseInlineImageMetadata}},
        5 =>
          {:codeMetadata, {:scalar, nil},
           {:message, WAAICommonDeprecated.AIRichResponseCodeMetadata}},
        6 =>
          {:tableMetadata, {:scalar, nil},
           {:message, WAAICommonDeprecated.AIRichResponseTableMetadata}},
        7 =>
          {:dynamicMetadata, {:scalar, nil},
           {:message, WAAICommonDeprecated.AIRichResponseDynamicMetadata}},
        8 =>
          {:latexMetadata, {:scalar, nil},
           {:message, WAAICommonDeprecated.AIRichResponseLatexMetadata}},
        9 =>
          {:mapMetadata, {:scalar, nil},
           {:message, WAAICommonDeprecated.AIRichResponseMapMetadata}},
        10 =>
          {:contentItemsMetadata, {:scalar, nil},
           {:message, WAAICommonDeprecated.AIRichResponseContentItemsMetadata}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        codeMetadata:
          {5, {:scalar, nil}, {:message, WAAICommonDeprecated.AIRichResponseCodeMetadata}},
        contentItemsMetadata:
          {10, {:scalar, nil},
           {:message, WAAICommonDeprecated.AIRichResponseContentItemsMetadata}},
        dynamicMetadata:
          {7, {:scalar, nil}, {:message, WAAICommonDeprecated.AIRichResponseDynamicMetadata}},
        gridImageMetadata:
          {2, {:scalar, nil}, {:message, WAAICommonDeprecated.AIRichResponseGridImageMetadata}},
        imageMetadata:
          {4, {:scalar, nil}, {:message, WAAICommonDeprecated.AIRichResponseInlineImageMetadata}},
        latexMetadata:
          {8, {:scalar, nil}, {:message, WAAICommonDeprecated.AIRichResponseLatexMetadata}},
        mapMetadata:
          {9, {:scalar, nil}, {:message, WAAICommonDeprecated.AIRichResponseMapMetadata}},
        messageText: {3, {:scalar, ""}, :string},
        messageType:
          {1, {:scalar, :AI_RICH_RESPONSE_UNKNOWN},
           {:enum, WAAICommonDeprecated.AIRichResponseSubMessageType}},
        tableMetadata:
          {6, {:scalar, nil}, {:message, WAAICommonDeprecated.AIRichResponseTableMetadata}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "messageType",
          kind: {:scalar, :AI_RICH_RESPONSE_UNKNOWN},
          label: :optional,
          name: :messageType,
          tag: 1,
          type: {:enum, WAAICommonDeprecated.AIRichResponseSubMessageType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "gridImageMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :gridImageMetadata,
          tag: 2,
          type: {:message, WAAICommonDeprecated.AIRichResponseGridImageMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageText",
          kind: {:scalar, ""},
          label: :optional,
          name: :messageText,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "imageMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :imageMetadata,
          tag: 4,
          type: {:message, WAAICommonDeprecated.AIRichResponseInlineImageMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "codeMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :codeMetadata,
          tag: 5,
          type: {:message, WAAICommonDeprecated.AIRichResponseCodeMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "tableMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :tableMetadata,
          tag: 6,
          type: {:message, WAAICommonDeprecated.AIRichResponseTableMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "dynamicMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :dynamicMetadata,
          tag: 7,
          type: {:message, WAAICommonDeprecated.AIRichResponseDynamicMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "latexMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :latexMetadata,
          tag: 8,
          type: {:message, WAAICommonDeprecated.AIRichResponseLatexMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "mapMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :mapMetadata,
          tag: 9,
          type: {:message, WAAICommonDeprecated.AIRichResponseMapMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "contentItemsMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :contentItemsMetadata,
          tag: 10,
          type: {:message, WAAICommonDeprecated.AIRichResponseContentItemsMetadata}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:messageType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageType",
             kind: {:scalar, :AI_RICH_RESPONSE_UNKNOWN},
             label: :optional,
             name: :messageType,
             tag: 1,
             type: {:enum, WAAICommonDeprecated.AIRichResponseSubMessageType}
           }}
        end

        def field_def("messageType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageType",
             kind: {:scalar, :AI_RICH_RESPONSE_UNKNOWN},
             label: :optional,
             name: :messageType,
             tag: 1,
             type: {:enum, WAAICommonDeprecated.AIRichResponseSubMessageType}
           }}
        end

        []
      ),
      (
        def field_def(:gridImageMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "gridImageMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :gridImageMetadata,
             tag: 2,
             type: {:message, WAAICommonDeprecated.AIRichResponseGridImageMetadata}
           }}
        end

        def field_def("gridImageMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "gridImageMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :gridImageMetadata,
             tag: 2,
             type: {:message, WAAICommonDeprecated.AIRichResponseGridImageMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:messageText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageText",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageText,
             tag: 3,
             type: :string
           }}
        end

        def field_def("messageText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageText",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageText,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:imageMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :imageMetadata,
             tag: 4,
             type: {:message, WAAICommonDeprecated.AIRichResponseInlineImageMetadata}
           }}
        end

        def field_def("imageMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :imageMetadata,
             tag: 4,
             type: {:message, WAAICommonDeprecated.AIRichResponseInlineImageMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:codeMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "codeMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :codeMetadata,
             tag: 5,
             type: {:message, WAAICommonDeprecated.AIRichResponseCodeMetadata}
           }}
        end

        def field_def("codeMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "codeMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :codeMetadata,
             tag: 5,
             type: {:message, WAAICommonDeprecated.AIRichResponseCodeMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:tableMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tableMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :tableMetadata,
             tag: 6,
             type: {:message, WAAICommonDeprecated.AIRichResponseTableMetadata}
           }}
        end

        def field_def("tableMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tableMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :tableMetadata,
             tag: 6,
             type: {:message, WAAICommonDeprecated.AIRichResponseTableMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:dynamicMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "dynamicMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :dynamicMetadata,
             tag: 7,
             type: {:message, WAAICommonDeprecated.AIRichResponseDynamicMetadata}
           }}
        end

        def field_def("dynamicMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "dynamicMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :dynamicMetadata,
             tag: 7,
             type: {:message, WAAICommonDeprecated.AIRichResponseDynamicMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:latexMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "latexMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :latexMetadata,
             tag: 8,
             type: {:message, WAAICommonDeprecated.AIRichResponseLatexMetadata}
           }}
        end

        def field_def("latexMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "latexMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :latexMetadata,
             tag: 8,
             type: {:message, WAAICommonDeprecated.AIRichResponseLatexMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:mapMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mapMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :mapMetadata,
             tag: 9,
             type: {:message, WAAICommonDeprecated.AIRichResponseMapMetadata}
           }}
        end

        def field_def("mapMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mapMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :mapMetadata,
             tag: 9,
             type: {:message, WAAICommonDeprecated.AIRichResponseMapMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:contentItemsMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contentItemsMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :contentItemsMetadata,
             tag: 10,
             type: {:message, WAAICommonDeprecated.AIRichResponseContentItemsMetadata}
           }}
        end

        def field_def("contentItemsMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contentItemsMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :contentItemsMetadata,
             tag: 10,
             type: {:message, WAAICommonDeprecated.AIRichResponseContentItemsMetadata}
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
    def default(:messageType) do
      {:ok, :AI_RICH_RESPONSE_UNKNOWN}
    end,
    def default(:gridImageMetadata) do
      {:ok, nil}
    end,
    def default(:messageText) do
      {:ok, ""}
    end,
    def default(:imageMetadata) do
      {:ok, nil}
    end,
    def default(:codeMetadata) do
      {:ok, nil}
    end,
    def default(:tableMetadata) do
      {:ok, nil}
    end,
    def default(:dynamicMetadata) do
      {:ok, nil}
    end,
    def default(:latexMetadata) do
      {:ok, nil}
    end,
    def default(:mapMetadata) do
      {:ok, nil}
    end,
    def default(:contentItemsMetadata) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waAICommonDeprecated",
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
