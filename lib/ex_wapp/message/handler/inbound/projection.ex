defmodule ExWapp.Message.Handler.Inbound.Projection do
  @moduledoc """
  Applies inbound presentation metadata to the local chat projection.

  This boundary owns chat-name hints and number fallbacks. It does not decode
  messages, mutate Signal sessions, or publish inbound events.
  """

  alias ExWapp.{Chat, JID}
  alias ExWapp.Message.Handler.Common

  @doc """
  Updates a chat name from inbound attributes or applies the phone-number fallback.
  """
  @spec update_chat_name(term(), term(), map()) :: :ok
  def update_chat_name(target, jid, attrs) when is_map(attrs) do
    name_hint =
      Common.first_non_empty([
        Map.get(attrs, "notify"),
        Map.get(attrs, "pushname")
      ])

    if is_binary(name_hint) and name_hint != "" do
      Chat.update_name(target, jid, name_hint)
    else
      maybe_set_number_fallback_name(target, jid)
    end
  end

  @spec maybe_set_number_fallback_name(term(), term()) :: :ok
  defp maybe_set_number_fallback_name(target, jid) do
    jid_str = Common.normalize_jid(jid)

    if JID.user?(jid_str) do
      fallback =
        case String.split(jid_str, "@", parts: 2) do
          [user, _] when user != "" -> user
          _ -> nil
        end

      case {fallback, Chat.get_or_create(target, jid).name} do
        {name, existing}
        when is_binary(name) and name != "" and (is_nil(existing) or existing == "") ->
          Chat.update_name(target, jid, name)

        _ ->
          :ok
      end
    else
      :ok
    end
  end
end
