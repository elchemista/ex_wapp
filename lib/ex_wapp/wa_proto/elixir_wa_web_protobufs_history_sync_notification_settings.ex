# credo:disable-for-this-file
defmodule WAWebProtobufsHistorySync.NotificationSettings do
  @moduledoc false
  defstruct messageVibrate: nil,
            messagePopup: nil,
            messageLight: nil,
            lowPriorityNotifications: nil,
            reactionsMuted: nil,
            callVibrate: nil,
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
        |> encode_messageVibrate(msg)
        |> encode_messagePopup(msg)
        |> encode_messageLight(msg)
        |> encode_lowPriorityNotifications(msg)
        |> encode_reactionsMuted(msg)
        |> encode_callVibrate(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_messageVibrate(acc, msg) do
        try do
          case msg.messageVibrate do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.messageVibrate)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageVibrate, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_messagePopup(acc, msg) do
        try do
          case msg.messagePopup do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.messagePopup)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messagePopup, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_messageLight(acc, msg) do
        try do
          case msg.messageLight do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.messageLight)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messageLight, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_lowPriorityNotifications(acc, msg) do
        try do
          case msg.lowPriorityNotifications do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_bool(msg.lowPriorityNotifications)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lowPriorityNotifications, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_reactionsMuted(acc, msg) do
        try do
          case msg.reactionsMuted do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_bool(msg.reactionsMuted)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:reactionsMuted, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_callVibrate(acc, msg) do
        try do
          case msg.callVibrate do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.callVibrate)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callVibrate, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsHistorySync.NotificationSettings))
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
              {[messageVibrate: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[messagePopup: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[messageLight: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[lowPriorityNotifications: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[reactionsMuted: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[callVibrate: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufsHistorySync.NotificationSettings,
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
        1 => {:messageVibrate, {:scalar, ""}, :string},
        2 => {:messagePopup, {:scalar, ""}, :string},
        3 => {:messageLight, {:scalar, ""}, :string},
        4 => {:lowPriorityNotifications, {:scalar, false}, :bool},
        5 => {:reactionsMuted, {:scalar, false}, :bool},
        6 => {:callVibrate, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        callVibrate: {6, {:scalar, ""}, :string},
        lowPriorityNotifications: {4, {:scalar, false}, :bool},
        messageLight: {3, {:scalar, ""}, :string},
        messagePopup: {2, {:scalar, ""}, :string},
        messageVibrate: {1, {:scalar, ""}, :string},
        reactionsMuted: {5, {:scalar, false}, :bool}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "messageVibrate",
          kind: {:scalar, ""},
          label: :optional,
          name: :messageVibrate,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "messagePopup",
          kind: {:scalar, ""},
          label: :optional,
          name: :messagePopup,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "messageLight",
          kind: {:scalar, ""},
          label: :optional,
          name: :messageLight,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "lowPriorityNotifications",
          kind: {:scalar, false},
          label: :optional,
          name: :lowPriorityNotifications,
          tag: 4,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "reactionsMuted",
          kind: {:scalar, false},
          label: :optional,
          name: :reactionsMuted,
          tag: 5,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "callVibrate",
          kind: {:scalar, ""},
          label: :optional,
          name: :callVibrate,
          tag: 6,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:messageVibrate) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageVibrate",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageVibrate,
             tag: 1,
             type: :string
           }}
        end

        def field_def("messageVibrate") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageVibrate",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageVibrate,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:messagePopup) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messagePopup",
             kind: {:scalar, ""},
             label: :optional,
             name: :messagePopup,
             tag: 2,
             type: :string
           }}
        end

        def field_def("messagePopup") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messagePopup",
             kind: {:scalar, ""},
             label: :optional,
             name: :messagePopup,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:messageLight) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageLight",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageLight,
             tag: 3,
             type: :string
           }}
        end

        def field_def("messageLight") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messageLight",
             kind: {:scalar, ""},
             label: :optional,
             name: :messageLight,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:lowPriorityNotifications) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lowPriorityNotifications",
             kind: {:scalar, false},
             label: :optional,
             name: :lowPriorityNotifications,
             tag: 4,
             type: :bool
           }}
        end

        def field_def("lowPriorityNotifications") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lowPriorityNotifications",
             kind: {:scalar, false},
             label: :optional,
             name: :lowPriorityNotifications,
             tag: 4,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:reactionsMuted) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reactionsMuted",
             kind: {:scalar, false},
             label: :optional,
             name: :reactionsMuted,
             tag: 5,
             type: :bool
           }}
        end

        def field_def("reactionsMuted") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reactionsMuted",
             kind: {:scalar, false},
             label: :optional,
             name: :reactionsMuted,
             tag: 5,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:callVibrate) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callVibrate",
             kind: {:scalar, ""},
             label: :optional,
             name: :callVibrate,
             tag: 6,
             type: :string
           }}
        end

        def field_def("callVibrate") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callVibrate",
             kind: {:scalar, ""},
             label: :optional,
             name: :callVibrate,
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
    def default(:messageVibrate) do
      {:ok, ""}
    end,
    def default(:messagePopup) do
      {:ok, ""}
    end,
    def default(:messageLight) do
      {:ok, ""}
    end,
    def default(:lowPriorityNotifications) do
      {:ok, false}
    end,
    def default(:reactionsMuted) do
      {:ok, false}
    end,
    def default(:callVibrate) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waHistorySync",
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
