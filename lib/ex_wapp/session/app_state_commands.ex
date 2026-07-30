defmodule ExWapp.Session.AppStateCommands do
  @moduledoc """
  Chat and contact commands that reach the server through app-state sync.

  Each command picks the patch that describes the change and hands it to the
  session, then reports success as `:ok` instead of leaking the hash state the
  transport returns.

  This is orchestration, not actor work: nothing here touches the session
  process state, which is why it lives outside `ExWapp.Session.Worker`.
  """

  alias ExWapp.AppState.Engine
  alias ExWapp.Session.Worker

  @type result :: :ok | {:error, term()}

  @doc "Archives a chat, synchronising the change to the other devices."
  @spec archive_chat(GenServer.server(), String.t()) :: result()
  def archive_chat(server, jid) do
    jid |> Engine.build_archive(true) |> send_patch(server)
  end

  @doc "Unarchives a chat, synchronising the change to the other devices."
  @spec unarchive_chat(GenServer.server(), String.t()) :: result()
  def unarchive_chat(server, jid) do
    jid |> Engine.build_archive(false) |> send_patch(server)
  end

  @doc "Deletes a chat, synchronising the change to the other devices."
  @spec delete_chat(GenServer.server(), String.t()) :: result()
  def delete_chat(server, jid) do
    jid |> Engine.build_delete_chat() |> send_patch(server)
  end

  @doc "Creates or updates a contact, synchronising the change to the other devices."
  @spec create_contact(GenServer.server(), String.t(), String.t()) :: result()
  def create_contact(server, jid, name) do
    jid |> Engine.build_contact(name) |> send_patch(server)
  end

  @doc "Deletes a contact, synchronising the change to the other devices."
  @spec delete_contact(GenServer.server(), String.t()) :: result()
  def delete_contact(server, jid) do
    jid |> Engine.build_delete_contact() |> send_patch(server)
  end

  @spec send_patch(map(), GenServer.server()) :: result()
  defp send_patch(patch, server) do
    case Worker.send_app_state(server, patch) do
      {:ok, _hash_state, _mutation_macs} -> :ok
      {:error, _reason} = error -> error
    end
  end
end
