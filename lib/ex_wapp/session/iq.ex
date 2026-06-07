defmodule ExWapp.Session.IQ do
  @moduledoc """
  Builders/parsers for IQ stanzas used in send session setup (USync + prekeys).
  """

  require Logger

  alias ExWapp.{Binary, JID}
  alias ExWapp.Session.JIDUtils

  @spec build_prekey_request(String.t() | [String.t()], String.t()) :: Binary.Node.t()
  def build_prekey_request(jid, message_id) when is_binary(jid) do
    build_prekey_request([jid], message_id)
  end

  def build_prekey_request(jids, message_id) when is_list(jids) do
    user_nodes =
      Enum.map(jids, fn jid ->
        %Binary.Node{
          tag: "user",
          attrs: %{"jid" => jid},
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

  @spec build_usync_device_query([String.t()], String.t()) :: Binary.Node.t()
  def build_usync_device_query(jids, message_id) when is_list(jids) do
    user_nodes =
      Enum.map(jids, fn jid ->
        %Binary.Node{
          tag: "user",
          attrs: %{"jid" => JIDUtils.strip_device(jid)},
          content: nil
        }
      end)

    %Binary.Node{
      tag: "iq",
      attrs: %{
        "id" => message_id,
        "xmlns" => "usync",
        "type" => "get",
        "to" => "s.whatsapp.net"
      },
      content: [
        %Binary.Node{
          tag: "usync",
          attrs: %{
            "sid" => random_sid(),
            "mode" => "query",
            "last" => "true",
            "index" => "0",
            "context" => "message"
          },
          content: [
            %Binary.Node{
              tag: "query",
              attrs: %{},
              content: [
                %Binary.Node{
                  tag: "devices",
                  attrs: %{"version" => "2"},
                  content: nil
                }
              ]
            },
            %Binary.Node{
              tag: "list",
              attrs: %{},
              content: user_nodes
            }
          ]
        }
      ]
    }
  end

  @doc """
  Builds the IQ stanza used to request WhatsApp media upload hosts.
  """
  @spec build_media_conn_query(String.t()) :: Binary.Node.t()
  def build_media_conn_query(message_id) when is_binary(message_id) do
    %Binary.Node{
      tag: "iq",
      attrs: %{
        "id" => message_id,
        "type" => "set",
        "xmlns" => "w:m",
        "to" => "s.whatsapp.net"
      },
      content: [
        %Binary.Node{
          tag: "media_conn",
          attrs: %{},
          content: nil
        }
      ]
    }
  end

  @doc """
  Parses a media connection response into upload/download host metadata.
  """
  @spec parse_media_conn_response(term()) :: {:ok, map()} | {:error, term()}
  def parse_media_conn_response(%Binary.Node{attrs: %{"type" => "result"}} = node) do
    case find_media_conn_node(node) do
      %Binary.Node{} = media_conn ->
        {:ok, media_conn_info(media_conn)}

      nil ->
        {:error, :media_conn_not_found}
    end
  end

  def parse_media_conn_response(%Binary.Node{attrs: %{"type" => "error"}} = node) do
    {:error, {:media_conn_error, node}}
  end

  def parse_media_conn_response(_), do: {:error, :invalid_media_conn_response}

  @spec parse_usync_device_response(term()) :: {:ok, map()} | {:error, term()}
  def parse_usync_device_response(%Binary.Node{
        tag: "iq",
        attrs: %{"type" => "result"},
        content: content
      })
      when is_list(content) do
    usync_node = find_child(content, "usync")
    list_node = if usync_node, do: find_child(usync_node.content || [], "list"), else: nil

    user_nodes =
      if list_node do
        (list_node.content || [])
        |> Enum.filter(&match?(%Binary.Node{tag: "user"}, &1))
      else
        []
      end

    device_map =
      Enum.reduce(user_nodes, %{}, fn user_node, acc ->
        case parse_user_device_list(user_node) do
          {base_jid, device_jids} -> Map.put(acc, base_jid, device_jids)
          nil -> acc
        end
      end)

    {:ok, device_map}
  end

  def parse_usync_device_response(%Binary.Node{attrs: %{"type" => "error"}} = node) do
    {:error, {:usync_error, node}}
  end

  def parse_usync_device_response(_), do: {:error, :invalid_usync_response}

  @spec parse_prekey_response(term()) :: {:ok, [map()]} | {:error, term()}
  def parse_prekey_response(%Binary.Node{
        tag: "iq",
        attrs: %{"type" => "result"},
        content: content
      })
      when is_list(content) do
    case find_child(content, "list") do
      %Binary.Node{content: users} when is_list(users) ->
        users
        |> parse_prekey_bundles_from_users()
        |> prekey_bundles_result()

      _ ->
        {:error, :no_list_in_response}
    end
  end

  def parse_prekey_response(%Binary.Node{attrs: %{"type" => "error"}} = node) do
    {:error, {:iq_error, node}}
  end

  def parse_prekey_response(_), do: {:error, :invalid_response}

  defp parse_prekey_bundles_from_users(users) when is_list(users) do
    users
    |> Enum.filter(&match?(%Binary.Node{tag: "user"}, &1))
    |> Enum.reduce([], &maybe_prepend_prekey_bundle/2)
    |> Enum.reverse()
  end

  defp maybe_prepend_prekey_bundle(user_node, acc) do
    case parse_user_prekey_bundle(user_node) do
      {:ok, bundle} ->
        device_jid =
          user_node
          |> extract_user_jid()
          |> JIDUtils.normalize_with_device()

        Logger.debug("[PREKEY] Parsed bundle for device_jid=#{inspect(device_jid)}")
        [Map.put(bundle, :device_jid, device_jid) | acc]

      {:error, reason} ->
        Logger.warning("[PREKEY] Skipping invalid bundle node: #{inspect(reason)}")
        acc
    end
  end

  defp prekey_bundles_result([]), do: {:error, :no_valid_bundles_in_response}
  defp prekey_bundles_result(bundles), do: {:ok, bundles}

  defp parse_user_prekey_bundle(%Binary.Node{attrs: _attrs, content: content})
       when is_list(content) do
    registration = find_child(content, "registration")
    registration_id = if registration, do: parse_binary_int(registration.content), else: 0

    identity = find_child(content, "identity")
    identity_key = if identity, do: extract_binary(identity.content), else: nil

    skey = find_child(content, "skey")
    signed_prekey = if skey, do: parse_signed_prekey_node(skey), else: nil

    key = find_child(content, "key")
    one_time_prekey = if key, do: parse_prekey_node(key), else: nil

    if identity_key && signed_prekey do
      Logger.debug(
        "[PREKEY] Bundle parsed: reg_id=#{registration_id} signed_prekey_id=#{signed_prekey.id} prekey_id=#{if(one_time_prekey, do: one_time_prekey.id, else: "none")}"
      )

      {:ok,
       %{
         registration_id: registration_id,
         identity_key: identity_key,
         signed_prekey: signed_prekey,
         prekey: one_time_prekey
       }}
    else
      {:error, :incomplete_bundle}
    end
  end

  defp parse_user_prekey_bundle(_), do: {:error, :invalid_user_node}

  defp parse_signed_prekey_node(%Binary.Node{content: content}) when is_list(content) do
    id_node = find_child(content, "id")
    value_node = find_child(content, "value")
    sig_node = find_child(content, "signature")

    id = if id_node, do: parse_key_id(id_node.content), else: 0
    public = if value_node, do: extract_binary(value_node.content), else: nil
    signature = if sig_node, do: extract_binary(sig_node.content), else: nil

    if public && signature do
      %{id: id, public: public, signature: signature}
    else
      nil
    end
  end

  defp parse_signed_prekey_node(_), do: nil

  defp parse_prekey_node(%Binary.Node{content: content}) when is_list(content) do
    id_node = find_child(content, "id")
    value_node = find_child(content, "value")

    id = if id_node, do: parse_key_id(id_node.content), else: 0
    public = if value_node, do: extract_binary(value_node.content), else: nil

    if public, do: %{id: id, public: public}, else: nil
  end

  defp parse_prekey_node(_), do: nil

  defp parse_user_device_list(user_node) do
    case extract_user_jid(user_node) do
      nil ->
        nil

      user_jid ->
        base_jid = JIDUtils.strip_device(user_jid)

        {user_part, server} =
          case String.split(base_jid, "@", parts: 2) do
            [user, srv] when user != "" and srv != "" -> {user, srv}
            _ -> {"", ""}
          end

        device_jids = extract_device_jids(user_node, user_part, server, base_jid)
        {base_jid, device_jids}
    end
  end

  defp extract_device_jids(user_node, user_part, server, base_jid) do
    devices_node = find_child(user_node.content || [], "devices")

    device_list_node =
      if devices_node, do: find_child(devices_node.content || [], "device-list")

    if valid_device_list?(device_list_node, user_part, server) do
      build_device_jids(device_list_node, user_part, server)
    else
      [base_jid]
    end
  end

  defp valid_device_list?(device_list_node, user_part, server) do
    not is_nil(device_list_node) and user_part != "" and server != ""
  end

  defp build_device_jids(device_list_node, user_part, server) do
    (device_list_node.content || [])
    |> Enum.filter(&match?(%Binary.Node{tag: "device"}, &1))
    |> Enum.map(fn device_node ->
      format_device_jid(user_part, server, parse_device_id(device_node))
    end)
  end

  defp format_device_jid(user_part, server, 0), do: "#{user_part}@#{server}"
  defp format_device_jid(user_part, server, device_id), do: "#{user_part}:#{device_id}@#{server}"

  defp parse_device_id(%Binary.Node{attrs: attrs}) do
    case Map.get(attrs || %{}, "id") do
      id when is_integer(id) -> id
      id when is_binary(id) -> parse_int_or_zero(id)
      _ -> 0
    end
  end

  defp parse_device_id(_), do: 0

  defp parse_int_or_zero(str) do
    case Integer.parse(str) do
      {parsed, ""} -> parsed
      _ -> 0
    end
  end

  defp extract_user_jid(%Binary.Node{attrs: attrs}) do
    case Map.get(attrs, "jid") do
      %JID{} = jid -> JID.to_string(jid)
      jid when is_binary(jid) -> jid
      _ -> nil
    end
  end

  defp find_child(content, tag) when is_list(content) do
    Enum.find(content, fn
      %Binary.Node{tag: ^tag} -> true
      _ -> false
    end)
  end

  defp find_child(_, _), do: nil

  @spec find_media_conn_node(term()) :: Binary.Node.t() | nil
  defp find_media_conn_node(%Binary.Node{tag: "media_conn"} = node), do: node

  defp find_media_conn_node(%Binary.Node{content: children}) when is_list(children) do
    Enum.find_value(children, &find_media_conn_node/1)
  end

  defp find_media_conn_node(_), do: nil

  @spec media_conn_info(Binary.Node.t()) :: %{auth: term(), hosts: [%{hostname: String.t()}]}
  defp media_conn_info(%Binary.Node{attrs: attrs, content: content}) do
    %{
      auth: Map.get(attrs, "auth"),
      hosts: media_hosts(content || [])
    }
  end

  @spec media_hosts([term()]) :: [%{hostname: String.t()}]
  defp media_hosts(children) when is_list(children) do
    children
    |> Enum.flat_map(&media_host/1)
  end

  @spec media_host(term()) :: [%{hostname: String.t()}]
  defp media_host(%Binary.Node{tag: "host", attrs: attrs}) do
    case Map.get(attrs || %{}, "hostname") || Map.get(attrs || %{}, "name") do
      hostname when is_binary(hostname) and hostname != "" -> [%{hostname: hostname}]
      _ -> []
    end
  end

  defp media_host(_), do: []

  defp extract_binary(nil), do: nil
  defp extract_binary(binary) when is_binary(binary), do: binary
  defp extract_binary({:raw, binary}), do: binary
  defp extract_binary(%Binary.Raw{data: binary}), do: binary
  defp extract_binary([item]), do: extract_binary(item)
  defp extract_binary(_), do: nil

  defp parse_binary_int(content) do
    case extract_binary(content) do
      nil ->
        0

      <<int::32>> ->
        int

      bin when is_binary(bin) and byte_size(bin) >= 4 ->
        <<int::32>> = binary_part(bin, 0, 4)
        int

      _ ->
        0
    end
  end

  defp parse_key_id(content) do
    case extract_binary(content) do
      nil -> 0
      <<id::24>> -> id
      <<_::8, id::24>> -> id
      bin when is_binary(bin) -> :binary.decode_unsigned(bin)
      _ -> 0
    end
  end

  defp random_sid do
    :crypto.strong_rand_bytes(12)
    |> Base.encode64(padding: false)
  end
end
