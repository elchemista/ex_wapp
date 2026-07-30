defmodule ExWapp.AppState.Engine.Dispatch do
  @moduledoc """
  Applies decoded app-state mutations to local contact and chat state.

  The decoder turns WhatsApp patch payloads into normalized mutation maps; this
  module is the bridge that translates those maps into the project's local
  `ExWapp.Contact` and `ExWapp.Chat` updates.
  """

  require Logger
  alias ExWapp.Log
  alias WAWebProtobufSyncAction.SyncActionValue

  @type action_value :: SyncActionValue.t() | nil
  @type patch_info :: %{type: String.t(), mutations: [map()], timestamp: integer() | nil}

  @doc """
  Dispatches one decoded mutation into the appropriate local store update.
  """
  @spec dispatch_mutation(struct(), non_neg_integer(), [String.t()], action_value()) ::
          :ok | :ignored
  def dispatch_mutation(store, operation, index, action_value)
      when is_integer(operation) and is_list(index) do
    dispatch_index_mutation(store, operation, index, action_value)
  rescue
    error ->
      Logger.warning(
        "[APP_STATE] Dispatch mutation error: #{Log.reason(error)} index=#{Log.reason(index)}"
      )

      :ignored
  end

  @doc """
  Backwards-compatible helper that treats the mutation as a SET operation.
  """
  @spec dispatch_mutation(struct(), [String.t()], action_value()) :: :ok | :ignored
  def dispatch_mutation(store, index, action_value) do
    dispatch_mutation(store, 0, index, action_value)
  end

  @doc """
  Replays the local side effects of an outgoing patch after server ack.
  """
  @spec apply_outgoing_patch(struct(), patch_info()) :: :ok
  def apply_outgoing_patch(store, patch_info) when is_map(patch_info) do
    patch_info
    |> Map.get(:mutations, [])
    |> Enum.each(fn mutation ->
      operation = if Map.get(mutation, :operation) == :remove, do: 1, else: 0
      dispatch_mutation(store, operation, mutation.index, mutation.value)
    end)

    :ok
  end

  defp dispatch_index_mutation(store, operation, ["contact", jid], action_value) do
    dispatch_contact_mutation(store, operation, jid, action_value)
  end

  defp dispatch_index_mutation(store, operation, ["archive", jid], action_value) do
    dispatch_archive_mutation(store, operation, jid, action_value)
  end

  defp dispatch_index_mutation(store, operation, ["pin_v1", jid], action_value) do
    dispatch_pin_mutation(store, operation, jid, action_value)
  end

  defp dispatch_index_mutation(store, operation, ["mute", jid], action_value) do
    dispatch_mute_mutation(store, operation, jid, action_value)
  end

  defp dispatch_index_mutation(store, operation, ["deleteChat", jid], _action_value) do
    dispatch_delete_chat_mutation(store, operation, jid)
  end

  defp dispatch_index_mutation(
         store,
         operation,
         ["deleteChat", jid, _delete_media],
         _action_value
       ) do
    dispatch_delete_chat_mutation(store, operation, jid)
  end

  defp dispatch_index_mutation(store, operation, ["markChatAsRead", jid], action_value) do
    dispatch_mark_read_mutation(store, operation, jid, action_value)
  end

  defp dispatch_index_mutation(_store, _operation, _index, _action_value), do: :ignored

  defp dispatch_contact_mutation(store, 1, jid, _action_value),
    do: ExWapp.Contact.delete(store, jid)

  defp dispatch_contact_mutation(store, _operation, jid, action_value) do
    case get_action_field(action_value, :contactAction) do
      nil -> :ignored
      contact_action -> ExWapp.Contact.merge_from_sync(store, jid, contact_action)
    end
  end

  defp dispatch_archive_mutation(_store, 1, _jid, _action_value), do: :ignored

  defp dispatch_archive_mutation(store, _operation, jid, action_value) do
    case get_action_field(action_value, :archiveChatAction) do
      nil ->
        :ignored

      archive_action ->
        ExWapp.Chat.update_archived(store, jid, Map.get(archive_action, :archived, false))
    end
  end

  defp dispatch_pin_mutation(_store, 1, _jid, _action_value), do: :ignored

  defp dispatch_pin_mutation(store, _operation, jid, action_value) do
    case get_action_field(action_value, :pinAction) do
      nil -> :ignored
      pin_action -> ExWapp.Chat.update_pinned(store, jid, Map.get(pin_action, :pinned, false))
    end
  end

  defp dispatch_mute_mutation(_store, 1, _jid, _action_value), do: :ignored

  defp dispatch_mute_mutation(store, _operation, jid, action_value) do
    case get_action_field(action_value, :muteAction) do
      nil -> :ignored
      mute_action -> ExWapp.Chat.update_muted(store, jid, mute_action)
    end
  end

  defp dispatch_delete_chat_mutation(store, _operation, jid), do: ExWapp.Chat.delete(store, jid)
  defp dispatch_mark_read_mutation(_store, 1, _jid, _action_value), do: :ignored

  defp dispatch_mark_read_mutation(store, _operation, jid, action_value) do
    if action_value, do: ExWapp.Chat.mark_read_from_sync(store, jid, action_value), else: :ignored
  end

  defp get_action_field(nil, _field), do: nil

  defp get_action_field(action_value, field) when is_map(action_value),
    do: Map.get(action_value, field)

  defp get_action_field(_, _), do: nil
end
