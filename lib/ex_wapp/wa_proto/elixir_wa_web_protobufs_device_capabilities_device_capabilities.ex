# credo:disable-for-this-file
defmodule WAWebProtobufsDeviceCapabilities.DeviceCapabilities do
  @moduledoc false
  defstruct chatLockSupportLevel: nil,
            lidMigration: nil,
            businessBroadcast: nil,
            userHasAvatar: nil,
            memberNameTagPrimarySupport: nil,
            aiThread: nil,
            aiFbidMigration: nil,
            bizAiSettingsSync: nil,
            contactRefresh: nil,
            reverseHistorySync: nil,
            newsletterChatsMigration: nil,
            hostWriteMutationSupport: nil,
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
        |> encode_chatLockSupportLevel(msg)
        |> encode_lidMigration(msg)
        |> encode_businessBroadcast(msg)
        |> encode_userHasAvatar(msg)
        |> encode_memberNameTagPrimarySupport(msg)
        |> encode_aiThread(msg)
        |> encode_aiFbidMigration(msg)
        |> encode_bizAiSettingsSync(msg)
        |> encode_contactRefresh(msg)
        |> encode_reverseHistorySync(msg)
        |> encode_newsletterChatsMigration(msg)
        |> encode_hostWriteMutationSupport(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_chatLockSupportLevel(acc, msg) do
        try do
          case msg.chatLockSupportLevel do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.chatLockSupportLevel
                |> WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ChatLockSupportLevel.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:chatLockSupportLevel, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_lidMigration(acc, msg) do
        try do
          case msg.lidMigration do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_message(msg.lidMigration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lidMigration, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_businessBroadcast(acc, msg) do
        try do
          case msg.businessBroadcast do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_message(msg.businessBroadcast)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:businessBroadcast, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_userHasAvatar(acc, msg) do
        try do
          case msg.userHasAvatar do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_message(msg.userHasAvatar)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:userHasAvatar, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_memberNameTagPrimarySupport(acc, msg) do
        try do
          case msg.memberNameTagPrimarySupport do
            nil ->
              acc

            _ ->
              [
                acc,
                "(",
                msg.memberNameTagPrimarySupport
                |> WAWebProtobufsDeviceCapabilities.DeviceCapabilities.MemberNameTagPrimarySupport.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:memberNameTagPrimarySupport, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_aiThread(acc, msg) do
        try do
          case msg.aiThread do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_message(msg.aiThread)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:aiThread, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_aiFbidMigration(acc, msg) do
        try do
          case msg.aiFbidMigration do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_message(msg.aiFbidMigration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:aiFbidMigration, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_bizAiSettingsSync(acc, msg) do
        try do
          case msg.bizAiSettingsSync do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.bizAiSettingsSync)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:bizAiSettingsSync, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_contactRefresh(acc, msg) do
        try do
          case msg.contactRefresh do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_message(msg.contactRefresh)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contactRefresh, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_reverseHistorySync(acc, msg) do
        try do
          case msg.reverseHistorySync do
            nil -> acc
            _ -> [acc, "R", Protox.Encode.encode_message(msg.reverseHistorySync)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:reverseHistorySync, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_newsletterChatsMigration(acc, msg) do
        try do
          case msg.newsletterChatsMigration do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_message(msg.newsletterChatsMigration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:newsletterChatsMigration, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_hostWriteMutationSupport(acc, msg) do
        try do
          case msg.hostWriteMutationSupport do
            nil -> acc
            _ -> [acc, "b", Protox.Encode.encode_message(msg.hostWriteMutationSupport)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:hostWriteMutationSupport, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsDeviceCapabilities.DeviceCapabilities))
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
                  WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ChatLockSupportLevel
                )

              {[chatLockSupportLevel: value], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 lidMigration:
                   Protox.MergeMessage.merge(
                     msg.lidMigration,
                     WAWebProtobufsDeviceCapabilities.DeviceCapabilities.LIDMigration.decode!(
                       delimited
                     )
                   )
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 businessBroadcast:
                   Protox.MergeMessage.merge(
                     msg.businessBroadcast,
                     WAWebProtobufsDeviceCapabilities.DeviceCapabilities.BusinessBroadcast.decode!(
                       delimited
                     )
                   )
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 userHasAvatar:
                   Protox.MergeMessage.merge(
                     msg.userHasAvatar,
                     WAWebProtobufsDeviceCapabilities.DeviceCapabilities.UserHasAvatar.decode!(
                       delimited
                     )
                   )
               ], rest}

            {5, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsDeviceCapabilities.DeviceCapabilities.MemberNameTagPrimarySupport
                )

              {[memberNameTagPrimarySupport: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 aiThread:
                   Protox.MergeMessage.merge(
                     msg.aiThread,
                     WAWebProtobufsDeviceCapabilities.DeviceCapabilities.AiThread.decode!(
                       delimited
                     )
                   )
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 aiFbidMigration:
                   Protox.MergeMessage.merge(
                     msg.aiFbidMigration,
                     WAWebProtobufsDeviceCapabilities.DeviceCapabilities.AiFbidMigration.decode!(
                       delimited
                     )
                   )
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 bizAiSettingsSync:
                   Protox.MergeMessage.merge(
                     msg.bizAiSettingsSync,
                     WAWebProtobufsDeviceCapabilities.DeviceCapabilities.BizAiSettingsSync.decode!(
                       delimited
                     )
                   )
               ], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 contactRefresh:
                   Protox.MergeMessage.merge(
                     msg.contactRefresh,
                     WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ContactRefresh.decode!(
                       delimited
                     )
                   )
               ], rest}

            {10, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 reverseHistorySync:
                   Protox.MergeMessage.merge(
                     msg.reverseHistorySync,
                     WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ReverseHistorySync.decode!(
                       delimited
                     )
                   )
               ], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 newsletterChatsMigration:
                   Protox.MergeMessage.merge(
                     msg.newsletterChatsMigration,
                     WAWebProtobufsDeviceCapabilities.DeviceCapabilities.NewsletterChatsMigration.decode!(
                       delimited
                     )
                   )
               ], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 hostWriteMutationSupport:
                   Protox.MergeMessage.merge(
                     msg.hostWriteMutationSupport,
                     WAWebProtobufsDeviceCapabilities.DeviceCapabilities.HostWriteMutationSupport.decode!(
                       delimited
                     )
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
        WAWebProtobufsDeviceCapabilities.DeviceCapabilities,
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
          {:chatLockSupportLevel, {:scalar, :NONE},
           {:enum, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ChatLockSupportLevel}},
        2 =>
          {:lidMigration, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.LIDMigration}},
        3 =>
          {:businessBroadcast, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.BusinessBroadcast}},
        4 =>
          {:userHasAvatar, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.UserHasAvatar}},
        5 =>
          {:memberNameTagPrimarySupport, {:scalar, :DISABLED},
           {:enum,
            WAWebProtobufsDeviceCapabilities.DeviceCapabilities.MemberNameTagPrimarySupport}},
        6 =>
          {:aiThread, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.AiThread}},
        7 =>
          {:aiFbidMigration, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.AiFbidMigration}},
        8 =>
          {:bizAiSettingsSync, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.BizAiSettingsSync}},
        9 =>
          {:contactRefresh, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ContactRefresh}},
        10 =>
          {:reverseHistorySync, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ReverseHistorySync}},
        11 =>
          {:newsletterChatsMigration, {:scalar, nil},
           {:message,
            WAWebProtobufsDeviceCapabilities.DeviceCapabilities.NewsletterChatsMigration}},
        12 =>
          {:hostWriteMutationSupport, {:scalar, nil},
           {:message,
            WAWebProtobufsDeviceCapabilities.DeviceCapabilities.HostWriteMutationSupport}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        aiFbidMigration:
          {7, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.AiFbidMigration}},
        aiThread:
          {6, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.AiThread}},
        bizAiSettingsSync:
          {8, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.BizAiSettingsSync}},
        businessBroadcast:
          {3, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.BusinessBroadcast}},
        chatLockSupportLevel:
          {1, {:scalar, :NONE},
           {:enum, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ChatLockSupportLevel}},
        contactRefresh:
          {9, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ContactRefresh}},
        hostWriteMutationSupport:
          {12, {:scalar, nil},
           {:message,
            WAWebProtobufsDeviceCapabilities.DeviceCapabilities.HostWriteMutationSupport}},
        lidMigration:
          {2, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.LIDMigration}},
        memberNameTagPrimarySupport:
          {5, {:scalar, :DISABLED},
           {:enum,
            WAWebProtobufsDeviceCapabilities.DeviceCapabilities.MemberNameTagPrimarySupport}},
        newsletterChatsMigration:
          {11, {:scalar, nil},
           {:message,
            WAWebProtobufsDeviceCapabilities.DeviceCapabilities.NewsletterChatsMigration}},
        reverseHistorySync:
          {10, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ReverseHistorySync}},
        userHasAvatar:
          {4, {:scalar, nil},
           {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.UserHasAvatar}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "chatLockSupportLevel",
          kind: {:scalar, :NONE},
          label: :optional,
          name: :chatLockSupportLevel,
          tag: 1,
          type: {:enum, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ChatLockSupportLevel}
        },
        %{
          __struct__: Protox.Field,
          json_name: "lidMigration",
          kind: {:scalar, nil},
          label: :optional,
          name: :lidMigration,
          tag: 2,
          type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.LIDMigration}
        },
        %{
          __struct__: Protox.Field,
          json_name: "businessBroadcast",
          kind: {:scalar, nil},
          label: :optional,
          name: :businessBroadcast,
          tag: 3,
          type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.BusinessBroadcast}
        },
        %{
          __struct__: Protox.Field,
          json_name: "userHasAvatar",
          kind: {:scalar, nil},
          label: :optional,
          name: :userHasAvatar,
          tag: 4,
          type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.UserHasAvatar}
        },
        %{
          __struct__: Protox.Field,
          json_name: "memberNameTagPrimarySupport",
          kind: {:scalar, :DISABLED},
          label: :optional,
          name: :memberNameTagPrimarySupport,
          tag: 5,
          type:
            {:enum,
             WAWebProtobufsDeviceCapabilities.DeviceCapabilities.MemberNameTagPrimarySupport}
        },
        %{
          __struct__: Protox.Field,
          json_name: "aiThread",
          kind: {:scalar, nil},
          label: :optional,
          name: :aiThread,
          tag: 6,
          type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.AiThread}
        },
        %{
          __struct__: Protox.Field,
          json_name: "aiFbidMigration",
          kind: {:scalar, nil},
          label: :optional,
          name: :aiFbidMigration,
          tag: 7,
          type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.AiFbidMigration}
        },
        %{
          __struct__: Protox.Field,
          json_name: "bizAiSettingsSync",
          kind: {:scalar, nil},
          label: :optional,
          name: :bizAiSettingsSync,
          tag: 8,
          type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.BizAiSettingsSync}
        },
        %{
          __struct__: Protox.Field,
          json_name: "contactRefresh",
          kind: {:scalar, nil},
          label: :optional,
          name: :contactRefresh,
          tag: 9,
          type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ContactRefresh}
        },
        %{
          __struct__: Protox.Field,
          json_name: "reverseHistorySync",
          kind: {:scalar, nil},
          label: :optional,
          name: :reverseHistorySync,
          tag: 10,
          type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ReverseHistorySync}
        },
        %{
          __struct__: Protox.Field,
          json_name: "newsletterChatsMigration",
          kind: {:scalar, nil},
          label: :optional,
          name: :newsletterChatsMigration,
          tag: 11,
          type:
            {:message,
             WAWebProtobufsDeviceCapabilities.DeviceCapabilities.NewsletterChatsMigration}
        },
        %{
          __struct__: Protox.Field,
          json_name: "hostWriteMutationSupport",
          kind: {:scalar, nil},
          label: :optional,
          name: :hostWriteMutationSupport,
          tag: 12,
          type:
            {:message,
             WAWebProtobufsDeviceCapabilities.DeviceCapabilities.HostWriteMutationSupport}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:chatLockSupportLevel) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatLockSupportLevel",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :chatLockSupportLevel,
             tag: 1,
             type:
               {:enum, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ChatLockSupportLevel}
           }}
        end

        def field_def("chatLockSupportLevel") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "chatLockSupportLevel",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :chatLockSupportLevel,
             tag: 1,
             type:
               {:enum, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ChatLockSupportLevel}
           }}
        end

        []
      ),
      (
        def field_def(:lidMigration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lidMigration",
             kind: {:scalar, nil},
             label: :optional,
             name: :lidMigration,
             tag: 2,
             type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.LIDMigration}
           }}
        end

        def field_def("lidMigration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lidMigration",
             kind: {:scalar, nil},
             label: :optional,
             name: :lidMigration,
             tag: 2,
             type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.LIDMigration}
           }}
        end

        []
      ),
      (
        def field_def(:businessBroadcast) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "businessBroadcast",
             kind: {:scalar, nil},
             label: :optional,
             name: :businessBroadcast,
             tag: 3,
             type:
               {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.BusinessBroadcast}
           }}
        end

        def field_def("businessBroadcast") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "businessBroadcast",
             kind: {:scalar, nil},
             label: :optional,
             name: :businessBroadcast,
             tag: 3,
             type:
               {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.BusinessBroadcast}
           }}
        end

        []
      ),
      (
        def field_def(:userHasAvatar) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "userHasAvatar",
             kind: {:scalar, nil},
             label: :optional,
             name: :userHasAvatar,
             tag: 4,
             type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.UserHasAvatar}
           }}
        end

        def field_def("userHasAvatar") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "userHasAvatar",
             kind: {:scalar, nil},
             label: :optional,
             name: :userHasAvatar,
             tag: 4,
             type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.UserHasAvatar}
           }}
        end

        []
      ),
      (
        def field_def(:memberNameTagPrimarySupport) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "memberNameTagPrimarySupport",
             kind: {:scalar, :DISABLED},
             label: :optional,
             name: :memberNameTagPrimarySupport,
             tag: 5,
             type:
               {:enum,
                WAWebProtobufsDeviceCapabilities.DeviceCapabilities.MemberNameTagPrimarySupport}
           }}
        end

        def field_def("memberNameTagPrimarySupport") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "memberNameTagPrimarySupport",
             kind: {:scalar, :DISABLED},
             label: :optional,
             name: :memberNameTagPrimarySupport,
             tag: 5,
             type:
               {:enum,
                WAWebProtobufsDeviceCapabilities.DeviceCapabilities.MemberNameTagPrimarySupport}
           }}
        end

        []
      ),
      (
        def field_def(:aiThread) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiThread",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiThread,
             tag: 6,
             type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.AiThread}
           }}
        end

        def field_def("aiThread") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiThread",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiThread,
             tag: 6,
             type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.AiThread}
           }}
        end

        []
      ),
      (
        def field_def(:aiFbidMigration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiFbidMigration",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiFbidMigration,
             tag: 7,
             type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.AiFbidMigration}
           }}
        end

        def field_def("aiFbidMigration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiFbidMigration",
             kind: {:scalar, nil},
             label: :optional,
             name: :aiFbidMigration,
             tag: 7,
             type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.AiFbidMigration}
           }}
        end

        []
      ),
      (
        def field_def(:bizAiSettingsSync) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bizAiSettingsSync",
             kind: {:scalar, nil},
             label: :optional,
             name: :bizAiSettingsSync,
             tag: 8,
             type:
               {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.BizAiSettingsSync}
           }}
        end

        def field_def("bizAiSettingsSync") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "bizAiSettingsSync",
             kind: {:scalar, nil},
             label: :optional,
             name: :bizAiSettingsSync,
             tag: 8,
             type:
               {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.BizAiSettingsSync}
           }}
        end

        []
      ),
      (
        def field_def(:contactRefresh) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contactRefresh",
             kind: {:scalar, nil},
             label: :optional,
             name: :contactRefresh,
             tag: 9,
             type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ContactRefresh}
           }}
        end

        def field_def("contactRefresh") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contactRefresh",
             kind: {:scalar, nil},
             label: :optional,
             name: :contactRefresh,
             tag: 9,
             type: {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ContactRefresh}
           }}
        end

        []
      ),
      (
        def field_def(:reverseHistorySync) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reverseHistorySync",
             kind: {:scalar, nil},
             label: :optional,
             name: :reverseHistorySync,
             tag: 10,
             type:
               {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ReverseHistorySync}
           }}
        end

        def field_def("reverseHistorySync") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "reverseHistorySync",
             kind: {:scalar, nil},
             label: :optional,
             name: :reverseHistorySync,
             tag: 10,
             type:
               {:message, WAWebProtobufsDeviceCapabilities.DeviceCapabilities.ReverseHistorySync}
           }}
        end

        []
      ),
      (
        def field_def(:newsletterChatsMigration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterChatsMigration",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterChatsMigration,
             tag: 11,
             type:
               {:message,
                WAWebProtobufsDeviceCapabilities.DeviceCapabilities.NewsletterChatsMigration}
           }}
        end

        def field_def("newsletterChatsMigration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newsletterChatsMigration",
             kind: {:scalar, nil},
             label: :optional,
             name: :newsletterChatsMigration,
             tag: 11,
             type:
               {:message,
                WAWebProtobufsDeviceCapabilities.DeviceCapabilities.NewsletterChatsMigration}
           }}
        end

        []
      ),
      (
        def field_def(:hostWriteMutationSupport) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hostWriteMutationSupport",
             kind: {:scalar, nil},
             label: :optional,
             name: :hostWriteMutationSupport,
             tag: 12,
             type:
               {:message,
                WAWebProtobufsDeviceCapabilities.DeviceCapabilities.HostWriteMutationSupport}
           }}
        end

        def field_def("hostWriteMutationSupport") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "hostWriteMutationSupport",
             kind: {:scalar, nil},
             label: :optional,
             name: :hostWriteMutationSupport,
             tag: 12,
             type:
               {:message,
                WAWebProtobufsDeviceCapabilities.DeviceCapabilities.HostWriteMutationSupport}
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
    def default(:chatLockSupportLevel) do
      {:ok, :NONE}
    end,
    def default(:lidMigration) do
      {:ok, nil}
    end,
    def default(:businessBroadcast) do
      {:ok, nil}
    end,
    def default(:userHasAvatar) do
      {:ok, nil}
    end,
    def default(:memberNameTagPrimarySupport) do
      {:ok, :DISABLED}
    end,
    def default(:aiThread) do
      {:ok, nil}
    end,
    def default(:aiFbidMigration) do
      {:ok, nil}
    end,
    def default(:bizAiSettingsSync) do
      {:ok, nil}
    end,
    def default(:contactRefresh) do
      {:ok, nil}
    end,
    def default(:reverseHistorySync) do
      {:ok, nil}
    end,
    def default(:newsletterChatsMigration) do
      {:ok, nil}
    end,
    def default(:hostWriteMutationSupport) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waDeviceCapabilities",
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
