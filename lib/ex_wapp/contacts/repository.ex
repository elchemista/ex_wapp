defmodule ExWapp.Domains.Contacts.Repository do
  @moduledoc """
  Persists normalized contacts in an `ExWapp.Store`.

  Every lookup and write canonicalizes the JID and removes legacy aliases, so
  consumers see one contact record regardless of the identifier form received
  from the wire.
  """

  alias ExWapp.Contact
  alias ExWapp.Domains.Contacts.JID
  alias ExWapp.Store

  @doc "Lists all normalized contacts currently stored."
  @spec list(struct()) :: [Contact.t()]
  def list(store) do
    store
    |> Store.get(:contacts, %{})
    |> Map.values()
  end

  @doc "Fetches a contact by JID, including records stored under legacy aliases."
  @spec get(struct(), String.t()) :: Contact.t() | nil
  def get(store, jid) do
    contacts = Store.get(store, :contacts, %{})
    normalized = JID.normalize(jid)

    Map.get(contacts, normalized) || find_legacy_contact(contacts, normalized)
  end

  @doc "Stores a contact under its canonical JID and removes duplicate aliases."
  @spec put(struct(), String.t(), Contact.t()) :: :ok
  def put(store, jid, %Contact{} = contact) do
    normalized = JID.normalize(jid)

    persist_contact(store, normalized, fn _existing ->
      %{contact | jid: normalized, phone_number: JID.extract_phone(normalized)}
    end)
  end

  @doc "Deletes a contact and every legacy alias for the same JID."
  @spec delete(struct(), String.t()) :: :ok
  def delete(store, jid) do
    normalized = JID.normalize(jid)

    Store.update(store, :contacts, %{}, fn contacts ->
      remove_contact_aliases(contacts, normalized)
    end)
  end

  @doc "Updates the push name associated with a contact."
  @spec update_push_name(struct(), String.t(), String.t()) :: :ok
  def update_push_name(store, jid, name) when is_binary(name) and name != "" do
    normalized = JID.normalize(jid)

    persist_contact(store, normalized, fn existing ->
      %{existing | push_name: name, phone_number: JID.extract_phone(normalized)}
    end)
  end

  def update_push_name(_store, _jid, _name), do: :ok

  @doc "Merges contact fields decoded from app-state synchronization."
  @spec merge_from_sync(struct(), String.t(), map()) :: :ok
  def merge_from_sync(store, jid, contact_action) when is_map(contact_action) do
    normalized = JID.normalize(jid)

    persist_contact(store, normalized, fn existing ->
      existing
      |> maybe_set(:full_name, Map.get(contact_action, :full_name))
      |> maybe_set(:first_name, Map.get(contact_action, :first_name))
      |> maybe_set(:lid, Map.get(contact_action, :lid_jid))
      |> maybe_set(:username, Map.get(contact_action, :username))
      |> Map.put(:phone_number, JID.extract_phone(normalized))
    end)
  end

  def merge_from_sync(_store, _jid, _contact_action), do: :ok

  @spec persist_contact(struct(), String.t(), (Contact.t() -> Contact.t())) :: :ok
  defp persist_contact(store, normalized, update_fun) do
    Store.update(store, :contacts, %{}, fn contacts ->
      existing =
        Map.get(contacts, normalized) || find_legacy_contact(contacts, normalized) ||
          %Contact{jid: normalized}

      # Alias cleanup prevents duplicate records when the same contact was stored
      # under older JID forms such as `+1555@whatsapp.net`.
      contacts = remove_contact_aliases(contacts, normalized)
      Map.put(contacts, normalized, update_fun.(existing))
    end)
  end

  @spec maybe_set(Contact.t(), atom(), term() | nil) :: Contact.t()
  defp maybe_set(contact, _key, nil), do: contact
  defp maybe_set(contact, key, value), do: Map.put(contact, key, value)

  @spec find_legacy_contact(map(), String.t()) :: Contact.t() | nil
  defp find_legacy_contact(contacts, normalized) when is_map(contacts) do
    Enum.find_value(contacts, fn {jid, contact} ->
      if JID.normalize(jid) == normalized, do: contact
    end)
  end

  @spec remove_contact_aliases(map(), String.t()) :: map()
  defp remove_contact_aliases(contacts, normalized) when is_map(contacts) do
    contacts
    |> Enum.reject(fn {jid, _contact} -> JID.normalize(jid) == normalized end)
    |> Map.new()
  end
end
