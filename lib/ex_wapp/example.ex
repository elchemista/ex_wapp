defmodule ExWapp.Example do
  @moduledoc """
  Minimal helper module for pairing and messaging during protocol debugging.

  This module intentionally stays small so the runtime behavior is easy to
  inspect when WhatsApp protocol details change.
  """

  alias ExWapp.Signal.Adapter, as: Signal

  @store_path "/tmp/ex_wapp/bot_session.etf"
  @store_dir "/tmp/ex_wapp"
  @qr_path "/tmp/whatsapp_qr.svg"

  @doc """
  Deletes local persisted state so the next run forces a fresh QR pairing.
  """
  def clear_session do
    case File.rm_rf(@store_dir) do
      {:ok, _} -> :ok
      {:error, reason, _path} -> {:error, reason}
    end
  end

  @doc """
  Starts a session, connects, and waits for QR pairing success.

  Returns `{:ok, session}` once paired and ready, otherwise `{:error, reason}`.
  """
  def run(opts \\ []) do
    File.mkdir_p!(Path.dirname(@store_path))

    store_opts = Keyword.get(opts, :store, {ExWapp.Store.Ets, path: @store_path})
    timeout_ms = Keyword.get(opts, :timeout_ms, 300_000)

    with {:ok, session} <- ExWapp.start_link(store: store_opts),
         :ok <- ExWapp.connect(session),
         :ok <- wait_for_pairing(session, timeout_ms) do
      {:ok, session}
    end
  end

  @doc """
  Waits for pairing events and saves each QR update to `#{@qr_path}`.
  """
  @spec wait_for_pairing(pid(), non_neg_integer()) :: :ok | {:error, term()}
  def wait_for_pairing(session, timeout_ms \\ 300_000) do
    started_at = System.monotonic_time(:millisecond)

    session
    |> ExWapp.qr_stream()
    |> Enum.reduce_while(:waiting, fn event, _acc ->
      elapsed = System.monotonic_time(:millisecond) - started_at

      cond do
        elapsed >= timeout_ms ->
          {:halt, {:error, :timeout}}

        true ->
          case event do
            {:code, code} ->
              _ = save_qr(code)
              {:cont, :waiting}

            :success ->
              {:halt, :ok}

            {:error, reason} ->
              {:halt, {:error, reason}}
          end
      end
    end)
  end

  @doc """
  Returns current Signal adapter info.
  """
  def signal_info, do: Signal.info()

  @doc """
  Explicitly selects the pure Elixir Signal implementation.
  """
  def use_elixir_signal, do: Signal.set_impl(:elixir)

  @doc """
  Backward-compatible helper. Native mode is not available anymore.
  """
  def use_native_signal, do: Signal.set_impl(:native)

  @doc """
  Small smoke test for keygen/signature functions.
  """
  def test_signal do
    {pub, priv} = Signal.generate_key_pair()
    {spk_pub, _spk_priv, sig} = Signal.generate_signed_prekey(priv)

    %{
      impl: Signal.get_impl(),
      identity_public_size: byte_size(pub),
      signed_prekey_public_size: byte_size(spk_pub),
      signature_size: byte_size(sig),
      signature_valid: Signal.verify_signature(pub, spk_pub, sig)
    }
  end

  @doc """
  Backward-compatible send helper.
  """
  def send_v2(session, jid, text, _device_id \\ nil) do
    ExWapp.send_message(session, jid, text)
  end

  @doc """
  Backward-compatible send helper.
  """
  def send_v3(session, jid, text) do
    ExWapp.send_message(session, jid, text)
  end

  @doc """
  Resolves your own user JID (without device suffix), when available.
  """
  def own_jid(session) do
    try do
      store = GenServer.call(session, :get_store)
      data = ExWapp.Store.load!(store)

      case get_in(data, [:pairing, :device, "jid"]) do
        %ExWapp.JID{user: user} when is_binary(user) ->
          {:ok, "#{user}@s.whatsapp.net"}

        jid when is_binary(jid) ->
          case String.split(jid, [":", "@"]) do
            [user | _] when user != "" -> {:ok, "#{user}@s.whatsapp.net"}
            _ -> {:error, :invalid_jid}
          end

        _ ->
          {:error, :jid_not_found}
      end
    catch
      _, _ -> {:error, :session_unavailable}
    end
  end

  defp save_qr(code) when is_binary(code) do
    code
    |> QRCode.create(:high)
    |> QRCode.render()
    |> QRCode.save(@qr_path)
  rescue
    _ -> {:error, :qr_render_failed}
  end
end
