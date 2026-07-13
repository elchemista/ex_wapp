defmodule ExWapp.Message.Handler.Inbound.Decryptor do
  @moduledoc """
  Signal and sender-key decryption for inbound message envelopes.

  This module resolves and tries encrypted payload/sender candidates, updates
  Signal sessions, processes group sender-key distributions, and normalizes
  decrypt failures. It returns plaintext without classifying message content.
  """

  require Logger

  alias ExWapp.JID
  alias ExWapp.Message.Handler.Common
  alias ExWapp.Message.Handler.Inbound.Envelope
  alias ExWapp.Session.{Account, JIDUtils}
  alias ExWapp.Signal.{Encryption, SenderKey, SessionStore}

  @type success :: %{
          message_data: map(),
          plaintext: binary(),
          updated_sessions: SessionStore.t(),
          sender_jid: String.t(),
          payload: map(),
          sender_key_distribution_count: non_neg_integer(),
          enc_type: term()
        }

  @doc """
  Decrypts one encrypted inbound message without classifying its content.
  """
  @spec decrypt(map(), map(), term(), term(), map()) ::
          {:ok, success(), map()} | {:error, map(), map()}
  def decrypt(
        %{encrypted: true, enc_type: enc_type} = message_data,
        state,
        from,
        participant,
        attrs
      )
      when is_map(state) and is_map(attrs) do
    decrypt_ctx = Envelope.decrypt_context(message_data, state, from, participant, attrs)
    log_decrypt_attempt(enc_type, decrypt_ctx, from)

    case validate_context(state, decrypt_ctx) do
      {:ok, store} ->
        decrypt_with_context(store, state, from, message_data, enc_type, decrypt_ctx)

      {:error, reason} ->
        {updated_message_data, updated_state} = error_result(message_data, state, reason)
        {:error, updated_message_data, updated_state}
    end
  end

  @spec log_decrypt_attempt(term(), Envelope.decrypt_context(), term()) :: :ok
  defp log_decrypt_attempt(enc_type, decrypt_ctx, from) do
    Logger.debug(
      "[DECRYPT] Attempting decrypt: enc_type=#{inspect(enc_type)} payload_candidates=#{length(decrypt_ctx.payload_candidates)} decryptable_payloads=#{length(decrypt_ctx.decryptable_payloads)} from=#{inspect(from)} sender_candidates=#{inspect(decrypt_ctx.sender_candidates)}"
    )
  end

  @spec validate_context(map(), Envelope.decrypt_context()) ::
          {:ok, term()}
          | {:error, :missing_store | :no_sender_candidates | :no_ciphertext_candidates}
  defp validate_context(state, decrypt_ctx) do
    cond do
      is_nil(Map.get(state, :store)) ->
        Logger.warning("[DECRYPT] Missing store in state, cannot decrypt")
        {:error, :missing_store}

      decrypt_ctx.sender_candidates == [] ->
        Logger.warning(
          "[DECRYPT] No sender candidates found from from/participant/sender_lid attrs"
        )

        {:error, :no_sender_candidates}

      decrypt_ctx.decryptable_payloads == [] ->
        Logger.warning(
          "[DECRYPT] Skipping decrypt: no binary ciphertext candidates. first_candidate=#{inspect(List.first(decrypt_ctx.payload_candidates))}"
        )

        {:error, :no_ciphertext_candidates}

      true ->
        {:ok, Map.get(state, :store)}
    end
  end

  @spec decrypt_with_context(
          term(),
          map(),
          term(),
          map(),
          term(),
          Envelope.decrypt_context()
        ) :: {:ok, success(), map()} | {:error, map(), map()}
  defp decrypt_with_context(store, state, from, message_data, enc_type, decrypt_ctx) do
    case decrypt_with_payload_candidates(
           store,
           Map.get(state, :signal_sessions),
           decrypt_ctx.sender_candidates,
           decrypt_ctx.decryptable_payloads,
           from
         ) do
      {:ok, padded_plaintext, updated_sessions, sender_jid, payload} ->
        build_success(
          state,
          from,
          message_data,
          enc_type,
          padded_plaintext,
          updated_sessions,
          sender_jid,
          payload
        )

      {:error, reason} ->
        log_decrypt_failure(state, from, enc_type, reason, decrypt_ctx)

        {updated_message_data, updated_state} =
          error_result(message_data, state, reason, decrypt_ctx.sender_candidates)

        {:error, updated_message_data, updated_state}
    end
  end

  @spec build_success(
          map(),
          term(),
          map(),
          term(),
          binary(),
          SessionStore.t(),
          String.t(),
          map()
        ) :: {:ok, success(), map()}
  defp build_success(
         state,
         from,
         message_data,
         enc_type,
         padded_plaintext,
         updated_sessions,
         sender_jid,
         payload
       ) do
    plaintext =
      Encryption.unpad_message(
        padded_plaintext,
        Map.get(payload, :enc_version) || Map.get(message_data, :enc_version)
      )

    {sender_key_distribution_count, state} =
      process_sender_key_distributions(state, from, sender_jid, plaintext)

    message_data = put_signal_sessions_update(message_data, updated_sessions)
    updated_state = Map.put(state, :signal_sessions, updated_sessions)

    {:ok,
     %{
       message_data: message_data,
       plaintext: plaintext,
       updated_sessions: updated_sessions,
       sender_jid: sender_jid,
       payload: payload,
       sender_key_distribution_count: sender_key_distribution_count,
       enc_type: enc_type
     }, updated_state}
  end

  @spec log_decrypt_failure(
          map(),
          term(),
          term(),
          term(),
          Envelope.decrypt_context()
        ) :: :ok
  defp log_decrypt_failure(state, from, enc_type, reason, decrypt_ctx) do
    signal_sessions = Map.get(state, :signal_sessions)
    sender_candidates = Map.get(decrypt_ctx, :sender_candidates, [])
    payloads = Map.get(decrypt_ctx, :decryptable_payloads, [])
    lid_mapping = Account.load_lid_mapping(Map.get(state, :store))

    candidate_identities =
      sender_candidates
      |> Enum.map(&JIDUtils.identity/1)
      |> MapSet.new()

    stored_session_targets =
      signal_sessions
      |> SessionStore.list_sessions()
      |> Enum.filter(&MapSet.member?(candidate_identities, JIDUtils.identity(&1)))
      |> Enum.sort()
      |> Enum.take(12)

    related_bases =
      sender_candidates
      |> Enum.flat_map(&JIDUtils.related_bases(&1, lid_mapping))
      |> Enum.uniq()
      |> Enum.sort()

    Logger.error(
      "[DECRYPT] Failed to decrypt message: enc_type=#{inspect(enc_type)} from=#{Common.normalize_jid_with_device(from)} reason=#{inspect(reason)} sender_candidates=#{inspect(sender_candidates)} related_bases=#{inspect(related_bases)} payload_count=#{length(payloads)} payload_types=#{inspect(Enum.map(payloads, &Map.get(&1, :enc_type)))} stored_session_targets=#{inspect(stored_session_targets)}"
    )
  rescue
    error ->
      Logger.error(
        "[DECRYPT] Failed to decrypt message and diagnostics logging raised: reason=#{inspect(reason)} logging_error=#{inspect(error)}"
      )
  end

  @spec error_result(map(), map(), term(), [String.t()]) :: {map(), map()}
  defp error_result(message_data, state, reason, sender_candidates \\ []) do
    {updated_state, maybe_updated_sessions} =
      maybe_reset_sessions_for_failure(state, reason, sender_candidates)

    updated_message_data =
      message_data
      |> Map.put(:decrypt_status, {:error, reason})
      |> put_signal_sessions_update(maybe_updated_sessions)

    {updated_message_data, updated_state}
  end

  @spec put_signal_sessions_update(map(), term()) :: map()
  defp put_signal_sessions_update(message_data, nil), do: message_data

  defp put_signal_sessions_update(message_data, sessions) do
    if SessionStore.store?(sessions),
      do: Map.put(message_data, :signal_sessions_update, sessions),
      else: message_data
  end

  @spec maybe_reset_sessions_for_failure(map(), term(), [String.t()]) ::
          {map(), SessionStore.t() | nil}
  defp maybe_reset_sessions_for_failure(state, reason, sender_candidates) do
    reset_candidates = failure_session_reset_candidates(reason, sender_candidates)

    case clear_sessions_for_candidates(
           Map.get(state, :signal_sessions),
           state,
           reset_candidates
         ) do
      nil -> {state, nil}
      updated_sessions -> {%{state | signal_sessions: updated_sessions}, updated_sessions}
    end
  end

  @spec failure_session_reset_candidates(term(), [String.t()]) :: [String.t()]
  defp failure_session_reset_candidates(
         {:decrypt_failed_for_payload, _, {:decrypt_failed_for_candidate, _candidate, reason}},
         sender_candidates
       )
       when reason in [:invalid_mac, :no_session, :unknown_signed_prekey] do
    sender_candidates
    |> Enum.map(&Common.normalize_jid_with_device/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp failure_session_reset_candidates(_reason, _sender_candidates), do: []

  @spec clear_sessions_for_candidates(term(), map(), [String.t()]) :: SessionStore.t() | nil
  defp clear_sessions_for_candidates(_signal_sessions, _state, []), do: nil
  defp clear_sessions_for_candidates(nil, _state, _candidates), do: nil

  defp clear_sessions_for_candidates(signal_sessions, state, candidates) do
    if SessionStore.store?(signal_sessions) do
      lid_mapping = Account.load_lid_mapping(Map.get(state, :store))

      Enum.reduce(candidates, signal_sessions, fn candidate, sessions ->
        SessionStore.delete_sessions_for_user(sessions, candidate, lid_mapping)
      end)
    else
      nil
    end
  rescue
    error ->
      Logger.warning("[DECRYPT] Failed clearing stale signal sessions: #{inspect(error)}")
      nil
  end

  @spec decrypt_with_payload_candidates(
          term(),
          term(),
          [String.t()],
          [Envelope.payload_candidate()],
          term()
        ) ::
          {:ok, binary(), SessionStore.t(), String.t(), map()} | {:error, term()}
  defp decrypt_with_payload_candidates(_store, _signal_sessions, _candidates, [], _chat_jid),
    do: {:error, :no_payload_candidates}

  defp decrypt_with_payload_candidates(
         store,
         signal_sessions,
         candidates,
         [payload | rest],
         chat_jid
       ) do
    ciphertext = Map.get(payload, :ciphertext)
    enc_type = Map.get(payload, :enc_type, "msg")

    case decrypt_with_candidates(
           store,
           signal_sessions,
           candidates,
           ciphertext,
           enc_type,
           chat_jid
         ) do
      {:ok, plaintext, updated_sessions, sender_jid} ->
        {:ok, plaintext, updated_sessions, sender_jid, payload}

      {:error, reason} ->
        case decrypt_with_payload_candidates(store, signal_sessions, candidates, rest, chat_jid) do
          {:ok, _plaintext, _updated_sessions, _sender_jid, _payload} = success -> success
          {:error, _other} -> {:error, {:decrypt_failed_for_payload, enc_type, reason}}
        end
    end
  end

  @spec decrypt_with_candidates(
          term(),
          term(),
          [String.t()],
          binary(),
          term(),
          term()
        ) :: {:ok, binary(), SessionStore.t(), String.t()} | {:error, term()}
  defp decrypt_with_candidates(_store, _signal_sessions, [], _ciphertext, _enc_type, _chat_jid),
    do: {:error, :no_sender_candidates}

  defp decrypt_with_candidates(
         store,
         signal_sessions,
         [candidate | rest],
         ciphertext,
         enc_type,
         chat_jid
       ) do
    decrypt_result =
      if sender_key_message?(enc_type, chat_jid) do
        case SenderKey.decrypt_group_message(store, chat_jid, candidate, ciphertext) do
          {:ok, plaintext} -> {:ok, plaintext, signal_sessions}
          {:error, reason} -> {:error, reason}
        end
      else
        Encryption.decrypt_from_sender_sync(
          store,
          signal_sessions,
          candidate,
          ciphertext,
          enc_type
        )
      end

    case decrypt_result do
      {:ok, plaintext, updated_sessions} ->
        {:ok, plaintext, updated_sessions, candidate}

      {:error, reason} ->
        case decrypt_with_candidates(store, signal_sessions, rest, ciphertext, enc_type, chat_jid) do
          {:ok, _plaintext, _updated_sessions, _candidate} = success -> success
          {:error, _} -> {:error, {:decrypt_failed_for_candidate, candidate, reason}}
        end
    end
  end

  @spec sender_key_message?(term(), term()) :: boolean()
  defp sender_key_message?(enc_type, chat_jid) do
    enc_type in [:skmsg, "skmsg"] and group_jid?(chat_jid)
  end

  @spec group_jid?(term()) :: boolean()
  defp group_jid?(jid) do
    jid
    |> Common.normalize_jid()
    |> JID.group?()
  end

  @spec process_sender_key_distributions(map(), term(), String.t(), binary()) ::
          {non_neg_integer(), map()}
  defp process_sender_key_distributions(state, from, sender_jid, plaintext)
       when is_binary(plaintext) do
    store = Map.get(state, :store)

    cond do
      is_nil(store) ->
        {0, state}

      not group_jid?(from) ->
        {0, state}

      true ->
        process_group_sender_key_distribution(store, state, from, sender_jid, plaintext)
    end
  end

  @spec process_group_sender_key_distribution(
          term(),
          map(),
          term(),
          String.t(),
          binary()
        ) :: {non_neg_integer(), map()}
  defp process_group_sender_key_distribution(store, state, from, sender_jid, plaintext) do
    case SenderKey.process_distributions_from_plaintext(store, from, sender_jid, plaintext) do
      {:ok, count} ->
        {count, state}

      {:error, reason} ->
        Logger.warning(
          "[SENDER_KEY] Failed processing sender key distribution: #{inspect(reason)}"
        )

        {0, state}
    end
  end
end
