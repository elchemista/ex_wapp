defmodule ExWapp.Prekeys do
  @moduledoc """
  Handles prekey generation and upload to WhatsApp servers.

  Reference: whatsmeow/prekeys.go
  """

  require Logger
  alias ExWapp.{Binary, Store}
  alias ExWapp.Binary.Node

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

    initial_upload = Keyword.get(opts, :initial, false)
    prekey_count = if initial_upload, do: @initial_prekey_count, else: @wanted_prekey_count

    Logger.debug("[PREKEYS] Building upload, signal keys: #{inspect(Map.keys(signal))}")

    with {:ok, registration_id} <- get_registration_id(signal),
         {:ok, identity_pub} <- get_identity_public(signal, data),
         {:ok, signed_prekey} <- get_signed_prekey(signal),
         {:ok, prekeys} <- generate_prekeys(signal, prekey_count) do
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

      Logger.info(
        "[PREKEYS] Built upload for #{length(prekeys)} prekeys (initial=#{initial_upload})"
      )

      {:ok, node, prekeys}
    end
  end

  @doc """
  Check if prekeys need to be uploaded based on server response.
  """
  def needs_upload?(server_count, local_count) do
    server_count < @min_prekey_count or local_count < @min_prekey_count
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

  defp generate_prekeys(signal, count) do
    # Get current prekey ID or start from 1
    start_id = Map.get(signal, :next_prekey_id, 1)

    prekeys =
      for i <- 0..(count - 1) do
        key_id = start_id + i
        {pub, priv} = :crypto.generate_key(:ecdh, :x25519)

        %{
          key_id: key_id,
          public: pub,
          private: priv
        }
      end

    {:ok, prekeys}
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
end
