# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.AIHomeState.AIHomeOption do
  @moduledoc false
  defstruct type: nil,
            title: nil,
            promptText: nil,
            sessionID: nil,
            imageWdsIdentifier: nil,
            imageTintColor: nil,
            imageBackgroundColor: nil,
            cardTypeID: nil,
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
        |> encode_type(msg)
        |> encode_title(msg)
        |> encode_promptText(msg)
        |> encode_sessionID(msg)
        |> encode_imageWdsIdentifier(msg)
        |> encode_imageTintColor(msg)
        |> encode_imageBackgroundColor(msg)
        |> encode_cardTypeID(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_type(acc, msg) do
        try do
          case msg.type do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.type
                |> WAWebProtobufsAICommon.AIHomeState.AIHomeOption.AIHomeActionType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:type, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_title(acc, msg) do
        try do
          case msg.title do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.title)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:title, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_promptText(acc, msg) do
        try do
          case msg.promptText do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.promptText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:promptText, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_sessionID(acc, msg) do
        try do
          case msg.sessionID do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.sessionID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:sessionID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_imageWdsIdentifier(acc, msg) do
        try do
          case msg.imageWdsIdentifier do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.imageWdsIdentifier)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imageWdsIdentifier, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_imageTintColor(acc, msg) do
        try do
          case msg.imageTintColor do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.imageTintColor)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imageTintColor, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_imageBackgroundColor(acc, msg) do
        try do
          case msg.imageBackgroundColor do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.imageBackgroundColor)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:imageBackgroundColor, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_cardTypeID(acc, msg) do
        try do
          case msg.cardTypeID do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg.cardTypeID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:cardTypeID, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsAICommon.AIHomeState.AIHomeOption))
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
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsAICommon.AIHomeState.AIHomeOption.AIHomeActionType
                )

              {[type: value], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[title: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[promptText: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[sessionID: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[imageWdsIdentifier: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[imageTintColor: Protox.Decode.validate_string!(delimited)], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[imageBackgroundColor: Protox.Decode.validate_string!(delimited)], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[cardTypeID: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufsAICommon.AIHomeState.AIHomeOption,
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
          {:type, {:scalar, :PROMPT},
           {:enum, WAWebProtobufsAICommon.AIHomeState.AIHomeOption.AIHomeActionType}},
        2 => {:title, {:scalar, ""}, :string},
        3 => {:promptText, {:scalar, ""}, :string},
        4 => {:sessionID, {:scalar, ""}, :string},
        5 => {:imageWdsIdentifier, {:scalar, ""}, :string},
        6 => {:imageTintColor, {:scalar, ""}, :string},
        7 => {:imageBackgroundColor, {:scalar, ""}, :string},
        8 => {:cardTypeID, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        cardTypeID: {8, {:scalar, ""}, :string},
        imageBackgroundColor: {7, {:scalar, ""}, :string},
        imageTintColor: {6, {:scalar, ""}, :string},
        imageWdsIdentifier: {5, {:scalar, ""}, :string},
        promptText: {3, {:scalar, ""}, :string},
        sessionID: {4, {:scalar, ""}, :string},
        title: {2, {:scalar, ""}, :string},
        type:
          {1, {:scalar, :PROMPT},
           {:enum, WAWebProtobufsAICommon.AIHomeState.AIHomeOption.AIHomeActionType}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "type",
          kind: {:scalar, :PROMPT},
          label: :optional,
          name: :type,
          tag: 1,
          type: {:enum, WAWebProtobufsAICommon.AIHomeState.AIHomeOption.AIHomeActionType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "title",
          kind: {:scalar, ""},
          label: :optional,
          name: :title,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "promptText",
          kind: {:scalar, ""},
          label: :optional,
          name: :promptText,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "sessionID",
          kind: {:scalar, ""},
          label: :optional,
          name: :sessionID,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "imageWdsIdentifier",
          kind: {:scalar, ""},
          label: :optional,
          name: :imageWdsIdentifier,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "imageTintColor",
          kind: {:scalar, ""},
          label: :optional,
          name: :imageTintColor,
          tag: 6,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "imageBackgroundColor",
          kind: {:scalar, ""},
          label: :optional,
          name: :imageBackgroundColor,
          tag: 7,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "cardTypeID",
          kind: {:scalar, ""},
          label: :optional,
          name: :cardTypeID,
          tag: 8,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:type) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, :PROMPT},
             label: :optional,
             name: :type,
             tag: 1,
             type: {:enum, WAWebProtobufsAICommon.AIHomeState.AIHomeOption.AIHomeActionType}
           }}
        end

        def field_def("type") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, :PROMPT},
             label: :optional,
             name: :type,
             tag: 1,
             type: {:enum, WAWebProtobufsAICommon.AIHomeState.AIHomeOption.AIHomeActionType}
           }}
        end

        []
      ),
      (
        def field_def(:title) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "title",
             kind: {:scalar, ""},
             label: :optional,
             name: :title,
             tag: 2,
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
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:promptText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "promptText",
             kind: {:scalar, ""},
             label: :optional,
             name: :promptText,
             tag: 3,
             type: :string
           }}
        end

        def field_def("promptText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "promptText",
             kind: {:scalar, ""},
             label: :optional,
             name: :promptText,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:sessionID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sessionID",
             kind: {:scalar, ""},
             label: :optional,
             name: :sessionID,
             tag: 4,
             type: :string
           }}
        end

        def field_def("sessionID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sessionID",
             kind: {:scalar, ""},
             label: :optional,
             name: :sessionID,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:imageWdsIdentifier) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageWdsIdentifier",
             kind: {:scalar, ""},
             label: :optional,
             name: :imageWdsIdentifier,
             tag: 5,
             type: :string
           }}
        end

        def field_def("imageWdsIdentifier") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageWdsIdentifier",
             kind: {:scalar, ""},
             label: :optional,
             name: :imageWdsIdentifier,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:imageTintColor) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageTintColor",
             kind: {:scalar, ""},
             label: :optional,
             name: :imageTintColor,
             tag: 6,
             type: :string
           }}
        end

        def field_def("imageTintColor") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageTintColor",
             kind: {:scalar, ""},
             label: :optional,
             name: :imageTintColor,
             tag: 6,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:imageBackgroundColor) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageBackgroundColor",
             kind: {:scalar, ""},
             label: :optional,
             name: :imageBackgroundColor,
             tag: 7,
             type: :string
           }}
        end

        def field_def("imageBackgroundColor") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "imageBackgroundColor",
             kind: {:scalar, ""},
             label: :optional,
             name: :imageBackgroundColor,
             tag: 7,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:cardTypeID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "cardTypeID",
             kind: {:scalar, ""},
             label: :optional,
             name: :cardTypeID,
             tag: 8,
             type: :string
           }}
        end

        def field_def("cardTypeID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "cardTypeID",
             kind: {:scalar, ""},
             label: :optional,
             name: :cardTypeID,
             tag: 8,
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
    def default(:type) do
      {:ok, :PROMPT}
    end,
    def default(:title) do
      {:ok, ""}
    end,
    def default(:promptText) do
      {:ok, ""}
    end,
    def default(:sessionID) do
      {:ok, ""}
    end,
    def default(:imageWdsIdentifier) do
      {:ok, ""}
    end,
    def default(:imageTintColor) do
      {:ok, ""}
    end,
    def default(:imageBackgroundColor) do
      {:ok, ""}
    end,
    def default(:cardTypeID) do
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

  @type t :: %__MODULE__{}
end
