defmodule ExWapp.Noise.ClientPayload do
  @moduledoc false

  alias ExWapp.Noise
  alias ExWapp.Signal
  alias ExWapp.Store
  alias WAWebProtobufsWa6.ClientPayload
  alias WAWebProtobufsWa6.ClientPayload.UserAgent
  alias WAWebProtobufsWa6.ClientPayload.UserAgent.AppVersion
  alias WAWebProtobufsWa6.ClientPayload.WebInfo
  alias WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData

  @version {2, 3000, 1_029_948_479}
  @version_string "2.3000.1029948479"

  @spec build(Noise.t()) :: {:ok, binary()} | {:ok, binary(), map()} | {:error, term()}
  def build(%Noise{store: store}) do
    data = Store.load!(store)

    # Check if we're already paired (have a JID stored)
    case get_in(data, [:pairing, :device, "jid"]) do
      %ExWapp.JID{} = jid ->
        # Already paired - use login payload
        build_login_payload(data, jid)

      _ ->
        # Not paired - use registration payload
        build_registration_payload(data)
    end
  end

  defp build_login_payload(data, jid) do
    require Logger
    Logger.info("[ClientPayload] Building LOGIN payload for #{inspect(jid)}")

    info = Map.get(data, :client_info, %{})

    # Match Go's getLoginPayload() - must include lidDbMigrated!
    payload = %ClientPayload{
      username: jid_to_username(jid),
      device: jid.device,
      passive: true,
      pull: true,
      lidDbMigrated: true,
      userAgent: build_user_agent(nil, info),
      webInfo: build_web_info(info),
      connectType: :WIFI_UNKNOWN,
      connectReason: :USER_ACTIVATED
    }

    with {:ok, iodata} <- ClientPayload.encode(payload) do
      binary = IO.iodata_to_binary(iodata)
      {:ok, binary}
    end
  end

  defp build_registration_payload(data) do
    require Logger
    Logger.info("[ClientPayload] Building REGISTRATION payload")

    with {:ok, signal_info, signal_state} <- ensure_signal_bundle(data) do
      info = Map.get(data, :client_info, %{})

      # Match Go's getRegistrationPayload() exactly
      payload = %ClientPayload{
        passive: false,
        pull: false,
        userAgent: build_user_agent(nil, info),
        webInfo: build_web_info(info),
        devicePairingData: build_device_pairing_data(signal_info),
        connectType: :WIFI_UNKNOWN,
        connectReason: :USER_ACTIVATED
      }

      with {:ok, iodata} <- ClientPayload.encode(payload) do
        binary = IO.iodata_to_binary(iodata)

        updated_data =
          data
          |> Map.put(:client_info, info)
          |> Map.put(:signal, signal_state)

        {:ok, binary, updated_data}
      end
    end
  end

  defp jid_to_username(%ExWapp.JID{user: user}) when is_binary(user) do
    case Integer.parse(user) do
      {num, ""} -> num
      _ -> 0
    end
  end

  defp jid_to_username(_), do: 0

  def build(_), do: {:error, :invalid_noise_state}

  defp build_user_agent(_phone_id, info) do
    {primary, secondary, tertiary} = @version

    # Match Go's BaseClientPayload.UserAgent exactly
    %UserAgent{
      platform: :WEB,
      appVersion: %AppVersion{primary: primary, secondary: secondary, tertiary: tertiary},
      mcc: "000",
      mnc: "000",
      osVersion: Map.get(info, :os_version, "0.1"),
      manufacturer: Map.get(info, :manufacturer, ""),
      device: Map.get(info, :device_name, "Desktop"),
      osBuildNumber: Map.get(info, :os_build, "0.1"),
      releaseChannel: :RELEASE,
      localeLanguageIso6391: Map.get(info, :locale_language, "en"),
      localeCountryIso31661Alpha2: Map.get(info, :locale_country, "US")
      # Note: Go doesn't set phoneID, deviceType, or deviceModelType
    }
  end

  defp build_web_info(_info) do
    # Match Go's BaseClientPayload.WebInfo - only webSubPlatform is set
    %WebInfo{
      webSubPlatform: :WEB_BROWSER
    }
  end

  defp ensure_signal_bundle(data) do
    params =
      %{}
      |> maybe_put(:current_signal, Map.get(data, :signal))
      |> maybe_put(:device_attrs, get_in(data, [:pairing, :device]))

    Signal.bootstrap(params)
  end

  defp build_device_pairing_data(%{
         registration_id: registration_id,
         identity_key: identity_key,
         signed_prekey: %{id: signed_id, public: signed_pub, signature: signed_sig}
       }) do
    %DevicePairingRegistrationData{
      eRegid: encode_registration_id(registration_id),
      eKeytype: <<5>>,
      eIdent: identity_key,
      eSkeyID: encode_signed_prekey_id(signed_id),
      eSkeyVal: signed_pub,
      eSkeySig: signed_sig,
      buildHash: version_hash(),
      deviceProps: device_props()
    }
  end

  defp encode_registration_id(registration_id) when is_integer(registration_id) do
    <<registration_id::unsigned-big-size(32)>>
  end

  defp encode_signed_prekey_id(id) when is_integer(id) and id >= 0 do
    <<id::unsigned-big-size(32)>>
    |> binary_part(1, 3)
  end

  defp version_hash do
    :crypto.hash(:md5, @version_string)
  end

  # Encoded WACompanionReg.DeviceProps payload
  # This must match what whatsmeow sends - it's critical for pairing
  defp device_props do
    # DeviceProps proto (from WACompanionReg.proto):
    # - os: string (field 1)
    # - version: AppVersion (field 2)
    #   - primary: uint32 (field 1)
    #   - secondary: uint32 (field 2)
    #   - tertiary: uint32 (field 3)
    # - platformType: enum (field 3) - UNKNOWN = 0
    # - requireFullSync: bool (field 4) - false
    # - historySyncConfig: message (field 5)
    #   - storageQuotaMb: uint32 (field 3) - 10240
    #   - inlineInitialPayloadInE2EeMsg: bool (field 4) - true
    #   - supportCallLogHistory: bool (field 6) - false
    #   - supportBotUserAgentChatHistory: bool (field 7) - true
    #   - supportCagReactionsAndPolls: bool (field 8) - true
    #   - supportBizHostedMsg: bool (field 9) - true
    #   - supportRecentSyncChunkMessageCountTuning: bool (field 10) - true
    #   - supportHostedGroupMsg: bool (field 11) - true
    #   - supportFbidBotChatHistory: bool (field 12) - true
    #   - supportMessageAssociation: bool (field 14) - true
    #   - supportGroupHistory: bool (field 15) - false

    # Build version submessage: {primary: 0, secondary: 1, tertiary: 0}
    version = <<0x08, 0x00, 0x10, 0x01, 0x18, 0x00>>

    # Build historySyncConfig submessage
    history_sync_config =
      <<
        # storageQuotaMb = 10240 (field 3)
        0x18,
        0x80,
        0x50,
        # inlineInitialPayloadInE2EeMsg = true (field 4)
        0x20,
        0x01,
        # supportCallLogHistory = false (field 6)
        0x30,
        0x00,
        # supportBotUserAgentChatHistory = true (field 7)
        0x38,
        0x01,
        # supportCagReactionsAndPolls = true (field 8)
        0x40,
        0x01,
        # supportBizHostedMsg = true (field 9)
        0x48,
        0x01,
        # supportRecentSyncChunkMessageCountTuning = true (field 10)
        0x50,
        0x01,
        # supportHostedGroupMsg = true (field 11)
        0x58,
        0x01,
        # supportFbidBotChatHistory = true (field 12)
        0x60,
        0x01,
        # supportMessageAssociation = true (field 14)
        0x70,
        0x01,
        # supportGroupHistory = false (field 15)
        0x78,
        0x00
      >>

    # Build DeviceProps message
    os_name = "ExWapp"
    os_len = byte_size(os_name)
    version_len = byte_size(version)
    history_len = byte_size(history_sync_config)

    <<
      # os = "ExWapp" (field 1, wire type 2)
      0x0A,
      os_len::8,
      os_name::binary,
      # version (field 2, wire type 2)
      0x12,
      version_len::8,
      version::binary,
      # platformType = UNKNOWN (0) (field 3, wire type 0)
      0x18,
      0x00,
      # requireFullSync = false (field 4, wire type 0)
      0x20,
      0x00,
      # historySyncConfig (field 5, wire type 2)
      0x2A,
      history_len::8,
      history_sync_config::binary
    >>
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
