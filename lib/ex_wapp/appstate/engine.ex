# credo:disable-for-this-file
defmodule ExWapp.AppState.Engine do
  @moduledoc """
  App State Sync Engine for WhatsApp.

  Handles encoding/decoding of app state patches, mutation building,
  and IQ-based communication with the WhatsApp server.

  Reference: whatsmeow `appstate/encode.go`, `appstate/decode.go`, `appstate.go`
  """

  require Logger

  alias ExWapp.AppState.{Crypto, LTHash}
  alias ExWapp.Proto.SyncAction

  alias ExWapp.Proto.SyncAction.{
    SyncdPatch,
    SyncdMutation,
    SyncdRecord,
    SyncActionData,
    SyncActionValue,
    ContactAction,
    MuteAction,
    PinAction,
    ArchiveChatAction,
    DeleteChatAction,
    MarkChatAsReadAction,
    ClearChatAction,
    SyncActionMessageRange
  }

  alias ExWapp.Binary
  alias ExWapp.Store

  # ============================================================================
  # Collection names (matching whatsmeow appstate/keys.go)
  # ============================================================================

  @collection_critical_block "critical_block"
  @collection_critical_unblock_low "critical_unblock_low"
  @collection_regular_high "regular_high"
  @collection_regular_low "regular_low"
  @collection_regular "regular"

  @all_collections [
    @collection_critical_block,
    @collection_critical_unblock_low,
    @collection_regular_high,
    @collection_regular_low,
    @collection_regular
  ]

  # ============================================================================
  # Types
  # ============================================================================

  @type mutation_info :: %{
          index: [String.t()],
          version: integer(),
          value: %SyncActionValue{}
        }

  @type patch_info :: %{
          type: String.t(),
          mutations: [mutation_info()],
          timestamp: integer() | nil
        }

  @type hash_state :: %{
          version: non_neg_integer(),
          hash: binary()
        }

  @type decoded_mutation :: %{
          operation: non_neg_integer(),
          action: %SyncActionValue{},
          version: integer() | nil,
          index: [String.t()],
          index_mac: binary(),
          value_mac: binary()
        }

  # ============================================================================
  # Mutation Builders
  # ============================================================================

  @doc "Build a contact creation/update patch."
  @spec build_contact(String.t(), String.t(), String.t() | nil) :: patch_info()
  def build_contact(jid, full_name, first_name \\ nil) do
    %{
      type: @collection_critical_unblock_low,
      mutations: [
        %{
          index: ["contact", jid],
          version: 2,
          value: %SyncActionValue{
            contact_action: %ContactAction{
              full_name: full_name,
              first_name: first_name || full_name
            }
          }
        }
      ],
      timestamp: nil
    }
  end

  @doc "Build a contact deletion patch (REMOVE operation)."
  @spec build_delete_contact(String.t()) :: patch_info()
  def build_delete_contact(jid) do
    %{
      type: @collection_critical_unblock_low,
      mutations: [
        %{
          index: ["contact", jid],
          version: 2,
          value: %SyncActionValue{},
          operation: :remove
        }
      ],
      timestamp: nil
    }
  end

  @doc "Build an archive/unarchive patch. Archiving also unpins."
  @spec build_archive(String.t(), boolean(), integer() | nil) :: patch_info()
  def build_archive(jid, archived, last_msg_ts \\ nil) do
    archive_mutation = %{
      index: ["archive", jid],
      version: 3,
      value: %SyncActionValue{
        archive_chat_action: %ArchiveChatAction{
          archived: archived,
          message_range: build_message_range(last_msg_ts)
        }
      }
    }

    mutations =
      if archived do
        # Archiving also unpins (matching whatsmeow BuildArchive)
        unpin_mutation = %{
          index: ["pin_v1", jid],
          version: 5,
          value: %SyncActionValue{
            pin_action: %PinAction{pinned: false}
          }
        }

        [archive_mutation, unpin_mutation]
      else
        [archive_mutation]
      end

    %{type: @collection_regular_low, mutations: mutations, timestamp: nil}
  end

  @doc "Build a pin/unpin patch."
  @spec build_pin(String.t(), boolean()) :: patch_info()
  def build_pin(jid, pinned) do
    %{
      type: @collection_regular_low,
      mutations: [
        %{
          index: ["pin_v1", jid],
          version: 5,
          value: %SyncActionValue{
            pin_action: %PinAction{pinned: pinned}
          }
        }
      ],
      timestamp: nil
    }
  end

  @doc "Build a mute/unmute patch."
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
            mute_action: %MuteAction{
              muted: muted,
              mute_end_timestamp: mute_end
            }
          }
        }
      ],
      timestamp: nil
    }
  end

  @doc "Build a delete chat patch."
  @spec build_delete_chat(String.t(), integer() | nil) :: patch_info()
  def build_delete_chat(jid, last_msg_ts \\ nil) do
    %{
      type: @collection_regular,
      mutations: [
        %{
          index: ["deleteChat", jid],
          version: 6,
          value: %SyncActionValue{
            delete_chat_action: %DeleteChatAction{
              message_range: build_message_range(last_msg_ts)
            }
          }
        }
      ],
      timestamp: nil
    }
  end

  @doc "Build a mark chat as read/unread patch."
  @spec build_mark_read(String.t(), boolean(), integer() | nil) :: patch_info()
  def build_mark_read(jid, read, last_msg_ts \\ nil) do
    %{
      type: @collection_regular_low,
      mutations: [
        %{
          index: ["markChatAsRead", jid],
          version: 3,
          value: %SyncActionValue{
            mark_chat_as_read_action: %MarkChatAsReadAction{
              read: read,
              message_range: build_message_range(last_msg_ts)
            }
          }
        }
      ],
      timestamp: nil
    }
  end

  @doc "Build a clear chat patch."
  @spec build_clear_chat(String.t(), integer() | nil) :: patch_info()
  def build_clear_chat(jid, last_msg_ts \\ nil) do
    %{
      type: @collection_regular,
      mutations: [
        %{
          index: ["clearChat", jid],
          version: 7,
          value: %SyncActionValue{
            clear_chat_action: %ClearChatAction{
              message_range: build_message_range(last_msg_ts)
            }
          }
        }
      ],
      timestamp: nil
    }
  end

  # ============================================================================
  # Encode Patch
  # ============================================================================

  @doc """
  Encode a patch_info into a binary SyncdPatch protobuf, ready to send to the server.

  Matches whatsmeow `Processor.EncodePatch()` in `appstate/encode.go:263-337`.

  Parameters:
  - `patch_info` - The patch to encode (from build_* functions)
  - `key_id` - The app state key ID (binary)
  - `key_data` - The 32-byte app state key data
  - `hash_state` - Current hash state `%{version: int, hash: binary_128}`
  - `mutation_macs` - Map of `%{index_mac_hex => value_mac}` for existing mutations

  Returns `{:ok, encoded_patch, new_hash_state, new_mutation_macs}` or `{:error, reason}`.
  """
  @spec encode_patch(patch_info(), binary(), binary(), hash_state(), map()) ::
          {:ok, binary(), hash_state(), map()} | {:error, term()}
  def encode_patch(patch_info, key_id, key_data, hash_state, mutation_macs \\ %{}) do
    keys = Crypto.expand_keys(key_data)
    timestamp = patch_info[:timestamp] || System.system_time(:millisecond)
    collection_name = patch_info.type

    # Build encrypted mutations
    {mutations, value_macs, updated_mutation_macs} =
      Enum.reduce(patch_info.mutations, {[], [], mutation_macs}, fn mut, {muts, vmacs, mmacs} ->
        operation = if Map.get(mut, :operation) == :remove, do: 1, else: 0

        # Set timestamp on the value
        value = %{mut.value | timestamp: timestamp}

        # Encode SyncActionData
        index_json = Jason.encode!(mut.index)

        action_data = %SyncActionData{
          index: index_json,
          value: value,
          padding: <<>>,
          version: mut.version
        }

        content = SyncAction.encode_sync_action_data(action_data)

        # Encrypt content with AES-256-CBC
        {iv, ciphertext} = Crypto.encrypt_cbc(content, keys.value_encryption)
        encrypted_content = iv <> ciphertext

        # Compute MACs
        value_mac =
          Crypto.compute_content_mac(operation, encrypted_content, key_id, keys.value_mac)

        index_mac = Crypto.compute_index_mac(index_json, keys.index)

        # Update mutation MACs map: remove old MAC for this index, add new
        index_mac_hex = Base.encode16(index_mac, case: :lower)

        old_value_mac = Map.get(mmacs, index_mac_hex)

        mmacs =
          if operation == 0 do
            Map.put(mmacs, index_mac_hex, value_mac)
          else
            Map.delete(mmacs, index_mac_hex)
          end

        mutation = %SyncdMutation{
          operation: operation,
          record: %SyncdRecord{
            index: index_mac,
            value: encrypted_content <> value_mac,
            key_id: key_id
          }
        }

        {muts ++ [mutation], vmacs ++ [{value_mac, old_value_mac, operation}], mmacs}
      end)

    # Update LTHash
    subtract_macs =
      value_macs
      |> Enum.map(fn {_new, old, _op} -> old end)
      |> Enum.reject(&is_nil/1)

    add_macs = Enum.map(value_macs, fn {new_mac, _old, _op} -> new_mac end)

    new_hash = LTHash.subtract_then_add(hash_state.hash, subtract_macs, add_macs)
    new_version = hash_state.version + 1

    # Compute snapshot MAC
    snapshot_mac =
      Crypto.compute_snapshot_mac(new_hash, new_version, collection_name, keys.snapshot_mac)

    # Build the patch
    patch = %SyncdPatch{
      version: new_version,
      mutations: mutations,
      snapshot_mac: snapshot_mac,
      key_id: key_id
    }

    # Compute patch MAC
    mutation_value_macs = Enum.map(value_macs, fn {new_mac, _old, _op} -> new_mac end)

    patch_mac =
      Crypto.compute_patch_mac(
        snapshot_mac,
        mutation_value_macs,
        new_version,
        collection_name,
        keys.patch_mac
      )

    patch = %{patch | patch_mac: patch_mac}
    encoded = SyncAction.encode_syncd_patch(patch)

    new_hash_state = %{version: new_version, hash: new_hash}

    {:ok, encoded, new_hash_state, updated_mutation_macs}
  rescue
    error ->
      {:error, {:encode_patch_failed, error}}
  end

  # ============================================================================
  # Decode Mutations
  # ============================================================================

  @doc """
  Decode a list of SyncdMutation structs into decoded mutations.

  Matches whatsmeow `Processor.decodeMutations()` in `appstate/decode.go:121-176`.
  """
  @spec decode_mutations([%SyncdMutation{}], map(), boolean()) ::
          {:ok, [decoded_mutation()]} | {:error, term()}
  def decode_mutations(mutations, key_store, validate_macs \\ true) do
    result =
      Enum.reduce_while(mutations, {:ok, []}, fn mutation, {:ok, acc} ->
        case decode_single_mutation(mutation, key_store, validate_macs) do
          {:ok, decoded} -> {:cont, {:ok, acc ++ [decoded]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)

    result
  end

  defp decode_single_mutation(%SyncdMutation{} = mutation, key_store, validate_macs) do
    key_id = mutation.record.key_id
    key_id_hex = if is_binary(key_id), do: Base.encode16(key_id, case: :lower), else: nil

    with {:ok, key_data} <- get_key_data(key_store, key_id_hex),
         keys <- Crypto.expand_keys(key_data),
         content <- mutation.record.value,
         true <- is_binary(content) and byte_size(content) > 32 do
      # Split value into encrypted content + value MAC (last 32 bytes)
      content_len = byte_size(content) - 32
      encrypted_content = binary_part(content, 0, content_len)
      value_mac = binary_part(content, content_len, 32)

      # Validate content MAC
      if validate_macs do
        expected =
          Crypto.compute_content_mac(
            mutation.operation,
            encrypted_content,
            key_id,
            keys.value_mac
          )

        if expected != value_mac do
          {:error, :mismatching_content_mac}
        else
          :ok
        end
      else
        :ok
      end
      |> case do
        :ok ->
          # Decrypt: first 16 bytes = IV, rest = ciphertext
          if byte_size(encrypted_content) < 16 do
            {:error, :encrypted_content_too_short}
          else
            iv = binary_part(encrypted_content, 0, 16)
            ciphertext = binary_part(encrypted_content, 16, byte_size(encrypted_content) - 16)

            case Crypto.decrypt_cbc(ciphertext, keys.value_encryption, iv) do
              {:ok, plaintext} ->
                case SyncAction.decode_sync_action_data(plaintext) do
                  {:ok, sync_action_data} ->
                    index_mac = mutation.record.index

                    # Validate index MAC
                    if validate_macs and is_binary(sync_action_data.index) do
                      expected_index_mac =
                        Crypto.compute_index_mac(sync_action_data.index, keys.index)

                      if expected_index_mac != index_mac do
                        {:error, :mismatching_index_mac}
                      else
                        :ok
                      end
                    else
                      :ok
                    end
                    |> case do
                      :ok ->
                        index =
                          case Jason.decode(sync_action_data.index || "[]") do
                            {:ok, parsed} when is_list(parsed) -> parsed
                            _ -> []
                          end

                        {:ok,
                         %{
                           operation: mutation.operation,
                           action: sync_action_data.value,
                           version: sync_action_data.version,
                           index: index,
                           index_mac: index_mac,
                           value_mac: value_mac
                         }}

                      error ->
                        error
                    end

                  {:error, reason} ->
                    {:error, {:decode_sync_action_data_failed, reason}}
                end

              {:error, reason} ->
                {:error, {:decrypt_failed, reason}}
            end
          end

        error ->
          error
      end
    else
      false -> {:error, :invalid_record_value}
      {:error, reason} -> {:error, reason}
    end
  end

  # ============================================================================
  # Send Mutation via IQ
  # ============================================================================

  @doc """
  Send an app state mutation to the WhatsApp server.

  This encodes the patch, builds the IQ node, and sends it via the session.

  Returns `{:ok, new_hash_state, new_mutation_macs}` or `{:error, reason}`.
  """
  @spec send_mutation(GenServer.server(), patch_info(), struct()) ::
          {:ok, hash_state(), map()} | {:error, term()}
  def send_mutation(session, patch_info, store) do
    with {:ok, key_id, key_data} <- get_latest_app_state_key(store),
         {:ok, hash_state, mutation_macs} <-
           get_collection_state(store, patch_info.type),
         {:ok, encoded_patch, new_hash_state, new_mutation_macs} <-
           encode_patch(patch_info, key_id, key_data, hash_state, mutation_macs) do
      # Build the IQ node
      collection_name = patch_info.type
      message_id = generate_request_id()

      iq_node = %Binary.Node{
        tag: "iq",
        attrs: %{
          "id" => message_id,
          "xmlns" => "w:sync:app:state",
          "type" => "set",
          "to" => "s.whatsapp.net"
        },
        content: [
          %Binary.Node{
            tag: "sync",
            attrs: %{},
            content: [
              %Binary.Node{
                tag: "collection",
                attrs: %{
                  "name" => collection_name,
                  "version" => to_string(new_hash_state.version - 1),
                  "return_snapshot" => "false"
                },
                content: [
                  %Binary.Node{
                    tag: "patch",
                    attrs: %{},
                    content: encoded_patch
                  }
                ]
              }
            ]
          }
        ]
      }

      # Send via session GenServer
      case GenServer.call(session, {:send_iq, iq_node, message_id}, 30_000) do
        {:ok, _response} ->
          # Persist new state
          persist_collection_state(store, collection_name, new_hash_state, new_mutation_macs)
          {:ok, new_hash_state, new_mutation_macs}

        {:error, reason} ->
          {:error, {:iq_failed, reason}}
      end
    end
  end

  # ============================================================================
  # Collection State Management
  # ============================================================================

  @doc "Get all collection names."
  @spec all_collections() :: [String.t()]
  def all_collections, do: @all_collections

  @doc "Get the current hash state and mutation MACs for a collection."
  @spec get_collection_state(struct(), String.t()) :: {:ok, hash_state(), map()}
  def get_collection_state(store, collection_name) do
    data = Store.load!(store)
    versions = Map.get(data, :app_state_versions, %{})
    all_macs = Map.get(data, :app_state_mutation_macs, %{})

    collection_state = Map.get(versions, collection_name, %{version: 0, hash: LTHash.new()})
    collection_macs = Map.get(all_macs, collection_name, %{})

    {:ok, collection_state, collection_macs}
  end

  @doc "Persist collection hash state and mutation MACs."
  @spec persist_collection_state(struct(), String.t(), hash_state(), map()) :: :ok
  def persist_collection_state(store, collection_name, hash_state, mutation_macs) do
    data = Store.load!(store)
    versions = Map.get(data, :app_state_versions, %{})
    all_macs = Map.get(data, :app_state_mutation_macs, %{})

    updated_versions = Map.put(versions, collection_name, hash_state)
    updated_macs = Map.put(all_macs, collection_name, mutation_macs)

    data =
      data
      |> Map.put(:app_state_versions, updated_versions)
      |> Map.put(:app_state_mutation_macs, updated_macs)

    Store.persist(store, data)
  end

  # ============================================================================
  # Dispatch Incoming Mutations
  # ============================================================================

  @doc """
  Dispatch a decoded mutation to update local state (contacts, chats).

  Called after decoding incoming patches from the server.
  Reference: whatsmeow `appstate.go:114-278` dispatchAppState
  """
  @spec dispatch_mutation(struct(), [String.t()], map()) :: :ok | :ignored
  def dispatch_mutation(store, index, action_value) when is_list(index) do
    case index do
      ["contact", jid] ->
        contact_action = get_action_field(action_value, :contact_action)

        if contact_action do
          ExWapp.Contact.merge_from_sync(store, jid, contact_action)
        else
          :ignored
        end

      ["archive", jid] ->
        archive_action = get_action_field(action_value, :archive_chat_action)

        if archive_action do
          ExWapp.Chat.update_archived(store, jid, Map.get(archive_action, :archived, false))
        else
          :ignored
        end

      ["pin_v1", jid] ->
        pin_action = get_action_field(action_value, :pin_action)

        if pin_action do
          ExWapp.Chat.update_pinned(store, jid, Map.get(pin_action, :pinned, false))
        else
          :ignored
        end

      ["mute", jid] ->
        mute_action = get_action_field(action_value, :mute_action)

        if mute_action do
          ExWapp.Chat.update_muted(store, jid, mute_action)
        else
          :ignored
        end

      ["deleteChat", jid] ->
        ExWapp.Chat.delete(store, jid)

      ["markChatAsRead", jid] ->
        if action_value do
          ExWapp.Chat.mark_read_from_sync(store, jid, action_value)
        else
          :ignored
        end

      _ ->
        :ignored
    end
  rescue
    error ->
      Logger.warning(
        "[APP_STATE] Dispatch mutation error: #{inspect(error)} index=#{inspect(index)}"
      )

      :ignored
  end

  def dispatch_mutation(_store, _index, _action_value), do: :ignored

  defp get_action_field(nil, _field), do: nil

  defp get_action_field(action_value, field) when is_map(action_value) do
    Map.get(action_value, field)
  end

  defp get_action_field(_, _), do: nil

  # ============================================================================
  # Helpers
  # ============================================================================

  defp get_latest_app_state_key(store) do
    data = Store.load!(store)
    app_state_keys = Map.get(data, :app_state_keys, %{})

    if map_size(app_state_keys) == 0 do
      {:error, :no_app_state_keys}
    else
      # Pick the key with the highest timestamp
      {key_id_hex, key_entry} =
        Enum.max_by(app_state_keys, fn {_id, entry} -> Map.get(entry, :timestamp, 0) end)

      case Base.decode16(key_id_hex, case: :mixed) do
        {:ok, key_id_binary} ->
          {:ok, key_id_binary, key_entry.data}

        :error ->
          {:error, {:invalid_key_id_hex, key_id_hex}}
      end
    end
  end

  defp get_key_data(key_store, key_id_hex) when is_map(key_store) and is_binary(key_id_hex) do
    case Map.get(key_store, key_id_hex) do
      %{data: data} when is_binary(data) and byte_size(data) == 32 -> {:ok, data}
      nil -> {:error, {:key_not_found, key_id_hex}}
      other -> {:error, {:invalid_key_entry, other}}
    end
  end

  defp get_key_data(_, _), do: {:error, :invalid_key_store_or_id}

  defp build_message_range(nil) do
    %SyncActionMessageRange{
      last_message_timestamp: System.system_time(:second)
    }
  end

  defp build_message_range(timestamp) when is_integer(timestamp) do
    %SyncActionMessageRange{
      last_message_timestamp: timestamp
    }
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64() |> String.slice(0, 16)
  end
end
