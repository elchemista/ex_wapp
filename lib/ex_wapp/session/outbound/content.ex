defmodule ExWapp.Session.Outbound.Content do
  @moduledoc false

  alias ExWapp.{Binary, Media, Message, Messages}
  alias ExWapp.Session.Worker.Outbound
  alias WAWebProtobufsE2E.Message, as: ProtoMessage

  @type prepared :: {:ok, ProtoMessage.t(), keyword()} | {:error, term()}

  @doc false
  @spec send(pid(), map(), Message.t()) :: {:ok, String.t()} | {:error, term()}
  def send(session_pid, state, %Message{to: jid} = message) do
    state = Map.put(state, :outbound_iq_router, session_pid)

    with {:ok, proto, send_opts} <- prepare(session_pid, state, message) do
      if message.type == :history_request do
        Outbound.send_peer_proto_worker(session_pid, state, proto, send_opts)
      else
        id = Keyword.get(send_opts, :retry_message_id) || message.id || Messages.generate_id()
        send_opts = Keyword.put(send_opts, :retry_message_id, id)
        :ok = GenServer.call(session_pid, {:remember_outgoing_proto, jid, id, proto, send_opts})
        Outbound.send_proto_worker(session_pid, state, jid, proto, send_opts)
      end
    end
  rescue
    exception -> {:error, {:content_send_exception, exception}}
  catch
    kind, reason -> {:error, {:content_send_throw, kind, reason}}
  end

  def send(_session_pid, _state, message), do: {:error, {:invalid_content, message}}

  @doc false
  @spec prepare(pid(), map(), Message.t()) :: prepared()
  def prepare(session_pid, state, %Message{} = message) do
    with :ok <- validate(message) do
      do_prepare(session_pid, state, message)
    end
  end

  def prepare(_session_pid, _state, message), do: {:error, {:invalid_content, message}}

  @doc false
  @spec validate(Message.t()) :: :ok | {:error, term()}
  def validate(%Message{type: type, body: %Media.Upload{type: type}, opts: opts})
      when type in [:image, :video, :sticker, :audio, :document],
      do: validate_media_options(opts)

  def validate(%Message{type: type, body: %Media.Upload{type: other}})
      when type in [:image, :video, :sticker, :audio, :document],
      do: {:error, {:media_type_mismatch, type, other}}

  def validate(%Message{type: type, body: {:bytes, bytes}, opts: opts})
      when type in [:image, :video, :sticker, :audio, :document] and is_binary(bytes),
      do: validate_media_options(opts)

  def validate(%Message{type: type, body: {:path, path}, opts: opts})
      when type in [:image, :video, :sticker, :audio, :document] and is_binary(path),
      do: validate_media_options(opts)

  def validate(%Message{type: type, body: source})
      when type in [:image, :video, :sticker, :audio, :document],
      do: {:error, {:unsupported_media_source, source}}

  def validate(%Message{type: :location, body: body}) when is_map(body) do
    if valid_location?(Map.get(body, :latitude), Map.get(body, :longitude)),
      do: :ok,
      else: {:error, :invalid_location}
  end

  def validate(%Message{type: :location}), do: {:error, {:invalid_content, :location}}

  def validate(%Message{type: :contact, body: body}) when is_map(body) do
    display_name = Map.get(body, :display_name)
    vcard = Map.get(body, :vcard)

    if is_binary(display_name) and display_name != "" and is_binary(vcard) and vcard != "",
      do: :ok,
      else: {:error, :invalid_contact}
  end

  def validate(%Message{type: :contact}), do: {:error, {:invalid_content, :contact}}

  def validate(%Message{type: :event, body: body}) when is_map(body) do
    name = Map.get(body, :name)
    start_time = Map.get(body, :start_time)

    if is_binary(name) and name != "" and
         (is_integer(start_time) or is_struct(start_time, DateTime)),
       do: :ok,
       else: {:error, :invalid_event}
  end

  def validate(%Message{
        type: :reaction,
        to: jid,
        body: %{message_id: id, text: text},
        opts: opts
      }) do
    from_me = Keyword.get(opts, :from_me, false)
    participant = Keyword.get(opts, :participant)

    cond do
      not supported_chat?(jid) ->
        {:error, :unsupported_reaction_chat}

      not nonempty_string?(id) ->
        {:error, :invalid_reaction_target}

      not valid_text?(text) ->
        {:error, :invalid_reaction_text}

      not is_boolean(from_me) ->
        {:error, :invalid_reaction_from_me}

      missing_reaction_participant?(jid, from_me, participant) ->
        {:error, :missing_reaction_participant}

      true ->
        :ok
    end
  end

  def validate(%Message{type: :history_request, to: jid, body: anchor, opts: opts})
      when is_map(anchor) do
    count = Keyword.get(opts, :count, 50)

    cond do
      not supported_chat?(jid) ->
        {:error, :unsupported_history_chat}

      not valid_history_anchor?(anchor) ->
        {:error, :invalid_history_anchor}

      not valid_history_count?(count) ->
        {:error, :invalid_history_count}

      true ->
        :ok
    end
  end

  def validate(%Message{type: :event}), do: {:error, {:invalid_content, :event}}
  def validate(%Message{type: type}), do: {:error, {:invalid_content, type}}

  @spec do_prepare(pid(), map(), Message.t()) :: prepared()
  defp do_prepare(session_pid, state, %Message{type: type, body: source, opts: opts})
       when type in [:image, :video, :sticker, :audio, :document] do
    opts = maybe_put_document_file_name(type, source, opts)

    with {:ok, upload} <- prepare_media_upload(session_pid, state, type, source, opts) do
      {:ok, build_media_proto(type, upload, opts), media_send_options(type, upload, opts)}
    end
  end

  defp do_prepare(
         _session_pid,
         _state,
         %Message{type: :location, body: body, opts: opts}
       )
       when is_map(body) do
    latitude = Map.get(body, :latitude)
    longitude = Map.get(body, :longitude)

    if valid_location?(latitude, longitude) do
      proto = Messages.build_location_proto(latitude, longitude, opts)

      send_opts =
        opts
        |> Keyword.put(:chat_text, Keyword.get(opts, :comment) || Keyword.get(opts, :name))
        |> Keyword.put(:message_node_type, "text")
        |> Keyword.put(
          :outgoing_raw,
          %{content_type: :location, location: Map.merge(body, Map.new(opts))}
        )

      {:ok, proto, send_opts}
    else
      {:error, :invalid_location}
    end
  end

  defp do_prepare(
         _session_pid,
         _state,
         %Message{type: :contact, body: body, opts: opts}
       )
       when is_map(body) do
    display_name = Map.get(body, :display_name)
    vcard = Map.get(body, :vcard)

    if is_binary(display_name) and display_name != "" and is_binary(vcard) and vcard != "" do
      proto = Messages.build_contact_proto(display_name, vcard, opts)

      send_opts =
        opts
        |> Keyword.put(:chat_text, display_name)
        |> Keyword.put(:message_node_type, "media")
        |> Keyword.put(:mediatype, "vcard")
        |> Keyword.put(:outgoing_raw, %{content_type: :contact, contact: body})

      {:ok, proto, send_opts}
    else
      {:error, :invalid_contact}
    end
  end

  defp do_prepare(
         _session_pid,
         _state,
         %Message{type: :event, body: body, opts: opts}
       )
       when is_map(body) do
    name = Map.get(body, :name)
    start_time = Map.get(body, :start_time)

    if is_binary(name) and name != "" and
         (is_integer(start_time) or is_struct(start_time, DateTime)) do
      proto = Messages.build_event_proto(name, start_time, opts)

      send_opts =
        opts
        |> Keyword.put(:chat_text, name)
        |> Keyword.put(:message_node_type, "event")
        |> Keyword.delete(:mediatype)
        |> Keyword.put(:additional_message_nodes, [
          %Binary.Node{tag: "meta", attrs: %{"event_type" => "creation"}, content: nil}
        ])
        |> Keyword.put(:outgoing_raw, %{
          content_type: :event,
          event: Map.merge(body, Map.new(opts))
        })

      {:ok, proto, send_opts}
    else
      {:error, :invalid_event}
    end
  end

  defp do_prepare(_session, _state, %Message{type: :reaction, to: jid, body: body, opts: opts}) do
    proto = Messages.build_reaction_proto(jid, body.message_id, body.text, opts)

    send_opts =
      opts
      |> Keyword.put(:message_node_type, "reaction")
      |> Keyword.put(:reaction_remove, body.text == "")
      |> Keyword.delete(:mediatype)
      |> Keyword.put(:chat_text, nil)
      |> Keyword.put(:outgoing_raw, %{
        content_type: :reaction,
        reaction: %{
          message_id: body.message_id,
          text: body.text,
          from_me: proto.reactionMessage.key.fromMe,
          chat_jid: jid,
          participant: proto.reactionMessage.key.participant,
          sender_timestamp_ms: proto.reactionMessage.senderTimestampMS
        }
      })

    {:ok, proto, send_opts}
  end

  defp do_prepare(_session, _state, %Message{
         type: :history_request,
         to: jid,
         body: anchor,
         opts: opts
       }) do
    {:ok, Messages.build_history_request_proto(jid, anchor, opts), opts}
  end

  defp validate_media_options(opts) do
    invalid =
      Enum.find(opts, fn
        {key, value} when key in [:animated, :gif_playback, :ptt, :view_once] ->
          not is_boolean(value)

        {key, value} when key in [:seconds, :duration, :width, :height] ->
          not (is_integer(value) and value >= 0 and value <= 4_294_967_295)

        {key, value} when key in [:caption, :mimetype, :file_name] ->
          not (is_binary(value) and byte_size(value) <= 65_536 and String.valid?(value))

        {key, value} when key in [:jpeg_thumbnail, :waveform] ->
          not (is_binary(value) and byte_size(value) <= 262_144)

        _ ->
          false
      end)

    case invalid do
      nil -> :ok
      {key, _} -> {:error, {:invalid_media_option, key}}
    end
  end

  defp nonempty_string?(value), do: is_binary(value) and value != "" and String.valid?(value)

  defp valid_text?(value),
    do: is_binary(value) and byte_size(value) <= 128 and String.valid?(value)

  defp missing_reaction_participant?(jid, from_me, participant),
    do: String.ends_with?(jid, "@g.us") and not from_me and not user_jid?(participant)

  defp valid_history_anchor?(%{id: id, from_me: from_me, timestamp: timestamp}),
    do:
      nonempty_string?(id) and not String.starts_with?(id, "history-sync-") and
        is_boolean(from_me) and is_integer(timestamp) and
        timestamp > 0 and timestamp <= 9_223_372_036_854_775_807

  defp valid_history_anchor?(_), do: false

  defp valid_history_count?(count), do: is_integer(count) and count in 1..1000

  defp user_jid?(jid) when is_binary(jid),
    do: String.valid?(jid) and Regex.match?(~r/^\d+(?::\d+)?@(s\.whatsapp\.net|lid)$/, jid)

  defp user_jid?(_), do: false

  defp supported_chat?(jid) when is_binary(jid),
    do: String.valid?(jid) and (user_jid?(jid) or Regex.match?(~r/^\d+(?:-\d+)?@g\.us$/, jid))

  defp supported_chat?(_), do: false

  @spec prepare_media_upload(pid(), map(), Media.media_type(), Media.source(), keyword()) ::
          {:ok, Media.Upload.t()} | {:error, term()}
  defp prepare_media_upload(
         _session_pid,
         _state,
         type,
         %Media.Upload{type: upload_type} = upload,
         _opts
       )
       when upload_type == type,
       do: {:ok, upload}

  defp prepare_media_upload(_session_pid, _state, type, %Media.Upload{type: other}, _opts),
    do: {:error, {:media_type_mismatch, type, other}}

  defp prepare_media_upload(session_pid, state, type, source, opts) do
    with {:ok, bytes} <- Media.read_source(source, opts) do
      Media.HTTP.upload(state, type, bytes, Keyword.put(opts, :session, session_pid))
    end
  end

  @spec build_media_proto(Media.media_type(), Media.Upload.t(), keyword()) :: ProtoMessage.t()
  defp build_media_proto(:image, upload, opts), do: Messages.build_image_proto(upload, opts)
  defp build_media_proto(:video, upload, opts), do: Messages.build_video_proto(upload, opts)
  defp build_media_proto(:sticker, upload, opts), do: Messages.build_sticker_proto(upload, opts)
  defp build_media_proto(:audio, upload, opts), do: Messages.build_audio_proto(upload, opts)
  defp build_media_proto(:document, upload, opts), do: Messages.build_document_proto(upload, opts)

  @spec media_send_options(Media.media_type(), Media.Upload.t(), keyword()) :: keyword()
  defp media_send_options(type, upload, opts) do
    opts
    |> Keyword.put(:chat_text, media_chat_text(type, opts))
    |> Keyword.put(:message_node_type, "media")
    |> Keyword.put(:mediatype, media_stanza_type(type, opts))
    |> Keyword.put(
      :outgoing_raw,
      %{content_type: type, media: Media.ref_from_upload(upload, opts)}
    )
  end

  @spec maybe_put_document_file_name(Media.media_type(), Media.source(), keyword()) :: keyword()
  defp maybe_put_document_file_name(:document, {:path, path}, opts) when is_binary(path),
    do: Keyword.put_new(opts, :file_name, Path.basename(path))

  defp maybe_put_document_file_name(_type, _source, opts), do: opts

  @spec media_chat_text(Media.media_type(), keyword()) :: String.t() | nil
  defp media_chat_text(:image, opts), do: Keyword.get(opts, :caption)
  defp media_chat_text(:document, opts), do: Keyword.get(opts, :caption)
  defp media_chat_text(:video, opts), do: Keyword.get(opts, :caption)
  defp media_chat_text(:sticker, _opts), do: nil
  defp media_chat_text(:audio, _opts), do: nil

  @spec media_stanza_type(Media.media_type(), keyword()) :: String.t()
  defp media_stanza_type(:image, _opts), do: "image"

  defp media_stanza_type(:video, opts),
    do: if(Keyword.get(opts, :gif_playback, false), do: "gif", else: "video")

  defp media_stanza_type(:sticker, _opts), do: "sticker"
  defp media_stanza_type(:document, _opts), do: "document"

  defp media_stanza_type(:audio, opts),
    do: if(Keyword.get(opts, :ptt, false), do: "ptt", else: "audio")

  @spec valid_location?(term(), term()) :: boolean()
  defp valid_location?(latitude, longitude) do
    is_number(latitude) and is_number(longitude) and latitude >= -90 and latitude <= 90 and
      longitude >= -180 and longitude <= 180
  end
end
