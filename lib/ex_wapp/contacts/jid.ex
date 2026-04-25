defmodule ExWapp.Domains.Contacts.JID do
  @moduledoc false

  @doc false
  @spec normalize(term()) :: String.t()
  def normalize(jid) when is_binary(jid) do
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

  def normalize(jid), do: jid |> to_string() |> normalize()

  @doc false
  @spec extract_phone(String.t()) :: String.t() | nil
  def extract_phone(jid) when is_binary(jid) do
    case String.split(jid, "@", parts: 2) do
      [user, _domain] when user != "" -> user
      _ -> nil
    end
  end
end
