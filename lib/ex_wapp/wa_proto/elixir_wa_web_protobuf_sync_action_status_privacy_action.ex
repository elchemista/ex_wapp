# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.StatusPrivacyAction do
  @moduledoc false
  defstruct mode: nil,
            userJID: [],
            shareToFb: nil,
            shareToIg: nil,
            customLists: [],
            modes: [],
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
        |> encode_mode(msg)
        |> encode_userJID(msg)
        |> encode_shareToFb(msg)
        |> encode_shareToIg(msg)
        |> encode_customLists(msg)
        |> encode_modes(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_mode(acc, msg) do
        try do
          case msg.mode do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.mode
                |> WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mode, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_userJID(acc, msg) do
        try do
          case msg.userJID do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x12", Protox.Encode.encode_string(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:userJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_shareToFb(acc, msg) do
        try do
          case msg.shareToFb do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_bool(msg.shareToFb)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:shareToFb, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_shareToIg(acc, msg) do
        try do
          case msg.shareToIg do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_bool(msg.shareToIg)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:shareToIg, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_customLists(acc, msg) do
        try do
          case msg.customLists do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "*", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:customLists, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_modes(acc, msg) do
        try do
          case msg.modes do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [
                    acc,
                    "0",
                    value
                    |> WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode.encode()
                    |> Protox.Encode.encode_enum()
                  ]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:modes, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufSyncAction.StatusPrivacyAction))
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
                  WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode
                )

              {[mode: value], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[userJID: msg.userJID ++ [Protox.Decode.validate_string!(delimited)]], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[shareToFb: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[shareToIg: value], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 customLists:
                   msg.customLists ++
                     [WAWebProtobufSyncAction.StatusPrivacyAction.CustomList.decode!(delimited)]
               ], rest}

            {6, 2, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 modes:
                   msg.modes ++
                     Protox.Decode.parse_repeated_enum(
                       [],
                       delimited,
                       WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode
                     )
               ], rest}

            {6, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode
                )

              {[modes: msg.modes ++ [value]], rest}

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
        WAWebProtobufSyncAction.StatusPrivacyAction,
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
          {:mode, {:scalar, :ALLOW_LIST},
           {:enum, WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode}},
        2 => {:userJID, :unpacked, :string},
        3 => {:shareToFb, {:scalar, false}, :bool},
        4 => {:shareToIg, {:scalar, false}, :bool},
        5 =>
          {:customLists, :unpacked,
           {:message, WAWebProtobufSyncAction.StatusPrivacyAction.CustomList}},
        6 =>
          {:modes, :unpacked,
           {:enum, WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        customLists:
          {5, :unpacked, {:message, WAWebProtobufSyncAction.StatusPrivacyAction.CustomList}},
        mode:
          {1, {:scalar, :ALLOW_LIST},
           {:enum, WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode}},
        modes:
          {6, :unpacked,
           {:enum, WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode}},
        shareToFb: {3, {:scalar, false}, :bool},
        shareToIg: {4, {:scalar, false}, :bool},
        userJID: {2, :unpacked, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "mode",
          kind: {:scalar, :ALLOW_LIST},
          label: :optional,
          name: :mode,
          tag: 1,
          type: {:enum, WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode}
        },
        %{
          __struct__: Protox.Field,
          json_name: "userJID",
          kind: :unpacked,
          label: :repeated,
          name: :userJID,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "shareToFb",
          kind: {:scalar, false},
          label: :optional,
          name: :shareToFb,
          tag: 3,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "shareToIg",
          kind: {:scalar, false},
          label: :optional,
          name: :shareToIg,
          tag: 4,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "customLists",
          kind: :unpacked,
          label: :repeated,
          name: :customLists,
          tag: 5,
          type: {:message, WAWebProtobufSyncAction.StatusPrivacyAction.CustomList}
        },
        %{
          __struct__: Protox.Field,
          json_name: "modes",
          kind: :unpacked,
          label: :repeated,
          name: :modes,
          tag: 6,
          type: {:enum, WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:mode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mode",
             kind: {:scalar, :ALLOW_LIST},
             label: :optional,
             name: :mode,
             tag: 1,
             type: {:enum, WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode}
           }}
        end

        def field_def("mode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mode",
             kind: {:scalar, :ALLOW_LIST},
             label: :optional,
             name: :mode,
             tag: 1,
             type: {:enum, WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode}
           }}
        end

        []
      ),
      (
        def field_def(:userJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "userJID",
             kind: :unpacked,
             label: :repeated,
             name: :userJID,
             tag: 2,
             type: :string
           }}
        end

        def field_def("userJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "userJID",
             kind: :unpacked,
             label: :repeated,
             name: :userJID,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:shareToFb) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shareToFb",
             kind: {:scalar, false},
             label: :optional,
             name: :shareToFb,
             tag: 3,
             type: :bool
           }}
        end

        def field_def("shareToFb") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shareToFb",
             kind: {:scalar, false},
             label: :optional,
             name: :shareToFb,
             tag: 3,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:shareToIg) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shareToIg",
             kind: {:scalar, false},
             label: :optional,
             name: :shareToIg,
             tag: 4,
             type: :bool
           }}
        end

        def field_def("shareToIg") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shareToIg",
             kind: {:scalar, false},
             label: :optional,
             name: :shareToIg,
             tag: 4,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:customLists) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "customLists",
             kind: :unpacked,
             label: :repeated,
             name: :customLists,
             tag: 5,
             type: {:message, WAWebProtobufSyncAction.StatusPrivacyAction.CustomList}
           }}
        end

        def field_def("customLists") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "customLists",
             kind: :unpacked,
             label: :repeated,
             name: :customLists,
             tag: 5,
             type: {:message, WAWebProtobufSyncAction.StatusPrivacyAction.CustomList}
           }}
        end

        []
      ),
      (
        def field_def(:modes) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "modes",
             kind: :unpacked,
             label: :repeated,
             name: :modes,
             tag: 6,
             type: {:enum, WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode}
           }}
        end

        def field_def("modes") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "modes",
             kind: :unpacked,
             label: :repeated,
             name: :modes,
             tag: 6,
             type: {:enum, WAWebProtobufSyncAction.StatusPrivacyAction.StatusDistributionMode}
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
    def default(:mode) do
      {:ok, :ALLOW_LIST}
    end,
    def default(:userJID) do
      {:error, :no_default_value}
    end,
    def default(:shareToFb) do
      {:ok, false}
    end,
    def default(:shareToIg) do
      {:ok, false}
    end,
    def default(:customLists) do
      {:error, :no_default_value}
    end,
    def default(:modes) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waSyncAction",
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
