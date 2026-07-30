# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.PaymentBackground do
  @moduledoc false
  defstruct ID: nil,
            fileLength: nil,
            width: nil,
            height: nil,
            mimetype: nil,
            placeholderArgb: nil,
            textArgb: nil,
            subtextArgb: nil,
            mediaData: nil,
            type: nil,
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
        |> encode_ID(msg)
        |> encode_fileLength(msg)
        |> encode_width(msg)
        |> encode_height(msg)
        |> encode_mimetype(msg)
        |> encode_placeholderArgb(msg)
        |> encode_textArgb(msg)
        |> encode_subtextArgb(msg)
        |> encode_mediaData(msg)
        |> encode_type(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_ID(acc, msg) do
        try do
          case msg."ID" do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg."ID")]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileLength(acc, msg) do
        try do
          case msg.fileLength do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_uint64(msg.fileLength)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileLength, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_width(acc, msg) do
        try do
          case msg.width do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_uint32(msg.width)]
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
            _ -> [acc, " ", Protox.Encode.encode_uint32(msg.height)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:height, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mimetype(acc, msg) do
        try do
          case msg.mimetype do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.mimetype)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mimetype, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_placeholderArgb(acc, msg) do
        try do
          case msg.placeholderArgb do
            nil -> acc
            _ -> [acc, "5", Protox.Encode.encode_fixed32(msg.placeholderArgb)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:placeholderArgb, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_textArgb(acc, msg) do
        try do
          case msg.textArgb do
            nil -> acc
            _ -> [acc, "=", Protox.Encode.encode_fixed32(msg.textArgb)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:textArgb, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_subtextArgb(acc, msg) do
        try do
          case msg.subtextArgb do
            nil -> acc
            _ -> [acc, "E", Protox.Encode.encode_fixed32(msg.subtextArgb)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:subtextArgb, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaData(acc, msg) do
        try do
          case msg.mediaData do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_message(msg.mediaData)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaData, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_type(acc, msg) do
        try do
          case msg.type do
            nil ->
              acc

            _ ->
              [
                acc,
                "P",
                msg.type
                |> WAWebProtobufsE2E.PaymentBackground.Type.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:type, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.PaymentBackground))
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
              {[ID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[fileLength: value], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[width: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[height: value], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mimetype: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_fixed32(bytes)
              {[placeholderArgb: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_fixed32(bytes)
              {[textArgb: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_fixed32(bytes)
              {[subtextArgb: value], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 mediaData:
                   Protox.MergeMessage.merge(
                     msg.mediaData,
                     WAWebProtobufsE2E.PaymentBackground.MediaData.decode!(delimited)
                   )
               ], rest}

            {10, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.PaymentBackground.Type)

              {[type: value], rest}

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
        WAWebProtobufsE2E.PaymentBackground,
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
        1 => {:ID, {:scalar, ""}, :string},
        2 => {:fileLength, {:scalar, 0}, :uint64},
        3 => {:width, {:scalar, 0}, :uint32},
        4 => {:height, {:scalar, 0}, :uint32},
        5 => {:mimetype, {:scalar, ""}, :string},
        6 => {:placeholderArgb, {:scalar, 0}, :fixed32},
        7 => {:textArgb, {:scalar, 0}, :fixed32},
        8 => {:subtextArgb, {:scalar, 0}, :fixed32},
        9 =>
          {:mediaData, {:scalar, nil}, {:message, WAWebProtobufsE2E.PaymentBackground.MediaData}},
        10 => {:type, {:scalar, :UNKNOWN}, {:enum, WAWebProtobufsE2E.PaymentBackground.Type}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        ID: {1, {:scalar, ""}, :string},
        fileLength: {2, {:scalar, 0}, :uint64},
        height: {4, {:scalar, 0}, :uint32},
        mediaData: {9, {:scalar, nil}, {:message, WAWebProtobufsE2E.PaymentBackground.MediaData}},
        mimetype: {5, {:scalar, ""}, :string},
        placeholderArgb: {6, {:scalar, 0}, :fixed32},
        subtextArgb: {8, {:scalar, 0}, :fixed32},
        textArgb: {7, {:scalar, 0}, :fixed32},
        type: {10, {:scalar, :UNKNOWN}, {:enum, WAWebProtobufsE2E.PaymentBackground.Type}},
        width: {3, {:scalar, 0}, :uint32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "ID",
          kind: {:scalar, ""},
          label: :optional,
          name: :ID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileLength",
          kind: {:scalar, 0},
          label: :optional,
          name: :fileLength,
          tag: 2,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "width",
          kind: {:scalar, 0},
          label: :optional,
          name: :width,
          tag: 3,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "height",
          kind: {:scalar, 0},
          label: :optional,
          name: :height,
          tag: 4,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "mimetype",
          kind: {:scalar, ""},
          label: :optional,
          name: :mimetype,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "placeholderArgb",
          kind: {:scalar, 0},
          label: :optional,
          name: :placeholderArgb,
          tag: 6,
          type: :fixed32
        },
        %{
          __struct__: Protox.Field,
          json_name: "textArgb",
          kind: {:scalar, 0},
          label: :optional,
          name: :textArgb,
          tag: 7,
          type: :fixed32
        },
        %{
          __struct__: Protox.Field,
          json_name: "subtextArgb",
          kind: {:scalar, 0},
          label: :optional,
          name: :subtextArgb,
          tag: 8,
          type: :fixed32
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaData",
          kind: {:scalar, nil},
          label: :optional,
          name: :mediaData,
          tag: 9,
          type: {:message, WAWebProtobufsE2E.PaymentBackground.MediaData}
        },
        %{
          __struct__: Protox.Field,
          json_name: "type",
          kind: {:scalar, :UNKNOWN},
          label: :optional,
          name: :type,
          tag: 10,
          type: {:enum, WAWebProtobufsE2E.PaymentBackground.Type}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:ID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ID",
             kind: {:scalar, ""},
             label: :optional,
             name: :ID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("ID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ID",
             kind: {:scalar, ""},
             label: :optional,
             name: :ID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:fileLength) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileLength",
             kind: {:scalar, 0},
             label: :optional,
             name: :fileLength,
             tag: 2,
             type: :uint64
           }}
        end

        def field_def("fileLength") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileLength",
             kind: {:scalar, 0},
             label: :optional,
             name: :fileLength,
             tag: 2,
             type: :uint64
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
             kind: {:scalar, 0},
             label: :optional,
             name: :width,
             tag: 3,
             type: :uint32
           }}
        end

        def field_def("width") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "width",
             kind: {:scalar, 0},
             label: :optional,
             name: :width,
             tag: 3,
             type: :uint32
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
             kind: {:scalar, 0},
             label: :optional,
             name: :height,
             tag: 4,
             type: :uint32
           }}
        end

        def field_def("height") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "height",
             kind: {:scalar, 0},
             label: :optional,
             name: :height,
             tag: 4,
             type: :uint32
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
             tag: 5,
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
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:placeholderArgb) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "placeholderArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :placeholderArgb,
             tag: 6,
             type: :fixed32
           }}
        end

        def field_def("placeholderArgb") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "placeholderArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :placeholderArgb,
             tag: 6,
             type: :fixed32
           }}
        end

        []
      ),
      (
        def field_def(:textArgb) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "textArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :textArgb,
             tag: 7,
             type: :fixed32
           }}
        end

        def field_def("textArgb") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "textArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :textArgb,
             tag: 7,
             type: :fixed32
           }}
        end

        []
      ),
      (
        def field_def(:subtextArgb) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "subtextArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :subtextArgb,
             tag: 8,
             type: :fixed32
           }}
        end

        def field_def("subtextArgb") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "subtextArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :subtextArgb,
             tag: 8,
             type: :fixed32
           }}
        end

        []
      ),
      (
        def field_def(:mediaData) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaData",
             kind: {:scalar, nil},
             label: :optional,
             name: :mediaData,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.PaymentBackground.MediaData}
           }}
        end

        def field_def("mediaData") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaData",
             kind: {:scalar, nil},
             label: :optional,
             name: :mediaData,
             tag: 9,
             type: {:message, WAWebProtobufsE2E.PaymentBackground.MediaData}
           }}
        end

        []
      ),
      (
        def field_def(:type) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :type,
             tag: 10,
             type: {:enum, WAWebProtobufsE2E.PaymentBackground.Type}
           }}
        end

        def field_def("type") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :type,
             tag: 10,
             type: {:enum, WAWebProtobufsE2E.PaymentBackground.Type}
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
    def default(:ID) do
      {:ok, ""}
    end,
    def default(:fileLength) do
      {:ok, 0}
    end,
    def default(:width) do
      {:ok, 0}
    end,
    def default(:height) do
      {:ok, 0}
    end,
    def default(:mimetype) do
      {:ok, ""}
    end,
    def default(:placeholderArgb) do
      {:ok, 0}
    end,
    def default(:textArgb) do
      {:ok, 0}
    end,
    def default(:subtextArgb) do
      {:ok, 0}
    end,
    def default(:mediaData) do
      {:ok, nil}
    end,
    def default(:type) do
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

  @type t :: %__MODULE__{}
end
