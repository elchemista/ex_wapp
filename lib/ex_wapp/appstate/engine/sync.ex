defmodule ExWapp.AppState.Engine.Sync do
  @moduledoc """
  Synchronization and transport helpers for app-state collections.

  This module owns the IQ request/response flow with WhatsApp, including
  collection fetches, mutation sends, external blob downloads, and the
  sequencing required to apply snapshots and patch chains into the local store.
  """

  require Logger

  alias ExWapp.AppState.{CollectionLock, Crypto}
  alias ExWapp.AppState.Engine.{Codec, Dispatch, State}
  alias ExWapp.{Binary, Log}
  alias ExWapp.Proto.SyncAction

  alias ExWapp.Proto.SyncAction.{
    ExternalBlobReference,
    SyncdMutations,
    SyncdPatch
  }

  alias ExWapp.Store
  alias ExWapp.Transport.TLS

  @media_key_hkdf_info "WhatsApp App State Keys"
  @appstate_media_mms_type "md-app-state"
  @default_media_hosts ["mmg.whatsapp.net", "mmg-fallback.whatsapp.net"]
  @media_hmac_length 10
  @media_conn_cache_ttl_ms :timer.minutes(5)
  @media_conn_cache_table :ex_wapp_media_conn_cache
  @max_collection_pages 1_000

  @type hash_state :: %{version: non_neg_integer(), hash: binary()}
  @type patch_info :: Codec.patch_info()

  @doc """
  Synchronizes the affected collection, encodes and sends a mutation patch,
  then applies the acknowledged change locally and schedules a background
  refresh. Operations for the same store collection are serialized.
  """
  @spec send_mutation(GenServer.server(), patch_info(), struct()) ::
          {:ok, hash_state(), map()} | {:error, term()}
  def send_mutation(session, patch_info, store) do
    CollectionLock.with_lock(store, patch_info.type, fn ->
      with :ok <- fetch_collection_unlocked(session, store, patch_info.type) do
        do_send_mutation(session, patch_info, store, true)
      end
    end)
  end

  @doc """
  Fetches a single app-state collection and applies its snapshot and patches.
  """
  @spec fetch_collection(GenServer.server(), struct(), String.t()) :: :ok | {:error, term()}
  def fetch_collection(session, store, collection_name) do
    CollectionLock.with_lock(store, collection_name, fn ->
      fetch_collection_unlocked(session, store, collection_name)
    end)
  end

  @mac_divergence_reasons [
    :mismatching_snapshot_mac,
    :mismatching_patch_mac,
    :mismatching_content_mac,
    :mismatching_index_mac
  ]

  defp fetch_collection_unlocked(session, store, collection_name) do
    Store.batch(store, {:app_state_collection, collection_name}, fn ->
      case do_fetch_collection(session, store, collection_name, true) do
        :ok ->
          :ok

        {:error, :snapshot_not_supported} ->
          do_fetch_collection(session, store, collection_name, false)

        {:error, {:apply_snapshot_failed, _reason}} ->
          do_fetch_collection(session, store, collection_name, false)

        {:error, {:apply_patch_failed, reason}} when reason in @mac_divergence_reasons ->
          # The local hash chain no longer matches the server's, and a normal
          # retry can never repair it: a snapshot is only requested at version
          # 0, so the same failing patch just comes back in front of us on
          # every fetch — and with it every mutation to this collection fails,
          # forever. Dropping the stored version forces a fresh snapshot sync,
          # which is exactly what whatsmeow does for this error class.
          Logger.warning(
            "[APP_STATE] #{collection_name} hash state diverged (#{Log.reason(reason)}); resyncing from snapshot"
          )

          :ok = State.reset_collection_state(store, collection_name)
          do_fetch_collection(session, store, collection_name, true)

        {:error, _reason} = error ->
          error
      end
    end)
  end

  @doc """
  Applies a collection response payload to the local store.
  """
  @spec apply_collection_response(struct(), String.t(), Binary.Node.t()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def apply_collection_response(store, collection_name, response) do
    apply_collection_response(store, collection_name, response, nil)
  end

  @doc """
  Applies a collection response payload and optionally uses a live session when
  external blobs must be fetched while decoding snapshots or patch chains.
  """
  @spec apply_collection_response(struct(), String.t(), Binary.Node.t(), pid() | nil) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def apply_collection_response(store, collection_name, response, session) do
    with {:ok, collection_data} <- extract_collection_data(response, collection_name),
         {:ok, hash_state, mutation_macs} <- State.get_collection_state(store, collection_name),
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
           ) do
      case apply_patches(
             store,
             session,
             collection_name,
             collection_data.patches,
             key_store,
             hash_state,
             mutation_macs
           ) do
        {:ok, hash_state, mutation_macs, patch_count} ->
          State.persist_collection_state(store, collection_name, hash_state, mutation_macs)
          {:ok, snapshot_count + patch_count}

        {:error, {:apply_patch_failed, reason}} = error ->
          maybe_accept_snapshot_only(
            store,
            collection_name,
            collection_data,
            hash_state,
            mutation_macs,
            snapshot_count,
            reason,
            error
          )
      end
    end
  end

  defp do_send_mutation(session, patch_info, store, allow_retry) do
    with {:ok, key_id, key_data} <- Codec.latest_app_state_key(store),
         {:ok, hash_state, mutation_macs} <-
           State.get_collection_state(store, patch_info.type),
         {:ok, encoded_patch, new_hash_state, new_mutation_macs} <-
           Codec.encode_patch(patch_info, key_id, key_data, hash_state, mutation_macs) do
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

      case GenServer.call(session, {:send_iq, iq_node, message_id}, 30_000) do
        {:ok, response} ->
          handle_mutation_response(
            session,
            store,
            patch_info,
            response,
            collection_name,
            new_hash_state,
            new_mutation_macs,
            allow_retry
          )

        {:error, reason} ->
          {:error, {:iq_failed, reason}}
      end
    end
  end

  defp handle_mutation_response(
         session,
         store,
         patch_info,
         response,
         collection_name,
         new_hash_state,
         new_mutation_macs,
         allow_retry
       ) do
    case validate_mutation_response(response, collection_name) do
      :ok ->
        State.persist_collection_state(store, collection_name, new_hash_state, new_mutation_macs)
        Dispatch.apply_outgoing_patch(store, patch_info)
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
  end

  defp refresh_collection_after_mutation(session, store, collection_name) do
    spawn(fn ->
      case fetch_collection(session, store, collection_name) do
        :ok ->
          :ok

        {:error, reason} ->
          Logger.debug(
            "[APP_STATE] Post-mutation refresh failed for #{collection_name}: #{Log.reason(reason)}"
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

  defp do_fetch_collection(session, store, collection_name, want_snapshot) do
    do_fetch_collection_page(session, store, collection_name, want_snapshot, 0)
  end

  defp do_fetch_collection_page(
         _session,
         _store,
         collection_name,
         _want_snapshot,
         page
       )
       when page >= @max_collection_pages do
    {:error, {:app_state_pagination_limit, collection_name, @max_collection_pages}}
  end

  defp do_fetch_collection_page(session, store, collection_name, want_snapshot, page) do
    with {:ok, hash_state, _macs} <- State.get_collection_state(store, collection_name),
         snapshot? <- want_snapshot and hash_state.version == 0,
         {:ok, response} <-
           send_collection_fetch_iq(session, collection_name, hash_state.version, snapshot?),
         {:ok, collection_data} <- extract_collection_data(response, collection_name),
         {:ok, _count} <- apply_collection_response(store, collection_name, response, session) do
      continue_collection_pagination(
        session,
        store,
        collection_name,
        collection_data.has_more_patches,
        hash_state.version,
        page
      )
    end
  end

  defp continue_collection_pagination(
         _session,
         _store,
         _collection_name,
         false,
         _previous_version,
         _page
       ),
       do: :ok

  defp continue_collection_pagination(
         session,
         store,
         collection_name,
         true,
         previous_version,
         page
       ) do
    with {:ok, %{version: version}, _macs} <- State.get_collection_state(store, collection_name),
         :ok <- ensure_pagination_progress(collection_name, previous_version, version) do
      do_fetch_collection_page(session, store, collection_name, false, page + 1)
    end
  end

  defp ensure_pagination_progress(_collection_name, previous_version, version)
       when is_integer(version) and version > previous_version,
       do: :ok

  defp ensure_pagination_progress(collection_name, previous_version, version) do
    {:error, {:app_state_pagination_stalled, collection_name, previous_version, version}}
  end

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
        Enum.flat_map(patch_nodes, &patch_binary_from_node/1)

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

  defp patch_binary_from_node(%Binary.Node{tag: "patch", content: value}) do
    case binary_content(value) do
      nil -> []
      binary -> [binary]
    end
  end

  defp patch_binary_from_node(_node), do: []

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
    result =
      timed_app_state(
        :decode,
        %{collection: collection_name, payload: :snapshot},
        %{payload_bytes: byte_size(snapshot_binary)},
        fn ->
          with {:ok, snapshot} <- decode_snapshot_payload(session, snapshot_binary),
               {:ok, version} <- Codec.normalize_patch_version(snapshot.version),
               {:ok, decoded} <- Codec.decode_snapshot_mutations(snapshot, key_store),
               {:ok, hash, macs} <-
                 Codec.verify_snapshot(snapshot, decoded, version, collection_name, key_store) do
            {:ok, decoded, version, hash, macs}
          end
        end
      )

    case result do
      {:ok, decoded, version, hash, macs} ->
        dispatch_decoded_mutations(store, decoded, collection_name)
        {:ok, %{version: version, hash: hash}, macs, length(decoded)}

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

  defp maybe_accept_snapshot_only(
         store,
         collection_name,
         %{snapshot: snapshot_binary},
         hash_state,
         mutation_macs,
         snapshot_count,
         reason,
         _error
       )
       when is_binary(snapshot_binary) and snapshot_count > 0 and
              reason in [:mismatching_snapshot_mac, :mismatching_patch_mac] do
    Logger.warning(
      "[APP_STATE] Ignoring trailing patch chain for #{collection_name} after valid snapshot: #{Log.reason(reason)}"
    )

    State.persist_collection_state(store, collection_name, hash_state, mutation_macs)
    {:ok, snapshot_count}
  end

  defp maybe_accept_snapshot_only(
         _store,
         _collection_name,
         _collection_data,
         _hash_state,
         _mutation_macs,
         _snapshot_count,
         _reason,
         error
       ) do
    error
  end

  defp dispatch_decoded_mutations(store, decoded_mutations, collection_name) do
    dispatch_decoded_mutation_batches(
      store,
      [decoded_mutations],
      length(decoded_mutations),
      collection_name
    )
  end

  defp dispatch_decoded_mutation_batches(store, decoded_batches, mutation_count, collection_name) do
    timed_app_state(
      :dispatch,
      %{collection: collection_name},
      %{mutation_count: mutation_count},
      fn ->
        Enum.each(decoded_batches, &dispatch_decoded_mutation_batch(store, &1))
      end
    )
  end

  defp dispatch_decoded_mutation_batch(store, decoded_mutations) do
    Enum.each(decoded_mutations, fn mutation ->
      Dispatch.dispatch_mutation(store, mutation.operation, mutation.index, mutation.action)
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
    result =
      Enum.reduce_while(
        patches,
        {:ok, hash_state, mutation_macs, [], 0},
        fn patch_binary, {:ok, state, macs, decoded_batches, decoded_count} ->
          case apply_single_patch(
                 session,
                 collection_name,
                 patch_binary,
                 key_store,
                 state,
                 macs
               ) do
            {:ok, decoded, new_state, new_macs} ->
              {:cont,
               {:ok, new_state, new_macs, [decoded | decoded_batches],
                decoded_count + length(decoded)}}

            {:error, reason} ->
              {:halt, {:error, {:apply_patch_failed, reason}}}
          end
        end
      )

    case result do
      {:ok, new_state, new_macs, decoded_batches, decoded_count} ->
        dispatch_decoded_mutation_batches(
          store,
          Enum.reverse(decoded_batches),
          decoded_count,
          collection_name
        )

        {:ok, new_state, new_macs, decoded_count}

      {:error, _reason} = error ->
        error
    end
  end

  defp apply_single_patch(session, collection_name, patch_binary, key_store, state, macs) do
    timed_app_state(
      :decode,
      %{collection: collection_name, payload: :patch},
      %{payload_bytes: byte_size(patch_binary)},
      fn ->
        with {:ok, patch} <- SyncAction.decode_syncd_patch(patch_binary),
             {:ok, patch} <- maybe_resolve_external_patch_mutations(session, patch) do
          Codec.decode_patch(patch, collection_name, state, macs, key_store, true)
        end
      end
    )
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
             {:ok, raw_snapshot} <- download_external_blob(session, ref) do
          SyncAction.decode_syncd_snapshot(raw_snapshot)
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
    timed_app_state(:external_blob, %{payload: :app_state}, %{}, fn ->
      with {:ok, direct_path} <- validate_external_direct_path(ref.direct_path),
           {:ok, encrypted_payload} <-
             download_external_blob_payload(session, direct_path, ref.file_enc_sha256) do
        decrypt_external_blob_payload(ref.media_key, encrypted_payload)
      end
    end)
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
            "[APP_STATE] External blob download failed from #{host}: #{Log.reason(reason)}"
          )

          {:cont, {:error, reason}}
      end
    end)
  end

  defp media_download_hosts(session) do
    queried_hosts =
      case cached_media_conn_hosts(session) do
        {:ok, hosts} when is_list(hosts) ->
          hosts

        :miss ->
          case query_media_conn_hosts(session) do
            {:ok, hosts} when is_list(hosts) ->
              cache_media_conn_hosts(session, hosts)
              hosts

            _ ->
              []
          end
      end

    (queried_hosts ++ @default_media_hosts)
    |> Enum.filter(&(is_binary(&1) and String.trim(&1) != ""))
    |> Enum.uniq()
  end

  defp cached_media_conn_hosts(session) when is_pid(session) do
    table = ensure_media_conn_cache_table()

    case :ets.lookup(table, session) do
      [{^session, %{hosts: hosts, expires_at: expires_at}}]
      when is_list(hosts) and is_integer(expires_at) ->
        if Process.alive?(session) and System.monotonic_time(:millisecond) < expires_at do
          {:ok, hosts}
        else
          :ets.delete(table, session)
          :miss
        end

      _ ->
        :miss
    end
  end

  defp cached_media_conn_hosts(_session), do: :miss

  defp cache_media_conn_hosts(session, hosts) when is_pid(session) and is_list(hosts) do
    table = ensure_media_conn_cache_table()

    :ets.insert(table, {
      session,
      %{
        hosts: hosts,
        expires_at: System.monotonic_time(:millisecond) + @media_conn_cache_ttl_ms
      }
    })

    :ok
  end

  defp cache_media_conn_hosts(_session, _hosts), do: :ok

  defp ensure_media_conn_cache_table do
    case :ets.whereis(@media_conn_cache_table) do
      :undefined ->
        try do
          :ets.new(@media_conn_cache_table, [:named_table, :public, :set, read_concurrency: true])
          @media_conn_cache_table
        rescue
          ArgumentError -> @media_conn_cache_table
        end

      _tid ->
        @media_conn_cache_table
    end
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
          |> Enum.flat_map(&host_from_media_conn_child/1)
          |> Enum.uniq()

        if hosts == [], do: {:error, :no_media_hosts}, else: {:ok, hosts}

      _ ->
        {:error, :media_conn_not_found}
    end
  end

  defp parse_media_conn_hosts(_), do: {:error, :invalid_media_conn_response}

  defp host_from_media_conn_child(%Binary.Node{tag: "host", attrs: attrs}) do
    case Map.get(attrs, "hostname") do
      host when is_binary(host) and host != "" -> [host]
      _ -> []
    end
  end

  defp host_from_media_conn_child(_child), do: []

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
    http_opts = TLS.httpc_options(url, timeout: 15_000, connect_timeout: 10_000)

    case :httpc.request(:get, request, http_opts, body_format: :binary) do
      {:ok, {{_http_version, 200, _reason}, _resp_headers, body}} when is_binary(body) ->
        {:ok, body}

      {:ok, {{_http_version, status, _reason}, _resp_headers, body}} ->
        {:error, {:http_status, status, byte_size(body)}}

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
      <<ciphertext::binary-size(^ciphertext_len), mac::binary-size(@media_hmac_length)>> = payload

      with {:ok, iv, cipher_key, mac_key} <- derive_external_blob_keys(media_key),
           :ok <- verify_external_blob_mac(iv, ciphertext, mac_key, mac) do
        Crypto.decrypt_cbc(ciphertext, cipher_key, iv)
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

  defp timed_app_state(stage, metadata, measurements, fun)
       when is_atom(stage) and is_map(metadata) and is_map(measurements) and is_function(fun, 0) do
    started_at = System.monotonic_time()
    result = fun.()
    duration = System.monotonic_time() - started_at

    measurements =
      measurements
      |> Map.put(:duration, duration)
      |> Map.put(:duration_ms, System.convert_time_unit(duration, :native, :millisecond))
      |> Map.merge(stage_result_measurements(result))

    metadata = Map.put(metadata, :result, stage_result(result))
    ExWapp.Telemetry.execute([:ex_wapp, :app_state, stage], measurements, metadata)

    Logger.debug(
      "[APP_STATE] stage=#{stage} collection=#{Map.get(metadata, :collection, "n/a")} result=#{metadata.result} duration_ms=#{measurements.duration_ms}"
    )

    result
  end

  defp stage_result_measurements({:ok, binary}) when is_binary(binary),
    do: %{result_bytes: byte_size(binary)}

  defp stage_result_measurements({:ok, decoded, _state, _macs}) when is_list(decoded),
    do: %{mutation_count: length(decoded)}

  defp stage_result_measurements({:ok, decoded, _version, _hash, _macs}) when is_list(decoded),
    do: %{mutation_count: length(decoded)}

  defp stage_result_measurements(_result), do: %{}

  defp stage_result({:ok, _value}), do: :ok
  defp stage_result({:ok, _value, _third, _fourth}), do: :ok
  defp stage_result({:ok, _value, _third, _fourth, _fifth}), do: :ok
  defp stage_result({:error, _reason}), do: :error
  defp stage_result(:ok), do: :ok
  defp stage_result(_result), do: :other

  defp generate_request_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64() |> String.slice(0, 16)
  end
end
