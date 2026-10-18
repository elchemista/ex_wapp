# credo:disable-for-this-file
defmodule WAWebProtobufSyncAction.BusinessBroadcastCampaignAction do
  @moduledoc false
  defstruct deviceID: nil,
            adID: nil,
            name: nil,
            msgID: nil,
            broadcastJID: nil,
            reservedQuota: nil,
            scheduledTimestamp: nil,
            createTimestamp: nil,
            status: nil,
            bbProStatus: nil,
            customAudienceFbid: nil,
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
        |> encode_deviceID(msg)
        |> encode_adID(msg)
        |> encode_name(msg)
        |> encode_msgID(msg)
        |> encode_broadcastJID(msg)
        |> encode_reservedQuota(msg)
        |> encode_scheduledTimestamp(msg)
        |> encode_createTimestamp(msg)
        |> encode_status(msg)
        |> encode_bbProStatus(msg)
        |> encode_customAudienceFbid(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_deviceID(acc, msg) do
        try do
          case msg.deviceID do
            nil -> acc
            _ -> [acc, "\b", Protox.Encode.encode_int32(msg.deviceID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deviceID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_adID(acc, msg) do
        try do
          case msg.adID do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.adID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:adID, "invalid field value"), __STACKTRACE__
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
      defp encode_msgID(acc, msg) do
        try do
          case msg.msgID do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.msgID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:msgID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_broadcastJID(acc, msg) do
        try do
          case msg.broadcastJID do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.broadcastJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:broadcastJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_reservedQuota(acc, msg) do
        try do
          case msg.reservedQuota do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_int32(msg.reservedQuota)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:reservedQuota, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_scheduledTimestamp(acc, msg) do
        try do
          case msg.scheduledTimestamp do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_int64(msg.scheduledTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:scheduledTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_createTimestamp(acc, msg) do
        try do
          case msg.createTimestamp do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_int64(msg.createTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:createTimestamp, "invalid field value"),
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
                "H",
                msg.status
                |> WAWebProtobufSyncAction.BusinessBroadcastCampaignStatus.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:status, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_bbProStatus(acc, msg) do
        try do
          case msg.bbProStatus do
            nil ->
              acc

            _ ->
              [
                acc,
                "P",
                msg.bbProStatus
                |> WAWebProtobufSyncAction.BusinessBroadcastCampaignBBProStatus.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:bbProStatus, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_customAudienceFbid(acc, msg) do
        try do
          case msg.customAudienceFbid do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_string(msg.customAudienceFbid)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:customAudienceFbid, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufSyncAction.BusinessBroadcastCampaignAction))
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
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[deviceID: value], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[adID: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[name: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[msgID: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[broadcastJID: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[reservedQuota: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[scheduledTimestamp: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[createTimestamp: value], rest}

            {9, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufSyncAction.BusinessBroadcastCampaignStatus
                )

              {[status: value], rest}

            {10, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufSyncAction.BusinessBroadcastCampaignBBProStatus
                )

              {[bbProStatus: value], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[customAudienceFbid: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufSyncAction.BusinessBroadcastCampaignAction,
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
        1 => {:deviceID, {:scalar, 0}, :int32},
        2 => {:adID, {:scalar, ""}, :string},
        3 => {:name, {:scalar, ""}, :string},
        4 => {:msgID, {:scalar, ""}, :string},
        5 => {:broadcastJID, {:scalar, ""}, :string},
        6 => {:reservedQuota, {:scalar, 0}, :int32},
        7 => {:scheduledTimestamp, {:scalar, 0}, :int64},
        8 => {:createTimestamp, {:scalar, 0}, :int64},
        9 =>
          {:status, {:scalar, :DRAFT},
           {:enum, WAWebProtobufSyncAction.BusinessBroadcastCampaignStatus}},
        10 =>
          {:bbProStatus, {:scalar, :BB_PRO_ACTIVE},
           {:enum, WAWebProtobufSyncAction.BusinessBroadcastCampaignBBProStatus}},
        11 => {:customAudienceFbid, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        adID: {2, {:scalar, ""}, :string},
        bbProStatus:
          {10, {:scalar, :BB_PRO_ACTIVE},
           {:enum, WAWebProtobufSyncAction.BusinessBroadcastCampaignBBProStatus}},
        broadcastJID: {5, {:scalar, ""}, :string},
        createTimestamp: {8, {:scalar, 0}, :int64},
        customAudienceFbid: {11, {:scalar, ""}, :string},
        deviceID: {1, {:scalar, 0}, :int32},
        msgID: {4, {:scalar, ""}, :string},
        name: {3, {:scalar, ""}, :string},
        reservedQuota: {6, {:scalar, 0}, :int32},
        scheduledTimestamp: {7, {:scalar, 0}, :int64},
        status:
          {9, {:scalar, :DRAFT}, {:enum, WAWebProtobufSyncAction.BusinessBroadcastCampaignStatus}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "deviceID",
          kind: {:scalar, 0},
          label: :optional,
          name: :deviceID,
          tag: 1,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "adID",
          kind: {:scalar, ""},
          label: :optional,
          name: :adID,
          tag: 2,
          type: :string
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
          json_name: "msgID",
          kind: {:scalar, ""},
          label: :optional,
          name: :msgID,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "broadcastJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :broadcastJID,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "reservedQuota",
          kind: {:scalar, 0},
          label: :optional,
          name: :reservedQuota,
          tag: 6,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "scheduledTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :scheduledTimestamp,
          tag: 7,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "createTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :createTimestamp,
          tag: 8,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "status",
          kind: {:scalar, :DRAFT},
          label: :optional,
          name: :status,
          tag: 9,
          type: {:enum, WAWebProtobufSyncAction.BusinessBroadcastCampaignStatus}
        },
        %{
          __struct__: Protox.Field,
          json_name: "bbProStatus",
          kind: {:scalar, :BB_PRO_ACTIVE},
          label: :optional,
          name: :bbProStatus,
          tag: 10,
          type: {:enum, WAWebProtobufSyncAction.BusinessBroadcastCampaignBBProStatus}
        },
        %{
          __struct__: Protox.Field,
          json_name: "customAudienceFbid",
          kind: {:scalar, ""},
          label: :optional,
          name: :customAudienceFbid,
          tag: 11,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:deviceID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceID",
             kind: {:scalar, 0},
             label: :optional,
             name: :deviceID,
             tag: 1,
             type: :int32
           }}
        end

        def field_def("deviceID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceID",
             kind: {:scalar, 0},
             label: :optional,
             name: :deviceID,
             tag: 1,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:adID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "adID",
             kind: {:scalar, ""},
             label: :optional,
             name: :adID,
             tag: 2,
             type: :string
           }}
        end

        def field_def("adID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "adID",
             kind: {:scalar, ""},
             label: :optional,
             name: :adID,
             tag: 2,
             type: :string
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
        def field_def(:msgID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "msgID",
             kind: {:scalar, ""},
             label: :optional,
             name: :msgID,
             tag: 4,
             type: :string
           }}
        end

        def field_def("msgID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "msgID",
             kind: {:scalar, ""},
             label: :optional,
             name: :msgID,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:broadcastJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "broadcastJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :broadcastJID,
             tag: 5,
             type: :string
           }}
        end

        def field_def("broadcastJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "broadcastJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :broadcastJID,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:reservedQuota) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reservedQuota",
             kind: {:scalar, 0},
             label: :optional,
             name: :reservedQuota,
             tag: 6,
             type: :int32
           }}
        end

        def field_def("reservedQuota") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reservedQuota",
             kind: {:scalar, 0},
             label: :optional,
             name: :reservedQuota,
             tag: 6,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:scheduledTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "scheduledTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :scheduledTimestamp,
             tag: 7,
             type: :int64
           }}
        end

        def field_def("scheduledTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "scheduledTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :scheduledTimestamp,
             tag: 7,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:createTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "createTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :createTimestamp,
             tag: 8,
             type: :int64
           }}
        end

        def field_def("createTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "createTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :createTimestamp,
             tag: 8,
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
             kind: {:scalar, :DRAFT},
             label: :optional,
             name: :status,
             tag: 9,
             type: {:enum, WAWebProtobufSyncAction.BusinessBroadcastCampaignStatus}
           }}
        end

        def field_def("status") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "status",
             kind: {:scalar, :DRAFT},
             label: :optional,
             name: :status,
             tag: 9,
             type: {:enum, WAWebProtobufSyncAction.BusinessBroadcastCampaignStatus}
           }}
        end

        []
      ),
      (
        def field_def(:bbProStatus) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bbProStatus",
             kind: {:scalar, :BB_PRO_ACTIVE},
             label: :optional,
             name: :bbProStatus,
             tag: 10,
             type: {:enum, WAWebProtobufSyncAction.BusinessBroadcastCampaignBBProStatus}
           }}
        end

        def field_def("bbProStatus") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bbProStatus",
             kind: {:scalar, :BB_PRO_ACTIVE},
             label: :optional,
             name: :bbProStatus,
             tag: 10,
             type: {:enum, WAWebProtobufSyncAction.BusinessBroadcastCampaignBBProStatus}
           }}
        end

        []
      ),
      (
        def field_def(:customAudienceFbid) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "customAudienceFbid",
             kind: {:scalar, ""},
             label: :optional,
             name: :customAudienceFbid,
             tag: 11,
             type: :string
           }}
        end

        def field_def("customAudienceFbid") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "customAudienceFbid",
             kind: {:scalar, ""},
             label: :optional,
             name: :customAudienceFbid,
             tag: 11,
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
    def default(:deviceID) do
      {:ok, 0}
    end,
    def default(:adID) do
      {:ok, ""}
    end,
    def default(:name) do
      {:ok, ""}
    end,
    def default(:msgID) do
      {:ok, ""}
    end,
    def default(:broadcastJID) do
      {:ok, ""}
    end,
    def default(:reservedQuota) do
      {:ok, 0}
    end,
    def default(:scheduledTimestamp) do
      {:ok, 0}
    end,
    def default(:createTimestamp) do
      {:ok, 0}
    end,
    def default(:status) do
      {:ok, :DRAFT}
    end,
    def default(:bbProStatus) do
      {:ok, :BB_PRO_ACTIVE}
    end,
    def default(:customAudienceFbid) do
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

  @type t :: %__MODULE__{}
end
