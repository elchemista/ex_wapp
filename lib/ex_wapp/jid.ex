defmodule ExWapp.JID do
  @moduledoc """
  Minimal representation of a WhatsApp JID.

  The implementation mirrors the pieces used by the binary encoder/decoder.
  """

  @default_user_server "s.whatsapp.net"
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
  def hidden_user_server, do: @hidden_user_server
  def hosted_server, do: @hosted_server
  def messenger_server, do: @messenger_server
  def interop_server, do: @interop_server

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
