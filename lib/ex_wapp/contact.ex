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

  @doc """
  Builds a WhatsApp-compatible vCard 3.0 payload for `send_contact/5`.

  The `waid` parameter is normalized to digits while the displayed telephone
  number keeps its leading `+` when one was supplied.
  """
  @spec vcard(String.t(), String.t()) :: String.t()
  def vcard(display_name, phone_number)
      when is_binary(display_name) and is_binary(phone_number) do
    phone_number = String.trim(phone_number)
    waid = String.replace(phone_number, ~r/\D/, "")

    [
      "BEGIN:VCARD",
      "VERSION:3.0",
      "FN:#{escape_vcard(display_name)}",
      "TEL;TYPE=CELL;TYPE=VOICE;waid=#{waid}:#{phone_number}",
      "END:VCARD"
    ]
    |> Enum.join("\r\n")
  end

  @doc "Get a contact by JID."
  @spec get(struct(), String.t()) :: t() | nil
  def get(store, jid) do
    data = Store.load!(store)
    contacts = Map.get(data, :contacts, %{})
    normalized = normalize_jid(jid)
    Map.get(contacts, normalized) || find_legacy_contact(contacts, normalized)
  end

  @doc "Put (create or update) a contact."
  @spec put(struct(), String.t(), t()) :: :ok
  def put(store, jid, %__MODULE__{} = contact) do
    data = Store.load!(store)
    normalized = normalize_jid(jid)
    contacts = data |> Map.get(:contacts, %{}) |> remove_contact_aliases(normalized)
    contact = %{contact | jid: normalized, phone_number: extract_phone(normalized)}
    Store.persist(store, Map.put(data, :contacts, Map.put(contacts, normalized, contact)))
  end

  @doc "Delete a contact by JID."
  @spec delete(struct(), String.t()) :: :ok
  def delete(store, jid) do
    data = Store.load!(store)
    normalized = normalize_jid(jid)
    contacts = data |> Map.get(:contacts, %{}) |> remove_contact_aliases(normalized)
    Store.persist(store, Map.put(data, :contacts, contacts))
  end

  @doc "Update push name for a contact (from incoming message notify attr)."
  @spec update_push_name(struct(), String.t(), String.t()) :: :ok
  def update_push_name(store, jid, name) when is_binary(name) and name != "" do
    normalized = normalize_jid(jid)
    data = Store.load!(store)
    contacts = Map.get(data, :contacts, %{})

    existing =
      Map.get(contacts, normalized) || find_legacy_contact(contacts, normalized) ||
        %__MODULE__{jid: normalized}

    contacts = remove_contact_aliases(contacts, normalized)
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

    existing =
      Map.get(contacts, normalized) || find_legacy_contact(contacts, normalized) ||
        %__MODULE__{jid: normalized}

    contacts = remove_contact_aliases(contacts, normalized)

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
    jid = String.trim(jid)

    case String.split(jid, "@", parts: 2) do
      [user, domain] ->
        normalized_domain =
          case String.downcase(domain) do
            "whatsapp.net" -> "s.whatsapp.net"
            "s.whatsapp.net" -> "s.whatsapp.net"
            other -> other
          end

        "#{String.trim_leading(user, "+")}@#{normalized_domain}"

      [user] ->
        "#{String.trim_leading(user, "+")}@s.whatsapp.net"
    end
  end

  defp normalize_jid(jid), do: jid |> to_string() |> normalize_jid()

  defp find_legacy_contact(contacts, normalized) when is_map(contacts) do
    Enum.find_value(contacts, fn {jid, contact} ->
      if normalize_jid(jid) == normalized, do: contact
    end)
  end

  defp remove_contact_aliases(contacts, normalized) when is_map(contacts) do
    contacts
    |> Enum.reject(fn {jid, _contact} -> normalize_jid(jid) == normalized end)
    |> Map.new()
  end

  defp extract_phone(jid) when is_binary(jid) do
    case String.split(jid, "@", parts: 2) do
      [user, _domain] when user != "" -> user
      _ -> nil
    end
  end

  @spec escape_vcard(String.t()) :: String.t()
  defp escape_vcard(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("\r\n", "\\n")
    |> String.replace("\n", "\\n")
    |> String.replace(";", "\\;")
    |> String.replace(",", "\\,")
  end
end
