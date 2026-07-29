# credo:disable-for-this-file
defmodule WAWebProtobufsAICommonDeprecated.AIRichResponseLatexMetadata.AIRichResponseLatexExpression do
  @moduledoc false
  defstruct latexExpression: nil,
            URL: nil,
            width: nil,
            height: nil,
            fontHeight: nil,
            imageTopPadding: nil,
            imageLeadingPadding: nil,
            imageBottomPadding: nil,
            imageTrailingPadding: nil,
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
        |> encode_latexExpression(msg)
        |> encode_URL(msg)
        |> encode_width(msg)
        |> encode_height(msg)
        |> encode_fontHeight(msg)
        |> encode_imageTopPadding(msg)
        |> encode_imageLeadingPadding(msg)
        |> encode_imageBottomPadding(msg)
        |> encode_imageTrailingPadding(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_latexExpression(acc, msg) do
        try do
          case msg.latexExpression do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.latexExpression)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:latexExpression, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_URL(acc, msg) do
        try do
          case msg."URL" do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg."URL")]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:URL, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_width(acc, msg) do
        try do
          case msg.width do
            nil -> acc
            _ -> [acc, "\x19", Protox.Encode.encode_double(msg.width)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:width, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_height(acc, msg) do
        try do
          case msg.height do
            nil -> acc
            _ -> [acc, "!", Protox.Encode.encode_double(msg.height)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:height, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fontHeight(acc, msg) do
        try do
          case msg.fontHeight do
            nil -> acc
            _ -> [acc, ")", Protox.Encode.encode_double(msg.fontHeight)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fontHeight, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_imageTopPadding(acc, msg) do
        try do
          case msg.imageTopPadding do
            nil -> acc
            _ -> [acc, "1", Protox.Encode.encode_double(msg.imageTopPadding)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imageTopPadding, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_imageLeadingPadding(acc, msg) do
        try do
          case msg.imageLeadingPadding do
            nil -> acc
            _ -> [acc, "9", Protox.Encode.encode_double(msg.imageLeadingPadding)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imageLeadingPadding, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_imageBottomPadding(acc, msg) do
        try do
          case msg.imageBottomPadding do
            nil -> acc
            _ -> [acc, "A", Protox.Encode.encode_double(msg.imageBottomPadding)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imageBottomPadding, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_imageTrailingPadding(acc, msg) do
        try do
          case msg.imageTrailingPadding do
            nil -> acc
            _ -> [acc, "I", Protox.Encode.encode_double(msg.imageTrailingPadding)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imageTrailingPadding, "invalid field value"),
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
          parse_key_value(
            bytes,
            struct(
              WAWebProtobufsAICommonDeprecated.AIRichResponseLatexMetadata.AIRichResponseLatexExpression
            )
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
              {[latexExpression: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[URL: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[width: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[height: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[fontHeight: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[imageTopPadding: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[imageLeadingPadding: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[imageBottomPadding: value], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[imageTrailingPadding: value], rest}

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
        WAWebProtobufsAICommonDeprecated.AIRichResponseLatexMetadata.AIRichResponseLatexExpression,
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
        1 => {:latexExpression, {:scalar, ""}, :string},
        2 => {:URL, {:scalar, ""}, :string},
        3 => {:width, {:scalar, 0.0}, :double},
        4 => {:height, {:scalar, 0.0}, :double},
        5 => {:fontHeight, {:scalar, 0.0}, :double},
        6 => {:imageTopPadding, {:scalar, 0.0}, :double},
        7 => {:imageLeadingPadding, {:scalar, 0.0}, :double},
        8 => {:imageBottomPadding, {:scalar, 0.0}, :double},
        9 => {:imageTrailingPadding, {:scalar, 0.0}, :double}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        URL: {2, {:scalar, ""}, :string},
        fontHeight: {5, {:scalar, 0.0}, :double},
        height: {4, {:scalar, 0.0}, :double},
        imageBottomPadding: {8, {:scalar, 0.0}, :double},
        imageLeadingPadding: {7, {:scalar, 0.0}, :double},
        imageTopPadding: {6, {:scalar, 0.0}, :double},
        imageTrailingPadding: {9, {:scalar, 0.0}, :double},
        latexExpression: {1, {:scalar, ""}, :string},
        width: {3, {:scalar, 0.0}, :double}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "latexExpression",
          kind: {:scalar, ""},
          label: :optional,
          name: :latexExpression,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "URL",
          kind: {:scalar, ""},
          label: :optional,
          name: :URL,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "width",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :width,
          tag: 3,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "height",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :height,
          tag: 4,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "fontHeight",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :fontHeight,
          tag: 5,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "imageTopPadding",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :imageTopPadding,
          tag: 6,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "imageLeadingPadding",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :imageLeadingPadding,
          tag: 7,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "imageBottomPadding",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :imageBottomPadding,
          tag: 8,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "imageTrailingPadding",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :imageTrailingPadding,
          tag: 9,
          type: :double
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:latexExpression) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "latexExpression",
             kind: {:scalar, ""},
             label: :optional,
             name: :latexExpression,
             tag: 1,
             type: :string
           }}
        end

        def field_def("latexExpression") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "latexExpression",
             kind: {:scalar, ""},
             label: :optional,
             name: :latexExpression,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:URL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "URL",
             kind: {:scalar, ""},
             label: :optional,
             name: :URL,
             tag: 2,
             type: :string
           }}
        end

        def field_def("URL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "URL",
             kind: {:scalar, ""},
             label: :optional,
             name: :URL,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:width) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "width",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :width,
             tag: 3,
             type: :double
           }}
        end

        def field_def("width") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "width",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :width,
             tag: 3,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:height) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "height",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :height,
             tag: 4,
             type: :double
           }}
        end

        def field_def("height") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "height",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :height,
             tag: 4,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:fontHeight) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fontHeight",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :fontHeight,
             tag: 5,
             type: :double
           }}
        end

        def field_def("fontHeight") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fontHeight",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :fontHeight,
             tag: 5,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:imageTopPadding) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageTopPadding",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :imageTopPadding,
             tag: 6,
             type: :double
           }}
        end

        def field_def("imageTopPadding") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageTopPadding",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :imageTopPadding,
             tag: 6,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:imageLeadingPadding) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageLeadingPadding",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :imageLeadingPadding,
             tag: 7,
             type: :double
           }}
        end

        def field_def("imageLeadingPadding") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageLeadingPadding",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :imageLeadingPadding,
             tag: 7,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:imageBottomPadding) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageBottomPadding",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :imageBottomPadding,
             tag: 8,
             type: :double
           }}
        end

        def field_def("imageBottomPadding") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageBottomPadding",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :imageBottomPadding,
             tag: 8,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:imageTrailingPadding) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageTrailingPadding",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :imageTrailingPadding,
             tag: 9,
             type: :double
           }}
        end

        def field_def("imageTrailingPadding") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageTrailingPadding",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :imageTrailingPadding,
             tag: 9,
             type: :double
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
    def default(:latexExpression) do
      {:ok, ""}
    end,
    def default(:URL) do
      {:ok, ""}
    end,
    def default(:width) do
      {:ok, 0.0}
    end,
    def default(:height) do
      {:ok, 0.0}
    end,
    def default(:fontHeight) do
      {:ok, 0.0}
    end,
    def default(:imageTopPadding) do
      {:ok, 0.0}
    end,
    def default(:imageLeadingPadding) do
      {:ok, 0.0}
    end,
    def default(:imageBottomPadding) do
      {:ok, 0.0}
    end,
    def default(:imageTrailingPadding) do
      {:ok, 0.0}
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
