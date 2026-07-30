# credo:disable-for-this-file
defmodule WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo do
  @moduledoc false
  defstruct title: nil,
            body: nil,
            mediaType: nil,
            thumbnailURL: nil,
            mediaURL: nil,
            thumbnail: nil,
            sourceType: nil,
            sourceID: nil,
            sourceURL: nil,
            containsAutoReply: nil,
            renderLargerThumbnail: nil,
            showAdAttribution: nil,
            ctwaClid: nil,
            ref: nil,
            clickToWhatsappCall: nil,
            adContextPreviewDismissed: nil,
            sourceApp: nil,
            automatedGreetingMessageShown: nil,
            greetingMessageBody: nil,
            ctaPayload: nil,
            disableNudge: nil,
            originalImageURL: nil,
            automatedGreetingMessageCtaType: nil,
            wtwaAdFormat: nil,
            adType: nil,
            wtwaWebsiteURL: nil,
            adPreviewURL: nil,
            containsCtwaFlowsAutoReply: nil,
            agmThumbnailStrategy: nil,
            agmTitleStrategy: nil,
            agmSubtitleStrategy: nil,
            agmHeaderInteractionStrategy: nil,
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
        |> encode_title(msg)
        |> encode_body(msg)
        |> encode_mediaType(msg)
        |> encode_thumbnailURL(msg)
        |> encode_mediaURL(msg)
        |> encode_thumbnail(msg)
        |> encode_sourceType(msg)
        |> encode_sourceID(msg)
        |> encode_sourceURL(msg)
        |> encode_containsAutoReply(msg)
        |> encode_renderLargerThumbnail(msg)
        |> encode_showAdAttribution(msg)
        |> encode_ctwaClid(msg)
        |> encode_ref(msg)
        |> encode_clickToWhatsappCall(msg)
        |> encode_adContextPreviewDismissed(msg)
        |> encode_sourceApp(msg)
        |> encode_automatedGreetingMessageShown(msg)
        |> encode_greetingMessageBody(msg)
        |> encode_ctaPayload(msg)
        |> encode_disableNudge(msg)
        |> encode_originalImageURL(msg)
        |> encode_automatedGreetingMessageCtaType(msg)
        |> encode_wtwaAdFormat(msg)
        |> encode_adType(msg)
        |> encode_wtwaWebsiteURL(msg)
        |> encode_adPreviewURL(msg)
        |> encode_containsCtwaFlowsAutoReply(msg)
        |> encode_agmThumbnailStrategy(msg)
        |> encode_agmTitleStrategy(msg)
        |> encode_agmSubtitleStrategy(msg)
        |> encode_agmHeaderInteractionStrategy(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_title(acc, msg) do
        try do
          case msg.title do
            nil -> acc
            _ -> [acc, "\n", Protox.Encode.encode_string(msg.title)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:title, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_body(acc, msg) do
        try do
          case msg.body do
            nil -> acc
            _ -> [acc, "\x12", Protox.Encode.encode_string(msg.body)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:body, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaType(acc, msg) do
        try do
          case msg.mediaType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\x18",
                msg.mediaType
                |> WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.MediaType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_thumbnailURL(acc, msg) do
        try do
          case msg.thumbnailURL do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.thumbnailURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnailURL, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaURL(acc, msg) do
        try do
          case msg.mediaURL do
            nil -> acc
            _ -> [acc, "*", Protox.Encode.encode_string(msg.mediaURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaURL, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_thumbnail(acc, msg) do
        try do
          case msg.thumbnail do
            nil -> acc
            _ -> [acc, "2", Protox.Encode.encode_bytes(msg.thumbnail)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:thumbnail, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_sourceType(acc, msg) do
        try do
          case msg.sourceType do
            nil -> acc
            _ -> [acc, ":", Protox.Encode.encode_string(msg.sourceType)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:sourceType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_sourceID(acc, msg) do
        try do
          case msg.sourceID do
            nil -> acc
            _ -> [acc, "B", Protox.Encode.encode_string(msg.sourceID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:sourceID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_sourceURL(acc, msg) do
        try do
          case msg.sourceURL do
            nil -> acc
            _ -> [acc, "J", Protox.Encode.encode_string(msg.sourceURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:sourceURL, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_containsAutoReply(acc, msg) do
        try do
          case msg.containsAutoReply do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_bool(msg.containsAutoReply)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:containsAutoReply, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_renderLargerThumbnail(acc, msg) do
        try do
          case msg.renderLargerThumbnail do
            nil -> acc
            _ -> [acc, "X", Protox.Encode.encode_bool(msg.renderLargerThumbnail)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:renderLargerThumbnail, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_showAdAttribution(acc, msg) do
        try do
          case msg.showAdAttribution do
            nil -> acc
            _ -> [acc, "`", Protox.Encode.encode_bool(msg.showAdAttribution)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:showAdAttribution, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ctwaClid(acc, msg) do
        try do
          case msg.ctwaClid do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_string(msg.ctwaClid)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ctwaClid, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_ref(acc, msg) do
        try do
          case msg.ref do
            nil -> acc
            _ -> [acc, "r", Protox.Encode.encode_string(msg.ref)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ref, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_clickToWhatsappCall(acc, msg) do
        try do
          case msg.clickToWhatsappCall do
            nil -> acc
            _ -> [acc, "x", Protox.Encode.encode_bool(msg.clickToWhatsappCall)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:clickToWhatsappCall, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_adContextPreviewDismissed(acc, msg) do
        try do
          case msg.adContextPreviewDismissed do
            nil -> acc
            _ -> [acc, "\x80\x01", Protox.Encode.encode_bool(msg.adContextPreviewDismissed)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:adContextPreviewDismissed, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_sourceApp(acc, msg) do
        try do
          case msg.sourceApp do
            nil -> acc
            _ -> [acc, "\x8A\x01", Protox.Encode.encode_string(msg.sourceApp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:sourceApp, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_automatedGreetingMessageShown(acc, msg) do
        try do
          case msg.automatedGreetingMessageShown do
            nil -> acc
            _ -> [acc, "\x90\x01", Protox.Encode.encode_bool(msg.automatedGreetingMessageShown)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :automatedGreetingMessageShown,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_greetingMessageBody(acc, msg) do
        try do
          case msg.greetingMessageBody do
            nil -> acc
            _ -> [acc, "\x9A\x01", Protox.Encode.encode_string(msg.greetingMessageBody)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:greetingMessageBody, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ctaPayload(acc, msg) do
        try do
          case msg.ctaPayload do
            nil -> acc
            _ -> [acc, "\xA2\x01", Protox.Encode.encode_string(msg.ctaPayload)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ctaPayload, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_disableNudge(acc, msg) do
        try do
          case msg.disableNudge do
            nil -> acc
            _ -> [acc, "\xA8\x01", Protox.Encode.encode_bool(msg.disableNudge)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:disableNudge, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_originalImageURL(acc, msg) do
        try do
          case msg.originalImageURL do
            nil -> acc
            _ -> [acc, "\xB2\x01", Protox.Encode.encode_string(msg.originalImageURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:originalImageURL, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_automatedGreetingMessageCtaType(acc, msg) do
        try do
          case msg.automatedGreetingMessageCtaType do
            nil ->
              acc

            _ ->
              [acc, "\xBA\x01", Protox.Encode.encode_string(msg.automatedGreetingMessageCtaType)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :automatedGreetingMessageCtaType,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_wtwaAdFormat(acc, msg) do
        try do
          case msg.wtwaAdFormat do
            nil -> acc
            _ -> [acc, "\xC0\x01", Protox.Encode.encode_bool(msg.wtwaAdFormat)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:wtwaAdFormat, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_adType(acc, msg) do
        try do
          case msg.adType do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xC8\x01",
                msg.adType
                |> WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.AdType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:adType, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_wtwaWebsiteURL(acc, msg) do
        try do
          case msg.wtwaWebsiteURL do
            nil -> acc
            _ -> [acc, "\xD2\x01", Protox.Encode.encode_string(msg.wtwaWebsiteURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:wtwaWebsiteURL, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_adPreviewURL(acc, msg) do
        try do
          case msg.adPreviewURL do
            nil -> acc
            _ -> [acc, "\xDA\x01", Protox.Encode.encode_string(msg.adPreviewURL)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:adPreviewURL, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_containsCtwaFlowsAutoReply(acc, msg) do
        try do
          case msg.containsCtwaFlowsAutoReply do
            nil -> acc
            _ -> [acc, "\xE0\x01", Protox.Encode.encode_bool(msg.containsCtwaFlowsAutoReply)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:containsCtwaFlowsAutoReply, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_agmThumbnailStrategy(acc, msg) do
        try do
          case msg.agmThumbnailStrategy do
            nil -> acc
            _ -> [acc, "\xE8\x01", Protox.Encode.encode_int32(msg.agmThumbnailStrategy)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:agmThumbnailStrategy, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_agmTitleStrategy(acc, msg) do
        try do
          case msg.agmTitleStrategy do
            nil -> acc
            _ -> [acc, "\xF0\x01", Protox.Encode.encode_int32(msg.agmTitleStrategy)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:agmTitleStrategy, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_agmSubtitleStrategy(acc, msg) do
        try do
          case msg.agmSubtitleStrategy do
            nil -> acc
            _ -> [acc, "\xF8\x01", Protox.Encode.encode_int32(msg.agmSubtitleStrategy)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:agmSubtitleStrategy, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_agmHeaderInteractionStrategy(acc, msg) do
        try do
          case msg.agmHeaderInteractionStrategy do
            nil -> acc
            _ -> [acc, "\x80\x02", Protox.Encode.encode_int32(msg.agmHeaderInteractionStrategy)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :agmHeaderInteractionStrategy,
                      "invalid field value"
                    ),
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
          parse_key_value(bytes, struct(WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo))
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
              {[title: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[body: Protox.Decode.validate_string!(delimited)], rest}

            {3, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.MediaType
                )

              {[mediaType: value], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnailURL: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[mediaURL: Protox.Decode.validate_string!(delimited)], rest}

            {6, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[thumbnail: delimited], rest}

            {7, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[sourceType: Protox.Decode.validate_string!(delimited)], rest}

            {8, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[sourceID: Protox.Decode.validate_string!(delimited)], rest}

            {9, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[sourceURL: Protox.Decode.validate_string!(delimited)], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[containsAutoReply: value], rest}

            {11, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[renderLargerThumbnail: value], rest}

            {12, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[showAdAttribution: value], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[ctwaClid: Protox.Decode.validate_string!(delimited)], rest}

            {14, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[ref: Protox.Decode.validate_string!(delimited)], rest}

            {15, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[clickToWhatsappCall: value], rest}

            {16, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[adContextPreviewDismissed: value], rest}

            {17, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[sourceApp: Protox.Decode.validate_string!(delimited)], rest}

            {18, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[automatedGreetingMessageShown: value], rest}

            {19, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[greetingMessageBody: Protox.Decode.validate_string!(delimited)], rest}

            {20, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[ctaPayload: Protox.Decode.validate_string!(delimited)], rest}

            {21, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[disableNudge: value], rest}

            {22, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[originalImageURL: Protox.Decode.validate_string!(delimited)], rest}

            {23, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[automatedGreetingMessageCtaType: Protox.Decode.validate_string!(delimited)], rest}

            {24, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[wtwaAdFormat: value], rest}

            {25, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.AdType
                )

              {[adType: value], rest}

            {26, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[wtwaWebsiteURL: Protox.Decode.validate_string!(delimited)], rest}

            {27, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[adPreviewURL: Protox.Decode.validate_string!(delimited)], rest}

            {28, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[containsCtwaFlowsAutoReply: value], rest}

            {29, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[agmThumbnailStrategy: value], rest}

            {30, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[agmTitleStrategy: value], rest}

            {31, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[agmSubtitleStrategy: value], rest}

            {32, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int32(bytes)
              {[agmHeaderInteractionStrategy: value], rest}

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
        WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo,
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
        1 => {:title, {:scalar, ""}, :string},
        2 => {:body, {:scalar, ""}, :string},
        3 =>
          {:mediaType, {:scalar, :NONE},
           {:enum, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.MediaType}},
        4 => {:thumbnailURL, {:scalar, ""}, :string},
        5 => {:mediaURL, {:scalar, ""}, :string},
        6 => {:thumbnail, {:scalar, ""}, :bytes},
        7 => {:sourceType, {:scalar, ""}, :string},
        8 => {:sourceID, {:scalar, ""}, :string},
        9 => {:sourceURL, {:scalar, ""}, :string},
        10 => {:containsAutoReply, {:scalar, false}, :bool},
        11 => {:renderLargerThumbnail, {:scalar, false}, :bool},
        12 => {:showAdAttribution, {:scalar, false}, :bool},
        13 => {:ctwaClid, {:scalar, ""}, :string},
        14 => {:ref, {:scalar, ""}, :string},
        15 => {:clickToWhatsappCall, {:scalar, false}, :bool},
        16 => {:adContextPreviewDismissed, {:scalar, false}, :bool},
        17 => {:sourceApp, {:scalar, ""}, :string},
        18 => {:automatedGreetingMessageShown, {:scalar, false}, :bool},
        19 => {:greetingMessageBody, {:scalar, ""}, :string},
        20 => {:ctaPayload, {:scalar, ""}, :string},
        21 => {:disableNudge, {:scalar, false}, :bool},
        22 => {:originalImageURL, {:scalar, ""}, :string},
        23 => {:automatedGreetingMessageCtaType, {:scalar, ""}, :string},
        24 => {:wtwaAdFormat, {:scalar, false}, :bool},
        25 =>
          {:adType, {:scalar, :CTWA},
           {:enum, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.AdType}},
        26 => {:wtwaWebsiteURL, {:scalar, ""}, :string},
        27 => {:adPreviewURL, {:scalar, ""}, :string},
        28 => {:containsCtwaFlowsAutoReply, {:scalar, false}, :bool},
        29 => {:agmThumbnailStrategy, {:scalar, 0}, :int32},
        30 => {:agmTitleStrategy, {:scalar, 0}, :int32},
        31 => {:agmSubtitleStrategy, {:scalar, 0}, :int32},
        32 => {:agmHeaderInteractionStrategy, {:scalar, 0}, :int32}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        adContextPreviewDismissed: {16, {:scalar, false}, :bool},
        adPreviewURL: {27, {:scalar, ""}, :string},
        adType:
          {25, {:scalar, :CTWA},
           {:enum, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.AdType}},
        agmHeaderInteractionStrategy: {32, {:scalar, 0}, :int32},
        agmSubtitleStrategy: {31, {:scalar, 0}, :int32},
        agmThumbnailStrategy: {29, {:scalar, 0}, :int32},
        agmTitleStrategy: {30, {:scalar, 0}, :int32},
        automatedGreetingMessageCtaType: {23, {:scalar, ""}, :string},
        automatedGreetingMessageShown: {18, {:scalar, false}, :bool},
        body: {2, {:scalar, ""}, :string},
        clickToWhatsappCall: {15, {:scalar, false}, :bool},
        containsAutoReply: {10, {:scalar, false}, :bool},
        containsCtwaFlowsAutoReply: {28, {:scalar, false}, :bool},
        ctaPayload: {20, {:scalar, ""}, :string},
        ctwaClid: {13, {:scalar, ""}, :string},
        disableNudge: {21, {:scalar, false}, :bool},
        greetingMessageBody: {19, {:scalar, ""}, :string},
        mediaType:
          {3, {:scalar, :NONE},
           {:enum, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.MediaType}},
        mediaURL: {5, {:scalar, ""}, :string},
        originalImageURL: {22, {:scalar, ""}, :string},
        ref: {14, {:scalar, ""}, :string},
        renderLargerThumbnail: {11, {:scalar, false}, :bool},
        showAdAttribution: {12, {:scalar, false}, :bool},
        sourceApp: {17, {:scalar, ""}, :string},
        sourceID: {8, {:scalar, ""}, :string},
        sourceType: {7, {:scalar, ""}, :string},
        sourceURL: {9, {:scalar, ""}, :string},
        thumbnail: {6, {:scalar, ""}, :bytes},
        thumbnailURL: {4, {:scalar, ""}, :string},
        title: {1, {:scalar, ""}, :string},
        wtwaAdFormat: {24, {:scalar, false}, :bool},
        wtwaWebsiteURL: {26, {:scalar, ""}, :string}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "title",
          kind: {:scalar, ""},
          label: :optional,
          name: :title,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "body",
          kind: {:scalar, ""},
          label: :optional,
          name: :body,
          tag: 2,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaType",
          kind: {:scalar, :NONE},
          label: :optional,
          name: :mediaType,
          tag: 3,
          type: {:enum, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.MediaType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnailURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnailURL,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :mediaURL,
          tag: 5,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "thumbnail",
          kind: {:scalar, ""},
          label: :optional,
          name: :thumbnail,
          tag: 6,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "sourceType",
          kind: {:scalar, ""},
          label: :optional,
          name: :sourceType,
          tag: 7,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "sourceID",
          kind: {:scalar, ""},
          label: :optional,
          name: :sourceID,
          tag: 8,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "sourceURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :sourceURL,
          tag: 9,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "containsAutoReply",
          kind: {:scalar, false},
          label: :optional,
          name: :containsAutoReply,
          tag: 10,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "renderLargerThumbnail",
          kind: {:scalar, false},
          label: :optional,
          name: :renderLargerThumbnail,
          tag: 11,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "showAdAttribution",
          kind: {:scalar, false},
          label: :optional,
          name: :showAdAttribution,
          tag: 12,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "ctwaClid",
          kind: {:scalar, ""},
          label: :optional,
          name: :ctwaClid,
          tag: 13,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "ref",
          kind: {:scalar, ""},
          label: :optional,
          name: :ref,
          tag: 14,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "clickToWhatsappCall",
          kind: {:scalar, false},
          label: :optional,
          name: :clickToWhatsappCall,
          tag: 15,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "adContextPreviewDismissed",
          kind: {:scalar, false},
          label: :optional,
          name: :adContextPreviewDismissed,
          tag: 16,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "sourceApp",
          kind: {:scalar, ""},
          label: :optional,
          name: :sourceApp,
          tag: 17,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "automatedGreetingMessageShown",
          kind: {:scalar, false},
          label: :optional,
          name: :automatedGreetingMessageShown,
          tag: 18,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "greetingMessageBody",
          kind: {:scalar, ""},
          label: :optional,
          name: :greetingMessageBody,
          tag: 19,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "ctaPayload",
          kind: {:scalar, ""},
          label: :optional,
          name: :ctaPayload,
          tag: 20,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "disableNudge",
          kind: {:scalar, false},
          label: :optional,
          name: :disableNudge,
          tag: 21,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "originalImageURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :originalImageURL,
          tag: 22,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "automatedGreetingMessageCtaType",
          kind: {:scalar, ""},
          label: :optional,
          name: :automatedGreetingMessageCtaType,
          tag: 23,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "wtwaAdFormat",
          kind: {:scalar, false},
          label: :optional,
          name: :wtwaAdFormat,
          tag: 24,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "adType",
          kind: {:scalar, :CTWA},
          label: :optional,
          name: :adType,
          tag: 25,
          type: {:enum, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.AdType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "wtwaWebsiteURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :wtwaWebsiteURL,
          tag: 26,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "adPreviewURL",
          kind: {:scalar, ""},
          label: :optional,
          name: :adPreviewURL,
          tag: 27,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "containsCtwaFlowsAutoReply",
          kind: {:scalar, false},
          label: :optional,
          name: :containsCtwaFlowsAutoReply,
          tag: 28,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "agmThumbnailStrategy",
          kind: {:scalar, 0},
          label: :optional,
          name: :agmThumbnailStrategy,
          tag: 29,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "agmTitleStrategy",
          kind: {:scalar, 0},
          label: :optional,
          name: :agmTitleStrategy,
          tag: 30,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "agmSubtitleStrategy",
          kind: {:scalar, 0},
          label: :optional,
          name: :agmSubtitleStrategy,
          tag: 31,
          type: :int32
        },
        %{
          __struct__: Protox.Field,
          json_name: "agmHeaderInteractionStrategy",
          kind: {:scalar, 0},
          label: :optional,
          name: :agmHeaderInteractionStrategy,
          tag: 32,
          type: :int32
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:title) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "title",
             kind: {:scalar, ""},
             label: :optional,
             name: :title,
             tag: 1,
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
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:body) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "body",
             kind: {:scalar, ""},
             label: :optional,
             name: :body,
             tag: 2,
             type: :string
           }}
        end

        def field_def("body") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "body",
             kind: {:scalar, ""},
             label: :optional,
             name: :body,
             tag: 2,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:mediaType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaType",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :mediaType,
             tag: 3,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.MediaType}
           }}
        end

        def field_def("mediaType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaType",
             kind: {:scalar, :NONE},
             label: :optional,
             name: :mediaType,
             tag: 3,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.MediaType}
           }}
        end

        []
      ),
      (
        def field_def(:thumbnailURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailURL,
             tag: 4,
             type: :string
           }}
        end

        def field_def("thumbnailURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnailURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnailURL,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:mediaURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :mediaURL,
             tag: 5,
             type: :string
           }}
        end

        def field_def("mediaURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :mediaURL,
             tag: 5,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:thumbnail) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnail",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnail,
             tag: 6,
             type: :bytes
           }}
        end

        def field_def("thumbnail") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "thumbnail",
             kind: {:scalar, ""},
             label: :optional,
             name: :thumbnail,
             tag: 6,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:sourceType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sourceType",
             kind: {:scalar, ""},
             label: :optional,
             name: :sourceType,
             tag: 7,
             type: :string
           }}
        end

        def field_def("sourceType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sourceType",
             kind: {:scalar, ""},
             label: :optional,
             name: :sourceType,
             tag: 7,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:sourceID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sourceID",
             kind: {:scalar, ""},
             label: :optional,
             name: :sourceID,
             tag: 8,
             type: :string
           }}
        end

        def field_def("sourceID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sourceID",
             kind: {:scalar, ""},
             label: :optional,
             name: :sourceID,
             tag: 8,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:sourceURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sourceURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :sourceURL,
             tag: 9,
             type: :string
           }}
        end

        def field_def("sourceURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sourceURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :sourceURL,
             tag: 9,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:containsAutoReply) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "containsAutoReply",
             kind: {:scalar, false},
             label: :optional,
             name: :containsAutoReply,
             tag: 10,
             type: :bool
           }}
        end

        def field_def("containsAutoReply") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "containsAutoReply",
             kind: {:scalar, false},
             label: :optional,
             name: :containsAutoReply,
             tag: 10,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:renderLargerThumbnail) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "renderLargerThumbnail",
             kind: {:scalar, false},
             label: :optional,
             name: :renderLargerThumbnail,
             tag: 11,
             type: :bool
           }}
        end

        def field_def("renderLargerThumbnail") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "renderLargerThumbnail",
             kind: {:scalar, false},
             label: :optional,
             name: :renderLargerThumbnail,
             tag: 11,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:showAdAttribution) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "showAdAttribution",
             kind: {:scalar, false},
             label: :optional,
             name: :showAdAttribution,
             tag: 12,
             type: :bool
           }}
        end

        def field_def("showAdAttribution") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "showAdAttribution",
             kind: {:scalar, false},
             label: :optional,
             name: :showAdAttribution,
             tag: 12,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:ctwaClid) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctwaClid",
             kind: {:scalar, ""},
             label: :optional,
             name: :ctwaClid,
             tag: 13,
             type: :string
           }}
        end

        def field_def("ctwaClid") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctwaClid",
             kind: {:scalar, ""},
             label: :optional,
             name: :ctwaClid,
             tag: 13,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:ref) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ref",
             kind: {:scalar, ""},
             label: :optional,
             name: :ref,
             tag: 14,
             type: :string
           }}
        end

        def field_def("ref") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ref",
             kind: {:scalar, ""},
             label: :optional,
             name: :ref,
             tag: 14,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:clickToWhatsappCall) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "clickToWhatsappCall",
             kind: {:scalar, false},
             label: :optional,
             name: :clickToWhatsappCall,
             tag: 15,
             type: :bool
           }}
        end

        def field_def("clickToWhatsappCall") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "clickToWhatsappCall",
             kind: {:scalar, false},
             label: :optional,
             name: :clickToWhatsappCall,
             tag: 15,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:adContextPreviewDismissed) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "adContextPreviewDismissed",
             kind: {:scalar, false},
             label: :optional,
             name: :adContextPreviewDismissed,
             tag: 16,
             type: :bool
           }}
        end

        def field_def("adContextPreviewDismissed") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "adContextPreviewDismissed",
             kind: {:scalar, false},
             label: :optional,
             name: :adContextPreviewDismissed,
             tag: 16,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:sourceApp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sourceApp",
             kind: {:scalar, ""},
             label: :optional,
             name: :sourceApp,
             tag: 17,
             type: :string
           }}
        end

        def field_def("sourceApp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "sourceApp",
             kind: {:scalar, ""},
             label: :optional,
             name: :sourceApp,
             tag: 17,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:automatedGreetingMessageShown) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "automatedGreetingMessageShown",
             kind: {:scalar, false},
             label: :optional,
             name: :automatedGreetingMessageShown,
             tag: 18,
             type: :bool
           }}
        end

        def field_def("automatedGreetingMessageShown") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "automatedGreetingMessageShown",
             kind: {:scalar, false},
             label: :optional,
             name: :automatedGreetingMessageShown,
             tag: 18,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:greetingMessageBody) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "greetingMessageBody",
             kind: {:scalar, ""},
             label: :optional,
             name: :greetingMessageBody,
             tag: 19,
             type: :string
           }}
        end

        def field_def("greetingMessageBody") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "greetingMessageBody",
             kind: {:scalar, ""},
             label: :optional,
             name: :greetingMessageBody,
             tag: 19,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:ctaPayload) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctaPayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :ctaPayload,
             tag: 20,
             type: :string
           }}
        end

        def field_def("ctaPayload") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ctaPayload",
             kind: {:scalar, ""},
             label: :optional,
             name: :ctaPayload,
             tag: 20,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:disableNudge) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "disableNudge",
             kind: {:scalar, false},
             label: :optional,
             name: :disableNudge,
             tag: 21,
             type: :bool
           }}
        end

        def field_def("disableNudge") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "disableNudge",
             kind: {:scalar, false},
             label: :optional,
             name: :disableNudge,
             tag: 21,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:originalImageURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "originalImageURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :originalImageURL,
             tag: 22,
             type: :string
           }}
        end

        def field_def("originalImageURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "originalImageURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :originalImageURL,
             tag: 22,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:automatedGreetingMessageCtaType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "automatedGreetingMessageCtaType",
             kind: {:scalar, ""},
             label: :optional,
             name: :automatedGreetingMessageCtaType,
             tag: 23,
             type: :string
           }}
        end

        def field_def("automatedGreetingMessageCtaType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "automatedGreetingMessageCtaType",
             kind: {:scalar, ""},
             label: :optional,
             name: :automatedGreetingMessageCtaType,
             tag: 23,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:wtwaAdFormat) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "wtwaAdFormat",
             kind: {:scalar, false},
             label: :optional,
             name: :wtwaAdFormat,
             tag: 24,
             type: :bool
           }}
        end

        def field_def("wtwaAdFormat") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "wtwaAdFormat",
             kind: {:scalar, false},
             label: :optional,
             name: :wtwaAdFormat,
             tag: 24,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:adType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "adType",
             kind: {:scalar, :CTWA},
             label: :optional,
             name: :adType,
             tag: 25,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.AdType}
           }}
        end

        def field_def("adType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "adType",
             kind: {:scalar, :CTWA},
             label: :optional,
             name: :adType,
             tag: 25,
             type: {:enum, WAWebProtobufsE2E.ContextInfo.ExternalAdReplyInfo.AdType}
           }}
        end

        []
      ),
      (
        def field_def(:wtwaWebsiteURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "wtwaWebsiteURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :wtwaWebsiteURL,
             tag: 26,
             type: :string
           }}
        end

        def field_def("wtwaWebsiteURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "wtwaWebsiteURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :wtwaWebsiteURL,
             tag: 26,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:adPreviewURL) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "adPreviewURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :adPreviewURL,
             tag: 27,
             type: :string
           }}
        end

        def field_def("adPreviewURL") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "adPreviewURL",
             kind: {:scalar, ""},
             label: :optional,
             name: :adPreviewURL,
             tag: 27,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:containsCtwaFlowsAutoReply) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "containsCtwaFlowsAutoReply",
             kind: {:scalar, false},
             label: :optional,
             name: :containsCtwaFlowsAutoReply,
             tag: 28,
             type: :bool
           }}
        end

        def field_def("containsCtwaFlowsAutoReply") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "containsCtwaFlowsAutoReply",
             kind: {:scalar, false},
             label: :optional,
             name: :containsCtwaFlowsAutoReply,
             tag: 28,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:agmThumbnailStrategy) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "agmThumbnailStrategy",
             kind: {:scalar, 0},
             label: :optional,
             name: :agmThumbnailStrategy,
             tag: 29,
             type: :int32
           }}
        end

        def field_def("agmThumbnailStrategy") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "agmThumbnailStrategy",
             kind: {:scalar, 0},
             label: :optional,
             name: :agmThumbnailStrategy,
             tag: 29,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:agmTitleStrategy) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "agmTitleStrategy",
             kind: {:scalar, 0},
             label: :optional,
             name: :agmTitleStrategy,
             tag: 30,
             type: :int32
           }}
        end

        def field_def("agmTitleStrategy") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "agmTitleStrategy",
             kind: {:scalar, 0},
             label: :optional,
             name: :agmTitleStrategy,
             tag: 30,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:agmSubtitleStrategy) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "agmSubtitleStrategy",
             kind: {:scalar, 0},
             label: :optional,
             name: :agmSubtitleStrategy,
             tag: 31,
             type: :int32
           }}
        end

        def field_def("agmSubtitleStrategy") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "agmSubtitleStrategy",
             kind: {:scalar, 0},
             label: :optional,
             name: :agmSubtitleStrategy,
             tag: 31,
             type: :int32
           }}
        end

        []
      ),
      (
        def field_def(:agmHeaderInteractionStrategy) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "agmHeaderInteractionStrategy",
             kind: {:scalar, 0},
             label: :optional,
             name: :agmHeaderInteractionStrategy,
             tag: 32,
             type: :int32
           }}
        end

        def field_def("agmHeaderInteractionStrategy") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "agmHeaderInteractionStrategy",
             kind: {:scalar, 0},
             label: :optional,
             name: :agmHeaderInteractionStrategy,
             tag: 32,
             type: :int32
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
    def default(:title) do
      {:ok, ""}
    end,
    def default(:body) do
      {:ok, ""}
    end,
    def default(:mediaType) do
      {:ok, :NONE}
    end,
    def default(:thumbnailURL) do
      {:ok, ""}
    end,
    def default(:mediaURL) do
      {:ok, ""}
    end,
    def default(:thumbnail) do
      {:ok, ""}
    end,
    def default(:sourceType) do
      {:ok, ""}
    end,
    def default(:sourceID) do
      {:ok, ""}
    end,
    def default(:sourceURL) do
      {:ok, ""}
    end,
    def default(:containsAutoReply) do
      {:ok, false}
    end,
    def default(:renderLargerThumbnail) do
      {:ok, false}
    end,
    def default(:showAdAttribution) do
      {:ok, false}
    end,
    def default(:ctwaClid) do
      {:ok, ""}
    end,
    def default(:ref) do
      {:ok, ""}
    end,
    def default(:clickToWhatsappCall) do
      {:ok, false}
    end,
    def default(:adContextPreviewDismissed) do
      {:ok, false}
    end,
    def default(:sourceApp) do
      {:ok, ""}
    end,
    def default(:automatedGreetingMessageShown) do
      {:ok, false}
    end,
    def default(:greetingMessageBody) do
      {:ok, ""}
    end,
    def default(:ctaPayload) do
      {:ok, ""}
    end,
    def default(:disableNudge) do
      {:ok, false}
    end,
    def default(:originalImageURL) do
      {:ok, ""}
    end,
    def default(:automatedGreetingMessageCtaType) do
      {:ok, ""}
    end,
    def default(:wtwaAdFormat) do
      {:ok, false}
    end,
    def default(:adType) do
      {:ok, :CTWA}
    end,
    def default(:wtwaWebsiteURL) do
      {:ok, ""}
    end,
    def default(:adPreviewURL) do
      {:ok, ""}
    end,
    def default(:containsCtwaFlowsAutoReply) do
      {:ok, false}
    end,
    def default(:agmThumbnailStrategy) do
      {:ok, 0}
    end,
    def default(:agmTitleStrategy) do
      {:ok, 0}
    end,
    def default(:agmSubtitleStrategy) do
      {:ok, 0}
    end,
    def default(:agmHeaderInteractionStrategy) do
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

  @type t :: %__MODULE__{}
end
