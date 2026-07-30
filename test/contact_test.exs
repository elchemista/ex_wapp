defmodule ExWapp.ContactTest do
  use ExUnit.Case, async: true

  alias ExWapp.Contact
  alias ExWapp.Store

  setup do
    store = Store.new(Store.Memory)
    %{store: store}
  end

  describe "put/3 and get/2" do
    test "stores and retrieves a contact", %{store: store} do
      contact = %Contact{
        jid: "1234@s.whatsapp.net",
        full_name: "Alice",
        first_name: "Alice"
      }

      assert :ok = Contact.put(store, "1234@s.whatsapp.net", contact)

      result = Contact.get(store, "1234@s.whatsapp.net")
      assert result != nil
      assert result.full_name == "Alice"
      assert result.phone_number == "1234"
    end

    test "normalizes JID on store", %{store: store} do
      contact = %Contact{jid: "5555@whatsapp.net", full_name: "Bob"}

      Contact.put(store, "5555@whatsapp.net", contact)

      # Should be retrievable with normalized JID
      result = Contact.get(store, "5555@s.whatsapp.net")
      assert result != nil
      assert result.full_name == "Bob"
    end

    test "strips leading + from phone JID", %{store: store} do
      contact = %Contact{jid: "+5555@s.whatsapp.net", full_name: "Bob"}

      Contact.put(store, "+5555@s.whatsapp.net", contact)

      result = Contact.get(store, "5555@s.whatsapp.net")
      assert result != nil
      assert result.jid == "5555@s.whatsapp.net"
      assert result.phone_number == "5555"
    end

    test "collapses legacy + JID aliases on update", %{store: store} do
      Contact.put(store, "+5555@s.whatsapp.net", %Contact{
        jid: "+5555@s.whatsapp.net",
        full_name: "Bob"
      })

      Contact.update_push_name(store, "5555@s.whatsapp.net", "Bob Push")

      keys =
        store
        |> Store.load!()
        |> Map.get(:contacts, %{})
        |> Map.keys()
        |> Enum.filter(&String.contains?(&1, "5555"))

      assert keys == ["5555@s.whatsapp.net"]

      result = Contact.get(store, "5555@s.whatsapp.net")
      assert result.push_name == "Bob Push"
    end

    test "returns nil for unknown JID", %{store: store} do
      assert nil == Contact.get(store, "unknown@s.whatsapp.net")
    end
  end

  describe "list/1" do
    test "lists all contacts", %{store: store} do
      Contact.put(store, "a@s.whatsapp.net", %Contact{jid: "a@s.whatsapp.net", full_name: "A"})
      Contact.put(store, "b@s.whatsapp.net", %Contact{jid: "b@s.whatsapp.net", full_name: "B"})

      contacts = Contact.list(store)
      assert length(contacts) == 2
      names = Enum.map(contacts, & &1.full_name) |> Enum.sort()
      assert names == ["A", "B"]
    end

    test "returns empty list when no contacts", %{store: store} do
      assert [] == Contact.list(store)
    end
  end

  describe "delete/2" do
    test "removes a contact", %{store: store} do
      Contact.put(store, "1234@s.whatsapp.net", %Contact{
        jid: "1234@s.whatsapp.net",
        full_name: "Del"
      })

      assert Contact.get(store, "1234@s.whatsapp.net") != nil

      Contact.delete(store, "1234@s.whatsapp.net")

      assert nil == Contact.get(store, "1234@s.whatsapp.net")
    end
  end

  describe "update_push_name/3" do
    test "sets push name on existing contact", %{store: store} do
      Contact.put(store, "1234@s.whatsapp.net", %Contact{
        jid: "1234@s.whatsapp.net",
        full_name: "Original"
      })

      Contact.update_push_name(store, "1234@s.whatsapp.net", "NewPush")

      result = Contact.get(store, "1234@s.whatsapp.net")
      assert result.push_name == "NewPush"
      assert result.full_name == "Original"
    end

    test "creates contact if not exists", %{store: store} do
      Contact.update_push_name(store, "new@s.whatsapp.net", "PushOnly")

      result = Contact.get(store, "new@s.whatsapp.net")
      assert result != nil
      assert result.push_name == "PushOnly"
      assert result.full_name == nil
    end

    test "ignores empty name", %{store: store} do
      assert :ok = Contact.update_push_name(store, "x@s.whatsapp.net", "")
      assert nil == Contact.get(store, "x@s.whatsapp.net")
    end
  end

  describe "merge_from_sync/3" do
    test "merges contact action data", %{store: store} do
      Contact.merge_from_sync(store, "1234@s.whatsapp.net", %{
        fullName: "Synced Name",
        firstName: "Synced"
      })

      result = Contact.get(store, "1234@s.whatsapp.net")
      assert result.full_name == "Synced Name"
      assert result.first_name == "Synced"
    end

    test "preserves existing fields not in sync data", %{store: store} do
      Contact.put(store, "1234@s.whatsapp.net", %Contact{
        jid: "1234@s.whatsapp.net",
        full_name: "Old Name",
        push_name: "Push"
      })

      Contact.merge_from_sync(store, "1234@s.whatsapp.net", %{
        fullName: "New Name"
      })

      result = Contact.get(store, "1234@s.whatsapp.net")
      assert result.full_name == "New Name"
      assert result.push_name == "Push"
    end
  end
end
