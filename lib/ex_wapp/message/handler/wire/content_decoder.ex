defmodule ExWapp.Message.Handler.Wire.ContentDecoder do
  @moduledoc """
  Pure decoder for supported WhatsApp message content.

  It decodes the E2E `Message` protobuf and maps supported content (text,
  media, location, contact, event) to the internal contract, but does not
  parse XML envelopes, decrypt Signal payloads, persist state, or publish
  events.
  """

  alias WAWebProtobufsE2E.{
    AudioMessage,
    ContactMessage,
    DocumentMessage,
    EventMessage,
    ImageMessage,
    LiveLocationMessage,
    LocationMessage,
    Message
  }

  @max_message_decode_depth 6

  @doc """
  Adds decoded media, location, contact, or event fields to a message map.
  """
  @spec apply_media_from_plaintext(map(), binary()) :: map()
  def apply_media_from_plaintext(message_data, plaintext) when is_binary(plaintext) do
    case decode_message(plaintext) do
      {:ok, message} -> apply_media_from_message(message_data, message)
      :error -> message_data
    end
  end

  @doc """
  Same as `apply_media_from_plaintext/2` for an already-decoded message.
  """
  @spec apply_media_from_message(map(), Message.t()) :: map()
  def apply_media_from_message(message_data, %Message{} = message),
    do: apply_supported_content(message_data, message)

  @spec apply_supported_content(map(), Message.t()) :: map()
  defp apply_supported_content(message_data, message) do
    case extract_supported_content(message, 0) do
      %{kind: :media, type: type, ref: ref, caption: caption} ->
        message_data
        |> Map.put(:media, ref)
        |> Map.put(:media_type, type)
        |> Map.put(:content_type, type)
        |> Map.put(:text, caption)

      %{kind: :location, value: location} ->
        message_data
        |> Map.put(:location, location)
        |> Map.put(:content_type, :location)
        |> Map.put(:text, location.comment || location.name || location.address)

      %{kind: :contact, value: contact} ->
        message_data
        |> Map.put(:contact, contact)
        |> Map.put(:content_type, :contact)
        |> Map.put(:text, contact.display_name)

      %{kind: :event, value: event} ->
        message_data
        |> Map.put(:event, event)
        |> Map.put(:content_type, :event)
        |> Map.put(:text, event.name)

      nil ->
        message_data
    end
  end

  @doc """
  Distinguishes protocol payloads from user content and extracts message text.
  """
  @spec classify_decrypted_content(binary(), non_neg_integer()) ::
          {:protocol | :user_message, binary() | nil}
  def classify_decrypted_content(_payload, sender_key_distribution_count)
      when sender_key_distribution_count > 0 do
    {:protocol, nil}
  end

  def classify_decrypted_content(payload, _sender_key_distribution_count)
      when is_binary(payload) do
    case decode_message(payload) do
      {:ok, message} -> classify_message(message, 0)
      :error -> {:user_message, nil}
    end
  end

  @doc """
  Same as `classify_decrypted_content/2` for an already-decoded message.
  """
  @spec classify_message(Message.t(), non_neg_integer()) ::
          {:protocol | :user_message, binary() | nil}
  def classify_message(_message, sender_key_distribution_count)
      when sender_key_distribution_count > 0 do
    {:protocol, nil}
  end

  def classify_message(%Message{protocolMessage: protocol}, _count) when not is_nil(protocol) do
    {:protocol, nil}
  end

  def classify_message(%Message{} = message, _count) do
    {:user_message, extract_message_text(message, 0)}
  end

  @doc """
  Reports whether a message is a `DeviceSentMessage` wrapper (own-device fanout).
  """
  @spec device_sent_message?(Message.t() | term()) :: boolean()
  def device_sent_message?(%Message{deviceSentMessage: %{}}), do: true
  def device_sent_message?(_message), do: false

  @doc """
  Decodes an E2E `Message` payload, returning `:error` on malformed protobuf.
  """
  @spec decode(binary()) :: {:ok, Message.t()} | :error
  def decode(payload) when is_binary(payload), do: decode_message(payload)

  @spec decode_message(binary()) :: {:ok, Message.t()} | :error
  defp decode_message(payload) do
    case Message.decode(payload) do
      {:ok, message} -> {:ok, message}
      {:error, _reason} -> :error
    end
  end

  @spec extract_supported_content(Message.t(), non_neg_integer()) :: map() | nil
  defp extract_supported_content(_message, depth) when depth > @max_message_decode_depth,
    do: nil

  defp extract_supported_content(message, depth) do
    extract_supported_content_shallow(message) ||
      Enum.find_value(wrapped_messages(message), fn wrapped ->
        extract_supported_content(wrapped, depth + 1)
      end)
  end

  @spec extract_supported_content_shallow(Message.t()) :: map() | nil
  defp extract_supported_content_shallow(message) do
    cond do
      match?(%ImageMessage{}, message.imageMessage) ->
        build_media_ref(:image, message.imageMessage)

      match?(%DocumentMessage{}, message.documentMessage) ->
        build_media_ref(:document, message.documentMessage)

      match?(%AudioMessage{}, message.audioMessage) ->
        build_media_ref(:audio, message.audioMessage)

      match?(%EventMessage{}, message.eventMessage) ->
        build_event(message.eventMessage)

      match?(%LocationMessage{}, message.locationMessage) ->
        build_location(message.locationMessage)

      match?(%LiveLocationMessage{}, message.liveLocationMessage) ->
        build_live_location(message.liveLocationMessage)

      match?(%ContactMessage{}, message.contactMessage) ->
        build_contact(message.contactMessage)

      true ->
        nil
    end
  end

  @spec wrapped_messages(Message.t()) :: [Message.t()]
  defp wrapped_messages(message) do
    wrappers = [
      message.deviceSentMessage,
      message.viewOnceMessage,
      message.ephemeralMessage,
      message.documentWithCaptionMessage,
      message.viewOnceMessageV2,
      message.viewOnceMessageV2Extension,
      message.lottieStickerMessage
    ]

    for %{message: %Message{} = wrapped} <- wrappers, do: wrapped
  end

  @spec build_media_ref(:image | :audio | :document, struct()) :: map()
  defp build_media_ref(:image, %ImageMessage{} = image) do
    %{
      kind: :media,
      type: :image,
      caption: image.caption,
      ref: %ExWapp.Media.Ref{
        type: :image,
        url: image."URL",
        mimetype: image.mimetype,
        file_sha256: image.fileSHA256,
        file_length: image.fileLength,
        media_key: image.mediaKey,
        file_enc_sha256: image.fileEncSHA256,
        direct_path: image.directPath,
        media_key_timestamp: image.mediaKeyTimestamp,
        metadata: %{
          height: image.height,
          width: image.width,
          media_key_timestamp: image.mediaKeyTimestamp,
          thumbnail: image."JPEGThumbnail"
        }
      }
    }
  end

  defp build_media_ref(:audio, %AudioMessage{} = audio) do
    %{
      kind: :media,
      type: :audio,
      caption: nil,
      ref: %ExWapp.Media.Ref{
        type: :audio,
        url: audio."URL",
        mimetype: audio.mimetype,
        file_sha256: audio.fileSHA256,
        file_length: audio.fileLength,
        media_key: audio.mediaKey,
        file_enc_sha256: audio.fileEncSHA256,
        direct_path: audio.directPath,
        media_key_timestamp: audio.mediaKeyTimestamp,
        metadata: %{
          seconds: audio.seconds,
          ptt: audio."PTT",
          media_key_timestamp: audio.mediaKeyTimestamp,
          waveform: audio.waveform
        }
      }
    }
  end

  defp build_media_ref(:document, %DocumentMessage{} = document) do
    %{
      kind: :media,
      type: :document,
      caption: document.caption,
      ref: %ExWapp.Media.Ref{
        type: :document,
        url: document."URL",
        mimetype: document.mimetype,
        file_sha256: document.fileSHA256,
        file_length: document.fileLength,
        media_key: document.mediaKey,
        file_enc_sha256: document.fileEncSHA256,
        direct_path: document.directPath,
        media_key_timestamp: document.mediaKeyTimestamp,
        metadata: %{
          title: document.title,
          page_count: document.pageCount,
          file_name: document.fileName,
          contact_vcard: document.contactVcard,
          thumbnail: document."JPEGThumbnail"
        }
      }
    }
  end

  @spec build_location(LocationMessage.t()) :: map()
  defp build_location(%LocationMessage{} = location) do
    %{
      kind: :location,
      value: %{
        latitude: location.degreesLatitude,
        longitude: location.degreesLongitude,
        name: location.name,
        address: location.address,
        url: location."URL",
        is_live: location.isLive,
        accuracy: location.accuracyInMeters,
        speed: location.speedInMps,
        bearing: location.degreesClockwiseFromMagneticNorth,
        comment: location.comment,
        jpeg_thumbnail: location."JPEGThumbnail"
      }
    }
  end

  @spec build_contact(ContactMessage.t()) :: map()
  defp build_contact(%ContactMessage{} = contact) do
    %{
      kind: :contact,
      value: %{
        display_name: contact.displayName,
        vcard: contact.vcard,
        is_self_contact: contact.isSelfContact
      }
    }
  end

  @spec build_live_location(LiveLocationMessage.t()) :: map()
  defp build_live_location(%LiveLocationMessage{} = live) do
    %{
      kind: :location,
      value: %{
        latitude: live.degreesLatitude,
        longitude: live.degreesLongitude,
        is_live: true,
        accuracy: live.accuracyInMeters,
        speed: live.speedInMps,
        bearing: live.degreesClockwiseFromMagneticNorth,
        comment: live.caption,
        sequence_number: live.sequenceNumber,
        time_offset: live.timeOffset,
        jpeg_thumbnail: live."JPEGThumbnail",
        name: nil,
        address: nil,
        url: nil
      }
    }
  end

  @spec build_event(EventMessage.t()) :: map()
  defp build_event(%EventMessage{} = event) do
    location =
      case event.location do
        %LocationMessage{} = event_location -> build_location(event_location).value
        _ -> nil
      end

    %{
      kind: :event,
      value: %{
        canceled: event.isCanceled,
        name: event.name,
        description: event.description,
        location: location,
        join_link: event.joinLink,
        start_time: event.startTime,
        end_time: event.endTime,
        extra_guests_allowed: event.extraGuestsAllowed,
        scheduled_call: event.isScheduleCall,
        has_reminder: event.hasReminder,
        reminder_offset_seconds: event.reminderOffsetSec
      }
    }
  end

  @spec extract_message_text(Message.t(), non_neg_integer()) :: binary() | nil
  defp extract_message_text(_message, depth) when depth > @max_message_decode_depth, do: nil

  defp extract_message_text(message, depth) do
    extract_message_text_shallow(message) ||
      Enum.find_value(wrapped_messages(message), fn wrapped ->
        extract_message_text(wrapped, depth + 1)
      end)
  end

  @spec extract_message_text_shallow(Message.t()) :: binary() | nil
  defp extract_message_text_shallow(message) do
    cond do
      valid_text_payload?(message.conversation) ->
        message.conversation

      is_map(message.extendedTextMessage) and
          valid_text_payload?(message.extendedTextMessage.text) ->
        message.extendedTextMessage.text

      true ->
        nil
    end
  end

  @spec valid_text_payload?(binary() | nil) :: boolean()
  defp valid_text_payload?(value) when is_binary(value),
    do: value != "" and String.valid?(value)

  defp valid_text_payload?(_value), do: false
end
