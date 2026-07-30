# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.GroupInviteMessage do
  @moduledoc false
  defstruct groupJID: nil,
            inviteCode: nil,
            inviteExpiration: nil,
            groupName: nil,
            JPEGThumbnail: nil,
            caption: nil,
            contextInfo: nil,
            groupType: nil,
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
        |> encode_groupJID(msg)
        |> encode_inviteCode(msg)
        |> encode_inviteExpiration(msg)
        |> encode_groupName(msg)
        |> encode_JPEGThumbnail(msg)
        |> encode_caption(msg)
        |> encode_contextInfo(msg)
        |> encode_groupType(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_groupJID(acc, msg) do
        try do
          case msg.groupJID do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.groupJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_inviteCode(acc, msg) do
        try do
          case msg.inviteCode do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.inviteCode)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:inviteCode, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_inviteExpiration(acc, msg) do
        try do
          case msg.inviteExpiration do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_int64(msg.inviteExpiration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:inviteExpiration, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_groupName(acc, msg) do
        try do
          case msg.groupName do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.groupName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupName, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_JPEGThumbnail(acc, msg) do
        try do
          case msg."JPEGThumbnail" do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_bytes(msg."JPEGThumbnail")]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:JPEGThumbnail, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_caption(acc, msg) do
        try do
          case msg.caption do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.caption)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:caption, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_contextInfo(acc, msg) do
        try do
          case msg.contextInfo do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_message(msg.contextInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contextInfo, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_groupType(acc, msg) do
        try do
          case msg.groupType do
            nil ->
              acc

            _ ->
              [
                acc,
                "@",
                msg.groupType
                |> WAWebProtobufsE2E.GroupInviteMessage.GroupType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupType, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.GroupInviteMessage))
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
              {[groupJID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[inviteCode: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[inviteExpiration: value], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[groupName: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[JPEGThumbnail: delimited], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[caption: Protox.Decode.validate_string!(delimited)], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contextInfo:
                   Protox.MergeMessage.merge(
                     msg.contextInfo,
                     WAWebProtobufsE2E.ContextInfo.decode!(delimited)
                   )
               ], rest}

            {8, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.GroupInviteMessage.GroupType)

              {[groupType: value], rest}

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
        WAWebProtobufsE2E.GroupInviteMessage,
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
        1 => {:groupJID, {:scalar, ""}, :string},
        2 => {:inviteCode, {:scalar, ""}, :string},
        3 => {:inviteExpiration, {:scalar, 0}, :int64},
        4 => {:groupName, {:scalar, ""}, :string},
        5 => {:JPEGThumbnail, {:scalar, ""}, :bytes},
        6 => {:caption, {:scalar, ""}, :string},
        7 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        8 =>
          {:groupType, {:scalar, :DEFAULT},
           {:enum, WAWebProtobufsE2E.GroupInviteMessage.GroupType}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        JPEGThumbnail: {5, {:scalar, ""}, :bytes},
        caption: {6, {:scalar, ""}, :string},
        contextInfo: {7, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        groupJID: {1, {:scalar, ""}, :string},
        groupName: {4, {:scalar, ""}, :string},
        groupType:
          {8, {:scalar, :DEFAULT}, {:enum, WAWebProtobufsE2E.GroupInviteMessage.GroupType}},
        inviteCode: {2, {:scalar, ""}, :string},
        inviteExpiration: {3, {:scalar, 0}, :int64}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "groupJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :groupJID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "inviteCode",
          kind: {:scalar, ""},
          label: :optional,
          name: :inviteCode,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "inviteExpiration",
          kind: {:scalar, 0},
          label: :optional,
          name: :inviteExpiration,
          tag: 3,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupName",
          kind: {:scalar, ""},
          label: :optional,
          name: :groupName,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "JPEGThumbnail",
          kind: {:scalar, ""},
          label: :optional,
          name: :JPEGThumbnail,
          tag: 5,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "caption",
          kind: {:scalar, ""},
          label: :optional,
          name: :caption,
          tag: 6,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "contextInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :contextInfo,
          tag: 7,
          type: {:message, WAWebProtobufsE2E.ContextInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupType",
          kind: {:scalar, :DEFAULT},
          label: :optional,
          name: :groupType,
          tag: 8,
          type: {:enum, WAWebProtobufsE2E.GroupInviteMessage.GroupType}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:groupJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :groupJID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("groupJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :groupJID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:inviteCode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inviteCode",
             kind: {:scalar, ""},
             label: :optional,
             name: :inviteCode,
             tag: 2,
             type: :string
           }}
        end

        def field_def("inviteCode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inviteCode",
             kind: {:scalar, ""},
             label: :optional,
             name: :inviteCode,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:inviteExpiration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inviteExpiration",
             kind: {:scalar, 0},
             label: :optional,
             name: :inviteExpiration,
             tag: 3,
             type: :int64
           }}
        end

        def field_def("inviteExpiration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inviteExpiration",
             kind: {:scalar, 0},
             label: :optional,
             name: :inviteExpiration,
             tag: 3,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:groupName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupName",
             kind: {:scalar, ""},
             label: :optional,
             name: :groupName,
             tag: 4,
             type: :string
           }}
        end

        def field_def("groupName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupName",
             kind: {:scalar, ""},
             label: :optional,
             name: :groupName,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:JPEGThumbnail) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "JPEGThumbnail",
             kind: {:scalar, ""},
             label: :optional,
             name: :JPEGThumbnail,
             tag: 5,
             type: :bytes
           }}
        end

        def field_def("JPEGThumbnail") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "JPEGThumbnail",
             kind: {:scalar, ""},
             label: :optional,
             name: :JPEGThumbnail,
             tag: 5,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:caption) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "caption",
             kind: {:scalar, ""},
             label: :optional,
             name: :caption,
             tag: 6,
             type: :string
           }}
        end

        def field_def("caption") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "caption",
             kind: {:scalar, ""},
             label: :optional,
             name: :caption,
             tag: 6,
             type: :string
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
             tag: 7,
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
             tag: 7,
             type: {:message, WAWebProtobufsE2E.ContextInfo}
           }}
        end

        []
      ),
      (
        def field_def(:groupType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupType",
             kind: {:scalar, :DEFAULT},
             label: :optional,
             name: :groupType,
             tag: 8,
             type: {:enum, WAWebProtobufsE2E.GroupInviteMessage.GroupType}
           }}
        end

        def field_def("groupType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupType",
             kind: {:scalar, :DEFAULT},
             label: :optional,
             name: :groupType,
             tag: 8,
             type: {:enum, WAWebProtobufsE2E.GroupInviteMessage.GroupType}
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
    def default(:groupJID) do
      {:ok, ""}
    end,
    def default(:inviteCode) do
      {:ok, ""}
    end,
    def default(:inviteExpiration) do
      {:ok, 0}
    end,
    def default(:groupName) do
      {:ok, ""}
    end,
    def default(:JPEGThumbnail) do
      {:ok, ""}
    end,
    def default(:caption) do
      {:ok, ""}
    end,
    def default(:contextInfo) do
      {:ok, nil}
    end,
    def default(:groupType) do
      {:ok, :DEFAULT}
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
