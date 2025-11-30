# credo:disable-for-this-file
defmodule WAWebProtobufsWa6.ClientPayload.UserAgent do
  @moduledoc false
  defstruct platform: nil,
            appVersion: nil,
            mcc: nil,
            mnc: nil,
            osVersion: nil,
            manufacturer: nil,
            device: nil,
            osBuildNumber: nil,
            phoneID: nil,
            releaseChannel: nil,
            localeLanguageIso6391: nil,
            localeCountryIso31661Alpha2: nil,
            deviceBoard: nil,
            deviceExpID: nil,
            deviceType: nil,
            deviceModelType: nil,
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
        |> encode_platform(msg)
        |> encode_appVersion(msg)
        |> encode_mcc(msg)
        |> encode_mnc(msg)
        |> encode_osVersion(msg)
        |> encode_manufacturer(msg)
        |> encode_device(msg)
        |> encode_osBuildNumber(msg)
        |> encode_phoneID(msg)
        |> encode_releaseChannel(msg)
        |> encode_localeLanguageIso6391(msg)
        |> encode_localeCountryIso31661Alpha2(msg)
        |> encode_deviceBoard(msg)
        |> encode_deviceExpID(msg)
        |> encode_deviceType(msg)
        |> encode_deviceModelType(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_platform(acc, msg) do
        try do
          case msg.platform do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.platform
                |> WAWebProtobufsWa6.ClientPayload.UserAgent.Platform.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:platform, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_appVersion(acc, msg) do
        try do
          case msg.appVersion do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_message(msg.appVersion)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:appVersion, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mcc(acc, msg) do
        try do
          case msg.mcc do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.mcc)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mcc, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mnc(acc, msg) do
        try do
          case msg.mnc do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.mnc)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mnc, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_osVersion(acc, msg) do
        try do
          case msg.osVersion do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.osVersion)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:osVersion, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_manufacturer(acc, msg) do
        try do
          case msg.manufacturer do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.manufacturer)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:manufacturer, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_device(acc, msg) do
        try do
          case msg.device do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.device)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:device, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_osBuildNumber(acc, msg) do
        try do
          case msg.osBuildNumber do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg.osBuildNumber)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:osBuildNumber, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_phoneID(acc, msg) do
        try do
          case msg.phoneID do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_string(msg.phoneID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:phoneID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_releaseChannel(acc, msg) do
        try do
          case msg.releaseChannel do
            nil ->
              acc

            _ ->
              [
                acc,
                "P",
                msg.releaseChannel
                |> WAWebProtobufsWa6.ClientPayload.UserAgent.ReleaseChannel.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:releaseChannel, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_localeLanguageIso6391(acc, msg) do
        try do
          case msg.localeLanguageIso6391 do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_string(msg.localeLanguageIso6391)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:localeLanguageIso6391, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_localeCountryIso31661Alpha2(acc, msg) do
        try do
          case msg.localeCountryIso31661Alpha2 do
            nil -> acc
            _ -> [acc, "b", Protox.Encode.encode_string(msg.localeCountryIso31661Alpha2)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:localeCountryIso31661Alpha2, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_deviceBoard(acc, msg) do
        try do
          case msg.deviceBoard do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_string(msg.deviceBoard)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deviceBoard, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_deviceExpID(acc, msg) do
        try do
          case msg.deviceExpID do
            nil -> acc
            _ -> [acc, "r", Protox.Encode.encode_string(msg.deviceExpID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deviceExpID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_deviceType(acc, msg) do
        try do
          case msg.deviceType do
            nil ->
              acc

            _ ->
              [
                acc,
                "x",
                msg.deviceType
                |> WAWebProtobufsWa6.ClientPayload.UserAgent.DeviceType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deviceType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_deviceModelType(acc, msg) do
        try do
          case msg.deviceModelType do
            nil -> acc
            _ -> [acc, "\x82\x01", Protox.Encode.encode_string(msg.deviceModelType)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:deviceModelType, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsWa6.ClientPayload.UserAgent))
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
                  WAWebProtobufsWa6.ClientPayload.UserAgent.Platform
                )

              {[platform: value], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 appVersion:
                   Protox.MergeMessage.merge(
                     msg.appVersion,
                     WAWebProtobufsWa6.ClientPayload.UserAgent.AppVersion.decode!(delimited)
                   )
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mcc: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mnc: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[osVersion: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[manufacturer: Protox.Decode.validate_string!(delimited)], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[device: Protox.Decode.validate_string!(delimited)], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[osBuildNumber: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[phoneID: Protox.Decode.validate_string!(delimited)], rest}

            {10, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsWa6.ClientPayload.UserAgent.ReleaseChannel
                )

              {[releaseChannel: value], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[localeLanguageIso6391: Protox.Decode.validate_string!(delimited)], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[localeCountryIso31661Alpha2: Protox.Decode.validate_string!(delimited)], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[deviceBoard: Protox.Decode.validate_string!(delimited)], rest}

            {14, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[deviceExpID: Protox.Decode.validate_string!(delimited)], rest}

            {15, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsWa6.ClientPayload.UserAgent.DeviceType
                )

              {[deviceType: value], rest}

            {16, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[deviceModelType: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufsWa6.ClientPayload.UserAgent,
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
          {:platform, {:scalar, :ANDROID},
           {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.Platform}},
        2 =>
          {:appVersion, {:scalar, nil},
           {:message, WAWebProtobufsWa6.ClientPayload.UserAgent.AppVersion}},
        3 => {:mcc, {:scalar, ""}, :string},
        4 => {:mnc, {:scalar, ""}, :string},
        5 => {:osVersion, {:scalar, ""}, :string},
        6 => {:manufacturer, {:scalar, ""}, :string},
        7 => {:device, {:scalar, ""}, :string},
        8 => {:osBuildNumber, {:scalar, ""}, :string},
        9 => {:phoneID, {:scalar, ""}, :string},
        10 =>
          {:releaseChannel, {:scalar, :RELEASE},
           {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.ReleaseChannel}},
        11 => {:localeLanguageIso6391, {:scalar, ""}, :string},
        12 => {:localeCountryIso31661Alpha2, {:scalar, ""}, :string},
        13 => {:deviceBoard, {:scalar, ""}, :string},
        14 => {:deviceExpID, {:scalar, ""}, :string},
        15 =>
          {:deviceType, {:scalar, :PHONE},
           {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.DeviceType}},
        16 => {:deviceModelType, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        appVersion:
          {2, {:scalar, nil}, {:message, WAWebProtobufsWa6.ClientPayload.UserAgent.AppVersion}},
        device: {7, {:scalar, ""}, :string},
        deviceBoard: {13, {:scalar, ""}, :string},
        deviceExpID: {14, {:scalar, ""}, :string},
        deviceModelType: {16, {:scalar, ""}, :string},
        deviceType:
          {15, {:scalar, :PHONE}, {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.DeviceType}},
        localeCountryIso31661Alpha2: {12, {:scalar, ""}, :string},
        localeLanguageIso6391: {11, {:scalar, ""}, :string},
        manufacturer: {6, {:scalar, ""}, :string},
        mcc: {3, {:scalar, ""}, :string},
        mnc: {4, {:scalar, ""}, :string},
        osBuildNumber: {8, {:scalar, ""}, :string},
        osVersion: {5, {:scalar, ""}, :string},
        phoneID: {9, {:scalar, ""}, :string},
        platform:
          {1, {:scalar, :ANDROID}, {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.Platform}},
        releaseChannel:
          {10, {:scalar, :RELEASE},
           {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.ReleaseChannel}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "platform",
          kind: {:scalar, :ANDROID},
          label: :optional,
          name: :platform,
          tag: 1,
          type: {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.Platform}
        },
        %{
          __struct__: Protox.Field,
          json_name: "appVersion",
          kind: {:scalar, nil},
          label: :optional,
          name: :appVersion,
          tag: 2,
          type: {:message, WAWebProtobufsWa6.ClientPayload.UserAgent.AppVersion}
        },
        %{
          __struct__: Protox.Field,
          json_name: "mcc",
          kind: {:scalar, ""},
          label: :optional,
          name: :mcc,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "mnc",
          kind: {:scalar, ""},
          label: :optional,
          name: :mnc,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "osVersion",
          kind: {:scalar, ""},
          label: :optional,
          name: :osVersion,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "manufacturer",
          kind: {:scalar, ""},
          label: :optional,
          name: :manufacturer,
          tag: 6,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "device",
          kind: {:scalar, ""},
          label: :optional,
          name: :device,
          tag: 7,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "osBuildNumber",
          kind: {:scalar, ""},
          label: :optional,
          name: :osBuildNumber,
          tag: 8,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "phoneID",
          kind: {:scalar, ""},
          label: :optional,
          name: :phoneID,
          tag: 9,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "releaseChannel",
          kind: {:scalar, :RELEASE},
          label: :optional,
          name: :releaseChannel,
          tag: 10,
          type: {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.ReleaseChannel}
        },
        %{
          __struct__: Protox.Field,
          json_name: "localeLanguageIso6391",
          kind: {:scalar, ""},
          label: :optional,
          name: :localeLanguageIso6391,
          tag: 11,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "localeCountryIso31661Alpha2",
          kind: {:scalar, ""},
          label: :optional,
          name: :localeCountryIso31661Alpha2,
          tag: 12,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "deviceBoard",
          kind: {:scalar, ""},
          label: :optional,
          name: :deviceBoard,
          tag: 13,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "deviceExpID",
          kind: {:scalar, ""},
          label: :optional,
          name: :deviceExpID,
          tag: 14,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "deviceType",
          kind: {:scalar, :PHONE},
          label: :optional,
          name: :deviceType,
          tag: 15,
          type: {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.DeviceType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "deviceModelType",
          kind: {:scalar, ""},
          label: :optional,
          name: :deviceModelType,
          tag: 16,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:platform) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "platform",
             kind: {:scalar, :ANDROID},
             label: :optional,
             name: :platform,
             tag: 1,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.Platform}
           }}
        end

        def field_def("platform") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "platform",
             kind: {:scalar, :ANDROID},
             label: :optional,
             name: :platform,
             tag: 1,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.Platform}
           }}
        end

        []
      ),
      (
        def field_def(:appVersion) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appVersion",
             kind: {:scalar, nil},
             label: :optional,
             name: :appVersion,
             tag: 2,
             type: {:message, WAWebProtobufsWa6.ClientPayload.UserAgent.AppVersion}
           }}
        end

        def field_def("appVersion") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appVersion",
             kind: {:scalar, nil},
             label: :optional,
             name: :appVersion,
             tag: 2,
             type: {:message, WAWebProtobufsWa6.ClientPayload.UserAgent.AppVersion}
           }}
        end

        []
      ),
      (
        def field_def(:mcc) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mcc",
             kind: {:scalar, ""},
             label: :optional,
             name: :mcc,
             tag: 3,
             type: :string
           }}
        end

        def field_def("mcc") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mcc",
             kind: {:scalar, ""},
             label: :optional,
             name: :mcc,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:mnc) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mnc",
             kind: {:scalar, ""},
             label: :optional,
             name: :mnc,
             tag: 4,
             type: :string
           }}
        end

        def field_def("mnc") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mnc",
             kind: {:scalar, ""},
             label: :optional,
             name: :mnc,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:osVersion) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "osVersion",
             kind: {:scalar, ""},
             label: :optional,
             name: :osVersion,
             tag: 5,
             type: :string
           }}
        end

        def field_def("osVersion") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "osVersion",
             kind: {:scalar, ""},
             label: :optional,
             name: :osVersion,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:manufacturer) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "manufacturer",
             kind: {:scalar, ""},
             label: :optional,
             name: :manufacturer,
             tag: 6,
             type: :string
           }}
        end

        def field_def("manufacturer") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "manufacturer",
             kind: {:scalar, ""},
             label: :optional,
             name: :manufacturer,
             tag: 6,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:device) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "device",
             kind: {:scalar, ""},
             label: :optional,
             name: :device,
             tag: 7,
             type: :string
           }}
        end

        def field_def("device") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "device",
             kind: {:scalar, ""},
             label: :optional,
             name: :device,
             tag: 7,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:osBuildNumber) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "osBuildNumber",
             kind: {:scalar, ""},
             label: :optional,
             name: :osBuildNumber,
             tag: 8,
             type: :string
           }}
        end

        def field_def("osBuildNumber") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "osBuildNumber",
             kind: {:scalar, ""},
             label: :optional,
             name: :osBuildNumber,
             tag: 8,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:phoneID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "phoneID",
             kind: {:scalar, ""},
             label: :optional,
             name: :phoneID,
             tag: 9,
             type: :string
           }}
        end

        def field_def("phoneID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "phoneID",
             kind: {:scalar, ""},
             label: :optional,
             name: :phoneID,
             tag: 9,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:releaseChannel) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "releaseChannel",
             kind: {:scalar, :RELEASE},
             label: :optional,
             name: :releaseChannel,
             tag: 10,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.ReleaseChannel}
           }}
        end

        def field_def("releaseChannel") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "releaseChannel",
             kind: {:scalar, :RELEASE},
             label: :optional,
             name: :releaseChannel,
             tag: 10,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.ReleaseChannel}
           }}
        end

        []
      ),
      (
        def field_def(:localeLanguageIso6391) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "localeLanguageIso6391",
             kind: {:scalar, ""},
             label: :optional,
             name: :localeLanguageIso6391,
             tag: 11,
             type: :string
           }}
        end

        def field_def("localeLanguageIso6391") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "localeLanguageIso6391",
             kind: {:scalar, ""},
             label: :optional,
             name: :localeLanguageIso6391,
             tag: 11,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:localeCountryIso31661Alpha2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "localeCountryIso31661Alpha2",
             kind: {:scalar, ""},
             label: :optional,
             name: :localeCountryIso31661Alpha2,
             tag: 12,
             type: :string
           }}
        end

        def field_def("localeCountryIso31661Alpha2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "localeCountryIso31661Alpha2",
             kind: {:scalar, ""},
             label: :optional,
             name: :localeCountryIso31661Alpha2,
             tag: 12,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:deviceBoard) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceBoard",
             kind: {:scalar, ""},
             label: :optional,
             name: :deviceBoard,
             tag: 13,
             type: :string
           }}
        end

        def field_def("deviceBoard") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceBoard",
             kind: {:scalar, ""},
             label: :optional,
             name: :deviceBoard,
             tag: 13,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:deviceExpID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceExpID",
             kind: {:scalar, ""},
             label: :optional,
             name: :deviceExpID,
             tag: 14,
             type: :string
           }}
        end

        def field_def("deviceExpID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceExpID",
             kind: {:scalar, ""},
             label: :optional,
             name: :deviceExpID,
             tag: 14,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:deviceType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceType",
             kind: {:scalar, :PHONE},
             label: :optional,
             name: :deviceType,
             tag: 15,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.DeviceType}
           }}
        end

        def field_def("deviceType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceType",
             kind: {:scalar, :PHONE},
             label: :optional,
             name: :deviceType,
             tag: 15,
             type: {:enum, WAWebProtobufsWa6.ClientPayload.UserAgent.DeviceType}
           }}
        end

        []
      ),
      (
        def field_def(:deviceModelType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceModelType",
             kind: {:scalar, ""},
             label: :optional,
             name: :deviceModelType,
             tag: 16,
             type: :string
           }}
        end

        def field_def("deviceModelType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "deviceModelType",
             kind: {:scalar, ""},
             label: :optional,
             name: :deviceModelType,
             tag: 16,
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
    def default(:platform) do
      {:ok, :ANDROID}
    end,
    def default(:appVersion) do
      {:ok, nil}
    end,
    def default(:mcc) do
      {:ok, ""}
    end,
    def default(:mnc) do
      {:ok, ""}
    end,
    def default(:osVersion) do
      {:ok, ""}
    end,
    def default(:manufacturer) do
      {:ok, ""}
    end,
    def default(:device) do
      {:ok, ""}
    end,
    def default(:osBuildNumber) do
      {:ok, ""}
    end,
    def default(:phoneID) do
      {:ok, ""}
    end,
    def default(:releaseChannel) do
      {:ok, :RELEASE}
    end,
    def default(:localeLanguageIso6391) do
      {:ok, ""}
    end,
    def default(:localeCountryIso31661Alpha2) do
      {:ok, ""}
    end,
    def default(:deviceBoard) do
      {:ok, ""}
    end,
    def default(:deviceExpID) do
      {:ok, ""}
    end,
    def default(:deviceType) do
      {:ok, :PHONE}
    end,
    def default(:deviceModelType) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waWa6",
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
