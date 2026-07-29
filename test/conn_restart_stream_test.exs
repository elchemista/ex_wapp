defmodule ExWapp.ConnRestartStreamTest do
  @moduledoc """
  Coverage for the `:restart_stream` cast in `ExWapp.Conn`.

  WebSockex accepts `{:ok, state}` or `{:reply, frame, state}` from
  `handle_cast/2` — a `{:noreply, state}` is a badreply that terminates the
  connection process, and a *list* of frames dies inside `Frame.encode_frame`
  and closes the socket. This handler used to return one or the other on every
  path, so any stream restart killed the connection it was trying to revive.
  """

  use ExUnit.Case, async: true

  alias ExWapp.Conn
  alias ExWapp.Conn.State
  alias ExWapp.Noise
  alias ExWapp.Store

  test "a restart in transport phase replies with exactly one frame tuple" do
    state = %State{
      session: self(),
      store: Store.new(Store.Memory),
      noise: transport_noise(),
      header_sent?: true,
      stream_started?: true
    }

    assert {:reply, {:binary, frame}, new_state} = Conn.handle_cast(:restart_stream, state)
    assert is_binary(frame)
    assert new_state.stream_started?
  end

  test "a restart before the handshake completes is acknowledged without a reply" do
    state = %State{session: self(), store: Store.new(Store.Memory), noise: nil}

    assert {:ok, new_state} = Conn.handle_cast(:restart_stream, state)
    refute new_state.stream_started?
  end

  defp transport_noise do
    %Noise{
      phase: :transport,
      cipher_ref: {
        %{key: :crypto.strong_rand_bytes(32), counter: 0},
        %{key: :crypto.strong_rand_bytes(32), counter: 0},
        :crypto.strong_rand_bytes(32)
      },
      tx_counter: 0,
      rx_counter: 0
    }
  end
end
