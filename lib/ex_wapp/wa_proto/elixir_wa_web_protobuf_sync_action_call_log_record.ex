# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.CallLogRecord do
  @moduledoc false
  defstruct callResult: nil,
            isDndMode: nil,
            silenceReason: nil,
            duration: nil,
            startTime: nil,
            isIncoming: nil,
            isVideo: nil,
            isCallLink: nil,
            callLinkToken: nil,
            scheduledCallID: nil,
            callID: nil,
            callCreatorJID: nil,
            groupJID: nil,
            participants: [],
            callType: nil,
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
        |> encode_callResult(msg)
        |> encode_isDndMode(msg)
        |> encode_silenceReason(msg)
        |> encode_duration(msg)
        |> encode_startTime(msg)
        |> encode_isIncoming(msg)
        |> encode_isVideo(msg)
        |> encode_isCallLink(msg)
        |> encode_callLinkToken(msg)
        |> encode_scheduledCallID(msg)
        |> encode_callID(msg)
        |> encode_callCreatorJID(msg)
        |> encode_groupJID(msg)
        |> encode_participants(msg)
        |> encode_callType(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_callResult(acc, msg) do
        try do
          case msg.callResult do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.callResult
                |> WAWebProtobufSyncAction.CallLogRecord.CallResult.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callResult, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isDndMode(acc, msg) do
        try do
          case msg.isDndMode do
            nil -> acc
            _ -> [acc, "\x10", Protox.Encode.encode_bool(msg.isDndMode)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isDndMode, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_silenceReason(acc, msg) do
        try do
          case msg.silenceReason do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x18",
                msg.silenceReason
                |> WAWebProtobufSyncAction.CallLogRecord.SilenceReason.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:silenceReason, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_duration(acc, msg) do
        try do
          case msg.duration do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_int64(msg.duration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:duration, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_startTime(acc, msg) do
        try do
          case msg.startTime do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_int64(msg.startTime)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:startTime, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isIncoming(acc, msg) do
        try do
          case msg.isIncoming do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_bool(msg.isIncoming)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isIncoming, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isVideo(acc, msg) do
        try do
          case msg.isVideo do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_bool(msg.isVideo)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isVideo, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isCallLink(acc, msg) do
        try do
          case msg.isCallLink do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_bool(msg.isCallLink)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isCallLink, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_callLinkToken(acc, msg) do
        try do
          case msg.callLinkToken do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_string(msg.callLinkToken)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callLinkToken, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_scheduledCallID(acc, msg) do
        try do
          case msg.scheduledCallID do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_string(msg.scheduledCallID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:scheduledCallID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_callID(acc, msg) do
        try do
          case msg.callID do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_string(msg.callID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_callCreatorJID(acc, msg) do
        try do
          case msg.callCreatorJID do
            nil -> acc
            _ -> [acc, "b", Protox.Encode.encode_string(msg.callCreatorJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callCreatorJID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_groupJID(acc, msg) do
        try do
          case msg.groupJID do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_string(msg.groupJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupJID, "invalid field value"), __STACKTRACE__
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
                  [acc, "r", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:participants, "invalid field value"), __STACKTRACE__
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
                "x",
                msg.callType
                |> WAWebProtobufSyncAction.CallLogRecord.CallType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callType, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufSyncAction.CallLogRecord))
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
                Protox.Decode.parse_enum(bytes, WAWebProtobufSyncAction.CallLogRecord.CallResult)

              {[callResult: value], rest}

            {2, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isDndMode: value], rest}

            {3, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufSyncAction.CallLogRecord.SilenceReason
                )

              {[silenceReason: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[duration: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[startTime: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isIncoming: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isVideo: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isCallLink: value], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[callLinkToken: Protox.Decode.validate_string!(delimited)], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[scheduledCallID: Protox.Decode.validate_string!(delimited)], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[callID: Protox.Decode.validate_string!(delimited)], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[callCreatorJID: Protox.Decode.validate_string!(delimited)], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[groupJID: Protox.Decode.validate_string!(delimited)], rest}

            {14, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 participants:
                   msg.participants ++
                     [WAWebProtobufSyncAction.CallLogRecord.ParticipantInfo.decode!(delimited)]
               ], rest}

            {15, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufSyncAction.CallLogRecord.CallType)

              {[callType: value], rest}

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
        WAWebProtobufSyncAction.CallLogRecord,
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
          {:callResult, {:scalar, :CONNECTED},
           {:enum, WAWebProtobufSyncAction.CallLogRecord.CallResult}},
        2 => {:isDndMode, {:scalar, false}, :bool},
        3 =>
          {:silenceReason, {:scalar, :NONE},
           {:enum, WAWebProtobufSyncAction.CallLogRecord.SilenceReason}},
        4 => {:duration, {:scalar, 0}, :int64},
        5 => {:startTime, {:scalar, 0}, :int64},
        6 => {:isIncoming, {:scalar, false}, :bool},
        7 => {:isVideo, {:scalar, false}, :bool},
        8 => {:isCallLink, {:scalar, false}, :bool},
        9 => {:callLinkToken, {:scalar, ""}, :string},
        10 => {:scheduledCallID, {:scalar, ""}, :string},
        11 => {:callID, {:scalar, ""}, :string},
        12 => {:callCreatorJID, {:scalar, ""}, :string},
        13 => {:groupJID, {:scalar, ""}, :string},
        14 =>
          {:participants, :unpacked,
           {:message, WAWebProtobufSyncAction.CallLogRecord.ParticipantInfo}},
        15 =>
          {:callType, {:scalar, :REGULAR},
           {:enum, WAWebProtobufSyncAction.CallLogRecord.CallType}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        callCreatorJID: {12, {:scalar, ""}, :string},
        callID: {11, {:scalar, ""}, :string},
        callLinkToken: {9, {:scalar, ""}, :string},
        callResult:
          {1, {:scalar, :CONNECTED}, {:enum, WAWebProtobufSyncAction.CallLogRecord.CallResult}},
        callType:
          {15, {:scalar, :REGULAR}, {:enum, WAWebProtobufSyncAction.CallLogRecord.CallType}},
        duration: {4, {:scalar, 0}, :int64},
        groupJID: {13, {:scalar, ""}, :string},
        isCallLink: {8, {:scalar, false}, :bool},
        isDndMode: {2, {:scalar, false}, :bool},
        isIncoming: {6, {:scalar, false}, :bool},
        isVideo: {7, {:scalar, false}, :bool},
        participants:
          {14, :unpacked, {:message, WAWebProtobufSyncAction.CallLogRecord.ParticipantInfo}},
        scheduledCallID: {10, {:scalar, ""}, :string},
        silenceReason:
          {3, {:scalar, :NONE}, {:enum, WAWebProtobufSyncAction.CallLogRecord.SilenceReason}},
        startTime: {5, {:scalar, 0}, :int64}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "callResult",
          kind: {:scalar, :CONNECTED},
          label: :optional,
          name: :callResult,
          tag: 1,
          type: {:enum, WAWebProtobufSyncAction.CallLogRecord.CallResult}
        },
        %{
          __struct__: Protox.Field,
          json_name: "isDndMode",
          kind: {:scalar, false},
          label: :optional,
          name: :isDndMode,
          tag: 2,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "silenceReason",
          kind: {:scalar, :NONE},
          label: :optional,
          name: :silenceReason,
          tag: 3,
          type: {:enum, WAWebProtobufSyncAction.CallLogRecord.SilenceReason}
        },
        %{
          __struct__: Protox.Field,
          json_name: "duration",
          kind: {:scalar, 0},
          label: :optional,
          name: :duration,
          tag: 4,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "startTime",
          kind: {:scalar, 0},
          label: :optional,
          name: :startTime,
          tag: 5,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "isIncoming",
          kind: {:scalar, false},
          label: :optional,
          name: :isIncoming,
          tag: 6,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isVideo",
          kind: {:scalar, false},
          label: :optional,
          name: :isVideo,
          tag: 7,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isCallLink",
          kind: {:scalar, false},
          label: :optional,
          name: :isCallLink,
          tag: 8,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "callLinkToken",
          kind: {:scalar, ""},
          label: :optional,
          name: :callLinkToken,
          tag: 9,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "scheduledCallID",
          kind: {:scalar, ""},
          label: :optional,
          name: :scheduledCallID,
          tag: 10,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "callID",
          kind: {:scalar, ""},
          label: :optional,
          name: :callID,
          tag: 11,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "callCreatorJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :callCreatorJID,
          tag: 12,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :groupJID,
          tag: 13,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "participants",
          kind: :unpacked,
          label: :repeated,
          name: :participants,
          tag: 14,
          type: {:message, WAWebProtobufSyncAction.CallLogRecord.ParticipantInfo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "callType",
          kind: {:scalar, :REGULAR},
          label: :optional,
          name: :callType,
          tag: 15,
          type: {:enum, WAWebProtobufSyncAction.CallLogRecord.CallType}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:callResult) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callResult",
             kind: {:scalar, :CONNECTED},
             label: :optional,
             name: :callResult,
             tag: 1,
             type: {:enum, WAWebProtobufSyncAction.CallLogRecord.CallResult}
           }}
        end

        def field_def("callResult") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callResult",
             kind: {:scalar, :CONNECTED},
             label: :optional,
             name: :callResult,
             tag: 1,
             type: {:enum, WAWebProtobufSyncAction.CallLogRecord.CallResult}
           }}
        end

        []
      ),
      (
        def field_def(:isDndMode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isDndMode",
             kind: {:scalar, false},
             label: :optional,
             name: :isDndMode,
             tag: 2,
             type: :bool
           }}
        end

        def field_def("isDndMode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isDndMode",
             kind: {:scalar, false},
             label: :optional,
             name: :isDndMode,
             tag: 2,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:silenceReason) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "silenceReason",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :silenceReason,
             tag: 3,
             type: {:enum, WAWebProtobufSyncAction.CallLogRecord.SilenceReason}
           }}
        end

        def field_def("silenceReason") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "silenceReason",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :silenceReason,
             tag: 3,
             type: {:enum, WAWebProtobufSyncAction.CallLogRecord.SilenceReason}
           }}
        end

        []
      ),
      (
        def field_def(:duration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "duration",
             kind: {:scalar, 0},
             label: :optional,
             name: :duration,
             tag: 4,
             type: :int64
           }}
        end

        def field_def("duration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "duration",
             kind: {:scalar, 0},
             label: :optional,
             name: :duration,
             tag: 4,
             type: :int64
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
             tag: 5,
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
             tag: 5,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:isIncoming) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isIncoming",
             kind: {:scalar, false},
             label: :optional,
             name: :isIncoming,
             tag: 6,
             type: :bool
           }}
        end

        def field_def("isIncoming") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isIncoming",
             kind: {:scalar, false},
             label: :optional,
             name: :isIncoming,
             tag: 6,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isVideo) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isVideo",
             kind: {:scalar, false},
             label: :optional,
             name: :isVideo,
             tag: 7,
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
             tag: 7,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isCallLink) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isCallLink",
             kind: {:scalar, false},
             label: :optional,
             name: :isCallLink,
             tag: 8,
             type: :bool
           }}
        end

        def field_def("isCallLink") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isCallLink",
             kind: {:scalar, false},
             label: :optional,
             name: :isCallLink,
             tag: 8,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:callLinkToken) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callLinkToken",
             kind: {:scalar, ""},
             label: :optional,
             name: :callLinkToken,
             tag: 9,
             type: :string
           }}
        end

        def field_def("callLinkToken") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callLinkToken",
             kind: {:scalar, ""},
             label: :optional,
             name: :callLinkToken,
             tag: 9,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:scheduledCallID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "scheduledCallID",
             kind: {:scalar, ""},
             label: :optional,
             name: :scheduledCallID,
             tag: 10,
             type: :string
           }}
        end

        def field_def("scheduledCallID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "scheduledCallID",
             kind: {:scalar, ""},
             label: :optional,
             name: :scheduledCallID,
             tag: 10,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:callID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callID",
             kind: {:scalar, ""},
             label: :optional,
             name: :callID,
             tag: 11,
             type: :string
           }}
        end

        def field_def("callID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callID",
             kind: {:scalar, ""},
             label: :optional,
             name: :callID,
             tag: 11,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:callCreatorJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callCreatorJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :callCreatorJID,
             tag: 12,
             type: :string
           }}
        end

        def field_def("callCreatorJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callCreatorJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :callCreatorJID,
             tag: 12,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:groupJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :groupJID,
             tag: 13,
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
             tag: 13,
             type: :string
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
             tag: 14,
             type: {:message, WAWebProtobufSyncAction.CallLogRecord.ParticipantInfo}
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
             tag: 14,
             type: {:message, WAWebProtobufSyncAction.CallLogRecord.ParticipantInfo}
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
             tag: 15,
             type: {:enum, WAWebProtobufSyncAction.CallLogRecord.CallType}
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
             tag: 15,
             type: {:enum, WAWebProtobufSyncAction.CallLogRecord.CallType}
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
    def default(:callResult) do
      {:ok, :CONNECTED}
    end,
    def default(:isDndMode) do
      {:ok, false}
    end,
    def default(:silenceReason) do
      {:ok, :NONE}
    end,
    def default(:duration) do
      {:ok, 0}
    end,
    def default(:startTime) do
      {:ok, 0}
    end,
    def default(:isIncoming) do
      {:ok, false}
    end,
    def default(:isVideo) do
      {:ok, false}
    end,
    def default(:isCallLink) do
      {:ok, false}
    end,
    def default(:callLinkToken) do
      {:ok, ""}
    end,
    def default(:scheduledCallID) do
      {:ok, ""}
    end,
    def default(:callID) do
      {:ok, ""}
    end,
    def default(:callCreatorJID) do
      {:ok, ""}
    end,
    def default(:groupJID) do
      {:ok, ""}
    end,
    def default(:participants) do
      {:error, :no_default_value}
    end,
    def default(:callType) do
      {:ok, :REGULAR}
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
