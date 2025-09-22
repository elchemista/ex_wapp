defmodule ExWapp.Pairing do
  @moduledoc """
  Implements the QR-code based pairing handshake used by WhatsApp Web.
  """

  alias ExWapp.{Binary, Noise.Certificate, Signal, Store}
  alias WAAdv.{ADVDeviceIdentity, ADVSignedDeviceIdentity, ADVSignedDeviceIdentityHMAC}
  require Logger

  @adv_prefix_account_signature <<6, 0>>
  @adv_prefix_device_signature_generate <<6, 1>>
  @adv_hosted_prefix_device_identity_account_signature <<6, 5>>
  @adv_hosted_prefix_device_identity_device_signature_verification <<6, 6>>

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
    base_events =
      case {Map.get(attrs, "from"), Map.get(attrs, "id")} do
        {from, id} when is_binary(from) and is_binary(id) ->
          ack = %Binary.Node{
            tag: "iq",
            attrs: %{"to" => from, "type" => "result", "id" => id},
            content: nil
          }

          [{:send_node, ack}]

        _ ->
          []
      end

    case persist_pair_success(store, pair_success) do
      {:ok, data} ->
        :ok = Store.persist(store, data)
        {%{state | status: :paired, ref: nil, req_id: nil}, base_events ++ [{:status, :success}]}

      {:error, reason} ->
        Logger.error("failed to persist pair-success data: #{inspect(reason)}")
        {state, base_events ++ [error_event(reason)]}
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
         {:ok, device_attrs} <- fetch_child_attrs(node, "device"),
         {:ok, biz_attrs} <- fetch_child_attrs(node, "biz", optional: true),
         {:ok, platform_attrs} <- fetch_child_attrs(node, "platform", optional: true),
         {:ok, signal_info} <-
           Signal.bootstrap(%{
             device_identity: device_identity,
             adv_device_identity: adv_identity,
             device_attrs: device_attrs
           }) do
      pairing_data =
        %{
          device_identity: device_identity,
          adv_device_identity: adv_identity,
          device: device_attrs,
          biz: biz_attrs,
          platform: platform_attrs,
          paired_at: System.system_time(:second),
          signal: signal_info
        }

      {:ok, Map.put(data, :pairing, pairing_data)}
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

  defp error_event(reason), do: {:error, reason}
end
