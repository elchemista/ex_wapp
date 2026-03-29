defmodule ExWapp.Session.Account do
  @moduledoc """
  Account/state helpers for session send flows.
  """

  require Logger

  alias ExWapp.{Binary, MapPath, Store}
  alias ExWapp.Pairing.ADV
  alias ExWapp.Session.JIDUtils

  @spec prekey_to_node(pos_integer(), binary()) :: Binary.Node.t()
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

  @spec signed_prekey_to_node(map()) :: Binary.Node.t()
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

  @spec local_registration_node(term()) :: Binary.Node.t() | nil
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
    e ->
      Logger.warning("[ACCOUNT] local_registration_node failed: #{inspect(e)}")
      nil
  end

  @spec load_lid_mapping(term()) :: map()
  def load_lid_mapping(nil), do: %{}

  def load_lid_mapping(store) do
    Store.get(store, :lid_mapping, %{})
  rescue
    e ->
      Logger.warning("[ACCOUNT] load_lid_mapping failed: #{inspect(e)}")
      %{}
  end

  @spec local_account_base_jid(term()) :: String.t()
  def local_account_base_jid(nil), do: ""

  def local_account_base_jid(store) do
    data = Store.load!(store)

    data
    |> local_account_jid_value()
    |> JIDUtils.normalize_with_device()
    |> JIDUtils.strip_device()
  rescue
    e ->
      Logger.warning("[ACCOUNT] local_account_base_jid failed: #{inspect(e)}")
      ""
  end

  @spec local_account_device_id(term()) :: non_neg_integer()
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
    e ->
      Logger.warning("[ACCOUNT] local_account_device_id failed: #{inspect(e)}")
      0
  end

  @spec local_account_lid_jid(term()) :: String.t()
  def local_account_lid_jid(nil), do: ""

  def local_account_lid_jid(store) do
    data = Store.load!(store)

    data
    |> local_account_lid_value()
    |> JIDUtils.normalize_with_device()
    |> JIDUtils.strip_device()
  rescue
    e ->
      Logger.warning("[ACCOUNT] local_account_lid_jid failed: #{inspect(e)}")
      ""
  end

  @spec local_account_sender_key_jid(term()) :: String.t()
  def local_account_sender_key_jid(nil), do: ""

  def local_account_sender_key_jid(store) do
    lid = local_account_lid_jid(store)
    if lid != "", do: lid, else: local_account_base_jid(store)
  end

  @spec local_account_sender_identity_for_destination(term(), String.t()) :: String.t()
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

  @spec maybe_append_tctoken(list(), String.t(), term()) :: list()
  def maybe_append_tctoken(content, jid, store) do
    if String.contains?(jid, "@g.us") do
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
    e ->
      Logger.warning("[ACCOUNT] maybe_append_tctoken failed: #{inspect(e)}")
      content
  end

  @spec get_device_identity_node(term()) ::
          {:ok, Binary.Node.t()} | {:error, term()}
  def get_device_identity_node(store) do
    data = Store.load!(store)

    case Map.get(data, :pairing) do
      %{adv: %{signed: signed}} ->
        case ADV.encode_signed_device_identity(
               signed,
               include_signature_key: true
             ) do
          {:ok, payload} ->
            Logger.debug(
              "[SEND] Using ADV signed identity with accountSignatureKey: #{byte_size(payload)} bytes"
            )

            {:ok, build_device_identity_node(payload)}

          {:error, reason} ->
            Logger.warning(
              "[SEND] Failed to encode ADV signed identity, falling back: #{inspect(reason)}"
            )

            get_device_identity_node_fallback(data)
        end

      pairing ->
        build_device_identity_from_raw(pairing)
    end
  end

  defp get_device_identity_node_fallback(data) do
    build_device_identity_from_raw(Map.get(data, :pairing))
  end

  defp build_device_identity_from_raw(%{device_identity: di}) when is_binary(di) do
    Logger.debug("[SEND] Using raw device_identity: #{byte_size(di)} bytes")
    {:ok, build_device_identity_node(di)}
  end

  defp build_device_identity_from_raw(%{adv_device_identity: adi}) when is_binary(adi) do
    Logger.debug("[SEND] Using raw adv_device_identity: #{byte_size(adi)} bytes")
    {:ok, build_device_identity_node(adi)}
  end

  defp build_device_identity_from_raw(_) do
    Logger.warning("[SEND] No device identity found in pairing data")
    {:error, :no_device_identity}
  end

  defp build_device_identity_node(payload) do
    %Binary.Node{
      tag: "device-identity",
      attrs: %{},
      content: Binary.raw(payload)
    }
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
