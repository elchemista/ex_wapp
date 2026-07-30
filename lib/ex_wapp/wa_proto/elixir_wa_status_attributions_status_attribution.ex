# credo:disable-for-this-file
defmodule WAStatusAttributions.StatusAttribution do
  @moduledoc false
  defstruct type: nil, actionURL: nil, attributionData: nil, __uf__: []

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
        |> encode_attributionData(msg)
        |> encode_type(msg)
        |> encode_actionURL(msg)
        |> encode_unknown_fields(msg)
      end
    )

    [
      defp encode_attributionData(acc, msg) do
        case msg.attributionData do
          nil -> acc
          {:statusReshare, _field_value} -> encode_statusReshare(acc, msg)
          {:externalShare, _field_value} -> encode_externalShare(acc, msg)
          {:music, _field_value} -> encode_music(acc, msg)
          {:groupStatus, _field_value} -> encode_groupStatus(acc, msg)
          {:rlAttribution, _field_value} -> encode_rlAttribution(acc, msg)
          {:aiCreatedAttribution, _field_value} -> encode_aiCreatedAttribution(acc, msg)
        end
      end
    ]

    [
      defp encode_type(acc, msg) do
        try do
          case msg.type do
            nil ->
              acc

            _ ->
              [
                acc,
                "\b",
                msg.type
                |> WAStatusAttributions.StatusAttribution.Type.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:type, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_actionURL(acc, msg) do
        try do
          case msg.actionURL do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.actionURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:actionURL, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_statusReshare(acc, msg) do
        try do
          {_, child_field_value} = msg.attributionData
          [acc, "\x1A", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:statusReshare, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_externalShare(acc, msg) do
        try do
          {_, child_field_value} = msg.attributionData
          [acc, "\"", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:externalShare, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_music(acc, msg) do
        try do
          {_, child_field_value} = msg.attributionData
          [acc, "*", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:music, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_groupStatus(acc, msg) do
        try do
          {_, child_field_value} = msg.attributionData
          [acc, "2", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:groupStatus, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_rlAttribution(acc, msg) do
        try do
          {_, child_field_value} = msg.attributionData
          [acc, ":", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:rlAttribution, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_aiCreatedAttribution(acc, msg) do
        try do
          {_, child_field_value} = msg.attributionData
          [acc, "B", Protox.Encode.encode_message(child_field_value)]
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:aiCreatedAttribution, "invalid field value"),
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
          parse_key_value(bytes, struct(WAStatusAttributions.StatusAttribution))
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
                Protox.Decode.parse_enum(bytes, WAStatusAttributions.StatusAttribution.Type)

              {[type: value], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[actionURL: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.attributionData do
                   {:statusReshare, previous_value} ->
                     {:attributionData,
                      {:statusReshare,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAStatusAttributions.StatusAttribution.StatusReshare.decode!(delimited)
                       )}}

                   _ ->
                     {:attributionData,
                      {:statusReshare,
                       WAStatusAttributions.StatusAttribution.StatusReshare.decode!(delimited)}}
                 end
               ], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.attributionData do
                   {:externalShare, previous_value} ->
                     {:attributionData,
                      {:externalShare,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAStatusAttributions.StatusAttribution.ExternalShare.decode!(delimited)
                       )}}

                   _ ->
                     {:attributionData,
                      {:externalShare,
                       WAStatusAttributions.StatusAttribution.ExternalShare.decode!(delimited)}}
                 end
               ], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.attributionData do
                   {:music, previous_value} ->
                     {:attributionData,
                      {:music,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAStatusAttributions.StatusAttribution.Music.decode!(delimited)
                       )}}

                   _ ->
                     {:attributionData,
                      {:music, WAStatusAttributions.StatusAttribution.Music.decode!(delimited)}}
                 end
               ], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.attributionData do
                   {:groupStatus, previous_value} ->
                     {:attributionData,
                      {:groupStatus,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAStatusAttributions.StatusAttribution.GroupStatus.decode!(delimited)
                       )}}

                   _ ->
                     {:attributionData,
                      {:groupStatus,
                       WAStatusAttributions.StatusAttribution.GroupStatus.decode!(delimited)}}
                 end
               ], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.attributionData do
                   {:rlAttribution, previous_value} ->
                     {:attributionData,
                      {:rlAttribution,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAStatusAttributions.StatusAttribution.RLAttribution.decode!(delimited)
                       )}}

                   _ ->
                     {:attributionData,
                      {:rlAttribution,
                       WAStatusAttributions.StatusAttribution.RLAttribution.decode!(delimited)}}
                 end
               ], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 case msg.attributionData do
                   {:aiCreatedAttribution, previous_value} ->
                     {:attributionData,
                      {:aiCreatedAttribution,
                       Protox.MergeMessage.merge(
                         previous_value,
                         WAStatusAttributions.StatusAttribution.AiCreatedAttribution.decode!(
                           delimited
                         )
                       )}}

                   _ ->
                     {:attributionData,
                      {:aiCreatedAttribution,
                       WAStatusAttributions.StatusAttribution.AiCreatedAttribution.decode!(
                         delimited
                       )}}
                 end
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
        WAStatusAttributions.StatusAttribution,
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
        1 => {:type, {:scalar, :UNKNOWN}, {:enum, WAStatusAttributions.StatusAttribution.Type}},
        2 => {:actionURL, {:scalar, ""}, :string},
        3 =>
          {:statusReshare, {:oneof, :attributionData},
           {:message, WAStatusAttributions.StatusAttribution.StatusReshare}},
        4 =>
          {:externalShare, {:oneof, :attributionData},
           {:message, WAStatusAttributions.StatusAttribution.ExternalShare}},
        5 =>
          {:music, {:oneof, :attributionData},
           {:message, WAStatusAttributions.StatusAttribution.Music}},
        6 =>
          {:groupStatus, {:oneof, :attributionData},
           {:message, WAStatusAttributions.StatusAttribution.GroupStatus}},
        7 =>
          {:rlAttribution, {:oneof, :attributionData},
           {:message, WAStatusAttributions.StatusAttribution.RLAttribution}},
        8 =>
          {:aiCreatedAttribution, {:oneof, :attributionData},
           {:message, WAStatusAttributions.StatusAttribution.AiCreatedAttribution}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        actionURL: {2, {:scalar, ""}, :string},
        aiCreatedAttribution:
          {8, {:oneof, :attributionData},
           {:message, WAStatusAttributions.StatusAttribution.AiCreatedAttribution}},
        externalShare:
          {4, {:oneof, :attributionData},
           {:message, WAStatusAttributions.StatusAttribution.ExternalShare}},
        groupStatus:
          {6, {:oneof, :attributionData},
           {:message, WAStatusAttributions.StatusAttribution.GroupStatus}},
        music:
          {5, {:oneof, :attributionData},
           {:message, WAStatusAttributions.StatusAttribution.Music}},
        rlAttribution:
          {7, {:oneof, :attributionData},
           {:message, WAStatusAttributions.StatusAttribution.RLAttribution}},
        statusReshare:
          {3, {:oneof, :attributionData},
           {:message, WAStatusAttributions.StatusAttribution.StatusReshare}},
        type: {1, {:scalar, :UNKNOWN}, {:enum, WAStatusAttributions.StatusAttribution.Type}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "type",
          kind: {:scalar, :UNKNOWN},
          label: :optional,
          name: :type,
          tag: 1,
          type: {:enum, WAStatusAttributions.StatusAttribution.Type}
        },
        %{
          __struct__: Protox.Field,
          json_name: "actionURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :actionURL,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "statusReshare",
          kind: {:oneof, :attributionData},
          label: :optional,
          name: :statusReshare,
          tag: 3,
          type: {:message, WAStatusAttributions.StatusAttribution.StatusReshare}
        },
        %{
          __struct__: Protox.Field,
          json_name: "externalShare",
          kind: {:oneof, :attributionData},
          label: :optional,
          name: :externalShare,
          tag: 4,
          type: {:message, WAStatusAttributions.StatusAttribution.ExternalShare}
        },
        %{
          __struct__: Protox.Field,
          json_name: "music",
          kind: {:oneof, :attributionData},
          label: :optional,
          name: :music,
          tag: 5,
          type: {:message, WAStatusAttributions.StatusAttribution.Music}
        },
        %{
          __struct__: Protox.Field,
          json_name: "groupStatus",
          kind: {:oneof, :attributionData},
          label: :optional,
          name: :groupStatus,
          tag: 6,
          type: {:message, WAStatusAttributions.StatusAttribution.GroupStatus}
        },
        %{
          __struct__: Protox.Field,
          json_name: "rlAttribution",
          kind: {:oneof, :attributionData},
          label: :optional,
          name: :rlAttribution,
          tag: 7,
          type: {:message, WAStatusAttributions.StatusAttribution.RLAttribution}
        },
        %{
          __struct__: Protox.Field,
          json_name: "aiCreatedAttribution",
          kind: {:oneof, :attributionData},
          label: :optional,
          name: :aiCreatedAttribution,
          tag: 8,
          type: {:message, WAStatusAttributions.StatusAttribution.AiCreatedAttribution}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:type) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :type,
             tag: 1,
             type: {:enum, WAStatusAttributions.StatusAttribution.Type}
           }}
        end

        def field_def("type") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "type",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :type,
             tag: 1,
             type: {:enum, WAStatusAttributions.StatusAttribution.Type}
           }}
        end

        []
      ),
      (
        def field_def(:actionURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "actionURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :actionURL,
             tag: 2,
             type: :string
           }}
        end

        def field_def("actionURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "actionURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :actionURL,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:statusReshare) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusReshare",
             kind: {:oneof, :attributionData},
             label: :optional,
             name: :statusReshare,
             tag: 3,
             type: {:message, WAStatusAttributions.StatusAttribution.StatusReshare}
           }}
        end

        def field_def("statusReshare") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "statusReshare",
             kind: {:oneof, :attributionData},
             label: :optional,
             name: :statusReshare,
             tag: 3,
             type: {:message, WAStatusAttributions.StatusAttribution.StatusReshare}
           }}
        end

        []
      ),
      (
        def field_def(:externalShare) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "externalShare",
             kind: {:oneof, :attributionData},
             label: :optional,
             name: :externalShare,
             tag: 4,
             type: {:message, WAStatusAttributions.StatusAttribution.ExternalShare}
           }}
        end

        def field_def("externalShare") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "externalShare",
             kind: {:oneof, :attributionData},
             label: :optional,
             name: :externalShare,
             tag: 4,
             type: {:message, WAStatusAttributions.StatusAttribution.ExternalShare}
           }}
        end

        []
      ),
      (
        def field_def(:music) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "music",
             kind: {:oneof, :attributionData},
             label: :optional,
             name: :music,
             tag: 5,
             type: {:message, WAStatusAttributions.StatusAttribution.Music}
           }}
        end

        def field_def("music") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "music",
             kind: {:oneof, :attributionData},
             label: :optional,
             name: :music,
             tag: 5,
             type: {:message, WAStatusAttributions.StatusAttribution.Music}
           }}
        end

        []
      ),
      (
        def field_def(:groupStatus) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupStatus",
             kind: {:oneof, :attributionData},
             label: :optional,
             name: :groupStatus,
             tag: 6,
             type: {:message, WAStatusAttributions.StatusAttribution.GroupStatus}
           }}
        end

        def field_def("groupStatus") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "groupStatus",
             kind: {:oneof, :attributionData},
             label: :optional,
             name: :groupStatus,
             tag: 6,
             type: {:message, WAStatusAttributions.StatusAttribution.GroupStatus}
           }}
        end

        []
      ),
      (
        def field_def(:rlAttribution) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "rlAttribution",
             kind: {:oneof, :attributionData},
             label: :optional,
             name: :rlAttribution,
             tag: 7,
             type: {:message, WAStatusAttributions.StatusAttribution.RLAttribution}
           }}
        end

        def field_def("rlAttribution") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "rlAttribution",
             kind: {:oneof, :attributionData},
             label: :optional,
             name: :rlAttribution,
             tag: 7,
             type: {:message, WAStatusAttributions.StatusAttribution.RLAttribution}
           }}
        end

        []
      ),
      (
        def field_def(:aiCreatedAttribution) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiCreatedAttribution",
             kind: {:oneof, :attributionData},
             label: :optional,
             name: :aiCreatedAttribution,
             tag: 8,
             type: {:message, WAStatusAttributions.StatusAttribution.AiCreatedAttribution}
           }}
        end

        def field_def("aiCreatedAttribution") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "aiCreatedAttribution",
             kind: {:oneof, :attributionData},
             label: :optional,
             name: :aiCreatedAttribution,
             tag: 8,
             type: {:message, WAStatusAttributions.StatusAttribution.AiCreatedAttribution}
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
    def default(:type) do
      {:ok, :UNKNOWN}
    end,
    def default(:actionURL) do
      {:ok, ""}
    end,
    def default(:statusReshare) do
      {:error, :no_default_value}
    end,
    def default(:externalShare) do
      {:error, :no_default_value}
    end,
    def default(:music) do
      {:error, :no_default_value}
    end,
    def default(:groupStatus) do
      {:error, :no_default_value}
    end,
    def default(:rlAttribution) do
      {:error, :no_default_value}
    end,
    def default(:aiCreatedAttribution) do
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
        go_package: "go.mau.fi/whatsmeow/proto/waStatusAttributions",
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
