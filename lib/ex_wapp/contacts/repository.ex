defmodule ExWapp.Domains.Contacts.Repository do
  @moduledoc false

  alias ExWapp.Contact
  alias ExWapp.Domains.Contacts.JID
  alias ExWapp.Store

  @doc false
  @spec list(struct()) :: [Contact.t()]
  def list(store) do
    store
    |> Store.load!()
    |> Map.get(:contacts, %{})
    |> Map.values()
  end

  @doc false
  @spec get(struct(), String.t()) :: Contact.t() | nil
  def get(store, jid) do
    data = Store.load!(store)
    contacts = Map.get(data, :contacts, %{})
    normalized = JID.normalize(jid)

    Map.get(contacts, normalized) || find_legacy_contact(contacts, normalized)
  end

  @doc false
  @spec put(struct(), String.t(), Contact.t()) :: :ok
  def put(store, jid, %Contact{} = contact) do
    normalized = JID.normalize(jid)

    persist_contact(store, normalized, fn _existing ->
      %{contact | jid: normalized, phone_number: JID.extract_phone(normalized)}
    end)
  end

  @doc false
  @spec delete(struct(), String.t()) :: :ok
  def delete(store, jid) do
    data = Store.load!(store)
    normalized = JID.normalize(jid)
    contacts = data |> Map.get(:contacts, %{}) |> remove_contact_aliases(normalized)
    Store.persist(store, Map.put(data, :contacts, contacts))
  end

  @doc false
  @spec update_push_name(struct(), String.t(), String.t()) :: :ok
  def update_push_name(store, jid, name) when is_binary(name) and name != "" do
    normalized = JID.normalize(jid)

    persist_contact(store, normalized, fn existing ->
      %{existing | push_name: name, phone_number: JID.extract_phone(normalized)}
    end)
  end

  def update_push_name(_store, _jid, _name), do: :ok

  @doc false
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
    data = Store.load!(store)
    contacts = Map.get(data, :contacts, %{})

    existing =
      Map.get(contacts, normalized) || find_legacy_contact(contacts, normalized) ||
        %Contact{jid: normalized}

    # Alias cleanup prevents duplicate records when the same contact was stored
    # under older JID forms such as `+1555@whatsapp.net`.
    contacts = remove_contact_aliases(contacts, normalized)
    updated = update_fun.(existing)

    Store.persist(store, Map.put(data, :contacts, Map.put(contacts, normalized, updated)))
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
