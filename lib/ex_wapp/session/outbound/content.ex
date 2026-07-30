defmodule ExWapp.Session.Outbound.Content do
  @moduledoc false

  alias ExWapp.{Binary, Media, Message, Messages}
  alias WAWebProtobufsE2E.Message, as: ProtoMessage
  alias ExWapp.Session.Worker.Outbound

  @type prepared :: {:ok, %ProtoMessage{}, keyword()} | {:error, term()}

  @doc false
  @spec send(pid(), map(), Message.t()) :: {:ok, String.t()} | {:error, term()}
  def send(session_pid, state, %Message{to: jid} = message) do
    state = Map.put(state, :outbound_iq_router, session_pid)

    with {:ok, proto, send_opts} <- prepare(session_pid, state, message) do
      Outbound.send_proto_worker(session_pid, state, jid, proto, send_opts)
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
  def validate(%Message{type: type, body: %Media.Upload{type: type}})
      when type in [:image, :audio, :document],
      do: :ok

  def validate(%Message{type: type, body: %Media.Upload{type: other}})
      when type in [:image, :audio, :document],
      do: {:error, {:media_type_mismatch, type, other}}

  def validate(%Message{type: type, body: {:bytes, bytes}})
      when type in [:image, :audio, :document] and is_binary(bytes),
      do: :ok

  def validate(%Message{type: type, body: {:path, path}})
      when type in [:image, :audio, :document] and is_binary(path),
      do: :ok

  def validate(%Message{type: type, body: source})
      when type in [:image, :audio, :document],
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

  def validate(%Message{type: :event}), do: {:error, {:invalid_content, :event}}
  def validate(%Message{type: type}), do: {:error, {:invalid_content, type}}

  @spec do_prepare(pid(), map(), Message.t()) :: prepared()
  defp do_prepare(session_pid, state, %Message{type: type, body: source, opts: opts})
       when type in [:image, :audio, :document] do
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
    with {:ok, bytes} <- Media.read_source(source) do
      Media.HTTP.upload(state, type, bytes, Keyword.put(opts, :session, session_pid))
    end
  end

  @spec build_media_proto(Media.media_type(), Media.Upload.t(), keyword()) :: %ProtoMessage{}
  defp build_media_proto(:image, upload, opts), do: Messages.build_image_proto(upload, opts)
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
  defp media_chat_text(:audio, _opts), do: nil

  @spec media_stanza_type(Media.media_type(), keyword()) :: String.t()
  defp media_stanza_type(:image, _opts), do: "image"
  defp media_stanza_type(:document, _opts), do: "document"

  defp media_stanza_type(:audio, opts),
    do: if(Keyword.get(opts, :ptt, false), do: "ptt", else: "audio")

  @spec valid_location?(term(), term()) :: boolean()
  defp valid_location?(latitude, longitude) do
    is_number(latitude) and is_number(longitude) and latitude >= -90 and latitude <= 90 and
      longitude >= -180 and longitude <= 180
  end
end
