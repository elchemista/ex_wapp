defmodule ExWapp.AppState.Engine do
  @moduledoc """
  High-level entry point for WhatsApp app-state synchronization.

  The implementation is split by responsibility:

  - `ExWapp.AppState.Engine.Builders` creates outgoing patch descriptions
  - `ExWapp.AppState.Engine.Codec` encodes and validates patch payloads
  - `ExWapp.AppState.Engine.Sync` handles IQ transport and collection syncing
  - `ExWapp.AppState.Engine.State` persists local hash-chain state
  - `ExWapp.AppState.Engine.Dispatch` applies decoded mutations to local data

  Keeping this module small makes the public API easier to scan while the lower
  level protocol details live in focused domain modules.
  """

  alias ExWapp.AppState.Engine.{Builders, Codec, Dispatch, State, Sync}
  alias ExWapp.Proto.SyncAction.{SyncdMutation, SyncdPatch}

  @typedoc "High-level mutation description used before protobuf encoding."
  @type mutation_info :: Codec.mutation_info()

  @typedoc "Logical patch information consumed by the encoder and sender."
  @type patch_info :: Codec.patch_info()

  @typedoc "Stored LTHash version and hash for a collection."
  @type hash_state :: Codec.hash_state()

  @typedoc "Decoded action payload extracted from a mutation."
  @type action_value :: Codec.action_value()

  @typedoc "Decoded mutation plus its validated MAC metadata."
  @type decoded_mutation :: Codec.decoded_mutation()

  @type syncd_mutation :: %SyncdMutation{}
  @type syncd_patch :: %SyncdPatch{}

  @doc """
  Builds a contact upsert mutation for the contact collection.
  """
  @spec build_contact(String.t(), String.t(), String.t() | nil) :: patch_info()
  defdelegate build_contact(jid, full_name, first_name \\ nil), to: Builders

  @doc """
  Builds a remove mutation for a contact entry.
  """
  @spec build_delete_contact(String.t()) :: patch_info()
  defdelegate build_delete_contact(jid), to: Builders

  @doc """
  Builds an archive or unarchive mutation for a chat.
  """
  @spec build_archive(String.t(), boolean(), integer() | nil) :: patch_info()
  defdelegate build_archive(jid, archived, last_msg_ts \\ nil), to: Builders

  @doc """
  Builds a pin or unpin mutation for a chat.
  """
  @spec build_pin(String.t(), boolean()) :: patch_info()
  defdelegate build_pin(jid, pinned), to: Builders

  @doc """
  Builds a mute or unmute mutation for a chat.
  """
  @spec build_mute(String.t(), boolean(), integer()) :: patch_info()
  defdelegate build_mute(jid, muted, mute_end_timestamp \\ -1), to: Builders

  @doc """
  Builds a delete-chat mutation.
  """
  @spec build_delete_chat(String.t(), integer() | nil) :: patch_info()
  defdelegate build_delete_chat(jid, last_msg_ts \\ nil), to: Builders

  @doc """
  Builds a mark-read or mark-unread mutation for a chat.
  """
  @spec build_mark_read(String.t(), boolean(), integer() | nil) :: patch_info()
  defdelegate build_mark_read(jid, read, last_msg_ts \\ nil), to: Builders

  @doc """
  Builds a clear-chat mutation.
  """
  @spec build_clear_chat(String.t(), integer() | nil) :: patch_info()
  defdelegate build_clear_chat(jid, last_msg_ts \\ nil), to: Builders

  @doc """
  Encodes a patch into the protobuf payload sent to WhatsApp.
  """
  @spec encode_patch(patch_info(), binary(), binary(), hash_state(), map()) ::
          {:ok, binary(), hash_state(), map()} | {:error, term()}
  defdelegate encode_patch(patch_info, key_id, key_data, hash_state, mutation_macs \\ %{}),
    to: Codec

  @doc """
  Decodes mutation records and validates their content and index MACs.
  """
  @spec decode_mutations([syncd_mutation()], map(), boolean()) ::
          {:ok, [decoded_mutation()]} | {:error, term()}
  defdelegate decode_mutations(mutations, key_store, validate_macs \\ true), to: Codec

  @doc """
  Decodes and validates a full incoming patch.
  """
  @spec decode_patch(syncd_patch(), String.t(), hash_state(), map(), map(), boolean()) ::
          {:ok, [decoded_mutation()], hash_state(), map()} | {:error, term()}
  defdelegate decode_patch(
                patch,
                collection_name,
                hash_state,
                mutation_macs,
                key_store,
                validate_macs \\ true
              ),
              to: Codec

  @doc """
  Sends an outgoing mutation patch through the session process.
  """
  @spec send_mutation(GenServer.server(), patch_info(), struct()) ::
          {:ok, hash_state(), map()} | {:error, term()}
  defdelegate send_mutation(session, patch_info, store), to: Sync

  @doc """
  Fetches and applies a single collection from the server.
  """
  @spec fetch_collection(GenServer.server(), struct(), String.t()) :: :ok | {:error, term()}
  defdelegate fetch_collection(session, store, collection_name), to: Sync

  @doc """
  Applies a collection response payload to the local store.
  """
  @spec apply_collection_response(struct(), String.t(), ExWapp.Binary.Node.t()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  defdelegate apply_collection_response(store, collection_name, response), to: Sync

  @doc """
  Applies a collection response payload with an optional live session for
  external blob downloads.
  """
  @spec apply_collection_response(struct(), String.t(), ExWapp.Binary.Node.t(), pid() | nil) ::
          {:ok, non_neg_integer()} | {:error, term()}
  defdelegate apply_collection_response(store, collection_name, response, session), to: Sync

  @doc """
  Returns the supported app-state collection names.
  """
  @spec all_collections() :: [String.t()]
  defdelegate all_collections(), to: State

  @doc """
  Loads the saved hash-chain state and mutation MACs for a collection.
  """
  @spec get_collection_state(struct(), String.t()) :: {:ok, hash_state(), map()}
  defdelegate get_collection_state(store, collection_name), to: State

  @doc """
  Persists the current hash-chain state and mutation MAC cache for a collection.
  """
  @spec persist_collection_state(struct(), String.t(), hash_state(), map()) :: :ok
  defdelegate persist_collection_state(store, collection_name, hash_state, mutation_macs),
    to: State

  @doc """
  Applies a decoded mutation to the local contact/chat store.
  """
  @spec dispatch_mutation(struct(), non_neg_integer(), [String.t()], action_value()) ::
          :ok | :ignored
  defdelegate dispatch_mutation(store, operation, index, action_value), to: Dispatch

  @doc """
  Backwards-compatible helper that treats the mutation as a SET operation.
  """
  @spec dispatch_mutation(struct(), [String.t()], action_value()) :: :ok | :ignored
  defdelegate dispatch_mutation(store, index, action_value), to: Dispatch

  @doc """
  Replays the local side effects of a patch after the server acknowledges it.
  """
  @spec apply_outgoing_patch(struct(), patch_info()) :: :ok
  defdelegate apply_outgoing_patch(store, patch_info), to: Dispatch
end
