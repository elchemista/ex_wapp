# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.LinkPreviewMetadata do
  @moduledoc false
  defstruct paymentLinkMetadata: nil,
            urlMetadata: nil,
            fbExperimentID: nil,
            linkMediaDuration: nil,
            socialMediaPostType: nil,
            linkInlineVideoMuted: nil,
            videoContentURL: nil,
            musicMetadata: nil,
            videoContentCaption: nil,
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
        |> encode_paymentLinkMetadata(msg)
        |> encode_urlMetadata(msg)
        |> encode_fbExperimentID(msg)
        |> encode_linkMediaDuration(msg)
        |> encode_socialMediaPostType(msg)
        |> encode_linkInlineVideoMuted(msg)
        |> encode_videoContentURL(msg)
        |> encode_musicMetadata(msg)
        |> encode_videoContentCaption(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_paymentLinkMetadata(acc, msg) do
        try do
          case msg.paymentLinkMetadata do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_message(msg.paymentLinkMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:paymentLinkMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_urlMetadata(acc, msg) do
        try do
          case msg.urlMetadata do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_message(msg.urlMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:urlMetadata, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fbExperimentID(acc, msg) do
        try do
          case msg.fbExperimentID do
            nil -> acc
            _ -> [acc, "\x18", Protox.Encode.encode_uint32(msg.fbExperimentID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fbExperimentID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_linkMediaDuration(acc, msg) do
        try do
          case msg.linkMediaDuration do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_uint32(msg.linkMediaDuration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:linkMediaDuration, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_socialMediaPostType(acc, msg) do
        try do
          case msg.socialMediaPostType do
            nil ->
              acc

            _ ->
              [
                acc,
                "(",
                msg.socialMediaPostType
                |> WAWebProtobufsE2E.LinkPreviewMetadata.SocialMediaPostType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:socialMediaPostType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_linkInlineVideoMuted(acc, msg) do
        try do
          case msg.linkInlineVideoMuted do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_bool(msg.linkInlineVideoMuted)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:linkInlineVideoMuted, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_videoContentURL(acc, msg) do
        try do
          case msg.videoContentURL do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.videoContentURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:videoContentURL, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_musicMetadata(acc, msg) do
        try do
          case msg.musicMetadata do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_message(msg.musicMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:musicMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_videoContentCaption(acc, msg) do
        try do
          case msg.videoContentCaption do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_string(msg.videoContentCaption)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:videoContentCaption, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.LinkPreviewMetadata))
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
                 paymentLinkMetadata:
                   Protox.MergeMessage.merge(
                     msg.paymentLinkMetadata,
                     WAWebProtobufsE2E.PaymentLinkMetadata.decode!(delimited)
                   )
               ], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 urlMetadata:
                   Protox.MergeMessage.merge(
                     msg.urlMetadata,
                     WAWebProtobufsE2E.URLMetadata.decode!(delimited)
                   )
               ], rest}

            {3, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[fbExperimentID: value], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[linkMediaDuration: value], rest}

            {5, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.LinkPreviewMetadata.SocialMediaPostType
                )

              {[socialMediaPostType: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[linkInlineVideoMuted: value], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[videoContentURL: Protox.Decode.validate_string!(delimited)], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 musicMetadata:
                   Protox.MergeMessage.merge(
                     msg.musicMetadata,
                     WAWebProtobufsE2E.EmbeddedMusic.decode!(delimited)
                   )
               ], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[videoContentCaption: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufsE2E.LinkPreviewMetadata,
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
          {:paymentLinkMetadata, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PaymentLinkMetadata}},
        2 => {:urlMetadata, {:scalar, nil}, {:message, WAWebProtobufsE2E.URLMetadata}},
        3 => {:fbExperimentID, {:scalar, 0}, :uint32},
        4 => {:linkMediaDuration, {:scalar, 0}, :uint32},
        5 =>
          {:socialMediaPostType, {:scalar, :NONE},
           {:enum, WAWebProtobufsE2E.LinkPreviewMetadata.SocialMediaPostType}},
        6 => {:linkInlineVideoMuted, {:scalar, false}, :bool},
        7 => {:videoContentURL, {:scalar, ""}, :string},
        8 => {:musicMetadata, {:scalar, nil}, {:message, WAWebProtobufsE2E.EmbeddedMusic}},
        9 => {:videoContentCaption, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        fbExperimentID: {3, {:scalar, 0}, :uint32},
        linkInlineVideoMuted: {6, {:scalar, false}, :bool},
        linkMediaDuration: {4, {:scalar, 0}, :uint32},
        musicMetadata: {8, {:scalar, nil}, {:message, WAWebProtobufsE2E.EmbeddedMusic}},
        paymentLinkMetadata:
          {1, {:scalar, nil}, {:message, WAWebProtobufsE2E.PaymentLinkMetadata}},
        socialMediaPostType:
          {5, {:scalar, :NONE},
           {:enum, WAWebProtobufsE2E.LinkPreviewMetadata.SocialMediaPostType}},
        urlMetadata: {2, {:scalar, nil}, {:message, WAWebProtobufsE2E.URLMetadata}},
        videoContentCaption: {9, {:scalar, ""}, :string},
        videoContentURL: {7, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "paymentLinkMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :paymentLinkMetadata,
          tag: 1,
          type: {:message, WAWebProtobufsE2E.PaymentLinkMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "urlMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :urlMetadata,
          tag: 2,
          type: {:message, WAWebProtobufsE2E.URLMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "fbExperimentID",
          kind: {:scalar, 0},
          label: :optional,
          name: :fbExperimentID,
          tag: 3,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "linkMediaDuration",
          kind: {:scalar, 0},
          label: :optional,
          name: :linkMediaDuration,
          tag: 4,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "socialMediaPostType",
          kind: {:scalar, :NONE},
          label: :optional,
          name: :socialMediaPostType,
          tag: 5,
          type: {:enum, WAWebProtobufsE2E.LinkPreviewMetadata.SocialMediaPostType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "linkInlineVideoMuted",
          kind: {:scalar, false},
          label: :optional,
          name: :linkInlineVideoMuted,
          tag: 6,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "videoContentURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :videoContentURL,
          tag: 7,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "musicMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :musicMetadata,
          tag: 8,
          type: {:message, WAWebProtobufsE2E.EmbeddedMusic}
        },
        %{
          __struct__: Protox.Field,
          json_name: "videoContentCaption",
          kind: {:scalar, ""},
          label: :optional,
          name: :videoContentCaption,
          tag: 9,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:paymentLinkMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentLinkMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentLinkMetadata,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.PaymentLinkMetadata}
           }}
        end

        def field_def("paymentLinkMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentLinkMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentLinkMetadata,
             tag: 1,
             type: {:message, WAWebProtobufsE2E.PaymentLinkMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:urlMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "urlMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :urlMetadata,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.URLMetadata}
           }}
        end

        def field_def("urlMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "urlMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :urlMetadata,
             tag: 2,
             type: {:message, WAWebProtobufsE2E.URLMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:fbExperimentID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fbExperimentID",
             kind: {:scalar, 0},
             label: :optional,
             name: :fbExperimentID,
             tag: 3,
             type: :uint32
           }}
        end

        def field_def("fbExperimentID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fbExperimentID",
             kind: {:scalar, 0},
             label: :optional,
             name: :fbExperimentID,
             tag: 3,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:linkMediaDuration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "linkMediaDuration",
             kind: {:scalar, 0},
             label: :optional,
             name: :linkMediaDuration,
             tag: 4,
             type: :uint32
           }}
        end

        def field_def("linkMediaDuration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "linkMediaDuration",
             kind: {:scalar, 0},
             label: :optional,
             name: :linkMediaDuration,
             tag: 4,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:socialMediaPostType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "socialMediaPostType",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :socialMediaPostType,
             tag: 5,
             type: {:enum, WAWebProtobufsE2E.LinkPreviewMetadata.SocialMediaPostType}
           }}
        end

        def field_def("socialMediaPostType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "socialMediaPostType",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :socialMediaPostType,
             tag: 5,
             type: {:enum, WAWebProtobufsE2E.LinkPreviewMetadata.SocialMediaPostType}
           }}
        end

        []
      ),
      (
        def field_def(:linkInlineVideoMuted) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "linkInlineVideoMuted",
             kind: {:scalar, false},
             label: :optional,
             name: :linkInlineVideoMuted,
             tag: 6,
             type: :bool
           }}
        end

        def field_def("linkInlineVideoMuted") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "linkInlineVideoMuted",
             kind: {:scalar, false},
             label: :optional,
             name: :linkInlineVideoMuted,
             tag: 6,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:videoContentURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoContentURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :videoContentURL,
             tag: 7,
             type: :string
           }}
        end

        def field_def("videoContentURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoContentURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :videoContentURL,
             tag: 7,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:musicMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "musicMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :musicMetadata,
             tag: 8,
             type: {:message, WAWebProtobufsE2E.EmbeddedMusic}
           }}
        end

        def field_def("musicMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "musicMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :musicMetadata,
             tag: 8,
             type: {:message, WAWebProtobufsE2E.EmbeddedMusic}
           }}
        end

        []
      ),
      (
        def field_def(:videoContentCaption) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoContentCaption",
             kind: {:scalar, ""},
             label: :optional,
             name: :videoContentCaption,
             tag: 9,
             type: :string
           }}
        end

        def field_def("videoContentCaption") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoContentCaption",
             kind: {:scalar, ""},
             label: :optional,
             name: :videoContentCaption,
             tag: 9,
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
    def default(:paymentLinkMetadata) do
      {:ok, nil}
    end,
    def default(:urlMetadata) do
      {:ok, nil}
    end,
    def default(:fbExperimentID) do
      {:ok, 0}
    end,
    def default(:linkMediaDuration) do
      {:ok, 0}
    end,
    def default(:socialMediaPostType) do
      {:ok, :NONE}
    end,
    def default(:linkInlineVideoMuted) do
      {:ok, false}
    end,
    def default(:videoContentURL) do
      {:ok, ""}
    end,
    def default(:musicMetadata) do
      {:ok, nil}
    end,
    def default(:videoContentCaption) do
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
