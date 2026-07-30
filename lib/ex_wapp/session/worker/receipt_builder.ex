defmodule ExWapp.Session.Worker.ReceiptBuilder do
  @moduledoc """
  Builds receipt and retry-receipt nodes for inbound message acknowledgement.
  """

  require Logger

  alias ExWapp.{Binary, Log, Prekeys, Store}
  alias ExWapp.Session.Account
  alias ExWapp.Session.Worker.Subscribers
  alias ExWapp.Signal.Keys

  @spec build_receipt_ack(
          String.t(),
          String.t(),
          String.t() | nil,
          String.t() | nil,
          map() | nil
        ) ::
          Binary.Node.t()
  def build_receipt_ack(to, id, participant, type, receipt_meta) do
    attrs = %{
      "id" => id,
      "to" => to
    }

    attrs = if type, do: Map.put(attrs, "type", type), else: attrs
    attrs = if participant, do: Map.put(attrs, "participant", participant), else: attrs
    attrs = maybe_put_receipt_recipient(attrs, receipt_meta)

    %Binary.Node{
      tag: "receipt",
      attrs: attrs,
      content: nil
    }
  end

  @typedoc """
  What a retry receipt is about: who to answer, which message, and why.

  Grouped rather than passed positionally — `nil, nil, 2, nil` at a call site
  says nothing about which field is which.
  """
  @type retry_receipt :: %{
          required(:to) => String.t(),
          required(:id) => String.t(),
          optional(:participant) => String.t() | nil,
          optional(:message_t) => String.t() | integer() | nil,
          optional(:retry_count) => non_neg_integer() | nil,
          optional(:error_code) => integer() | nil,
          optional(:retry_meta) => map() | nil
        }

  @spec build_retry_receipt_ack(Store.t(), retry_receipt(), map()) :: Binary.Node.t()
  def build_retry_receipt_ack(store, receipt, session_ctx \\ %{}) do
    %{to: to, id: id} = receipt
    participant = Map.get(receipt, :participant)
    message_t = Map.get(receipt, :message_t)
    retry_count = Map.get(receipt, :retry_count)
    error_code = Map.get(receipt, :error_code)
    retry_meta = Map.get(receipt, :retry_meta)

    attrs = %{
      "id" => id,
      "to" => to,
      "type" => "retry"
    }

    attrs = if participant, do: Map.put(attrs, "participant", participant), else: attrs
    attrs = maybe_put_retry_recipient(attrs, retry_meta)
    attrs = maybe_put_retry_category(attrs, retry_meta)

    retry_attrs =
      %{
        "v" => "1",
        "id" => id,
        "t" => retry_timestamp(message_t),
        "count" => Integer.to_string(max(retry_count || 1, 1))
      }
      |> maybe_put_retry_error(error_code)

    retry_node = %Binary.Node{
      tag: "retry",
      attrs: retry_attrs,
      content: nil
    }

    content =
      case local_registration_node(store) do
        nil -> [retry_node]
        registration_node -> [retry_node, registration_node]
      end

    content =
      if retry_keys_needed?(retry_count, retry_meta) do
        case local_retry_keys_node(store, session_ctx) do
          {:ok, keys_node} ->
            content ++ [keys_node]

          {:error, reason} ->
            Logger.warning("[SESSION] Retry keys unavailable: #{Log.reason(reason)}")
            content
        end
      else
        content
      end

    %Binary.Node{
      tag: "receipt",
      attrs: attrs,
      content: content
    }
  end

  # -- Internal helpers -------------------------------------------------------

  defp maybe_put_retry_error(attrs, error_code) when is_integer(error_code) and error_code >= 0 do
    Map.put(attrs, "error", Integer.to_string(error_code))
  end

  defp maybe_put_retry_error(attrs, _), do: attrs

  defp maybe_put_receipt_recipient(attrs, %{recipient: recipient})
       when is_binary(recipient) and recipient != "" do
    Map.put(attrs, "recipient", recipient)
  end

  defp maybe_put_receipt_recipient(attrs, _), do: attrs

  defp maybe_put_retry_recipient(attrs, %{recipient: recipient})
       when is_binary(recipient) and recipient != "" do
    Map.put(attrs, "recipient", recipient)
  end

  defp maybe_put_retry_recipient(attrs, _), do: attrs

  defp maybe_put_retry_category(attrs, %{category: category})
       when is_binary(category) and category != "" do
    Map.put(attrs, "category", category)
  end

  defp maybe_put_retry_category(attrs, _), do: attrs

  defp retry_timestamp(message_t) when is_binary(message_t) and message_t != "", do: message_t
  defp retry_timestamp(message_t) when is_integer(message_t), do: Integer.to_string(message_t)
  defp retry_timestamp(_), do: Integer.to_string(System.system_time(:second))

  # A plain retry asks the peer to send the same ciphertext again, which is worth
  # doing when the failure was transient. It is worthless when the peer built
  # that ciphertext against key material this device cannot produce: the resend
  # is byte-identical and fails identically, and the pair burns its retry budget
  # discovering that. Those failures are told apart upstream, and they get the
  # key bundle on the first receipt instead of the second — that bundle is the
  # only thing that moves the peer onto a session this device can open.
  defp retry_keys_needed?(retry_count, %{force_keys?: true}) when is_integer(retry_count),
    do: true

  defp retry_keys_needed?(retry_count, _retry_meta) when is_integer(retry_count),
    do: retry_count >= 2

  defp retry_keys_needed?(_retry_count, _retry_meta), do: false

  defp local_retry_keys_node(nil, _session_ctx), do: {:error, :missing_store}

  defp local_retry_keys_node(store, session_ctx) do
    data = Store.load!(store)
    signal = Map.get(data, :signal, %{})

    with {:ok, identity_pub} <- local_identity_public(signal),
         {:ok, signed_prekey} <- local_signed_prekey(signal),
         {:ok, device_identity_node} <- Account.get_device_identity_node(store),
         %Binary.Node{content: %Binary.Raw{data: device_identity_payload}} <-
           device_identity_node,
         {:ok, prekey_id, prekey_public} <- generate_retry_prekey(store, session_ctx, signal) do
      type_node = %Binary.Node{tag: "type", attrs: %{}, content: Binary.raw(<<5>>)}

      identity_node = %Binary.Node{
        tag: "identity",
        attrs: %{},
        content: Binary.raw(identity_pub)
      }

      prekey_node = Account.prekey_to_node(prekey_id, prekey_public)
      signed_prekey_node = Account.signed_prekey_to_node(signed_prekey)

      keys_content = [
        type_node,
        identity_node,
        prekey_node,
        signed_prekey_node,
        %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: Binary.raw(device_identity_payload)
        }
      ]

      {:ok, %Binary.Node{tag: "keys", attrs: %{}, content: keys_content}}
    else
      {:error, reason} -> {:error, reason}
    end
  rescue
    error -> {:error, {:retry_keys_build_failed, error}}
  end

  defp local_identity_public(%{identity_key: %{public: pub}})
       when is_binary(pub) and byte_size(pub) == 32 do
    {:ok, pub}
  end

  defp local_identity_public(_), do: {:error, :missing_identity_public}

  defp local_signed_prekey(%{signed_prekeys: signed})
       when is_map(signed) and map_size(signed) > 0 do
    signed
    |> Enum.find(fn
      {id, %{public: pub, signature: sig}}
      when is_integer(id) and is_binary(pub) and byte_size(pub) == 32 and is_binary(sig) and
             byte_size(sig) == 64 ->
        true

      _ ->
        false
    end)
    |> case do
      {id, prekey} -> {:ok, Map.put(prekey, :id, id)}
      nil -> {:error, :missing_signed_prekey}
    end
  end

  defp local_signed_prekey(_), do: {:error, :missing_signed_prekey}

  defp generate_retry_prekey(store, session_ctx, signal) do
    runtime_cfg = Map.get(session_ctx, :runtime_cfg) || %{}

    # Reserved before the store transaction opens: an allocator that reaches an
    # external system has no business running inside the store's write owner.
    with {:ok, allocated_id} <- Prekeys.allocate_ids(runtime_cfg, signal, 1),
         {:ok, prekey_id, prekey_public} <- mint_retry_prekey(store, allocated_id) do
      announce_key_material(session_ctx, prekey_id)
      {:ok, prekey_id, prekey_public}
    end
  end

  # This key exists nowhere but the peer's copy of this receipt and the store's
  # last flush. A host that archives the store on a timer has a window in which
  # the key is live for the peer and absent from anything that survives the
  # process, and that window is precisely how a session becomes permanently
  # undecryptable. Saying so lets the host close it on the event instead of
  # guessing an interval short enough.
  defp announce_key_material(session_ctx, prekey_id) do
    case Map.get(session_ctx, :session_id) do
      session_id when is_binary(session_id) ->
        Subscribers.broadcast_lifecycle(
          session_id,
          {:ex_wapp_session, :key_material_advertised,
           %{session_id: session_id, reason: :retry_prekey, highest_prekey_id: prekey_id}}
        )

      _no_session ->
        :ok
    end
  end

  defp mint_retry_prekey(store, allocated_id) do
    result =
      Store.get_and_update(store, :signal, %{}, fn signal ->
        prekeys = if is_map(signal[:prekeys]), do: signal[:prekeys], else: %{}
        next_id = max(allocated_id, Prekeys.next_safe_id(signal, prekeys))
        prekey = Keys.generate_prekey(next_id)
        prekeys = Map.put(prekeys, next_id, prekey)

        updated_signal =
          signal
          |> Map.put(:prekeys, prekeys)
          |> Map.put(:next_prekey_id, next_id + 1)
          |> Map.put(:updated_at, System.system_time(:second))
          |> Prekeys.advertise_ids([next_id])

        {{:ok, next_id, prekey.public}, updated_signal}
      end)

    case result do
      {:ok, prekey_id, prekey_public} ->
        case Store.flush(store) do
          :ok ->
            {:ok, prekey_id, prekey_public}

          {:error, reason} ->
            {:error, {:retry_prekey_flush_failed, reason}}
        end

      {:error, _reason} = error ->
        error

      other ->
        {:error, {:retry_prekey_reservation_failed, other}}
    end
  end

  defp local_registration_node(store), do: Account.local_registration_node(store)
end
