defmodule ExWapp.Prekeys do
  @moduledoc """
  Handles prekey generation and upload to WhatsApp servers.

  Reference: whatsmeow/prekeys.go
  """

  require Logger
  alias ExWapp.{Binary, Config, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Signal.Keys

  # Number of prekeys to upload on initial registration
  @initial_prekey_count 812
  # Number of prekeys on normal refill
  @wanted_prekey_count 50
  # Minimum prekeys before triggering upload
  @min_prekey_count 5
  # One-time prekey ids travel as 3 bytes on the wire. An id above this is
  # advertised under a different (truncated) number than the store holds it
  # by, so every pkmsg drawing it fails permanently — the ceiling has to be
  # enforced where ids are minted.
  @max_prekey_id 0xFFFFFF

  @doc """
  Returns the next one-time prekey id that is safe to mint.

  An id is safe only if it was never handed to the server. WhatsApp keeps
  serving an uploaded prekey to peers long after this client forgot it — after a
  crash before the durable write, or after the session file is restored from an
  older snapshot — and a peer that opens a session with a stale id sends a
  `pkmsg` this client answers with `:prekey_not_found`. Minting that id again
  with fresh key material makes the damage permanent: the peer holds one public
  half, the store holds another, and every X3DH between them fails from then on.
  So the ceiling is the highest id ever advertised, not the highest id still
  held.
  """
  @spec next_safe_id(map(), map()) :: pos_integer()
  def next_safe_id(signal, prekeys) when is_map(signal) and is_map(prekeys) do
    configured =
      case Map.get(signal, :next_prekey_id, 1) do
        value when is_integer(value) and value > 0 -> value
        _other -> 1
      end

    after_existing = highest_id(Map.keys(prekeys)) + 1
    after_advertised = advertised_watermark(signal) + 1

    Enum.max([configured, after_existing, after_advertised])
  end

  @doc """
  Reserves `count` consecutive ids and returns the first one to mint.

  The local watermark is only as trustworthy as the store holding it: restore the
  session file from a snapshot and the ceiling comes back with it, below ids the
  server is already handing out. A host that keeps its durable state somewhere
  that cannot roll back — a row in the database the session file is archived
  into, say — can close that gap by configuring
  `prekeys: [id_allocator: fn local_floor, count -> {:ok, first_id} end]`. The
  allocator is expected to be atomic and monotonic; it receives the local floor
  so it can never hand back a range this store has already used.

  Without one, the local floor stands on its own, which is correct for any
  deployment whose store never travels backwards.

  An allocator that fails aborts the caller. Refusing to mint costs a thinner
  prekey pool on the server until it recovers; minting anyway costs an id space
  that two devices disagree about, which nothing repairs.
  """
  @spec allocate_ids(map(), map(), pos_integer()) :: {:ok, pos_integer()} | {:error, term()}
  def allocate_ids(runtime_cfg, signal, count)
      when is_map(signal) and is_integer(count) and count > 0 do
    local_floor = next_safe_id(signal, Map.get(signal, :prekeys) || %{})

    case prekey_cfg(runtime_cfg || %{}, :id_allocator, nil) do
      nil ->
        bounded_id_range(local_floor, count)

      allocator when is_function(allocator, 2) ->
        apply_id_allocator(allocator, local_floor, count)

      other ->
        {:error, {:invalid_prekey_id_allocator, other}}
    end
  end

  defp bounded_id_range(first_id, count) when first_id + count - 1 <= @max_prekey_id,
    do: {:ok, first_id}

  defp bounded_id_range(_first_id, _count),
    do: {:error, :prekey_id_space_exhausted}

  defp apply_id_allocator(allocator, local_floor, count) do
    case allocator.(local_floor, count) do
      {:ok, first_id} when is_integer(first_id) and first_id >= local_floor ->
        bounded_id_range(first_id, count)

      {:ok, first_id} when is_integer(first_id) ->
        # A floor below what this store has already minted would reissue live
        # ids. The allocator is the ceiling, never a way to move backwards.
        Logger.error(
          "[PREKEYS] Id allocator returned #{first_id}, below the local floor #{local_floor}; " <>
            "keeping the local floor"
        )

        {:ok, local_floor}

      {:error, reason} ->
        {:error, {:prekey_id_allocation_failed, reason}}

      other ->
        {:error, {:prekey_id_allocation_failed, other}}
    end
  rescue
    error -> {:error, {:prekey_id_allocation_failed, error}}
  catch
    kind, reason -> {:error, {:prekey_id_allocation_failed, {kind, reason}}}
  end

  @doc """
  Raises the advertised-id watermark to cover `ids`.

  Called for every id this client puts in front of the server or a peer: an
  upload batch, a retry receipt's key bundle, and any id an inbound `pkmsg`
  proves the server is still serving.
  """
  @spec advertise_ids(map(), [term()]) :: map()
  def advertise_ids(signal, ids) when is_map(signal) and is_list(ids) do
    watermark = max(advertised_watermark(signal), highest_id(ids))

    if watermark > 0 do
      Map.put(signal, :max_advertised_prekey_id, watermark)
    else
      signal
    end
  end

  @doc """
  Records that the server is still serving `prekey_id` for this account.

  The trigger is an inbound `pkmsg` naming a one-time prekey the local store
  cannot produce. Nothing can recover that message — the private half is gone —
  but the id must never be reissued, so the watermark absorbs it here.
  """
  @spec note_advertised_prekey_id(Store.t(), term()) :: :ok | {:error, term()}
  def note_advertised_prekey_id(store, prekey_id)
      when is_integer(prekey_id) and prekey_id > 0 do
    # `get_and_update/4` rather than `update/4`: every adapter that reserves
    # prekeys already implements it, while `update/4` falls back to a whole-store
    # transaction that a narrower adapter may not support at all — and a silently
    # dropped watermark is the one outcome this must not have.
    case Store.get_and_update(store, :signal, %{}, &{:ok, advertise_ids(&1, [prekey_id])}) do
      :ok -> :ok
      {:error, _reason} = error -> error
      other -> {:error, {:prekey_watermark_update_failed, other}}
    end
  rescue
    error -> {:error, {:prekey_watermark_update_failed, error}}
  catch
    kind, reason -> {:error, {:prekey_watermark_update_failed, {kind, reason}}}
  end

  def note_advertised_prekey_id(_store, _prekey_id), do: :ok

  @doc """
  Returns the highest one-time prekey id this account has ever advertised.
  """
  @spec advertised_watermark(map()) :: non_neg_integer()
  def advertised_watermark(signal) when is_map(signal) do
    case Map.get(signal, :max_advertised_prekey_id) do
      value when is_integer(value) and value > 0 -> value
      _other -> 0
    end
  end

  defp highest_id(ids) do
    ids
    |> Enum.filter(&(is_integer(&1) and &1 > 0))
    |> Enum.max(fn -> 0 end)
  end

  @doc """
  Builds the IQ node to query prekey count on server.
  """
  def build_prekey_count_query do
    request_id = generate_request_id()

    %Node{
      tag: "iq",
      attrs: %{
        "id" => request_id,
        "xmlns" => "encrypt",
        "type" => "get",
        "to" => "s.whatsapp.net"
      },
      content: [%Node{tag: "count", attrs: %{}, content: nil}]
    }
  end

  @doc """
  Builds the IQ node to upload prekeys to server.

  Reference: whatsmeow/prekeys.go uploadPreKeys()
  """
  def build_prekey_upload(store, opts \\ []) do
    data = Store.load!(store)
    signal = Map.get(data, :signal, %{})
    runtime_cfg = Keyword.get(opts, :runtime_cfg, %{})

    initial_upload = Keyword.get(opts, :initial, false)
    initial_count = prekey_cfg(runtime_cfg, :initial_prekey_count, @initial_prekey_count)
    refill_count = prekey_cfg(runtime_cfg, :refill_prekey_count, @wanted_prekey_count)

    prekey_count =
      Keyword.get(opts, :count) || if(initial_upload, do: initial_count, else: refill_count)

    Logger.debug("[PREKEYS] Building upload, signal keys: #{inspect(Map.keys(signal))}")

    with true <- is_integer(prekey_count) and prekey_count > 0,
         {:ok, registration_id} <- get_registration_id(signal),
         {:ok, identity_pub} <- get_identity_public(signal, data),
         {:ok, signed_prekey} <- get_signed_prekey(signal),
         {:ok, start_id} <- allocate_ids(runtime_cfg, signal, keys_to_mint(signal, prekey_count)),
         {:ok, reservation} <- reserve_prekeys(store, prekey_count, start_id),
         :ok <- flush_reservation(store) do
      prekeys = reservation.prekeys
      request_id = generate_request_id()

      # Build registration ID as 4-byte big-endian
      reg_id_bytes = <<registration_id::big-32>>

      # DJB key type = 0x05
      key_type = <<0x05>>

      node = %Node{
        tag: "iq",
        attrs: %{
          "id" => request_id,
          "xmlns" => "encrypt",
          "type" => "set",
          "to" => "s.whatsapp.net"
        },
        content: [
          %Node{tag: "registration", attrs: %{}, content: Binary.raw(reg_id_bytes)},
          %Node{tag: "type", attrs: %{}, content: Binary.raw(key_type)},
          %Node{tag: "identity", attrs: %{}, content: Binary.raw(identity_pub)},
          %Node{tag: "list", attrs: %{}, content: prekeys_to_nodes(prekeys)},
          signed_prekey_to_node(signed_prekey)
        ]
      }

      Logger.debug(
        "[PREKEYS] Built durable upload batch count=#{length(prekeys)} initial=#{initial_upload} " <>
          "reused=#{reservation.reused_count} generated=#{reservation.generated_count} " <>
          "id_range=#{format_id_range(prekeys)}"
      )

      {:ok, node, prekeys}
    else
      false -> {:error, :invalid_prekey_count}
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Marks a durably reserved prekey batch as acknowledged by the server.

  Private key material is already present before the IQ is sent; this mutation
  only changes upload bookkeeping and can therefore be safely retried.
  """
  @spec mark_uploaded(Store.t(), [map()]) :: :ok | {:error, term()}
  def mark_uploaded(store, prekeys) when is_list(prekeys) do
    ids =
      prekeys
      |> Enum.map(&(Map.get(&1, :key_id) || Map.get(&1, :id)))
      |> Enum.filter(&(is_integer(&1) and &1 > 0))
      |> MapSet.new()

    case Store.update(store, :signal, %{}, fn signal ->
           updated_prekeys =
             signal
             |> Map.get(:prekeys, %{})
             |> Enum.into(%{}, &mark_prekey_uploaded(&1, ids))

           Map.put(signal, :prekeys, updated_prekeys)
         end) do
      :ok -> :ok
      {:error, _reason} = error -> error
    end
  rescue
    error -> {:error, {:prekey_upload_mark_failed, error}}
  catch
    kind, reason -> {:error, {:prekey_upload_mark_failed, {kind, reason}}}
  end

  @doc """
  Parses the server's response to a prekey count query.

  The response contains a `<count>` child node with a `value` attribute.
  Reference: Baileys getAvailablePreKeysOnServer()
  """
  def parse_count_response(content) when is_list(content) do
    Enum.find_value(content, 0, fn
      %Node{tag: "count", attrs: attrs} ->
        attrs
        |> Map.get("value")
        |> parse_count_value()

      _ ->
        nil
    end)
  end

  def parse_count_response(_), do: 0

  defp parse_count_value(nil), do: 0
  defp parse_count_value(val) when is_integer(val), do: val

  defp parse_count_value(val) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp parse_count_value(_), do: 0

  @doc """
  Check if prekeys need to be uploaded based on server response.
  """
  def needs_upload?(server_count, local_count) do
    server_count < @min_prekey_count or local_count < @min_prekey_count
  end

  @doc """
  Configurable version of `needs_upload?/2` using runtime config.
  """
  def needs_upload?(server_count, local_count, runtime_cfg) when is_map(runtime_cfg) do
    threshold = prekey_cfg(runtime_cfg, :min_threshold, @min_prekey_count)
    server_count < threshold or local_count < threshold
  end

  @doc """
  Check if this is an initial upload (no prekeys exist).
  """
  def initial_upload?(server_count, local_count) do
    server_count == 0 and local_count == 0
  end

  # Private functions

  defp get_registration_id(%{registration_id: reg_id}) when is_integer(reg_id), do: {:ok, reg_id}

  defp get_registration_id(signal) do
    Logger.warning("[PREKEYS] Missing registration_id in signal: #{inspect(Map.keys(signal))}")
    {:error, :missing_registration_id}
  end

  # Signal state stores identity_key, but root data may have identity
  defp get_identity_public(%{identity_key: %{public: pub}}, _data)
       when is_binary(pub) and byte_size(pub) == 32,
       do: {:ok, pub}

  defp get_identity_public(_signal, %{identity: %{public: pub}})
       when is_binary(pub) and byte_size(pub) == 32,
       do: {:ok, pub}

  defp get_identity_public(signal, data) do
    Logger.warning(
      "[PREKEYS] Missing identity_public, signal keys: #{inspect(Map.keys(signal))}, data keys: #{inspect(Map.keys(data))}"
    )

    {:error, :missing_identity_public}
  end

  # Signal state stores signed_prekeys as map of {id => key}, get the first valid one
  defp get_signed_prekey(%{signed_prekeys: spks}) when is_map(spks) and map_size(spks) > 0 do
    # Get first signed prekey from the map
    {id, spk} = Enum.at(spks, 0)
    {:ok, Map.put(spk, :key_id, id)}
  end

  defp get_signed_prekey(%{signed_prekey: spk}) when is_map(spk), do: {:ok, spk}

  defp get_signed_prekey(signal) do
    Logger.warning("[PREKEYS] Missing signed_prekey in signal: #{inspect(Map.keys(signal))}")
    {:error, :missing_signed_prekey}
  end

  # How many ids the batch will actually mint. Keys reserved by an upload that
  # never completed are reused rather than replaced, and asking the allocator for
  # ids that will not be used would burn the id space on every failed attempt.
  defp keys_to_mint(signal, count) do
    reusable =
      signal
      |> Map.get(:prekeys, %{})
      |> Enum.count(&unuploaded_prekey?/1)

    max(count - reusable, 1)
  end

  defp reserve_prekeys(store, count, allocated_start_id) do
    case Store.get_and_update(store, :signal, %{}, fn signal ->
           prekeys = Map.get(signal, :prekeys, %{})

           reusable =
             prekeys
             |> Enum.filter(&unuploaded_prekey?/1)
             |> Enum.sort_by(&elem(&1, 0))
             |> Enum.take(count)

           generated_count = max(count - length(reusable), 0)
           start_id = max(allocated_start_id, next_safe_id(signal, prekeys))
           now = System.system_time(:second)

           generated =
             generate_reserved_prekeys(start_id, generated_count, now)

           updated_prekeys = Enum.reduce(generated, prekeys, &put_reserved_prekey/2)

           selected = Enum.map(reusable, &prekey_with_id/1) ++ generated

           next_prekey_id = next_prekey_id_after(generated, start_id)

           reservation = %{
             prekeys: Enum.map(selected, &to_upload_prekey/1),
             reused_count: length(reusable),
             generated_count: generated_count
           }

           {{:ok, reservation},
            signal
            |> Map.put(:prekeys, updated_prekeys)
            |> Map.put(:next_prekey_id, next_prekey_id)
            |> advertise_ids(Enum.map(selected, & &1.id))}
         end) do
      {:ok, _reservation} = success -> success
      {:error, _reason} = error -> {:error, {:prekey_reservation_failed, error}}
      other -> {:error, {:prekey_reservation_failed, other}}
    end
  rescue
    error -> {:error, {:prekey_reservation_failed, error}}
  catch
    kind, reason -> {:error, {:prekey_reservation_failed, {kind, reason}}}
  end

  # The batch is durable before the IQ leaves, never after. An adapter that
  # persists asynchronously would otherwise let this client advertise public
  # halves whose private halves are still only in memory: a crash in that window
  # leaves the server serving keys nothing can decrypt with, and every peer that
  # draws one is stuck on `:prekey_not_found` until it is nudged onto a new
  # bundle. Refusing to upload keeps that state unreachable.
  defp flush_reservation(store) do
    case Store.flush(store) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error(
          "[PREKEYS] Refusing to advertise a batch that could not be persisted: #{inspect(reason)}"
        )

        {:error, {:prekey_reservation_flush_failed, reason}}

      other ->
        {:error, {:prekey_reservation_flush_failed, other}}
    end
  end

  defp mark_prekey_uploaded({id, prekey}, ids) do
    if MapSet.member?(ids, id) and is_map(prekey) do
      {id, Map.put(prekey, :uploaded, true)}
    else
      {id, prekey}
    end
  end

  defp next_prekey_id_after([], start_id), do: start_id

  defp next_prekey_id_after(generated, _start_id) do
    generated
    |> List.last()
    |> Map.fetch!(:id)
    |> Kernel.+(1)
  end

  defp put_reserved_prekey(prekey, prekeys), do: Map.put(prekeys, prekey.id, prekey)
  defp prekey_with_id({id, prekey}), do: Map.put(prekey, :id, id)

  defp unuploaded_prekey?({id, prekey}) when is_integer(id) and is_map(prekey) do
    Map.get(prekey, :uploaded, true) == false and
      match?(<<_::binary-size(32)>>, Map.get(prekey, :public)) and
      match?(<<_::binary-size(32)>>, Map.get(prekey, :private))
  end

  defp unuploaded_prekey?(_entry), do: false

  defp generate_reserved_prekeys(_start_id, 0, _now), do: []

  defp generate_reserved_prekeys(start_id, count, now) do
    for offset <- 0..(count - 1) do
      start_id
      |> Kernel.+(offset)
      |> Keys.generate_prekey()
      |> Map.put(:generated_at, now)
      |> Map.put(:uploaded, false)
    end
  end

  defp to_upload_prekey(prekey) do
    %{
      key_id: Map.fetch!(prekey, :id),
      public: Map.fetch!(prekey, :public),
      private: Map.fetch!(prekey, :private)
    }
  end

  defp format_id_range([]), do: "empty"

  defp format_id_range(prekeys) do
    ids = Enum.map(prekeys, &Map.fetch!(&1, :key_id))
    "#{Enum.min(ids)}..#{Enum.max(ids)}"
  end

  defp prekeys_to_nodes(prekeys) do
    Enum.map(prekeys, fn prekey ->
      # Key IDs are 3 bytes on the wire. Matching the high byte to zero makes
      # an out-of-range id fail loudly instead of being advertised under a
      # silently truncated number the store does not hold.
      <<0::8, key_id_bytes::binary-3>> = <<prekey.key_id::big-32>>

      %Node{
        tag: "key",
        attrs: %{},
        content: [
          %Node{tag: "id", attrs: %{}, content: Binary.raw(key_id_bytes)},
          %Node{tag: "value", attrs: %{}, content: Binary.raw(prekey.public)}
        ]
      }
    end)
  end

  defp signed_prekey_to_node(spk) do
    # Key IDs are 3 bytes on the wire; an out-of-range id must fail loudly
    # rather than truncate.
    key_id = Map.get(spk, :key_id, 1)
    <<0::8, key_id_bytes::binary-3>> = <<key_id::big-32>>

    pub = Map.get(spk, :public)
    sig = Map.get(spk, :signature)

    %Node{
      tag: "skey",
      attrs: %{},
      content: [
        %Node{tag: "id", attrs: %{}, content: Binary.raw(key_id_bytes)},
        %Node{tag: "value", attrs: %{}, content: Binary.raw(pub)},
        %Node{tag: "signature", attrs: %{}, content: Binary.raw(sig)}
      ]
    }
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(8) |> Base.encode64() |> String.slice(0, 12)
  end

  defp prekey_cfg(runtime_cfg, key, default) do
    Config.get(runtime_cfg, [:prekeys, key], default)
  end
end
