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
    SyncdMutations,
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
    SyncActionMessageRange,
    ExternalBlobReference
  }

  alias ExWapp.Binary
  alias ExWapp.Store

  @media_key_hkdf_info "WhatsApp App State Keys"
  @appstate_media_mms_type "md-app-state"
  @default_media_hosts ["mmg.whatsapp.net", "mmg-fallback.whatsapp.net"]
  @media_hmac_length 10

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
          required(:index) => [String.t()],
          required(:version) => integer(),
          required(:value) => %SyncActionValue{},
          optional(:operation) => :remove
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

  @type action_value :: %SyncActionValue{} | nil

  @type decoded_mutation :: %{
          operation: non_neg_integer(),
          action: action_value(),
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
    normalized_jid = normalize_contact_jid(jid)

    %{
      type: @collection_critical_unblock_low,
      mutations: [
        %{
          index: ["contact", normalized_jid],
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
      type: @collection_regular_high,
      mutations: [
        %{
          # Third index component is delete-media flag ("0" = keep media).
          index: ["deleteChat", jid, "0"],
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
      type: @collection_regular_high,
      mutations: [
        %{
          # ["1","0"] matches web client shape (keep-starred disabled, keep-media disabled).
          index: ["clearChat", jid, "1", "0"],
          version: 6,
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

    {mutations, value_macs, updated_macs} =
      encode_all_mutations(patch_info.mutations, keys, key_id, timestamp, mutation_macs)

    new_hash = compute_lthash_update(hash_state.hash, value_macs)
    new_version = hash_state.version + 1

    encoded =
      finalize_patch(mutations, value_macs, new_hash, new_version, collection_name, keys, key_id)

    new_hash_state = %{version: new_version, hash: new_hash}
    {:ok, encoded, new_hash_state, updated_macs}
  rescue
    error ->
      {:error, {:encode_patch_failed, error}}
  end

  defp encode_all_mutations(raw_mutations, keys, key_id, timestamp, mutation_macs) do
    Enum.reduce(raw_mutations, {[], [], mutation_macs}, fn mut, {muts, vmacs, mmacs} ->
      {mutation, value_mac, old_mac, operation, mmacs} =
        encode_single_mutation(mut, keys, key_id, timestamp, mmacs)

      {muts ++ [mutation], vmacs ++ [{value_mac, old_mac, operation}], mmacs}
    end)
  end

  defp encode_single_mutation(mut, keys, key_id, timestamp, mmacs) do
    operation = if Map.get(mut, :operation) == :remove, do: 1, else: 0
    value = %{mut.value | timestamp: timestamp}
    index_json = Jason.encode!(mut.index)

    content =
      SyncAction.encode_sync_action_data(%SyncActionData{
        index: index_json,
        value: value,
        padding: <<>>,
        version: mut.version
      })

    {iv, ciphertext} = Crypto.encrypt_cbc(content, keys.value_encryption)
    encrypted = iv <> ciphertext

    value_mac =
      Crypto.compute_content_mac(operation, encrypted, key_id, keys.value_mac)

    index_mac = Crypto.compute_index_mac(index_json, keys.index)
    index_hex = Base.encode16(index_mac, case: :lower)
    old_mac = Map.get(mmacs, index_hex)

    updated_mmacs =
      if operation == 0,
        do: Map.put(mmacs, index_hex, value_mac),
        else: Map.delete(mmacs, index_hex)

    mutation = %SyncdMutation{
      operation: operation,
      record: %SyncdRecord{
        index: index_mac,
        value: encrypted <> value_mac,
        key_id: key_id
      }
    }

    {mutation, value_mac, old_mac, operation, updated_mmacs}
  end

  defp compute_lthash_update(hash, value_macs) do
    subtract =
      value_macs
      |> Enum.map(fn {_new, old, _op} -> old end)
      |> Enum.reject(&is_nil/1)

    add =
      value_macs
      |> Enum.filter(fn {_new, _old, op} -> op == 0 end)
      |> Enum.map(fn {new_mac, _old, _op} -> new_mac end)

    LTHash.subtract_then_add(hash, subtract, add)
  end

  defp finalize_patch(mutations, value_macs, hash, version, collection, keys, key_id) do
    snapshot_mac =
      Crypto.compute_snapshot_mac(hash, version, collection, keys.snapshot_mac)

    all_value_macs =
      Enum.map(value_macs, fn {new_mac, _old, _op} -> new_mac end)

    patch_mac =
      Crypto.compute_patch_mac(
        snapshot_mac,
        all_value_macs,
        version,
        collection,
        keys.patch_mac
      )

    %SyncdPatch{
      # WhatsApp web clients omit patch.version on outgoing mutations.
      mutations: mutations,
      snapshot_mac: snapshot_mac,
      patch_mac: patch_mac,
      key_id: key_id
    }
    |> SyncAction.encode_syncd_patch()
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
    record = mutation.record

    with {:ok, keys, key_id} <- resolve_mutation_keys(record, key_store),
         {:ok, encrypted_content, value_mac} <- split_record_value(record.value),
         :ok <-
           verify_content_mac(
             mutation.operation,
             encrypted_content,
             key_id,
             keys,
             validate_macs,
             value_mac
           ),
         {:ok, plaintext} <- decrypt_content(encrypted_content, keys),
         {:ok, sync_data} <- decode_action_data(plaintext),
         :ok <- verify_index_mac(sync_data.index, record.index, keys, validate_macs) do
      {:ok, build_decoded_mutation(mutation, sync_data, record.index, value_mac)}
    end
  end

  defp resolve_mutation_keys(record, key_store) do
    key_id = record.key_id

    key_id_hex =
      if is_binary(key_id),
        do: Base.encode16(key_id, case: :lower),
        else: nil

    with {:ok, key_data} <- get_key_data(key_store, key_id_hex) do
      {:ok, Crypto.expand_keys(key_data), key_id}
    end
  end

  defp split_record_value(content)
       when is_binary(content) and byte_size(content) > 32 do
    content_len = byte_size(content) - 32

    {:ok, binary_part(content, 0, content_len), binary_part(content, content_len, 32)}
  end

  defp split_record_value(_content), do: {:error, :invalid_record_value}

  defp verify_content_mac(_op, _enc, _key_id, _keys, false, _mac), do: :ok

  defp verify_content_mac(op, encrypted, key_id, keys, true, value_mac) do
    expected =
      Crypto.compute_content_mac(op, encrypted, key_id, keys.value_mac)

    if expected == value_mac, do: :ok, else: {:error, :mismatching_content_mac}
  end

  defp decrypt_content(encrypted, _keys) when byte_size(encrypted) < 16 do
    {:error, :encrypted_content_too_short}
  end

  defp decrypt_content(encrypted, keys) do
    iv = binary_part(encrypted, 0, 16)
    ct = binary_part(encrypted, 16, byte_size(encrypted) - 16)

    case Crypto.decrypt_cbc(ct, keys.value_encryption, iv) do
      {:ok, _plaintext} = ok -> ok
      {:error, reason} -> {:error, {:decrypt_failed, reason}}
    end
  end

  defp decode_action_data(plaintext) do
    case SyncAction.decode_sync_action_data(plaintext) do
      {:ok, _data} = ok -> ok
      {:error, reason} -> {:error, {:decode_sync_action_data_failed, reason}}
    end
  end

  defp verify_index_mac(_index_blob, _index_mac, _keys, false), do: :ok

  defp verify_index_mac(index_blob, index_mac, keys, true) when is_binary(index_blob) do
    expected = Crypto.compute_index_mac(index_blob, keys.index)
    if expected == index_mac, do: :ok, else: {:error, :mismatching_index_mac}
  end

  defp verify_index_mac(_index_blob, _index_mac, _keys, _validate), do: :ok

  defp build_decoded_mutation(mutation, sync_data, index_mac, value_mac) do
    index =
      case Jason.decode(sync_data.index || "[]") do
        {:ok, parsed} when is_list(parsed) -> parsed
        _ -> []
      end

    %{
      operation: mutation.operation,
      action: sync_data.value,
      version: sync_data.version,
      index: index,
      index_mac: index_mac,
      value_mac: value_mac
    }
  end

  @doc """
  Decode and validate a single SyncdPatch.

  This verifies:
  - content/index MACs per mutation,
  - snapshot MAC,
  - patch MAC,
  - LTHash state transition.
  """
  @spec decode_patch(%SyncdPatch{}, String.t(), hash_state(), map(), map(), boolean()) ::
          {:ok, [decoded_mutation()], hash_state(), map()} | {:error, term()}
  def decode_patch(
        %SyncdPatch{} = patch,
        collection_name,
        hash_state,
        mutation_macs,
        key_store,
        validate_macs \\ true
      ) do
    with {:ok, patch_version} <- normalize_patch_version(patch.version, hash_state.version),
         {:ok, key_data} <- get_patch_key_data(patch, key_store),
         keys <- Crypto.expand_keys(key_data),
         {:ok, decoded_mutations} <- decode_mutations(patch.mutations, key_store, validate_macs),
         {:ok, new_hash} <-
           update_hash_for_patch(decoded_mutations, hash_state.hash, mutation_macs),
         :ok <-
           validate_snapshot_mac(
             patch,
             validate_macs,
             new_hash,
             patch_version,
             collection_name,
             keys
           ),
         :ok <-
           validate_patch_mac(
             patch,
             validate_macs,
             patch_version,
             collection_name,
             decoded_mutations,
             keys
           ),
         {:ok, updated_mutation_macs} <- update_mutation_macs(decoded_mutations, mutation_macs) do
      {:ok, decoded_mutations, %{version: patch_version, hash: new_hash}, updated_mutation_macs}
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
    do_send_mutation(session, patch_info, store, true)
  end

  defp do_send_mutation(session, patch_info, store, allow_retry) do
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
                    content: Binary.raw(encoded_patch)
                  }
                ]
              }
            ]
          }
        ]
      }

      # Send via session GenServer
      case GenServer.call(session, {:send_iq, iq_node, message_id}, 30_000) do
        {:ok, response} ->
          case validate_mutation_response(response, collection_name) do
            :ok ->
              persist_collection_state(store, collection_name, new_hash_state, new_mutation_macs)
              apply_outgoing_patch(store, patch_info)
              refresh_collection_after_mutation(session, store, collection_name)
              {:ok, new_hash_state, new_mutation_macs}

            {:error, {:conflict, _code}} when allow_retry ->
              Logger.warning(
                "[APP_STATE] Conflict while sending patch for #{collection_name}, applying conflict response and retrying once"
              )

              _ = apply_collection_response(store, collection_name, response, session)
              do_send_mutation(session, patch_info, store, false)

            {:error, reason} ->
              {:error, {:app_state_update_failed, reason}}
          end

        {:error, reason} ->
          {:error, {:iq_failed, reason}}
      end
    end
  end

  defp refresh_collection_after_mutation(session, store, collection_name) do
    spawn(fn ->
      case fetch_collection(session, store, collection_name) do
        :ok ->
          :ok

        {:error, reason} ->
          Logger.debug(
            "[APP_STATE] Post-mutation refresh failed for #{collection_name}: #{inspect(reason)}"
          )
      end
    end)
  end

  defp validate_mutation_response(%Binary.Node{} = response, collection_name) do
    case find_collection_node(response, collection_name) || find_first_collection_node(response) do
      nil ->
        {:error, :collection_not_found}

      %Binary.Node{attrs: attrs} = collection_node ->
        case Map.get(attrs, "type") do
          "error" -> {:error, classify_collection_error(collection_node)}
          _ -> :ok
        end
    end
  end

  defp validate_mutation_response(_response, _collection_name) do
    {:error, :invalid_collection_response}
  end

  defp classify_collection_error(%Binary.Node{} = collection_node) do
    case collection_error_code(collection_node) do
      409 -> {:conflict, 409}
      nil -> {:server_error, :unknown}
      code -> {:server_error, code}
    end
  end

  defp collection_error_code(%Binary.Node{content: children}) when is_list(children) do
    Enum.find_value(children, fn
      %Binary.Node{tag: "error", attrs: attrs} ->
        parse_integer_attr(Map.get(attrs, "code"))

      _ ->
        nil
    end)
  end

  defp collection_error_code(_), do: nil

  @doc """
  Fetch and apply a single app state collection from the server.
  """
  @spec fetch_collection(GenServer.server(), struct(), String.t()) :: :ok | {:error, term()}
  def fetch_collection(session, store, collection_name) do
    case do_fetch_collection(session, store, collection_name, _want_snapshot = true) do
      :ok ->
        :ok

      {:error, :snapshot_not_supported} ->
        do_fetch_collection(session, store, collection_name, false)

      {:error, {:apply_snapshot_failed, _reason}} ->
        do_fetch_collection(session, store, collection_name, false)

      {:error, _reason} = error ->
        error
    end
  end

  defp do_fetch_collection(session, store, collection_name, want_snapshot) do
    with {:ok, hash_state, _macs} <- get_collection_state(store, collection_name),
         snapshot? <- want_snapshot and hash_state.version == 0,
         {:ok, response} <-
           send_collection_fetch_iq(session, collection_name, hash_state.version, snapshot?),
         {:ok, count} <- apply_collection_response(store, collection_name, response, session) do
      Logger.debug("[APP_STATE] Applied #{count} mutations for #{collection_name}")

      :ok
    end
  end

  @doc """
  Apply collection response content (`snapshot` + `patches`) to local store.
  """
  @spec apply_collection_response(struct(), String.t(), Binary.Node.t()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def apply_collection_response(store, collection_name, response) do
    apply_collection_response(store, collection_name, response, nil)
  end

  @spec apply_collection_response(struct(), String.t(), Binary.Node.t(), pid() | nil) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def apply_collection_response(store, collection_name, response, session) do
    with {:ok, collection_data} <- extract_collection_data(response, collection_name),
         {:ok, hash_state, mutation_macs} <- get_collection_state(store, collection_name),
         key_store <- store_key_data(store),
         {:ok, hash_state, mutation_macs, snapshot_count} <-
           maybe_apply_snapshot(
             store,
             session,
             collection_name,
             collection_data.snapshot,
             key_store,
             hash_state,
             mutation_macs
           ),
         {:ok, hash_state, mutation_macs, patch_count} <-
           apply_patches(
             store,
             session,
             collection_name,
             collection_data.patches,
             key_store,
             hash_state,
             mutation_macs
           ) do
      persist_collection_state(store, collection_name, hash_state, mutation_macs)
      {:ok, snapshot_count + patch_count}
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
  @spec dispatch_mutation(struct(), non_neg_integer(), [String.t()], action_value()) ::
          :ok | :ignored
  def dispatch_mutation(store, operation, index, action_value)
      when is_integer(operation) and is_list(index) do
    case index do
      ["contact", jid] ->
        dispatch_contact_mutation(store, operation, jid, action_value)

      ["archive", jid] ->
        dispatch_archive_mutation(store, operation, jid, action_value)

      ["pin_v1", jid] ->
        dispatch_pin_mutation(store, operation, jid, action_value)

      ["mute", jid] ->
        dispatch_mute_mutation(store, operation, jid, action_value)

      ["deleteChat", jid] ->
        dispatch_delete_chat_mutation(store, operation, jid)

      ["deleteChat", jid, _delete_media] ->
        dispatch_delete_chat_mutation(store, operation, jid)

      ["markChatAsRead", jid] ->
        dispatch_mark_read_mutation(store, operation, jid, action_value)

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

  @doc """
  Backwards-compatible dispatch entrypoint for SET operations.
  """
  @spec dispatch_mutation(struct(), [String.t()], action_value()) :: :ok | :ignored
  def dispatch_mutation(store, index, action_value) do
    dispatch_mutation(store, 0, index, action_value)
  end

  defp dispatch_contact_mutation(store, 1, jid, _action_value),
    do: ExWapp.Contact.delete(store, jid)

  defp dispatch_contact_mutation(store, _operation, jid, action_value) do
    case get_action_field(action_value, :contact_action) do
      nil -> :ignored
      contact_action -> ExWapp.Contact.merge_from_sync(store, jid, contact_action)
    end
  end

  defp dispatch_archive_mutation(_store, 1, _jid, _action_value), do: :ignored

  defp dispatch_archive_mutation(store, _operation, jid, action_value) do
    case get_action_field(action_value, :archive_chat_action) do
      nil ->
        :ignored

      archive_action ->
        ExWapp.Chat.update_archived(store, jid, Map.get(archive_action, :archived, false))
    end
  end

  defp dispatch_pin_mutation(_store, 1, _jid, _action_value), do: :ignored

  defp dispatch_pin_mutation(store, _operation, jid, action_value) do
    case get_action_field(action_value, :pin_action) do
      nil -> :ignored
      pin_action -> ExWapp.Chat.update_pinned(store, jid, Map.get(pin_action, :pinned, false))
    end
  end

  defp dispatch_mute_mutation(_store, 1, _jid, _action_value), do: :ignored

  defp dispatch_mute_mutation(store, _operation, jid, action_value) do
    case get_action_field(action_value, :mute_action) do
      nil -> :ignored
      mute_action -> ExWapp.Chat.update_muted(store, jid, mute_action)
    end
  end

  defp dispatch_delete_chat_mutation(store, _operation, jid) do
    ExWapp.Chat.delete(store, jid)
  end

  defp dispatch_mark_read_mutation(_store, 1, _jid, _action_value), do: :ignored

  defp dispatch_mark_read_mutation(store, _operation, jid, action_value) do
    if action_value do
      ExWapp.Chat.mark_read_from_sync(store, jid, action_value)
    else
      :ignored
    end
  end

  defp get_action_field(nil, _field), do: nil

  defp get_action_field(action_value, field) when is_map(action_value) do
    Map.get(action_value, field)
  end

  defp get_action_field(_, _), do: nil

  @doc """
  Apply outgoing mutation effects locally after a successful server ack.
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

  # ============================================================================
  # Helpers
  # ============================================================================

  defp send_collection_fetch_iq(session, collection_name, version, return_snapshot?) do
    message_id = generate_request_id()

    collection_attrs =
      if return_snapshot? do
        %{"name" => collection_name, "return_snapshot" => "true"}
      else
        %{
          "name" => collection_name,
          "version" => to_string(version),
          "return_snapshot" => "false"
        }
      end

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
              attrs: collection_attrs,
              content: nil
            }
          ]
        }
      ]
    }

    case GenServer.call(session, {:send_iq, iq_node, message_id}, 30_000) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, {:iq_failed, reason}}
    end
  end

  defp extract_collection_data(%Binary.Node{} = response, collection_name) do
    case find_collection_node(response, collection_name) do
      nil ->
        {:error, :collection_not_found}

      %Binary.Node{attrs: attrs, content: children} ->
        snapshot = find_child_binary(children, "snapshot")
        patches = extract_patch_binaries(children)

        {:ok,
         %{
           snapshot: snapshot,
           patches: patches,
           has_more_patches: parse_bool_attr(Map.get(attrs, "has_more_patches"))
         }}
    end
  end

  defp extract_collection_data(_response, _collection_name) do
    {:error, :invalid_collection_response}
  end

  defp find_collection_node(%Binary.Node{tag: "collection", attrs: attrs} = node, collection_name) do
    if Map.get(attrs, "name") == collection_name do
      node
    end
  end

  defp find_collection_node(%Binary.Node{content: children}, collection_name)
       when is_list(children) do
    Enum.find_value(children, &find_collection_node(&1, collection_name))
  end

  defp find_collection_node(_node, _collection_name), do: nil

  defp find_first_collection_node(%Binary.Node{tag: "collection"} = node), do: node

  defp find_first_collection_node(%Binary.Node{content: children}) when is_list(children) do
    Enum.find_value(children, &find_first_collection_node/1)
  end

  defp find_first_collection_node(_node), do: nil

  defp find_child_binary(children, tag) when is_list(children) do
    Enum.find_value(children, fn
      %Binary.Node{tag: ^tag, content: value} -> binary_content(value)
      _ -> nil
    end)
  end

  defp find_child_binary(_children, _tag), do: nil

  defp extract_patch_binaries(children) when is_list(children) do
    Enum.flat_map(children, fn
      %Binary.Node{tag: "patches", content: patch_nodes} when is_list(patch_nodes) ->
        Enum.flat_map(patch_nodes, fn
          %Binary.Node{tag: "patch", content: value} ->
            case binary_content(value) do
              nil -> []
              binary -> [binary]
            end

          _ ->
            []
        end)

      %Binary.Node{tag: "patch", content: value} ->
        case binary_content(value) do
          nil -> []
          binary -> [binary]
        end

      _ ->
        []
    end)
  end

  defp extract_patch_binaries(_children), do: []

  defp binary_content(%Binary.Raw{data: data}) when is_binary(data), do: data
  defp binary_content(data) when is_binary(data), do: data
  defp binary_content(_), do: nil

  defp parse_bool_attr(value) when is_boolean(value), do: value
  defp parse_bool_attr(1), do: true
  defp parse_bool_attr(0), do: false

  defp parse_bool_attr(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "1" -> true
      "true" -> true
      "yes" -> true
      "0" -> false
      "false" -> false
      "no" -> false
      _ -> false
    end
  end

  defp parse_bool_attr(_), do: false

  defp parse_integer_attr(value) when is_integer(value), do: value

  defp parse_integer_attr(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {parsed, _} -> parsed
      :error -> nil
    end
  end

  defp parse_integer_attr(_), do: nil

  defp store_key_data(store) do
    store
    |> Store.load!()
    |> Map.get(:app_state_keys, %{})
  end

  defp maybe_apply_snapshot(
         _store,
         _session,
         _collection_name,
         nil,
         _key_store,
         hash_state,
         mutation_macs
       ) do
    {:ok, hash_state, mutation_macs, 0}
  end

  defp maybe_apply_snapshot(store, session, collection_name, snapshot_binary, key_store, _hs, _mm) do
    with {:ok, snapshot} <- decode_snapshot_payload(session, snapshot_binary),
         {:ok, version} <- normalize_patch_version(snapshot.version),
         {:ok, decoded} <- decode_snapshot_mutations(snapshot, key_store),
         {:ok, hash, macs} <-
           verify_snapshot(snapshot, decoded, version, collection_name, key_store) do
      dispatch_decoded_mutations(store, decoded)
      {:ok, %{version: version, hash: hash}, macs, length(decoded)}
    else
      {:error, reason}
      when reason in [
             :invalid_length_delimited_field,
             :missing_snapshot_key_id,
             :invalid_snapshot_payload,
             :invalid_external_blob_reference
           ] ->
        {:error, :snapshot_not_supported}

      {:error, reason} ->
        {:error, {:apply_snapshot_failed, reason}}
    end
  end

  defp decode_snapshot_mutations(snapshot, key_store) do
    with {:ok, mutations} <- build_snapshot_mutations(snapshot) do
      decode_mutations(mutations, key_store, true)
    end
  end

  defp verify_snapshot(snapshot, decoded_mutations, version, collection_name, key_store) do
    with {:ok, key_data} <- get_snapshot_key_data(snapshot, key_store),
         keys <- Crypto.expand_keys(key_data),
         new_hash <- LTHash.add(LTHash.new(), Enum.map(decoded_mutations, & &1.value_mac)),
         :ok <-
           validate_snapshot_hash(
             snapshot.mac,
             keys.snapshot_mac,
             new_hash,
             version,
             collection_name
           ),
         {:ok, macs} <- update_mutation_macs(decoded_mutations, %{}) do
      {:ok, new_hash, macs}
    end
  end

  defp dispatch_decoded_mutations(store, decoded_mutations) do
    Enum.each(decoded_mutations, fn m ->
      dispatch_mutation(store, m.operation, m.index, m.action)
    end)
  end

  defp apply_patches(
         store,
         session,
         collection_name,
         patches,
         key_store,
         hash_state,
         mutation_macs
       )
       when is_list(patches) do
    Enum.reduce_while(patches, {:ok, hash_state, mutation_macs, 0}, fn patch_binary,
                                                                       {:ok, state, macs, count} ->
      case apply_single_patch(
             store,
             session,
             collection_name,
             patch_binary,
             key_store,
             state,
             macs
           ) do
        {:ok, decoded, new_state, new_macs} ->
          {:cont, {:ok, new_state, new_macs, count + length(decoded)}}

        {:error, reason} ->
          {:halt, {:error, {:apply_patch_failed, reason}}}
      end
    end)
  end

  defp apply_single_patch(store, session, collection_name, patch_binary, key_store, state, macs) do
    with {:ok, patch} <- SyncAction.decode_syncd_patch(patch_binary),
         {:ok, patch} <- maybe_resolve_external_patch_mutations(session, patch),
         {:ok, decoded, new_state, new_macs} <-
           decode_patch(patch, collection_name, state, macs, key_store, true) do
      dispatch_decoded_mutations(store, decoded)
      {:ok, decoded, new_state, new_macs}
    end
  end

  defp decode_snapshot_payload(_session, snapshot_binary) when not is_binary(snapshot_binary) do
    {:error, :invalid_snapshot_payload}
  end

  defp decode_snapshot_payload(session, snapshot_binary) do
    case SyncAction.decode_syncd_snapshot(snapshot_binary) do
      {:ok, snapshot} ->
        {:ok, snapshot}

      {:error, _reason} ->
        with {:ok, ref} <- SyncAction.decode_external_blob_reference(snapshot_binary),
             {:ok, raw_snapshot} <- download_external_blob(session, ref),
             {:ok, snapshot} <- SyncAction.decode_syncd_snapshot(raw_snapshot) do
          {:ok, snapshot}
        end
    end
  end

  defp maybe_resolve_external_patch_mutations(
         _session,
         %SyncdPatch{external_mutations: nil} = patch
       ) do
    {:ok, patch}
  end

  defp maybe_resolve_external_patch_mutations(
         session,
         %SyncdPatch{external_mutations: %ExternalBlobReference{} = ref} = patch
       ) do
    with {:ok, raw_mutations} <- download_external_blob(session, ref),
         {:ok, %SyncdMutations{mutations: mutations}} <-
           SyncAction.decode_syncd_mutations(raw_mutations) do
      {:ok, %{patch | mutations: mutations}}
    end
  end

  defp maybe_resolve_external_patch_mutations(_session, %SyncdPatch{} = patch) do
    {:ok, patch}
  end

  defp download_external_blob(session, %ExternalBlobReference{} = ref) do
    with {:ok, direct_path} <- validate_external_direct_path(ref.direct_path),
         {:ok, encrypted_payload} <-
           download_external_blob_payload(session, direct_path, ref.file_enc_sha256) do
      decrypt_external_blob_payload(ref.media_key, encrypted_payload)
    end
  end

  defp validate_external_direct_path(path) when is_binary(path) do
    trimmed = String.trim(path)
    if trimmed == "", do: {:error, :missing_external_blob_path}, else: {:ok, trimmed}
  end

  defp validate_external_direct_path(_), do: {:error, :missing_external_blob_path}

  defp download_external_blob_payload(session, direct_path, file_enc_sha256) do
    hosts = media_download_hosts(session)

    Enum.reduce_while(hosts, {:error, :external_blob_download_failed}, fn host, _acc ->
      case http_get_binary(build_external_blob_url(host, direct_path, file_enc_sha256)) do
        {:ok, body} ->
          {:halt, {:ok, body}}

        {:error, reason} ->
          Logger.debug(
            "[APP_STATE] External blob download failed from #{host}: #{inspect(reason)}"
          )

          {:cont, {:error, reason}}
      end
    end)
  end

  defp media_download_hosts(session) do
    queried_hosts =
      case query_media_conn_hosts(session) do
        {:ok, hosts} when is_list(hosts) -> hosts
        _ -> []
      end

    (queried_hosts ++ @default_media_hosts)
    |> Enum.filter(&(is_binary(&1) and String.trim(&1) != ""))
    |> Enum.uniq()
  end

  defp query_media_conn_hosts(session) when is_pid(session) do
    if Process.alive?(session) do
      message_id = generate_request_id()

      iq_node = %Binary.Node{
        tag: "iq",
        attrs: %{
          "id" => message_id,
          "xmlns" => "w:m",
          "type" => "set",
          "to" => "s.whatsapp.net"
        },
        content: [
          %Binary.Node{
            tag: "media_conn",
            attrs: %{},
            content: nil
          }
        ]
      }

      case GenServer.call(session, {:send_iq, iq_node, message_id}, 30_000) do
        {:ok, response} -> parse_media_conn_hosts(response)
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :invalid_session}
    end
  end

  defp query_media_conn_hosts(_), do: {:error, :invalid_session}

  defp parse_media_conn_hosts(%Binary.Node{} = response) do
    case find_media_conn_node(response) do
      %Binary.Node{content: children} when is_list(children) ->
        hosts =
          children
          |> Enum.flat_map(fn
            %Binary.Node{tag: "host", attrs: attrs} ->
              case Map.get(attrs, "hostname") do
                host when is_binary(host) and host != "" -> [host]
                _ -> []
              end

            _ ->
              []
          end)
          |> Enum.uniq()

        if hosts == [], do: {:error, :no_media_hosts}, else: {:ok, hosts}

      _ ->
        {:error, :media_conn_not_found}
    end
  end

  defp parse_media_conn_hosts(_), do: {:error, :invalid_media_conn_response}

  defp find_media_conn_node(%Binary.Node{tag: "media_conn"} = node), do: node

  defp find_media_conn_node(%Binary.Node{content: children}) when is_list(children) do
    Enum.find_value(children, &find_media_conn_node/1)
  end

  defp find_media_conn_node(_), do: nil

  defp build_external_blob_url(_host, direct_path, _file_enc_sha256)
       when direct_path in [nil, ""] do
    direct_path
  end

  defp build_external_blob_url(_host, <<"https://", _::binary>> = direct_path, _file_enc_sha256) do
    direct_path
  end

  defp build_external_blob_url(_host, <<"http://", _::binary>> = direct_path, _file_enc_sha256) do
    direct_path
  end

  defp build_external_blob_url(host, direct_path, file_enc_sha256) do
    direct_path =
      if String.starts_with?(direct_path, "/"), do: direct_path, else: "/" <> direct_path

    separator = if String.contains?(direct_path, "?"), do: "&", else: "?"

    hash_param =
      case file_enc_sha256 do
        bin when is_binary(bin) and byte_size(bin) > 0 -> Base.url_encode64(bin, padding: false)
        _ -> ""
      end

    "https://#{host}#{direct_path}#{separator}hash=#{hash_param}&mms-type=#{@appstate_media_mms_type}&__wa-mms="
  end

  defp http_get_binary(url) when is_binary(url) and url != "" do
    _ = Application.ensure_all_started(:inets)
    _ = Application.ensure_all_started(:ssl)

    headers = [
      {~c"Origin", ~c"https://web.whatsapp.com"},
      {~c"Referer", ~c"https://web.whatsapp.com/"},
      {~c"User-Agent", ~c"Mozilla/5.0"}
    ]

    request = {String.to_charlist(url), headers}
    http_opts = [timeout: 15_000, connect_timeout: 10_000]

    case :httpc.request(:get, request, http_opts, body_format: :binary) do
      {:ok, {{_http_version, 200, _reason}, _resp_headers, body}} when is_binary(body) ->
        {:ok, body}

      {:ok, {{_http_version, status, _reason}, _resp_headers, body}} ->
        {:error, {:http_status, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp http_get_binary(_), do: {:error, :invalid_external_blob_url}

  defp decrypt_external_blob_payload(nil, payload) when is_binary(payload), do: {:ok, payload}

  defp decrypt_external_blob_payload(media_key, payload)
       when is_binary(media_key) and is_binary(payload) do
    if byte_size(payload) <= @media_hmac_length do
      {:error, :external_blob_payload_too_short}
    else
      ciphertext_len = byte_size(payload) - @media_hmac_length
      <<ciphertext::binary-size(ciphertext_len), mac::binary-size(@media_hmac_length)>> = payload

      with {:ok, iv, cipher_key, mac_key} <- derive_external_blob_keys(media_key),
           :ok <- verify_external_blob_mac(iv, ciphertext, mac_key, mac),
           {:ok, plaintext} <- Crypto.decrypt_cbc(ciphertext, cipher_key, iv) do
        {:ok, plaintext}
      end
    end
  end

  defp decrypt_external_blob_payload(_media_key, _payload),
    do: {:error, :invalid_external_blob_key}

  defp derive_external_blob_keys(media_key)
       when is_binary(media_key) and byte_size(media_key) > 0 do
    expanded = hkdf_sha256(media_key, <<>>, @media_key_hkdf_info, 112)
    iv = binary_part(expanded, 0, 16)
    cipher_key = binary_part(expanded, 16, 32)
    mac_key = binary_part(expanded, 48, 32)
    {:ok, iv, cipher_key, mac_key}
  end

  defp derive_external_blob_keys(_), do: {:error, :invalid_external_blob_key}

  defp verify_external_blob_mac(iv, ciphertext, mac_key, mac)
       when is_binary(iv) and is_binary(ciphertext) and is_binary(mac_key) and is_binary(mac) do
    expected =
      :crypto.mac(:hmac, :sha256, mac_key, [iv, ciphertext])
      |> binary_part(0, @media_hmac_length)

    if expected == mac, do: :ok, else: {:error, :invalid_external_blob_mac}
  end

  defp verify_external_blob_mac(_, _, _, _), do: {:error, :invalid_external_blob_mac}

  defp hkdf_sha256(ikm, <<>>, info, length),
    do: hkdf_sha256(ikm, :binary.copy(<<0>>, 32), info, length)

  defp hkdf_sha256(ikm, salt, info, length) do
    prk = :crypto.mac(:hmac, :sha256, salt, ikm)
    hkdf_expand(prk, info, length)
  end

  defp hkdf_expand(prk, info, length) do
    n = ceil(length / 32)

    {output, _} =
      Enum.reduce(1..n, {<<>>, <<>>}, fn i, {acc, prev} ->
        t = :crypto.mac(:hmac, :sha256, prk, prev <> info <> <<i::8>>)
        {acc <> t, t}
      end)

    binary_part(output, 0, length)
  end

  defp build_snapshot_mutations(snapshot) do
    snapshot_key_id = snapshot.key_id

    mutations =
      Enum.map(snapshot.records, fn record ->
        record =
          if is_binary(record.key_id), do: record, else: %{record | key_id: snapshot_key_id}

        %SyncdMutation{operation: 0, record: record}
      end)

    {:ok, mutations}
  end

  defp get_snapshot_key_data(snapshot, key_store) do
    key_id = snapshot.key_id || snapshot_key_id_from_records(snapshot.records)

    if is_binary(key_id) do
      key_id_hex = Base.encode16(key_id, case: :lower)
      get_key_data(key_store, key_id_hex)
    else
      {:error, :missing_snapshot_key_id}
    end
  end

  defp snapshot_key_id_from_records(records) do
    Enum.find_value(records, fn
      %{key_id: key_id} when is_binary(key_id) -> key_id
      _ -> nil
    end)
  end

  defp normalize_patch_version(version) when is_integer(version) and version >= 0 do
    {:ok, version}
  end

  defp normalize_patch_version(_version), do: {:error, :invalid_patch_version}

  defp normalize_patch_version(version, _current_version)
       when is_integer(version) and version >= 0 do
    {:ok, version}
  end

  defp normalize_patch_version(nil, current_version)
       when is_integer(current_version) and current_version >= 0 do
    {:ok, current_version + 1}
  end

  defp normalize_patch_version(_version, _current_version), do: {:error, :invalid_patch_version}

  defp get_patch_key_data(%SyncdPatch{key_id: key_id}, key_store) when is_binary(key_id) do
    key_id_hex = Base.encode16(key_id, case: :lower)
    get_key_data(key_store, key_id_hex)
  end

  defp get_patch_key_data(_patch, _key_store), do: {:error, :missing_patch_key_id}

  defp update_hash_for_patch(decoded_mutations, hash, mutation_macs) do
    {new_hash, _} =
      Enum.reduce(decoded_mutations, {hash, mutation_macs}, fn mutation, {acc_hash, acc_macs} ->
        index_hex = index_mac_hex(mutation.index_mac)
        old_mac = Map.get(acc_macs, index_hex)
        subtract_macs = if is_binary(old_mac), do: [old_mac], else: []
        add_macs = if mutation.operation == 0, do: [mutation.value_mac], else: []

        next_hash = LTHash.subtract_then_add(acc_hash, subtract_macs, add_macs)
        next_macs = put_mutation_mac(acc_macs, mutation)
        {next_hash, next_macs}
      end)

    {:ok, new_hash}
  rescue
    error ->
      {:error, {:hash_update_failed, error}}
  end

  defp validate_snapshot_mac(_patch, false, _h, _v, _c, _k), do: :ok

  defp validate_snapshot_mac(%{snapshot_mac: nil}, true, _h, _v, _c, _k),
    do: {:error, :invalid_snapshot_mac}

  defp validate_snapshot_mac(patch, true, hash, version, collection, keys) do
    expected =
      Crypto.compute_snapshot_mac(hash, version, collection, keys.snapshot_mac)

    compare_mac(expected, patch.snapshot_mac, :mismatching_snapshot_mac)
  end

  defp validate_patch_mac(_p, false, _v, _c, _m, _k), do: :ok

  defp validate_patch_mac(%{snapshot_mac: s, patch_mac: p}, true, _v, _c, _m, _k)
       when not is_binary(s) or not is_binary(p),
       do: {:error, :invalid_patch_mac}

  defp validate_patch_mac(patch, true, version, collection, decoded_mutations, keys) do
    value_macs = Enum.map(decoded_mutations, & &1.value_mac)

    expected =
      Crypto.compute_patch_mac(
        patch.snapshot_mac,
        value_macs,
        version,
        collection,
        keys.patch_mac
      )

    compare_mac(expected, patch.patch_mac, :mismatching_patch_mac)
  end

  defp validate_snapshot_hash(mac, mac_key, hash, version, collection) do
    expected =
      Crypto.compute_snapshot_mac(hash, version, collection, mac_key)

    compare_mac(expected, mac, :mismatching_snapshot_mac)
  end

  defp compare_mac(expected, actual, _error) when expected == actual, do: :ok
  defp compare_mac(_expected, _actual, error), do: {:error, error}

  defp update_mutation_macs(decoded_mutations, mutation_macs) when is_map(mutation_macs) do
    updated =
      Enum.reduce(decoded_mutations, mutation_macs, fn mutation, acc ->
        put_mutation_mac(acc, mutation)
      end)

    {:ok, updated}
  end

  defp update_mutation_macs(_decoded_mutations, _mutation_macs) do
    {:error, :invalid_mutation_macs}
  end

  defp put_mutation_mac(macs, mutation) do
    index_hex = index_mac_hex(mutation.index_mac)

    case mutation.operation do
      0 -> Map.put(macs, index_hex, mutation.value_mac)
      1 -> Map.delete(macs, index_hex)
      _ -> macs
    end
  end

  defp index_mac_hex(index_mac) when is_binary(index_mac) do
    Base.encode16(index_mac, case: :lower)
  end

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

  defp generate_request_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64() |> String.slice(0, 16)
  end
end
