defmodule ExWapp.Message.Handler.Common do
  @moduledoc false

  alias ExWapp.{Binary, Chat, JID}
  alias ExWapp.Binary.Node

  @spec update_stats(map(), atom()) :: map()
  def update_stats(state, key) when is_map(state) do
    stats = Map.get(state, :stats, %{})
    new_count = Map.get(stats, key, 0) + 1
    new_stats = Map.put(stats, key, new_count)
    Map.put(state, :stats, new_stats)
  end

  @spec find_child_node(term(), binary()) :: Node.t() | nil
  def find_child_node(content, tag) when is_list(content) do
    Enum.find(content, fn
      %Node{tag: ^tag} -> true
      _ -> false
    end)
  end

  def find_child_node(_, _), do: nil

  @spec parse_timestamp(term()) :: integer()
  def parse_timestamp(nil), do: System.system_time(:second)

  def parse_timestamp(ts) when is_binary(ts) do
    case Integer.parse(ts) do
      {int, _} -> int
      :error -> System.system_time(:second)
    end
  end

  def parse_timestamp(ts) when is_integer(ts), do: ts

  @spec upsert_chat_from_sync_attrs(pid() | struct(), map(), map()) :: :ok
  def upsert_chat_from_sync_attrs(target, attrs, extra_metadata \\ %{})

  def upsert_chat_from_sync_attrs(target, attrs, extra_metadata)
      when is_map(attrs) and is_map(extra_metadata) do
    jid =
      attrs
      |> find_first_attr(["jid", "id", "chat_jid"])
      |> normalize_jid()

    if jid != "" do
      metadata =
        %{}
        |> maybe_put_sync_metadata(:name, extract_sync_name(attrs))
        |> maybe_put_sync_metadata(
          :unread_count,
          extract_sync_non_neg_integer(attrs, ["count", "unread", "unread_count"])
        )
        |> maybe_put_sync_metadata(
          :last_message_timestamp,
          extract_sync_non_neg_integer(attrs, ["t", "last", "last_message_timestamp", "timestamp"])
        )
        |> maybe_put_sync_metadata(:pinned, extract_sync_boolean(attrs, ["pin", "pinned"]))
        |> maybe_put_sync_metadata(
          :archived,
          extract_sync_boolean(attrs, ["archive", "archived"])
        )
        |> maybe_put_sync_metadata(:is_group, JID.group?(jid))
        |> maybe_put_sync_mute(attrs)
        |> Map.merge(extra_metadata)

      Chat.merge_metadata(target, jid, metadata)
    end

    :ok
  end

  def upsert_chat_from_sync_attrs(_target, _attrs, _extra_metadata), do: :ok

  @spec extract_group_subject(term()) :: binary() | nil
  def extract_group_subject(content) when is_list(content) do
    create_node = find_child_node(content, "create")
    subject_node = find_child_node(content, "subject")

    create_group_node =
      case create_node do
        %Node{content: create_content} when is_list(create_content) ->
          find_child_node(create_content, "group")

        _ ->
          nil
      end

    first_non_empty([
      node_attr(subject_node, "subject"),
      node_attr(create_group_node, "subject"),
      node_attr(create_group_node, "name"),
      node_attr(create_node, "subject")
    ])
  end

  def extract_group_subject(_), do: nil

  @spec extract_group_event_timestamp(term()) :: integer() | nil
  def extract_group_event_timestamp(content) when is_list(content) do
    create_node = find_child_node(content, "create")
    subject_node = find_child_node(content, "subject")

    create_group_node =
      case create_node do
        %Node{content: create_content} when is_list(create_content) ->
          find_child_node(create_content, "group")

        _ ->
          nil
      end

    first_integer_value([
      node_attr(subject_node, "t"),
      node_attr(create_group_node, "creation"),
      node_attr(create_group_node, "t"),
      node_attr(create_node, "t")
    ])
  end

  def extract_group_event_timestamp(_), do: nil

  @spec normalize_optional_text(term()) :: binary() | nil
  def normalize_optional_text(%JID{} = jid), do: normalize_optional_text(JID.to_string(jid))

  def normalize_optional_text(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  def normalize_optional_text(_), do: nil

  @spec node_attr(term(), binary()) :: term()
  def node_attr(%Node{attrs: attrs}, key), do: Map.get(attrs, key)
  def node_attr(_, _), do: nil

  @spec parse_enc_version(term()) :: integer() | nil
  def parse_enc_version(version) when is_integer(version), do: version

  def parse_enc_version(version) when is_binary(version) do
    case Integer.parse(version) do
      {value, ""} -> value
      _ -> nil
    end
  end

  def parse_enc_version(_), do: nil

  @spec parse_non_neg_integer(term()) :: non_neg_integer() | nil
  def parse_non_neg_integer(value) when is_integer(value) and value >= 0, do: value

  def parse_non_neg_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed >= 0 -> parsed
      _ -> nil
    end
  end

  def parse_non_neg_integer(_), do: nil

  @spec normalize_content(term()) :: binary() | nil
  def normalize_content(%Binary.Raw{data: data}), do: data
  def normalize_content({:raw, data}) when is_binary(data), do: data
  def normalize_content(content) when is_binary(content), do: content
  def normalize_content([single]), do: normalize_content(single)

  def normalize_content(list) when is_list(list) do
    if Enum.all?(list, &is_integer/1), do: :erlang.list_to_binary(list), else: nil
  end

  def normalize_content(_), do: nil

  @spec chat_target(pid() | term(), map()) :: pid() | struct() | nil
  def chat_target(session, state) do
    case Map.get(state, :store) do
      nil -> if(is_pid(session), do: session, else: nil)
      %{__struct__: _} = store -> store
      _ -> if(is_pid(session), do: session, else: nil)
    end
  end

  @spec resolve_store_from_target(pid() | struct()) :: struct() | nil
  def resolve_store_from_target(%{__struct__: _} = store), do: store

  def resolve_store_from_target(pid) when is_pid(pid) do
    GenServer.call(pid, :get_store)
  catch
    :exit, _ -> nil
  end

  @spec first_non_empty(list()) :: binary() | nil
  def first_non_empty(values) when is_list(values) do
    Enum.find(values, fn
      value when is_binary(value) and value != "" -> true
      _ -> false
    end)
  end

  @spec normalize_jid_with_device(term()) :: binary()
  def normalize_jid_with_device(%JID{} = jid), do: normalize_jid_with_device(JID.to_string(jid))
  def normalize_jid_with_device(nil), do: ""

  def normalize_jid_with_device(jid) when is_binary(jid) do
    jid
    |> String.trim()
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
  end

  def normalize_jid_with_device(_), do: ""

  @spec strip_device_from_jid(term()) :: binary()
  def strip_device_from_jid(jid) when is_binary(jid), do: String.replace(jid, ~r/:(\d+)@/, "@")
  def strip_device_from_jid(_), do: ""

  @spec normalize_jid(term()) :: binary()
  def normalize_jid(%JID{} = jid), do: normalize_jid(JID.to_string(jid))
  def normalize_jid(nil), do: ""

  def normalize_jid(jid) when is_binary(jid) do
    jid
    |> String.replace("@whatsapp.net", "@s.whatsapp.net")
    |> then(fn value ->
      case String.split(value, "@", parts: 2) do
        [user, domain] -> Regex.replace(~r/:(\d+)$/, user, "") <> "@" <> domain
        _ -> value
      end
    end)
  end

  def normalize_jid(_), do: ""

  @spec lid_jid?(term()) :: boolean()
  def lid_jid?(jid) when is_binary(jid) do
    String.ends_with?(jid, "@lid") or String.ends_with?(jid, "@hosted.lid")
  end

  def lid_jid?(_), do: false

  defp maybe_put_sync_mute(metadata, attrs) do
    case extract_sync_integer(attrs, ["mute", "mute_t", "mute_until", "muted_until"]) do
      {:ok, value} when value > 0 -> Map.put(metadata, :muted_until, value)
      {:ok, _value} -> Map.put(metadata, :muted_until, nil)
      :error -> metadata
    end
  end

  defp maybe_put_sync_metadata(metadata, _key, nil), do: metadata
  defp maybe_put_sync_metadata(metadata, key, value), do: Map.put(metadata, key, value)

  defp extract_sync_name(attrs) when is_map(attrs) do
    attrs
    |> find_first_attr(["name", "display_name", "subject", "title"])
    |> normalize_optional_text()
  end

  defp find_first_attr(attrs, keys) when is_map(attrs) and is_list(keys) do
    Enum.find_value(keys, fn key ->
      case Map.get(attrs, key) do
        nil -> nil
        value -> value
      end
    end)
  end

  defp find_first_attr(_, _), do: nil

  defp extract_sync_non_neg_integer(attrs, keys) do
    case extract_sync_integer(attrs, keys) do
      {:ok, value} when value >= 0 -> value
      _ -> nil
    end
  end

  defp extract_sync_integer(attrs, keys) when is_map(attrs) and is_list(keys) do
    Enum.reduce_while(keys, :error, fn key, _acc ->
      case parse_sync_integer(Map.get(attrs, key)) do
        {:ok, value} -> {:halt, {:ok, value}}
        :error -> {:cont, :error}
      end
    end)
  end

  defp extract_sync_integer(_, _), do: :error

  defp extract_sync_boolean(attrs, keys) when is_map(attrs) and is_list(keys) do
    Enum.reduce_while(keys, nil, fn key, _acc ->
      case parse_sync_boolean(Map.get(attrs, key)) do
        {:ok, value} -> {:halt, value}
        :error -> {:cont, nil}
      end
    end)
  end

  defp extract_sync_boolean(_, _), do: nil

  defp first_integer_value(values) when is_list(values) do
    Enum.reduce_while(values, nil, fn value, _acc ->
      case parse_sync_integer(value) do
        {:ok, parsed} -> {:halt, parsed}
        :error -> {:cont, nil}
      end
    end)
  end

  defp parse_sync_integer(value) when is_integer(value), do: {:ok, value}

  defp parse_sync_integer(value) when is_binary(value) do
    value
    |> String.trim()
    |> Integer.parse()
    |> case do
      {parsed, _rest} -> {:ok, parsed}
      :error -> :error
    end
  end

  defp parse_sync_integer(_), do: :error

  defp parse_sync_boolean(value) when is_boolean(value), do: {:ok, value}
  defp parse_sync_boolean(1), do: {:ok, true}
  defp parse_sync_boolean(0), do: {:ok, false}

  defp parse_sync_boolean(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> parse_sync_boolean_string()
  end

  defp parse_sync_boolean(_), do: :error

  defp parse_sync_boolean_string(value) when value in ["1", "true", "yes", "on"], do: {:ok, true}

  defp parse_sync_boolean_string(value) when value in ["0", "false", "no", "off"],
    do: {:ok, false}

  defp parse_sync_boolean_string(_value), do: :error
end
