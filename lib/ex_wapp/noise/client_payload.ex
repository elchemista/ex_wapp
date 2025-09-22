defmodule ExWapp.Noise.ClientPayload do
  @moduledoc false

  alias ExWapp.Noise
  alias ExWapp.Store
  alias WAWebProtobufsWa6.ClientPayload
  alias WAWebProtobufsWa6.ClientPayload.UserAgent
  alias WAWebProtobufsWa6.ClientPayload.UserAgent.AppVersion
  alias WAWebProtobufsWa6.ClientPayload.WebInfo

  @version {2, 3000, 1_027_171_458}
  @version_string "2.3000.1027171458"

  @spec build(Noise.t()) :: {:ok, binary()} | {:ok, binary(), map()} | {:error, term()}
  def build(%Noise{store: store}) do
    data = Store.load!(store)
    info = Map.get(data, :client_info, %{})

    {phone_id, info} = ensure_phone_id(info)
    push_name = Map.get(info, :push_name, "ExWapp")

    payload = %ClientPayload{
      passive: false,
      pull: false,
      pushName: push_name,
      userAgent: build_user_agent(phone_id, info),
      webInfo: build_web_info(info),
      connectType: :WIFI_UNKNOWN,
      connectReason: :USER_ACTIVATED
    }

    with {:ok, iodata} <- ClientPayload.encode(payload) do
      binary = IO.iodata_to_binary(iodata)
      {:ok, binary, Map.put(data, :client_info, info)}
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

  defp ensure_phone_id(info) do
    case Map.get(info, :phone_id) do
      nil ->
        phone_id = generate_phone_id()
        {phone_id, Map.put(info, :phone_id, phone_id)}

      phone_id ->
        {phone_id, info}
    end
  end

  defp generate_phone_id do
    16
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
