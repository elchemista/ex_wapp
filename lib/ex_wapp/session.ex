defmodule ExWapp.Session do
  @moduledoc """
  Internal facade for the built-in WhatsApp session engine.

  The GenServer implementation lives in `ExWapp.Session.Worker`. This module is
  used by `ExWapp.Client.Transport.Session`; it is documented for maintainers
  and custom transport authors, but it is not part of ExWapp's stable public
  API. Applications should use the `%ExWapp.Client{}` API through `ExWapp`.
  """

  alias ExWapp.Message
  alias ExWapp.Session.AppStateCommands
  alias ExWapp.Session.Options
  alias ExWapp.Session.Worker

  @typedoc "Human readable events emitted during the pairing flow."
  @type qr_event ::
          {:code, String.t()} | {:pairing_code, String.t()} | :success | {:error, term()}

  @typedoc "Session status"
  @type status :: :idle | :connecting | :handshaking | :syncing | :connected | :disconnected

  @opaque t :: Worker.t()

  @spec child_spec(term()) :: Supervisor.child_spec()
  defdelegate child_spec(arg), to: Worker

  @spec start_link(keyword() | Options.t()) :: GenServer.on_start()
  defdelegate start_link(opts), to: Worker

  @spec connect(GenServer.server()) :: :ok
  def connect(server), do: GenServer.cast(server, :connect)

  @spec disconnect(GenServer.server()) :: :ok
  defdelegate disconnect(server), to: Worker

  @spec state(GenServer.server()) :: status()
  defdelegate state(server), to: Worker

  @spec stats(GenServer.server()) :: map()
  defdelegate stats(server), to: Worker

  @spec get_session_id(GenServer.server()) :: term() | nil
  defdelegate get_session_id(server), to: Worker

  @spec runtime_config(GenServer.server()) :: map()
  defdelegate runtime_config(server), to: Worker, as: :get_runtime_config

  @spec policy_status(GenServer.server()) :: map()
  defdelegate policy_status(server), to: Worker, as: :get_policy_status

  @spec health_status(GenServer.server()) :: map()
  defdelegate health_status(server), to: Worker, as: :get_health_status

  @spec subscribe_qr(GenServer.server()) :: {:ok, reference()}
  defdelegate subscribe_qr(server), to: Worker

  @spec unsubscribe_qr(GenServer.server(), reference()) :: :ok
  defdelegate unsubscribe_qr(server, ref), to: Worker

  @doc """
  Requests an eight-character phone-number pairing code.

  Call this after `connect/1`, once the Noise transport has entered the
  handshaking state. `:custom_code` may be supplied and must contain exactly
  eight bytes.
  """
  @spec request_pairing_code(GenServer.server(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  defdelegate request_pairing_code(server, phone, opts \\ []), to: Worker

  @spec send_text(GenServer.server(), binary(), iodata(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_text(server, jid, text, opts \\ []) when is_list(opts) do
    jid
    |> Message.text(text, message_options(opts))
    |> then(&send_message(server, &1))
  end

  @doc """
  Sends a canonical outbound message through the session engine.

  The message ID, when present, is preserved through encryption and transport.
  """
  @spec send_message(GenServer.server(), Message.t()) ::
          {:ok, String.t()} | {:error, term()}
  def send_message(server, %Message{} = message) do
    GenServer.call(server, {:send_message, message}, message_timeout(message))
  end

  @spec send_typing(GenServer.server(), binary(), boolean()) :: :ok | {:error, term()}
  def send_typing(server, jid, composing \\ true) do
    GenServer.call(server, {:send_typing, jid, composing})
  end

  @spec send_image(GenServer.server(), binary(), ExWapp.Media.source(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_image(server, jid, source, opts \\ []) do
    jid
    |> Message.image(source, message_options(opts))
    |> then(&send_message(server, &1))
  end

  @spec send_audio(GenServer.server(), binary(), ExWapp.Media.source(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_audio(server, jid, source, opts \\ []) do
    jid
    |> Message.audio(source, message_options(opts))
    |> then(&send_message(server, &1))
  end

  @spec send_document(GenServer.server(), binary(), ExWapp.Media.source(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_document(server, jid, source, opts \\ []) do
    jid
    |> Message.document(source, message_options(opts))
    |> then(&send_message(server, &1))
  end

  @spec send_location(GenServer.server(), binary(), number(), number(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_location(server, jid, latitude, longitude, opts \\ []) do
    jid
    |> Message.location(latitude, longitude, message_options(opts))
    |> then(&send_message(server, &1))
  end

  @spec send_contact(GenServer.server(), binary(), String.t(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_contact(server, jid, display_name, vcard, opts \\ []) do
    jid
    |> Message.contact(display_name, vcard, message_options(opts))
    |> then(&send_message(server, &1))
  end

  @spec send_event(
          GenServer.server(),
          binary(),
          String.t(),
          integer() | DateTime.t(),
          keyword()
        ) :: {:ok, String.t()} | {:error, term()}
  def send_event(server, jid, name, start_time, opts \\ []) do
    jid
    |> Message.event(name, start_time, message_options(opts))
    |> then(&send_message(server, &1))
  end

  @spec download_media(GenServer.server(), ExWapp.Media.Ref.t(), keyword()) ::
          {:ok, ExWapp.Media.Download.t()} | {:error, term()}
  def download_media(server, ref, opts \\ []),
    do: GenServer.call(server, {:download_media, ref, opts}, media_timeout(opts))

  @doc """
  Asks the sender's phone to re-upload an expired media object.

  The message must still exist in the local message store so its media key and
  conversation envelope can be authenticated on the wire.
  """
  @spec retry_media(GenServer.server(), String.t(), keyword()) ::
          {:ok, ExWapp.Media.Ref.t()} | {:error, term()}
  def retry_media(server, message_id, opts \\ []) when is_binary(message_id) do
    timeout = Keyword.get(opts, :timeout, 30_000)
    call_timeout = if is_integer(timeout) and timeout > 0, do: timeout + 1_000, else: 31_000
    GenServer.call(server, {:retry_media, message_id, opts}, call_timeout)
  end

  @spec flush_store(GenServer.server()) :: :ok | {:error, term()}
  def flush_store(server) do
    server
    |> GenServer.call(:get_store)
    |> flush_store_adapter()
  end

  @doc """
  Flushes the session store and exports its complete local snapshot.

  The result includes decoded `:data`, the serialized `:blob`, and a SHA-256
  `:checksum`. This is useful for backups or wrapper-level database imports.
  It reflects local state only and does not request additional server history.
  """
  @spec export_snapshot(GenServer.server()) :: {:ok, map()} | {:error, term()}
  def export_snapshot(server) do
    store = GenServer.call(server, :get_store)

    with :ok <- flush_store_adapter(store),
         {:ok, data} <- ExWapp.Store.snapshot(store) do
      blob = :erlang.term_to_binary(data)

      {:ok,
       %{
         data: data,
         blob: blob,
         checksum: :crypto.hash(:sha256, blob) |> Base.encode16(case: :lower)
       }}
    end
  end

  @spec pause_sends(GenServer.server()) :: :ok
  defdelegate pause_sends(server), to: Worker

  @spec resume_sends(GenServer.server()) :: :ok
  defdelegate resume_sends(server), to: Worker

  @spec stop_worker(GenServer.server()) :: :ok
  defdelegate stop_worker(server), to: Worker

  @spec qr_stream(GenServer.server()) :: Enumerable.t()
  defdelegate qr_stream(server), to: Worker

  @spec message_stream(GenServer.server()) :: Enumerable.t()
  defdelegate message_stream(server), to: Worker

  # ── App State Sync (server-synced operations) ──

  @spec send_app_state(GenServer.server(), map()) :: {:ok, map(), map()} | {:error, term()}
  defdelegate send_app_state(server, patch_info), to: Worker

  @spec archive_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  defdelegate archive_chat(server, jid), to: AppStateCommands

  @spec unarchive_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  defdelegate unarchive_chat(server, jid), to: AppStateCommands

  @spec delete_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  defdelegate delete_chat(server, jid), to: AppStateCommands

  @spec create_contact(GenServer.server(), String.t(), String.t()) :: :ok | {:error, term()}
  defdelegate create_contact(server, jid, name), to: AppStateCommands

  @spec delete_contact(GenServer.server(), String.t()) :: :ok | {:error, term()}
  defdelegate delete_contact(server, jid), to: AppStateCommands

  @doc """
  Refreshes contact-related app-state data from the server.

  This operation updates contacts only; it does not request complete chat
  history.
  """
  @spec sync_contacts(GenServer.server()) :: :ok | {:error, term()}
  defdelegate sync_contacts(server), to: Worker

  @doc "Lists contacts currently present in the session store."
  @spec list_contacts(GenServer.server()) :: [ExWapp.Contact.t()]
  defdelegate list_contacts(server), to: Worker

  @doc "Gets one contact from the session store, or `nil` when it is unknown."
  @spec get_contact(GenServer.server(), String.t()) :: ExWapp.Contact.t() | nil
  defdelegate get_contact(server, jid), to: Worker

  @spec get_chat_info(GenServer.server(), String.t()) ::
          {:ok, ExWapp.Chat.chat()} | {:error, :not_found}
  defdelegate get_chat_info(server, jid), to: Worker

  defp flush_store_adapter(nil), do: :ok

  defp flush_store_adapter(%_{} = store) do
    if function_exported?(store.__struct__, :flush, 1) do
      store.__struct__.flush(store)
    else
      :ok
    end
  rescue
    exception -> {:error, exception}
  end

  @spec media_timeout(keyword()) :: timeout()
  defp media_timeout(opts), do: Keyword.get(opts, :timeout, 60_000)

  defp message_timeout(%Message{opts: opts}) when is_list(opts), do: media_timeout(opts)
  defp message_timeout(%Message{}), do: 60_000

  defp message_options(opts) when is_list(opts) do
    case Keyword.get(opts, :retry_message_id) do
      message_id when is_binary(message_id) and message_id != "" ->
        Keyword.put_new(opts, :id, message_id)

      _other ->
        opts
    end
  end
end
