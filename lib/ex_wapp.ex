defmodule ExWapp do
  @moduledoc """
  Runtime-neutral WhatsApp Web protocol client.

  ExWapp exposes a high-level client API and adapter behaviours. It does not
  own supervision, GenServers, queues, sockets, PubSub, or retry policy. Keep
  `%ExWapp.Client{}` in your own process state, or use it directly in scripts
  and tests.
  """

  require Logger

  alias ExWapp.{Chat, Client, Contact, Error, Event, Events, Media, Message}

  @doc """
  Creates a runtime-neutral ExWapp client.
  """
  @spec new(keyword()) :: Client.t()
  def new(opts \\ []), do: Client.new(opts)

  @doc """
  Connects a client through its configured `ExWapp.Client.Transport` adapter.
  """
  @spec connect(Client.t()) :: {:ok, Client.t()} | {:error, Error.t(), Client.t()}
  def connect(%Client{} = client) do
    run_client_operation(client, :connect, fn ->
      client.transport.connect(client)
      |> normalize_connect_result(client)
    end)
  end

  @doc """
  Starts pairing through the configured transport adapter.
  """
  @spec pair(Client.t()) :: {:ok, Client.t(), term()} | {:error, Error.t(), Client.t()}
  def pair(%Client{} = client) do
    run_client_operation(client, :pair, fn ->
      if adapter_exports?(client.transport, :pair, 1) do
        client.transport.pair(client)
        |> normalize_pair_result(client)
      else
        fail_client(client, :pair, :transport, :pair_not_supported)
      end
    end)
  end

  @doc """
  Disconnects through the configured transport adapter when it supports
  `disconnect/1`; otherwise marks the local client as disconnected.
  """
  @spec disconnect(Client.t()) :: {:ok, Client.t()} | {:error, Error.t(), Client.t()}
  def disconnect(%Client{} = client) do
    run_client_operation(client, :disconnect, fn ->
      if adapter_exports?(client.transport, :disconnect, 1) do
        client.transport.disconnect(client)
        |> normalize_disconnect_result(client)
      else
        disconnected =
          client
          |> Map.put(:status, :disconnected)
          |> Client.trace(:disconnect, %{adapter: :not_supported})

        emit_client_event(disconnected, :disconnected, %{reason: :local})
        {:ok, disconnected}
      end
    end)
  end

  @doc """
  Sends a high-level message through the configured transport adapter.

  Accepts either an `%ExWapp.Message{}` or keyword options:

      ExWapp.send_message(client, to: jid, text: "hello")
      ExWapp.send_message(client, ExWapp.Message.text(jid, "hello"))
  """
  @spec send_message(Client.t(), keyword() | Message.t()) ::
          {:ok, Client.t(), String.t()} | {:error, Error.t(), Client.t()}
  def send_message(%Client{} = client, %Message{} = message) do
    run_client_operation(client, :send_message, fn ->
      do_send_message(client, message)
    end)
  end

  def send_message(%Client{} = client, opts) when is_list(opts) do
    run_client_operation(client, :send_message, fn ->
      case build_message_from_opts(opts) do
        {:ok, message} ->
          do_send_message(client, message)

        {:error, reason} ->
          fail_client(client, :send_message, :build_message, reason)
      end
    end)
  end

  @doc """
  Processes an inbound adapter payload.
  """
  @spec receive_message(Client.t(), term(), keyword()) ::
          {:ok, Client.t(), [Event.t()]} | {:error, Error.t(), Client.t()}
  def receive_message(%Client{} = client, payload, opts \\ []) do
    run_client_operation(client, :receive_message, fn ->
      if adapter_exports?(client.transport, :receive_message, 3) do
        client.transport.receive_message(client, payload, opts)
        |> normalize_receive_result(client)
      else
        fail_client(client, :receive_message, :transport, :receive_not_supported)
      end
    end)
  end

  @doc """
  Lists locally known contacts through the configured transport adapter.
  """
  @spec list_contacts(Client.t()) :: {:ok, [Contact.t()]} | {:error, Error.t(), Client.t()}
  def list_contacts(%Client{} = client) do
    run_client_operation(client, :list_contacts, fn ->
      if adapter_exports?(client.transport, :list_contacts, 1) do
        client.transport.list_contacts(client)
        |> normalize_list_result(client, :list_contacts, :contacts)
      else
        fail_client(client, :list_contacts, :transport, :contacts_not_supported)
      end
    end)
  end

  @doc """
  Gets a locally known contact by JID.
  """
  @spec get_contact(Client.t(), String.t()) ::
          {:ok, Contact.t() | nil} | {:error, Error.t(), Client.t()}
  def get_contact(%Client{} = client, jid) when is_binary(jid) do
    run_client_operation(client, :get_contact, fn ->
      if adapter_exports?(client.transport, :get_contact, 2) do
        client.transport.get_contact(client, jid)
        |> normalize_value_result(client, :get_contact, :contact)
      else
        fail_client(client, :get_contact, :transport, :contacts_not_supported)
      end
    end)
  end

  @doc """
  Requests a contact app-state sync through the configured transport adapter.
  """
  @spec sync_contacts(Client.t()) :: {:ok, Client.t()} | {:error, Error.t(), Client.t()}
  def sync_contacts(%Client{} = client) do
    run_client_operation(client, :sync_contacts, fn ->
      if adapter_exports?(client.transport, :sync_contacts, 1) do
        client.transport.sync_contacts(client)
        |> normalize_client_result(client, :sync_contacts, :contacts_synced, %{})
      else
        fail_client(client, :sync_contacts, :transport, :contacts_not_supported)
      end
    end)
  end

  @doc """
  Creates or updates a server-synced contact.
  """
  @spec create_contact(Client.t(), String.t(), String.t()) ::
          {:ok, Client.t()} | {:error, Error.t(), Client.t()}
  def create_contact(%Client{} = client, jid, name) when is_binary(jid) and is_binary(name) do
    run_client_operation(client, :create_contact, fn ->
      if adapter_exports?(client.transport, :create_contact, 3) do
        client.transport.create_contact(client, jid, name)
        |> normalize_client_result(client, :create_contact, :contact_created, %{jid: jid})
      else
        fail_client(client, :create_contact, :transport, :contacts_not_supported)
      end
    end)
  end

  @doc """
  Updates contact fields when the configured transport supports it.
  """
  @spec update_contact(Client.t(), String.t(), map() | keyword()) ::
          {:ok, Client.t()} | {:error, Error.t(), Client.t()}
  def update_contact(%Client{} = client, jid, attrs) when is_binary(jid) do
    run_client_operation(client, :update_contact, fn ->
      if adapter_exports?(client.transport, :update_contact, 3) do
        client.transport.update_contact(client, jid, attrs)
        |> normalize_client_result(client, :update_contact, :contact_updated, %{jid: jid})
      else
        fail_client(client, :update_contact, :transport, :contacts_not_supported)
      end
    end)
  end

  @doc """
  Deletes a server-synced contact.
  """
  @spec delete_contact(Client.t(), String.t()) ::
          {:ok, Client.t()} | {:error, Error.t(), Client.t()}
  def delete_contact(%Client{} = client, jid) when is_binary(jid) do
    run_client_operation(client, :delete_contact, fn ->
      if adapter_exports?(client.transport, :delete_contact, 2) do
        client.transport.delete_contact(client, jid)
        |> normalize_client_result(client, :delete_contact, :contact_deleted, %{jid: jid})
      else
        fail_client(client, :delete_contact, :transport, :contacts_not_supported)
      end
    end)
  end

  @doc """
  Lists locally known chats.
  """
  @spec list_chats(Client.t()) :: {:ok, [Chat.chat()]} | {:error, Error.t(), Client.t()}
  def list_chats(%Client{} = client) do
    run_client_operation(client, :list_chats, fn ->
      if adapter_exports?(client.transport, :list_chats, 1) do
        client.transport.list_chats(client)
        |> normalize_list_result(client, :list_chats, :chats)
      else
        fail_client(client, :list_chats, :transport, :chats_not_supported)
      end
    end)
  end

  @doc """
  Lists locally known group chats.
  """
  @spec list_groups(Client.t()) :: {:ok, [Chat.chat()]} | {:error, Error.t(), Client.t()}
  def list_groups(%Client{} = client) do
    run_client_operation(client, :list_groups, fn ->
      if adapter_exports?(client.transport, :list_groups, 1) do
        client.transport.list_groups(client)
        |> normalize_list_result(client, :list_groups, :groups)
      else
        fail_client(client, :list_groups, :transport, :groups_not_supported)
      end
    end)
  end

  @doc """
  Gets a locally known chat by JID.
  """
  @spec get_chat(Client.t(), String.t()) :: {:ok, Chat.chat()} | {:error, Error.t(), Client.t()}
  def get_chat(%Client{} = client, jid) when is_binary(jid) do
    run_client_operation(client, :get_chat, fn ->
      if adapter_exports?(client.transport, :get_chat, 2) do
        client.transport.get_chat(client, jid)
        |> normalize_value_result(client, :get_chat, :chat)
      else
        fail_client(client, :get_chat, :transport, :chats_not_supported)
      end
    end)
  end

  @doc """
  Sends an image message.
  """
  @spec send_image(Client.t(), String.t(), Media.source(), keyword()) ::
          {:ok, Client.t(), String.t()} | {:error, Error.t(), Client.t()}
  def send_image(%Client{} = client, to, source, opts \\ []) do
    send_message(client, Message.image(to, source, opts))
  end

  @doc """
  Sends an audio message.
  """
  @spec send_audio(Client.t(), String.t(), Media.source(), keyword()) ::
          {:ok, Client.t(), String.t()} | {:error, Error.t(), Client.t()}
  def send_audio(%Client{} = client, to, source, opts \\ []) do
    send_message(client, Message.audio(to, source, opts))
  end

  @doc """
  Downloads media referenced by an inbound media message.
  """
  @spec download_media(Client.t(), Media.Ref.t(), keyword()) ::
          {:ok, Client.t(), Media.Download.t()} | {:error, Error.t(), Client.t()}
  def download_media(%Client{} = client, %Media.Ref{} = ref, opts \\ []) do
    run_client_operation(client, :download_media, fn ->
      if adapter_exports?(client.transport, :download_media, 3) do
        client.transport.download_media(client, ref, opts)
        |> normalize_download_result(client)
      else
        fail_client(client, :download_media, :transport, :media_not_supported)
      end
    end)
  end

  @doc """
  Returns the high-level client status.
  """
  @spec status(Client.t()) :: Client.status()
  def status(%Client{} = client), do: client.status

  @doc """
  Returns the last structured client error, if any.
  """
  @spec last_error(Client.t()) :: Error.t() | nil
  def last_error(%Client{} = client), do: client.last_error

  @doc """
  Returns compact diagnostics for a high-level client.
  """
  @spec diagnostics(Client.t()) :: map()
  def diagnostics(%Client{} = client) do
    %{
      session_id: client.session_id,
      status: client.status,
      transport: client.transport,
      events: client.events,
      store: client.store.__struct__,
      last_error: client.last_error,
      trace: client.trace
    }
  end

  @spec run_client_operation(Client.t(), atom(), (-> term())) :: term()
  defp run_client_operation(%Client{} = client, operation, fun)
       when is_atom(operation) and is_function(fun, 0) do
    start = System.monotonic_time()
    metadata = client_metadata(client, operation)

    Logger.debug("[ExWapp] #{operation} start session_id=#{inspect(client.session_id)}")

    ExWapp.Telemetry.execute(
      [:ex_wapp, :client, operation, :start],
      %{system_time: System.system_time()},
      metadata
    )

    try do
      result = fun.()
      duration = System.monotonic_time() - start

      case result do
        {:error, error, _client} ->
          Logger.error("[ExWapp] #{operation} failed reason=#{inspect(error)}")

        _ ->
          Logger.info("[ExWapp] #{operation} ok session_id=#{inspect(client.session_id)}")
      end

      ExWapp.Telemetry.execute(
        [:ex_wapp, :client, operation, :stop],
        %{duration: duration},
        metadata
      )

      result
    rescue
      exception ->
        duration = System.monotonic_time() - start
        stacktrace = __STACKTRACE__

        Logger.error(
          "[ExWapp] #{operation} exception=#{Exception.format(:error, exception, stacktrace)}"
        )

        ExWapp.Telemetry.execute(
          [:ex_wapp, :client, operation, :exception],
          %{duration: duration},
          Map.put(metadata, :kind, :error)
        )

        reraise exception, stacktrace
    catch
      kind, reason ->
        duration = System.monotonic_time() - start

        Logger.error(
          "[ExWapp] #{operation} throw/exit kind=#{inspect(kind)} reason=#{inspect(reason)}"
        )

        ExWapp.Telemetry.execute(
          [:ex_wapp, :client, operation, :exception],
          %{duration: duration},
          Map.merge(metadata, %{kind: kind, reason: inspect(reason)})
        )

        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end

  @spec client_metadata(Client.t(), atom()) :: map()
  defp client_metadata(%Client{} = client, operation) do
    %{
      session_id: client.session_id,
      operation: operation,
      transport: client.transport,
      events: client.events
    }
  end

  @spec adapter_exports?(module(), atom(), non_neg_integer()) :: boolean()
  defp adapter_exports?(module, function, arity) do
    Code.ensure_loaded?(module) and function_exported?(module, function, arity)
  end

  @spec do_send_message(Client.t(), Message.t()) ::
          {:ok, Client.t(), String.t()} | {:error, Error.t(), Client.t()}
  defp do_send_message(%Client{} = client, %Message{} = message) do
    message = ensure_message_id(message)

    client.transport.send_message(client, message)
    |> normalize_send_result(client, message)
  end

  @spec build_message_from_opts(keyword()) :: {:ok, Message.t()} | {:error, term()}
  defp build_message_from_opts(opts) do
    type = Keyword.get(opts, :type, :text)

    case type do
      :text ->
        with {:ok, to} <- fetch_required(opts, :to),
             {:ok, text} <- fetch_required_text(opts) do
          message_opts = Keyword.drop(opts, [:to, :text, :body, :type])
          {:ok, Message.text(to, text, message_opts)}
        end

      :typing ->
        with {:ok, to} <- fetch_required(opts, :to) do
          composing = Keyword.get(opts, :composing, true)
          message_opts = Keyword.drop(opts, [:to, :type, :composing])
          {:ok, Message.typing(to, composing, message_opts)}
        end

      :read_receipt ->
        with {:ok, to} <- fetch_required(opts, :to),
             {:ok, ids} <- fetch_required(opts, :message_ids) do
          message_opts = Keyword.drop(opts, [:to, :type, :message_ids])
          {:ok, Message.read_receipt(to, ids, message_opts)}
        end

      :image ->
        with {:ok, to} <- fetch_required(opts, :to),
             {:ok, source} <- fetch_media_source(opts) do
          message_opts = Keyword.drop(opts, [:to, :type, :source, :path, :bytes, :upload])
          {:ok, Message.image(to, source, message_opts)}
        end

      :audio ->
        with {:ok, to} <- fetch_required(opts, :to),
             {:ok, source} <- fetch_media_source(opts) do
          message_opts = Keyword.drop(opts, [:to, :type, :source, :path, :bytes, :upload])
          {:ok, Message.audio(to, source, message_opts)}
        end

      other ->
        {:error, {:unsupported_message_type, other}}
    end
  end

  @spec fetch_required(keyword(), atom()) :: {:ok, term()} | {:error, {:missing_required, atom()}}
  defp fetch_required(opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_required, key}}
    end
  end

  @spec fetch_required_text(keyword()) :: {:ok, term()} | {:error, {:missing_required, atom()}}
  defp fetch_required_text(opts) do
    case Keyword.fetch(opts, :text) do
      {:ok, value} -> {:ok, value}
      :error -> fetch_required(opts, :body)
    end
  end

  @spec fetch_media_source(keyword()) ::
          {:ok, Media.source()} | {:error, {:missing_required, atom()}}
  defp fetch_media_source(opts) do
    cond do
      Keyword.has_key?(opts, :source) -> {:ok, Keyword.fetch!(opts, :source)}
      Keyword.has_key?(opts, :path) -> {:ok, {:path, Keyword.fetch!(opts, :path)}}
      Keyword.has_key?(opts, :bytes) -> {:ok, {:bytes, Keyword.fetch!(opts, :bytes)}}
      Keyword.has_key?(opts, :upload) -> {:ok, Keyword.fetch!(opts, :upload)}
      true -> {:error, {:missing_required, :source}}
    end
  end

  @spec ensure_message_id(Message.t()) :: Message.t()
  defp ensure_message_id(%Message{id: id} = message) when is_binary(id) and id != "" do
    message
  end

  defp ensure_message_id(%Message{} = message) do
    %{message | id: ExWapp.Messages.generate_id()}
  end

  @spec normalize_pair_result(term(), Client.t()) ::
          {:ok, Client.t(), term()} | {:error, Error.t(), Client.t()}
  defp normalize_pair_result({:ok, %Client{} = client, qr}, _original) do
    client =
      client
      |> Map.put(:status, :pairing)
      |> Client.trace(:pair, %{result: :ok})

    emit_client_event(client, :qr, qr)
    {:ok, client, qr}
  end

  defp normalize_pair_result({:ok, qr}, original) do
    normalize_pair_result({:ok, original, qr}, original)
  end

  defp normalize_pair_result({:error, reason}, original) do
    fail_client(original, :pair, :transport, reason)
  end

  defp normalize_pair_result(other, original) do
    fail_client(original, :pair, :transport, {:bad_return, other})
  end

  @spec normalize_connect_result(term(), Client.t()) ::
          {:ok, Client.t()} | {:error, Error.t(), Client.t()}
  defp normalize_connect_result({:ok, %Client{} = client}, _original) do
    status =
      case client.status do
        :new -> :connected
        nil -> :connected
        other -> other
      end

    client =
      client
      |> Map.put(:status, status)
      |> Client.trace(:connect, %{result: :ok})

    emit_client_event(client, :status, status)
    {:ok, client}
  end

  defp normalize_connect_result(:ok, original) do
    normalize_connect_result({:ok, original}, original)
  end

  defp normalize_connect_result({:error, reason}, original) do
    fail_client(original, :connect, :transport, reason)
  end

  defp normalize_connect_result(other, original) do
    fail_client(original, :connect, :transport, {:bad_return, other})
  end

  @spec normalize_disconnect_result(term(), Client.t()) ::
          {:ok, Client.t()} | {:error, Error.t(), Client.t()}
  defp normalize_disconnect_result({:ok, %Client{} = client}, _original) do
    client =
      client
      |> Map.put(:status, :disconnected)
      |> Client.trace(:disconnect, %{result: :ok})

    emit_client_event(client, :disconnected, %{reason: :adapter})
    {:ok, client}
  end

  defp normalize_disconnect_result(:ok, original) do
    normalize_disconnect_result({:ok, original}, original)
  end

  defp normalize_disconnect_result({:error, reason}, original) do
    fail_client(original, :disconnect, :transport, reason)
  end

  defp normalize_disconnect_result(other, original) do
    fail_client(original, :disconnect, :transport, {:bad_return, other})
  end

  @spec normalize_send_result(term(), Client.t(), Message.t()) ::
          {:ok, Client.t(), String.t()} | {:error, Error.t(), Client.t()}
  defp normalize_send_result({:ok, %Client{} = client, message_id}, _original, message) do
    client = Client.trace(client, :send_message, %{message_id: message_id, to: message.to})

    emit_client_event(client, :message_sent, %{id: message_id, to: message.to, type: message.type})

    {:ok, client, message_id}
  end

  defp normalize_send_result({:ok, message_id}, original, message) when is_binary(message_id) do
    normalize_send_result({:ok, original, message_id}, original, message)
  end

  defp normalize_send_result(:ok, original, %Message{id: message_id} = message) do
    normalize_send_result({:ok, original, message_id}, original, message)
  end

  defp normalize_send_result({:error, %Client{} = client, reason}, _original, message) do
    fail_client(client, :send_message, :transport, reason, message_id: message.id)
  end

  defp normalize_send_result({:error, reason}, original, message) do
    fail_client(original, :send_message, :transport, reason, message_id: message.id)
  end

  defp normalize_send_result(other, original, message) do
    fail_client(original, :send_message, :transport, {:bad_return, other}, message_id: message.id)
  end

  @spec normalize_receive_result(term(), Client.t()) ::
          {:ok, Client.t(), [Event.t()]} | {:error, Error.t(), Client.t()}
  defp normalize_receive_result({:ok, %Client{} = client, events}, _original)
       when is_list(events) do
    client = Client.trace(client, :receive_message, %{events: length(events)})
    Events.emit_many(client, events)
    {:ok, client, events}
  end

  defp normalize_receive_result({:ok, events}, original) when is_list(events) do
    normalize_receive_result({:ok, original, events}, original)
  end

  defp normalize_receive_result({:error, reason}, original) do
    fail_client(original, :receive_message, :transport, reason)
  end

  defp normalize_receive_result(other, original) do
    fail_client(original, :receive_message, :transport, {:bad_return, other})
  end

  @spec normalize_list_result(term(), Client.t(), atom(), atom()) ::
          {:ok, list()} | {:error, Error.t(), Client.t()}
  defp normalize_list_result({:ok, values}, _original, _operation, _label) when is_list(values),
    do: {:ok, values}

  defp normalize_list_result({:error, reason}, original, operation, _label),
    do: fail_client(original, operation, :transport, reason)

  defp normalize_list_result(other, original, operation, label),
    do: fail_client(original, operation, :transport, {:bad_return, label, other})

  @spec normalize_value_result(term(), Client.t(), atom(), atom()) ::
          {:ok, term()} | {:error, Error.t(), Client.t()}
  defp normalize_value_result({:ok, value}, _original, _operation, _label), do: {:ok, value}

  defp normalize_value_result({:error, reason}, original, operation, _label),
    do: fail_client(original, operation, :transport, reason)

  defp normalize_value_result(other, original, operation, label),
    do: fail_client(original, operation, :transport, {:bad_return, label, other})

  @spec normalize_client_result(term(), Client.t(), atom(), Event.type(), term()) ::
          {:ok, Client.t()} | {:error, Error.t(), Client.t()}
  defp normalize_client_result(
         {:ok, %Client{} = client},
         _original,
         operation,
         event_type,
         payload
       ) do
    client = Client.trace(client, operation, %{result: :ok})
    emit_client_event(client, event_type, payload)
    {:ok, client}
  end

  defp normalize_client_result(:ok, original, operation, event_type, payload) do
    normalize_client_result({:ok, original}, original, operation, event_type, payload)
  end

  defp normalize_client_result({:error, reason}, original, operation, _event_type, _payload),
    do: fail_client(original, operation, :transport, reason)

  defp normalize_client_result(other, original, operation, _event_type, _payload),
    do: fail_client(original, operation, :transport, {:bad_return, other})

  @spec normalize_download_result(term(), Client.t()) ::
          {:ok, Client.t(), Media.Download.t()} | {:error, Error.t(), Client.t()}
  defp normalize_download_result(
         {:ok, %Client{} = client, %Media.Download{} = download},
         _original
       ) do
    client = Client.trace(client, :download_media, %{bytes: byte_size(download.bytes)})
    emit_client_event(client, :media_downloaded, download.ref)
    {:ok, client, download}
  end

  defp normalize_download_result({:ok, %Media.Download{} = download}, original) do
    normalize_download_result({:ok, original, download}, original)
  end

  defp normalize_download_result({:error, reason}, original) do
    fail_client(original, :download_media, :transport, reason)
  end

  defp normalize_download_result(other, original) do
    fail_client(original, :download_media, :transport, {:bad_return, other})
  end

  @spec fail_client(Client.t(), atom(), atom() | nil, term(), keyword()) ::
          {:error, Error.t(), Client.t()}
  defp fail_client(%Client{} = client, operation, phase, reason, opts \\ []) do
    error =
      Error.new(operation, phase, reason,
        message_id: Keyword.get(opts, :message_id),
        metadata: Keyword.get(opts, :metadata, %{})
      )

    failed =
      client
      |> Map.put(:status, :error)
      |> Map.put(:last_error, error)
      |> Client.trace(operation, %{result: :error, phase: phase, reason: reason})

    emit_client_event(failed, :error, error)
    {:error, error, failed}
  end

  @spec emit_client_event(Client.t(), Event.type(), term()) :: :ok
  defp emit_client_event(%Client{} = client, type, payload) do
    event = Event.new(type, payload, session_id: client.session_id)

    case Events.emit(client, event) do
      :ok -> :ok
      {:error, _reason} -> :ok
    end
  end
end
