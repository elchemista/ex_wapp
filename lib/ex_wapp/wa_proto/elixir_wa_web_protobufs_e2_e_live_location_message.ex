# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.LiveLocationMessage do
  @moduledoc false
  defstruct degreesLatitude: nil,
            degreesLongitude: nil,
            accuracyInMeters: nil,
            speedInMps: nil,
            degreesClockwiseFromMagneticNorth: nil,
            caption: nil,
            sequenceNumber: nil,
            timeOffset: nil,
            JPEGThumbnail: nil,
            contextInfo: nil,
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
        |> encode_degreesLatitude(msg)
        |> encode_degreesLongitude(msg)
        |> encode_accuracyInMeters(msg)
        |> encode_speedInMps(msg)
        |> encode_degreesClockwiseFromMagneticNorth(msg)
        |> encode_caption(msg)
        |> encode_sequenceNumber(msg)
        |> encode_timeOffset(msg)
        |> encode_JPEGThumbnail(msg)
        |> encode_contextInfo(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_degreesLatitude(acc, msg) do
        try do
          case msg.degreesLatitude do
            nil -> acc
            _ -> [acc, "\t", Protox.Encode.encode_double(msg.degreesLatitude)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:degreesLatitude, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_degreesLongitude(acc, msg) do
        try do
          case msg.degreesLongitude do
            nil -> acc
            _ -> [acc, "\x11", Protox.Encode.encode_double(msg.degreesLongitude)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:degreesLongitude, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_accuracyInMeters(acc, msg) do
        try do
          case msg.accuracyInMeters do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_uint32(msg.accuracyInMeters)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:accuracyInMeters, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_speedInMps(acc, msg) do
        try do
          case msg.speedInMps do
            nil -> acc
            _ -> [acc, "%", Protox.Encode.encode_float(msg.speedInMps)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:speedInMps, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_degreesClockwiseFromMagneticNorth(acc, msg) do
        try do
          case msg.degreesClockwiseFromMagneticNorth do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_uint32(msg.degreesClockwiseFromMagneticNorth)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :degreesClockwiseFromMagneticNorth,
                      "invalid field value"
                    ),
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
      defp encode_sequenceNumber(acc, msg) do
        try do
          case msg.sequenceNumber do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_int64(msg.sequenceNumber)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:sequenceNumber, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_timeOffset(acc, msg) do
        try do
          case msg.timeOffset do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_uint32(msg.timeOffset)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:timeOffset, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_JPEGThumbnail(acc, msg) do
        try do
          case msg."JPEGThumbnail" do
            nil -> acc
            _ -> [acc, "\x82\x01", Protox.Encode.encode_bytes(msg."JPEGThumbnail")]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:JPEGThumbnail, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_contextInfo(acc, msg) do
        try do
          case msg.contextInfo do
            nil -> acc
            _ -> [acc, "\x8A\x01", Protox.Encode.encode_message(msg.contextInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contextInfo, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.LiveLocationMessage))
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
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[degreesLatitude: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_double(bytes)
              {[degreesLongitude: value], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[accuracyInMeters: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_float(bytes)
              {[speedInMps: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[degreesClockwiseFromMagneticNorth: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[caption: Protox.Decode.validate_string!(delimited)], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[sequenceNumber: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[timeOffset: value], rest}

            {16, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[JPEGThumbnail: delimited], rest}

            {17, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contextInfo:
                   Protox.MergeMessage.merge(
                     msg.contextInfo,
                     WAWebProtobufsE2E.ContextInfo.decode!(delimited)
                   )
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
        WAWebProtobufsE2E.LiveLocationMessage,
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
        1 => {:degreesLatitude, {:scalar, 0.0}, :double},
        2 => {:degreesLongitude, {:scalar, 0.0}, :double},
        3 => {:accuracyInMeters, {:scalar, 0}, :uint32},
        4 => {:speedInMps, {:scalar, 0.0}, :float},
        5 => {:degreesClockwiseFromMagneticNorth, {:scalar, 0}, :uint32},
        6 => {:caption, {:scalar, ""}, :string},
        7 => {:sequenceNumber, {:scalar, 0}, :int64},
        8 => {:timeOffset, {:scalar, 0}, :uint32},
        16 => {:JPEGThumbnail, {:scalar, ""}, :bytes},
        17 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        JPEGThumbnail: {16, {:scalar, ""}, :bytes},
        accuracyInMeters: {3, {:scalar, 0}, :uint32},
        caption: {6, {:scalar, ""}, :string},
        contextInfo: {17, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        degreesClockwiseFromMagneticNorth: {5, {:scalar, 0}, :uint32},
        degreesLatitude: {1, {:scalar, 0.0}, :double},
        degreesLongitude: {2, {:scalar, 0.0}, :double},
        sequenceNumber: {7, {:scalar, 0}, :int64},
        speedInMps: {4, {:scalar, 0.0}, :float},
        timeOffset: {8, {:scalar, 0}, :uint32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "degreesLatitude",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :degreesLatitude,
          tag: 1,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "degreesLongitude",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :degreesLongitude,
          tag: 2,
          type: :double
        },
        %{
          __struct__: Protox.Field,
          json_name: "accuracyInMeters",
          kind: {:scalar, 0},
          label: :optional,
          name: :accuracyInMeters,
          tag: 3,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "speedInMps",
          kind: {:scalar, 0.0},
          label: :optional,
          name: :speedInMps,
          tag: 4,
          type: :float
        },
        %{
          __struct__: Protox.Field,
          json_name: "degreesClockwiseFromMagneticNorth",
          kind: {:scalar, 0},
          label: :optional,
          name: :degreesClockwiseFromMagneticNorth,
          tag: 5,
          type: :uint32
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
          json_name: "sequenceNumber",
          kind: {:scalar, 0},
          label: :optional,
          name: :sequenceNumber,
          tag: 7,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "timeOffset",
          kind: {:scalar, 0},
          label: :optional,
          name: :timeOffset,
          tag: 8,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "JPEGThumbnail",
          kind: {:scalar, ""},
          label: :optional,
          name: :JPEGThumbnail,
          tag: 16,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "contextInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :contextInfo,
          tag: 17,
          type: {:message, WAWebProtobufsE2E.ContextInfo}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:degreesLatitude) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "degreesLatitude",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :degreesLatitude,
             tag: 1,
             type: :double
           }}
        end

        def field_def("degreesLatitude") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "degreesLatitude",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :degreesLatitude,
             tag: 1,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:degreesLongitude) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "degreesLongitude",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :degreesLongitude,
             tag: 2,
             type: :double
           }}
        end

        def field_def("degreesLongitude") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "degreesLongitude",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :degreesLongitude,
             tag: 2,
             type: :double
           }}
        end

        []
      ),
      (
        def field_def(:accuracyInMeters) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accuracyInMeters",
             kind: {:scalar, 0},
             label: :optional,
             name: :accuracyInMeters,
             tag: 3,
             type: :uint32
           }}
        end

        def field_def("accuracyInMeters") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accuracyInMeters",
             kind: {:scalar, 0},
             label: :optional,
             name: :accuracyInMeters,
             tag: 3,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:speedInMps) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "speedInMps",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :speedInMps,
             tag: 4,
             type: :float
           }}
        end

        def field_def("speedInMps") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "speedInMps",
             kind: {:scalar, 0.0},
             label: :optional,
             name: :speedInMps,
             tag: 4,
             type: :float
           }}
        end

        []
      ),
      (
        def field_def(:degreesClockwiseFromMagneticNorth) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "degreesClockwiseFromMagneticNorth",
             kind: {:scalar, 0},
             label: :optional,
             name: :degreesClockwiseFromMagneticNorth,
             tag: 5,
             type: :uint32
           }}
        end

        def field_def("degreesClockwiseFromMagneticNorth") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "degreesClockwiseFromMagneticNorth",
             kind: {:scalar, 0},
             label: :optional,
             name: :degreesClockwiseFromMagneticNorth,
             tag: 5,
             type: :uint32
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
        def field_def(:sequenceNumber) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sequenceNumber",
             kind: {:scalar, 0},
             label: :optional,
             name: :sequenceNumber,
             tag: 7,
             type: :int64
           }}
        end

        def field_def("sequenceNumber") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sequenceNumber",
             kind: {:scalar, 0},
             label: :optional,
             name: :sequenceNumber,
             tag: 7,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:timeOffset) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "timeOffset",
             kind: {:scalar, 0},
             label: :optional,
             name: :timeOffset,
             tag: 8,
             type: :uint32
           }}
        end

        def field_def("timeOffset") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "timeOffset",
             kind: {:scalar, 0},
             label: :optional,
             name: :timeOffset,
             tag: 8,
             type: :uint32
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
             tag: 16,
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
             tag: 16,
             type: :bytes
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
             tag: 17,
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
             tag: 17,
             type: {:message, WAWebProtobufsE2E.ContextInfo}
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
    def default(:degreesLatitude) do
      {:ok, 0.0}
    end,
    def default(:degreesLongitude) do
      {:ok, 0.0}
    end,
    def default(:accuracyInMeters) do
      {:ok, 0}
    end,
    def default(:speedInMps) do
      {:ok, 0.0}
    end,
    def default(:degreesClockwiseFromMagneticNorth) do
      {:ok, 0}
    end,
    def default(:caption) do
      {:ok, ""}
    end,
    def default(:sequenceNumber) do
      {:ok, 0}
    end,
    def default(:timeOffset) do
      {:ok, 0}
    end,
    def default(:JPEGThumbnail) do
      {:ok, ""}
    end,
    def default(:contextInfo) do
      {:ok, nil}
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
