defmodule ExWapp.Client do
  @moduledoc """
  High-level, runtime-neutral ExWapp client.

  Store this struct wherever your application owns session state: a GenServer,
  a GenStateMachine, ETS, a job, or plain functional code in tests/scripts.
  """

  alias ExWapp.{Config, Store}

  defstruct [
    :session_id,
    :store,
    :transport,
    :events,
    :runtime,
    :status,
    :last_error,
    metadata: %{},
    trace: []
  ]

  @type status :: :new | :pairing | :connecting | :connected | :disconnected | :error

  @type t :: %__MODULE__{
          session_id: term() | nil,
          store: Store.t(),
          transport: module(),
          events: module(),
          runtime: map(),
          status: status(),
          last_error: ExWapp.Error.t() | nil,
          metadata: map(),
          trace: [map()]
        }

  @doc """
  Creates a high-level client.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    runtime =
      case Config.resolve(opts) do
        {:ok, cfg} -> cfg
        {:error, reason} -> raise ArgumentError, "invalid runtime config: #{inspect(reason)}"
      end

    %__MODULE__{
      session_id: Keyword.get(opts, :session_id),
      store: Store.new(Keyword.get(opts, :store)),
      transport: Keyword.get(opts, :transport, ExWapp.Client.Transport.Noop),
      events: Keyword.get(opts, :events, ExWapp.Events.Noop),
      runtime: runtime,
      status: Keyword.get(opts, :status, :new),
      metadata: Keyword.get(opts, :metadata, %{}),
      trace: []
    }
  end

  @doc """
  Builds a small wrapper module with default adapters.

  This macro is convenience glue only. It does not start processes, add
  supervision, or hide the client state from the application.
  """
  defmacro __using__(opts) do
    opts =
      opts
      |> expand_client_opts(__CALLER__)
      |> Macro.escape()

    quote do
      @ex_wapp_client_opts unquote(opts)

      @doc "Creates an ExWapp client with this module's default adapters."
      @spec new(keyword()) :: ExWapp.Client.t()
      def new(overrides \\ []) do
        @ex_wapp_client_opts
        |> Keyword.merge(overrides)
        |> ExWapp.new()
      end

      @doc "Connects the client using the configured transport adapter."
      @spec connect(ExWapp.Client.t()) ::
              {:ok, ExWapp.Client.t()} | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def connect(client), do: ExWapp.connect(client)

      @doc "Starts pairing using the configured transport adapter."
      @spec pair(ExWapp.Client.t()) ::
              {:ok, ExWapp.Client.t(), term()} | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def pair(client), do: ExWapp.pair(client)

      @doc "Sends a high-level message."
      @spec send_message(ExWapp.Client.t(), keyword() | ExWapp.Message.t()) ::
              {:ok, ExWapp.Client.t(), String.t()}
              | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def send_message(client, message_or_opts), do: ExWapp.send_message(client, message_or_opts)

      @doc "Processes an inbound payload through the configured transport adapter."
      @spec receive_message(ExWapp.Client.t(), term(), keyword()) ::
              {:ok, ExWapp.Client.t(), [ExWapp.Event.t()]}
              | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def receive_message(client, payload, receive_opts \\ []) do
        ExWapp.receive_message(client, payload, receive_opts)
      end

      @doc "Lists locally known contacts."
      @spec list_contacts(ExWapp.Client.t()) ::
              {:ok, [ExWapp.Contact.t()]} | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def list_contacts(client), do: ExWapp.list_contacts(client)

      @doc "Gets a locally known contact by JID."
      @spec get_contact(ExWapp.Client.t(), String.t()) ::
              {:ok, ExWapp.Contact.t() | nil} | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def get_contact(client, jid), do: ExWapp.get_contact(client, jid)

      @doc "Synchronizes contacts through the configured transport adapter."
      @spec sync_contacts(ExWapp.Client.t()) ::
              {:ok, ExWapp.Client.t()} | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def sync_contacts(client), do: ExWapp.sync_contacts(client)

      @doc "Creates or updates a contact."
      @spec create_contact(ExWapp.Client.t(), String.t(), String.t()) ::
              {:ok, ExWapp.Client.t()} | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def create_contact(client, jid, name), do: ExWapp.create_contact(client, jid, name)

      @doc "Updates a contact."
      @spec update_contact(ExWapp.Client.t(), String.t(), map() | keyword()) ::
              {:ok, ExWapp.Client.t()} | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def update_contact(client, jid, attrs), do: ExWapp.update_contact(client, jid, attrs)

      @doc "Deletes a contact."
      @spec delete_contact(ExWapp.Client.t(), String.t()) ::
              {:ok, ExWapp.Client.t()} | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def delete_contact(client, jid), do: ExWapp.delete_contact(client, jid)

      @doc "Lists locally known chats."
      @spec list_chats(ExWapp.Client.t()) ::
              {:ok, [ExWapp.Chat.chat()]} | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def list_chats(client), do: ExWapp.list_chats(client)

      @doc "Lists locally known group chats."
      @spec list_groups(ExWapp.Client.t()) ::
              {:ok, [ExWapp.Chat.chat()]} | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def list_groups(client), do: ExWapp.list_groups(client)

      @doc "Gets chat metadata by JID."
      @spec get_chat(ExWapp.Client.t(), String.t()) ::
              {:ok, ExWapp.Chat.chat()} | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def get_chat(client, jid), do: ExWapp.get_chat(client, jid)

      @doc "Sends an image message."
      @spec send_image(ExWapp.Client.t(), String.t(), ExWapp.Media.source(), keyword()) ::
              {:ok, ExWapp.Client.t(), String.t()}
              | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def send_image(client, to, source, opts \\ []),
        do: ExWapp.send_image(client, to, source, opts)

      @doc "Sends an audio message."
      @spec send_audio(ExWapp.Client.t(), String.t(), ExWapp.Media.source(), keyword()) ::
              {:ok, ExWapp.Client.t(), String.t()}
              | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def send_audio(client, to, source, opts \\ []),
        do: ExWapp.send_audio(client, to, source, opts)

      @doc "Downloads media referenced by an inbound media message."
      @spec download_media(ExWapp.Client.t(), ExWapp.Media.Ref.t(), keyword()) ::
              {:ok, ExWapp.Client.t(), ExWapp.Media.Download.t()}
              | {:error, ExWapp.Error.t(), ExWapp.Client.t()}
      def download_media(client, ref, opts \\ []), do: ExWapp.download_media(client, ref, opts)
    end
  end

  @spec expand_client_opts(keyword(), Macro.Env.t()) :: keyword()
  defp expand_client_opts(opts, env) when is_list(opts) do
    Enum.map(opts, fn {key, value} -> {key, expand_client_opt_value(value, env)} end)
  end

  @spec expand_client_opt_value(term(), Macro.Env.t()) :: term()
  defp expand_client_opt_value({:__aliases__, _, _} = alias_ast, env) do
    Macro.expand(alias_ast, env)
  end

  defp expand_client_opt_value({left, right}, env) do
    {expand_client_opt_value(left, env), expand_client_opt_value(right, env)}
  end

  defp expand_client_opt_value(value, _env), do: value

  @doc """
  Records a compact trace entry on the client.
  """
  @spec trace(t(), atom(), map()) :: t()
  def trace(%__MODULE__{} = client, operation, metadata \\ %{}) when is_atom(operation) do
    entry = %{
      operation: operation,
      at: System.system_time(:millisecond),
      metadata: metadata
    }

    %{client | trace: [entry | Enum.take(client.trace, 49)]}
  end
end
