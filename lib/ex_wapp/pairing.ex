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

    qr_event =
      case List.first(refs) do
        ref when is_binary(ref) -> [{:qr, qr_from_ref(state, ref)}]
        _ -> []
      end

    ack_attrs = %{
      "to" => Map.get(attrs, "from"),
      "id" => Map.get(attrs, "id"),
      "type" => "result"
    }

    ack_node = %Binary.Node{tag: "iq", attrs: ack_attrs, content: nil}

    # WhatsApp returns multiple refs, but only the first one should be shown
    # immediately. Emitting all refs at once causes invalid/stale QR scans.
    events = [{:send_node, ack_node}] ++ qr_event

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

        # from can be a JID struct or binary, both are valid for building ack
        ack =
          if valid_from?(from) and is_binary(id) do
            build_pair_success_ack(from, id, pairing_data)
          else
            Logger.warning("[PAIRING] Cannot build ack: from=#{inspect(from)}, id=#{inspect(id)}")
            nil
          end

        events = if(ack, do: [{:send_node, ack}], else: []) ++ [{:status, :success}]

        {%{state | status: :paired, ref: nil, req_id: nil}, events}

      {:error, reason} ->
        Logger.error("failed to persist pair-success data: #{inspect(reason)}")

        error_ack =
          if valid_from?(from) and is_binary(id) do
            build_pair_success_error_ack(from, id, reason)
          else
            nil
          end

        events =
          if error_ack,
            do: [{:send_node, error_ack}, error_event(reason)],
            else: [error_event(reason)]

        {state, events}
    end
  end

  # Check if from is valid - can be binary string or JID struct
  defp valid_from?(from) when is_binary(from), do: true
  defp valid_from?(%ExWapp.JID{}), do: true
  defp valid_from?(_), do: false

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

    # Only add "2@" prefix if not already present
    qr_ref = if String.starts_with?(ref, "2@"), do: ref, else: "2@" <> ref
    Enum.join([qr_ref, noise, identity, adv], ",")
  end

  def qr_from_ref(_state, ref), do: ref

  defp ensure_identity(data) do
    # IMPORTANT: Use the SAME identity that was sent during registration!
    # The signal.identity_key was sent to the server in the handshake payload.
    # Using a different identity for QR code will cause prekey upload to fail (406).
    case data do
      # First priority: use signal.identity_key (from registration handshake)
      %{signal: %{identity_key: %{public: pub, private: priv}}}
      when is_binary(pub) and byte_size(pub) == 32 ->
        identity = %{public: pub, private: priv}
        {Map.put(data, :identity, identity), pub}

      # Fallback: reuse existing pairing identity if signal is unavailable
      %{identity: %{public: pub, private: priv}}
      when is_binary(pub) and byte_size(pub) == 32 and
             is_binary(priv) and byte_size(priv) == 32 ->
        {data, pub}

      # Last resort: generate new identity (only if no signal state yet)
      _ ->
        %{public: pub, private: priv} = ExWapp.Signal.Keys.generate_key_pair()
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

    # NOTE: Pair-success `device-identity` is the incoming ADV payload, but in
    # upstream clients it is an ADVSignedDeviceIdentityHMAC container around the
    # inner ADVSignedDeviceIdentity. That is different from the direct
    # ADVSignedDeviceIdentity bytes we later send in pair-device-sign ACKs and
    # outbound message device-identity nodes.
    #
    # Pair-success persistence is the point where we decide whether the linked
    # device identity is trustworthy enough to survive reconnects. The ADV
    # parser must fully validate the HMAC/account signature chain before we
    # write pairing/signal state, otherwise the session may pair successfully
    # once and then be removed by the server on the first real login.

    with {:ok, device_identity} <- fetch_child_binary(node, "device-identity"),
         # Parse the pair-success ADV container and persist the self-signed form
         # returned by `ADV.parse_signed_device_identity/3` for the ACK.
         {:ok, adv_parsed} <- parse_adv_identity(data, device_identity),
         {:ok, device_attrs} <- fetch_child_attrs(node, "device"),
         {:ok, biz_attrs} <- fetch_child_attrs(node, "biz", optional: true),
         {:ok, platform_attrs} <- fetch_child_attrs(node, "platform", optional: true),
         # Keep Signal identity from current signal state when present.
         # Pair-success must not replace it with a stale QR identity.
         signal_with_identity = merge_pairing_identity(data),
         {:ok, signal_info, signal_state} <-
           Signal.bootstrap(%{
             device_identity: device_identity,
             adv_device_identity: device_identity,
             adv: adv_parsed,
             device_attrs: device_attrs,
             current_signal: signal_with_identity
           }) do
      pairing_data =
        %{
          device_identity: device_identity,
          adv_device_identity: device_identity,
          adv: adv_parsed,
          adv_self_signed: adv_parsed && Map.get(adv_parsed, :self_signed),
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
         {:ok, identity} <- fetch_identity_keypair(data) do
      ADV.parse_signed_device_identity(adv_identity, adv_secret, identity)
    end
  end

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

  # Preserve Signal identity from current signal state.
  # Only fall back to pairing identity when signal identity is missing.
  defp merge_pairing_identity(%{
         signal:
           %{
             identity_key: %{public: pub, private: priv} = identity
           } = signal
       })
       when is_binary(pub) and byte_size(pub) == 32 and
              is_binary(priv) and byte_size(priv) == 32 do
    Logger.debug("[PAIRING] Keeping existing Signal identity: #{Base.encode64(pub)}")
    Map.put(signal, :identity_key, identity)
  end

  defp merge_pairing_identity(%{
         identity: %{public: pub, private: priv} = identity,
         signal: signal
       })
       when is_binary(pub) and byte_size(pub) == 32 and
              is_binary(priv) and byte_size(priv) == 32 do
    Logger.warning(
      "[PAIRING] Signal identity missing, falling back to pairing identity: #{Base.encode64(pub)}"
    )

    Map.put(signal || %{}, :identity_key, identity)
  end

  defp merge_pairing_identity(%{
         identity: %{public: pub, private: priv} = identity
       })
       when is_binary(pub) and byte_size(pub) == 32 and
              is_binary(priv) and byte_size(priv) == 32 do
    Logger.warning(
      "[PAIRING] Signal identity missing, creating state from pairing identity: #{Base.encode64(pub)}"
    )

    %{identity_key: identity}
  end

  defp merge_pairing_identity(%{identity: identity}) do
    Logger.warning("[PAIRING] Invalid pairing identity: #{inspect(identity)}")
    %{}
  end

  defp merge_pairing_identity(_data), do: %{}

  defp error_event(reason), do: {:error, reason}

  defp build_pair_success_ack(from, id, pairing_data) do
    base_attrs = %{"to" => from, "type" => "result", "id" => id}

    case build_pair_device_sign(pairing_data) do
      {:ok, pair_device_sign} ->
        Logger.debug("[PAIRING] ✓ Built pair-device-sign for acknowledgment")
        %Binary.Node{tag: "iq", attrs: base_attrs, content: [pair_device_sign]}

      :error ->
        Logger.error(
          "[PAIRING] ✗ Failed to build pair-device-sign! Sending empty ack (will fail!)"
        )

        Logger.error("[PAIRING] pairing_data keys: #{inspect(Map.keys(pairing_data || %{}))}")

        Logger.error(
          "[PAIRING] adv_self_signed: #{inspect(pairing_data && Map.get(pairing_data, :adv_self_signed))}"
        )

        %Binary.Node{tag: "iq", attrs: base_attrs, content: nil}
    end
  end

  defp build_pair_device_sign(%{adv_self_signed: adv_self_signed} = pairing_data)
       when is_binary(adv_self_signed) do
    key_index =
      pairing_data
      |> extract_key_index()
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

  defp build_pair_success_error_ack(from, id, reason) do
    %Binary.Node{
      tag: "iq",
      attrs: %{"to" => from, "type" => "error", "id" => id},
      content: [
        %Binary.Node{
          tag: "error",
          attrs: pair_error_attrs(reason),
          content: nil
        }
      ]
    }
  end

  # whatsmeow reports signature/HMAC validation failures with 401 and uses a
  # generic internal-error for local parse/storage problems. Mirror that here so
  # bad pair-success payloads fail explicitly instead of receiving an empty
  # result IQ that leaves the next disconnect ambiguous.
  defp pair_error_attrs(:adv_hmac_mismatch), do: %{"code" => "401", "text" => "hmac-mismatch"}

  defp pair_error_attrs(:adv_invalid_account_signature),
    do: %{"code" => "401", "text" => "signature-mismatch"}

  defp pair_error_attrs(:adv_invalid_account_signature_fields),
    do: %{"code" => "401", "text" => "signature-mismatch"}

  defp pair_error_attrs(_reason), do: %{"code" => "500", "text" => "internal-error"}

  defp extract_key_index(%{adv: %{details: details}}) when is_map(details) do
    Map.get(details, :keyIndex) || Map.get(details, "keyIndex")
  end

  defp extract_key_index(_), do: nil

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
