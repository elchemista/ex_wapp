defmodule ExWapp.Session.Account do
  @moduledoc """
  Account/state helpers for session send flows.
  """

  require Logger

  alias ExWapp.{Binary, MapPath, Store}
  alias ExWapp.Session.JIDUtils

  def prekey_to_node(id, public)
      when is_integer(id) and id > 0 and is_binary(public) and byte_size(public) == 32 do
    <<_::8, id3::binary-3>> = <<id::big-32>>

    %Binary.Node{
      tag: "key",
      attrs: %{},
      content: [
        %Binary.Node{tag: "id", attrs: %{}, content: Binary.raw(id3)},
        %Binary.Node{tag: "value", attrs: %{}, content: Binary.raw(public)}
      ]
    }
  end

  def signed_prekey_to_node(%{id: id, public: public, signature: signature})
      when is_integer(id) and is_binary(public) and byte_size(public) == 32 and
             is_binary(signature) and byte_size(signature) == 64 do
    <<_::8, id3::binary-3>> = <<id::big-32>>

    %Binary.Node{
      tag: "skey",
      attrs: %{},
      content: [
        %Binary.Node{tag: "id", attrs: %{}, content: Binary.raw(id3)},
        %Binary.Node{tag: "value", attrs: %{}, content: Binary.raw(public)},
        %Binary.Node{tag: "signature", attrs: %{}, content: Binary.raw(signature)}
      ]
    }
  end

  def local_registration_node(nil), do: nil

  def local_registration_node(store) do
    data = Store.load!(store)

    registration_id =
      MapPath.first(data, [
        ["signal", "registration_id"],
        ["pairing", "signal", "registration_id"]
      ])

    if is_integer(registration_id) and registration_id >= 0 and registration_id <= 0xFFFFFFFF do
      %Binary.Node{
        tag: "registration",
        attrs: %{},
        content: Binary.raw(<<registration_id::32>>)
      }
    else
      nil
    end
  rescue
    _ -> nil
  end

  def load_lid_mapping(nil), do: %{}

  def load_lid_mapping(store) do
    store
    |> Store.load!()
    |> Map.get(:lid_mapping, %{})
  rescue
    _ -> %{}
  end

  def local_account_base_jid(nil), do: ""

  def local_account_base_jid(store) do
    data = Store.load!(store)

    data
    |> local_account_jid_value()
    |> JIDUtils.normalize_with_device()
    |> JIDUtils.strip_device()
  rescue
    _ -> ""
  end

  def local_account_device_id(nil), do: 0

  def local_account_device_id(store) do
    data = Store.load!(store)
    signal_device_id = MapPath.get(data, ["signal", "device_id"])

    case local_account_jid_value(data) do
      %ExWapp.JID{device: device} when is_integer(device) and device >= 0 ->
        device

      jid when is_binary(jid) ->
        JIDUtils.device_id(jid) || signal_device_id || 0

      _ ->
        signal_device_id || 0
    end
  rescue
    _ -> 0
  end

  def local_account_lid_jid(nil), do: ""

  def local_account_lid_jid(store) do
    data = Store.load!(store)

    data
    |> local_account_lid_value()
    |> JIDUtils.normalize_with_device()
    |> JIDUtils.strip_device()
  rescue
    _ -> ""
  end

  def local_account_sender_key_jid(nil), do: ""

  def local_account_sender_key_jid(store) do
    lid = local_account_lid_jid(store)
    if lid != "", do: lid, else: local_account_base_jid(store)
  end

  def local_account_sender_identity_for_destination(nil, _destination_jid), do: ""

  def local_account_sender_identity_for_destination(store, destination_jid) do
    destination_jid = JIDUtils.normalize_with_device(destination_jid)
    own_base = local_account_base_jid(store)
    own_lid = local_account_lid_jid(store)

    cond do
      JIDUtils.lid_jid?(destination_jid) and own_lid != "" ->
        own_lid

      own_base != "" ->
        own_base

      own_lid != "" ->
        own_lid

      true ->
        ""
    end
  end

  def maybe_append_tctoken(content, jid, store) do
    is_group = String.contains?(jid, "@g.us")

    if is_group do
      content
    else
      data = Store.load!(store)
      tctokens = Map.get(data, :tctokens, %{})

      case Map.get(tctokens, jid) do
        %{token: token} when is_binary(token) ->
          Logger.debug("[SEND] Appending tctoken for #{jid}")

          tctoken_node = %Binary.Node{
            tag: "tctoken",
            attrs: %{},
            content: Binary.raw(token)
          }

          content ++ [tctoken_node]

        _ ->
          content
      end
    end
  rescue
    _ -> content
  end

  def get_device_identity_node(store) do
    data = Store.load!(store)

    case Map.get(data, :pairing) do
      %{adv: %{signed: signed}} ->
        case ExWapp.Pairing.ADV.encode_signed_device_identity(
               signed,
               include_signature_key: true
             ) do
          {:ok, payload} ->
            Logger.info(
              "[SEND] Using ADV signed identity with accountSignatureKey: #{byte_size(payload)} bytes"
            )

            node = %Binary.Node{
              tag: "device-identity",
              attrs: %{},
              content: Binary.raw(payload)
            }

            {:ok, node}

          {:error, reason} ->
            Logger.warning(
              "[SEND] Failed to encode ADV signed identity, falling back: #{inspect(reason)}"
            )

            get_device_identity_node_fallback(data)
        end

      %{device_identity: device_identity} when is_binary(device_identity) ->
        Logger.info("[SEND] Found device_identity: #{byte_size(device_identity)} bytes")

        node = %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: Binary.raw(device_identity)
        }

        {:ok, node}

      %{adv_device_identity: adv_identity} when is_binary(adv_identity) ->
        Logger.info("[SEND] Found adv_device_identity: #{byte_size(adv_identity)} bytes")

        node = %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: Binary.raw(adv_identity)
        }

        {:ok, node}

      _ ->
        get_device_identity_node_fallback(data)
    end
  end

  defp get_device_identity_node_fallback(data) do
    case Map.get(data, :pairing) do
      %{device_identity: device_identity} when is_binary(device_identity) ->
        Logger.info(
          "[SEND] Falling back to raw device_identity: #{byte_size(device_identity)} bytes"
        )

        node = %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: Binary.raw(device_identity)
        }

        {:ok, node}

      %{adv_device_identity: adv_identity} when is_binary(adv_identity) ->
        Logger.info(
          "[SEND] Falling back to raw adv_device_identity: #{byte_size(adv_identity)} bytes"
        )

        node = %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: Binary.raw(adv_identity)
        }

        {:ok, node}

      _ ->
        Logger.warning("[SEND] No device identity found in pairing data")
        {:error, :no_device_identity}
    end
  end

  defp local_account_jid_value(data) do
    MapPath.first(data, [
      ["pairing", "device", "jid"],
      ["client_info", "jid"]
    ])
  end

  defp local_account_lid_value(data) do
    MapPath.first(data, [
      ["pairing", "device", "lid"],
      ["client_info", "lid"]
    ])
  end
end
