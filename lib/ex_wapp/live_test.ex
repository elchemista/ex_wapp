defmodule ExWapp.LiveTest do
  @moduledoc """
  Backward-compatible wrapper around `ExWapp.Live`.
  """

  @spec run(keyword()) :: {:ok, map()} | {:error, term()}
  defdelegate run(opts \\ []), to: ExWapp.Live

  @spec run_session(term(), keyword()) :: {:ok, map()} | {:error, term()}
  defdelegate run_session(session_id, opts \\ []), to: ExWapp.Live

  @spec stop_session(term()) :: :ok | {:error, :not_found}
  defdelegate stop_session(session_id), to: ExWapp.Live

  @spec list_sessions() :: [{term(), pid()}]
  defdelegate list_sessions(), to: ExWapp.Live

  @spec send_message(pid(), String.t(), iodata()) :: {:ok, String.t()} | {:error, term()}
  defdelegate send_message(session, jid, text), to: ExWapp.Live

  @spec list_chats(pid()) :: [ExWapp.Chat.chat()]
  defdelegate list_chats(session), to: ExWapp.Live

  @spec list_groups(pid()) :: [ExWapp.Chat.chat()]
  defdelegate list_groups(session), to: ExWapp.Live

  @spec get_messages(pid(), String.t(), keyword()) :: [ExWapp.Chat.message()]
  defdelegate get_messages(session, jid, opts \\ []), to: ExWapp.Live

  @spec wait_new_messages(pid(), keyword()) ::
          {:ok, [{String.t(), ExWapp.Chat.message()}]} | {:error, :timeout}
  defdelegate wait_new_messages(session, opts \\ []), to: ExWapp.Live
end
