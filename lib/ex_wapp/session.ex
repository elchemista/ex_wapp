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
  defdelegate connect(server), to: Worker

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
  defdelegate send_text(server, jid, text), to: Worker

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

  @spec sync_contacts(GenServer.server()) :: :ok | {:error, term()}
  defdelegate sync_contacts(server), to: Worker

  @spec list_contacts(GenServer.server()) :: [ExWapp.Contact.t()]
  defdelegate list_contacts(server), to: Worker

  @spec get_contact(GenServer.server(), String.t()) :: ExWapp.Contact.t() | nil
  defdelegate get_contact(server, jid), to: Worker

  @spec get_chat_info(GenServer.server(), String.t()) ::
          {:ok, ExWapp.Chat.chat()} | {:error, :not_found}
  defdelegate get_chat_info(server, jid), to: Worker
end
