defmodule ExWapp.Signal do
  @moduledoc """
  Manages Signal protocol key material and session state.

  The WhatsApp Web stack uses X3DH for session setup and the Double Ratchet
  for transport messages. This module generates the initial identity and
  pre-keys that must be published to the server and returns a structure that
  can be persisted by the store backend.
  """

  alias Ed25519

  @type identity_key :: %{public: binary(), private: binary()}
  @type signed_prekey :: %{
          id: pos_integer(),
          public: binary(),
          private: binary(),
          signature: binary()
        }
  @type one_time_prekey :: %{id: pos_integer(), public: binary(), private: binary()}
  @type signal_info :: %{
          registration_id: pos_integer(),
          device_id: non_neg_integer(),
          identity_key: binary(),
          signed_prekey: %{id: pos_integer(), public: binary(), signature: binary()},
          prekey: %{id: pos_integer(), public: binary()},
          bundle: map()
        }
  @type signal_state :: %{
          identity_key: identity_key(),
          registration_id: pos_integer(),
          device_id: non_neg_integer(),
          signed_prekeys: %{optional(pos_integer()) => signed_prekey()},
          prekeys: %{optional(pos_integer()) => one_time_prekey()},
          next_prekey_id: pos_integer(),
          sessions: map(),
          updated_at: integer()
        }

  @doc """
  Initialises local identity and pre-key material.

  Returns a tuple containing the published bundle information together with the
  internal state that should be persisted.
  """
  @spec bootstrap(map()) :: {:ok, signal_info(), signal_state()} | {:error, term()}
  def bootstrap(params) when is_map(params) do
    current = Map.get(params, :current_signal) || %{}
    now = System.system_time(:second)

    with {:ok, identity} <- ensure_identity(current, now),
         {:ok, registration_id} <- ensure_registration_id(current),
         {:ok, device_id} <- ensure_device_id(Map.get(params, :device_attrs), current),
         {:ok, signed_prekey, signed_map} <- ensure_signed_prekey(current, identity, now),
         {:ok, prekey, prekeys_map, next_prekey_id} <- ensure_one_time_prekey(current, now) do
      sessions = Map.get(current, :sessions) || %{}

      bundle = build_bundle(registration_id, device_id, identity, signed_prekey, prekey)

      info = %{
        registration_id: registration_id,
        device_id: device_id,
        identity_key: identity.public,
        signed_prekey: Map.take(signed_prekey, [:id, :public, :signature]),
        prekey: Map.take(prekey, [:id, :public]),
        bundle: bundle
      }

      state = %{
        identity_key: identity,
        registration_id: registration_id,
        device_id: device_id,
        signed_prekeys: signed_map,
        prekeys: prekeys_map,
        next_prekey_id: next_prekey_id,
        sessions: sessions,
        updated_at: now
      }

      {:ok, info, state}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def bootstrap(_), do: {:error, :invalid_parameters}

  defp ensure_identity(
         %{
           identity_key:
             %{public: <<_::binary-size(32)>>, private: <<_::binary-size(32)>>} = identity
         },
         _now
       ),
       do: {:ok, identity}

  defp ensure_identity(_current, now) do
    {priv, pub} = Ed25519.generate_key_pair()
    {:ok, %{public: pub, private: priv, generated_at: now}}
  end

  defp ensure_registration_id(%{registration_id: id})
       when is_integer(id) and id > 0 and id < 65_536,
       do: {:ok, id}

  defp ensure_registration_id(_current) do
    {:ok, :rand.uniform(65_535)}
  end

  defp ensure_device_id(%{} = attrs, _current) do
    attrs
    |> Map.get("device-id")
    |> case do
      nil -> attrs |> Map.get(:device_id) |> ensure_device_id(nil)
      value -> ensure_device_id(value, nil)
    end
  end

  defp ensure_device_id(value, _current) when is_integer(value) and value >= 0, do: {:ok, value}

  defp ensure_device_id(value, _current) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} when int >= 0 -> {:ok, int}
      _ -> {:ok, 0}
    end
  end

  defp ensure_device_id(_value, %{device_id: id}) when is_integer(id) and id >= 0, do: {:ok, id}
  defp ensure_device_id(_value, _current), do: {:ok, 0}

  defp ensure_signed_prekey(current, identity, now) do
    existing = Map.get(current, :signed_prekeys) || %{}

    case find_valid_signed_prekey(existing, identity.public) do
      {:ok, _id, key} ->
        {:ok, key, existing}

      :error ->
        id = next_identifier(existing, 1)
        {priv, pub} = Ed25519.generate_key_pair()
        signature = Ed25519.signature(pub, identity.private, identity.public)

        key = %{
          id: id,
          public: pub,
          private: priv,
          signature: signature,
          generated_at: now
        }

        {:ok, key, Map.put(existing, id, key)}
    end
  end

  defp ensure_one_time_prekey(current, now) do
    existing = Map.get(current, :prekeys) || %{}
    next_id_hint = Map.get(current, :next_prekey_id)

    case find_valid_prekey(existing) do
      {:ok, _id, key} ->
        next_id = next_id_hint || next_identifier(existing, key.id + 1)
        {:ok, key, existing, next_id}

      :error ->
        id = next_id_hint || next_identifier(existing, 1)
        {priv, pub} = Ed25519.generate_key_pair()

        key = %{
          id: id,
          public: pub,
          private: priv,
          generated_at: now
        }

        {:ok, key, Map.put(existing, id, key), id + 1}
    end
  end

  defp find_valid_signed_prekey(map, identity_pub) when is_map(map) do
    map
    |> Enum.find(fn
      {_,
       %{
         public: <<_::binary-size(32)>> = pub,
         private: <<_::binary-size(32)>>,
         signature: <<_::binary-size(64)>> = sig
       }} ->
        Ed25519.valid_signature?(sig, pub, identity_pub)

      _ ->
        false
    end)
    |> case do
      {id, key} -> {:ok, id, key}
      nil -> :error
    end
  end

  defp find_valid_prekey(map) when is_map(map) do
    map
    |> Enum.find(fn
      {_, %{public: <<_::binary-size(32)>>, private: <<_::binary-size(32)>>}} -> true
      _ -> false
    end)
    |> case do
      {id, key} -> {:ok, id, key}
      nil -> :error
    end
  end

  defp next_identifier(map, _default) when is_map(map) and map_size(map) > 0 do
    map
    |> Map.keys()
    |> Enum.max()
    |> Kernel.+(1)
  end

  defp next_identifier(_map, default), do: default

  defp build_bundle(registration_id, device_id, identity, signed_prekey, prekey) do
    %{
      registration_id: registration_id,
      device_id: device_id,
      identity_key: identity.public,
      signed_prekey: Map.take(signed_prekey, [:id, :public, :signature]),
      prekey: Map.take(prekey, [:id, :public]),
      type: :curve25519
    }
  end
end
