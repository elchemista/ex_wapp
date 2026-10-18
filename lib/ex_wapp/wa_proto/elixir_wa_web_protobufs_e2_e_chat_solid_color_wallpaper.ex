# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ChatSolidColorWallpaper do
  @moduledoc false
  defstruct backgroundLightArgb: nil,
            backgroundDarkArgb: nil,
            isDoodleEnabled: nil,
            doodleLightArgb: nil,
            doodleDarkArgb: nil,
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
        |> encode_backgroundLightArgb(msg)
        |> encode_backgroundDarkArgb(msg)
        |> encode_isDoodleEnabled(msg)
        |> encode_doodleLightArgb(msg)
        |> encode_doodleDarkArgb(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_backgroundLightArgb(acc, msg) do
        try do
          case msg.backgroundLightArgb do
            nil -> acc
            _ -> [acc, "\r", Protox.Encode.encode_fixed32(msg.backgroundLightArgb)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:backgroundLightArgb, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_backgroundDarkArgb(acc, msg) do
        try do
          case msg.backgroundDarkArgb do
            nil -> acc
            _ -> [acc, "\x15", Protox.Encode.encode_fixed32(msg.backgroundDarkArgb)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:backgroundDarkArgb, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isDoodleEnabled(acc, msg) do
        try do
          case msg.isDoodleEnabled do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_bool(msg.isDoodleEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isDoodleEnabled, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_doodleLightArgb(acc, msg) do
        try do
          case msg.doodleLightArgb do
            nil -> acc
            _ -> [acc, "%", Protox.Encode.encode_fixed32(msg.doodleLightArgb)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:doodleLightArgb, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_doodleDarkArgb(acc, msg) do
        try do
          case msg.doodleDarkArgb do
            nil -> acc
            _ -> [acc, "-", Protox.Encode.encode_fixed32(msg.doodleDarkArgb)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:doodleDarkArgb, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.ChatSolidColorWallpaper))
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
              {value, rest} = Protox.Decode.parse_fixed32(bytes)
              {[backgroundLightArgb: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_fixed32(bytes)
              {[backgroundDarkArgb: value], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isDoodleEnabled: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_fixed32(bytes)
              {[doodleLightArgb: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_fixed32(bytes)
              {[doodleDarkArgb: value], rest}

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
        WAWebProtobufsE2E.ChatSolidColorWallpaper,
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
        1 => {:backgroundLightArgb, {:scalar, 0}, :fixed32},
        2 => {:backgroundDarkArgb, {:scalar, 0}, :fixed32},
        3 => {:isDoodleEnabled, {:scalar, false}, :bool},
        4 => {:doodleLightArgb, {:scalar, 0}, :fixed32},
        5 => {:doodleDarkArgb, {:scalar, 0}, :fixed32}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        backgroundDarkArgb: {2, {:scalar, 0}, :fixed32},
        backgroundLightArgb: {1, {:scalar, 0}, :fixed32},
        doodleDarkArgb: {5, {:scalar, 0}, :fixed32},
        doodleLightArgb: {4, {:scalar, 0}, :fixed32},
        isDoodleEnabled: {3, {:scalar, false}, :bool}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "backgroundLightArgb",
          kind: {:scalar, 0},
          label: :optional,
          name: :backgroundLightArgb,
          tag: 1,
          type: :fixed32
        },
        %{
          __struct__: Protox.Field,
          json_name: "backgroundDarkArgb",
          kind: {:scalar, 0},
          label: :optional,
          name: :backgroundDarkArgb,
          tag: 2,
          type: :fixed32
        },
        %{
          __struct__: Protox.Field,
          json_name: "isDoodleEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :isDoodleEnabled,
          tag: 3,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "doodleLightArgb",
          kind: {:scalar, 0},
          label: :optional,
          name: :doodleLightArgb,
          tag: 4,
          type: :fixed32
        },
        %{
          __struct__: Protox.Field,
          json_name: "doodleDarkArgb",
          kind: {:scalar, 0},
          label: :optional,
          name: :doodleDarkArgb,
          tag: 5,
          type: :fixed32
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:backgroundLightArgb) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "backgroundLightArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :backgroundLightArgb,
             tag: 1,
             type: :fixed32
           }}
        end

        def field_def("backgroundLightArgb") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "backgroundLightArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :backgroundLightArgb,
             tag: 1,
             type: :fixed32
           }}
        end

        []
      ),
      (
        def field_def(:backgroundDarkArgb) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "backgroundDarkArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :backgroundDarkArgb,
             tag: 2,
             type: :fixed32
           }}
        end

        def field_def("backgroundDarkArgb") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "backgroundDarkArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :backgroundDarkArgb,
             tag: 2,
             type: :fixed32
           }}
        end

        []
      ),
      (
        def field_def(:isDoodleEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isDoodleEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isDoodleEnabled,
             tag: 3,
             type: :bool
           }}
        end

        def field_def("isDoodleEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isDoodleEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :isDoodleEnabled,
             tag: 3,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:doodleLightArgb) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "doodleLightArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :doodleLightArgb,
             tag: 4,
             type: :fixed32
           }}
        end

        def field_def("doodleLightArgb") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "doodleLightArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :doodleLightArgb,
             tag: 4,
             type: :fixed32
           }}
        end

        []
      ),
      (
        def field_def(:doodleDarkArgb) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "doodleDarkArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :doodleDarkArgb,
             tag: 5,
             type: :fixed32
           }}
        end

        def field_def("doodleDarkArgb") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "doodleDarkArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :doodleDarkArgb,
             tag: 5,
             type: :fixed32
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
    def default(:backgroundLightArgb) do
      {:ok, 0}
    end,
    def default(:backgroundDarkArgb) do
      {:ok, 0}
    end,
    def default(:isDoodleEnabled) do
      {:ok, false}
    end,
    def default(:doodleLightArgb) do
      {:ok, 0}
    end,
    def default(:doodleDarkArgb) do
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
