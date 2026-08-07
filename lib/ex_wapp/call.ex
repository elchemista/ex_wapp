defmodule ExWapp.Call do
  @moduledoc """
  Call log storage and queries.

  One `%ExWapp.Call{}` describes one call: who started it, where it belongs,
  how it ended, and how long it lasted. Records are built from three sources
  and merged by call ID, so a call first seen live as `<call>` stanzas can
  later be enriched by the authoritative `CallLogRecord` the phone syncs:

  - `:live` — inbound `<call>` signalling stanzas (offer/accept/terminate/...)
  - `:app_state` — `call_log` app-state mutations carrying `CallLogRecord`
  - `:history_sync` — `HistorySync.callLogRecords` entries

  ## Storage

  Records are persisted via the session's store adapter under the `:call_log`
  key, bounded to `max_records` entries (oldest dropped first) so an active
  account cannot grow the store without limit. The bound is configurable via
  `config.calls.max_records`.

  ## Usage

      # Most recent calls, newest first (limit defaults to 50)
      calls = ExWapp.Call.list(session, limit: 20)

      # Only missed incoming calls since a unix timestamp
      missed = ExWapp.Call.list(session, status: :missed, since: 1_754_000_000)

      # Deferred chronological traversal over the bounded retained log
      ExWapp.Call.stream(session) |> Enum.each(&IO.inspect/1)

      # Timestamps are unix seconds
      DateTime.from_unix!(call.start_time)
  """

  alias ExWapp.{Config, JID, Store}
  alias WAWebProtobufSyncAction.CallLogRecord

  @type target :: pid() | struct()

  @typedoc """
  Lifecycle status of a call.

  `:ringing` and `:ongoing` are transient live states; everything else is a
  final outcome. `:missed` means an incoming call ended unanswered,
  `:cancelled` an outgoing call ended before the peer accepted, and
  `:accepted_elsewhere` that another device of this account took the call.
  """
  @type status ::
          :ringing
          | :ongoing
          | :connected
          | :missed
          | :rejected
          | :cancelled
          | :accepted_elsewhere
          | :failed
          | :unavailable
          | :upcoming
          | :abandoned
          | :invalid
          | :silenced
          | :unknown

  @type participant :: %{jid: String.t() | nil, status: status()}

  @type t :: %__MODULE__{
          id: String.t() | nil,
          chat_jid: String.t() | nil,
          creator_jid: String.t() | nil,
          group_jid: String.t() | nil,
          status: status() | nil,
          is_incoming: boolean() | nil,
          is_video: boolean() | nil,
          is_group: boolean(),
          start_time: non_neg_integer() | nil,
          accepted_at: non_neg_integer() | nil,
          ended_at: non_neg_integer() | nil,
          duration: non_neg_integer() | nil,
          end_reason: String.t() | nil,
          call_type: :regular | :scheduled_call | :voice_chat | nil,
          source: :live | :app_state | :history_sync | nil,
          participants: [participant()]
        }

  defstruct [
    :id,
    :chat_jid,
    :creator_jid,
    :group_jid,
    :status,
    :is_incoming,
    :is_video,
    :start_time,
    :accepted_at,
    :ended_at,
    :duration,
    :end_reason,
    :call_type,
    :source,
    is_group: false,
    participants: []
  ]

  @store_key :call_log
  @default_max_records 500
  @transient_statuses [:ringing, :ongoing]
  @source_priorities %{nil => 0, live: 1, app_state: 2, history_sync: 2}
  @transient_status_priorities %{ringing: 1, ongoing: 2}

  @call_result_statuses %{
    CONNECTED: :connected,
    REJECTED: :rejected,
    CANCELLED: :cancelled,
    ACCEPTEDELSEWHERE: :accepted_elsewhere,
    MISSED: :missed,
    INVALID: :invalid,
    UNAVAILABLE: :unavailable,
    UPCOMING: :upcoming,
    FAILED: :failed,
    ABANDONED: :abandoned,
    ONGOING: :ongoing
  }

  @call_types %{REGULAR: :regular, SCHEDULED_CALL: :scheduled_call, VOICE_CHAT: :voice_chat}

  @doc """
  Default bound on stored call records, used when no configuration overrides
  `config.calls.max_records`.
  """
  @spec default_max_records() :: pos_integer()
  def default_max_records, do: @default_max_records

  @doc false
  @spec retention_options(map()) :: keyword()
  def retention_options(runtime_cfg) do
    case Config.get(runtime_cfg, [:calls, :max_records]) do
      max when is_integer(max) and max > 0 -> [max_records: max]
      _unset -> []
    end
  end

  @doc """
  Lists stored calls, newest first by default.

  ## Options

  - `:limit` — max records returned, `:all` for everything retained (default `50`)
  - `:offset` — records skipped before taking `:limit` (default `0`)
  - `:order` — `:newest_first` (default) or `:oldest_first`
  - `:status` — a `t:status/0` atom or list of them
  - `:jid` — only calls belonging to this chat/group JID
  - `:since` / `:until` — unix-second bounds on `start_time`
  """
  @spec list(target(), keyword()) :: [t()]
  def list(target, opts \\ []) do
    case resolve_store(target) do
      nil ->
        []

      store ->
        store
        |> stored_calls()
        |> filter_calls(opts)
        |> sort_calls(Keyword.get(opts, :order, :newest_first))
        |> Enum.drop(non_neg_option(opts, :offset, 0))
        |> take_limit(Keyword.get(opts, :limit, 50))
    end
  end

  @doc """
  Builds a deferred stream over stored calls.

  Defaults to oldest first with no limit so a wrapper can export the log in
  chronological order. The retained call-log snapshot is loaded and sorted on
  first enumeration, not when the stream is created; it is bounded by
  `config.calls.max_records`. Accepts the same options as `list/2`.
  """
  @spec stream(target(), keyword()) :: Enumerable.t()
  def stream(target, opts \\ []) do
    opts = opts |> Keyword.put_new(:order, :oldest_first) |> Keyword.put_new(:limit, :all)

    Stream.resource(
      fn -> list(target, opts) end,
      fn
        [] -> {:halt, []}
        [call | rest] -> {[call], rest}
      end,
      fn _calls -> :ok end
    )
  end

  @doc """
  Gets one stored call by call ID.
  """
  @spec get(target(), String.t()) :: {:ok, t()} | {:error, :not_found}
  def get(target, call_id) when is_binary(call_id) do
    store = resolve_store(target)

    with %{} = store <- store,
         %__MODULE__{} = call <- store |> raw_calls() |> Map.get(call_id) |> coerce_call() do
      {:ok, call}
    else
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Counts stored call records.
  """
  @spec count(target()) :: non_neg_integer()
  def count(target) do
    case resolve_store(target) do
      nil -> 0
      store -> store |> raw_calls() |> map_size()
    end
  end

  @doc """
  Deletes every stored call record.
  """
  @spec clear(target()) :: :ok | {:error, term()}
  def clear(target) do
    case resolve_store(target) do
      nil -> :ok
      store -> Store.put(store, @store_key, %{})
    end
  end

  @doc """
  Inserts or merges one call record by ID and prunes the log to the bound.

  Field-level merge: incoming non-nil fields from an equally or more
  authoritative source win. App-state and history-sync records are
  authoritative over live signalling; a later live stanza may fill a missing
  field but cannot replace a synchronized value or outcome. Transient status
  progression is monotonic (`:ringing` then `:ongoing`) and never overwrites a
  final outcome. When both `accepted_at` and `ended_at` are known and
  `duration` is not, the duration is derived from their difference.

  ## Options

  - `:max_records` — retention bound (default `#{@default_max_records}`)
  """
  @spec upsert(target(), t(), keyword()) :: {:ok, t()} | {:error, term()}
  def upsert(target, call, opts \\ [])

  def upsert(target, %__MODULE__{id: id} = call, opts) when is_binary(id) and id != "" do
    case resolve_store(target) do
      nil -> {:ok, finalize_call(call)}
      store -> upsert_in_store(store, call, opts)
    end
  end

  def upsert(_target, _call, _opts), do: {:error, :invalid_call}

  @doc """
  Applies one `CallLogRecord` coming from app-state or history sync.

  Returns `:ok` when the record was stored, `:ignored` when it carries no
  usable call ID.
  """
  @spec merge_from_sync(target(), CallLogRecord.t() | nil, keyword()) :: :ok | :ignored
  def merge_from_sync(target, record, opts \\ []) do
    case from_call_log_record(record, opts) do
      %__MODULE__{} = call ->
        case upsert(target, call, opts) do
          {:ok, _merged} -> :ok
          {:error, _reason} -> :ignored
        end

      nil ->
        :ignored
    end
  end

  @doc """
  Deletes stored 1:1 call records for one peer.

  Mirrors the app-state `DeleteIndividualCallLogAction`: `is_incoming` limits
  the deletion to one direction, `nil` removes both directions.
  """
  @spec delete_by_peer(target(), String.t() | JID.t(), boolean() | nil) :: :ok | {:error, term()}
  def delete_by_peer(target, peer_jid, is_incoming \\ nil) do
    peer = normalize_jid(peer_jid)

    case resolve_store(target) do
      nil ->
        :ok

      _store when peer == "" ->
        :ok

      store ->
        Store.update(store, @store_key, %{}, &reject_peer_calls(&1, peer, is_incoming))
    end
  end

  defp reject_peer_calls(calls, peer, is_incoming) do
    calls
    |> coerce_calls()
    |> Enum.reject(fn {_id, call} -> peer_match?(call, peer, is_incoming) end)
    |> Map.new()
  end

  @doc """
  Converts a `CallLogRecord` protobuf into a call struct.

  Returns `nil` when the record has no call ID. `:source` defaults to
  `:app_state`; the history-sync ingester passes `source: :history_sync`.
  """
  @spec from_call_log_record(CallLogRecord.t() | nil, keyword()) :: t() | nil
  def from_call_log_record(record, opts \\ [])

  def from_call_log_record(%CallLogRecord{} = record, opts) do
    case non_empty_text(record.callID) do
      nil -> nil
      id -> build_from_call_log_record(id, record, opts)
    end
  end

  def from_call_log_record(_record, _opts), do: nil

  # -- record construction ----------------------------------------------------

  defp build_from_call_log_record(id, record, opts) do
    creator = normalize_optional_jid(record.callCreatorJID)
    group_jid = normalize_optional_jid(record.groupJID)
    participants = Enum.map(record.participants, &participant_from_record/1)

    finalize_call(%__MODULE__{
      id: id,
      chat_jid: group_jid || record_peer_jid(record, creator, participants),
      creator_jid: creator,
      group_jid: group_jid,
      status: status_from_call_result(record.callResult),
      is_incoming: boolean_or_nil(record.isIncoming),
      is_video: boolean_or_nil(record.isVideo),
      is_group: group_jid != nil,
      start_time: positive_or_nil(record.startTime),
      duration: non_neg_or_nil(record.duration),
      call_type: Map.get(@call_types, record.callType),
      source: Keyword.get(opts, :source, :app_state),
      participants: participants
    })
  end

  defp record_peer_jid(record, creator, participants) do
    participant_jid =
      Enum.find_value(participants, fn
        %{jid: jid} when is_binary(jid) and jid != creator -> jid
        _participant -> nil
      end)

    if record.isIncoming == false do
      participant_jid || creator
    else
      creator || participant_jid
    end
  end

  defp participant_from_record(%{userJID: jid, callResult: result}) do
    %{jid: normalize_optional_jid(jid), status: status_from_call_result(result)}
  end

  defp participant_from_record(_participant), do: %{jid: nil, status: :unknown}

  defp status_from_call_result(result), do: Map.get(@call_result_statuses, result, :unknown)

  # -- merge ------------------------------------------------------------------

  defp upsert_in_store(store, call, opts) do
    max_records = max_records_option(opts)

    result =
      Store.get_and_update(store, @store_key, %{}, fn calls ->
        calls = coerce_calls(calls)
        merged = merge_call(Map.get(calls, call.id), call)
        {merged, prune(Map.put(calls, call.id, merged), max_records)}
      end)

    case result do
      %__MODULE__{} = merged -> {:ok, merged}
      {:error, reason} -> {:error, reason}
      _other -> {:ok, finalize_call(call)}
    end
  end

  defp merge_call(nil, %__MODULE__{} = incoming), do: finalize_call(incoming)

  defp merge_call(%__MODULE__{} = existing, %__MODULE__{} = incoming) do
    incoming_can_override? =
      source_priority(incoming.source) >= source_priority(existing.source)

    incoming
    |> Map.from_struct()
    |> Map.drop([:source, :status])
    |> Enum.reduce(existing, fn {field, value}, acc ->
      if merge_field?(field, value, Map.get(acc, field), incoming_can_override?) do
        Map.put(acc, field, value)
      else
        acc
      end
    end)
    |> merge_status(existing.status, incoming.status, incoming_can_override?)
    |> merge_source(existing.source, incoming.source)
    |> finalize_call()
  end

  defp merge_field?(field, value, existing_value, incoming_can_override?) do
    mergeable_value?(field, value) and
      (incoming_can_override? or missing_value?(field, existing_value))
  end

  defp mergeable_value?(_field, nil), do: false
  defp mergeable_value?(:participants, []), do: false
  defp mergeable_value?(:is_group, value), do: value == true
  defp mergeable_value?(_field, _value), do: true

  defp missing_value?(_field, nil), do: true
  defp missing_value?(:participants, []), do: true
  defp missing_value?(:is_group, false), do: true
  defp missing_value?(_field, _value), do: false

  defp merge_status(call, old_status, new_status, incoming_can_override?) do
    %{call | status: merged_status(old_status, new_status, incoming_can_override?)}
  end

  defp merged_status(old_status, nil, _incoming_can_override?), do: old_status

  defp merged_status(old_status, _new_status, false) when old_status != nil,
    do: old_status

  defp merged_status(old_status, new_status, _incoming_can_override?) do
    if status_regression?(old_status, new_status), do: old_status, else: new_status
  end

  defp status_regression?(old_status, new_status) do
    (final_status?(old_status) and new_status in @transient_statuses) or
      transient_status_regression?(old_status, new_status)
  end

  defp transient_status_regression?(old_status, new_status)
       when old_status in @transient_statuses and new_status in @transient_statuses do
    transient_status_priority(new_status) < transient_status_priority(old_status)
  end

  defp transient_status_regression?(_old_status, _new_status), do: false

  defp merge_source(call, old_source, new_source) do
    if source_priority(new_source) >= source_priority(old_source) and new_source != nil do
      %{call | source: new_source}
    else
      %{call | source: old_source}
    end
  end

  defp source_priority(source), do: Map.get(@source_priorities, source, 0)

  defp transient_status_priority(status),
    do: Map.get(@transient_status_priorities, status, 0)

  defp final_status?(status), do: status != nil and status not in @transient_statuses

  defp finalize_call(%__MODULE__{} = call) do
    call
    |> derive_duration()
    |> derive_is_group()
  end

  defp derive_duration(%__MODULE__{duration: nil, accepted_at: accepted, ended_at: ended} = call)
       when is_integer(accepted) and is_integer(ended) and ended >= accepted do
    %{call | duration: ended - accepted}
  end

  defp derive_duration(call), do: call

  defp derive_is_group(%__MODULE__{group_jid: group_jid} = call) when is_binary(group_jid),
    do: %{call | is_group: true}

  defp derive_is_group(%__MODULE__{chat_jid: chat_jid} = call) when is_binary(chat_jid),
    do: %{call | is_group: call.is_group or JID.group?(chat_jid)}

  defp derive_is_group(call), do: call

  defp prune(calls, max_records) when map_size(calls) > max_records do
    calls
    |> Enum.sort_by(fn {_id, call} -> sort_key(call) end, :desc)
    |> Enum.take(max_records)
    |> Map.new()
  end

  defp prune(calls, _max_records), do: calls

  defp max_records_option(opts) do
    case Keyword.get(opts, :max_records, @default_max_records) do
      max when is_integer(max) and max > 0 -> max
      _invalid -> @default_max_records
    end
  end

  # -- queries ----------------------------------------------------------------

  defp stored_calls(store) do
    store
    |> raw_calls()
    |> Map.values()
    |> Enum.map(&coerce_call/1)
    |> Enum.reject(&is_nil/1)
  end

  defp raw_calls(store) do
    case Store.get(store, @store_key, %{}) do
      calls when is_map(calls) -> calls
      _other -> %{}
    end
  end

  defp filter_calls(calls, opts) do
    calls
    |> filter_by_status(Keyword.get(opts, :status))
    |> filter_by_jid(Keyword.get(opts, :jid))
    |> filter_by_range(Keyword.get(opts, :since), Keyword.get(opts, :until))
  end

  defp filter_by_status(calls, nil), do: calls

  defp filter_by_status(calls, statuses) when is_list(statuses),
    do: Enum.filter(calls, &(&1.status in statuses))

  defp filter_by_status(calls, status), do: filter_by_status(calls, [status])

  defp filter_by_jid(calls, nil), do: calls

  defp filter_by_jid(calls, jid) do
    case normalize_jid(jid) do
      "" -> calls
      normalized -> Enum.filter(calls, &(&1.chat_jid == normalized))
    end
  end

  defp filter_by_range(calls, nil, nil), do: calls

  defp filter_by_range(calls, since, until) do
    Enum.filter(calls, fn call ->
      start_time = call.start_time || 0

      (not is_integer(since) or start_time >= since) and
        (not is_integer(until) or start_time <= until)
    end)
  end

  defp sort_calls(calls, :oldest_first), do: Enum.sort_by(calls, &sort_key/1, :asc)
  defp sort_calls(calls, _order), do: Enum.sort_by(calls, &sort_key/1, :desc)

  defp sort_key(%__MODULE__{} = call), do: {call.start_time || 0, call.id || ""}

  defp take_limit(calls, :all), do: calls
  defp take_limit(calls, limit) when is_integer(limit) and limit >= 0, do: Enum.take(calls, limit)
  defp take_limit(calls, _invalid), do: calls

  defp non_neg_option(opts, key, default) do
    case Keyword.get(opts, key, default) do
      value when is_integer(value) and value >= 0 -> value
      _invalid -> default
    end
  end

  defp peer_match?(%__MODULE__{is_group: true}, _peer, _is_incoming), do: false

  defp peer_match?(%__MODULE__{} = call, peer, is_incoming) do
    call.chat_jid == peer and (is_nil(is_incoming) or call.is_incoming == is_incoming)
  end

  # -- coercion ---------------------------------------------------------------

  defp coerce_calls(calls) when is_map(calls) do
    calls
    |> Enum.reduce(%{}, fn {id, raw}, acc ->
      case coerce_call(raw) do
        nil -> acc
        call -> Map.put(acc, id, call)
      end
    end)
  end

  defp coerce_calls(_calls), do: %{}

  defp coerce_call(%__MODULE__{} = call), do: call

  defp coerce_call(call) when is_map(call) do
    fields = Map.take(call, Map.keys(Map.from_struct(%__MODULE__{})))
    struct(__MODULE__, fields)
  end

  defp coerce_call(_call), do: nil

  # -- store / jid helpers ----------------------------------------------------

  defp resolve_store(target) when is_pid(target), do: get_store(target)

  defp resolve_store(%{__struct__: mod} = store) when is_atom(mod) do
    if function_exported?(mod, :load, 1) and function_exported?(mod, :persist, 2) do
      store
    else
      nil
    end
  end

  defp resolve_store(_target), do: nil

  defp get_store(session) do
    GenServer.call(session, :get_store)
  catch
    :exit, _ -> nil
  end

  defp normalize_optional_jid(value) do
    case normalize_jid(value) do
      "" -> nil
      jid -> jid
    end
  end

  defp normalize_jid(%JID{} = jid), do: normalize_jid(JID.to_string(jid))

  defp normalize_jid(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
    |> then(fn value ->
      case String.split(value, "@", parts: 2) do
        [user, domain] when user != "" and domain != "" ->
          Regex.replace(~r/:(\d+)$/, user, "") <> "@" <> domain

        _ ->
          value
      end
    end)
  end

  defp normalize_jid(_value), do: ""

  defp non_empty_text(value) when is_binary(value) do
    trimmed = String.trim(value)
    if trimmed == "", do: nil, else: trimmed
  end

  defp non_empty_text(_value), do: nil

  defp boolean_or_nil(value) when is_boolean(value), do: value
  defp boolean_or_nil(_value), do: nil

  defp positive_or_nil(value) when is_integer(value) and value > 0, do: value
  defp positive_or_nil(_value), do: nil

  defp non_neg_or_nil(value) when is_integer(value) and value >= 0, do: value
  defp non_neg_or_nil(_value), do: nil
end
