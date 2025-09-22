defmodule ExWapp.Pairing do
  @moduledoc """
  Implements the QR-code based pairing handshake used by WhatsApp Web.
  """

  alias ExWapp.{Binary, Signal, Store}
  alias ExWapp.Pairing.ADV
  require Logger

  @typedoc """
  Aggregate structure that keeps temporary pairing data.
  """
  @type state :: %{
          status: :idle | :waiting_for_scan | :paired,
          ref: String.t() | nil,
          store: Store.t(),
          req_id: String.t() | nil
        }

  @doc """
  Returns the initial pairing state.
  """
  @spec new(Store.t()) :: state()
  def new(store) do
    %{status: :idle, ref: nil, store: store, req_id: nil}
  end

  @doc """
  Applies a decoded node and returns the updated state plus pairing events.
  """
  @spec apply_node(state(), Binary.binary_node()) :: {state(), [term()]}
  def apply_node(state, %Binary.Node{tag: "iq", attrs: attrs, content: content}) do
    cond do
      pair_device = find_child(content, "pair-device") ->
        handle_pair_device(state, attrs, pair_device)

      pair_success = find_child(content, "pair-success") ->
        handle_pair_success(state, attrs, pair_success)

      true ->
        {state, []}
    end
  end

  def apply_node(state, _other), do: {state, []}

  defp handle_pair_device(state, attrs, pair_device) do
    refs = extract_refs(state, pair_device)
    codes = Enum.map(refs, &qr_from_ref(state, &1))

    ack_attrs = %{
      "to" => Map.get(attrs, "from"),
      "id" => Map.get(attrs, "id"),
      "type" => "result"
    }

    ack_node = %Binary.Node{tag: "iq", attrs: ack_attrs, content: nil}

    events =
      [{:send_node, ack_node}] ++
        Enum.map(codes, fn code -> {:qr, code} end)

    new_state = %{
      state
      | status: :waiting_for_scan,
        ref: List.first(refs),
        req_id: Map.get(attrs, "id")
    }

    {new_state, events}
  end

  defp handle_pair_success(%{store: store} = state, attrs, %Binary.Node{} = pair_success) do
    from = Map.get(attrs, "from")
    id = Map.get(attrs, "id")

    case persist_pair_success(store, pair_success) do
      {:ok, data} ->
        :ok = Store.persist(store, data)
        pairing_data = Map.get(data, :pairing)

        ack =
          if is_binary(from) and is_binary(id) do
            build_pair_success_ack(from, id, pairing_data)
          else
            nil
          end

        events = if(ack, do: [{:send_node, ack}], else: []) ++ [{:status, :success}]

        {%{state | status: :paired, ref: nil, req_id: nil}, events}

      {:error, reason} ->
        Logger.error("failed to persist pair-success data: #{inspect(reason)}")

        ack =
          if is_binary(from) and is_binary(id) do
            build_pair_success_ack(from, id, nil)
          else
            nil
          end

        events = if ack, do: [{:send_node, ack}, error_event(reason)], else: [error_event(reason)]

        {state, events}
    end
  end

  defp find_child(nil, _tag), do: nil

  defp find_child(children, tag) when is_list(children) do
    Enum.find(children, fn
      %Binary.Node{tag: ^tag} -> true
      _ -> false
    end)
  end

  defp extract_refs(_state, %Binary.Node{content: children}) when is_list(children) do
    children
    |> Enum.reduce([], fn child, acc ->
      case child do
        %Binary.Node{tag: "ref", content: %Binary.Raw{data: data}} ->
          [IO.iodata_to_binary(data) | acc]

        %Binary.Node{tag: "ref", content: binary} when is_binary(binary) ->
          [binary | acc]

        _other ->
          acc
      end
    end)
    |> Enum.reverse()
    |> case do
      [] ->
        Logger.warning("pair-device node contained no ref children")
        []

      refs ->
        refs
    end
  end

  defp extract_refs(_state, _other), do: []

  @doc """
  Turns the server-provided ref into a QR string.
  """
  @spec qr_from_ref(state(), binary()) :: String.t()
  def qr_from_ref(%{store: store}, ref) when is_binary(ref) do
    data = Store.load!(store)
    original = data

    {data, identity_pub} = ensure_identity(data)
    {data, adv_secret} = ensure_adv_secret(data)

    noise_pub = get_in(data, [:noise, :static_public]) || raise "noise static key missing"

    if data != original do
      :ok = Store.persist(store, data)
    end

    noise = Base.encode64(noise_pub)
    identity = Base.encode64(identity_pub)
    adv = Base.encode64(adv_secret)

    Enum.join([ref, noise, identity, adv], ",")
  end

  def qr_from_ref(_state, ref), do: ref

  defp ensure_identity(data) do
    case data[:identity] do
      %{public: pub} = _identity when is_binary(pub) ->
        {data, pub}

      _ ->
        {pub, priv} = :crypto.generate_key(:ecdh, :x25519)
        identity = %{public: pub, private: priv}
        {Map.put(data, :identity, identity), pub}
    end
  end

  defp ensure_adv_secret(data) do
    case data[:adv_secret] do
      secret when is_binary(secret) and byte_size(secret) == 32 ->
        {data, secret}

      _ ->
        secret = :crypto.strong_rand_bytes(32)
        {Map.put(data, :adv_secret, secret), secret}
    end
  end

  defp persist_pair_success(store, %Binary.Node{} = node) do
    data = Store.load!(store)

    with {:ok, device_identity} <- fetch_child_binary(node, "device-identity"),
         {:ok, adv_identity} <- fetch_child_binary(node, "adv-device-identity", optional: true),
         {:ok, adv_parsed} <- parse_adv_identity(data, adv_identity),
         {:ok, device_attrs} <- fetch_child_attrs(node, "device"),
         {:ok, biz_attrs} <- fetch_child_attrs(node, "biz", optional: true),
         {:ok, platform_attrs} <- fetch_child_attrs(node, "platform", optional: true),
         {:ok, signal_info, signal_state} <-
           Signal.bootstrap(%{
             device_identity: device_identity,
             adv_device_identity: adv_identity,
             adv: adv_parsed,
             device_attrs: device_attrs,
             current_signal: Map.get(data, :signal)
           }) do
      pairing_data =
        %{
          device_identity: device_identity,
          adv_device_identity: adv_identity,
          adv: adv_parsed,
          adv_self_signed: adv_parsed && adv_parsed.self_signed,
          device: device_attrs,
          biz: biz_attrs,
          platform: platform_attrs,
          paired_at: System.system_time(:second),
          signal: signal_info
        }

      updated_data =
        data
        |> Map.put(:pairing, pairing_data)
        |> Map.put(:signal, signal_state)

      {:ok, updated_data}
    end
  end

  defp fetch_child_binary(node, tag, opts \\ []) do
    optional? = Keyword.get(opts, :optional, false)

    case find_child(node.content, tag) do
      %Binary.Node{content: %Binary.Raw{data: data}} -> {:ok, IO.iodata_to_binary(data)}
      %Binary.Node{content: binary} when is_binary(binary) -> {:ok, binary}
      nil when optional? -> {:ok, nil}
      nil -> {:error, {:missing_child, tag}}
      _ -> {:error, {:invalid_child, tag}}
    end
  end

  defp fetch_child_attrs(node, tag, opts \\ []) do
    optional? = Keyword.get(opts, :optional, false)

    case find_child(node.content, tag) do
      %Binary.Node{attrs: attrs} -> {:ok, attrs}
      nil when optional? -> {:ok, %{}}
      nil -> {:error, {:missing_child, tag}}
      _ -> {:error, {:invalid_child, tag}}
    end
  end

  defp parse_adv_identity(_data, nil), do: {:ok, nil}

  defp parse_adv_identity(data, adv_identity) when is_binary(adv_identity) do
    with {:ok, adv_secret} <- fetch_adv_secret(data),
         {:ok, identity} <- fetch_identity_keypair(data),
         {:ok, parsed} <- ADV.parse_signed_device_identity(adv_identity, adv_secret, identity) do
      {:ok, parsed}
    end
  end

  defp parse_adv_identity(_data, _), do: {:error, :invalid_adv_identity}

  defp fetch_adv_secret(%{adv_secret: <<_::binary-size(32)>> = secret}), do: {:ok, secret}

  defp fetch_adv_secret(%{adv_secret: secret}) when is_binary(secret),
    do: {:error, :invalid_adv_secret}

  defp fetch_adv_secret(_), do: {:error, :missing_adv_secret}

  defp fetch_identity_keypair(%{
         identity: %{public: <<_::binary-size(32)>>, private: <<_::binary-size(32)>>} = identity
       }),
       do: {:ok, identity}

  defp fetch_identity_keypair(%{identity: %{}}), do: {:error, :invalid_identity_keypair}
  defp fetch_identity_keypair(_), do: {:error, :missing_identity_keypair}

  defp error_event(reason), do: {:error, reason}

  defp build_pair_success_ack(from, id, pairing_data) do
    base_attrs = %{"to" => from, "type" => "result", "id" => id}

    case build_pair_device_sign(pairing_data) do
      {:ok, pair_device_sign} ->
        %Binary.Node{tag: "iq", attrs: base_attrs, content: [pair_device_sign]}

      :error ->
        %Binary.Node{tag: "iq", attrs: base_attrs, content: nil}
    end
  end

  defp build_pair_device_sign(%{adv_self_signed: adv_self_signed} = pairing_data)
       when is_binary(adv_self_signed) do
    key_index =
      pairing_data
      |> get_in([:adv, :details, :keyIndex])
      |> normalize_key_index()

    attrs =
      case key_index do
        nil -> %{}
        value -> %{"key-index" => value}
      end

    device_identity = %Binary.Node{
      tag: "device-identity",
      attrs: attrs,
      content: Binary.raw(adv_self_signed)
    }

    {:ok, %Binary.Node{tag: "pair-device-sign", attrs: %{}, content: [device_identity]}}
  end

  defp build_pair_device_sign(_pairing_data), do: :error

  defp normalize_key_index(value) when is_integer(value) and value >= 0,
    do: Integer.to_string(value)

  defp normalize_key_index(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} when int >= 0 -> Integer.to_string(int)
      _ -> nil
    end
  end

  defp normalize_key_index(_value), do: nil
end
