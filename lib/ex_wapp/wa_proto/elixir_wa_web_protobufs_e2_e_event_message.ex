# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.EventMessage do
  @moduledoc false
  defstruct contextInfo: nil,
            isCanceled: nil,
            name: nil,
            description: nil,
            location: nil,
            joinLink: nil,
            startTime: nil,
            endTime: nil,
            extraGuestsAllowed: nil,
            isScheduleCall: nil,
            hasReminder: nil,
            reminderOffsetSec: nil,
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
        |> encode_contextInfo(msg)
        |> encode_isCanceled(msg)
        |> encode_name(msg)
        |> encode_description(msg)
        |> encode_location(msg)
        |> encode_joinLink(msg)
        |> encode_startTime(msg)
        |> encode_endTime(msg)
        |> encode_extraGuestsAllowed(msg)
        |> encode_isScheduleCall(msg)
        |> encode_hasReminder(msg)
        |> encode_reminderOffsetSec(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_contextInfo(acc, msg) do
        try do
          case msg.contextInfo do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_message(msg.contextInfo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contextInfo, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isCanceled(acc, msg) do
        try do
          case msg.isCanceled do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_bool(msg.isCanceled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isCanceled, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_name(acc, msg) do
        try do
          case msg.name do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.name)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:name, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_description(acc, msg) do
        try do
          case msg.description do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.description)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:description, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_location(acc, msg) do
        try do
          case msg.location do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_message(msg.location)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:location, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_joinLink(acc, msg) do
        try do
          case msg.joinLink do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.joinLink)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:joinLink, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_startTime(acc, msg) do
        try do
          case msg.startTime do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_int64(msg.startTime)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:startTime, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_endTime(acc, msg) do
        try do
          case msg.endTime do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_int64(msg.endTime)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:endTime, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_extraGuestsAllowed(acc, msg) do
        try do
          case msg.extraGuestsAllowed do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_bool(msg.extraGuestsAllowed)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:extraGuestsAllowed, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isScheduleCall(acc, msg) do
        try do
          case msg.isScheduleCall do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_bool(msg.isScheduleCall)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isScheduleCall, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_hasReminder(acc, msg) do
        try do
          case msg.hasReminder do
            nil -> acc
            _ -> [acc, "X", Protox.Encode.encode_bool(msg.hasReminder)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:hasReminder, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_reminderOffsetSec(acc, msg) do
        try do
          case msg.reminderOffsetSec do
            nil -> acc
            _ -> [acc, "`", Protox.Encode.encode_int64(msg.reminderOffsetSec)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:reminderOffsetSec, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.EventMessage))
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

              {[
                 contextInfo:
                   Protox.MergeMessage.merge(
                     msg.contextInfo,
                     WAWebProtobufsE2E.ContextInfo.decode!(delimited)
                   )
               ], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isCanceled: value], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[name: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[description: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 location:
                   Protox.MergeMessage.merge(
                     msg.location,
                     WAWebProtobufsE2E.LocationMessage.decode!(delimited)
                   )
               ], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[joinLink: Protox.Decode.validate_string!(delimited)], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[startTime: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[endTime: value], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[extraGuestsAllowed: value], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isScheduleCall: value], rest}

            {11, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[hasReminder: value], rest}

            {12, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[reminderOffsetSec: value], rest}

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
        WAWebProtobufsE2E.EventMessage,
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
        1 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        2 => {:isCanceled, {:scalar, false}, :bool},
        3 => {:name, {:scalar, ""}, :string},
        4 => {:description, {:scalar, ""}, :string},
        5 => {:location, {:scalar, nil}, {:message, WAWebProtobufsE2E.LocationMessage}},
        6 => {:joinLink, {:scalar, ""}, :string},
        7 => {:startTime, {:scalar, 0}, :int64},
        8 => {:endTime, {:scalar, 0}, :int64},
        9 => {:extraGuestsAllowed, {:scalar, false}, :bool},
        10 => {:isScheduleCall, {:scalar, false}, :bool},
        11 => {:hasReminder, {:scalar, false}, :bool},
        12 => {:reminderOffsetSec, {:scalar, 0}, :int64}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        contextInfo: {1, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        description: {4, {:scalar, ""}, :string},
        endTime: {8, {:scalar, 0}, :int64},
        extraGuestsAllowed: {9, {:scalar, false}, :bool},
        hasReminder: {11, {:scalar, false}, :bool},
        isCanceled: {2, {:scalar, false}, :bool},
        isScheduleCall: {10, {:scalar, false}, :bool},
        joinLink: {6, {:scalar, ""}, :string},
        location: {5, {:scalar, nil}, {:message, WAWebProtobufsE2E.LocationMessage}},
        name: {3, {:scalar, ""}, :string},
        reminderOffsetSec: {12, {:scalar, 0}, :int64},
        startTime: {7, {:scalar, 0}, :int64}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "contextInfo",
          kind: {:scalar, nil},
          label: :optional,
          name: :contextInfo,
          tag: 1,
          type: {:message, WAWebProtobufsE2E.ContextInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "isCanceled",
          kind: {:scalar, false},
          label: :optional,
          name: :isCanceled,
          tag: 2,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "name",
          kind: {:scalar, ""},
          label: :optional,
          name: :name,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "description",
          kind: {:scalar, ""},
          label: :optional,
          name: :description,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "location",
          kind: {:scalar, nil},
          label: :optional,
          name: :location,
          tag: 5,
          type: {:message, WAWebProtobufsE2E.LocationMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "joinLink",
          kind: {:scalar, ""},
          label: :optional,
          name: :joinLink,
          tag: 6,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "startTime",
          kind: {:scalar, 0},
          label: :optional,
          name: :startTime,
          tag: 7,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "endTime",
          kind: {:scalar, 0},
          label: :optional,
          name: :endTime,
          tag: 8,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "extraGuestsAllowed",
          kind: {:scalar, false},
          label: :optional,
          name: :extraGuestsAllowed,
          tag: 9,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isScheduleCall",
          kind: {:scalar, false},
          label: :optional,
          name: :isScheduleCall,
          tag: 10,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "hasReminder",
          kind: {:scalar, false},
          label: :optional,
          name: :hasReminder,
          tag: 11,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "reminderOffsetSec",
          kind: {:scalar, 0},
          label: :optional,
          name: :reminderOffsetSec,
          tag: 12,
          type: :int64
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:contextInfo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contextInfo",
             kind: {:scalar, nil},
             label: :optional,
             name: :contextInfo,
             tag: 1,
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
             tag: 1,
             type: {:message, WAWebProtobufsE2E.ContextInfo}
           }}
        end

        []
      ),
      (
        def field_def(:isCanceled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isCanceled",
             kind: {:scalar, false},
             label: :optional,
             name: :isCanceled,
             tag: 2,
             type: :bool
           }}
        end

        def field_def("isCanceled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isCanceled",
             kind: {:scalar, false},
             label: :optional,
             name: :isCanceled,
             tag: 2,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:name) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "name",
             kind: {:scalar, ""},
             label: :optional,
             name: :name,
             tag: 3,
             type: :string
           }}
        end

        def field_def("name") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "name",
             kind: {:scalar, ""},
             label: :optional,
             name: :name,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:description) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "description",
             kind: {:scalar, ""},
             label: :optional,
             name: :description,
             tag: 4,
             type: :string
           }}
        end

        def field_def("description") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "description",
             kind: {:scalar, ""},
             label: :optional,
             name: :description,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:location) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "location",
             kind: {:scalar, nil},
             label: :optional,
             name: :location,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.LocationMessage}
           }}
        end

        def field_def("location") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "location",
             kind: {:scalar, nil},
             label: :optional,
             name: :location,
             tag: 5,
             type: {:message, WAWebProtobufsE2E.LocationMessage}
           }}
        end

        []
      ),
      (
        def field_def(:joinLink) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "joinLink",
             kind: {:scalar, ""},
             label: :optional,
             name: :joinLink,
             tag: 6,
             type: :string
           }}
        end

        def field_def("joinLink") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "joinLink",
             kind: {:scalar, ""},
             label: :optional,
             name: :joinLink,
             tag: 6,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:startTime) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "startTime",
             kind: {:scalar, 0},
             label: :optional,
             name: :startTime,
             tag: 7,
             type: :int64
           }}
        end

        def field_def("startTime") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "startTime",
             kind: {:scalar, 0},
             label: :optional,
             name: :startTime,
             tag: 7,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:endTime) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "endTime",
             kind: {:scalar, 0},
             label: :optional,
             name: :endTime,
             tag: 8,
             type: :int64
           }}
        end

        def field_def("endTime") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "endTime",
             kind: {:scalar, 0},
             label: :optional,
             name: :endTime,
             tag: 8,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:extraGuestsAllowed) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "extraGuestsAllowed",
             kind: {:scalar, false},
             label: :optional,
             name: :extraGuestsAllowed,
             tag: 9,
             type: :bool
           }}
        end

        def field_def("extraGuestsAllowed") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "extraGuestsAllowed",
             kind: {:scalar, false},
             label: :optional,
             name: :extraGuestsAllowed,
             tag: 9,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isScheduleCall) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isScheduleCall",
             kind: {:scalar, false},
             label: :optional,
             name: :isScheduleCall,
             tag: 10,
             type: :bool
           }}
        end

        def field_def("isScheduleCall") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isScheduleCall",
             kind: {:scalar, false},
             label: :optional,
             name: :isScheduleCall,
             tag: 10,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:hasReminder) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hasReminder",
             kind: {:scalar, false},
             label: :optional,
             name: :hasReminder,
             tag: 11,
             type: :bool
           }}
        end

        def field_def("hasReminder") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hasReminder",
             kind: {:scalar, false},
             label: :optional,
             name: :hasReminder,
             tag: 11,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:reminderOffsetSec) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reminderOffsetSec",
             kind: {:scalar, 0},
             label: :optional,
             name: :reminderOffsetSec,
             tag: 12,
             type: :int64
           }}
        end

        def field_def("reminderOffsetSec") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reminderOffsetSec",
             kind: {:scalar, 0},
             label: :optional,
             name: :reminderOffsetSec,
             tag: 12,
             type: :int64
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
    def default(:contextInfo) do
      {:ok, nil}
    end,
    def default(:isCanceled) do
      {:ok, false}
    end,
    def default(:name) do
      {:ok, ""}
    end,
    def default(:description) do
      {:ok, ""}
    end,
    def default(:location) do
      {:ok, nil}
    end,
    def default(:joinLink) do
      {:ok, ""}
    end,
    def default(:startTime) do
      {:ok, 0}
    end,
    def default(:endTime) do
      {:ok, 0}
    end,
    def default(:extraGuestsAllowed) do
      {:ok, false}
    end,
    def default(:isScheduleCall) do
      {:ok, false}
    end,
    def default(:hasReminder) do
      {:ok, false}
    end,
    def default(:reminderOffsetSec) do
      {:ok, 0}
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
