defmodule ExWapp.Pairing do
  @moduledoc """
  Implements the QR-code based pairing handshake used by WhatsApp Web.
  """

  alias ExWapp.{Binary, Store}
  require Logger

  @typedoc """
  Aggregate structure that keeps temporary pairing data.
  """
  @type state :: %{
          status: :idle | :waiting_for_scan | :paired,
          ref: String.t() | nil,
          store: Store.t()
        }

  @doc """
  Returns the initial pairing state.
  """
  @spec new(Store.t()) :: state()
  def new(store) do
    %{status: :idle, ref: nil, store: store}
  end

  @doc """
  Applies a decoded node and returns the updated state plus pairing events.
  """
  @spec apply_node(state(), Binary.binary_node()) :: {state(), [term()]}
  def apply_node(state, %Binary.Node{tag: "iq", attrs: attrs, content: content} = node) do
    case find_child(content, "pair-device") do
      nil ->
        {state, []}

      pair_device ->
        handle_pair_device(state, node, attrs, pair_device)
    end
  end

  def apply_node(state, _other), do: {state, []}

  defp handle_pair_device(state, _node, attrs, pair_device) do
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

    new_state = %{state | status: :waiting_for_scan, ref: List.first(refs)}
    {new_state, events}
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
end
