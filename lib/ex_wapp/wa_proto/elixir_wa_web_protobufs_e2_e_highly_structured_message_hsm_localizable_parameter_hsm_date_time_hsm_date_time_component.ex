# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent do
  @moduledoc false
  defstruct dayOfWeek: nil,
            year: nil,
            month: nil,
            dayOfMonth: nil,
            hour: nil,
            minute: nil,
            calendar: nil,
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
        |> encode_dayOfWeek(msg)
        |> encode_year(msg)
        |> encode_month(msg)
        |> encode_dayOfMonth(msg)
        |> encode_hour(msg)
        |> encode_minute(msg)
        |> encode_calendar(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_dayOfWeek(acc, msg) do
        try do
          case msg.dayOfWeek do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.dayOfWeek
                |> WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.DayOfWeekType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:dayOfWeek, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_year(acc, msg) do
        try do
          case msg.year do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_uint32(msg.year)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:year, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_month(acc, msg) do
        try do
          case msg.month do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_uint32(msg.month)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:month, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_dayOfMonth(acc, msg) do
        try do
          case msg.dayOfMonth do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_uint32(msg.dayOfMonth)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:dayOfMonth, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_hour(acc, msg) do
        try do
          case msg.hour do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_uint32(msg.hour)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:hour, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_minute(acc, msg) do
        try do
          case msg.minute do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_uint32(msg.minute)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:minute, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_calendar(acc, msg) do
        try do
          case msg.calendar do
            nil ->
              acc

            _ ->
              [
                acc,
                "8",
                msg.calendar
                |> WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.CalendarType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:calendar, "invalid field value"), __STACKTRACE__
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
            struct(
              WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent
            )
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
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.DayOfWeekType
                )

              {[dayOfWeek: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[year: value], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[month: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[dayOfMonth: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[hour: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[minute: value], rest}

            {7, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.CalendarType
                )

              {[calendar: value], rest}

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
        WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent,
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
          {:dayOfWeek, {:scalar, :MONDAY},
           {:enum,
            WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.DayOfWeekType}},
        2 => {:year, {:scalar, 0}, :uint32},
        3 => {:month, {:scalar, 0}, :uint32},
        4 => {:dayOfMonth, {:scalar, 0}, :uint32},
        5 => {:hour, {:scalar, 0}, :uint32},
        6 => {:minute, {:scalar, 0}, :uint32},
        7 =>
          {:calendar, {:scalar, :GREGORIAN},
           {:enum,
            WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.CalendarType}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        calendar:
          {7, {:scalar, :GREGORIAN},
           {:enum,
            WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.CalendarType}},
        dayOfMonth: {4, {:scalar, 0}, :uint32},
        dayOfWeek:
          {1, {:scalar, :MONDAY},
           {:enum,
            WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.DayOfWeekType}},
        hour: {5, {:scalar, 0}, :uint32},
        minute: {6, {:scalar, 0}, :uint32},
        month: {3, {:scalar, 0}, :uint32},
        year: {2, {:scalar, 0}, :uint32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "dayOfWeek",
          kind: {:scalar, :MONDAY},
          label: :optional,
          name: :dayOfWeek,
          tag: 1,
          type:
            {:enum,
             WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.DayOfWeekType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "year",
          kind: {:scalar, 0},
          label: :optional,
          name: :year,
          tag: 2,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "month",
          kind: {:scalar, 0},
          label: :optional,
          name: :month,
          tag: 3,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "dayOfMonth",
          kind: {:scalar, 0},
          label: :optional,
          name: :dayOfMonth,
          tag: 4,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "hour",
          kind: {:scalar, 0},
          label: :optional,
          name: :hour,
          tag: 5,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "minute",
          kind: {:scalar, 0},
          label: :optional,
          name: :minute,
          tag: 6,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "calendar",
          kind: {:scalar, :GREGORIAN},
          label: :optional,
          name: :calendar,
          tag: 7,
          type:
            {:enum,
             WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.CalendarType}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:dayOfWeek) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "dayOfWeek",
             kind: {:scalar, :MONDAY},
             label: :optional,
             name: :dayOfWeek,
             tag: 1,
             type:
               {:enum,
                WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.DayOfWeekType}
           }}
        end

        def field_def("dayOfWeek") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "dayOfWeek",
             kind: {:scalar, :MONDAY},
             label: :optional,
             name: :dayOfWeek,
             tag: 1,
             type:
               {:enum,
                WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.DayOfWeekType}
           }}
        end

        []
      ),
      (
        def field_def(:year) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "year",
             kind: {:scalar, 0},
             label: :optional,
             name: :year,
             tag: 2,
             type: :uint32
           }}
        end

        def field_def("year") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "year",
             kind: {:scalar, 0},
             label: :optional,
             name: :year,
             tag: 2,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:month) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "month",
             kind: {:scalar, 0},
             label: :optional,
             name: :month,
             tag: 3,
             type: :uint32
           }}
        end

        def field_def("month") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "month",
             kind: {:scalar, 0},
             label: :optional,
             name: :month,
             tag: 3,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:dayOfMonth) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "dayOfMonth",
             kind: {:scalar, 0},
             label: :optional,
             name: :dayOfMonth,
             tag: 4,
             type: :uint32
           }}
        end

        def field_def("dayOfMonth") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "dayOfMonth",
             kind: {:scalar, 0},
             label: :optional,
             name: :dayOfMonth,
             tag: 4,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:hour) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hour",
             kind: {:scalar, 0},
             label: :optional,
             name: :hour,
             tag: 5,
             type: :uint32
           }}
        end

        def field_def("hour") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hour",
             kind: {:scalar, 0},
             label: :optional,
             name: :hour,
             tag: 5,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:minute) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "minute",
             kind: {:scalar, 0},
             label: :optional,
             name: :minute,
             tag: 6,
             type: :uint32
           }}
        end

        def field_def("minute") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "minute",
             kind: {:scalar, 0},
             label: :optional,
             name: :minute,
             tag: 6,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:calendar) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "calendar",
             kind: {:scalar, :GREGORIAN},
             label: :optional,
             name: :calendar,
             tag: 7,
             type:
               {:enum,
                WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.CalendarType}
           }}
        end

        def field_def("calendar") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "calendar",
             kind: {:scalar, :GREGORIAN},
             label: :optional,
             name: :calendar,
             tag: 7,
             type:
               {:enum,
                WAWebProtobufsE2E.HighlyStructuredMessage.HSMLocalizableParameter.HSMDateTime.HSMDateTimeComponent.CalendarType}
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
    def default(:dayOfWeek) do
      {:ok, :MONDAY}
    end,
    def default(:year) do
      {:ok, 0}
    end,
    def default(:month) do
      {:ok, 0}
    end,
    def default(:dayOfMonth) do
      {:ok, 0}
    end,
    def default(:hour) do
      {:ok, 0}
    end,
    def default(:minute) do
      {:ok, 0}
    end,
    def default(:calendar) do
      {:ok, :GREGORIAN}
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
