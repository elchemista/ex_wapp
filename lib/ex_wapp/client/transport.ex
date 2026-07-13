defmodule ExWapp.Client.Transport do
  @moduledoc """
  Behaviour for high-level, runtime-neutral ExWapp client adapters.

  The `Transport` name is retained for API compatibility, but this is not a
  wire transport. The adapter is owned by the host application and connects the
  public client API to a complete runtime, session, queue, or test double.

  Production WhatsApp messaging should use `ExWapp.Client.Transport.Session`.
  A raw WebSocket alone cannot implement this contract safely because it lacks
  Signal sessions, device fanout, sender keys, retry, and synchronized state.
  """

  alias ExWapp.{Chat, Client, Contact, Media, Message}

  @callback connect(Client.t()) :: {:ok, Client.t()} | {:error, term()}
  @callback pair(Client.t()) :: {:ok, Client.t(), term()} | {:error, term()}
  @callback disconnect(Client.t()) :: {:ok, Client.t()} | :ok | {:error, term()}
  @callback send_message(Client.t(), Message.t()) ::
              {:ok, String.t()}
              | {:ok, Client.t(), String.t()}
              | {:error, Client.t(), term()}
              | {:error, term()}
  @callback receive_message(Client.t(), term(), keyword()) ::
              {:ok, Client.t(), [ExWapp.Event.t()]}
              | {:ok, [ExWapp.Event.t()]}
              | {:error, term()}
  @callback list_contacts(Client.t()) :: {:ok, [Contact.t()]} | {:error, term()}
  @callback get_contact(Client.t(), String.t()) :: {:ok, Contact.t() | nil} | {:error, term()}
  @callback sync_contacts(Client.t()) :: {:ok, Client.t()} | :ok | {:error, term()}
  @callback create_contact(Client.t(), String.t(), String.t()) ::
              {:ok, Client.t()} | :ok | {:error, term()}
  @callback update_contact(Client.t(), String.t(), map() | keyword()) ::
              {:ok, Client.t()} | :ok | {:error, term()}
  @callback delete_contact(Client.t(), String.t()) :: {:ok, Client.t()} | :ok | {:error, term()}
  @callback list_chats(Client.t()) :: {:ok, [Chat.chat()]} | {:error, term()}
  @callback list_groups(Client.t()) :: {:ok, [Chat.chat()]} | {:error, term()}
  @callback get_chat(Client.t(), String.t()) :: {:ok, Chat.chat()} | {:error, term()}
  @callback get_messages(Client.t(), String.t(), keyword()) ::
              {:ok, [Chat.message()]} | {:error, term()}
  @callback download_media(Client.t(), Media.Ref.t(), keyword()) ::
              {:ok, Client.t(), Media.Download.t()} | {:error, term()}

  @optional_callbacks pair: 1,
                      disconnect: 1,
                      receive_message: 3,
                      list_contacts: 1,
                      get_contact: 2,
                      sync_contacts: 1,
                      create_contact: 3,
                      update_contact: 3,
                      delete_contact: 2,
                      list_chats: 1,
                      list_groups: 1,
                      get_chat: 2,
                      get_messages: 3,
                      download_media: 3
end
