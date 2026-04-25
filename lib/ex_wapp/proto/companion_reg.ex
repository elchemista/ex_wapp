defmodule ExWapp.Proto.CompanionReg.AppVersion do
  @moduledoc false

  defstruct primary: nil,
            secondary: nil,
            tertiary: nil

  @type t :: %__MODULE__{
          primary: non_neg_integer() | nil,
          secondary: non_neg_integer() | nil,
          tertiary: non_neg_integer() | nil
        }

  @spec encode(t()) :: {:ok, iodata()} | {:error, Exception.t()}
  def encode(%__MODULE__{} = msg) do
    {:ok, encode!(msg)}
  rescue
    e in [ArgumentError] -> {:error, e}
  end

  @spec encode!(t()) :: iodata()
  def encode!(%__MODULE__{} = msg) do
    []
    |> encode_uint32_field(1, msg.primary)
    |> encode_uint32_field(2, msg.secondary)
    |> encode_uint32_field(3, msg.tertiary)
  end

  @spec decode!(binary()) :: t()
  def decode!(bytes), do: parse_key_value(bytes, %__MODULE__{})

  defp parse_key_value(<<>>, msg), do: msg

  defp parse_key_value(bytes, msg) do
    {field, rest} =
      case Protox.Decode.parse_key(bytes) do
        {1, _, bytes} ->
          {value, rest} = Protox.Decode.parse_uint32(bytes)
          {[primary: value], rest}

        {2, _, bytes} ->
          {value, rest} = Protox.Decode.parse_uint32(bytes)
          {[secondary: value], rest}

        {3, _, bytes} ->
          {value, rest} = Protox.Decode.parse_uint32(bytes)
          {[tertiary: value], rest}

        {tag, wire_type, rest} ->
          {_value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)
          {[], rest}
      end

    parse_key_value(rest, struct(msg, field))
  end

  defp encode_uint32_field(acc, _tag, nil), do: acc

  defp encode_uint32_field(acc, tag, value) do
    [acc, Protox.Varint.encode(tag * 8), Protox.Encode.encode_uint32(value)]
  end
end

defmodule ExWapp.Proto.CompanionReg.HistorySyncConfig do
  @moduledoc false

  import Bitwise

  @history_sync_fields %{
    3 => {:uint32, :storage_quota_mb},
    4 => {:bool, :inline_initial_payload_in_e2ee_msg},
    6 => {:bool, :support_call_log_history},
    7 => {:bool, :support_bot_user_agent_chat_history},
    8 => {:bool, :support_cag_reactions_and_polls},
    9 => {:bool, :support_biz_hosted_msg},
    10 => {:bool, :support_recent_sync_chunk_message_count_tuning},
    11 => {:bool, :support_hosted_group_msg},
    12 => {:bool, :support_fbid_bot_chat_history},
    14 => {:bool, :support_message_association},
    15 => {:bool, :support_group_history}
  }

  defstruct storage_quota_mb: nil,
            inline_initial_payload_in_e2ee_msg: nil,
            support_call_log_history: nil,
            support_bot_user_agent_chat_history: nil,
            support_cag_reactions_and_polls: nil,
            support_biz_hosted_msg: nil,
            support_recent_sync_chunk_message_count_tuning: nil,
            support_hosted_group_msg: nil,
            support_fbid_bot_chat_history: nil,
            support_message_association: nil,
            support_group_history: nil

  @type t :: %__MODULE__{
          storage_quota_mb: non_neg_integer() | nil,
          inline_initial_payload_in_e2ee_msg: boolean() | nil,
          support_call_log_history: boolean() | nil,
          support_bot_user_agent_chat_history: boolean() | nil,
          support_cag_reactions_and_polls: boolean() | nil,
          support_biz_hosted_msg: boolean() | nil,
          support_recent_sync_chunk_message_count_tuning: boolean() | nil,
          support_hosted_group_msg: boolean() | nil,
          support_fbid_bot_chat_history: boolean() | nil,
          support_message_association: boolean() | nil,
          support_group_history: boolean() | nil
        }

  @spec encode(t()) :: {:ok, iodata()} | {:error, Exception.t()}
  def encode(%__MODULE__{} = msg) do
    {:ok, encode!(msg)}
  rescue
    e in [ArgumentError] -> {:error, e}
  end

  @spec encode!(t()) :: iodata()
  def encode!(%__MODULE__{} = msg) do
    []
    |> encode_uint32_field(3, msg.storage_quota_mb)
    |> encode_bool_field(4, msg.inline_initial_payload_in_e2ee_msg)
    |> encode_bool_field(6, msg.support_call_log_history)
    |> encode_bool_field(7, msg.support_bot_user_agent_chat_history)
    |> encode_bool_field(8, msg.support_cag_reactions_and_polls)
    |> encode_bool_field(9, msg.support_biz_hosted_msg)
    |> encode_bool_field(10, msg.support_recent_sync_chunk_message_count_tuning)
    |> encode_bool_field(11, msg.support_hosted_group_msg)
    |> encode_bool_field(12, msg.support_fbid_bot_chat_history)
    |> encode_bool_field(14, msg.support_message_association)
    |> encode_bool_field(15, msg.support_group_history)
  end

  @spec decode!(binary()) :: t()
  def decode!(bytes), do: parse_key_value(bytes, %__MODULE__{})

  defp parse_key_value(<<>>, msg), do: msg

  defp parse_key_value(bytes, msg) do
    {field, rest} = parse_history_sync_field(bytes)

    parse_key_value(rest, struct(msg, field))
  end

  defp parse_history_sync_field(bytes) do
    case Protox.Decode.parse_key(bytes) do
      {tag, _, bytes} when is_map_key(@history_sync_fields, tag) ->
        parse_known_history_sync_field(bytes, Map.fetch!(@history_sync_fields, tag))

      {tag, wire_type, rest} ->
        parse_unknown_field(tag, wire_type, rest)
    end
  end

  defp parse_known_history_sync_field(bytes, {:uint32, field_name}),
    do: parse_uint32_field(bytes, field_name)

  defp parse_known_history_sync_field(bytes, {:bool, field_name}),
    do: parse_bool_field(bytes, field_name)

  defp encode_uint32_field(acc, _tag, nil), do: acc

  defp encode_uint32_field(acc, tag, value) do
    [acc, encode_key(tag, 0), Protox.Encode.encode_uint32(value)]
  end

  defp encode_bool_field(acc, _tag, nil), do: acc

  defp encode_bool_field(acc, tag, value) do
    [acc, encode_key(tag, 0), Protox.Encode.encode_bool(value)]
  end

  defp parse_uint32_field(bytes, field_name) do
    {value, rest} = Protox.Decode.parse_uint32(bytes)
    {[{field_name, value}], rest}
  end

  defp parse_bool_field(bytes, field_name) do
    {value, rest} = Protox.Decode.parse_bool(bytes)
    {[{field_name, value}], rest}
  end

  defp parse_unknown_field(tag, wire_type, rest) do
    {_value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)
    {[], rest}
  end

  defp encode_key(tag, wire_type), do: Protox.Varint.encode(bsl(tag, 3) + wire_type)
end

defmodule ExWapp.Proto.CompanionReg.DeviceProps do
  @moduledoc false

  import Bitwise

  alias ExWapp.Proto.CompanionReg.AppVersion
  alias ExWapp.Proto.CompanionReg.HistorySyncConfig

  defstruct os: nil,
            version: nil,
            platform_type: nil,
            require_full_sync: nil,
            history_sync_config: nil

  @type t :: %__MODULE__{
          os: binary() | nil,
          version: AppVersion.t() | nil,
          platform_type: non_neg_integer() | nil,
          require_full_sync: boolean() | nil,
          history_sync_config: HistorySyncConfig.t() | nil
        }

  @spec encode(t()) :: {:ok, iodata()} | {:error, Exception.t()}
  def encode(%__MODULE__{} = msg) do
    {:ok, encode!(msg)}
  rescue
    e in [ArgumentError] -> {:error, e}
  end

  @spec encode!(t()) :: iodata()
  def encode!(%__MODULE__{} = msg) do
    []
    |> encode_string_field(1, msg.os)
    |> encode_message_field(2, msg.version, &AppVersion.encode!/1)
    |> encode_uint32_field(3, msg.platform_type)
    |> encode_bool_field(4, msg.require_full_sync)
    |> encode_message_field(5, msg.history_sync_config, &HistorySyncConfig.encode!/1)
  end

  @spec decode!(binary()) :: t()
  def decode!(bytes), do: parse_key_value(bytes, %__MODULE__{})

  defp parse_key_value(<<>>, msg), do: msg

  defp parse_key_value(bytes, msg) do
    {field, rest} =
      case Protox.Decode.parse_key(bytes) do
        {1, _, bytes} ->
          {len, bytes} = Protox.Varint.decode(bytes)
          {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
          {[os: delimited], rest}

        {2, _, bytes} ->
          {len, bytes} = Protox.Varint.decode(bytes)
          {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
          {[version: AppVersion.decode!(delimited)], rest}

        {3, _, bytes} ->
          {value, rest} = Protox.Decode.parse_uint32(bytes)
          {[platform_type: value], rest}

        {4, _, bytes} ->
          {value, rest} = Protox.Decode.parse_bool(bytes)
          {[require_full_sync: value], rest}

        {5, _, bytes} ->
          {len, bytes} = Protox.Varint.decode(bytes)
          {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
          {[history_sync_config: HistorySyncConfig.decode!(delimited)], rest}

        {tag, wire_type, rest} ->
          {_value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)
          {[], rest}
      end

    parse_key_value(rest, struct(msg, field))
  end

  defp encode_string_field(acc, _tag, nil), do: acc

  defp encode_string_field(acc, tag, value) do
    [acc, encode_key(tag, 2), Protox.Encode.encode_string(value)]
  end

  defp encode_uint32_field(acc, _tag, nil), do: acc

  defp encode_uint32_field(acc, tag, value) do
    [acc, encode_key(tag, 0), Protox.Encode.encode_uint32(value)]
  end

  defp encode_bool_field(acc, _tag, nil), do: acc

  defp encode_bool_field(acc, tag, value) do
    [acc, encode_key(tag, 0), Protox.Encode.encode_bool(value)]
  end

  defp encode_message_field(acc, _tag, nil, _encoder), do: acc

  defp encode_message_field(acc, tag, value, encoder) do
    encoded =
      value
      |> encoder.()
      |> IO.iodata_to_binary()

    [acc, encode_key(tag, 2), Protox.Encode.encode_bytes(encoded)]
  end

  defp encode_key(tag, wire_type), do: Protox.Varint.encode(bsl(tag, 3) + wire_type)
end
