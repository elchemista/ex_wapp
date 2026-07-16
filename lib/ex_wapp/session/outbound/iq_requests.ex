defmodule ExWapp.Session.Outbound.IQRequests do
  @moduledoc """
  Effect boundary for outbound USync, prekey, and group-info IQ requests.

  The caller supplies the transport send function. Receives and timeouts run in
  the caller process, preserving the existing session-worker mailbox contract.
  """

  require Logger

  alias ExWapp.{Binary, Config, Log, Store}
  alias ExWapp.Session.{Account, DeviceCache, IQ}
  alias ExWapp.Session.Outbound.{Group, Prekeys}
  alias ExWapp.Signal.SessionStore

  @type request_state :: %{
          required(:store) => term(),
          optional(:runtime_cfg) => map() | nil,
          optional(atom()) => term()
        }

  @type send_node_fun :: (Binary.Node.t() -> :ok | {:error, term()})

  @doc """
  Fetches prekeys for several device JIDs in one IQ request.
  """
  @spec fetch_prekeys_batch(
          request_state(),
          nonempty_list(String.t()),
          SessionStore.t(),
          send_node_fun()
        ) :: Prekeys.fetch_result()
  def fetch_prekeys_batch(state, device_jids, signal_sessions, send_node_fun)
      when is_list(device_jids) and device_jids != [] and is_function(send_node_fun, 1) do
    message_id = request_id()
    request_node = IQ.build_prekey_request(device_jids, message_id)

    Logger.debug("[PREKEY] Sending batch prekey request for #{length(device_jids)} devices")

    case send_node_fun.(request_node) do
      :ok ->
        receive_prekey_response(
          state.store,
          message_id,
          nil,
          signal_sessions,
          prekey_timeout_ms(state),
          "batch"
        )

      error ->
        {:error, {:send_failed, error}}
    end
  end

  @doc """
  Fetches a prekey for one device JID.
  """
  @spec fetch_prekey(
          request_state(),
          String.t(),
          SessionStore.t(),
          send_node_fun()
        ) :: Prekeys.fetch_result()
  def fetch_prekey(state, jid, signal_sessions, send_node_fun)
      when is_binary(jid) and is_function(send_node_fun, 1) do
    message_id = request_id()
    request_node = IQ.build_prekey_request(jid, message_id)

    Logger.debug("[PREKEY] Sending prekey request for #{Log.reference(jid)}")

    case send_node_fun.(request_node) do
      :ok ->
        receive_prekey_response(
          state.store,
          message_id,
          jid,
          signal_sessions,
          prekey_timeout_ms(state),
          "single"
        )

      error ->
        {:error, {:send_failed, error}}
    end
  end

  @doc """
  Queries the linked-device map and persists the successful USync result.
  """
  @spec query_devices(request_state(), [String.t()], send_node_fun()) ::
          {:ok, map()} | {:error, term()}
  def query_devices(state, jids, send_node_fun)
      when is_list(jids) and is_function(send_node_fun, 1) do
    message_id = request_id()
    query_node = IQ.build_usync_device_query(jids, message_id)

    Logger.debug("[USYNC] Querying device list #{Log.references(jids)}")

    case send_node_fun.(query_node) do
      :ok ->
        receive do
          {:prekey_response, ^message_id, response_node} ->
            handle_device_response(state.store, response_node)

          {:prekey_error, ^message_id, error} ->
            Logger.warning("[USYNC] Device list query error: #{Log.reason(error)}")
            {:error, {:usync_query_error, error}}
        after
          usync_timeout_ms(state) ->
            Logger.warning("[USYNC] Device list query timed out")
            {:error, :usync_timeout}
        end

      error ->
        {:error, {:usync_send_failed, error}}
    end
  end

  @doc """
  Queries current group participants and addressing mode.
  """
  @spec query_group_info(request_state(), String.t(), send_node_fun()) ::
          {:ok, Group.group_info()} | {:error, term()}
  def query_group_info(state, group_jid, send_node_fun)
      when is_binary(group_jid) and is_function(send_node_fun, 1) do
    message_id = request_id()
    query_node = Group.build_info_query(group_jid, message_id)

    Logger.debug("[GROUP] Querying group info for #{Log.reference(group_jid)}")

    case send_node_fun.(query_node) do
      :ok ->
        receive do
          {:prekey_response, ^message_id, response_node} ->
            Group.parse_info_response(response_node, group_jid)

          {:prekey_error, ^message_id, error} ->
            {:error, {:group_info_query_error, error}}
        after
          group_info_timeout_ms(state) ->
            {:error, :group_info_timeout}
        end

      error ->
        {:error, {:group_info_send_failed, error}}
    end
  end

  @spec receive_prekey_response(
          Store.t(),
          String.t(),
          String.t() | nil,
          SessionStore.t(),
          non_neg_integer(),
          String.t()
        ) :: Prekeys.fetch_result()
  defp receive_prekey_response(
         store,
         message_id,
         requested_jid,
         signal_sessions,
         timeout_ms,
         context
       ) do
    receive do
      {:prekey_response, ^message_id, response_node} ->
        Logger.debug("[PREKEY] Got #{context} prekey response")
        process_prekey_response(store, response_node, requested_jid, signal_sessions)

      {:prekey_error, ^message_id, error} ->
        {:error, {:prekey_fetch_error, error}}
    after
      timeout_ms ->
        {:error, :prekey_timeout}
    end
  end

  @spec process_prekey_response(
          Store.t(),
          Binary.Node.t(),
          String.t() | nil,
          SessionStore.t()
        ) :: Prekeys.fetch_result()
  defp process_prekey_response(store, response_node, requested_jid, signal_sessions) do
    case IQ.parse_prekey_response(response_node) do
      {:ok, bundles} ->
        Logger.debug("[PREKEY] Parsed #{length(bundles)} prekey bundles, creating sessions")
        create_prekey_sessions(store, signal_sessions, requested_jid, bundles)

      {:error, reason} ->
        {:error, {:prekey_parse_failed, reason}}
    end
  end

  @spec create_prekey_sessions(Store.t(), SessionStore.t(), String.t() | nil, [map()]) ::
          Prekeys.fetch_result()
  defp create_prekey_sessions(store, signal_sessions, requested_jid, bundles) do
    data = Store.load!(store)
    signal_data = Map.get(data, :signal, %{})
    local_identity = Map.get(signal_data, :identity_key)
    local_reg_id = Map.get(signal_data, :registration_id, 0)

    if local_identity do
      Prekeys.create_sessions_for_bundles(
        signal_sessions,
        requested_jid,
        bundles,
        local_identity,
        local_reg_id,
        Account.load_lid_mapping(store)
      )
    else
      {:error, :no_local_identity}
    end
  end

  @spec handle_device_response(Store.t(), Binary.Node.t()) ::
          {:ok, map()} | {:error, term()}
  defp handle_device_response(store, response_node) do
    Logger.debug("[USYNC] Got device list response")

    case IQ.parse_usync_device_response(response_node) do
      {:ok, device_map} = result ->
        DeviceCache.persist_usync_map(store, device_map)
        result

      error ->
        error
    end
  end

  @spec request_id() :: String.t()
  defp request_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64() |> String.slice(0, 16)
  end

  @spec prekey_timeout_ms(request_state()) :: non_neg_integer()
  defp prekey_timeout_ms(state),
    do: Config.get(Map.get(state, :runtime_cfg) || %{}, [:iq, :prekey_timeout_ms], 30_000)

  @spec usync_timeout_ms(request_state()) :: non_neg_integer()
  defp usync_timeout_ms(state),
    do: Config.get(Map.get(state, :runtime_cfg) || %{}, [:iq, :usync_timeout_ms], 15_000)

  @spec group_info_timeout_ms(request_state()) :: non_neg_integer()
  defp group_info_timeout_ms(state),
    do: Config.get(Map.get(state, :runtime_cfg) || %{}, [:iq, :group_info_timeout_ms], 15_000)
end
