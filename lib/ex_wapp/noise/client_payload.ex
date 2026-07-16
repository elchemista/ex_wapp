defmodule ExWapp.Noise.ClientPayload do
  @moduledoc """
  Builds the protobuf client payload encrypted into the Noise handshake.

  It selects registration or login fields from persisted pairing state and
  returns updated client or Signal data when key material is initialized.
  """

  require Logger

  alias ExWapp.{Config, Log, MapPath, Noise}
  alias ExWapp.Proto.CompanionReg.AppVersion, as: CompanionAppVersion
  alias ExWapp.Proto.CompanionReg.DeviceProps, as: CompanionDeviceProps
  alias ExWapp.Proto.CompanionReg.HistorySyncConfig
  alias ExWapp.Signal
  alias ExWapp.Store
  alias WAWebProtobufsWa6.ClientPayload
  alias WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData
  alias WAWebProtobufsWa6.ClientPayload.UserAgent
  alias WAWebProtobufsWa6.ClientPayload.UserAgent.AppVersion
  alias WAWebProtobufsWa6.ClientPayload.WebInfo

  @spec build(Noise.t()) :: {:ok, binary()} | {:ok, binary(), map()} | {:error, term()}
  def build(%Noise{} = noise), do: build(noise, default_runtime_cfg())
  def build(_), do: {:error, :invalid_noise_state}

  @spec build(Noise.t(), map()) :: {:ok, binary()} | {:ok, binary(), map()} | {:error, term()}
  def build(%Noise{store: store}, runtime_cfg) when is_map(runtime_cfg) do
    data = Store.load!(store)

    Logger.debug(
      "[ClientPayload] Store loaded: keys=#{inspect(Map.keys(data))} has_pairing=#{is_map(Map.get(data, :pairing))} has_signal=#{is_map(Map.get(data, :signal))}"
    )

    case resolve_login_jid(data) do
      %ExWapp.JID{} = jid ->
        # Already paired - use login payload
        Logger.debug(
          "[ClientPayload] Building LOGIN payload for #{Log.reference(jid)} " <>
            "client_version=#{version_string(runtime_cfg)}"
        )

        build_login_payload(data, jid, runtime_cfg)

      other ->
        # Not paired - use registration payload
        Logger.debug(
          "[ClientPayload] Building REGISTRATION payload — no JID found (got #{Log.term_summary(other)})"
        )

        build_registration_payload(data, runtime_cfg)
    end
  end

  def build(_, _), do: {:error, :invalid_noise_state}

  defp build_login_payload(data, jid, runtime_cfg) do
    info =
      data
      |> resolve_client_info(runtime_cfg)
      |> Map.put(:jid, jid)

    # Match Go's getLoginPayload() - must include lidDbMigrated!
    payload = %ClientPayload{
      username: jid_to_username(jid),
      device: jid.device,
      passive: true,
      pull: true,
      lidDbMigrated: true,
      lc: 1,
      userAgent: build_user_agent(nil, info, runtime_cfg),
      webInfo: build_web_info(info, runtime_cfg),
      connectType: :WIFI_UNKNOWN,
      connectReason: :USER_ACTIVATED
    }

    with {:ok, iodata} <- ClientPayload.encode(payload) do
      binary = IO.iodata_to_binary(iodata)
      updated_data = Map.put(data, :client_info, info)
      {:ok, binary, updated_data}
    end
  end

  defp build_registration_payload(data, runtime_cfg) do
    Logger.debug(
      "[ClientPayload] Building REGISTRATION payload " <>
        "client_version=#{version_string(runtime_cfg)}"
    )

    with {:ok, signal_info, signal_state} <- ensure_signal_bundle(data) do
      info = resolve_client_info(data, runtime_cfg)

      # Match Go's getRegistrationPayload() exactly
      payload = %ClientPayload{
        passive: false,
        pull: false,
        userAgent: build_user_agent(nil, info, runtime_cfg),
        webInfo: build_web_info(info, runtime_cfg),
        devicePairingData: build_device_pairing_data(signal_info, runtime_cfg),
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

  defp resolve_login_jid(data) do
    data
    |> MapPath.first([
      ["pairing", "device", "jid"],
      ["client_info", "jid"]
    ])
    |> normalize_login_jid(MapPath.get(data, ["signal", "device_id"]))
  end

  defp normalize_login_jid(%ExWapp.JID{} = jid, device_id) do
    maybe_apply_device_id(jid, device_id)
  end

  defp normalize_login_jid(jid, device_id) when is_binary(jid) do
    jid
    |> normalize_jid_string()
    |> ExWapp.JID.parse()
    |> case do
      {:ok, parsed_jid} -> maybe_apply_device_id(parsed_jid, device_id)
      _ -> nil
    end
  end

  defp normalize_login_jid(_, _device_id), do: nil

  defp maybe_apply_device_id(%ExWapp.JID{device: 0} = jid, device_id)
       when is_integer(device_id) and device_id > 0 do
    ExWapp.JID.with_device(jid, device_id)
  end

  defp maybe_apply_device_id(%ExWapp.JID{} = jid, _device_id), do: jid

  defp normalize_jid_string(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
  end

  defp build_user_agent(_phone_id, info, runtime_cfg) do
    {primary, secondary, tertiary} = protocol_version(runtime_cfg)
    ua_defaults = Config.get(runtime_cfg, [:protocol, :user_agent], %{})

    # Web remains the compatibility default. Android mode mirrors the native
    # companion payload used by upstream clients and must not carry WebInfo.
    %UserAgent{
      platform: user_agent_platform(runtime_cfg),
      appVersion: %AppVersion{primary: primary, secondary: secondary, tertiary: tertiary},
      mcc: "000",
      mnc: "000",
      osVersion: Map.get(info, :os_version, Map.get(ua_defaults, :os_version, "Linux")),
      manufacturer: Map.get(info, :manufacturer, Map.get(ua_defaults, :manufacturer, "")),
      device: Map.get(info, :device_name, Map.get(ua_defaults, :device_name, "Desktop")),
      osBuildNumber: Map.get(info, :os_build, Map.get(ua_defaults, :os_build, "Linux")),
      releaseChannel: :RELEASE,
      localeLanguageIso6391:
        Map.get(info, :locale_language, Map.get(ua_defaults, :locale_language, "en")),
      localeCountryIso31661Alpha2:
        Map.get(info, :locale_country, Map.get(ua_defaults, :locale_country, "US"))
      # Note: Go doesn't set phoneID, deviceType, or deviceModelType
    }
  end

  defp resolve_client_info(data, runtime_cfg) do
    ua_defaults = Config.get(runtime_cfg, [:protocol, :user_agent], %{})

    data
    |> Map.get(:client_info, %{})
    |> put_default(:os_version, Map.get(ua_defaults, :os_version, "Linux"))
    |> put_default(:manufacturer, Map.get(ua_defaults, :manufacturer, ""))
    |> put_default(:device_name, Map.get(ua_defaults, :device_name, "Desktop"))
    |> put_default(:os_build, Map.get(ua_defaults, :os_build, "Linux"))
    |> put_default(:locale_language, Map.get(ua_defaults, :locale_language, "en"))
    |> put_default(:locale_country, Map.get(ua_defaults, :locale_country, "US"))
  end

  defp put_default(info, _key, nil), do: info

  defp put_default(info, key, default) do
    case Map.get(info, key) do
      nil -> Map.put(info, key, default)
      "" -> Map.put(info, key, default)
      _ -> info
    end
  end

  defp build_web_info(_info, runtime_cfg) do
    if client_mode(runtime_cfg) == :android do
      nil
    else
      web_info()
    end
  end

  defp web_info do
    # Match Go's BaseClientPayload.WebInfo - only webSubPlatform is set
    %WebInfo{
      webSubPlatform: :WEB_BROWSER
    }
  end

  defp user_agent_platform(runtime_cfg) do
    if client_mode(runtime_cfg) == :android, do: :ANDROID, else: :WEB
  end

  defp client_mode(runtime_cfg), do: Config.get(runtime_cfg, [:protocol, :client_mode], :web)

  defp ensure_signal_bundle(data) do
    params =
      %{}
      |> maybe_put(:current_signal, Map.get(data, :signal))
      |> maybe_put(:device_attrs, get_in(data, [:pairing, :device]))

    Signal.bootstrap(params)
  end

  defp build_device_pairing_data(
         %{
           registration_id: registration_id,
           identity_key: identity_key,
           signed_prekey: %{id: signed_id, public: signed_pub, signature: signed_sig}
         },
         runtime_cfg
       ) do
    %DevicePairingRegistrationData{
      eRegid: encode_registration_id(registration_id),
      eKeytype: <<5>>,
      eIdent: identity_key,
      eSkeyID: encode_signed_prekey_id(signed_id),
      eSkeyVal: signed_pub,
      eSkeySig: signed_sig,
      buildHash: version_hash(runtime_cfg),
      deviceProps: device_props(runtime_cfg)
    }
  end

  defp encode_registration_id(registration_id) when is_integer(registration_id) do
    <<registration_id::unsigned-big-size(32)>>
  end

  defp encode_signed_prekey_id(id) when is_integer(id) and id >= 0 do
    <<id::unsigned-big-size(32)>>
    |> binary_part(1, 3)
  end

  defp version_hash(runtime_cfg) do
    :crypto.hash(:md5, version_string(runtime_cfg))
  end

  defp default_runtime_cfg do
    case Config.resolve([]) do
      {:ok, cfg} -> cfg
      {:error, _} -> %{}
    end
  end

  defp protocol_version(runtime_cfg) do
    default_version = Config.default_client_version()

    primary =
      Config.get(runtime_cfg, [:protocol, :client_version, :primary], default_version.primary)

    secondary =
      Config.get(
        runtime_cfg,
        [:protocol, :client_version, :secondary],
        default_version.secondary
      )

    tertiary =
      Config.get(runtime_cfg, [:protocol, :client_version, :tertiary], default_version.tertiary)

    {primary, secondary, tertiary}
  end

  defp version_string(runtime_cfg) do
    {primary, secondary, tertiary} = protocol_version(runtime_cfg)
    "#{primary}.#{secondary}.#{tertiary}"
  end

  # Encoded WACompanionReg.DeviceProps payload
  # This must match what whatsmeow sends - it's critical for pairing
  defp device_props(runtime_cfg) do
    device_props = Config.get(runtime_cfg, [:protocol, :pairing_device_props], %{})

    %CompanionDeviceProps{
      os: Map.get(device_props, :os, "whatsmeow"),
      version: build_device_props_version(device_props),
      platform_type: pairing_platform_type(device_props, runtime_cfg),
      require_full_sync: Map.get(device_props, :require_full_sync, false),
      history_sync_config: build_history_sync_config(device_props)
    }
    |> CompanionDeviceProps.encode!()
    |> IO.iodata_to_binary()
  end

  # DeviceProps.PlatformType.ANDROID_PHONE is 16. In web mode keep the
  # configurable platform type exactly as before.
  defp pairing_platform_type(device_props, runtime_cfg)
       when is_map(runtime_cfg) do
    if client_mode(runtime_cfg) == :android do
      16
    else
      Map.get(device_props, :platform_type, 0)
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp build_device_props_version(device_props) do
    version = Map.get(device_props, :version, %{})

    %CompanionAppVersion{
      primary: Map.get(version, :primary, 0),
      secondary: Map.get(version, :secondary, 1),
      tertiary: Map.get(version, :tertiary, 0)
    }
  end

  defp build_history_sync_config(device_props) do
    config = Map.get(device_props, :history_sync_config, %{})

    %HistorySyncConfig{
      storage_quota_mb: Map.get(config, :storage_quota_mb, 10_240),
      inline_initial_payload_in_e2ee_msg:
        Map.get(config, :inline_initial_payload_in_e2ee_msg, true),
      support_call_log_history: Map.get(config, :support_call_log_history, false),
      support_bot_user_agent_chat_history:
        Map.get(config, :support_bot_user_agent_chat_history, true),
      support_cag_reactions_and_polls: Map.get(config, :support_cag_reactions_and_polls, true),
      support_biz_hosted_msg: Map.get(config, :support_biz_hosted_msg, true),
      support_recent_sync_chunk_message_count_tuning:
        Map.get(config, :support_recent_sync_chunk_message_count_tuning, true),
      support_hosted_group_msg: Map.get(config, :support_hosted_group_msg, true),
      support_fbid_bot_chat_history: Map.get(config, :support_fbid_bot_chat_history, true),
      support_message_association: Map.get(config, :support_message_association, true),
      support_group_history: Map.get(config, :support_group_history, false)
    }
  end
end
