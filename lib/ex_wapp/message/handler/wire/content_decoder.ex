defmodule ExWapp.Message.Handler.Wire.ContentDecoder do
  @moduledoc """
  Pure decoder for supported WhatsApp message content.

  It understands message protobuf field assignments and wrapper messages, but
  does not parse XML envelopes, decrypt Signal payloads, persist state, or
  publish events.
  """

  alias ExWapp.Message.Handler.Wire.Fields

  @max_message_decode_depth 6

  @doc """
  Adds decoded media, location, contact, or event fields to a message map.
  """
  @spec apply_media_from_plaintext(map(), binary()) :: map()
  def apply_media_from_plaintext(message_data, plaintext) when is_binary(plaintext) do
    case extract_supported_content(plaintext) do
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
    case Fields.find_length_delimited(payload, 12) do
      {:ok, _protocol_msg} ->
        {:protocol, nil}

      _ ->
        case decode_message_text_recursive(payload, 0) do
          {:ok, text} -> {:user_message, text}
          :error -> {:user_message, nil}
        end
    end
  end

  @spec extract_supported_content(binary()) :: map() | nil
  defp extract_supported_content(message_payload),
    do: extract_supported_content_recursive(message_payload, 0)

  @spec extract_supported_content_recursive(binary(), non_neg_integer()) :: map() | nil
  defp extract_supported_content_recursive(_message_payload, depth)
       when depth > @max_message_decode_depth,
       do: nil

  defp extract_supported_content_recursive(message_payload, depth) do
    extract_supported_content_shallow(message_payload) ||
      extract_wrapped_supported_content(message_payload, depth)
  end

  @spec extract_supported_content_shallow(binary()) :: map() | nil
  defp extract_supported_content_shallow(message_payload) do
    cond do
      match?({:ok, _}, Fields.find_length_delimited(message_payload, 3)) ->
        {:ok, payload} = Fields.find_length_delimited(message_payload, 3)
        build_media_ref(:image, payload)

      match?({:ok, _}, Fields.find_length_delimited(message_payload, 7)) ->
        {:ok, payload} = Fields.find_length_delimited(message_payload, 7)
        build_media_ref(:document, payload)

      match?({:ok, _}, Fields.find_length_delimited(message_payload, 8)) ->
        {:ok, payload} = Fields.find_length_delimited(message_payload, 8)
        build_media_ref(:audio, payload)

      match?({:ok, _}, Fields.find_length_delimited(message_payload, 75)) ->
        {:ok, payload} = Fields.find_length_delimited(message_payload, 75)
        build_event(payload)

      match?({:ok, _}, Fields.find_length_delimited(message_payload, 5)) ->
        {:ok, payload} = Fields.find_length_delimited(message_payload, 5)
        build_location(payload)

      match?({:ok, _}, Fields.find_length_delimited(message_payload, 18)) ->
        {:ok, payload} = Fields.find_length_delimited(message_payload, 18)
        build_live_location(payload)

      match?({:ok, _}, Fields.find_length_delimited(message_payload, 4)) ->
        {:ok, payload} = Fields.find_length_delimited(message_payload, 4)
        build_contact(payload)

      true ->
        nil
    end
  end

  @spec extract_wrapped_supported_content(binary(), non_neg_integer()) :: map() | nil
  defp extract_wrapped_supported_content(message_payload, depth) do
    wrapper_fields = [31, 37, 40, 53, 55, 59, 74]

    Enum.find_value(
      wrapper_fields,
      &extract_wrapped_supported_content(message_payload, depth, &1)
    )
  end

  @spec extract_wrapped_supported_content(binary(), non_neg_integer(), non_neg_integer()) ::
          map() | nil
  defp extract_wrapped_supported_content(message_payload, depth, field) do
    with {:ok, wrapper} <- Fields.find_length_delimited(message_payload, field),
         {:ok, nested_message} <-
           Fields.find_length_delimited(wrapper, nested_message_field(field)) do
      extract_supported_content_recursive(nested_message, depth + 1)
    else
      _ -> nil
    end
  end

  @spec nested_message_field(non_neg_integer()) :: pos_integer()
  defp nested_message_field(31), do: 2
  defp nested_message_field(_field), do: 1

  @spec build_media_ref(:image | :audio | :document, binary()) :: map()
  defp build_media_ref(:image, payload) do
    %{
      kind: :media,
      type: :image,
      caption: Fields.bytes(payload, 3),
      ref: %ExWapp.Media.Ref{
        type: :image,
        url: Fields.bytes(payload, 1),
        mimetype: Fields.bytes(payload, 2),
        file_sha256: Fields.bytes(payload, 4),
        file_length: Fields.varint(payload, 5),
        media_key: Fields.bytes(payload, 8),
        file_enc_sha256: Fields.bytes(payload, 9),
        direct_path: Fields.bytes(payload, 11),
        media_key_timestamp: Fields.varint(payload, 12),
        metadata: %{
          height: Fields.varint(payload, 6),
          width: Fields.varint(payload, 7),
          media_key_timestamp: Fields.varint(payload, 12),
          thumbnail: Fields.bytes(payload, 16)
        }
      }
    }
  end

  defp build_media_ref(:audio, payload) do
    %{
      kind: :media,
      type: :audio,
      caption: nil,
      ref: %ExWapp.Media.Ref{
        type: :audio,
        url: Fields.bytes(payload, 1),
        mimetype: Fields.bytes(payload, 2),
        file_sha256: Fields.bytes(payload, 3),
        file_length: Fields.varint(payload, 4),
        media_key: Fields.bytes(payload, 7),
        file_enc_sha256: Fields.bytes(payload, 8),
        direct_path: Fields.bytes(payload, 9),
        media_key_timestamp: Fields.varint(payload, 10),
        metadata: %{
          seconds: Fields.varint(payload, 5),
          ptt: Fields.bool(payload, 6),
          media_key_timestamp: Fields.varint(payload, 10),
          waveform: Fields.bytes(payload, 19)
        }
      }
    }
  end

  defp build_media_ref(:document, payload) do
    %{
      kind: :media,
      type: :document,
      caption: Fields.bytes(payload, 20),
      ref: %ExWapp.Media.Ref{
        type: :document,
        url: Fields.bytes(payload, 1),
        mimetype: Fields.bytes(payload, 2),
        file_sha256: Fields.bytes(payload, 4),
        file_length: Fields.varint(payload, 5),
        media_key: Fields.bytes(payload, 7),
        file_enc_sha256: Fields.bytes(payload, 9),
        direct_path: Fields.bytes(payload, 10),
        media_key_timestamp: Fields.varint(payload, 11),
        metadata: %{
          title: Fields.bytes(payload, 3),
          page_count: Fields.varint(payload, 6),
          file_name: Fields.bytes(payload, 8),
          contact_vcard: Fields.bool(payload, 12),
          thumbnail: Fields.bytes(payload, 16)
        }
      }
    }
  end

  @spec build_location(binary()) :: map()
  defp build_location(payload) do
    %{
      kind: :location,
      value: %{
        latitude: Fields.double(payload, 1),
        longitude: Fields.double(payload, 2),
        name: Fields.bytes(payload, 3),
        address: Fields.bytes(payload, 4),
        url: Fields.bytes(payload, 5),
        is_live: Fields.bool(payload, 6),
        accuracy: Fields.varint(payload, 7),
        speed: Fields.float(payload, 8),
        bearing: Fields.varint(payload, 9),
        comment: Fields.bytes(payload, 11),
        jpeg_thumbnail: Fields.bytes(payload, 16)
      }
    }
  end

  @spec build_contact(binary()) :: map()
  defp build_contact(payload) do
    %{
      kind: :contact,
      value: %{
        display_name: Fields.bytes(payload, 1),
        vcard: Fields.bytes(payload, 16),
        is_self_contact: Fields.bool(payload, 18)
      }
    }
  end

  @spec build_live_location(binary()) :: map()
  defp build_live_location(payload) do
    %{
      kind: :location,
      value: %{
        latitude: Fields.double(payload, 1),
        longitude: Fields.double(payload, 2),
        is_live: true,
        accuracy: Fields.varint(payload, 3),
        speed: Fields.float(payload, 4),
        bearing: Fields.varint(payload, 5),
        comment: Fields.bytes(payload, 6),
        sequence_number: Fields.varint(payload, 7),
        time_offset: Fields.varint(payload, 8),
        jpeg_thumbnail: Fields.bytes(payload, 16),
        name: nil,
        address: nil,
        url: nil
      }
    }
  end

  @spec build_event(binary()) :: map()
  defp build_event(payload) do
    location =
      case Fields.find_length_delimited(payload, 5) do
        {:ok, location_payload} -> build_location(location_payload).value
        _ -> nil
      end

    %{
      kind: :event,
      value: %{
        canceled: Fields.bool(payload, 2),
        name: Fields.bytes(payload, 3),
        description: Fields.bytes(payload, 4),
        location: location,
        join_link: Fields.bytes(payload, 6),
        start_time: Fields.varint(payload, 7),
        end_time: Fields.varint(payload, 8),
        extra_guests_allowed: Fields.bool(payload, 9),
        scheduled_call: Fields.bool(payload, 10),
        has_reminder: Fields.bool(payload, 11),
        reminder_offset_seconds: Fields.varint(payload, 12)
      }
    }
  end

  @spec decode_message_text_recursive(binary(), non_neg_integer()) ::
          {:ok, binary()} | :error
  defp decode_message_text_recursive(_payload, depth) when depth > @max_message_decode_depth,
    do: :error

  defp decode_message_text_recursive(payload, depth) do
    case decode_message_text_shallow(payload) do
      {:ok, text} -> {:ok, text}
      :error -> decode_nested_message_text(payload, depth)
    end
  end

  @spec decode_nested_message_text(binary(), non_neg_integer()) ::
          {:ok, binary()} | :error
  defp decode_nested_message_text(payload, depth) do
    case Fields.collect_length_delimited_values(payload) do
      {:ok, nested_values} ->
        Enum.reduce_while(nested_values, :error, fn nested, _acc ->
          reduce_nested_message_text(nested, depth)
        end)

      {:error, _reason} ->
        :error
    end
  end

  @spec reduce_nested_message_text(binary(), non_neg_integer()) ::
          {:halt, {:ok, binary()}} | {:cont, :error}
  defp reduce_nested_message_text(nested, depth) do
    case decode_message_text_recursive(nested, depth + 1) do
      {:ok, text} -> {:halt, {:ok, text}}
      :error -> {:cont, :error}
    end
  end

  @spec decode_message_text_shallow(binary()) :: {:ok, binary()} | :error
  defp decode_message_text_shallow(payload) do
    with {:ok, conversation} <- Fields.find_length_delimited(payload, 1),
         true <- valid_text_payload?(conversation) do
      {:ok, conversation}
    else
      _ ->
        with {:ok, extended} <- Fields.find_length_delimited(payload, 6),
             {:ok, text} <- Fields.find_length_delimited(extended, 1),
             true <- valid_text_payload?(text) do
          {:ok, text}
        else
          _ -> :error
        end
    end
  end

  @spec valid_text_payload?(binary()) :: boolean()
  defp valid_text_payload?(value) when is_binary(value), do: value != "" and String.valid?(value)
end
