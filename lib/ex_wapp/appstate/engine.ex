defmodule ExWapp.AppState.Engine do
  @moduledoc """
  Public façade for WhatsApp app-state sync.

  This module is the stable entry point; the work lives in five modules, each
  with one reason to change:

  - `ExWapp.AppState.Engine.Builders` — build outgoing patch descriptions
    (contact, archive, pin, mute, delete, mark-read, clear-chat)
  - `ExWapp.AppState.Engine.Codec` — encode/decode patches, mutation MACs,
    snapshot verification and the LTHash chain
  - `ExWapp.AppState.Engine.Sync` — the IQ round-trips with the server, external
    blob download, and applying collection responses
  - `ExWapp.AppState.Engine.Dispatch` — turn decoded mutations into contact and
    chat updates
  - `ExWapp.AppState.Engine.State` — persist collection versions, hashes and
    mutation MACs

  Reference: whatsmeow `appstate/encode.go`, `appstate/decode.go`, `appstate.go`.

  The types for the shapes crossing this boundary (`patch_info`,
  `mutation_info`, `hash_state`, `decoded_mutation`) are declared where they are
  produced, in `Builders` and `Codec`.
  """

  alias ExWapp.AppState.Engine.Builders
  alias ExWapp.AppState.Engine.Codec
  alias ExWapp.AppState.Engine.Dispatch
  alias ExWapp.AppState.Engine.State
  alias ExWapp.AppState.Engine.Sync

  # Building outgoing mutations. Builders declare optional arguments as
  # defaults; defdelegate cannot carry a default, so each arity is delegated.
  defdelegate build_contact(jid, full_name), to: Builders
  defdelegate build_contact(jid, full_name, first_name), to: Builders
  defdelegate build_delete_contact(jid), to: Builders
  defdelegate build_archive(jid, archived), to: Builders
  defdelegate build_archive(jid, archived, last_msg_ts), to: Builders
  defdelegate build_pin(jid, pinned), to: Builders
  defdelegate build_mute(jid, muted), to: Builders
  defdelegate build_mute(jid, muted, mute_end_timestamp), to: Builders
  defdelegate build_delete_chat(jid), to: Builders
  defdelegate build_delete_chat(jid, last_msg_ts), to: Builders
  defdelegate build_mark_read(jid, read), to: Builders
  defdelegate build_mark_read(jid, read, last_msg_ts), to: Builders
  defdelegate build_clear_chat(jid), to: Builders
  defdelegate build_clear_chat(jid, last_msg_ts), to: Builders

  # Encoding, decoding, MAC and hash-chain validation.
  defdelegate encode_patch(patch_info, key_id, key_data, hash_state), to: Codec
  defdelegate encode_patch(patch_info, key_id, key_data, hash_state, mutation_macs), to: Codec
  defdelegate decode_mutations(mutations, key_store), to: Codec
  defdelegate decode_mutations(mutations, key_store, validate_macs), to: Codec

  defdelegate decode_patch(patch, collection_name, hash_state, mutation_macs, key_store),
    to: Codec

  defdelegate decode_patch(
                patch,
                collection_name,
                hash_state,
                mutation_macs,
                key_store,
                validate_macs
              ),
              to: Codec

  # Server round-trips.
  defdelegate send_mutation(session, patch_info, store), to: Sync
  defdelegate send_mutation(session, patch_info, store, opts), to: Sync
  defdelegate fetch_collection(session, store, collection_name), to: Sync
  defdelegate fetch_collection(session, store, collection_name, opts), to: Sync
  defdelegate apply_collection_response(store, collection_name, response), to: Sync
  defdelegate apply_collection_response(store, collection_name, response, session), to: Sync

  defdelegate apply_collection_response(store, collection_name, response, session, opts),
    to: Sync

  # Local persistence of collection state.
  defdelegate all_collections(), to: State
  defdelegate get_collection_state(store, collection_name), to: State

  defdelegate persist_collection_state(store, collection_name, hash_state, mutation_macs),
    to: State

  defdelegate reset_collection_state(store, collection_name), to: State

  # Applying decoded mutations locally.
  defdelegate dispatch_mutation(store, index, action_value), to: Dispatch
  defdelegate dispatch_mutation(store, operation, index, action_value), to: Dispatch
  defdelegate dispatch_mutation(store, operation, index, action_value, opts), to: Dispatch
  defdelegate apply_outgoing_patch(store, patch_info), to: Dispatch
  defdelegate apply_outgoing_patch(store, patch_info, opts), to: Dispatch
end
