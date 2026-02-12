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

  @spec subscribe_qr(GenServer.server()) :: {:ok, reference()}
  defdelegate subscribe_qr(server), to: Worker

  @spec unsubscribe_qr(GenServer.server(), reference()) :: :ok
  defdelegate unsubscribe_qr(server, ref), to: Worker

  @spec send_text(GenServer.server(), binary(), iodata()) :: :ok | {:error, term()}
  defdelegate send_text(server, jid, text), to: Worker

  @spec qr_stream(GenServer.server()) :: Enumerable.t()
  defdelegate qr_stream(server), to: Worker

  @spec subscribe_messages(GenServer.server()) :: {:ok, reference()}
  defdelegate subscribe_messages(server), to: Worker

  @spec unsubscribe_messages(GenServer.server(), reference()) :: :ok
  defdelegate unsubscribe_messages(server, ref), to: Worker

  @spec message_stream(GenServer.server()) :: Enumerable.t()
  defdelegate message_stream(server), to: Worker
end
