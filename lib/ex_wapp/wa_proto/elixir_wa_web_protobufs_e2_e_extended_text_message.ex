# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ExtendedTextMessage do
  @moduledoc false
  defstruct text: nil,
            matchedText: nil,
            description: nil,
            title: nil,
            textArgb: nil,
            backgroundArgb: nil,
            font: nil,
            previewType: nil,
            JPEGThumbnail: nil,
            contextInfo: nil,
            doNotPlayInline: nil,
            thumbnailDirectPath: nil,
            thumbnailSHA256: nil,
            thumbnailEncSHA256: nil,
            mediaKey: nil,
            mediaKeyTimestamp: nil,
            thumbnailHeight: nil,
            thumbnailWidth: nil,
            inviteLinkGroupType: nil,
            inviteLinkParentGroupSubjectV2: nil,
            inviteLinkParentGroupThumbnailV2: nil,
            inviteLinkGroupTypeV2: nil,
            viewOnce: nil,
            videoHeight: nil,
            videoWidth: nil,
            faviconMmsMetadata: nil,
            linkPreviewMetadata: nil,
            paymentLinkMetadata: nil,
            endCardTiles: [],
            videoContentURL: nil,
            musicMetadata: nil,
            paymentExtendedMetadata: nil,
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
        |> encode_text(msg)
        |> encode_matchedText(msg)
        |> encode_description(msg)
        |> encode_title(msg)
        |> encode_textArgb(msg)
        |> encode_backgroundArgb(msg)
        |> encode_font(msg)
        |> encode_previewType(msg)
        |> encode_JPEGThumbnail(msg)
        |> encode_contextInfo(msg)
        |> encode_doNotPlayInline(msg)
        |> encode_thumbnailDirectPath(msg)
        |> encode_thumbnailSHA256(msg)
        |> encode_thumbnailEncSHA256(msg)
        |> encode_mediaKey(msg)
        |> encode_mediaKeyTimestamp(msg)
        |> encode_thumbnailHeight(msg)
        |> encode_thumbnailWidth(msg)
        |> encode_inviteLinkGroupType(msg)
        |> encode_inviteLinkParentGroupSubjectV2(msg)
        |> encode_inviteLinkParentGroupThumbnailV2(msg)
        |> encode_inviteLinkGroupTypeV2(msg)
        |> encode_viewOnce(msg)
        |> encode_videoHeight(msg)
        |> encode_videoWidth(msg)
        |> encode_faviconMmsMetadata(msg)
        |> encode_linkPreviewMetadata(msg)
        |> encode_paymentLinkMetadata(msg)
        |> encode_endCardTiles(msg)
        |> encode_videoContentURL(msg)
        |> encode_musicMetadata(msg)
        |> encode_paymentExtendedMetadata(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_text(acc, msg) do
        try do
          case msg.text do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.text)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:text, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_matchedText(acc, msg) do
        try do
          case msg.matchedText do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.matchedText)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:matchedText, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_description(acc, msg) do
        try do
          case msg.description do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.description)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:description, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_title(acc, msg) do
        try do
          case msg.title do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_string(msg.title)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:title, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_textArgb(acc, msg) do
        try do
          case msg.textArgb do
            nil -> acc
            _ -> [acc, "=", Protox.Encode.encode_fixed32(msg.textArgb)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:textArgb, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_backgroundArgb(acc, msg) do
        try do
          case msg.backgroundArgb do
            nil -> acc
            _ -> [acc, "E", Protox.Encode.encode_fixed32(msg.backgroundArgb)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:backgroundArgb, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_font(acc, msg) do
        try do
          case msg.font do
            nil ->
              acc

            _ ->
              [
                acc,
                "H",
                msg.font
                |> WAWebProtobufsE2E.ExtendedTextMessage.FontType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:font, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_previewType(acc, msg) do
        try do
          case msg.previewType do
            nil ->
              acc

            _ ->
              [
                acc,
                "P",
                msg.previewType
                |> WAWebProtobufsE2E.ExtendedTextMessage.PreviewType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:previewType, "invalid field value"), __STACKTRACE__
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
      defp encode_doNotPlayInline(acc, msg) do
        try do
          case msg.doNotPlayInline do
            nil -> acc
            _ -> [acc, "\x90\x01", Protox.Encode.encode_bool(msg.doNotPlayInline)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:doNotPlayInline, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailDirectPath(acc, msg) do
        try do
          case msg.thumbnailDirectPath do
            nil -> acc
            _ -> [acc, "\x9A\x01", Protox.Encode.encode_string(msg.thumbnailDirectPath)]
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
            _ -> [acc, "\xA2\x01", Protox.Encode.encode_bytes(msg.thumbnailSHA256)]
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
            _ -> [acc, "\xAA\x01", Protox.Encode.encode_bytes(msg.thumbnailEncSHA256)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailEncSHA256, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_mediaKey(acc, msg) do
        try do
          case msg.mediaKey do
            nil -> acc
            _ -> [acc, "\xB2\x01", Protox.Encode.encode_bytes(msg.mediaKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaKey, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaKeyTimestamp(acc, msg) do
        try do
          case msg.mediaKeyTimestamp do
            nil -> acc
            _ -> [acc, "\xB8\x01", Protox.Encode.encode_int64(msg.mediaKeyTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaKeyTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailHeight(acc, msg) do
        try do
          case msg.thumbnailHeight do
            nil -> acc
            _ -> [acc, "\xC0\x01", Protox.Encode.encode_uint32(msg.thumbnailHeight)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailHeight, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_thumbnailWidth(acc, msg) do
        try do
          case msg.thumbnailWidth do
            nil -> acc
            _ -> [acc, "\xC8\x01", Protox.Encode.encode_uint32(msg.thumbnailWidth)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailWidth, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_inviteLinkGroupType(acc, msg) do
        try do
          case msg.inviteLinkGroupType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xD0\x01",
                msg.inviteLinkGroupType
                |> WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:inviteLinkGroupType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_inviteLinkParentGroupSubjectV2(acc, msg) do
        try do
          case msg.inviteLinkParentGroupSubjectV2 do
            nil ->
              acc

            _ ->
              [acc, "\xDA\x01", Protox.Encode.encode_string(msg.inviteLinkParentGroupSubjectV2)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :inviteLinkParentGroupSubjectV2,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_inviteLinkParentGroupThumbnailV2(acc, msg) do
        try do
          case msg.inviteLinkParentGroupThumbnailV2 do
            nil ->
              acc

            _ ->
              [acc, "\xE2\x01", Protox.Encode.encode_bytes(msg.inviteLinkParentGroupThumbnailV2)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :inviteLinkParentGroupThumbnailV2,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_inviteLinkGroupTypeV2(acc, msg) do
        try do
          case msg.inviteLinkGroupTypeV2 do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xE8\x01",
                msg.inviteLinkGroupTypeV2
                |> WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:inviteLinkGroupTypeV2, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_viewOnce(acc, msg) do
        try do
          case msg.viewOnce do
            nil -> acc
            _ -> [acc, "\xF0\x01", Protox.Encode.encode_bool(msg.viewOnce)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:viewOnce, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_videoHeight(acc, msg) do
        try do
          case msg.videoHeight do
            nil -> acc
            _ -> [acc, "\xF8\x01", Protox.Encode.encode_uint32(msg.videoHeight)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:videoHeight, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_videoWidth(acc, msg) do
        try do
          case msg.videoWidth do
            nil -> acc
            _ -> [acc, "\x80\x02", Protox.Encode.encode_uint32(msg.videoWidth)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:videoWidth, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_faviconMmsMetadata(acc, msg) do
        try do
          case msg.faviconMmsMetadata do
            nil -> acc
            _ -> [acc, "\x8A\x02", Protox.Encode.encode_message(msg.faviconMmsMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:faviconMmsMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_linkPreviewMetadata(acc, msg) do
        try do
          case msg.linkPreviewMetadata do
            nil -> acc
            _ -> [acc, "\x92\x02", Protox.Encode.encode_message(msg.linkPreviewMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:linkPreviewMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_paymentLinkMetadata(acc, msg) do
        try do
          case msg.paymentLinkMetadata do
            nil -> acc
            _ -> [acc, "\x9A\x02", Protox.Encode.encode_message(msg.paymentLinkMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:paymentLinkMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_endCardTiles(acc, msg) do
        try do
          case msg.endCardTiles do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xA2\x02", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:endCardTiles, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_videoContentURL(acc, msg) do
        try do
          case msg.videoContentURL do
            nil -> acc
            _ -> [acc, "\xAA\x02", Protox.Encode.encode_string(msg.videoContentURL)]
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
            _ -> [acc, "\xB2\x02", Protox.Encode.encode_message(msg.musicMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:musicMetadata, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_paymentExtendedMetadata(acc, msg) do
        try do
          case msg.paymentExtendedMetadata do
            nil -> acc
            _ -> [acc, "\xBA\x02", Protox.Encode.encode_message(msg.paymentExtendedMetadata)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:paymentExtendedMetadata, "invalid field value"),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.ExtendedTextMessage))
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
              {[text: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[matchedText: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[description: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[title: Protox.Decode.validate_string!(delimited)], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_fixed32(bytes)
              {[textArgb: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_fixed32(bytes)
              {[backgroundArgb: value], rest}

            {9, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.ExtendedTextMessage.FontType)

              {[font: value], rest}

            {10, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsE2E.ExtendedTextMessage.PreviewType)

              {[previewType: value], rest}

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
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[doNotPlayInline: value], rest}

            {19, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnailDirectPath: Protox.Decode.validate_string!(delimited)], rest}

            {20, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnailSHA256: delimited], rest}

            {21, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnailEncSHA256: delimited], rest}

            {22, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mediaKey: delimited], rest}

            {23, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)
              {[mediaKeyTimestamp: value], rest}

            {24, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[thumbnailHeight: value], rest}

            {25, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[thumbnailWidth: value], rest}

            {26, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType
                )

              {[inviteLinkGroupType: value], rest}

            {27, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[inviteLinkParentGroupSubjectV2: Protox.Decode.validate_string!(delimited)], rest}

            {28, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[inviteLinkParentGroupThumbnailV2: delimited], rest}

            {29, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType
                )

              {[inviteLinkGroupTypeV2: value], rest}

            {30, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[viewOnce: value], rest}

            {31, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[videoHeight: value], rest}

            {32, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[videoWidth: value], rest}

            {33, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 faviconMmsMetadata:
                   Protox.MergeMessage.merge(
                     msg.faviconMmsMetadata,
                     WAWebProtobufsE2E.MMSThumbnailMetadata.decode!(delimited)
                   )
               ], rest}

            {34, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 linkPreviewMetadata:
                   Protox.MergeMessage.merge(
                     msg.linkPreviewMetadata,
                     WAWebProtobufsE2E.LinkPreviewMetadata.decode!(delimited)
                   )
               ], rest}

            {35, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 paymentLinkMetadata:
                   Protox.MergeMessage.merge(
                     msg.paymentLinkMetadata,
                     WAWebProtobufsE2E.PaymentLinkMetadata.decode!(delimited)
                   )
               ], rest}

            {36, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 endCardTiles:
                   msg.endCardTiles ++ [WAWebProtobufsE2E.VideoEndCard.decode!(delimited)]
               ], rest}

            {37, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[videoContentURL: Protox.Decode.validate_string!(delimited)], rest}

            {38, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 musicMetadata:
                   Protox.MergeMessage.merge(
                     msg.musicMetadata,
                     WAWebProtobufsE2E.EmbeddedMusic.decode!(delimited)
                   )
               ], rest}

            {39, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[
                 paymentExtendedMetadata:
                   Protox.MergeMessage.merge(
                     msg.paymentExtendedMetadata,
                     WAWebProtobufsE2E.PaymentExtendedMetadata.decode!(delimited)
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
        WAWebProtobufsE2E.ExtendedTextMessage,
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
        1 => {:text, {:scalar, ""}, :string},
        2 => {:matchedText, {:scalar, ""}, :string},
        5 => {:description, {:scalar, ""}, :string},
        6 => {:title, {:scalar, ""}, :string},
        7 => {:textArgb, {:scalar, 0}, :fixed32},
        8 => {:backgroundArgb, {:scalar, 0}, :fixed32},
        9 => {:font, {:scalar, :SYSTEM}, {:enum, WAWebProtobufsE2E.ExtendedTextMessage.FontType}},
        10 =>
          {:previewType, {:scalar, :NONE},
           {:enum, WAWebProtobufsE2E.ExtendedTextMessage.PreviewType}},
        16 => {:JPEGThumbnail, {:scalar, ""}, :bytes},
        17 => {:contextInfo, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        18 => {:doNotPlayInline, {:scalar, false}, :bool},
        19 => {:thumbnailDirectPath, {:scalar, ""}, :string},
        20 => {:thumbnailSHA256, {:scalar, ""}, :bytes},
        21 => {:thumbnailEncSHA256, {:scalar, ""}, :bytes},
        22 => {:mediaKey, {:scalar, ""}, :bytes},
        23 => {:mediaKeyTimestamp, {:scalar, 0}, :int64},
        24 => {:thumbnailHeight, {:scalar, 0}, :uint32},
        25 => {:thumbnailWidth, {:scalar, 0}, :uint32},
        26 =>
          {:inviteLinkGroupType, {:scalar, :DEFAULT},
           {:enum, WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType}},
        27 => {:inviteLinkParentGroupSubjectV2, {:scalar, ""}, :string},
        28 => {:inviteLinkParentGroupThumbnailV2, {:scalar, ""}, :bytes},
        29 =>
          {:inviteLinkGroupTypeV2, {:scalar, :DEFAULT},
           {:enum, WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType}},
        30 => {:viewOnce, {:scalar, false}, :bool},
        31 => {:videoHeight, {:scalar, 0}, :uint32},
        32 => {:videoWidth, {:scalar, 0}, :uint32},
        33 =>
          {:faviconMmsMetadata, {:scalar, nil},
           {:message, WAWebProtobufsE2E.MMSThumbnailMetadata}},
        34 =>
          {:linkPreviewMetadata, {:scalar, nil},
           {:message, WAWebProtobufsE2E.LinkPreviewMetadata}},
        35 =>
          {:paymentLinkMetadata, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PaymentLinkMetadata}},
        36 => {:endCardTiles, :unpacked, {:message, WAWebProtobufsE2E.VideoEndCard}},
        37 => {:videoContentURL, {:scalar, ""}, :string},
        38 => {:musicMetadata, {:scalar, nil}, {:message, WAWebProtobufsE2E.EmbeddedMusic}},
        39 =>
          {:paymentExtendedMetadata, {:scalar, nil},
           {:message, WAWebProtobufsE2E.PaymentExtendedMetadata}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        JPEGThumbnail: {16, {:scalar, ""}, :bytes},
        backgroundArgb: {8, {:scalar, 0}, :fixed32},
        contextInfo: {17, {:scalar, nil}, {:message, WAWebProtobufsE2E.ContextInfo}},
        description: {5, {:scalar, ""}, :string},
        doNotPlayInline: {18, {:scalar, false}, :bool},
        endCardTiles: {36, :unpacked, {:message, WAWebProtobufsE2E.VideoEndCard}},
        faviconMmsMetadata:
          {33, {:scalar, nil}, {:message, WAWebProtobufsE2E.MMSThumbnailMetadata}},
        font: {9, {:scalar, :SYSTEM}, {:enum, WAWebProtobufsE2E.ExtendedTextMessage.FontType}},
        inviteLinkGroupType:
          {26, {:scalar, :DEFAULT},
           {:enum, WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType}},
        inviteLinkGroupTypeV2:
          {29, {:scalar, :DEFAULT},
           {:enum, WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType}},
        inviteLinkParentGroupSubjectV2: {27, {:scalar, ""}, :string},
        inviteLinkParentGroupThumbnailV2: {28, {:scalar, ""}, :bytes},
        linkPreviewMetadata:
          {34, {:scalar, nil}, {:message, WAWebProtobufsE2E.LinkPreviewMetadata}},
        matchedText: {2, {:scalar, ""}, :string},
        mediaKey: {22, {:scalar, ""}, :bytes},
        mediaKeyTimestamp: {23, {:scalar, 0}, :int64},
        musicMetadata: {38, {:scalar, nil}, {:message, WAWebProtobufsE2E.EmbeddedMusic}},
        paymentExtendedMetadata:
          {39, {:scalar, nil}, {:message, WAWebProtobufsE2E.PaymentExtendedMetadata}},
        paymentLinkMetadata:
          {35, {:scalar, nil}, {:message, WAWebProtobufsE2E.PaymentLinkMetadata}},
        previewType:
          {10, {:scalar, :NONE}, {:enum, WAWebProtobufsE2E.ExtendedTextMessage.PreviewType}},
        text: {1, {:scalar, ""}, :string},
        textArgb: {7, {:scalar, 0}, :fixed32},
        thumbnailDirectPath: {19, {:scalar, ""}, :string},
        thumbnailEncSHA256: {21, {:scalar, ""}, :bytes},
        thumbnailHeight: {24, {:scalar, 0}, :uint32},
        thumbnailSHA256: {20, {:scalar, ""}, :bytes},
        thumbnailWidth: {25, {:scalar, 0}, :uint32},
        title: {6, {:scalar, ""}, :string},
        videoContentURL: {37, {:scalar, ""}, :string},
        videoHeight: {31, {:scalar, 0}, :uint32},
        videoWidth: {32, {:scalar, 0}, :uint32},
        viewOnce: {30, {:scalar, false}, :bool}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "text",
          kind: {:scalar, ""},
          label: :optional,
          name: :text,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "matchedText",
          kind: {:scalar, ""},
          label: :optional,
          name: :matchedText,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "description",
          kind: {:scalar, ""},
          label: :optional,
          name: :description,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "title",
          kind: {:scalar, ""},
          label: :optional,
          name: :title,
          tag: 6,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "textArgb",
          kind: {:scalar, 0},
          label: :optional,
          name: :textArgb,
          tag: 7,
          type: :fixed32
        },
        %{
          __struct__: Protox.Field,
          json_name: "backgroundArgb",
          kind: {:scalar, 0},
          label: :optional,
          name: :backgroundArgb,
          tag: 8,
          type: :fixed32
        },
        %{
          __struct__: Protox.Field,
          json_name: "font",
          kind: {:scalar, :SYSTEM},
          label: :optional,
          name: :font,
          tag: 9,
          type: {:enum, WAWebProtobufsE2E.ExtendedTextMessage.FontType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "previewType",
          kind: {:scalar, :NONE},
          label: :optional,
          name: :previewType,
          tag: 10,
          type: {:enum, WAWebProtobufsE2E.ExtendedTextMessage.PreviewType}
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
          json_name: "doNotPlayInline",
          kind: {:scalar, false},
          label: :optional,
          name: :doNotPlayInline,
          tag: 18,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailDirectPath",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailDirectPath,
          tag: 19,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailSHA256,
          tag: 20,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailEncSHA256",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailEncSHA256,
          tag: 21,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :mediaKey,
          tag: 22,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaKeyTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :mediaKeyTimestamp,
          tag: 23,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailHeight",
          kind: {:scalar, 0},
          label: :optional,
          name: :thumbnailHeight,
          tag: 24,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailWidth",
          kind: {:scalar, 0},
          label: :optional,
          name: :thumbnailWidth,
          tag: 25,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "inviteLinkGroupType",
          kind: {:scalar, :DEFAULT},
          label: :optional,
          name: :inviteLinkGroupType,
          tag: 26,
          type: {:enum, WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "inviteLinkParentGroupSubjectV2",
          kind: {:scalar, ""},
          label: :optional,
          name: :inviteLinkParentGroupSubjectV2,
          tag: 27,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "inviteLinkParentGroupThumbnailV2",
          kind: {:scalar, ""},
          label: :optional,
          name: :inviteLinkParentGroupThumbnailV2,
          tag: 28,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "inviteLinkGroupTypeV2",
          kind: {:scalar, :DEFAULT},
          label: :optional,
          name: :inviteLinkGroupTypeV2,
          tag: 29,
          type: {:enum, WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "viewOnce",
          kind: {:scalar, false},
          label: :optional,
          name: :viewOnce,
          tag: 30,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "videoHeight",
          kind: {:scalar, 0},
          label: :optional,
          name: :videoHeight,
          tag: 31,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "videoWidth",
          kind: {:scalar, 0},
          label: :optional,
          name: :videoWidth,
          tag: 32,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "faviconMmsMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :faviconMmsMetadata,
          tag: 33,
          type: {:message, WAWebProtobufsE2E.MMSThumbnailMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "linkPreviewMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :linkPreviewMetadata,
          tag: 34,
          type: {:message, WAWebProtobufsE2E.LinkPreviewMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "paymentLinkMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :paymentLinkMetadata,
          tag: 35,
          type: {:message, WAWebProtobufsE2E.PaymentLinkMetadata}
        },
        %{
          __struct__: Protox.Field,
          json_name: "endCardTiles",
          kind: :unpacked,
          label: :repeated,
          name: :endCardTiles,
          tag: 36,
          type: {:message, WAWebProtobufsE2E.VideoEndCard}
        },
        %{
          __struct__: Protox.Field,
          json_name: "videoContentURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :videoContentURL,
          tag: 37,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "musicMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :musicMetadata,
          tag: 38,
          type: {:message, WAWebProtobufsE2E.EmbeddedMusic}
        },
        %{
          __struct__: Protox.Field,
          json_name: "paymentExtendedMetadata",
          kind: {:scalar, nil},
          label: :optional,
          name: :paymentExtendedMetadata,
          tag: 39,
          type: {:message, WAWebProtobufsE2E.PaymentExtendedMetadata}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:text) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "text",
             kind: {:scalar, ""},
             label: :optional,
             name: :text,
             tag: 1,
             type: :string
           }}
        end

        def field_def("text") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "text",
             kind: {:scalar, ""},
             label: :optional,
             name: :text,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:matchedText) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "matchedText",
             kind: {:scalar, ""},
             label: :optional,
             name: :matchedText,
             tag: 2,
             type: :string
           }}
        end

        def field_def("matchedText") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "matchedText",
             kind: {:scalar, ""},
             label: :optional,
             name: :matchedText,
             tag: 2,
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
             tag: 5,
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
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:title) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "title",
             kind: {:scalar, ""},
             label: :optional,
             name: :title,
             tag: 6,
             type: :string
           }}
        end

        def field_def("title") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "title",
             kind: {:scalar, ""},
             label: :optional,
             name: :title,
             tag: 6,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:textArgb) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "textArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :textArgb,
             tag: 7,
             type: :fixed32
           }}
        end

        def field_def("textArgb") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "textArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :textArgb,
             tag: 7,
             type: :fixed32
           }}
        end

        []
      ),
      (
        def field_def(:backgroundArgb) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "backgroundArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :backgroundArgb,
             tag: 8,
             type: :fixed32
           }}
        end

        def field_def("backgroundArgb") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "backgroundArgb",
             kind: {:scalar, 0},
             label: :optional,
             name: :backgroundArgb,
             tag: 8,
             type: :fixed32
           }}
        end

        []
      ),
      (
        def field_def(:font) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "font",
             kind: {:scalar, :SYSTEM},
             label: :optional,
             name: :font,
             tag: 9,
             type: {:enum, WAWebProtobufsE2E.ExtendedTextMessage.FontType}
           }}
        end

        def field_def("font") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "font",
             kind: {:scalar, :SYSTEM},
             label: :optional,
             name: :font,
             tag: 9,
             type: {:enum, WAWebProtobufsE2E.ExtendedTextMessage.FontType}
           }}
        end

        []
      ),
      (
        def field_def(:previewType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "previewType",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :previewType,
             tag: 10,
             type: {:enum, WAWebProtobufsE2E.ExtendedTextMessage.PreviewType}
           }}
        end

        def field_def("previewType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "previewType",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :previewType,
             tag: 10,
             type: {:enum, WAWebProtobufsE2E.ExtendedTextMessage.PreviewType}
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
        def field_def(:doNotPlayInline) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "doNotPlayInline",
             kind: {:scalar, false},
             label: :optional,
             name: :doNotPlayInline,
             tag: 18,
             type: :bool
           }}
        end

        def field_def("doNotPlayInline") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "doNotPlayInline",
             kind: {:scalar, false},
             label: :optional,
             name: :doNotPlayInline,
             tag: 18,
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
             tag: 19,
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
             tag: 19,
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
             tag: 20,
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
             tag: 20,
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
             tag: 21,
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
             tag: 21,
             type: :bytes
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
             tag: 22,
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
             tag: 22,
             type: :bytes
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
             tag: 23,
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
             tag: 23,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailHeight) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailHeight",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailHeight,
             tag: 24,
             type: :uint32
           }}
        end

        def field_def("thumbnailHeight") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailHeight",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailHeight,
             tag: 24,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailWidth) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailWidth",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailWidth,
             tag: 25,
             type: :uint32
           }}
        end

        def field_def("thumbnailWidth") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailWidth",
             kind: {:scalar, 0},
             label: :optional,
             name: :thumbnailWidth,
             tag: 25,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:inviteLinkGroupType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inviteLinkGroupType",
             kind: {:scalar, :DEFAULT},
             label: :optional,
             name: :inviteLinkGroupType,
             tag: 26,
             type: {:enum, WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType}
           }}
        end

        def field_def("inviteLinkGroupType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inviteLinkGroupType",
             kind: {:scalar, :DEFAULT},
             label: :optional,
             name: :inviteLinkGroupType,
             tag: 26,
             type: {:enum, WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType}
           }}
        end

        []
      ),
      (
        def field_def(:inviteLinkParentGroupSubjectV2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inviteLinkParentGroupSubjectV2",
             kind: {:scalar, ""},
             label: :optional,
             name: :inviteLinkParentGroupSubjectV2,
             tag: 27,
             type: :string
           }}
        end

        def field_def("inviteLinkParentGroupSubjectV2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inviteLinkParentGroupSubjectV2",
             kind: {:scalar, ""},
             label: :optional,
             name: :inviteLinkParentGroupSubjectV2,
             tag: 27,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:inviteLinkParentGroupThumbnailV2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inviteLinkParentGroupThumbnailV2",
             kind: {:scalar, ""},
             label: :optional,
             name: :inviteLinkParentGroupThumbnailV2,
             tag: 28,
             type: :bytes
           }}
        end

        def field_def("inviteLinkParentGroupThumbnailV2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inviteLinkParentGroupThumbnailV2",
             kind: {:scalar, ""},
             label: :optional,
             name: :inviteLinkParentGroupThumbnailV2,
             tag: 28,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:inviteLinkGroupTypeV2) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inviteLinkGroupTypeV2",
             kind: {:scalar, :DEFAULT},
             label: :optional,
             name: :inviteLinkGroupTypeV2,
             tag: 29,
             type: {:enum, WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType}
           }}
        end

        def field_def("inviteLinkGroupTypeV2") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "inviteLinkGroupTypeV2",
             kind: {:scalar, :DEFAULT},
             label: :optional,
             name: :inviteLinkGroupTypeV2,
             tag: 29,
             type: {:enum, WAWebProtobufsE2E.ExtendedTextMessage.InviteLinkGroupType}
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
             tag: 30,
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
             tag: 30,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:videoHeight) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoHeight",
             kind: {:scalar, 0},
             label: :optional,
             name: :videoHeight,
             tag: 31,
             type: :uint32
           }}
        end

        def field_def("videoHeight") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoHeight",
             kind: {:scalar, 0},
             label: :optional,
             name: :videoHeight,
             tag: 31,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:videoWidth) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoWidth",
             kind: {:scalar, 0},
             label: :optional,
             name: :videoWidth,
             tag: 32,
             type: :uint32
           }}
        end

        def field_def("videoWidth") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "videoWidth",
             kind: {:scalar, 0},
             label: :optional,
             name: :videoWidth,
             tag: 32,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:faviconMmsMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "faviconMmsMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :faviconMmsMetadata,
             tag: 33,
             type: {:message, WAWebProtobufsE2E.MMSThumbnailMetadata}
           }}
        end

        def field_def("faviconMmsMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "faviconMmsMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :faviconMmsMetadata,
             tag: 33,
             type: {:message, WAWebProtobufsE2E.MMSThumbnailMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:linkPreviewMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "linkPreviewMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :linkPreviewMetadata,
             tag: 34,
             type: {:message, WAWebProtobufsE2E.LinkPreviewMetadata}
           }}
        end

        def field_def("linkPreviewMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "linkPreviewMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :linkPreviewMetadata,
             tag: 34,
             type: {:message, WAWebProtobufsE2E.LinkPreviewMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:paymentLinkMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentLinkMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentLinkMetadata,
             tag: 35,
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
             tag: 35,
             type: {:message, WAWebProtobufsE2E.PaymentLinkMetadata}
           }}
        end

        []
      ),
      (
        def field_def(:endCardTiles) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "endCardTiles",
             kind: :unpacked,
             label: :repeated,
             name: :endCardTiles,
             tag: 36,
             type: {:message, WAWebProtobufsE2E.VideoEndCard}
           }}
        end

        def field_def("endCardTiles") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "endCardTiles",
             kind: :unpacked,
             label: :repeated,
             name: :endCardTiles,
             tag: 36,
             type: {:message, WAWebProtobufsE2E.VideoEndCard}
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
             tag: 37,
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
             tag: 37,
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
             tag: 38,
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
             tag: 38,
             type: {:message, WAWebProtobufsE2E.EmbeddedMusic}
           }}
        end

        []
      ),
      (
        def field_def(:paymentExtendedMetadata) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentExtendedMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentExtendedMetadata,
             tag: 39,
             type: {:message, WAWebProtobufsE2E.PaymentExtendedMetadata}
           }}
        end

        def field_def("paymentExtendedMetadata") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "paymentExtendedMetadata",
             kind: {:scalar, nil},
             label: :optional,
             name: :paymentExtendedMetadata,
             tag: 39,
             type: {:message, WAWebProtobufsE2E.PaymentExtendedMetadata}
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
    def default(:text) do
      {:ok, ""}
    end,
    def default(:matchedText) do
      {:ok, ""}
    end,
    def default(:description) do
      {:ok, ""}
    end,
    def default(:title) do
      {:ok, ""}
    end,
    def default(:textArgb) do
      {:ok, 0}
    end,
    def default(:backgroundArgb) do
      {:ok, 0}
    end,
    def default(:font) do
      {:ok, :SYSTEM}
    end,
    def default(:previewType) do
      {:ok, :NONE}
    end,
    def default(:JPEGThumbnail) do
      {:ok, ""}
    end,
    def default(:contextInfo) do
      {:ok, nil}
    end,
    def default(:doNotPlayInline) do
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
    def default(:mediaKey) do
      {:ok, ""}
    end,
    def default(:mediaKeyTimestamp) do
      {:ok, 0}
    end,
    def default(:thumbnailHeight) do
      {:ok, 0}
    end,
    def default(:thumbnailWidth) do
      {:ok, 0}
    end,
    def default(:inviteLinkGroupType) do
      {:ok, :DEFAULT}
    end,
    def default(:inviteLinkParentGroupSubjectV2) do
      {:ok, ""}
    end,
    def default(:inviteLinkParentGroupThumbnailV2) do
      {:ok, ""}
    end,
    def default(:inviteLinkGroupTypeV2) do
      {:ok, :DEFAULT}
    end,
    def default(:viewOnce) do
      {:ok, false}
    end,
    def default(:videoHeight) do
      {:ok, 0}
    end,
    def default(:videoWidth) do
      {:ok, 0}
    end,
    def default(:faviconMmsMetadata) do
      {:ok, nil}
    end,
    def default(:linkPreviewMetadata) do
      {:ok, nil}
    end,
    def default(:paymentLinkMetadata) do
      {:ok, nil}
    end,
    def default(:endCardTiles) do
      {:error, :no_default_value}
    end,
    def default(:videoContentURL) do
      {:ok, ""}
    end,
    def default(:musicMetadata) do
      {:ok, nil}
    end,
    def default(:paymentExtendedMetadata) do
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
