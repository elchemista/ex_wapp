defmodule ExWapp.Session do
  @moduledoc """
  Public API facade for WhatsApp session lifecycle and messaging.

  The GenServer implementation lives in `ExWapp.Session.Worker`.
  """

  alias ExWapp.Session.Worker

  @typedoc "Human readable events emitted during the pairing flow."
  @type qr_event :: {:code, String.t()} | :success | {:error, term()}

  @typedoc "Session status"
  @type status :: :idle | :connecting | :handshaking | :connected | :disconnected

  @opaque t :: Worker.t()

  @spec child_spec(term()) :: Supervisor.child_spec()
  defdelegate child_spec(arg), to: Worker

  @spec start_link(keyword()) :: GenServer.on_start()
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

  @spec send_text(GenServer.server(), binary(), iodata()) :: :ok | {:error, term()}
  def send_text(server, jid, text) do
    GenServer.call(
      server,
      {:send_text, jid, IO.iodata_to_binary(text)},
      media_timeout([])
    )
  end

  @spec send_typing(GenServer.server(), binary(), boolean()) :: :ok | {:error, term()}
  def send_typing(server, jid, composing \\ true) do
    GenServer.call(server, {:send_typing, jid, composing})
  end

  @spec send_image(GenServer.server(), binary(), ExWapp.Media.source(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_image(server, jid, source, opts \\ []),
    do: GenServer.call(server, {:send_content, :image, jid, source, opts}, media_timeout(opts))

  @spec send_audio(GenServer.server(), binary(), ExWapp.Media.source(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_audio(server, jid, source, opts \\ []),
    do: GenServer.call(server, {:send_content, :audio, jid, source, opts}, media_timeout(opts))

  @spec send_document(GenServer.server(), binary(), ExWapp.Media.source(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_document(server, jid, source, opts \\ []),
    do: GenServer.call(server, {:send_content, :document, jid, source, opts}, media_timeout(opts))

  @spec send_location(GenServer.server(), binary(), number(), number(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_location(server, jid, latitude, longitude, opts \\ []) do
    body = %{latitude: latitude, longitude: longitude}
    GenServer.call(server, {:send_content, :location, jid, body, opts}, media_timeout(opts))
  end

  @spec send_contact(GenServer.server(), binary(), String.t(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def send_contact(server, jid, display_name, vcard, opts \\ []) do
    body = %{display_name: display_name, vcard: vcard}
    GenServer.call(server, {:send_content, :contact, jid, body, opts}, media_timeout(opts))
  end

  @spec send_event(
          GenServer.server(),
          binary(),
          String.t(),
          integer() | DateTime.t(),
          keyword()
        ) :: {:ok, String.t()} | {:error, term()}
  def send_event(server, jid, name, start_time, opts \\ []) do
    body = %{name: name, start_time: start_time}
    GenServer.call(server, {:send_content, :event, jid, body, opts}, media_timeout(opts))
  end

  @spec download_media(GenServer.server(), ExWapp.Media.Ref.t(), keyword()) ::
          {:ok, ExWapp.Media.Download.t()} | {:error, term()}
  def download_media(server, ref, opts \\ []),
    do: GenServer.call(server, {:download_media, ref, opts}, media_timeout(opts))

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
  defdelegate archive_chat(server, jid), to: Worker

  @spec unarchive_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  defdelegate unarchive_chat(server, jid), to: Worker

  @spec delete_chat(GenServer.server(), String.t()) :: :ok | {:error, term()}
  defdelegate delete_chat(server, jid), to: Worker

  @spec create_contact(GenServer.server(), String.t(), String.t()) :: :ok | {:error, term()}
  defdelegate create_contact(server, jid, name), to: Worker

  @spec delete_contact(GenServer.server(), String.t()) :: :ok | {:error, term()}
  defdelegate delete_contact(server, jid), to: Worker

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
end
