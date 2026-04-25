# credo:disable-for-this-file
defmodule ExWapp.Contact do
  @moduledoc """
  Public contact struct and CRUD helpers backed by the configured store.

  Contacts are populated from several protocol paths:
  - App state sync patches (`contact` mutations in `critical_unblock_low`)
  - Incoming message notify attributes (`push_name`)
  - History sync payloads restored during session bootstrap

  The store/update details live in `lib/ex_wapp/domains/contacts/` so this
  module can stay focused on the public API.
  """

  alias ExWapp.Domains.Contacts.Repository

  defstruct [
    :jid,
    :lid,
    :full_name,
    :first_name,
    :push_name,
    :username,
    :phone_number
  ]

  @type t :: %__MODULE__{
          jid: String.t(),
          lid: String.t() | nil,
          full_name: String.t() | nil,
          first_name: String.t() | nil,
          push_name: String.t() | nil,
          username: String.t() | nil,
          phone_number: String.t() | nil
        }

  @doc """
  Lists all contacts currently persisted in the store.
  """
  @spec list(struct()) :: [t()]
  def list(store), do: Repository.list(store)

  @doc """
  Fetches a contact by JID after normalizing legacy aliases.
  """
  @spec get(struct(), String.t()) :: t() | nil
  def get(store, jid), do: Repository.get(store, jid)

  @doc """
  Creates or replaces a contact entry.

  The stored contact JID is normalized so callers can use older forms like
  `+1555@whatsapp.net` and still end up with one canonical key.
  """
  @spec put(struct(), String.t(), t()) :: :ok
  def put(store, jid, %__MODULE__{} = contact), do: Repository.put(store, jid, contact)

  @doc """
  Deletes a contact and any normalized aliases that point to the same JID.
  """
  @spec delete(struct(), String.t()) :: :ok
  def delete(store, jid), do: Repository.delete(store, jid)

  @doc """
  Updates the push name learned from incoming message metadata.

  When the contact does not exist yet, a minimal placeholder contact is created
  so later sync patches can enrich it.
  """
  @spec update_push_name(struct(), String.t(), String.t()) :: :ok
  def update_push_name(store, jid, name), do: Repository.update_push_name(store, jid, name)

  @doc """
  Merges app-state contact fields into the locally stored contact.
  """
  @spec merge_from_sync(struct(), String.t(), map()) :: :ok
  def merge_from_sync(store, jid, contact_action),
    do: Repository.merge_from_sync(store, jid, contact_action)
end
