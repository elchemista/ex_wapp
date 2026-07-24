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
         {:ok, reservation} <- reserve_prekeys(store, prekey_count) do
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

  defp reserve_prekeys(store, count) do
    case Store.get_and_update(store, :signal, %{}, fn signal ->
           prekeys = Map.get(signal, :prekeys, %{})

           reusable =
             prekeys
             |> Enum.filter(&unuploaded_prekey?/1)
             |> Enum.sort_by(&elem(&1, 0))
             |> Enum.take(count)

           generated_count = max(count - length(reusable), 0)
           start_id = next_safe_prekey_id(signal, prekeys)
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
            |> Map.put(:next_prekey_id, next_prekey_id)}
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

  defp next_safe_prekey_id(signal, prekeys) do
    configured =
      case Map.get(signal, :next_prekey_id, 1) do
        value when is_integer(value) and value > 0 -> value
        _other -> 1
      end

    after_existing =
      prekeys
      |> Map.keys()
      |> Enum.filter(&is_integer/1)
      |> case do
        [] -> 1
        ids -> Enum.max(ids) + 1
      end

    max(configured, after_existing)
  end

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
      # Key ID is 3 bytes (last 3 bytes of 4-byte BE)
      <<_::8, key_id_bytes::binary-3>> = <<prekey.key_id::big-32>>

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
    # Key ID is 3 bytes (last 3 bytes of 4-byte BE)
    key_id = Map.get(spk, :key_id, 1)
    <<_::8, key_id_bytes::binary-3>> = <<key_id::big-32>>

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
