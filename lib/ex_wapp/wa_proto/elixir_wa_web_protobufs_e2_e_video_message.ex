# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.VideoMessage do
  @moduledoc false
  defstruct URL: nil,
            mimetype: nil,
            fileSHA256: nil,
            fileLength: nil,
            seconds: nil,
            mediaKey: nil,
            caption: nil,
            gifPlayback: nil,
            height: nil,
            width: nil,
            fileEncSHA256: nil,
            interactiveAnnotations: [],
            directPath: nil,
            mediaKeyTimestamp: nil,
            JPEGThumbnail: nil,
            contextInfo: nil,
            streamingSidecar: nil,
            gifAttribution: nil,
            viewOnce: nil,
            thumbnailDirectPath: nil,
            thumbnailSHA256: nil,
            thumbnailEncSHA256: nil,
            staticURL: nil,
            annotations: [],
            accessibilityLabel: nil,
            processedVideos: [],
            externalShareFullVideoDurationInSeconds: nil,
            motionPhotoPresentationOffsetMS: nil,
            metadataURL: nil,
            videoSourceType: nil,
            dashManifestURL: nil,
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
        |> encode_URL(msg)
        |> encode_mimetype(msg)
        |> encode_fileSHA256(msg)
        |> encode_fileLength(msg)
        |> encode_seconds(msg)
        |> encode_mediaKey(msg)
        |> encode_caption(msg)
        |> encode_gifPlayback(msg)
        |> encode_height(msg)
        |> encode_width(msg)
        |> encode_fileEncSHA256(msg)
        |> encode_interactiveAnnotations(msg)
        |> encode_directPath(msg)
        |> encode_mediaKeyTimestamp(msg)
        |> encode_JPEGThumbnail(msg)
        |> encode_contextInfo(msg)
        |> encode_streamingSidecar(msg)
        |> encode_gifAttribution(msg)
        |> encode_viewOnce(msg)
        |> encode_thumbnailDirectPath(msg)
        |> encode_thumbnailSHA256(msg)
        |> encode_thumbnailEncSHA256(msg)
        |> encode_staticURL(msg)
        |> encode_annotations(msg)
        |> encode_accessibilityLabel(msg)
        |> encode_processedVideos(msg)
        |> encode_externalShareFullVideoDurationInSeconds(msg)
        |> encode_motionPhotoPresentationOffsetMS(msg)
        |> encode_metadataURL(msg)
        |> encode_videoSourceType(msg)
        |> encode_dashManifestURL(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_URL(acc, msg) do
        try do
          case msg."URL" do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg."URL")]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:URL, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mimetype(acc, msg) do
        try do
          case msg.mimetype do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.mimetype)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mimetype, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileSHA256(acc, msg) do
        try do
          case msg.fileSHA256 do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_bytes(msg.fileSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileSHA256, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileLength(acc, msg) do
        try do
          case msg.fileLength do
            nil -> acc
            _ -> [acc, " ", Protox.Encode.encode_uint64(msg.fileLength)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileLength, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_seconds(acc, msg) do
        try do
          case msg.seconds do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_uint32(msg.seconds)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:seconds, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaKey(acc, msg) do
        try do
          case msg.mediaKey do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_bytes(msg.mediaKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaKey, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_caption(acc, msg) do
        try do
          case msg.caption do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.caption)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:caption, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_gifPlayback(acc, msg) do
        try do
          case msg.gifPlayback do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_bool(msg.gifPlayback)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:gifPlayback, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_height(acc, msg) do
        try do
          case msg.height do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_uint32(msg.height)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:height, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_width(acc, msg) do
        try do
          case msg.width do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_uint32(msg.width)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:width, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_fileEncSHA256(acc, msg) do
        try do
          case msg.fileEncSHA256 do
            nil -> acc
            _ -> [acc, "Z", Protox.Encode.encode_bytes(msg.fileEncSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:fileEncSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_interactiveAnnotations(acc, msg) do
        try do
          case msg.interactiveAnnotations do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "b", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:interactiveAnnotations, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_directPath(acc, msg) do
        try do
          case msg.directPath do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_string(msg.directPath)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:directPath, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaKeyTimestamp(acc, msg) do
        try do
          case msg.mediaKeyTimestamp do
            nil -> acc
            _ -> [acc, "p", Protox.Encode.encode_int64(msg.mediaKeyTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaKeyTimestamp, "invalid field value"),
                    __STACKTRACE__
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
      end,
      defp encode_streamingSidecar(acc, msg) do
        try do
          case msg.streamingSidecar do
            nil -> acc
            _ -> [acc, "\x92\x01", Protox.Encode.encode_bytes(msg.streamingSidecar)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:streamingSidecar, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_gifAttribution(acc, msg) do
        try do
          case msg.gifAttribution do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x98\x01",
                msg.gifAttribution
                |> WAWebProtobufsE2E.VideoMessage.Attribution.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:gifAttribution, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_viewOnce(acc, msg) do
        try do
          case msg.viewOnce do
            nil -> acc
            _ -> [acc, "\xA0\x01", Protox.Encode.encode_bool(msg.viewOnce)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:viewOnce, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_thumbnailDirectPath(acc, msg) do
        try do
          case msg.thumbnailDirectPath do
            nil -> acc
            _ -> [acc, "\xAA\x01", Protox.Encode.encode_string(msg.thumbnailDirectPath)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailDirectPath, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailSHA256(acc, msg) do
        try do
          case msg.thumbnailSHA256 do
            nil -> acc
            _ -> [acc, "\xB2\x01", Protox.Encode.encode_bytes(msg.thumbnailSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailEncSHA256(acc, msg) do
        try do
          case msg.thumbnailEncSHA256 do
            nil -> acc
            _ -> [acc, "\xBA\x01", Protox.Encode.encode_bytes(msg.thumbnailEncSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailEncSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_staticURL(acc, msg) do
        try do
          case msg.staticURL do
            nil -> acc
            _ -> [acc, "\xC2\x01", Protox.Encode.encode_string(msg.staticURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:staticURL, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_annotations(acc, msg) do
        try do
          case msg.annotations do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xCA\x01", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:annotations, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_accessibilityLabel(acc, msg) do
        try do
          case msg.accessibilityLabel do
            nil -> acc
            _ -> [acc, "\xD2\x01", Protox.Encode.encode_string(msg.accessibilityLabel)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:accessibilityLabel, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_processedVideos(acc, msg) do
        try do
          case msg.processedVideos do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xDA\x01", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:processedVideos, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_externalShareFullVideoDurationInSeconds(acc, msg) do
        try do
          case msg.externalShareFullVideoDurationInSeconds do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xE0\x01",
                Protox.Encode.encode_uint32(msg.externalShareFullVideoDurationInSeconds)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :externalShareFullVideoDurationInSeconds,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_motionPhotoPresentationOffsetMS(acc, msg) do
        try do
          case msg.motionPhotoPresentationOffsetMS do
            nil ->
              acc

            _ ->
              [acc, "\xE8\x01", Protox.Encode.encode_uint64(msg.motionPhotoPresentationOffsetMS)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :motionPhotoPresentationOffsetMS,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_metadataURL(acc, msg) do
        try do
          case msg.metadataURL do
            nil -> acc
            _ -> [acc, "\xF2\x01", Protox.Encode.encode_string(msg.metadataURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:metadataURL, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_videoSourceType(acc, msg) do
        try do
          case msg.videoSourceType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xF8\x01",
                msg.videoSourceType
                |> WAWebProtobufsE2E.VideoMessage.VideoSourceType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:videoSourceType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_dashManifestURL(acc, msg) do
        try do
          case msg.dashManifestURL do
            nil -> acc
            _ -> [acc, "\x8A\x02", Protox.Encode.encode_string(msg.dashManifestURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:dashManifestURL, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.VideoMessage))
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
              {[URL: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mimetype: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fileSHA256: delimited], rest}

            {4, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[fileLength: value], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[seconds: value], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mediaKey: delimited], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[caption: Protox.Decode.validate_string!(delimited)], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[gifPlayback: value], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[height: value], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[width: value], rest}

            {11, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[fileEncSHA256: delimited], rest}

            {12, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 interactiveAnnotations:
                   msg.interactiveAnnotations ++
                     [WAWebProtobufsE2E.InteractiveAnnotation.decode!(delimited)]
               ], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[directPath: Protox.Decode.validate_string!(delimited)], rest}

            {14, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[mediaKeyTimestamp: value], rest}

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

            {18, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[streamingSidecar: delimited], rest}

            {19, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.VideoMessage.Attribution)

              {[gifAttribution: value], rest}

            {20, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[viewOnce: value], rest}

            {21, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnailDirectPath: Protox.Decode.validate_string!(delimited)], rest}

            {22, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnailSHA256: delimited], rest}

            {23, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnailEncSHA256: delimited], rest}

            {24, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[staticURL: Protox.Decode.validate_string!(delimited)], rest}

            {25, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 annotations:
                   msg.annotations ++ [WAWebProtobufsE2E.InteractiveAnnotation.decode!(delimited)]
               ], rest}

            {26, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[accessibilityLabel: Protox.Decode.validate_string!(delimited)], rest}

            {27, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 processedVideos:
                   msg.processedVideos ++ [WAWebProtobufsE2E.ProcessedVideo.decode!(delimited)]
               ], rest}

            {28, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[externalShareFullVideoDurationInSeconds: value], rest}

            {29, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[motionPhotoPresentationOffsetMS: value], rest}

            {30, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[metadataURL: Protox.Decode.validate_string!(delimited)], rest}

            {31, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.VideoMessage.VideoSourceType)

              {[videoSourceType: value], rest}

            {33, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[dashManifestURL: Protox.Decode.validate_string!(delimited)], rest}

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
        WAWebProtobufsE2E.VideoMessage,
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
        1 => {:URL, {:scalar, ""}, :string},
        2 => {:mimetype, {:scalar, ""}, :string},
        3 => {:fileSHA256, {:scalar, ""}, :bytes},
        4 => {:fileLength, {:scalar, 0}, :uint64},
        5 => {:seconds, {:scalar, 0}, :uint32},
        6 => {:mediaKey, {:scalar, ""}, :bytes},
        7 => {:caption, {:scalar, ""}, :string},
        8 => {:gifPlayback, {:scalar, false}, :bool},
        9 => {:height, {:scalar, 0}, :uint32},
        10 => {:width, {:scalar, 0}, :uint32},
        11 => {:fileEncSHA256, {:scalar, ""}, :bytes},
        12 =>
          {:interactiveAnnotations, :unpacked,
           {:message, WAWebProtobufsE2E.InteractiveAnnotation}},
        13 => {:directPath, {:scalar, ""}, :string},
        14 => {:mediaKeyTimestamp, {:scalar, 0}, :int64},
        16 => {:JPEGThumbnail, {:scalar, ""}, :bytes},
        17 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        18 => {:streamingSidecar, {:scalar, ""}, :bytes},
        19 =>
          {:gifAttribution, {:scalar, :NONE}, {:enum, WAWebProtobufsE2E.VideoMessage.Attribution}},
        20 => {:viewOnce, {:scalar, false}, :bool},
        21 => {:thumbnailDirectPath, {:scalar, ""}, :string},
        22 => {:thumbnailSHA256, {:scalar, ""}, :bytes},
        23 => {:thumbnailEncSHA256, {:scalar, ""}, :bytes},
        24 => {:staticURL, {:scalar, ""}, :string},
        25 => {:annotations, :unpacked, {:message, WAWebProtobufsE2E.InteractiveAnnotation}},
        26 => {:accessibilityLabel, {:scalar, ""}, :string},
        27 => {:processedVideos, :unpacked, {:message, WAWebProtobufsE2E.ProcessedVideo}},
        28 => {:externalShareFullVideoDurationInSeconds, {:scalar, 0}, :uint32},
        29 => {:motionPhotoPresentationOffsetMS, {:scalar, 0}, :uint64},
        30 => {:metadataURL, {:scalar, ""}, :string},
        31 =>
          {:videoSourceType, {:scalar, :USER_VIDEO},
           {:enum, WAWebProtobufsE2E.VideoMessage.VideoSourceType}},
        33 => {:dashManifestURL, {:scalar, ""}, :string}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        JPEGThumbnail: {16, {:scalar, ""}, :bytes},
        URL: {1, {:scalar, ""}, :string},
        accessibilityLabel: {26, {:scalar, ""}, :string},
        annotations: {25, :unpacked, {:message, WAWebProtobufsE2E.InteractiveAnnotation}},
        caption: {7, {:scalar, ""}, :string},
        contextInfo: {17, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        dashManifestURL: {33, {:scalar, ""}, :string},
        directPath: {13, {:scalar, ""}, :string},
        externalShareFullVideoDurationInSeconds: {28, {:scalar, 0}, :uint32},
        fileEncSHA256: {11, {:scalar, ""}, :bytes},
        fileLength: {4, {:scalar, 0}, :uint64},
        fileSHA256: {3, {:scalar, ""}, :bytes},
        gifAttribution:
          {19, {:scalar, :NONE}, {:enum, WAWebProtobufsE2E.VideoMessage.Attribution}},
        gifPlayback: {8, {:scalar, false}, :bool},
        height: {9, {:scalar, 0}, :uint32},
        interactiveAnnotations:
          {12, :unpacked, {:message, WAWebProtobufsE2E.InteractiveAnnotation}},
        mediaKey: {6, {:scalar, ""}, :bytes},
        mediaKeyTimestamp: {14, {:scalar, 0}, :int64},
        metadataURL: {30, {:scalar, ""}, :string},
        mimetype: {2, {:scalar, ""}, :string},
        motionPhotoPresentationOffsetMS: {29, {:scalar, 0}, :uint64},
        processedVideos: {27, :unpacked, {:message, WAWebProtobufsE2E.ProcessedVideo}},
        seconds: {5, {:scalar, 0}, :uint32},
        staticURL: {24, {:scalar, ""}, :string},
        streamingSidecar: {18, {:scalar, ""}, :bytes},
        thumbnailDirectPath: {21, {:scalar, ""}, :string},
        thumbnailEncSHA256: {23, {:scalar, ""}, :bytes},
        thumbnailSHA256: {22, {:scalar, ""}, :bytes},
        videoSourceType:
          {31, {:scalar, :USER_VIDEO}, {:enum, WAWebProtobufsE2E.VideoMessage.VideoSourceType}},
        viewOnce: {20, {:scalar, false}, :bool},
        width: {10, {:scalar, 0}, :uint32}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "URL",
          kind: {:scalar, ""},
          label: :optional,
          name: :URL,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "mimetype",
          kind: {:scalar, ""},
          label: :optional,
          name: :mimetype,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileSHA256,
          tag: 3,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileLength",
          kind: {:scalar, 0},
          label: :optional,
          name: :fileLength,
          tag: 4,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "seconds",
          kind: {:scalar, 0},
          label: :optional,
          name: :seconds,
          tag: 5,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :mediaKey,
          tag: 6,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "caption",
          kind: {:scalar, ""},
          label: :optional,
          name: :caption,
          tag: 7,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "gifPlayback",
          kind: {:scalar, false},
          label: :optional,
          name: :gifPlayback,
          tag: 8,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "height",
          kind: {:scalar, 0},
          label: :optional,
          name: :height,
          tag: 9,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "width",
          kind: {:scalar, 0},
          label: :optional,
          name: :width,
          tag: 10,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "fileEncSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :fileEncSHA256,
          tag: 11,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "interactiveAnnotations",
          kind: :unpacked,
          label: :repeated,
          name: :interactiveAnnotations,
          tag: 12,
          type: {:message, WAWebProtobufsE2E.InteractiveAnnotation}
        },
        %{
          __struct__: Protox.Field,
          json_name: "directPath",
          kind: {:scalar, ""},
          label: :optional,
          name: :directPath,
          tag: 13,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKeyTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :mediaKeyTimestamp,
          tag: 14,
          type: :int64
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
        },
        %{
          __struct__: Protox.Field,
          json_name: "streamingSidecar",
          kind: {:scalar, ""},
          label: :optional,
          name: :streamingSidecar,
          tag: 18,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "gifAttribution",
          kind: {:scalar, :NONE},
          label: :optional,
          name: :gifAttribution,
          tag: 19,
          type: {:enum, WAWebProtobufsE2E.VideoMessage.Attribution}
        },
        %{
          __struct__: Protox.Field,
          json_name: "viewOnce",
          kind: {:scalar, false},
          label: :optional,
          name: :viewOnce,
          tag: 20,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailDirectPath",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailDirectPath,
          tag: 21,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailSHA256,
          tag: 22,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailEncSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailEncSHA256,
          tag: 23,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "staticURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :staticURL,
          tag: 24,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "annotations",
          kind: :unpacked,
          label: :repeated,
          name: :annotations,
          tag: 25,
          type: {:message, WAWebProtobufsE2E.InteractiveAnnotation}
        },
        %{
          __struct__: Protox.Field,
          json_name: "accessibilityLabel",
          kind: {:scalar, ""},
          label: :optional,
          name: :accessibilityLabel,
          tag: 26,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "processedVideos",
          kind: :unpacked,
          label: :repeated,
          name: :processedVideos,
          tag: 27,
          type: {:message, WAWebProtobufsE2E.ProcessedVideo}
        },
        %{
          __struct__: Protox.Field,
          json_name: "externalShareFullVideoDurationInSeconds",
          kind: {:scalar, 0},
          label: :optional,
          name: :externalShareFullVideoDurationInSeconds,
          tag: 28,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "motionPhotoPresentationOffsetMS",
          kind: {:scalar, 0},
          label: :optional,
          name: :motionPhotoPresentationOffsetMS,
          tag: 29,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "metadataURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :metadataURL,
          tag: 30,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "videoSourceType",
          kind: {:scalar, :USER_VIDEO},
          label: :optional,
          name: :videoSourceType,
          tag: 31,
          type: {:enum, WAWebProtobufsE2E.VideoMessage.VideoSourceType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "dashManifestURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :dashManifestURL,
          tag: 33,
          type: :string
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:URL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "URL",
             kind: {:scalar, ""},
             label: :optional,
             name: :URL,
             tag: 1,
             type: :string
           }}
        end

        def field_def("URL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "URL",
             kind: {:scalar, ""},
             label: :optional,
             name: :URL,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:mimetype) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mimetype",
             kind: {:scalar, ""},
             label: :optional,
             name: :mimetype,
             tag: 2,
             type: :string
           }}
        end

        def field_def("mimetype") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mimetype",
             kind: {:scalar, ""},
             label: :optional,
             name: :mimetype,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:fileSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileSHA256,
             tag: 3,
             type: :bytes
           }}
        end

        def field_def("fileSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileSHA256,
             tag: 3,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:fileLength) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileLength",
             kind: {:scalar, 0},
             label: :optional,
             name: :fileLength,
             tag: 4,
             type: :uint64
           }}
        end

        def field_def("fileLength") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileLength",
             kind: {:scalar, 0},
             label: :optional,
             name: :fileLength,
             tag: 4,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:seconds) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "seconds",
             kind: {:scalar, 0},
             label: :optional,
             name: :seconds,
             tag: 5,
             type: :uint32
           }}
        end

        def field_def("seconds") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "seconds",
             kind: {:scalar, 0},
             label: :optional,
             name: :seconds,
             tag: 5,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:mediaKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :mediaKey,
             tag: 6,
             type: :bytes
           }}
        end

        def field_def("mediaKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :mediaKey,
             tag: 6,
             type: :bytes
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
             tag: 7,
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
             tag: 7,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:gifPlayback) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "gifPlayback",
             kind: {:scalar, false},
             label: :optional,
             name: :gifPlayback,
             tag: 8,
             type: :bool
           }}
        end

        def field_def("gifPlayback") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "gifPlayback",
             kind: {:scalar, false},
             label: :optional,
             name: :gifPlayback,
             tag: 8,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:height) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "height",
             kind: {:scalar, 0},
             label: :optional,
             name: :height,
             tag: 9,
             type: :uint32
           }}
        end

        def field_def("height") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "height",
             kind: {:scalar, 0},
             label: :optional,
             name: :height,
             tag: 9,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:width) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "width",
             kind: {:scalar, 0},
             label: :optional,
             name: :width,
             tag: 10,
             type: :uint32
           }}
        end

        def field_def("width") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "width",
             kind: {:scalar, 0},
             label: :optional,
             name: :width,
             tag: 10,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:fileEncSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileEncSHA256,
             tag: 11,
             type: :bytes
           }}
        end

        def field_def("fileEncSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "fileEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :fileEncSHA256,
             tag: 11,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:interactiveAnnotations) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interactiveAnnotations",
             kind: :unpacked,
             label: :repeated,
             name: :interactiveAnnotations,
             tag: 12,
             type: {:message, WAWebProtobufsE2E.InteractiveAnnotation}
           }}
        end

        def field_def("interactiveAnnotations") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "interactiveAnnotations",
             kind: :unpacked,
             label: :repeated,
             name: :interactiveAnnotations,
             tag: 12,
             type: {:message, WAWebProtobufsE2E.InteractiveAnnotation}
           }}
        end

        []
      ),
      (
        def field_def(:directPath) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "directPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :directPath,
             tag: 13,
             type: :string
           }}
        end

        def field_def("directPath") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "directPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :directPath,
             tag: 13,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:mediaKeyTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaKeyTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :mediaKeyTimestamp,
             tag: 14,
             type: :int64
           }}
        end

        def field_def("mediaKeyTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaKeyTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :mediaKeyTimestamp,
             tag: 14,
             type: :int64
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
      (
        def field_def(:streamingSidecar) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "streamingSidecar",
             kind: {:scalar, ""},
             label: :optional,
             name: :streamingSidecar,
             tag: 18,
             type: :bytes
           }}
        end

        def field_def("streamingSidecar") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "streamingSidecar",
             kind: {:scalar, ""},
             label: :optional,
             name: :streamingSidecar,
             tag: 18,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:gifAttribution) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "gifAttribution",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :gifAttribution,
             tag: 19,
             type: {:enum, WAWebProtobufsE2E.VideoMessage.Attribution}
           }}
        end

        def field_def("gifAttribution") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "gifAttribution",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :gifAttribution,
             tag: 19,
             type: {:enum, WAWebProtobufsE2E.VideoMessage.Attribution}
           }}
        end

        []
      ),
      (
        def field_def(:viewOnce) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "viewOnce",
             kind: {:scalar, false},
             label: :optional,
             name: :viewOnce,
             tag: 20,
             type: :bool
           }}
        end

        def field_def("viewOnce") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "viewOnce",
             kind: {:scalar, false},
             label: :optional,
             name: :viewOnce,
             tag: 20,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailDirectPath) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailDirectPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailDirectPath,
             tag: 21,
             type: :string
           }}
        end

        def field_def("thumbnailDirectPath") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailDirectPath",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailDirectPath,
             tag: 21,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailSHA256,
             tag: 22,
             type: :bytes
           }}
        end

        def field_def("thumbnailSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailSHA256,
             tag: 22,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailEncSHA256) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailEncSHA256,
             tag: 23,
             type: :bytes
           }}
        end

        def field_def("thumbnailEncSHA256") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailEncSHA256",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailEncSHA256,
             tag: 23,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:staticURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "staticURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :staticURL,
             tag: 24,
             type: :string
           }}
        end

        def field_def("staticURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "staticURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :staticURL,
             tag: 24,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:annotations) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "annotations",
             kind: :unpacked,
             label: :repeated,
             name: :annotations,
             tag: 25,
             type: {:message, WAWebProtobufsE2E.InteractiveAnnotation}
           }}
        end

        def field_def("annotations") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "annotations",
             kind: :unpacked,
             label: :repeated,
             name: :annotations,
             tag: 25,
             type: {:message, WAWebProtobufsE2E.InteractiveAnnotation}
           }}
        end

        []
      ),
      (
        def field_def(:accessibilityLabel) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accessibilityLabel",
             kind: {:scalar, ""},
             label: :optional,
             name: :accessibilityLabel,
             tag: 26,
             type: :string
           }}
        end

        def field_def("accessibilityLabel") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accessibilityLabel",
             kind: {:scalar, ""},
             label: :optional,
             name: :accessibilityLabel,
             tag: 26,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:processedVideos) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "processedVideos",
             kind: :unpacked,
             label: :repeated,
             name: :processedVideos,
             tag: 27,
             type: {:message, WAWebProtobufsE2E.ProcessedVideo}
           }}
        end

        def field_def("processedVideos") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "processedVideos",
             kind: :unpacked,
             label: :repeated,
             name: :processedVideos,
             tag: 27,
             type: {:message, WAWebProtobufsE2E.ProcessedVideo}
           }}
        end

        []
      ),
      (
        def field_def(:externalShareFullVideoDurationInSeconds) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "externalShareFullVideoDurationInSeconds",
             kind: {:scalar, 0},
             label: :optional,
             name: :externalShareFullVideoDurationInSeconds,
             tag: 28,
             type: :uint32
           }}
        end

        def field_def("externalShareFullVideoDurationInSeconds") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "externalShareFullVideoDurationInSeconds",
             kind: {:scalar, 0},
             label: :optional,
             name: :externalShareFullVideoDurationInSeconds,
             tag: 28,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:motionPhotoPresentationOffsetMS) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "motionPhotoPresentationOffsetMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :motionPhotoPresentationOffsetMS,
             tag: 29,
             type: :uint64
           }}
        end

        def field_def("motionPhotoPresentationOffsetMS") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "motionPhotoPresentationOffsetMS",
             kind: {:scalar, 0},
             label: :optional,
             name: :motionPhotoPresentationOffsetMS,
             tag: 29,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:metadataURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "metadataURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :metadataURL,
             tag: 30,
             type: :string
           }}
        end

        def field_def("metadataURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "metadataURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :metadataURL,
             tag: 30,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:videoSourceType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoSourceType",
             kind: {:scalar, :USER_VIDEO},
             label: :optional,
             name: :videoSourceType,
             tag: 31,
             type: {:enum, WAWebProtobufsE2E.VideoMessage.VideoSourceType}
           }}
        end

        def field_def("videoSourceType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoSourceType",
             kind: {:scalar, :USER_VIDEO},
             label: :optional,
             name: :videoSourceType,
             tag: 31,
             type: {:enum, WAWebProtobufsE2E.VideoMessage.VideoSourceType}
           }}
        end

        []
      ),
      (
        def field_def(:dashManifestURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "dashManifestURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :dashManifestURL,
             tag: 33,
             type: :string
           }}
        end

        def field_def("dashManifestURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "dashManifestURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :dashManifestURL,
             tag: 33,
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
    def default(:URL) do
      {:ok, ""}
    end,
    def default(:mimetype) do
      {:ok, ""}
    end,
    def default(:fileSHA256) do
      {:ok, ""}
    end,
    def default(:fileLength) do
      {:ok, 0}
    end,
    def default(:seconds) do
      {:ok, 0}
    end,
    def default(:mediaKey) do
      {:ok, ""}
    end,
    def default(:caption) do
      {:ok, ""}
    end,
    def default(:gifPlayback) do
      {:ok, false}
    end,
    def default(:height) do
      {:ok, 0}
    end,
    def default(:width) do
      {:ok, 0}
    end,
    def default(:fileEncSHA256) do
      {:ok, ""}
    end,
    def default(:interactiveAnnotations) do
      {:error, :no_default_value}
    end,
    def default(:directPath) do
      {:ok, ""}
    end,
    def default(:mediaKeyTimestamp) do
      {:ok, 0}
    end,
    def default(:JPEGThumbnail) do
      {:ok, ""}
    end,
    def default(:contextInfo) do
      {:ok, nil}
    end,
    def default(:streamingSidecar) do
      {:ok, ""}
    end,
    def default(:gifAttribution) do
      {:ok, :NONE}
    end,
    def default(:viewOnce) do
      {:ok, false}
    end,
    def default(:thumbnailDirectPath) do
      {:ok, ""}
    end,
    def default(:thumbnailSHA256) do
      {:ok, ""}
    end,
    def default(:thumbnailEncSHA256) do
      {:ok, ""}
    end,
    def default(:staticURL) do
      {:ok, ""}
    end,
    def default(:annotations) do
      {:error, :no_default_value}
    end,
    def default(:accessibilityLabel) do
      {:ok, ""}
    end,
    def default(:processedVideos) do
      {:error, :no_default_value}
    end,
    def default(:externalShareFullVideoDurationInSeconds) do
      {:ok, 0}
    end,
    def default(:motionPhotoPresentationOffsetMS) do
      {:ok, 0}
    end,
    def default(:metadataURL) do
      {:ok, ""}
    end,
    def default(:videoSourceType) do
      {:ok, :USER_VIDEO}
    end,
    def default(:dashManifestURL) do
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
