# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo do
  @moduledoc false
  defstruct newsletterJID: nil,
            serverMessageID: nil,
            newsletterName: nil,
            contentType: nil,
            accessibilityText: nil,
            profileName: nil,
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
        |> encode_newsletterJID(msg)
        |> encode_serverMessageID(msg)
        |> encode_newsletterName(msg)
        |> encode_contentType(msg)
        |> encode_accessibilityText(msg)
        |> encode_profileName(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_newsletterJID(acc, msg) do
        try do
          case msg.newsletterJID do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.newsletterJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:newsletterJID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_serverMessageID(acc, msg) do
        try do
          case msg.serverMessageID do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_int32(msg.serverMessageID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:serverMessageID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_newsletterName(acc, msg) do
        try do
          case msg.newsletterName do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.newsletterName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:newsletterName, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_contentType(acc, msg) do
        try do
          case msg.contentType do
            nil ->
              acc

            _ ->
              [
                acc,
                " ",
                msg.contentType
                |> WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo.ContentType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contentType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_accessibilityText(acc, msg) do
        try do
          case msg.accessibilityText do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.accessibilityText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:accessibilityText, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_profileName(acc, msg) do
        try do
          case msg.profileName do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.profileName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:profileName, "invalid field value"), __STACKTRACE__
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
            struct(WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo)
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
              {[newsletterJID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[serverMessageID: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[newsletterName: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo.ContentType
                )

              {[contentType: value], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[accessibilityText: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[profileName: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo,
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
        1 => {:newsletterJID, {:scalar, ""}, :string},
        2 => {:serverMessageID, {:scalar, 0}, :int32},
        3 => {:newsletterName, {:scalar, ""}, :string},
        4 =>
          {:contentType, {:scalar, :UPDATE},
           {:enum, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo.ContentType}},
        5 => {:accessibilityText, {:scalar, ""}, :string},
        6 => {:profileName, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        accessibilityText: {5, {:scalar, ""}, :string},
        contentType:
          {4, {:scalar, :UPDATE},
           {:enum, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo.ContentType}},
        newsletterJID: {1, {:scalar, ""}, :string},
        newsletterName: {3, {:scalar, ""}, :string},
        profileName: {6, {:scalar, ""}, :string},
        serverMessageID: {2, {:scalar, 0}, :int32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "newsletterJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :newsletterJID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "serverMessageID",
          kind: {:scalar, 0},
          label: :optional,
          name: :serverMessageID,
          tag: 2,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "newsletterName",
          kind: {:scalar, ""},
          label: :optional,
          name: :newsletterName,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "contentType",
          kind: {:scalar, :UPDATE},
          label: :optional,
          name: :contentType,
          tag: 4,
          type: {:enum, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo.ContentType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "accessibilityText",
          kind: {:scalar, ""},
          label: :optional,
          name: :accessibilityText,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "profileName",
          kind: {:scalar, ""},
          label: :optional,
          name: :profileName,
          tag: 6,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:newsletterJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :newsletterJID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("newsletterJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :newsletterJID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:serverMessageID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "serverMessageID",
             kind: {:scalar, 0},
             label: :optional,
             name: :serverMessageID,
             tag: 2,
             type: :int32
           }}
        end

        def field_def("serverMessageID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "serverMessageID",
             kind: {:scalar, 0},
             label: :optional,
             name: :serverMessageID,
             tag: 2,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:newsletterName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterName",
             kind: {:scalar, ""},
             label: :optional,
             name: :newsletterName,
             tag: 3,
             type: :string
           }}
        end

        def field_def("newsletterName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterName",
             kind: {:scalar, ""},
             label: :optional,
             name: :newsletterName,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:contentType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contentType",
             kind: {:scalar, :UPDATE},
             label: :optional,
             name: :contentType,
             tag: 4,
             type:
               {:enum, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo.ContentType}
           }}
        end

        def field_def("contentType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contentType",
             kind: {:scalar, :UPDATE},
             label: :optional,
             name: :contentType,
             tag: 4,
             type:
               {:enum, WAWebProtobufsE2E.ContextInfo.ForwardedNewsletterMessageInfo.ContentType}
           }}
        end

        []
      ),
      (
        def field_def(:accessibilityText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accessibilityText",
             kind: {:scalar, ""},
             label: :optional,
             name: :accessibilityText,
             tag: 5,
             type: :string
           }}
        end

        def field_def("accessibilityText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accessibilityText",
             kind: {:scalar, ""},
             label: :optional,
             name: :accessibilityText,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:profileName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "profileName",
             kind: {:scalar, ""},
             label: :optional,
             name: :profileName,
             tag: 6,
             type: :string
           }}
        end

        def field_def("profileName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "profileName",
             kind: {:scalar, ""},
             label: :optional,
             name: :profileName,
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
    def default(:newsletterJID) do
      {:ok, ""}
    end,
    def default(:serverMessageID) do
      {:ok, 0}
    end,
    def default(:newsletterName) do
      {:ok, ""}
    end,
    def default(:contentType) do
      {:ok, :UPDATE}
    end,
    def default(:accessibilityText) do
      {:ok, ""}
    end,
    def default(:profileName) do
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
