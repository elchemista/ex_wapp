defmodule ExWapp.Signal.PrekeyFetcher do
  @moduledoc """
  Fetches prekey bundles from WhatsApp server for establishing Signal sessions.
  """

  alias ExWapp.Binary

  require Logger

  @doc """
  Fetches prekey bundle for a recipient JID.

  Sends an IQ query and waits for the response.
  """
  @spec fetch_prekeys(pid(), String.t()) :: {:ok, map()} | {:error, term()}
  def fetch_prekeys(session, jid) do
    # Build the prekey request IQ
    message_id = generate_id()

    node = build_prekey_request(jid, message_id)

    Logger.debug("[PREKEY] Fetching prekeys for #{jid}")

    # Register for the response
    case GenServer.call(session, {:send_iq, node, message_id}, 30_000) do
      {:ok, response} ->
        parse_prekey_response(response)

      {:error, reason} ->
        Logger.error("[PREKEY] Failed to fetch prekeys: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches prekey bundles for multiple recipients at once.
  """
  @spec fetch_prekeys_batch(pid(), [String.t()]) ::
          {:ok, %{String.t() => map()}} | {:error, term()}
  def fetch_prekeys_batch(session, jids) when is_list(jids) do
    message_id = generate_id()

    node = build_batch_prekey_request(jids, message_id)

    Logger.debug("[PREKEY] Fetching prekeys for #{length(jids)} recipients")

    case GenServer.call(session, {:send_iq, node, message_id}, 30_000) do
      {:ok, response} ->
        parse_batch_prekey_response(response)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Build IQ node to request prekeys
  defp build_prekey_request(jid, message_id) do
    %Binary.Node{
      tag: "iq",
      attrs: %{
        "id" => message_id,
        "xmlns" => "encrypt",
        "type" => "get",
        "to" => "s.whatsapp.net"
      },
      content: [
        %Binary.Node{
          tag: "key",
          attrs: %{},
          content: [
            %Binary.Node{
              tag: "user",
              attrs: %{"jid" => normalize_jid(jid)},
              content: nil
            }
          ]
        }
      ]
    }
  end

  defp build_batch_prekey_request(jids, message_id) do
    user_nodes =
      Enum.map(jids, fn jid ->
        %Binary.Node{
          tag: "user",
          attrs: %{"jid" => normalize_jid(jid)},
          content: nil
        }
      end)

    %Binary.Node{
      tag: "iq",
      attrs: %{
        "id" => message_id,
        "xmlns" => "encrypt",
        "type" => "get",
        "to" => "s.whatsapp.net"
      },
      content: [
        %Binary.Node{
          tag: "key",
          attrs: %{},
          content: user_nodes
        }
      ]
    }
  end

  # Parse the prekey response from server
  defp parse_prekey_response(%Binary.Node{tag: "iq", content: content}) when is_list(content) do
    case find_child(content, "list") do
      %Binary.Node{content: users} when is_list(users) ->
        case Enum.find(users, &match?(%Binary.Node{tag: "user"}, &1)) do
          %Binary.Node{} = user_node ->
            parse_user_prekey(user_node)

          nil ->
            {:error, :no_prekeys_in_response}
        end

      _ ->
        {:error, :invalid_prekey_response}
    end
  end

  defp parse_prekey_response(_), do: {:error, :invalid_response}

  defp parse_batch_prekey_response(%Binary.Node{tag: "iq", content: content})
       when is_list(content) do
    case find_child(content, "list") do
      %Binary.Node{content: users} when is_list(users) ->
        {:ok, parse_batch_user_bundles(users)}

      _ ->
        {:error, :invalid_prekey_response}
    end
  end

  defp parse_batch_prekey_response(_), do: {:error, :invalid_response}

  defp parse_batch_user_bundles(users) when is_list(users) do
    Enum.reduce(users, %{}, &maybe_put_user_bundle/2)
  end

  defp maybe_put_user_bundle(%Binary.Node{tag: "user"} = user_node, acc) do
    jid = get_attr(user_node, "jid")

    case parse_user_prekey(user_node) do
      {:ok, bundle} -> Map.put(acc, jid, bundle)
      _ -> acc
    end
  end

  defp maybe_put_user_bundle(_other, acc), do: acc

  defp parse_user_prekey(%Binary.Node{attrs: attrs, content: content}) when is_list(content) do
    jid = Map.get(attrs, "jid")

    # Extract registration ID
    registration = find_child(content, "registration")
    registration_id = if registration, do: parse_registration_id(registration.content), else: 0

    # Extract identity key
    identity = find_child(content, "identity")
    identity_key = if identity, do: extract_binary_content(identity.content), else: nil

    # Extract type (should be 5 for Curve25519)
    type_node = find_child(content, "type")
    _key_type = if type_node, do: extract_binary_content(type_node.content), else: <<5>>

    # Extract signed prekey
    skey = find_child(content, "skey")
    signed_prekey = if skey, do: parse_signed_prekey(skey), else: nil

    # Extract one-time prekey (optional)
    key = find_child(content, "key")
    one_time_prekey = if key, do: parse_one_time_prekey(key), else: nil

    if identity_key && signed_prekey do
      bundle = %{
        jid: jid,
        registration_id: registration_id,
        identity_key: identity_key,
        signed_prekey: signed_prekey,
        prekey: one_time_prekey
      }

      Logger.debug(
        "[PREKEY] Got bundle for #{jid}: reg=#{registration_id}, spk_id=#{signed_prekey.id}"
      )

      {:ok, bundle}
    else
      Logger.warning("[PREKEY] Incomplete prekey bundle for #{jid}")
      {:error, :incomplete_bundle}
    end
  end

  defp parse_user_prekey(_), do: {:error, :invalid_user_node}

  defp parse_signed_prekey(%Binary.Node{content: content}) when is_list(content) do
    id_node = find_child(content, "id")
    value_node = find_child(content, "value")
    sig_node = find_child(content, "signature")

    id = if id_node, do: parse_key_id(id_node.content), else: 0
    public = if value_node, do: extract_binary_content(value_node.content), else: nil
    signature = if sig_node, do: extract_binary_content(sig_node.content), else: nil

    if public && signature do
      %{id: id, public: public, signature: signature}
    else
      nil
    end
  end

  defp parse_signed_prekey(_), do: nil

  defp parse_one_time_prekey(%Binary.Node{content: content}) when is_list(content) do
    id_node = find_child(content, "id")
    value_node = find_child(content, "value")

    id = if id_node, do: parse_key_id(id_node.content), else: 0
    public = if value_node, do: extract_binary_content(value_node.content), else: nil

    if public do
      %{id: id, public: public}
    else
      nil
    end
  end

  defp parse_one_time_prekey(_), do: nil

  defp parse_registration_id(content) do
    binary = extract_binary_content(content)

    if binary && byte_size(binary) >= 4 do
      <<reg_id::32>> = binary_part(binary, 0, 4)
      reg_id
    else
      0
    end
  end

  defp parse_key_id(content) do
    binary = extract_binary_content(content)

    if binary do
      # Key ID is 3 bytes, big endian
      case byte_size(binary) do
        3 ->
          <<id::24>> = binary
          id

        4 ->
          <<_::8, id::24>> = binary
          id

        _ ->
          :binary.decode_unsigned(binary)
      end
    else
      0
    end
  end

  defp extract_binary_content(nil), do: nil
  defp extract_binary_content(binary) when is_binary(binary), do: binary
  defp extract_binary_content({:raw, binary}) when is_binary(binary), do: binary
  defp extract_binary_content([{:raw, binary}]) when is_binary(binary), do: binary
  defp extract_binary_content([binary]) when is_binary(binary), do: binary
  defp extract_binary_content(_), do: nil

  defp find_child(content, tag) when is_list(content) do
    Enum.find(content, fn
      %Binary.Node{tag: ^tag} -> true
      _ -> false
    end)
  end

  defp get_attr(%Binary.Node{attrs: attrs}, key), do: Map.get(attrs, key)

  defp normalize_jid(jid) when is_binary(jid) do
    case String.split(jid, [":", "@"]) do
      [user, _device, domain] -> "#{user}@#{domain}"
      [user, domain] -> "#{user}@#{domain}"
      _ -> jid
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :upper)
  end
end
