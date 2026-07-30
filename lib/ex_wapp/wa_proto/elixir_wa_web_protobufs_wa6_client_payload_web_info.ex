# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.WebInfo do
  @moduledoc false
  defstruct refToken: nil,
            version: nil,
            webdPayload: nil,
            webSubPlatform: nil,
            browser: nil,
            browserVersion: nil,
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
        |> encode_refToken(msg)
        |> encode_version(msg)
        |> encode_webdPayload(msg)
        |> encode_webSubPlatform(msg)
        |> encode_browser(msg)
        |> encode_browserVersion(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_refToken(acc, msg) do
        try do
          case msg.refToken do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.refToken)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:refToken, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_version(acc, msg) do
        try do
          case msg.version do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.version)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:version, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_webdPayload(acc, msg) do
        try do
          case msg.webdPayload do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_message(msg.webdPayload)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:webdPayload, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_webSubPlatform(acc, msg) do
        try do
          case msg.webSubPlatform do
            nil ->
              acc

            _ ->
              [
                acc,
                " ",
                msg.webSubPlatform
                |> WAWebProtobufsWa6.ClientPayload.WebInfo.WebSubPlatform.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:webSubPlatform, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_browser(acc, msg) do
        try do
          case msg.browser do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.browser)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:browser, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_browserVersion(acc, msg) do
        try do
          case msg.browserVersion do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.browserVersion)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:browserVersion, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsWa6.ClientPayload.WebInfo))
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
              {[refToken: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[version: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 webdPayload:
                   Protox.MergeMessage.merge(
                     msg.webdPayload,
                     WAWebProtobufsWa6.ClientPayload.WebInfo.WebdPayload.decode!(delimited)
                   )
               ], rest}

            {4, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsWa6.ClientPayload.WebInfo.WebSubPlatform
                )

              {[webSubPlatform: value], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[browser: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[browserVersion: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufsWa6.ClientPayload.WebInfo,
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
        1 => {:refToken, {:scalar, ""}, :string},
        2 => {:version, {:scalar, ""}, :string},
        3 =>
          {:webdPayload, {:scalar, nil},
           {:message, WAWebProtobufsWa6.ClientPayload.WebInfo.WebdPayload}},
        4 =>
          {:webSubPlatform, {:scalar, :WEB_BROWSER},
           {:enum, WAWebProtobufsWa6.ClientPayload.WebInfo.WebSubPlatform}},
        5 => {:browser, {:scalar, ""}, :string},
        6 => {:browserVersion, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        browser: {5, {:scalar, ""}, :string},
        browserVersion: {6, {:scalar, ""}, :string},
        refToken: {1, {:scalar, ""}, :string},
        version: {2, {:scalar, ""}, :string},
        webSubPlatform:
          {4, {:scalar, :WEB_BROWSER},
           {:enum, WAWebProtobufsWa6.ClientPayload.WebInfo.WebSubPlatform}},
        webdPayload:
          {3, {:scalar, nil}, {:message, WAWebProtobufsWa6.ClientPayload.WebInfo.WebdPayload}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "refToken",
          kind: {:scalar, ""},
          label: :optional,
          name: :refToken,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "version",
          kind: {:scalar, ""},
          label: :optional,
          name: :version,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "webdPayload",
          kind: {:scalar, nil},
          label: :optional,
          name: :webdPayload,
          tag: 3,
          type: {:message, WAWebProtobufsWa6.ClientPayload.WebInfo.WebdPayload}
        },
        %{
          __struct__: Protox.Field,
          json_name: "webSubPlatform",
          kind: {:scalar, :WEB_BROWSER},
          label: :optional,
          name: :webSubPlatform,
          tag: 4,
          type: {:enum, WAWebProtobufsWa6.ClientPayload.WebInfo.WebSubPlatform}
        },
        %{
          __struct__: Protox.Field,
          json_name: "browser",
          kind: {:scalar, ""},
          label: :optional,
          name: :browser,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "browserVersion",
          kind: {:scalar, ""},
          label: :optional,
          name: :browserVersion,
          tag: 6,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:refToken) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "refToken",
             kind: {:scalar, ""},
             label: :optional,
             name: :refToken,
             tag: 1,
             type: :string
           }}
        end

        def field_def("refToken") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "refToken",
             kind: {:scalar, ""},
             label: :optional,
             name: :refToken,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:version) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "version",
             kind: {:scalar, ""},
             label: :optional,
             name: :version,
             tag: 2,
             type: :string
           }}
        end

        def field_def("version") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "version",
             kind: {:scalar, ""},
             label: :optional,
             name: :version,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:webdPayload) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "webdPayload",
             kind: {:scalar, nil},
             label: :optional,
             name: :webdPayload,
             tag: 3,
             type: {:message, WAWebProtobufsWa6.ClientPayload.WebInfo.WebdPayload}
           }}
        end

        def field_def("webdPayload") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "webdPayload",
             kind: {:scalar, nil},
             label: :optional,
             name: :webdPayload,
             tag: 3,
             type: {:message, WAWebProtobufsWa6.ClientPayload.WebInfo.WebdPayload}
           }}
        end

        []
      ),
      (
        def field_def(:webSubPlatform) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "webSubPlatform",
             kind: {:scalar, :WEB_BROWSER},
             label: :optional,
             name: :webSubPlatform,
             tag: 4,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.WebInfo.WebSubPlatform}
           }}
        end

        def field_def("webSubPlatform") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "webSubPlatform",
             kind: {:scalar, :WEB_BROWSER},
             label: :optional,
             name: :webSubPlatform,
             tag: 4,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.WebInfo.WebSubPlatform}
           }}
        end

        []
      ),
      (
        def field_def(:browser) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "browser",
             kind: {:scalar, ""},
             label: :optional,
             name: :browser,
             tag: 5,
             type: :string
           }}
        end

        def field_def("browser") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "browser",
             kind: {:scalar, ""},
             label: :optional,
             name: :browser,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:browserVersion) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "browserVersion",
             kind: {:scalar, ""},
             label: :optional,
             name: :browserVersion,
             tag: 6,
             type: :string
           }}
        end

        def field_def("browserVersion") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "browserVersion",
             kind: {:scalar, ""},
             label: :optional,
             name: :browserVersion,
             tag: 6,
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
    def default(:refToken) do
      {:ok, ""}
    end,
    def default(:version) do
      {:ok, ""}
    end,
    def default(:webdPayload) do
      {:ok, nil}
    end,
    def default(:webSubPlatform) do
      {:ok, :WEB_BROWSER}
    end,
    def default(:browser) do
      {:ok, ""}
    end,
    def default(:browserVersion) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waWa6",
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
