defmodule ExWapp.Session.AppStateCommandsTest do
  use ExUnit.Case, async: true

  alias ExWapp.Session.AppStateCommands

  # A stub session: replies to the app-state call and forwards the patch it was
  # asked to send, so each command can be checked without a real session.
  defp stub_session(reply) do
    test = self()

    spawn_link(fn -> stub_loop(test, reply) end)
  end

  defp stub_loop(test, reply) do
    receive do
      {:"$gen_call", from, {:app_state_mutation, patch}} ->
        send(test, {:patch_sent, patch})
        GenServer.reply(from, reply)
        stub_loop(test, reply)
    end
  end

  defp sent_patch do
    assert_receive {:patch_sent, patch}
    patch
  end

  defp index_of(patch) do
    assert [mutation] = patch.mutations
    mutation.index
  end

  describe "with a session that accepts the patch" do
    setup do
      %{session: stub_session({:ok, %{version: 1, hash: <<0>>}, %{}})}
    end

    test "archive_chat archives and unpins, as WhatsApp Web does", %{session: session} do
      assert :ok = AppStateCommands.archive_chat(session, "15550001111@s.whatsapp.net")

      assert [
               %{
                 index: ["archive", "15550001111@s.whatsapp.net"],
                 value: %{archiveChatAction: %{archived: true}}
               },
               %{
                 index: ["pin_v1", "15550001111@s.whatsapp.net"],
                 value: %{pinAction: %{pinned: false}}
               }
             ] = sent_patch().mutations
    end

    test "unarchive_chat only flips the archived flag, leaving the pin alone", %{session: session} do
      assert :ok = AppStateCommands.unarchive_chat(session, "15550001111@s.whatsapp.net")

      assert [
               %{
                 index: ["archive", "15550001111@s.whatsapp.net"],
                 value: %{archiveChatAction: %{archived: false}}
               }
             ] = sent_patch().mutations
    end

    test "delete_chat sends a delete-chat patch", %{session: session} do
      assert :ok = AppStateCommands.delete_chat(session, "15550001111@s.whatsapp.net")

      patch = sent_patch()
      assert index_of(patch) == ["deleteChat", "15550001111@s.whatsapp.net", "0"]
      assert [%{value: %{deleteChatAction: %{}}}] = patch.mutations
    end

    test "create_contact carries the name in the contact action", %{session: session} do
      assert :ok = AppStateCommands.create_contact(session, "15550002222@s.whatsapp.net", "Alice")

      patch = sent_patch()
      assert index_of(patch) == ["contact", "15550002222@s.whatsapp.net"]
      assert [%{value: %{contactAction: %{fullName: "Alice"}}}] = patch.mutations
    end

    test "delete_contact sends a remove operation", %{session: session} do
      assert :ok = AppStateCommands.delete_contact(session, "15550002222@s.whatsapp.net")

      assert [%{index: ["contact", "15550002222@s.whatsapp.net"], operation: :remove}] =
               sent_patch().mutations
    end
  end

  test "a rejected patch is reported to the caller unchanged" do
    session = stub_session({:error, {:not_connected, :idle}})

    assert {:error, {:not_connected, :idle}} =
             AppStateCommands.archive_chat(session, "15550001111@s.whatsapp.net")
  end
end
