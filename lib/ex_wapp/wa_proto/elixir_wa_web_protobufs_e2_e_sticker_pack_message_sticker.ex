# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.StickerPackMessage.Sticker do
  @moduledoc false
  defstruct fileName: nil,
            isAnimated: nil,
            emojis: [],
            accessibilityLabel: nil,
            isLottie: nil,
            mimetype: nil,
            premium: nil,
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
        |> encode_fileName(msg)
        |> encode_isAnimated(msg)
        |> encode_emojis(msg)
        |> encode_accessibilityLabel(msg)
        |> encode_isLottie(msg)
        |> encode_mimetype(msg)
        |> encode_premium(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_fileName(acc, msg) do
        try do
          case msg.fileName do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.fileName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileName, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isAnimated(acc, msg) do
        try do
          case msg.isAnimated do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_bool(msg.isAnimated)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isAnimated, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_emojis(acc, msg) do
        try do
          case msg.emojis do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x1A", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:emojis, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_accessibilityLabel(acc, msg) do
        try do
          case msg.accessibilityLabel do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.accessibilityLabel)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:accessibilityLabel, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isLottie(acc, msg) do
        try do
          case msg.isLottie do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_bool(msg.isLottie)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isLottie, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mimetype(acc, msg) do
        try do
          case msg.mimetype do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.mimetype)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mimetype, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_premium(acc, msg) do
        try do
          case msg.premium do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_int32(msg.premium)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:premium, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.StickerPackMessage.Sticker))
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
              {[fileName: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isAnimated: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[emojis: msg.emojis ++ [Protox.Decode.validate_string!(delimited)]], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[accessibilityLabel: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isLottie: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mimetype: Protox.Decode.validate_string!(delimited)], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[premium: value], rest}

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
        WAWebProtobufsE2E.StickerPackMessage.Sticker,
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
        1 => {:fileName, {:scalar, ""}, :string},
        2 => {:isAnimated, {:scalar, false}, :bool},
        3 => {:emojis, :unpacked, :string},
        4 => {:accessibilityLabel, {:scalar, ""}, :string},
        5 => {:isLottie, {:scalar, false}, :bool},
        6 => {:mimetype, {:scalar, ""}, :string},
        7 => {:premium, {:scalar, 0}, :int32}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        accessibilityLabel: {4, {:scalar, ""}, :string},
        emojis: {3, :unpacked, :string},
        fileName: {1, {:scalar, ""}, :string},
        isAnimated: {2, {:scalar, false}, :bool},
        isLottie: {5, {:scalar, false}, :bool},
        mimetype: {6, {:scalar, ""}, :string},
        premium: {7, {:scalar, 0}, :int32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "fileName",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileName,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "isAnimated",
          kind: {:scalar, false},
          label: :optional,
          name: :isAnimated,
          tag: 2,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "emojis",
          kind: :unpacked,
          label: :repeated,
          name: :emojis,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "accessibilityLabel",
          kind: {:scalar, ""},
          label: :optional,
          name: :accessibilityLabel,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "isLottie",
          kind: {:scalar, false},
          label: :optional,
          name: :isLottie,
          tag: 5,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "mimetype",
          kind: {:scalar, ""},
          label: :optional,
          name: :mimetype,
          tag: 6,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "premium",
          kind: {:scalar, 0},
          label: :optional,
          name: :premium,
          tag: 7,
          type: :int32
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:fileName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileName",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileName,
             tag: 1,
             type: :string
           }}
        end

        def field_def("fileName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileName",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileName,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:isAnimated) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isAnimated",
             kind: {:scalar, false},
             label: :optional,
             name: :isAnimated,
             tag: 2,
             type: :bool
           }}
        end

        def field_def("isAnimated") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isAnimated",
             kind: {:scalar, false},
             label: :optional,
             name: :isAnimated,
             tag: 2,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:emojis) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "emojis",
             kind: :unpacked,
             label: :repeated,
             name: :emojis,
             tag: 3,
             type: :string
           }}
        end

        def field_def("emojis") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "emojis",
             kind: :unpacked,
             label: :repeated,
             name: :emojis,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:accessibilityLabel) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accessibilityLabel",
             kind: {:scalar, ""},
             label: :optional,
             name: :accessibilityLabel,
             tag: 4,
             type: :string
           }}
        end

        def field_def("accessibilityLabel") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accessibilityLabel",
             kind: {:scalar, ""},
             label: :optional,
             name: :accessibilityLabel,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:isLottie) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isLottie",
             kind: {:scalar, false},
             label: :optional,
             name: :isLottie,
             tag: 5,
             type: :bool
           }}
        end

        def field_def("isLottie") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isLottie",
             kind: {:scalar, false},
             label: :optional,
             name: :isLottie,
             tag: 5,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:mimetype) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mimetype",
             kind: {:scalar, ""},
             label: :optional,
             name: :mimetype,
             tag: 6,
             type: :string
           }}
        end

        def field_def("mimetype") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mimetype",
             kind: {:scalar, ""},
             label: :optional,
             name: :mimetype,
             tag: 6,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:premium) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "premium",
             kind: {:scalar, 0},
             label: :optional,
             name: :premium,
             tag: 7,
             type: :int32
           }}
        end

        def field_def("premium") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "premium",
             kind: {:scalar, 0},
             label: :optional,
             name: :premium,
             tag: 7,
             type: :int32
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
    def default(:fileName) do
      {:ok, ""}
    end,
    def default(:isAnimated) do
      {:ok, false}
    end,
    def default(:emojis) do
      {:error, :no_default_value}
    end,
    def default(:accessibilityLabel) do
      {:ok, ""}
    end,
    def default(:isLottie) do
      {:ok, false}
    end,
    def default(:mimetype) do
      {:ok, ""}
    end,
    def default(:premium) do
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
