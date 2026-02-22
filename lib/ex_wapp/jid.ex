defmodule ExWapp.JID do
  @moduledoc """
  Minimal representation of a WhatsApp JID.

  The implementation mirrors the pieces used by the binary encoder/decoder.
  """

  @default_user_server "s.whatsapp.net"
  @group_server "g.us"
  @broadcast_server "broadcast"
  @hidden_user_server "lid"
  @messenger_server "msgr"
  @interop_server "interop"
  @hosted_server "hosted"

  defstruct user: "", raw_agent: 0, device: 0, integrator: 0, server: @default_user_server

  @type t :: %__MODULE__{
          user: String.t(),
          raw_agent: non_neg_integer(),
          device: non_neg_integer(),
          integrator: non_neg_integer(),
          server: String.t()
        }

  def default_user_server, do: @default_user_server
  def group_server, do: @group_server
  def broadcast_server, do: @broadcast_server
  def hidden_user_server, do: @hidden_user_server
  def hosted_server, do: @hosted_server
  def messenger_server, do: @messenger_server
  def interop_server, do: @interop_server

  @doc "Checks if a JID string represents a group."
  @spec group?(String.t() | t()) :: boolean()
  def group?(%__MODULE__{server: server}), do: server == @group_server
  def group?(jid) when is_binary(jid), do: String.ends_with?(jid, "@" <> @group_server)
  @deprecated "Use group?/1 instead."
  # credo:disable-for-next-line Credo.Check.Readability.PredicateFunctionNames
  def is_group?(jid), do: group?(jid)

  @doc "Checks if a JID string represents a broadcast list."
  @spec broadcast?(String.t() | t()) :: boolean()
  def broadcast?(%__MODULE__{server: server}), do: server == @broadcast_server
  def broadcast?(jid) when is_binary(jid), do: String.ends_with?(jid, "@" <> @broadcast_server)
  @deprecated "Use broadcast?/1 instead."
  # credo:disable-for-next-line Credo.Check.Readability.PredicateFunctionNames
  def is_broadcast?(jid), do: broadcast?(jid)

  @doc "Checks if a JID string represents a regular user."
  @spec user?(String.t() | t()) :: boolean()
  def user?(%__MODULE__{server: server}), do: server == @default_user_server
  def user?(jid) when is_binary(jid), do: String.ends_with?(jid, "@" <> @default_user_server)
  @deprecated "Use user?/1 instead."
  # credo:disable-for-next-line Credo.Check.Readability.PredicateFunctionNames
  def is_user?(jid), do: user?(jid)

  @doc "Parses a JID string into a struct."
  @spec parse(String.t()) :: {:ok, t()} | {:error, :invalid_jid}
  def parse(jid) when is_binary(jid) do
    case String.split(jid, "@") do
      [user, server] ->
        {user, device} = parse_user_device(user)
        {:ok, %__MODULE__{user: user, device: device, server: server}}

      [server] ->
        {:ok, %__MODULE__{user: "", server: server}}

      _ ->
        {:error, :invalid_jid}
    end
  end

  defp parse_user_device(user) do
    case String.split(user, ":") do
      [u, d] -> {u, String.to_integer(d)}
      [u] -> {u, 0}
    end
  end

  def new(user, server), do: %__MODULE__{user: user, server: server}

  def new_ad(user, agent, device) do
    {server, normalized_agent} =
      case agent do
        0 -> {@default_user_server, 0}
        1 -> {@hidden_user_server, 0}
        _ -> {@hosted_server, agent}
      end

    %__MODULE__{user: user, raw_agent: normalized_agent, device: device, server: server}
  end

  def actual_agent(%__MODULE__{server: @default_user_server}), do: 0
  def actual_agent(%__MODULE__{server: @hidden_user_server}), do: 1
  def actual_agent(%__MODULE__{raw_agent: agent}), do: agent

  def with_device(%__MODULE__{} = jid, device) do
    %{jid | device: device}
  end

  def with_integrator(%__MODULE__{} = jid, integrator) do
    %{jid | integrator: integrator}
  end

  def empty?, do: %__MODULE__{}

  def to_string(%__MODULE__{user: user, server: server, raw_agent: 0, device: 0}) do
    if user == "" do
      server
    else
      user <> "@" <> server
    end
  end

  def to_string(%__MODULE__{user: user, raw_agent: agent, device: device, server: server}) do
    cond do
      agent == 0 and device == 0 ->
        user <> "@" <> server

      agent == 0 ->
        user <> ":" <> Integer.to_string(device) <> "@" <> server

      device == 0 ->
        user <> "." <> Integer.to_string(agent) <> "@" <> server

      true ->
        user <>
          "." <> Integer.to_string(agent) <> ":" <> Integer.to_string(device) <> "@" <> server
    end
  end
end

# Implement String.Chars protocol so JID can be used in string interpolation
defimpl String.Chars, for: ExWapp.JID do
  def to_string(jid), do: ExWapp.JID.to_string(jid)
end
