defmodule ExWapp.Store do
  @moduledoc """
  Persistence adapter behaviour for WhatsApp session state.

  Adapters implement this behaviour to persist session data including:
  - Noise protocol keys (static keypair, handshake hash/salt)
  - Signal protocol state (identity, signed prekeys, sessions)
  - Client configuration and pairing data
  - App state sync data:
    - `:app_state_keys`
    - `:app_state_versions`
    - `:app_state_mutation_macs`
    - `:contacts`

  ## Built-in Adapters

    * `ExWapp.Store.Ets` - ETS table with file persistence (default)
    * `ExWapp.Store.Memory` - In-memory only, useful for testing

  ## Passing a Store to Session

  ```elixir
  # Use default ETS adapter
  ExWapp.connect(store: nil)

  # Use ETS with custom path
  ExWapp.connect(store: {ExWapp.Store.Ets, path: "/custom/path.etf"})

  # Use memory adapter for testing
  ExWapp.connect(store: ExWapp.Store.Memory)

  # Use pre-created store instance
  store = ExWapp.Store.Ets.new(path: "my_session.etf")
  ExWapp.connect(store: store)
  ```

  ## Creating a Custom Adapter

  Implement the `ExWapp.Store` behaviour:

  ```elixir
  defmodule MyApp.PostgresStore do
    @behaviour ExWapp.Store

    defstruct [:conn, :user_id]

    @impl true
    def new(opts) do
      conn = Keyword.fetch!(opts, :conn)
      user_id = Keyword.fetch!(opts, :user_id)
      %__MODULE__{conn: conn, user_id: user_id}
    end

    @impl true
    def load(%__MODULE__{conn: conn, user_id: user_id}) do
      case MyApp.Repo.get_by(WaSession, user_id: user_id) do
        nil -> {:ok, %{}}
        session -> {:ok, session.data}
      end
    end

    @impl true
    def persist(%__MODULE__{conn: conn, user_id: user_id}, data) do
      MyApp.Repo.insert_or_update!(%WaSession{user_id: user_id, data: data})
      :ok
    end
  end
  ```
  """

  require Logger
  alias ExWapp.Log
  alias ExWapp.Signal.SessionStore

  @type data :: map()
  @type t :: struct()

  @doc """
  Creates a new store instance.

  Options are adapter-specific. See the adapter module documentation.
  """
  @callback new(opts :: keyword()) :: t()

  @doc """
  Loads persisted session data.

  Returns `{:ok, data}` with the stored map, or `{:ok, %{}}` if no data exists.
  Returns `{:error, reason}` if the load operation fails.
  """
  @callback load(store :: t()) :: {:ok, data()} | {:error, term()}

  @doc """
  Persists session data.

  The `data` map contains all session state that needs to survive restarts.
  Returns `:ok` on success or `{:error, reason}` on failure.
  """
  @callback persist(store :: t(), data :: data()) :: :ok | {:error, term()}

  @doc "Reads a consistent snapshot of non-specialized top-level store data."
  @callback read(store :: t(), (data() -> term())) :: term()

  @doc "Atomically updates one top-level store domain."
  @callback update(store :: t(), key :: atom(), default :: term(), (term() -> term())) ::
              :ok | {:error, term()}

  @doc "Atomically updates one domain and returns a value from the update."
  @callback get_and_update(
              store :: t(),
              key :: atom(),
              default :: term(),
              (term() -> {term(), term()})
            ) :: term() | {:error, term()}

  @doc "Atomically transforms all non-specialized top-level store data."
  @callback transaction(store :: t(), (data() -> data())) :: :ok | {:error, term()}

  @doc "Begins a caller-owned persistence batch."
  @callback begin_batch(store :: t(), reason :: term()) :: :ok | {:error, term()}

  @doc "Ends a caller-owned persistence batch and durably flushes pending writes."
  @callback finish_batch(store :: t(), reason :: term()) :: :ok | {:error, term()}

  @doc "Durably flushes all pending writes without closing the adapter."
  @callback flush(store :: t()) :: :ok | {:error, term()}

  @doc """
  Optional callback that releases adapter-owned processes or connections.

  Sessions call this only for store instances they created themselves. A
  pre-created store passed as a struct remains owned by the caller.
  """
  @callback close(store :: t()) :: :ok | {:error, term()}

  @doc """
  Optional callback to clear all stored data.

  Useful for testing or when unlinking a device.
  """
  @callback clear(store :: t()) :: :ok | {:error, term()}

  @doc "Returns a lazy cursor over messages stored for one chat."
  @callback stream_messages(store :: t(), jid :: String.t(), opts :: keyword()) ::
              Enumerable.t()

  @doc "Upserts messages without embedding them in chat metadata."
  @callback upsert_messages(store :: t(), jid :: String.t(), messages :: [map()]) ::
              :ok | {:error, term()}

  @doc "Finds one message in a chat by ID."
  @callback find_message(store :: t(), jid :: String.t(), message_id :: String.t()) ::
              map() | nil

  @doc "Finds one message by ID across all chats."
  @callback find_message_by_id(store :: t(), message_id :: String.t()) ::
              {String.t(), map()} | nil

  @doc "Updates the status of one message in a chat."
  @callback update_message_status(
              store :: t(),
              jid :: String.t(),
              message_id :: String.t(),
              status :: atom()
            ) :: :ok | {:error, term()}

  @doc "Updates the status of every message matching an ID."
  @callback update_message_status_by_id(
              store :: t(),
              message_id :: String.t(),
              status :: atom()
            ) :: :ok | {:error, term()}

  @doc "Deletes selected messages after durable application persistence."
  @callback delete_messages(store :: t(), jid :: String.t(), message_ids :: [String.t()]) ::
              :ok | {:error, term()}

  @doc "Deletes every message associated with one chat."
  @callback delete_chat_messages(store :: t(), jid :: String.t()) ::
              :ok | {:error, term()}

  @doc "Materializes all messages for an explicit backup operation."
  @callback snapshot_messages(store :: t()) :: %{optional(String.t()) => [map()]}

  @optional_callbacks close: 1,
                      clear: 1,
                      read: 2,
                      update: 4,
                      get_and_update: 4,
                      transaction: 2,
                      begin_batch: 2,
                      finish_batch: 2,
                      flush: 1,
                      stream_messages: 3,
                      upsert_messages: 3,
                      find_message: 3,
                      find_message_by_id: 2,
                      update_message_status: 4,
                      update_message_status_by_id: 3,
                      delete_messages: 3,
                      delete_chat_messages: 2,
                      snapshot_messages: 1

  # Default adapter
  @default_adapter ExWapp.Store.Ets

  @doc """
  Creates a store instance from various input formats.

  ## Examples

      # Use default adapter
      iex> ExWapp.Store.new(nil)
      %ExWapp.Store.Ets{...}

      # Use module name
      iex> ExWapp.Store.new(ExWapp.Store.Memory)
      %ExWapp.Store.Memory{...}

      # Use module with options
      iex> ExWapp.Store.new({ExWapp.Store.Ets, path: "/tmp/test.etf"})
      %ExWapp.Store.Ets{path: "/tmp/test.etf", ...}

      # Pass existing struct
      iex> store = ExWapp.Store.Memory.new([])
      iex> ExWapp.Store.new(store) == store
      true
  """
  @spec new(nil | module() | {module(), keyword()} | t()) :: t()
  def new(nil), do: @default_adapter.new([])
  def new(%_{} = struct), do: struct
  def new({mod, opts}) when is_atom(mod) and is_list(opts), do: mod.new(opts)
  def new(mod) when is_atom(mod), do: mod.new([])

  @doc """
  Releases resources held by a store adapter when it implements `close/1`.

  Adapters without process or connection resources need no callback.
  """
  @spec close(t()) :: :ok | {:error, term()}
  def close(%module{} = store) do
    if function_exported?(module, :close, 1), do: module.close(store), else: :ok
  end

  @doc """
  Loads data from a store adapter.

  ## Examples

      iex> store = ExWapp.Store.Memory.new([])
      iex> ExWapp.Store.load(store)
      {:ok, %{}}
  """
  @spec load(t()) :: {:ok, data()} | {:error, term()}
  def load(store), do: store.__struct__.load(store)

  @doc """
  Reads a single top-level key from the store.

  Adapters may override this with a more efficient implementation that avoids
  loading and merging the entire persisted store.
  """
  @spec get(t(), atom(), term()) :: term()
  def get(store, key, default \\ nil) when is_atom(key) do
    if function_exported?(store.__struct__, :get, 3) do
      case store.__struct__.get(store, key, default) do
        {:ok, value} -> value
        {:error, _reason} -> default
        value -> value
      end
    else
      store
      |> load!()
      |> Map.get(key, default)
    end
  end

  @doc """
  Loads data from store, returning empty map on error.

  This is a convenience function that never fails. Use `load/1` if you
  need to handle errors explicitly.
  """
  @spec load!(t()) :: data()
  def load!(store) do
    case load(store) do
      {:ok, data} ->
        data

      {:error, :empty_store} ->
        %{}

      {:error, reason} ->
        Logger.error(
          "[STORE] load! failed adapter=#{inspect(store.__struct__)} reason=#{Log.reason(reason)}"
        )

        raise "ExWapp.Store.load! failed: #{inspect(reason)}"
    end
  rescue
    exception ->
      Logger.error(
        "[STORE] load! raised adapter=#{inspect(store.__struct__)} error=#{Log.reason(exception)}"
      )

      reraise exception, __STACKTRACE__
  catch
    :exit, reason ->
      Logger.error(
        "[STORE] load! exited adapter=#{inspect(store.__struct__)} reason=#{Log.reason(reason)}"
      )

      raise "ExWapp.Store.load! exited: #{inspect(reason)}"
  end

  @doc """
  Persists data via the store adapter.

  ## Examples

      iex> store = ExWapp.Store.Memory.new([])
      iex> ExWapp.Store.persist(store, %{foo: "bar"})
      :ok
      iex> ExWapp.Store.load(store)
      {:ok, %{foo: "bar"}}
  """
  @spec persist(t(), data()) :: :ok | {:error, term()}
  def persist(store, data), do: store.__struct__.persist(store, data)

  @doc "Reads the adapter's non-specialized data through its write owner when supported."
  @spec read(t(), (data() -> term())) :: term()
  def read(store, reader) when is_function(reader, 1) do
    if function_exported?(store.__struct__, :read, 2) do
      store.__struct__.read(store, reader)
    else
      reader.(load!(store))
    end
  end

  @doc """
  Atomically updates one top-level domain without a load/modify/persist race.

  Built-in adapters execute `updater` inside their write owner. Custom adapters
  can implement `update/4`; the compatibility fallback cannot guarantee
  serialization across callers.
  """
  @spec update(t(), atom(), term(), (term() -> term())) :: :ok | {:error, term()}
  def update(store, key, default, updater)
      when is_atom(key) and is_function(updater, 1) do
    if function_exported?(store.__struct__, :update, 4) do
      store.__struct__.update(store, key, default, updater)
    else
      transaction(store, fn data ->
        Map.put(data, key, updater.(Map.get(data, key, default)))
      end)
    end
  end

  @doc "Atomically updates one top-level domain and returns the updater's reply."
  @spec get_and_update(t(), atom(), term(), (term() -> {term(), term()})) ::
          term() | {:error, term()}
  def get_and_update(store, key, default, updater)
      when is_atom(key) and is_function(updater, 1) do
    if function_exported?(store.__struct__, :get_and_update, 4) do
      store.__struct__.get_and_update(store, key, default, updater)
    else
      current = get(store, key, default)
      {reply, updated} = updater.(current)

      case put(store, key, updated) do
        :ok -> reply
        {:error, _reason} = error -> error
      end
    end
  end

  @doc "Stores one top-level domain atomically."
  @spec put(t(), atom(), term()) :: :ok | {:error, term()}
  def put(store, key, value) when is_atom(key) do
    update(store, key, nil, fn _current -> value end)
  end

  @doc """
  Atomically transforms the adapter's non-specialized top-level data.

  Prefer `update/4` for a single domain because it avoids materializing the
  rest of the store.
  """
  @spec transaction(t(), (data() -> data())) :: :ok | {:error, term()}
  def transaction(store, updater) when is_function(updater, 1) do
    if function_exported?(store.__struct__, :transaction, 2) do
      store.__struct__.transaction(store, updater)
    else
      store
      |> load!()
      |> updater.()
      |> then(&persist(store, &1))
    end
  end

  @doc "Starts a caller-owned write batch when supported by the adapter."
  @spec begin_batch(t(), term()) :: :ok | {:error, term()}
  def begin_batch(%module{} = store, reason) do
    if function_exported?(module, :begin_batch, 2),
      do: module.begin_batch(store, reason),
      else: :ok
  end

  @doc "Finishes a caller-owned write batch and flushes it when supported."
  @spec finish_batch(t(), term()) :: :ok | {:error, term()}
  def finish_batch(%module{} = store, reason) do
    if function_exported?(module, :finish_batch, 2),
      do: module.finish_batch(store, reason),
      else: :ok
  end

  @doc "Durably flushes pending adapter writes when the adapter supports it."
  @spec flush(t()) :: :ok | {:error, term()}
  def flush(%module{} = store) do
    if function_exported?(module, :flush, 1), do: module.flush(store), else: :ok
  end

  @doc """
  Reports which optional callbacks an adapter does not implement.

  Every message-level callback is optional and dispatched through
  `function_exported?/3`, so an adapter that misspells one, or never wrote it,
  silently falls through to a generic path with different semantics — no
  compile warning, no runtime error, just behaviour that quietly diverges.
  Naming the gap once at session start turns that into something a reader can
  see. Returns the missing `{function, arity}` pairs, newest adapters usually
  returning `[]`.
  """
  @spec missing_optional_callbacks(t()) :: [{atom(), arity()}]
  def missing_optional_callbacks(%module{}) do
    Code.ensure_loaded(module)

    __optional_callbacks__()
    |> Enum.reject(fn {fun, arity} -> function_exported?(module, fun, arity) end)
  end

  def missing_optional_callbacks(_store), do: []

  @doc false
  @spec __optional_callbacks__() :: [{atom(), arity()}]
  def __optional_callbacks__ do
    [
      close: 1,
      clear: 1,
      read: 2,
      update: 4,
      get_and_update: 4,
      transaction: 2,
      begin_batch: 2,
      finish_batch: 2,
      flush: 1,
      stream_messages: 3,
      upsert_messages: 3,
      find_message: 3,
      find_message_by_id: 2,
      update_message_status: 4,
      update_message_status_by_id: 3,
      delete_messages: 3,
      delete_chat_messages: 2,
      snapshot_messages: 1
    ]
  end

  @doc "Runs a function inside a caller-owned persistence batch."
  @spec batch(t(), term(), (-> term())) :: term()
  def batch(store, reason, fun) when is_function(fun, 0) do
    with :ok <- begin_batch(store, reason) do
      run_batch(store, reason, fun)
    end
  end

  @doc """
  Loads Signal session state from the store.

  ETS-backed adapters may return a lightweight session-store reference instead
  of a plain map so callers can avoid keeping large session state on process
  heaps.
  """
  @spec load_signal_sessions(t()) :: term()
  def load_signal_sessions(store) do
    if function_exported?(store.__struct__, :load_signal_sessions, 1) do
      store.__struct__.load_signal_sessions(store)
    else
      get(store, :signal_sessions)
    end
  end

  @doc """
  Persists Signal session state back to the store.
  """
  @spec persist_signal_sessions(t(), term()) :: :ok | {:error, term()}
  def persist_signal_sessions(store, sessions) do
    if function_exported?(store.__struct__, :persist_signal_sessions, 2) do
      store.__struct__.persist_signal_sessions(store, sessions)
    else
      persist(store, Map.put(load!(store), :signal_sessions, SessionStore.snapshot(sessions)))
    end
  end

  @doc """
  Loads the recent device cache snapshot.
  """
  @spec load_device_cache(t()) :: map()
  def load_device_cache(store) do
    if function_exported?(store.__struct__, :load_device_cache, 1) do
      store.__struct__.load_device_cache(store)
    else
      get(store, :device_cache, %{})
    end
  end

  @doc """
  Persists the recent device cache snapshot.
  """
  @spec persist_device_cache(t(), map()) :: :ok | {:error, term()}
  def persist_device_cache(store, cache) when is_map(cache) do
    if function_exported?(store.__struct__, :persist_device_cache, 2) do
      store.__struct__.persist_device_cache(store, cache)
    else
      persist(store, Map.put(load!(store), :device_cache, cache))
    end
  end

  @doc """
  Builds a lazy message stream for a chat.

  Built-in adapters keep message payloads outside chat metadata. Custom
  adapters can implement stream_messages/3 with a database cursor; adapters
  that do not implement it use a compatibility fallback over :chat_messages.
  """
  @spec stream_messages(t(), String.t(), keyword()) :: Enumerable.t()
  def stream_messages(store, jid, opts \\ []) when is_binary(jid) do
    if function_exported?(store.__struct__, :stream_messages, 3) do
      store.__struct__.stream_messages(store, jid, opts)
    else
      fallback_message_stream(store, jid, opts)
    end
  end

  @doc """
  Materializes a single page from the message stream.
  """
  @spec list_messages(t(), String.t(), keyword()) :: [map()]
  def list_messages(store, jid, opts \\ []) do
    opts = Keyword.put_new(opts, :limit, 50)
    store |> stream_messages(jid, opts) |> Enum.to_list()
  end

  @doc """
  Inserts or replaces messages by ID in the dedicated message store.
  """
  @spec upsert_messages(t(), String.t(), [map()]) :: :ok | {:error, term()}
  def upsert_messages(store, jid, messages) when is_binary(jid) and is_list(messages) do
    if function_exported?(store.__struct__, :upsert_messages, 3) do
      store.__struct__.upsert_messages(store, jid, messages)
    else
      fallback_upsert_messages(store, jid, messages)
    end
  end

  @doc "Finds one stored message in a chat."
  @spec find_message(t(), String.t(), String.t()) :: map() | nil
  def find_message(store, jid, message_id) do
    if function_exported?(store.__struct__, :find_message, 3) do
      store.__struct__.find_message(store, jid, message_id)
    else
      store
      |> fallback_messages_for(jid)
      |> Enum.find(&(Map.get(&1, :id) == message_id))
    end
  end

  @doc "Finds one stored message by ID across all chats."
  @spec find_message_by_id(t(), String.t()) :: {String.t(), map()} | nil
  def find_message_by_id(store, message_id) do
    if function_exported?(store.__struct__, :find_message_by_id, 2) do
      store.__struct__.find_message_by_id(store, message_id)
    else
      fallback_message_map(store)
      |> Enum.find_value(&message_with_jid(&1, message_id))
    end
  end

  @doc "Updates one stored message status."
  @spec update_message_status(t(), String.t(), String.t(), atom()) ::
          :ok | {:error, term()}
  def update_message_status(store, jid, message_id, status) do
    if function_exported?(store.__struct__, :update_message_status, 4) do
      store.__struct__.update_message_status(store, jid, message_id, status)
    else
      messages =
        store
        |> fallback_messages_for(jid)
        |> replace_status(message_id, status)

      persist_fallback_messages(store, jid, messages)
    end
  end

  @doc "Updates message status by ID across all chats."
  @spec update_message_status_by_id(t(), String.t(), atom()) :: :ok | {:error, term()}
  def update_message_status_by_id(store, message_id, status) do
    if function_exported?(store.__struct__, :update_message_status_by_id, 3) do
      store.__struct__.update_message_status_by_id(store, message_id, status)
    else
      messages =
        Enum.into(fallback_message_map(store), %{}, fn {jid, chat_messages} ->
          {jid, replace_status(chat_messages, message_id, status)}
        end)

      persist_fallback_message_map(store, messages)
    end
  end

  @doc """
  Deletes selected messages after the caller has persisted them durably.
  """
  @spec delete_messages(t(), String.t(), [String.t()]) :: :ok | {:error, term()}
  def delete_messages(store, jid, message_ids) when is_list(message_ids) do
    if function_exported?(store.__struct__, :delete_messages, 3) do
      store.__struct__.delete_messages(store, jid, message_ids)
    else
      ids = MapSet.new(message_ids)

      messages =
        Enum.reject(fallback_messages_for(store, jid), &MapSet.member?(ids, Map.get(&1, :id)))

      persist_fallback_messages(store, jid, messages)
    end
  end

  @doc "Deletes all messages associated with one chat."
  @spec delete_chat_messages(t(), String.t()) :: :ok | {:error, term()}
  def delete_chat_messages(store, jid) do
    if function_exported?(store.__struct__, :delete_chat_messages, 2) do
      store.__struct__.delete_chat_messages(store, jid)
    else
      messages = Map.delete(fallback_message_map(store), jid)
      persist_fallback_message_map(store, messages)
    end
  end

  @doc """
  Returns a complete local snapshot including separately stored messages.

  This is intentionally eager and should only be used for explicit backups.
  Normal consumers should use stream_messages/3.
  """
  @spec snapshot(t()) :: {:ok, data()} | {:error, term()}
  def snapshot(store) do
    with {:ok, data} <- load(store) do
      messages =
        if function_exported?(store.__struct__, :snapshot_messages, 1) do
          store.__struct__.snapshot_messages(store)
        else
          fallback_message_map(store)
        end

      {:ok, put_message_snapshot(data, messages)}
    end
  end

  @doc """
  Clears all data from the store.

  Only available if the adapter implements the optional `clear/1` callback.
  """
  @spec clear(t()) :: :ok | {:error, term()}
  def clear(store) do
    if function_exported?(store.__struct__, :clear, 1) do
      store.__struct__.clear(store)
    else
      {:error, :not_implemented}
    end
  end

  defp fallback_message_stream(store, jid, opts) do
    store
    |> fallback_resource_stream(jid, opts)
    |> Stream.map(& &1)
  end

  defp fallback_resource_stream(store, jid, opts) do
    Stream.resource(
      fn ->
        messages =
          store
          |> fallback_messages_for(jid)
          |> Enum.sort_by(&message_sort_key/1, message_order(opts))
          |> Enum.drop(valid_offset(opts))
          |> take_messages(Keyword.get(opts, :limit, :all))

        messages
      end,
      fn
        [] -> {:halt, []}
        [message | rest] -> {[message], rest}
      end,
      fn _messages -> :ok end
    )
  end

  defp fallback_upsert_messages(store, jid, messages) do
    merged =
      (fallback_messages_for(store, jid) ++ messages)
      |> Enum.filter(&is_map/1)
      |> Enum.uniq_by(&Map.get(&1, :id))
      |> Enum.sort_by(&message_sort_key/1, :desc)

    persist_fallback_messages(store, jid, merged)
  end

  defp fallback_message_map(store) do
    data = load!(store)
    current = Map.get(data, :chat_messages, %{})

    legacy =
      data
      |> Map.get(:chats, %{})
      |> Enum.reduce(%{}, &put_legacy_messages/2)

    Map.merge(current, legacy, fn _jid, left, right -> left ++ right end)
  end

  defp message_with_jid({jid, messages}, message_id) do
    case Enum.find(messages, &(Map.get(&1, :id) == message_id)) do
      nil -> nil
      message -> {jid, message}
    end
  end

  defp put_message_snapshot(data, messages) when map_size(messages) == 0,
    do: Map.delete(data, :chat_messages)

  defp put_message_snapshot(data, messages), do: Map.put(data, :chat_messages, messages)

  defp put_legacy_messages({jid, chat}, acc) do
    case legacy_chat_messages(chat) do
      messages when is_list(messages) and messages != [] -> Map.put(acc, jid, messages)
      _ -> acc
    end
  end

  defp legacy_chat_messages(chat) when is_map(chat), do: Map.get(chat, :messages, [])
  defp legacy_chat_messages(_chat), do: []

  defp fallback_messages_for(store, jid) do
    store
    |> fallback_message_map()
    |> Map.get(jid, [])
  end

  defp persist_fallback_messages(store, jid, messages) do
    store
    |> fallback_message_map()
    |> Map.put(jid, messages)
    |> then(&persist_fallback_message_map(store, &1))
  end

  defp persist_fallback_message_map(store, messages) do
    store
    |> load!()
    |> Map.put(:chat_messages, messages)
    |> then(&persist(store, &1))
  end

  defp replace_status(messages, message_id, status) do
    Enum.map(messages, fn message ->
      if Map.get(message, :id) == message_id, do: Map.put(message, :status, status), else: message
    end)
  end

  defp message_sort_key(message) do
    {Map.get(message, :timestamp, 0), Map.get(message, :id, "")}
  end

  defp message_order(opts) do
    if Keyword.get(opts, :order, :newest_first) == :oldest_first, do: :asc, else: :desc
  end

  defp valid_offset(opts) do
    case Keyword.get(opts, :offset, 0) do
      offset when is_integer(offset) and offset >= 0 -> offset
      _ -> 0
    end
  end

  defp take_messages(messages, :all), do: messages

  defp take_messages(messages, limit) when is_integer(limit) and limit >= 0,
    do: Enum.take(messages, limit)

  defp take_messages(messages, _invalid), do: messages

  defp run_batch(store, reason, fun) do
    result = fun.()

    case finish_batch(store, reason) do
      :ok -> result
      {:error, _reason} = error -> error
    end
  rescue
    exception ->
      _ = finish_batch(store, reason)
      reraise exception, __STACKTRACE__
  catch
    kind, caught_reason ->
      _ = finish_batch(store, reason)
      :erlang.raise(kind, caught_reason, __STACKTRACE__)
  end
end
