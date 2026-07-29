# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ChatThemeSetting do
  @moduledoc false
  defstruct settingTimestampMS: nil,
            clearTheme: nil,
            colorSchemeID: nil,
            wallpaper: nil,
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
        |> encode_wallpaper(msg)
        |> encode_settingTimestampMS(msg)
        |> encode_clearTheme(msg)
        |> encode_colorSchemeID(msg)
        |> encode_unknown_fields(msg)
      end
    )

    [
      defp encode_wallpaper(acc, msg) do
        case msg.wallpaper do
          nil -> acc
          {:defaultWallpaper, _field_value} -> encode_defaultWallpaper(acc, msg)
          {:solidColor, _field_value} -> encode_solidColor(acc, msg)
          {:stockImage, _field_value} -> encode_stockImage(acc, msg)
          {:customImage, _field_value} -> encode_customImage(acc, msg)
        end
      end
    ]

    [
      defp encode_settingTimestampMS(acc, msg) do
        try do
          case msg.settingTimestampMS do
            nil -> acc
            _ -> [acc, "\b", Protox.Encode.encode_int64(msg.settingTimestampMS)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:settingTimestampMS, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_clearTheme(acc, msg) do
        try do
          case msg.clearTheme do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_bool(msg.clearTheme)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:clearTheme, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_colorSchemeID(acc, msg) do
        try do
          case msg.colorSchemeID do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.colorSchemeID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:colorSchemeID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_defaultWallpaper(acc, msg) do
        try do
          {_, child_field_value} = msg.wallpaper
          [acc, "R", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:defaultWallpaper, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_solidColor(acc, msg) do
        try do
          {_, child_field_value} = msg.wallpaper
          [acc, "Z", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:solidColor, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_stockImage(acc, msg) do
        try do
          {_, child_field_value} = msg.wallpaper
          [acc, "b", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:stockImage, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_customImage(acc, msg) do
        try do
          {_, child_field_value} = msg.wallpaper
          [acc, "j", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:customImage, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.ChatThemeSetting))
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
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[settingTimestampMS: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[clearTheme: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[colorSchemeID: Protox.Decode.validate_string!(delimited)], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.wallpaper do
                   {:defaultWallpaper, previous_value} ->
                     {:wallpaper,
                      {:defaultWallpaper,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.ChatDefaultWallpaper.decode!(delimited)
                       )}}

                   _ ->
                     {:wallpaper,
                      {:defaultWallpaper,
                       WAWebProtobufsE2E.ChatDefaultWallpaper.decode!(delimited)}}
                 end
               ], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.wallpaper do
                   {:solidColor, previous_value} ->
                     {:wallpaper,
                      {:solidColor,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.ChatSolidColorWallpaper.decode!(delimited)
                       )}}

                   _ ->
                     {:wallpaper,
                      {:solidColor, WAWebProtobufsE2E.ChatSolidColorWallpaper.decode!(delimited)}}
                 end
               ], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.wallpaper do
                   {:stockImage, previous_value} ->
                     {:wallpaper,
                      {:stockImage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.ChatStockImageWallpaper.decode!(delimited)
                       )}}

                   _ ->
                     {:wallpaper,
                      {:stockImage, WAWebProtobufsE2E.ChatStockImageWallpaper.decode!(delimited)}}
                 end
               ], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.wallpaper do
                   {:customImage, previous_value} ->
                     {:wallpaper,
                      {:customImage,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAWebProtobufsE2E.ChatCustomImageWallpaper.decode!(delimited)
                       )}}

                   _ ->
                     {:wallpaper,
                      {:customImage,
                       WAWebProtobufsE2E.ChatCustomImageWallpaper.decode!(delimited)}}
                 end
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
        WAWebProtobufsE2E.ChatThemeSetting,
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
        1 => {:settingTimestampMS, {:scalar, 0}, :int64},
        2 => {:clearTheme, {:scalar, false}, :bool},
        3 => {:colorSchemeID, {:scalar, ""}, :string},
        10 =>
          {:defaultWallpaper, {:oneof, :wallpaper},
           {:message, WAWebProtobufsE2E.ChatDefaultWallpaper}},
        11 =>
          {:solidColor, {:oneof, :wallpaper},
           {:message, WAWebProtobufsE2E.ChatSolidColorWallpaper}},
        12 =>
          {:stockImage, {:oneof, :wallpaper},
           {:message, WAWebProtobufsE2E.ChatStockImageWallpaper}},
        13 =>
          {:customImage, {:oneof, :wallpaper},
           {:message, WAWebProtobufsE2E.ChatCustomImageWallpaper}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        clearTheme: {2, {:scalar, false}, :bool},
        colorSchemeID: {3, {:scalar, ""}, :string},
        customImage:
          {13, {:oneof, :wallpaper}, {:message, WAWebProtobufsE2E.ChatCustomImageWallpaper}},
        defaultWallpaper:
          {10, {:oneof, :wallpaper}, {:message, WAWebProtobufsE2E.ChatDefaultWallpaper}},
        settingTimestampMS: {1, {:scalar, 0}, :int64},
        solidColor:
          {11, {:oneof, :wallpaper}, {:message, WAWebProtobufsE2E.ChatSolidColorWallpaper}},
        stockImage:
          {12, {:oneof, :wallpaper}, {:message, WAWebProtobufsE2E.ChatStockImageWallpaper}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "settingTimestampMS",
          kind: {:scalar, 0},
          label: :optional,
          name: :settingTimestampMS,
          tag: 1,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "clearTheme",
          kind: {:scalar, false},
          label: :optional,
          name: :clearTheme,
          tag: 2,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "colorSchemeID",
          kind: {:scalar, ""},
          label: :optional,
          name: :colorSchemeID,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "defaultWallpaper",
          kind: {:oneof, :wallpaper},
          label: :optional,
          name: :defaultWallpaper,
          tag: 10,
          type: {:message, WAWebProtobufsE2E.ChatDefaultWallpaper}
        },
        %{
          __struct__: Protox.Field,
          json_name: "solidColor",
          kind: {:oneof, :wallpaper},
          label: :optional,
          name: :solidColor,
          tag: 11,
          type: {:message, WAWebProtobufsE2E.ChatSolidColorWallpaper}
        },
        %{
          __struct__: Protox.Field,
          json_name: "stockImage",
          kind: {:oneof, :wallpaper},
          label: :optional,
          name: :stockImage,
          tag: 12,
          type: {:message, WAWebProtobufsE2E.ChatStockImageWallpaper}
        },
        %{
          __struct__: Protox.Field,
          json_name: "customImage",
          kind: {:oneof, :wallpaper},
          label: :optional,
          name: :customImage,
          tag: 13,
          type: {:message, WAWebProtobufsE2E.ChatCustomImageWallpaper}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:settingTimestampMS) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "settingTimestampMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :settingTimestampMS,
             tag: 1,
             type: :int64
           }}
        end

        def field_def("settingTimestampMS") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "settingTimestampMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :settingTimestampMS,
             tag: 1,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:clearTheme) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "clearTheme",
             kind: {:scalar, false},
             label: :optional,
             name: :clearTheme,
             tag: 2,
             type: :bool
           }}
        end

        def field_def("clearTheme") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "clearTheme",
             kind: {:scalar, false},
             label: :optional,
             name: :clearTheme,
             tag: 2,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:colorSchemeID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "colorSchemeID",
             kind: {:scalar, ""},
             label: :optional,
             name: :colorSchemeID,
             tag: 3,
             type: :string
           }}
        end

        def field_def("colorSchemeID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "colorSchemeID",
             kind: {:scalar, ""},
             label: :optional,
             name: :colorSchemeID,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:defaultWallpaper) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "defaultWallpaper",
             kind: {:oneof, :wallpaper},
             label: :optional,
             name: :defaultWallpaper,
             tag: 10,
             type: {:message, WAWebProtobufsE2E.ChatDefaultWallpaper}
           }}
        end

        def field_def("defaultWallpaper") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "defaultWallpaper",
             kind: {:oneof, :wallpaper},
             label: :optional,
             name: :defaultWallpaper,
             tag: 10,
             type: {:message, WAWebProtobufsE2E.ChatDefaultWallpaper}
           }}
        end

        []
      ),
      (
        def field_def(:solidColor) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "solidColor",
             kind: {:oneof, :wallpaper},
             label: :optional,
             name: :solidColor,
             tag: 11,
             type: {:message, WAWebProtobufsE2E.ChatSolidColorWallpaper}
           }}
        end

        def field_def("solidColor") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "solidColor",
             kind: {:oneof, :wallpaper},
             label: :optional,
             name: :solidColor,
             tag: 11,
             type: {:message, WAWebProtobufsE2E.ChatSolidColorWallpaper}
           }}
        end

        []
      ),
      (
        def field_def(:stockImage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stockImage",
             kind: {:oneof, :wallpaper},
             label: :optional,
             name: :stockImage,
             tag: 12,
             type: {:message, WAWebProtobufsE2E.ChatStockImageWallpaper}
           }}
        end

        def field_def("stockImage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "stockImage",
             kind: {:oneof, :wallpaper},
             label: :optional,
             name: :stockImage,
             tag: 12,
             type: {:message, WAWebProtobufsE2E.ChatStockImageWallpaper}
           }}
        end

        []
      ),
      (
        def field_def(:customImage) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "customImage",
             kind: {:oneof, :wallpaper},
             label: :optional,
             name: :customImage,
             tag: 13,
             type: {:message, WAWebProtobufsE2E.ChatCustomImageWallpaper}
           }}
        end

        def field_def("customImage") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "customImage",
             kind: {:oneof, :wallpaper},
             label: :optional,
             name: :customImage,
             tag: 13,
             type: {:message, WAWebProtobufsE2E.ChatCustomImageWallpaper}
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
    def default(:settingTimestampMS) do
      {:ok, 0}
    end,
    def default(:clearTheme) do
      {:ok, false}
    end,
    def default(:colorSchemeID) do
      {:ok, ""}
    end,
    def default(:defaultWallpaper) do
      {:error, :no_default_value}
    end,
    def default(:solidColor) do
      {:error, :no_default_value}
    end,
    def default(:stockImage) do
      {:error, :no_default_value}
    end,
    def default(:customImage) do
      {:error, :no_default_value}
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
