# credo:disable-for-this-file
defmodule ExWapp.Contact do
  @moduledoc """
  Contact struct and local CRUD operations.

  Contact data is populated from:
  - App state sync patches (field "contact" in critical_unblock_low)
  - Incoming message notify attribute (push name)
  - History sync data
  """

  alias ExWapp.Store

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

  @doc "List all contacts from the store."
  @spec list(struct()) :: [t()]
  def list(store) do
    data = Store.load!(store)
    contacts = Map.get(data, :contacts, %{})
    Map.values(contacts)
  end

  @doc "Get a contact by JID."
  @spec get(struct(), String.t()) :: t() | nil
  def get(store, jid) do
    data = Store.load!(store)
    contacts = Map.get(data, :contacts, %{})
    Map.get(contacts, normalize_jid(jid))
  end

  @doc "Put (create or update) a contact."
  @spec put(struct(), String.t(), t()) :: :ok
  def put(store, jid, %__MODULE__{} = contact) do
    data = Store.load!(store)
    contacts = Map.get(data, :contacts, %{})
    normalized = normalize_jid(jid)
    contact = %{contact | jid: normalized, phone_number: extract_phone(normalized)}
    Store.persist(store, Map.put(data, :contacts, Map.put(contacts, normalized, contact)))
  end

  @doc "Delete a contact by JID."
  @spec delete(struct(), String.t()) :: :ok
  def delete(store, jid) do
    data = Store.load!(store)
    contacts = Map.get(data, :contacts, %{})
    Store.persist(store, Map.put(data, :contacts, Map.delete(contacts, normalize_jid(jid))))
  end

  @doc "Update push name for a contact (from incoming message notify attr)."
  @spec update_push_name(struct(), String.t(), String.t()) :: :ok
  def update_push_name(store, jid, name) when is_binary(name) and name != "" do
    normalized = normalize_jid(jid)
    data = Store.load!(store)
    contacts = Map.get(data, :contacts, %{})

    existing = Map.get(contacts, normalized, %__MODULE__{jid: normalized})
    updated = %{existing | push_name: name, phone_number: extract_phone(normalized)}

    Store.persist(store, Map.put(data, :contacts, Map.put(contacts, normalized, updated)))
  end

  def update_push_name(_store, _jid, _name), do: :ok

  @doc "Merge contact data from an app state sync ContactAction."
  @spec merge_from_sync(struct(), String.t(), map()) :: :ok
  def merge_from_sync(store, jid, contact_action) when is_map(contact_action) do
    normalized = normalize_jid(jid)
    data = Store.load!(store)
    contacts = Map.get(data, :contacts, %{})

    existing = Map.get(contacts, normalized, %__MODULE__{jid: normalized})

    updated =
      existing
      |> maybe_set(:full_name, Map.get(contact_action, :full_name))
      |> maybe_set(:first_name, Map.get(contact_action, :first_name))
      |> maybe_set(:lid, Map.get(contact_action, :lid_jid))
      |> maybe_set(:username, Map.get(contact_action, :username))
      |> Map.put(:phone_number, extract_phone(normalized))

    Store.persist(store, Map.put(data, :contacts, Map.put(contacts, normalized, updated)))
  end

  def merge_from_sync(_store, _jid, _contact_action), do: :ok

  defp maybe_set(contact, _key, nil), do: contact
  defp maybe_set(contact, key, value), do: Map.put(contact, key, value)

  defp normalize_jid(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
  end

  defp normalize_jid(jid), do: to_string(jid)

  defp extract_phone(jid) when is_binary(jid) do
    case String.split(jid, "@", parts: 2) do
      [user, _domain] when user != "" -> user
      _ -> nil
    end
  end
end
