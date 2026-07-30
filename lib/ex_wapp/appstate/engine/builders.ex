defmodule ExWapp.AppState.Engine.Builders do
  @moduledoc """
  Builders for outgoing app-state mutations.

  Each helper returns a logical patch description that mirrors one user action
  such as archiving a chat or updating a contact. The encoder later turns these
  maps into protobuf payloads and cryptographic MACs.
  """

  alias WAWebProtobufSyncAction.{
    ArchiveChatAction,
    ClearChatAction,
    ContactAction,
    DeleteChatAction,
    MarkChatAsReadAction,
    MuteAction,
    PinAction,
    SyncActionMessageRange,
    SyncActionValue
  }

  @collection_critical_unblock_low "critical_unblock_low"
  @collection_regular_high "regular_high"
  @collection_regular_low "regular_low"

  @type patch_info :: %{
          type: String.t(),
          mutations: [map()],
          timestamp: integer() | nil
        }

  @type message_range :: %SyncActionMessageRange{}

  @doc """
  Builds a contact upsert mutation.
  """
  @spec build_contact(String.t(), String.t(), String.t() | nil) :: patch_info()
  def build_contact(jid, full_name, first_name \\ nil) do
    normalized_jid = normalize_contact_jid(jid)

    %{
      type: @collection_critical_unblock_low,
      mutations: [
        %{
          index: ["contact", normalized_jid],
          version: 2,
          value: %SyncActionValue{
            contactAction: %ContactAction{
              fullName: full_name,
              firstName: first_name || full_name,
              saveOnPrimaryAddressbook: true
            }
          }
        }
      ],
      timestamp: nil
    }
  end

  @doc """
  Builds a remove mutation for a contact.
  """
  @spec build_delete_contact(String.t()) :: patch_info()
  def build_delete_contact(jid) do
    normalized_jid = normalize_contact_jid(jid)

    %{
      type: @collection_critical_unblock_low,
      mutations: [
        %{
          index: ["contact", normalized_jid],
          version: 2,
          value: %SyncActionValue{},
          operation: :remove
        }
      ],
      timestamp: nil
    }
  end

  @doc """
  Builds an archive or unarchive mutation for a chat.

  When archiving we also emit the unpin mutation that WhatsApp Web sends, so
  the local behavior stays aligned with the server's expectations.
  """
  @spec build_archive(String.t(), boolean(), integer() | nil) :: patch_info()
  def build_archive(jid, archived, last_msg_ts \\ nil) do
    archive_mutation = %{
      index: ["archive", jid],
      version: 3,
      value: %SyncActionValue{
        archiveChatAction: %ArchiveChatAction{
          archived: archived,
          messageRange: build_message_range(last_msg_ts)
        }
      }
    }

    mutations =
      if archived do
        unpin_mutation = %{
          index: ["pin_v1", jid],
          version: 5,
          value: %SyncActionValue{
            pinAction: %PinAction{pinned: false}
          }
        }

        [archive_mutation, unpin_mutation]
      else
        [archive_mutation]
      end

    %{type: @collection_regular_low, mutations: mutations, timestamp: nil}
  end

  @doc """
  Builds a pin or unpin mutation for a chat.
  """
  @spec build_pin(String.t(), boolean()) :: patch_info()
  def build_pin(jid, pinned) do
    %{
      type: @collection_regular_low,
      mutations: [
        %{
          index: ["pin_v1", jid],
          version: 5,
          value: %SyncActionValue{
            pinAction: %PinAction{pinned: pinned}
          }
        }
      ],
      timestamp: nil
    }
  end

  @doc """
  Builds a mute or unmute mutation for a chat.
  """
  @spec build_mute(String.t(), boolean(), integer()) :: patch_info()
  def build_mute(jid, muted, mute_end_timestamp \\ -1) do
    mute_end =
      cond do
        not muted -> nil
        mute_end_timestamp == 0 -> -1
        true -> mute_end_timestamp
      end

    %{
      type: @collection_regular_high,
      mutations: [
        %{
          index: ["mute", jid],
          version: 2,
          value: %SyncActionValue{
            muteAction: %MuteAction{
              muted: muted,
              muteEndTimestamp: mute_end
            }
          }
        }
      ],
      timestamp: nil
    }
  end

  @doc """
  Builds a delete-chat mutation.
  """
  @spec build_delete_chat(String.t(), integer() | nil) :: patch_info()
  def build_delete_chat(jid, last_msg_ts \\ nil) do
    %{
      type: @collection_regular_high,
      mutations: [
        %{
          index: ["deleteChat", jid, "0"],
          version: 6,
          value: %SyncActionValue{
            deleteChatAction: %DeleteChatAction{
              messageRange: build_message_range(last_msg_ts)
            }
          }
        }
      ],
      timestamp: nil
    }
  end

  @doc """
  Builds a mark-read or mark-unread mutation for a chat.
  """
  @spec build_mark_read(String.t(), boolean(), integer() | nil) :: patch_info()
  def build_mark_read(jid, read, last_msg_ts \\ nil) do
    %{
      type: @collection_regular_low,
      mutations: [
        %{
          index: ["markChatAsRead", jid],
          version: 3,
          value: %SyncActionValue{
            markChatAsReadAction: %MarkChatAsReadAction{
              read: read,
              messageRange: build_message_range(last_msg_ts)
            }
          }
        }
      ],
      timestamp: nil
    }
  end

  @doc """
  Builds a clear-chat mutation.
  """
  @spec build_clear_chat(String.t(), integer() | nil) :: patch_info()
  def build_clear_chat(jid, last_msg_ts \\ nil) do
    %{
      type: @collection_regular_high,
      mutations: [
        %{
          # Keep the wire shape aligned with WhatsApp Web so the server treats
          # this as a full clear-chat action rather than a per-message delete.
          index: ["clearChat", jid, "1", "0"],
          version: 6,
          value: %SyncActionValue{
            clearChatAction: %ClearChatAction{
              messageRange: build_message_range(last_msg_ts)
            }
          }
        }
      ],
      timestamp: nil
    }
  end

  @spec build_message_range(integer() | nil) :: message_range()
  defp build_message_range(nil) do
    %SyncActionMessageRange{lastMessageTimestamp: System.system_time(:second)}
  end

  defp build_message_range(timestamp) when is_integer(timestamp) do
    %SyncActionMessageRange{lastMessageTimestamp: timestamp}
  end

  @spec normalize_contact_jid(term()) :: String.t()
  defp normalize_contact_jid(jid) when is_binary(jid) do
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

  defp normalize_contact_jid(jid), do: jid |> to_string() |> normalize_contact_jid()
end
