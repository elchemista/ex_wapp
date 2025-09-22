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

  @version {2, 3000, 1_027_171_458}
  @version_string "2.3000.1027171458"

  @spec build(Noise.t()) :: {:ok, binary()} | {:ok, binary(), map()} | {:error, term()}
  def build(%Noise{store: store}) do
    data = Store.load!(store)

    with {:ok, signal_info, signal_state} <- ensure_signal_bundle(data) do
      info = Map.get(data, :client_info, %{})

      {phone_id, info} = ensure_phone_id(info)
      push_name = Map.get(info, :push_name, "ExWapp")

      payload = %ClientPayload{
        passive: false,
        pull: false,
        pushName: push_name,
        userAgent: build_user_agent(phone_id, info),
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

  def build(_), do: {:error, :invalid_noise_state}

  defp build_user_agent(phone_id, info) do
    {primary, secondary, tertiary} = @version

    %UserAgent{
      platform: :WEB,
      appVersion: %AppVersion{primary: primary, secondary: secondary, tertiary: tertiary},
      mcc: "000",
      mnc: "000",
      osVersion: Map.get(info, :os_version, "0.1.0"),
      manufacturer: Map.get(info, :manufacturer, ""),
      device: Map.get(info, :device_name, "Desktop"),
      osBuildNumber: Map.get(info, :os_build, "0.1.0"),
      phoneID: phone_id,
      releaseChannel: :RELEASE,
      localeLanguageIso6391: Map.get(info, :locale_language, "en"),
      localeCountryIso31661Alpha2: Map.get(info, :locale_country, "US"),
      deviceType: :DESKTOP,
      deviceModelType: Map.get(info, :device_model_type, "EX_WAPP")
    }
  end

  defp build_web_info(info) do
    %WebInfo{
      version: Map.get(info, :web_version, @version_string),
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

  defp ensure_phone_id(info) do
    case Map.get(info, :phone_id) do
      nil ->
        phone_id = generate_phone_id()
        {phone_id, Map.put(info, :phone_id, phone_id)}

      phone_id ->
        {phone_id, info}
    end
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

  # Encoded WACompanionReg.DeviceProps payload (whatsmeow default values).
  defp device_props do
    <<
      0x0A,
      0x09,
      "whatsmeow",
      0x12,
      0x06,
      0x08,
      0x00,
      0x10,
      0x01,
      0x18,
      0x00,
      0x18,
      0x00,
      0x20,
      0x00
    >>
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp generate_phone_id do
    16
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
