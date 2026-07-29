# credo:disable-for-this-file
defmodule WAWebProtobufsAICommon.BotPluginMetadata do
  @moduledoc false
  defstruct provider: nil,
            pluginType: nil,
            thumbnailCDNURL: nil,
            profilePhotoCDNURL: nil,
            searchProviderURL: nil,
            referenceIndex: nil,
            expectedLinksCount: nil,
            searchQuery: nil,
            parentPluginMessageKey: nil,
            deprecatedField: nil,
            parentPluginType: nil,
            faviconCDNURL: nil,
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
        |> encode_provider(msg)
        |> encode_pluginType(msg)
        |> encode_thumbnailCDNURL(msg)
        |> encode_profilePhotoCDNURL(msg)
        |> encode_searchProviderURL(msg)
        |> encode_referenceIndex(msg)
        |> encode_expectedLinksCount(msg)
        |> encode_searchQuery(msg)
        |> encode_parentPluginMessageKey(msg)
        |> encode_deprecatedField(msg)
        |> encode_parentPluginType(msg)
        |> encode_faviconCDNURL(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_provider(acc, msg) do
        try do
          case msg.provider do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.provider
                |> WAWebProtobufsAICommon.BotPluginMetadata.SearchProvider.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:provider, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pluginType(acc, msg) do
        try do
          case msg.pluginType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x10",
                msg.pluginType
                |> WAWebProtobufsAICommon.BotPluginMetadata.PluginType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pluginType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_thumbnailCDNURL(acc, msg) do
        try do
          case msg.thumbnailCDNURL do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.thumbnailCDNURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailCDNURL, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_profilePhotoCDNURL(acc, msg) do
        try do
          case msg.profilePhotoCDNURL do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.profilePhotoCDNURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:profilePhotoCDNURL, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_searchProviderURL(acc, msg) do
        try do
          case msg.searchProviderURL do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.searchProviderURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:searchProviderURL, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_referenceIndex(acc, msg) do
        try do
          case msg.referenceIndex do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_uint32(msg.referenceIndex)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:referenceIndex, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_expectedLinksCount(acc, msg) do
        try do
          case msg.expectedLinksCount do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_uint32(msg.expectedLinksCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:expectedLinksCount, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_searchQuery(acc, msg) do
        try do
          case msg.searchQuery do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_string(msg.searchQuery)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:searchQuery, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_parentPluginMessageKey(acc, msg) do
        try do
          case msg.parentPluginMessageKey do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_message(msg.parentPluginMessageKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:parentPluginMessageKey, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_deprecatedField(acc, msg) do
        try do
          case msg.deprecatedField do
            nil ->
              acc

            _ ->
              [
                acc,
                "X",
                msg.deprecatedField
                |> WAWebProtobufsAICommon.BotPluginMetadata.PluginType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deprecatedField, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_parentPluginType(acc, msg) do
        try do
          case msg.parentPluginType do
            nil ->
              acc

            _ ->
              [
                acc,
                "`",
                msg.parentPluginType
                |> WAWebProtobufsAICommon.BotPluginMetadata.PluginType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:parentPluginType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_faviconCDNURL(acc, msg) do
        try do
          case msg.faviconCDNURL do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_string(msg.faviconCDNURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:faviconCDNURL, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsAICommon.BotPluginMetadata))
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
                  WAWebProtobufsAICommon.BotPluginMetadata.SearchProvider
                )

              {[provider: value], rest}

            {2, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsAICommon.BotPluginMetadata.PluginType
                )

              {[pluginType: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnailCDNURL: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[profilePhotoCDNURL: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[searchProviderURL: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[referenceIndex: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[expectedLinksCount: value], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[searchQuery: Protox.Decode.validate_string!(delimited)], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 parentPluginMessageKey:
                   Protox.MergeMessage.merge(
                     msg.parentPluginMessageKey,
                     WACommon.MessageKey.decode!(delimited)
                   )
               ], rest}

            {11, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsAICommon.BotPluginMetadata.PluginType
                )

              {[deprecatedField: value], rest}

            {12, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsAICommon.BotPluginMetadata.PluginType
                )

              {[parentPluginType: value], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[faviconCDNURL: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufsAICommon.BotPluginMetadata,
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
          {:provider, {:scalar, :UNKNOWN},
           {:enum, WAWebProtobufsAICommon.BotPluginMetadata.SearchProvider}},
        2 =>
          {:pluginType, {:scalar, :UNKNOWN_PLUGIN},
           {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}},
        3 => {:thumbnailCDNURL, {:scalar, ""}, :string},
        4 => {:profilePhotoCDNURL, {:scalar, ""}, :string},
        5 => {:searchProviderURL, {:scalar, ""}, :string},
        6 => {:referenceIndex, {:scalar, 0}, :uint32},
        7 => {:expectedLinksCount, {:scalar, 0}, :uint32},
        9 => {:searchQuery, {:scalar, ""}, :string},
        10 => {:parentPluginMessageKey, {:scalar, nil}, {:message, WACommon.MessageKey}},
        11 =>
          {:deprecatedField, {:scalar, :UNKNOWN_PLUGIN},
           {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}},
        12 =>
          {:parentPluginType, {:scalar, :UNKNOWN_PLUGIN},
           {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}},
        13 => {:faviconCDNURL, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        deprecatedField:
          {11, {:scalar, :UNKNOWN_PLUGIN},
           {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}},
        expectedLinksCount: {7, {:scalar, 0}, :uint32},
        faviconCDNURL: {13, {:scalar, ""}, :string},
        parentPluginMessageKey: {10, {:scalar, nil}, {:message, WACommon.MessageKey}},
        parentPluginType:
          {12, {:scalar, :UNKNOWN_PLUGIN},
           {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}},
        pluginType:
          {2, {:scalar, :UNKNOWN_PLUGIN},
           {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}},
        profilePhotoCDNURL: {4, {:scalar, ""}, :string},
        provider:
          {1, {:scalar, :UNKNOWN},
           {:enum, WAWebProtobufsAICommon.BotPluginMetadata.SearchProvider}},
        referenceIndex: {6, {:scalar, 0}, :uint32},
        searchProviderURL: {5, {:scalar, ""}, :string},
        searchQuery: {9, {:scalar, ""}, :string},
        thumbnailCDNURL: {3, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "provider",
          kind: {:scalar, :UNKNOWN},
          label: :optional,
          name: :provider,
          tag: 1,
          type: {:enum, WAWebProtobufsAICommon.BotPluginMetadata.SearchProvider}
        },
        %{
          __struct__: Protox.Field,
          json_name: "pluginType",
          kind: {:scalar, :UNKNOWN_PLUGIN},
          label: :optional,
          name: :pluginType,
          tag: 2,
          type: {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailCDNURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailCDNURL,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "profilePhotoCDNURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :profilePhotoCDNURL,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "searchProviderURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :searchProviderURL,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "referenceIndex",
          kind: {:scalar, 0},
          label: :optional,
          name: :referenceIndex,
          tag: 6,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "expectedLinksCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :expectedLinksCount,
          tag: 7,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "searchQuery",
          kind: {:scalar, ""},
          label: :optional,
          name: :searchQuery,
          tag: 9,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "parentPluginMessageKey",
          kind: {:scalar, nil},
          label: :optional,
          name: :parentPluginMessageKey,
          tag: 10,
          type: {:message, WACommon.MessageKey}
        },
        %{
          __struct__: Protox.Field,
          json_name: "deprecatedField",
          kind: {:scalar, :UNKNOWN_PLUGIN},
          label: :optional,
          name: :deprecatedField,
          tag: 11,
          type: {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "parentPluginType",
          kind: {:scalar, :UNKNOWN_PLUGIN},
          label: :optional,
          name: :parentPluginType,
          tag: 12,
          type: {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "faviconCDNURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :faviconCDNURL,
          tag: 13,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:provider) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "provider",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :provider,
             tag: 1,
             type: {:enum, WAWebProtobufsAICommon.BotPluginMetadata.SearchProvider}
           }}
        end

        def field_def("provider") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "provider",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :provider,
             tag: 1,
             type: {:enum, WAWebProtobufsAICommon.BotPluginMetadata.SearchProvider}
           }}
        end

        []
      ),
      (
        def field_def(:pluginType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pluginType",
             kind: {:scalar, :UNKNOWN_PLUGIN},
             label: :optional,
             name: :pluginType,
             tag: 2,
             type: {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}
           }}
        end

        def field_def("pluginType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pluginType",
             kind: {:scalar, :UNKNOWN_PLUGIN},
             label: :optional,
             name: :pluginType,
             tag: 2,
             type: {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailCDNURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailCDNURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailCDNURL,
             tag: 3,
             type: :string
           }}
        end

        def field_def("thumbnailCDNURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailCDNURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailCDNURL,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:profilePhotoCDNURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "profilePhotoCDNURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :profilePhotoCDNURL,
             tag: 4,
             type: :string
           }}
        end

        def field_def("profilePhotoCDNURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "profilePhotoCDNURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :profilePhotoCDNURL,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:searchProviderURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "searchProviderURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :searchProviderURL,
             tag: 5,
             type: :string
           }}
        end

        def field_def("searchProviderURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "searchProviderURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :searchProviderURL,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:referenceIndex) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "referenceIndex",
             kind: {:scalar, 0},
             label: :optional,
             name: :referenceIndex,
             tag: 6,
             type: :uint32
           }}
        end

        def field_def("referenceIndex") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "referenceIndex",
             kind: {:scalar, 0},
             label: :optional,
             name: :referenceIndex,
             tag: 6,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:expectedLinksCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "expectedLinksCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :expectedLinksCount,
             tag: 7,
             type: :uint32
           }}
        end

        def field_def("expectedLinksCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "expectedLinksCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :expectedLinksCount,
             tag: 7,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:searchQuery) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "searchQuery",
             kind: {:scalar, ""},
             label: :optional,
             name: :searchQuery,
             tag: 9,
             type: :string
           }}
        end

        def field_def("searchQuery") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "searchQuery",
             kind: {:scalar, ""},
             label: :optional,
             name: :searchQuery,
             tag: 9,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:parentPluginMessageKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "parentPluginMessageKey",
             kind: {:scalar, nil},
             label: :optional,
             name: :parentPluginMessageKey,
             tag: 10,
             type: {:message, WACommon.MessageKey}
           }}
        end

        def field_def("parentPluginMessageKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "parentPluginMessageKey",
             kind: {:scalar, nil},
             label: :optional,
             name: :parentPluginMessageKey,
             tag: 10,
             type: {:message, WACommon.MessageKey}
           }}
        end

        []
      ),
      (
        def field_def(:deprecatedField) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deprecatedField",
             kind: {:scalar, :UNKNOWN_PLUGIN},
             label: :optional,
             name: :deprecatedField,
             tag: 11,
             type: {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}
           }}
        end

        def field_def("deprecatedField") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deprecatedField",
             kind: {:scalar, :UNKNOWN_PLUGIN},
             label: :optional,
             name: :deprecatedField,
             tag: 11,
             type: {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}
           }}
        end

        []
      ),
      (
        def field_def(:parentPluginType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "parentPluginType",
             kind: {:scalar, :UNKNOWN_PLUGIN},
             label: :optional,
             name: :parentPluginType,
             tag: 12,
             type: {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}
           }}
        end

        def field_def("parentPluginType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "parentPluginType",
             kind: {:scalar, :UNKNOWN_PLUGIN},
             label: :optional,
             name: :parentPluginType,
             tag: 12,
             type: {:enum, WAWebProtobufsAICommon.BotPluginMetadata.PluginType}
           }}
        end

        []
      ),
      (
        def field_def(:faviconCDNURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "faviconCDNURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :faviconCDNURL,
             tag: 13,
             type: :string
           }}
        end

        def field_def("faviconCDNURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "faviconCDNURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :faviconCDNURL,
             tag: 13,
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
    def default(:provider) do
      {:ok, :UNKNOWN}
    end,
    def default(:pluginType) do
      {:ok, :UNKNOWN_PLUGIN}
    end,
    def default(:thumbnailCDNURL) do
      {:ok, ""}
    end,
    def default(:profilePhotoCDNURL) do
      {:ok, ""}
    end,
    def default(:searchProviderURL) do
      {:ok, ""}
    end,
    def default(:referenceIndex) do
      {:ok, 0}
    end,
    def default(:expectedLinksCount) do
      {:ok, 0}
    end,
    def default(:searchQuery) do
      {:ok, ""}
    end,
    def default(:parentPluginMessageKey) do
      {:ok, nil}
    end,
    def default(:deprecatedField) do
      {:ok, :UNKNOWN_PLUGIN}
    end,
    def default(:parentPluginType) do
      {:ok, :UNKNOWN_PLUGIN}
    end,
    def default(:faviconCDNURL) do
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
end
