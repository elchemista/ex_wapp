defmodule ExWapp.Session.Worker.PostAuth do
  @moduledoc """
  Post-authentication helpers triggered after the `success` node is received.

  Handles LID persistence, PN↔LID mapping, prekey count queries, and
  prekey upload logic.
  """

  require Logger

  alias ExWapp.{Binary, Config, MapPath, Store}

  @min_prekey_threshold 5

  @doc """
  Persists the LID value from the success node and creates own PN↔LID mapping.
  """
  @spec persist_lid_and_mapping(map(), binary() | nil) :: map()
  def persist_lid_and_mapping(state, nil), do: state

  def persist_lid_and_mapping(state, lid) when is_binary(lid) do
    Logger.info("[SESSION] LID from success: #{inspect(lid)}")

    data = Store.load!(state.store)

    # Persist LID in client_info
    client_info = Map.get(data, :client_info, %{})
    client_info = Map.put(client_info, :lid, lid)

    # Create own PN<->LID mapping (Baileys: storeLIDPNMappings)
    own_pn =
      MapPath.first(data, [
        ["pairing", "device", "jid"],
        ["client_info", "jid"]
      ])

    lid_mapping = Map.get(data, :lid_mapping, %{})

    lid_mapping =
      if own_pn do
        pn_normalized = normalize_jid_string(to_string(own_pn))
        lid_normalized = normalize_jid_string(to_string(lid))

        Logger.info(
          "[SESSION] Storing own PN<->LID mapping: #{pn_normalized} <-> #{lid_normalized}"
        )

        lid_mapping
        |> Map.put({:pn_to_lid, pn_normalized}, lid_normalized)
        |> Map.put({:lid_to_pn, lid_normalized}, pn_normalized)
      else
        lid_mapping
      end

    data =
      data
      |> Map.put(:client_info, client_info)
      |> Map.put(:lid_mapping, lid_mapping)

    Store.persist(state.store, data)
    state
  end

  def persist_lid_and_mapping(state, _), do: state

  @doc """
  Handles the prekey count response from the server and decides whether to upload.

  Returns `{state, actions}`.
  """
  @spec handle_prekey_count_response(Binary.Node.t(), map()) :: {map(), list()}
  def handle_prekey_count_response(%Binary.Node{content: content}, state) do
    state = %{state | prekey_count_query_id: nil}

    server_count = ExWapp.Prekeys.parse_count_response(content)
    Logger.info("[SESSION] Server prekey count: #{server_count}")

    data = Store.load!(state.store)
    signal = Map.get(data, :signal, %{})
    local_count = signal |> Map.get(:prekeys, %{}) |> map_size()

    # Baileys logic: if server count == 0 -> INITIAL (812), low -> refill (50)
    # For fresh devices, server_count == 0 always needs full initial upload
    cond do
      server_count == 0 ->
        Logger.info(
          "[SESSION] No prekeys on server, uploading initial batch (local=#{local_count})"
        )

        do_prekey_upload(state, initial: true)

      server_count <= min_prekey_threshold(state) ->
        Logger.info("[SESSION] Server prekeys low (#{server_count}), uploading refill batch")
        do_prekey_upload(state, initial: false)

      true ->
        Logger.info(
          "[SESSION] Prekey count OK (server=#{server_count}, local=#{local_count}), skipping upload"
        )

        {state, []}
    end
  end

  # -- Internal helpers -------------------------------------------------------

  defp do_prekey_upload(state, opts) do
    case ExWapp.Prekeys.build_prekey_upload(
           state.store,
           Keyword.put(opts, :runtime_cfg, state.runtime_cfg || %{})
         ) do
      {:ok, prekey_node, prekeys} ->
        persist_uploaded_prekeys(state.store, prekeys)
        initial = Keyword.get(opts, :initial, false)
        Logger.info("[SESSION] Uploading prekeys (initial=#{initial}, count=#{length(prekeys)})")
        {state, [{:send_node, prekey_node}]}

      {:error, reason} ->
        Logger.warning("[SESSION] Cannot upload prekeys: #{inspect(reason)}")
        {state, []}
    end
  end

  defp normalize_jid_string(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
  end

  defp persist_uploaded_prekeys(store, prekeys) when is_list(prekeys) do
    data = Store.load!(store)
    signal = Map.get(data, :signal, %{})
    existing_prekeys = Map.get(signal, :prekeys, %{})

    merged_prekeys =
      Enum.reduce(prekeys, existing_prekeys, fn
        %{key_id: id, public: pub, private: priv}, acc ->
          Map.put(acc, id, %{id: id, public: pub, private: priv})

        _, acc ->
          acc
      end)

    next_prekey_id =
      prekeys
      |> Enum.map(&Map.get(&1, :key_id))
      |> Enum.filter(&is_integer/1)
      |> case do
        [] -> Map.get(signal, :next_prekey_id, 1)
        ids -> Enum.max(ids) + 1
      end

    updated_signal =
      signal
      |> Map.put(:prekeys, merged_prekeys)
      |> Map.put(:next_prekey_id, next_prekey_id)

    Store.persist(store, Map.put(data, :signal, updated_signal))
    :ok
  rescue
    error ->
      Logger.warning("[SESSION] Failed to persist uploaded prekeys: #{inspect(error)}")
      :ok
  end

  defp min_prekey_threshold(state) do
    Config.get(state.runtime_cfg || %{}, [:prekeys, :min_threshold], @min_prekey_threshold)
  end
end
