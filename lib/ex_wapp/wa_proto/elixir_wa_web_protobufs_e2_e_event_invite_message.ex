# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.EventInviteMessage do
  @moduledoc false
  defstruct contextInfo: nil,
            eventID: nil,
            eventTitle: nil,
            JPEGThumbnail: nil,
            startTime: nil,
            caption: nil,
            isCanceled: nil,
            endTime: nil,
            callLink: nil,
            coverImageHandle: nil,
            locationName: nil,
            lastUpdatedTSUsec: nil,
            status: nil,
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
        |> encode_eventID(msg)
        |> encode_eventTitle(msg)
        |> encode_JPEGThumbnail(msg)
        |> encode_startTime(msg)
        |> encode_caption(msg)
        |> encode_isCanceled(msg)
        |> encode_endTime(msg)
        |> encode_callLink(msg)
        |> encode_coverImageHandle(msg)
        |> encode_locationName(msg)
        |> encode_lastUpdatedTSUsec(msg)
        |> encode_status(msg)
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
      defp encode_eventID(acc, msg) do
        try do
          case msg.eventID do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.eventID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:eventID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_eventTitle(acc, msg) do
        try do
          case msg.eventTitle do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.eventTitle)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:eventTitle, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_JPEGThumbnail(acc, msg) do
        try do
          case msg."JPEGThumbnail" do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_bytes(msg."JPEGThumbnail")]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:JPEGThumbnail, "invalid field value"),
                    __STACKTRACE__
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
      defp encode_isCanceled(acc, msg) do
        try do
          case msg.isCanceled do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_bool(msg.isCanceled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isCanceled, "invalid field value"), __STACKTRACE__
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
      defp encode_callLink(acc, msg) do
        try do
          case msg.callLink do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_string(msg.callLink)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:callLink, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_coverImageHandle(acc, msg) do
        try do
          case msg.coverImageHandle do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_string(msg.coverImageHandle)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:coverImageHandle, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_locationName(acc, msg) do
        try do
          case msg.locationName do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_string(msg.locationName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:locationName, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_lastUpdatedTSUsec(acc, msg) do
        try do
          case msg.lastUpdatedTSUsec do
            nil -> acc
            _ -> [acc, "`", Protox.Encode.encode_int64(msg.lastUpdatedTSUsec)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lastUpdatedTSUsec, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_status(acc, msg) do
        try do
          case msg.status do
            nil ->
              acc

            _ ->
              [
                acc,
                "h",
                msg.status
                |> WAWebProtobufsE2E.EventInviteMessage.EventStatus.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:status, "invalid field value"), __STACKTRACE__
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.EventInviteMessage))
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
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[eventID: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[eventTitle: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[JPEGThumbnail: delimited], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[startTime: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[caption: Protox.Decode.validate_string!(delimited)], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[isCanceled: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[endTime: value], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[callLink: Protox.Decode.validate_string!(delimited)], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[coverImageHandle: Protox.Decode.validate_string!(delimited)], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[locationName: Protox.Decode.validate_string!(delimited)], rest}

            {12, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[lastUpdatedTSUsec: value], rest}

            {13, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.EventInviteMessage.EventStatus)

              {[status: value], rest}

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
        WAWebProtobufsE2E.EventInviteMessage,
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
        2 => {:eventID, {:scalar, ""}, :string},
        3 => {:eventTitle, {:scalar, ""}, :string},
        4 => {:JPEGThumbnail, {:scalar, ""}, :bytes},
        5 => {:startTime, {:scalar, 0}, :int64},
        6 => {:caption, {:scalar, ""}, :string},
        7 => {:isCanceled, {:scalar, false}, :bool},
        8 => {:endTime, {:scalar, 0}, :int64},
        9 => {:callLink, {:scalar, ""}, :string},
        10 => {:coverImageHandle, {:scalar, ""}, :string},
        11 => {:locationName, {:scalar, ""}, :string},
        12 => {:lastUpdatedTSUsec, {:scalar, 0}, :int64},
        13 =>
          {:status, {:scalar, :UNKNOWN},
           {:enum, WAWebProtobufsE2E.EventInviteMessage.EventStatus}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        JPEGThumbnail: {4, {:scalar, ""}, :bytes},
        callLink: {9, {:scalar, ""}, :string},
        caption: {6, {:scalar, ""}, :string},
        contextInfo: {1, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        coverImageHandle: {10, {:scalar, ""}, :string},
        endTime: {8, {:scalar, 0}, :int64},
        eventID: {2, {:scalar, ""}, :string},
        eventTitle: {3, {:scalar, ""}, :string},
        isCanceled: {7, {:scalar, false}, :bool},
        lastUpdatedTSUsec: {12, {:scalar, 0}, :int64},
        locationName: {11, {:scalar, ""}, :string},
        startTime: {5, {:scalar, 0}, :int64},
        status:
          {13, {:scalar, :UNKNOWN}, {:enum, WAWebProtobufsE2E.EventInviteMessage.EventStatus}}
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
          json_name: "eventID",
          kind: {:scalar, ""},
          label: :optional,
          name: :eventID,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "eventTitle",
          kind: {:scalar, ""},
          label: :optional,
          name: :eventTitle,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "JPEGThumbnail",
          kind: {:scalar, ""},
          label: :optional,
          name: :JPEGThumbnail,
          tag: 4,
          type: :bytes
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
          json_name: "caption",
          kind: {:scalar, ""},
          label: :optional,
          name: :caption,
          tag: 6,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "isCanceled",
          kind: {:scalar, false},
          label: :optional,
          name: :isCanceled,
          tag: 7,
          type: :bool
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
          json_name: "callLink",
          kind: {:scalar, ""},
          label: :optional,
          name: :callLink,
          tag: 9,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "coverImageHandle",
          kind: {:scalar, ""},
          label: :optional,
          name: :coverImageHandle,
          tag: 10,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "locationName",
          kind: {:scalar, ""},
          label: :optional,
          name: :locationName,
          tag: 11,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "lastUpdatedTSUsec",
          kind: {:scalar, 0},
          label: :optional,
          name: :lastUpdatedTSUsec,
          tag: 12,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "status",
          kind: {:scalar, :UNKNOWN},
          label: :optional,
          name: :status,
          tag: 13,
          type: {:enum, WAWebProtobufsE2E.EventInviteMessage.EventStatus}
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
        def field_def(:eventID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventID",
             kind: {:scalar, ""},
             label: :optional,
             name: :eventID,
             tag: 2,
             type: :string
           }}
        end

        def field_def("eventID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventID",
             kind: {:scalar, ""},
             label: :optional,
             name: :eventID,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:eventTitle) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventTitle",
             kind: {:scalar, ""},
             label: :optional,
             name: :eventTitle,
             tag: 3,
             type: :string
           }}
        end

        def field_def("eventTitle") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "eventTitle",
             kind: {:scalar, ""},
             label: :optional,
             name: :eventTitle,
             tag: 3,
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
             tag: 4,
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
             tag: 4,
             type: :bytes
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
        def field_def(:isCanceled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isCanceled",
             kind: {:scalar, false},
             label: :optional,
             name: :isCanceled,
             tag: 7,
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
             tag: 7,
             type: :bool
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
        def field_def(:callLink) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callLink",
             kind: {:scalar, ""},
             label: :optional,
             name: :callLink,
             tag: 9,
             type: :string
           }}
        end

        def field_def("callLink") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "callLink",
             kind: {:scalar, ""},
             label: :optional,
             name: :callLink,
             tag: 9,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:coverImageHandle) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "coverImageHandle",
             kind: {:scalar, ""},
             label: :optional,
             name: :coverImageHandle,
             tag: 10,
             type: :string
           }}
        end

        def field_def("coverImageHandle") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "coverImageHandle",
             kind: {:scalar, ""},
             label: :optional,
             name: :coverImageHandle,
             tag: 10,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:locationName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "locationName",
             kind: {:scalar, ""},
             label: :optional,
             name: :locationName,
             tag: 11,
             type: :string
           }}
        end

        def field_def("locationName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "locationName",
             kind: {:scalar, ""},
             label: :optional,
             name: :locationName,
             tag: 11,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:lastUpdatedTSUsec) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lastUpdatedTSUsec",
             kind: {:scalar, 0},
             label: :optional,
             name: :lastUpdatedTSUsec,
             tag: 12,
             type: :int64
           }}
        end

        def field_def("lastUpdatedTSUsec") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lastUpdatedTSUsec",
             kind: {:scalar, 0},
             label: :optional,
             name: :lastUpdatedTSUsec,
             tag: 12,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:status) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "status",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :status,
             tag: 13,
             type: {:enum, WAWebProtobufsE2E.EventInviteMessage.EventStatus}
           }}
        end

        def field_def("status") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "status",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :status,
             tag: 13,
             type: {:enum, WAWebProtobufsE2E.EventInviteMessage.EventStatus}
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
    def default(:eventID) do
      {:ok, ""}
    end,
    def default(:eventTitle) do
      {:ok, ""}
    end,
    def default(:JPEGThumbnail) do
      {:ok, ""}
    end,
    def default(:startTime) do
      {:ok, 0}
    end,
    def default(:caption) do
      {:ok, ""}
    end,
    def default(:isCanceled) do
      {:ok, false}
    end,
    def default(:endTime) do
      {:ok, 0}
    end,
    def default(:callLink) do
      {:ok, ""}
    end,
    def default(:coverImageHandle) do
      {:ok, ""}
    end,
    def default(:locationName) do
      {:ok, ""}
    end,
    def default(:lastUpdatedTSUsec) do
      {:ok, 0}
    end,
    def default(:status) do
      {:ok, :UNKNOWN}
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
