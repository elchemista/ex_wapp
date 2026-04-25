defmodule ExWapp.Client.Transport.Noop do
  @moduledoc """
  Default high-level transport adapter.

  It intentionally does not perform network IO. Configure a transport adapter in
  real applications.
  """

  @behaviour ExWapp.Client.Transport

  alias ExWapp.{Client, Message}

  @impl true
  @spec connect(Client.t()) :: {:error, :missing_transport}
  def connect(_client), do: {:error, :missing_transport}

  @impl true
  @spec send_message(Client.t(), Message.t()) :: {:error, :missing_transport}
  def send_message(_client, _message), do: {:error, :missing_transport}
end
