defmodule ExWapp.Chat do
  @moduledoc """
  Chat and conversation management.

  This module handles:
  - Storing and retrieving conversations
  - Managing chat history
  - Tracking message state (read, delivered, etc.)

  ## Storage

  Chats are persisted via the session's store adapter. The chat data is stored
  under the `:chats` key in the store.

  ## Usage

      # Get all chats from session
      chats = ExWapp.Chat.list(session)

      # Get a specific chat
      {:ok, chat} = ExWapp.Chat.get(session, "1234567890@s.whatsapp.net")

      # Get messages for a chat
      messages = ExWapp.Chat.messages(session, "1234567890@s.whatsapp.net")
  """

  alias ExWapp.{Binary, JID, Store}

  @type message_status :: :pending | :sent | :delivered | :read | :failed

  @type message :: %{
          id: String.t(),
          from_me: boolean(),
          timestamp: integer(),
          text: String.t() | nil,
          status: message_status(),
          participant: String.t() | nil,
          raw: map() | nil
        }

  @type chat :: %{
          jid: String.t(),
          name: String.t() | nil,
          unread_count: non_neg_integer(),
          last_message_timestamp: integer() | nil,
          pinned: boolean(),
          muted_until: integer() | nil,
          archived: boolean(),
          is_group: boolean(),
          messages: [message()]
        }

  defstruct [
    :jid,
    :name,
    unread_count: 0,
    last_message_timestamp: nil,
    pinned: false,
    muted_until: nil,
    archived: false,
    is_group: false,
    messages: []
  ]

  @doc """
  Lists all chats for a session.

  Returns a list of chat structs sorted by last message timestamp (most recent first).
  """
  @spec list(pid()) :: [chat()]
  def list(session) when is_pid(session) do
    store = get_store(session)
    data = Store.load!(store)

    data
    |> Map.get(:chats, %{})
    |> Map.values()
    |> Enum.sort_by(& &1.last_message_timestamp, :desc)
  end

  @doc """
  Gets a specific chat by JID.
  """
  @spec get(pid(), String.t() | JID.t()) :: {:ok, chat()} | {:error, :not_found}
  def get(session, jid) when is_pid(session) do
    jid_str = normalize_jid(jid)
    store = get_store(session)
    data = Store.load!(store)

    case get_in(data, [:chats, jid_str]) do
      nil -> {:error, :not_found}
      chat -> {:ok, chat}
    end
  end

  @doc """
  Gets or creates a chat for a JID.
  """
  @spec get_or_create(pid(), String.t() | JID.t(), keyword()) :: chat()
  def get_or_create(session, jid, opts \\ []) when is_pid(session) do
    # Normalize JID to string
    jid_str = normalize_jid(jid)

    case get(session, jid_str) do
      {:ok, chat} ->
        chat

      {:error, :not_found} ->
        chat = new_chat(jid_str, opts)
        save_chat(session, chat)
        chat
    end
  end

  @doc """
  Creates a new chat struct.
  """
  @spec new_chat(String.t(), keyword()) :: chat()
  def new_chat(jid, opts \\ []) do
    %__MODULE__{
      jid: jid,
      name: Keyword.get(opts, :name),
      is_group: JID.is_group?(jid),
      unread_count: 0,
      messages: []
    }
  end

  @doc """
  Gets messages for a chat, optionally with pagination.
  """
  @spec messages(pid(), String.t() | JID.t(), keyword()) :: [message()]
  def messages(session, jid, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    case get(session, jid) do
      {:ok, chat} ->
        chat.messages
        |> Enum.drop(offset)
        |> Enum.take(limit)

      {:error, _} ->
        []
    end
  end

  @doc """
  Adds a message to a chat.
  """
  @spec add_message(pid(), String.t() | JID.t(), message()) :: :ok
  def add_message(session, jid, message) when is_pid(session) do
    chat = get_or_create(session, jid)

    updated_chat = %{
      chat
      | messages: [message | chat.messages] |> Enum.take(1000),
        last_message_timestamp: message.timestamp,
        unread_count: if(message.from_me, do: chat.unread_count, else: chat.unread_count + 1)
    }

    save_chat(session, updated_chat)
  end

  @doc """
  Marks all messages in a chat as read.
  """
  @spec mark_read(pid(), String.t() | JID.t()) :: :ok
  def mark_read(session, jid) when is_pid(session) do
    case get(session, jid) do
      {:ok, chat} ->
        updated_chat = %{chat | unread_count: 0}
        save_chat(session, updated_chat)

      {:error, _} ->
        :ok
    end
  end

  @doc """
  Updates a message status.
  """
  @spec update_message_status(pid(), String.t() | JID.t(), String.t(), message_status()) :: :ok
  def update_message_status(session, jid, message_id, status) do
    case get(session, jid) do
      {:ok, chat} ->
        updated_messages =
          Enum.map(chat.messages, fn msg ->
            if msg.id == message_id do
              %{msg | status: status}
            else
              msg
            end
          end)

        save_chat(session, %{chat | messages: updated_messages})

      {:error, _} ->
        :ok
    end
  end

  @doc """
  Deletes a chat.
  """
  @spec delete(pid(), String.t()) :: :ok
  def delete(session, jid) when is_pid(session) do
    store = get_store(session)
    data = Store.load!(store)

    updated_data =
      update_in(data, [:chats], fn chats ->
        Map.delete(chats || %{}, jid)
      end)

    Store.persist(store, updated_data)
  end

  @doc """
  Archives a chat.
  """
  @spec archive(pid(), String.t()) :: :ok
  def archive(session, jid) do
    update_chat(session, jid, fn chat -> %{chat | archived: true} end)
  end

  @doc """
  Unarchives a chat.
  """
  @spec unarchive(pid(), String.t()) :: :ok
  def unarchive(session, jid) do
    update_chat(session, jid, fn chat -> %{chat | archived: false} end)
  end

  @doc """
  Pins a chat.
  """
  @spec pin(pid(), String.t()) :: :ok
  def pin(session, jid) do
    update_chat(session, jid, fn chat -> %{chat | pinned: true} end)
  end

  @doc """
  Unpins a chat.
  """
  @spec unpin(pid(), String.t()) :: :ok
  def unpin(session, jid) do
    update_chat(session, jid, fn chat -> %{chat | pinned: false} end)
  end

  @doc """
  Updates the chat name (for contacts that send push names).
  """
  @spec update_name(pid(), String.t(), String.t()) :: :ok
  def update_name(session, jid, name) do
    update_chat(session, jid, fn chat -> %{chat | name: name} end)
  end

  # ============================================================================
  # Message Parsing
  # ============================================================================

  @doc """
  Parses a received message node into a message struct.
  """
  @spec parse_message_node(Binary.Node.t()) :: {:ok, String.t(), message()} | {:error, term()}
  def parse_message_node(%Binary.Node{tag: "message", attrs: attrs, content: content}) do
    with {:ok, from} <- Map.fetch(attrs, "from"),
         {:ok, id} <- Map.fetch(attrs, "id"),
         {:ok, type} <- Map.fetch(attrs, "type") do
      # Normalize JID to string (may come as struct or string)
      jid = normalize_jid(from)
      timestamp = parse_timestamp(Map.get(attrs, "t", "0"))
      participant = Map.get(attrs, "participant")
      from_me = Map.get(attrs, "from_me") == "1"

      text = extract_text(content, type)

      message = %{
        id: id,
        from_me: from_me,
        timestamp: timestamp,
        text: text,
        status: :delivered,
        participant: participant,
        raw: %{type: type, attrs: attrs}
      }

      {:ok, jid, message}
    else
      :error -> {:error, :invalid_message_node}
    end
  end

  def parse_message_node(_), do: {:error, :not_a_message}

  defp extract_text(content, "text") when is_binary(content), do: content

  defp extract_text([%Binary.Node{tag: "enc", content: _enc_content}], _) do
    # Encrypted content - would need Signal decryption
    "(encrypted)"
  end

  defp extract_text(_, _), do: nil

  # ============================================================================
  # Internal Helpers
  # ============================================================================

  defp get_store(session) do
    GenServer.call(session, :get_store)
  catch
    :exit, _ -> nil
  end

  # Normalize JID to string format
  defp normalize_jid(%JID{} = jid), do: JID.to_string(jid)
  defp normalize_jid(jid) when is_binary(jid), do: jid

  # Parse timestamp (may be string or integer)
  defp parse_timestamp(ts) when is_integer(ts), do: ts
  defp parse_timestamp(ts) when is_binary(ts), do: String.to_integer(ts)
  defp parse_timestamp(_), do: 0

  defp save_chat(session, chat) do
    store = get_store(session)

    if store do
      data = Store.load!(store)
      updated_data = put_in(data, [:chats, chat.jid], chat)
      Store.persist(store, updated_data)
    end

    :ok
  end

  defp update_chat(session, jid, update_fn) do
    case get(session, jid) do
      {:ok, chat} ->
        save_chat(session, update_fn.(chat))

      {:error, _} ->
        :ok
    end
  end
end
