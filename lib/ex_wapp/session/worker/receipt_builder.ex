defmodule ExWapp.Session.Worker.ReceiptBuilder do
  @moduledoc """
  Builds receipt and retry-receipt nodes for inbound message acknowledgement.
  """

  require Logger

  alias ExWapp.{Binary, Store}
  alias ExWapp.Session.Account
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

  @spec build_retry_receipt_ack(
          Store.t(),
          String.t(),
          String.t(),
          String.t() | nil,
          String.t() | integer() | nil,
          non_neg_integer() | nil,
          integer() | nil,
          map() | nil
        ) :: Binary.Node.t()
  def build_retry_receipt_ack(
        store,
        to,
        id,
        participant,
        message_t,
        retry_count,
        error_code,
        retry_meta
      ) do
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
      if retry_keys_needed?(retry_count) do
        case local_retry_keys_node(store) do
          {:ok, keys_node} ->
            content ++ [keys_node]

          {:error, reason} ->
            Logger.warning("[SESSION] Retry keys unavailable: #{inspect(reason)}")
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

  defp retry_keys_needed?(retry_count) when is_integer(retry_count), do: retry_count >= 2
  defp retry_keys_needed?(_), do: false

  defp local_retry_keys_node(nil), do: {:error, :missing_store}

  defp local_retry_keys_node(store) do
    data = Store.load!(store)
    signal = Map.get(data, :signal, %{})

    with {:ok, identity_pub} <- local_identity_public(signal),
         {:ok, signed_prekey} <- local_signed_prekey(signal),
         {:ok, prekey_id, prekey_public} <- generate_retry_prekey(store, data, signal),
         {:ok, device_identity_node} <- Account.get_device_identity_node(store),
         %Binary.Node{content: %Binary.Raw{data: device_identity_payload}} <-
           device_identity_node do
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

  defp generate_retry_prekey(store, data, signal) do
    next_id =
      cond do
        is_integer(signal[:next_prekey_id]) and signal[:next_prekey_id] > 0 ->
          signal[:next_prekey_id]

        is_map(signal[:prekeys]) and map_size(signal[:prekeys]) > 0 ->
          signal[:prekeys] |> Map.keys() |> Enum.max() |> Kernel.+(1)

        true ->
          1
      end

    prekey = Keys.generate_prekey(next_id)
    prekeys = Map.get(signal, :prekeys, %{}) |> Map.put(next_id, prekey)

    updated_signal =
      signal
      |> Map.put(:prekeys, prekeys)
      |> Map.put(:next_prekey_id, next_id + 1)
      |> Map.put(:updated_at, System.system_time(:second))

    :ok = Store.persist(store, Map.put(data, :signal, updated_signal))

    {:ok, next_id, prekey.public}
  end

  defp local_registration_node(store), do: Account.local_registration_node(store)
end
