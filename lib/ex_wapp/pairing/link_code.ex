defmodule ExWapp.Pairing.LinkCode do
  @moduledoc """
  Implements WhatsApp's phone-number (link-code) companion pairing protocol.

  The request side wraps a fresh companion ephemeral public key with the
  eight-character pairing code. The finish side unwraps the primary phone's
  ephemeral key, derives the authenticated key bundle, rotates the ADV secret,
  and persists enough account state for the reconnect/login that follows.
  """

  import Bitwise

  alias ExWapp.{Binary, Config, Messages, Store}
  alias ExWapp.Binary.{Node, Raw}
  alias ExWapp.Signal.Keys

  @crockford_alphabet "123456789ABCDEFGHJKLMNPQRSTVWXYZ"
  @pairing_code_iterations 131_072
  @key_bundle_info "link_code_pairing_key_bundle_encryption_key"
  @adv_secret_info "adv_secret"
  @server_jid "s.whatsapp.net"

  @type request_result :: %{
          code: String.t(),
          jid: String.t(),
          request_id: String.t(),
          node: Node.t()
        }

  @type finish_result :: %{
          jid: String.t(),
          node: Node.t(),
          adv_secret: binary(),
          data: map()
        }

  @doc """
  Starts a link-code pairing request and persists its ephemeral credentials.

  A custom code follows the upstream contract: it must be exactly eight bytes.
  When omitted, five random bytes are encoded with WhatsApp's Crockford
  alphabet, producing an eight-character code.
  """
  @spec request(Store.t(), String.t(), keyword(), map()) ::
          {:ok, request_result()} | {:error, term()}
  def request(store, phone, opts \\ [], runtime_cfg \\ %{})

  def request(store, phone, opts, runtime_cfg)
      when is_binary(phone) and is_list(opts) and is_map(runtime_cfg) do
    with {:ok, normalized_phone} <- normalize_phone(phone),
         {:ok, code} <- build_pairing_code(Keyword.get(opts, :custom_code)),
         data when is_map(data) <- Store.load!(store),
         :ok <- ensure_unpaired(data),
         {:ok, identity} <- fetch_identity_keypair(data),
         {:ok, noise_public} <- fetch_noise_public(data),
         pairing_ephemeral <- Keys.generate_key_pair(),
         request_id <- Messages.generate_id(),
         wrapped <- wrap_companion_ephemeral(pairing_ephemeral.public, code),
         jid <- normalized_phone <> "@" <> @server_jid,
         node <-
           build_companion_hello(
             jid,
             request_id,
             wrapped,
             noise_public,
             runtime_cfg
           ),
         updated_data <-
           persist_pending_request(
             data,
             jid,
             code,
             request_id,
             pairing_ephemeral,
             identity
           ),
         :ok <- Store.persist(store, updated_data) do
      {:ok, %{code: code, jid: jid, request_id: request_id, node: node}}
    else
      {:error, _reason} = error -> error
    end
  rescue
    exception -> {:error, {:link_code_request_failed, exception}}
  end

  def request(_store, _phone, _opts, _runtime_cfg), do: {:error, :invalid_link_code_request}

  @doc """
  Completes a pending link-code pairing from a server notification.

  The returned `node` is the `companion_finish` IQ that must be sent before the
  server's expected reconnect. Credential persistence is completed before this
  function returns.
  """
  @spec finish(Store.t(), Node.t()) :: {:ok, finish_result()} | {:error, term()}
  def finish(store, %Node{} = notification) do
    with {:ok, registration} <- registration_node(notification),
         {:ok, ref} <- child_binary(registration, "link_code_pairing_ref"),
         {:ok, primary_identity_public} <- child_binary(registration, "primary_identity_pub"),
         {:ok, wrapped_primary_ephemeral} <-
           child_binary(registration, "link_code_pairing_wrapped_primary_ephemeral_pub"),
         :ok <- ensure_length(ref, :non_empty, :pairing_ref),
         :ok <- ensure_length(primary_identity_public, 32, :primary_identity_public),
         :ok <- ensure_length(wrapped_primary_ephemeral, 80, :wrapped_primary_ephemeral),
         data when is_map(data) <- Store.load!(store),
         {:ok, pending} <- fetch_pending_request(data),
         {:ok, identity} <- fetch_identity_keypair(data),
         {:ok, code_pairing_public} <-
           unwrap_primary_ephemeral(wrapped_primary_ephemeral, pending.code),
         {:ok, companion_shared} <-
           shared_secret(pending.ephemeral_key.private, code_pairing_public),
         {:ok, identity_shared} <-
           shared_secret(identity.private, primary_identity_public),
         {:ok, encrypted_bundle, random} <-
           build_encrypted_key_bundle(
             companion_shared,
             identity.public,
             primary_identity_public
           ),
         adv_secret <-
           hkdf_sha256(
             companion_shared <> identity_shared <> random,
             <<>>,
             @adv_secret_info,
             32
           ),
         finish_id <- Messages.generate_id(),
         finish_node <-
           build_companion_finish(
             pending.jid,
             finish_id,
             encrypted_bundle,
             identity.public,
             ref
           ),
         updated_data <- persist_finished_pairing(data, pending.jid, adv_secret, identity),
         :ok <- Store.persist(store, updated_data) do
      {:ok,
       %{
         jid: pending.jid,
         node: finish_node,
         adv_secret: adv_secret,
         data: updated_data
       }}
    else
      {:error, _reason} = error -> error
    end
  rescue
    exception -> {:error, {:link_code_finish_failed, exception}}
  end

  def finish(_store, _notification), do: {:error, :invalid_link_code_notification}

  @doc "Encodes bytes with WhatsApp's Crockford alphabet."
  @spec crockford_encode(binary()) :: String.t()
  def crockford_encode(bytes) when is_binary(bytes) do
    {characters, value, bit_count} =
      for <<byte <- bytes>>, reduce: {[], 0, 0} do
        {acc, current_value, current_bits} ->
          current_value = bor(bsl(current_value, 8), band(byte, 0xFF))
          emit_crockford_chunks(acc, current_value, current_bits + 8)
      end

    characters =
      if bit_count > 0 do
        [crockford_character(band(bsl(value, 5 - bit_count), 31)) | characters]
      else
        characters
      end

    characters
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end

  @doc "Derives the AES key used to wrap link-code ephemeral public keys."
  @spec derive_pairing_code_key(binary(), binary()) :: binary()
  def derive_pairing_code_key(pairing_code, <<_::binary-size(32)>> = salt)
      when is_binary(pairing_code) do
    :crypto.pbkdf2_hmac(
      :sha256,
      pairing_code,
      salt,
      @pairing_code_iterations,
      32
    )
  end

  @doc false
  @spec hkdf_sha256(binary(), binary(), binary(), pos_integer()) :: binary()
  def hkdf_sha256(input_key_material, salt, info, length)
      when is_binary(input_key_material) and is_binary(salt) and is_binary(info) and
             is_integer(length) and length > 0 do
    salt = if salt == <<>>, do: :binary.copy(<<0>>, 32), else: salt
    pseudo_random_key = :crypto.mac(:hmac, :sha256, salt, input_key_material)
    hkdf_expand(pseudo_random_key, info, length, <<>>, 1, <<>>)
  end

  defp normalize_phone(phone) do
    normalized = String.replace(phone, ~r/\D/u, "")
    if normalized == "", do: {:error, :invalid_phone_number}, else: {:ok, normalized}
  end

  defp build_pairing_code(nil), do: {:ok, crockford_encode(:crypto.strong_rand_bytes(5))}

  defp build_pairing_code(code) when is_binary(code) and byte_size(code) == 8,
    do: {:ok, code}

  defp build_pairing_code(_code), do: {:error, :custom_pairing_code_must_be_8_chars}

  defp ensure_unpaired(data) do
    paired_jid = get_in(data, [:pairing, :device, :jid]) || get_in(data, [:client_info, :jid])

    if paired_jid in [nil, ""], do: :ok, else: {:error, :already_paired}
  end

  defp fetch_identity_keypair(data) do
    candidates = [get_in(data, [:signal, :identity_key]), Map.get(data, :identity)]

    case Enum.find(candidates, &valid_keypair?/1) do
      %{public: public, private: private} -> {:ok, %{public: public, private: private}}
      _ -> {:error, :missing_identity_keypair}
    end
  end

  defp fetch_noise_public(data) do
    case get_in(data, [:noise, :static_public]) do
      <<_::binary-size(32)>> = public -> {:ok, public}
      _ -> {:error, :missing_noise_static_key}
    end
  end

  defp fetch_pending_request(%{
         link_code_pairing:
           %{
             status: :pending,
             code: code,
             jid: jid,
             ephemeral_key: %{private: private, public: public} = ephemeral_key
           } = pending
       })
       when is_binary(code) and byte_size(code) == 8 and is_binary(jid) and jid != "" and
              is_binary(private) and byte_size(private) == 32 and is_binary(public) and
              byte_size(public) == 32 do
    {:ok, Map.put(pending, :ephemeral_key, ephemeral_key)}
  end

  defp fetch_pending_request(_data), do: {:error, :link_code_not_pending}

  defp valid_keypair?(%{
         public: <<_::binary-size(32)>>,
         private: <<_::binary-size(32)>>
       }),
       do: true

  defp valid_keypair?(_keypair), do: false

  defp persist_pending_request(data, jid, code, request_id, ephemeral_key, identity) do
    pending = %{
      status: :pending,
      code: code,
      jid: jid,
      request_id: request_id,
      ephemeral_key: ephemeral_key,
      requested_at: System.system_time(:second)
    }

    data
    |> Map.put(:identity, identity)
    |> Map.put(:link_code_pairing, pending)
  end

  defp persist_finished_pairing(data, jid, adv_secret, identity) do
    now = System.system_time(:second)
    pairing = Map.get(data, :pairing, %{})
    pairing_device = pairing |> Map.get(:device, %{}) |> Map.put(:jid, jid)

    pairing =
      pairing
      |> Map.put(:device, pairing_device)
      |> Map.put(:via, :link_code)
      |> Map.put(:paired_at, now)

    client_info = data |> Map.get(:client_info, %{}) |> Map.put(:jid, jid)

    completed = %{
      status: :registered,
      jid: jid,
      registered_at: now
    }

    data
    |> Map.put(:identity, identity)
    |> Map.put(:adv_secret, adv_secret)
    |> Map.put(:pairing, pairing)
    |> Map.put(:client_info, client_info)
    |> Map.put(:link_code_pairing, completed)
  end

  defp wrap_companion_ephemeral(public_key, code) do
    salt = :crypto.strong_rand_bytes(32)
    iv = :crypto.strong_rand_bytes(16)
    key = derive_pairing_code_key(code, salt)
    ciphertext = :crypto.crypto_one_time(:aes_256_ctr, key, iv, public_key, true)
    salt <> iv <> ciphertext
  end

  defp unwrap_primary_ephemeral(
         <<salt::binary-size(32), iv::binary-size(16), ciphertext::binary-size(32)>>,
         code
       ) do
    key = derive_pairing_code_key(code, salt)
    {:ok, :crypto.crypto_one_time(:aes_256_ctr, key, iv, ciphertext, false)}
  rescue
    exception -> {:error, {:primary_ephemeral_decrypt_failed, exception}}
  end

  defp unwrap_primary_ephemeral(_wrapped, _code),
    do: {:error, {:invalid_length, :wrapped_primary_ephemeral}}

  defp shared_secret(<<_::binary-size(32)>> = private, <<_::binary-size(32)>> = public) do
    {:ok, :crypto.compute_key(:ecdh, public, private, :x25519)}
  rescue
    exception -> {:error, {:invalid_curve25519_public_key, exception}}
  end

  defp shared_secret(_private, _public), do: {:error, :invalid_curve25519_keypair}

  defp build_encrypted_key_bundle(
         companion_shared,
         identity_public,
         primary_identity_public
       ) do
    random = :crypto.strong_rand_bytes(32)
    salt = :crypto.strong_rand_bytes(32)
    iv = :crypto.strong_rand_bytes(12)
    key = hkdf_sha256(companion_shared, salt, @key_bundle_info, 32)
    plaintext = identity_public <> primary_identity_public <> random

    {ciphertext, authentication_tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, <<>>, true)

    {:ok, salt <> iv <> ciphertext <> authentication_tag, random}
  rescue
    exception -> {:error, {:key_bundle_encrypt_failed, exception}}
  end

  defp build_companion_hello(
         jid,
         request_id,
         wrapped,
         noise_public,
         runtime_cfg
       ) do
    registration = %Node{
      tag: "link_code_companion_reg",
      attrs: %{
        "jid" => jid,
        "stage" => "companion_hello",
        "should_show_push_notification" => "true"
      },
      content: [
        child("link_code_pairing_wrapped_companion_ephemeral_pub", wrapped),
        child("companion_server_auth_key_pub", noise_public),
        child("companion_platform_id", companion_platform_id(runtime_cfg)),
        child("companion_platform_display", companion_platform_display(runtime_cfg)),
        child("link_code_pairing_nonce", "0")
      ]
    }

    %Node{
      tag: "iq",
      attrs: %{
        "to" => @server_jid,
        "type" => "set",
        "id" => request_id,
        "xmlns" => "md"
      },
      content: [registration]
    }
  end

  defp build_companion_finish(
         jid,
         request_id,
         encrypted_bundle,
         identity_public,
         ref
       ) do
    registration = %Node{
      tag: "link_code_companion_reg",
      attrs: %{"jid" => jid, "stage" => "companion_finish"},
      content: [
        child("link_code_pairing_wrapped_key_bundle", encrypted_bundle),
        child("companion_identity_public", identity_public),
        child("link_code_pairing_ref", ref)
      ]
    }

    %Node{
      tag: "iq",
      attrs: %{
        "to" => @server_jid,
        "type" => "set",
        "id" => request_id,
        "xmlns" => "md"
      },
      content: [registration]
    }
  end

  defp companion_platform_id(runtime_cfg) do
    ua = Config.get(runtime_cfg, [:protocol, :user_agent], %{})
    os = Map.get(ua, :os_version, "")
    name = Map.get(ua, :device_name, "")

    cond do
      Config.get(runtime_cfg, [:protocol, :client_mode], :web) == :android ->
        "9"

      String.downcase(name) == "desktop" and String.contains?(String.downcase(os), "windows") ->
        "8"

      String.downcase(name) == "desktop" ->
        "7"

      true ->
        browser_platform_id(String.downcase(name))
    end
  end

  defp browser_platform_id("chrome"), do: "1"
  defp browser_platform_id("edge"), do: "2"
  defp browser_platform_id("firefox"), do: "3"
  defp browser_platform_id("ie"), do: "4"
  defp browser_platform_id("opera"), do: "5"
  defp browser_platform_id("safari"), do: "6"
  defp browser_platform_id(_name), do: "9"

  defp companion_platform_display(runtime_cfg) do
    ua = Config.get(runtime_cfg, [:protocol, :user_agent], %{})
    os = Map.get(ua, :os_version, "")
    name = Map.get(ua, :device_name, "")

    cond do
      name != "" and os != "" -> "#{name} (#{os})"
      name != "" -> name
      true -> "ExWapp"
    end
  end

  defp registration_node(%Node{tag: "link_code_companion_reg"} = registration),
    do: {:ok, registration}

  defp registration_node(%Node{content: content}) when is_list(content) do
    case Enum.find(content, &match?(%Node{tag: "link_code_companion_reg"}, &1)) do
      %Node{} = registration -> {:ok, registration}
      nil -> {:error, :missing_link_code_registration}
    end
  end

  defp registration_node(_node), do: {:error, :missing_link_code_registration}

  defp child_binary(%Node{content: content}, tag) when is_list(content) do
    content
    |> Enum.find(&match?(%Node{tag: ^tag}, &1))
    |> node_binary(tag)
  end

  defp child_binary(_node, tag), do: {:error, {:missing_link_code_field, tag}}

  defp node_binary(%Node{content: %Raw{data: data}}, _tag),
    do: {:ok, IO.iodata_to_binary(data)}

  defp node_binary(%Node{content: data}, _tag) when is_binary(data), do: {:ok, data}
  defp node_binary(_node, tag), do: {:error, {:missing_link_code_field, tag}}

  defp ensure_length(value, :non_empty, _field) when is_binary(value) and value != "", do: :ok

  defp ensure_length(value, expected, _field)
       when is_binary(value) and is_integer(expected) and byte_size(value) == expected,
       do: :ok

  defp ensure_length(_value, _expected, field), do: {:error, {:invalid_length, field}}

  defp child(tag, content),
    do: %Node{tag: tag, attrs: %{}, content: Binary.raw(content)}

  defp emit_crockford_chunks(acc, value, bit_count) when bit_count >= 5 do
    character = crockford_character(band(bsr(value, bit_count - 5), 31))
    emit_crockford_chunks([character | acc], value, bit_count - 5)
  end

  defp emit_crockford_chunks(acc, value, bit_count), do: {acc, value, bit_count}

  defp crockford_character(index), do: binary_part(@crockford_alphabet, index, 1)

  defp hkdf_expand(_key, _info, length, _previous, _counter, output)
       when byte_size(output) >= length,
       do: binary_part(output, 0, length)

  defp hkdf_expand(key, info, length, previous, counter, output) when counter <= 255 do
    block = :crypto.mac(:hmac, :sha256, key, previous <> info <> <<counter>>)
    hkdf_expand(key, info, length, block, counter + 1, output <> block)
  end
end
