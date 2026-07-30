# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.CallLogMessage do
  @moduledoc false
  defstruct isVideo: nil,
            callOutcome: nil,
            durationSecs: nil,
            callType: nil,
            participants: [],
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
        |> encode_isVideo(msg)
        |> encode_callOutcome(msg)
        |> encode_durationSecs(msg)
        |> encode_callType(msg)
        |> encode_participants(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_isVideo(acc, msg) do
        try do
          case msg.isVideo do
            nil -> acc
            _ -> [acc, "\b", Protox.Encode.encode_bool(msg.isVideo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isVideo, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_callOutcome(acc, msg) do
        try do
          case msg.callOutcome do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x10",
                msg.callOutcome
                |> WAWebProtobufsE2E.CallLogMessage.CallOutcome.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callOutcome, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_durationSecs(acc, msg) do
        try do
          case msg.durationSecs do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_int64(msg.durationSecs)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:durationSecs, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_callType(acc, msg) do
        try do
          case msg.callType do
            nil ->
              acc

            _ ->
              [
                acc,
                " ",
                msg.callType
                |> WAWebProtobufsE2E.CallLogMessage.CallType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_participants(acc, msg) do
        try do
          case msg.participants do
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
            reraise Protox.EncodingError.new(:participants, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.CallLogMessage))
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
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isVideo: value], rest}

            {2, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.CallLogMessage.CallOutcome)

              {[callOutcome: value], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[durationSecs: value], rest}

            {4, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.CallLogMessage.CallType)

              {[callType: value], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 participants:
                   msg.participants ++
                     [WAWebProtobufsE2E.CallLogMessage.CallParticipant.decode!(delimited)]
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
        WAWebProtobufsE2E.CallLogMessage,
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
        1 => {:isVideo, {:scalar, false}, :bool},
        2 =>
          {:callOutcome, {:scalar, :CONNECTED},
           {:enum, WAWebProtobufsE2E.CallLogMessage.CallOutcome}},
        3 => {:durationSecs, {:scalar, 0}, :int64},
        4 => {:callType, {:scalar, :REGULAR}, {:enum, WAWebProtobufsE2E.CallLogMessage.CallType}},
        5 =>
          {:participants, :unpacked, {:message, WAWebProtobufsE2E.CallLogMessage.CallParticipant}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        callOutcome:
          {2, {:scalar, :CONNECTED}, {:enum, WAWebProtobufsE2E.CallLogMessage.CallOutcome}},
        callType: {4, {:scalar, :REGULAR}, {:enum, WAWebProtobufsE2E.CallLogMessage.CallType}},
        durationSecs: {3, {:scalar, 0}, :int64},
        isVideo: {1, {:scalar, false}, :bool},
        participants: {5, :unpacked, {:message, WAWebProtobufsE2E.CallLogMessage.CallParticipant}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "isVideo",
          kind: {:scalar, false},
          label: :optional,
          name: :isVideo,
          tag: 1,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "callOutcome",
          kind: {:scalar, :CONNECTED},
          label: :optional,
          name: :callOutcome,
          tag: 2,
          type: {:enum, WAWebProtobufsE2E.CallLogMessage.CallOutcome}
        },
        %{
          __struct__: Protox.Field,
          json_name: "durationSecs",
          kind: {:scalar, 0},
          label: :optional,
          name: :durationSecs,
          tag: 3,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "callType",
          kind: {:scalar, :REGULAR},
          label: :optional,
          name: :callType,
          tag: 4,
          type: {:enum, WAWebProtobufsE2E.CallLogMessage.CallType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "participants",
          kind: :unpacked,
          label: :repeated,
          name: :participants,
          tag: 5,
          type: {:message, WAWebProtobufsE2E.CallLogMessage.CallParticipant}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:isVideo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isVideo",
             kind: {:scalar, false},
             label: :optional,
             name: :isVideo,
             tag: 1,
             type: :bool
           }}
        end

        def field_def("isVideo") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isVideo",
             kind: {:scalar, false},
             label: :optional,
             name: :isVideo,
             tag: 1,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:callOutcome) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callOutcome",
             kind: {:scalar, :CONNECTED},
             label: :optional,
             name: :callOutcome,
             tag: 2,
             type: {:enum, WAWebProtobufsE2E.CallLogMessage.CallOutcome}
           }}
        end

        def field_def("callOutcome") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callOutcome",
             kind: {:scalar, :CONNECTED},
             label: :optional,
             name: :callOutcome,
             tag: 2,
             type: {:enum, WAWebProtobufsE2E.CallLogMessage.CallOutcome}
           }}
        end

        []
      ),
      (
        def field_def(:durationSecs) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "durationSecs",
             kind: {:scalar, 0},
             label: :optional,
             name: :durationSecs,
             tag: 3,
             type: :int64
           }}
        end

        def field_def("durationSecs") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "durationSecs",
             kind: {:scalar, 0},
             label: :optional,
             name: :durationSecs,
             tag: 3,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:callType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callType",
             kind: {:scalar, :REGULAR},
             label: :optional,
             name: :callType,
             tag: 4,
             type: {:enum, WAWebProtobufsE2E.CallLogMessage.CallType}
           }}
        end

        def field_def("callType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callType",
             kind: {:scalar, :REGULAR},
             label: :optional,
             name: :callType,
             tag: 4,
             type: {:enum, WAWebProtobufsE2E.CallLogMessage.CallType}
           }}
        end

        []
      ),
      (
        def field_def(:participants) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "participants",
             kind: :unpacked,
             label: :repeated,
             name: :participants,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.CallLogMessage.CallParticipant}
           }}
        end

        def field_def("participants") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "participants",
             kind: :unpacked,
             label: :repeated,
             name: :participants,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.CallLogMessage.CallParticipant}
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
    def default(:isVideo) do
      {:ok, false}
    end,
    def default(:callOutcome) do
      {:ok, :CONNECTED}
    end,
    def default(:durationSecs) do
      {:ok, 0}
    end,
    def default(:callType) do
      {:ok, :REGULAR}
    end,
    def default(:participants) do
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

  @type t :: %__MODULE__{}
end
