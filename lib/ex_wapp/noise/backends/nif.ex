defmodule ExWapp.Noise.Backends.Nif do
  @moduledoc """
  Noise backend backed by the Rust NIF implementation bundled with ExWapp.
  """

  @behaviour ExWapp.Noise.Backend

  alias ExWapp.Nif
  alias ExWapp.Noise.HandshakeSecrets

  @impl true
  def init_handshake(payload, static_key, _opts) do
    maybe_priv =
      case static_key do
        %{priv: priv} when is_binary(priv) -> priv
        %{priv: priv} when is_list(priv) -> :erlang.list_to_binary(priv)
        _ -> nil
      end

    case Nif.handshake_new(payload, maybe_priv) do
      {:error, reason} ->
        {:error, reason}

      {handshake_ref, client_hello, static_pub, static_priv} ->
        {:ok, handshake_ref, ensure_binary(client_hello),
         build_static_map(static_pub, static_priv)}
    end
  end

  @impl true
  def write_client_finish(handshake_ref, payload) do
    case Nif.handshake_client_finish(handshake_ref, payload) do
      {:error, reason} -> {:error, reason}
      bin when is_binary(bin) -> {:ok, handshake_ref, bin}
      list when is_list(list) -> {:ok, handshake_ref, :erlang.list_to_binary(list)}
    end
  end

  @impl true
  def complete_handshake(handshake_ref) do
    case Nif.handshake_finish(handshake_ref) do
      {:error, reason} -> {:error, reason}
      %ExWappNif.HandshakeSecrets{} = secrets -> {:ok, HandshakeSecrets.from_nif(secrets)}
    end
  end

  @impl true
  def setup_transport(%HandshakeSecrets{} = secrets) do
    case Nif.noise_cipher_new(secrets.write_key, secrets.read_key, secrets.handshake_hash) do
      {:error, reason} -> {:error, reason}
      cipher_ref -> {:ok, cipher_ref}
    end
  end

  @impl true
  def encrypt(cipher_ref, plaintext, _counter) do
    case Nif.noise_encrypt(cipher_ref, plaintext) do
      {:error, reason} -> {:error, reason}
      payload when is_binary(payload) -> {:ok, cipher_ref, payload}
      payload when is_list(payload) -> {:ok, cipher_ref, :erlang.list_to_binary(payload)}
    end
  end

  @impl true
  def decrypt(cipher_ref, ciphertext, _counter) do
    case Nif.noise_decrypt(cipher_ref, ciphertext) do
      {:error, reason} -> {:error, reason}
      plaintext when is_binary(plaintext) -> {:ok, cipher_ref, plaintext}
      plaintext when is_list(plaintext) -> {:ok, cipher_ref, :erlang.list_to_binary(plaintext)}
    end
  end

  defp build_static_map(static_pub, static_priv)
       when is_binary(static_pub) and is_binary(static_priv) do
    %{priv: static_priv, pub: static_pub}
  end

  defp build_static_map(static_pub, static_priv)
       when is_list(static_pub) or is_list(static_priv) do
    build_static_map(ensure_binary(static_pub), ensure_binary(static_priv))
  end

  defp build_static_map(_static_pub, _static_priv), do: nil

  defp ensure_binary(value) when is_binary(value), do: value
  defp ensure_binary(value) when is_list(value), do: :erlang.list_to_binary(value)
  defp ensure_binary(value), do: value
end
