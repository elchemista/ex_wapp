defmodule ExWapp.TargetResolutionCompatibilityTest do
  use ExUnit.Case, async: true
  alias ExWapp.Session.{Targets, JIDUtils}
  alias ExWapp.Signal.SessionStore
  alias ExWapp.Message.Handler.Common
  alias ExWapp.{Chat, Store}

  test "legacy target resolver keeps explicit device hints and excludes the local device" do
    sessions =
      Enum.reduce(
        [
          "123@s.whatsapp.net",
          "123:1@s.whatsapp.net",
          "123:2@s.whatsapp.net",
          "456:1@s.whatsapp.net"
        ],
        SessionStore.new(),
        &SessionStore.put_session(&2, &1, %{})
      )

    assert Enum.sort(Targets.list_session_targets_for_jid(sessions, "123@s.whatsapp.net")) == [
             "123:1@s.whatsapp.net",
             "123:2@s.whatsapp.net",
             "123@s.whatsapp.net"
           ]

    assert Enum.sort(Targets.resolve_encryption_targets(sessions, "123@s.whatsapp.net", %{}, nil)) ==
             ["123:1@s.whatsapp.net", "123:2@s.whatsapp.net"]

    assert Targets.resolve_encryption_targets(nil, "123@s.whatsapp.net", %{}, nil) == [
             "123@s.whatsapp.net"
           ]

    assert Targets.resolve_encryption_targets(
             nil,
             "123@s.whatsapp.net",
             %{"123:7@s.whatsapp.net" => %{}},
             nil
           ) == ["123:7@s.whatsapp.net"]

    hints = ["123@s.whatsapp.net", "123:1@s.whatsapp.net"]
    assert Targets.resolve_encryption_targets(sessions, "123@s.whatsapp.net", %{}, hints) == hints

    refute "123:1@s.whatsapp.net" in Targets.resolve_own_device_targets(
             sessions,
             "123@s.whatsapp.net",
             1,
             nil
           )

    assert Targets.resolve_own_device_targets(sessions, "123@s.whatsapp.net", 1, hints) == [
             "123@s.whatsapp.net"
           ]

    assert Targets.resolve_own_device_targets(sessions, "", 1, nil) == []
    assert Targets.drop_base_alias_targets(nil) == []
    assert Targets.drop_base_alias_targets(["123@s.whatsapp.net"]) == ["123@s.whatsapp.net"]

    assert Targets.filter_prekey_bundles_for_identity(
             %{"123:7@s.whatsapp.net" => :keep, "456:1@s.whatsapp.net" => :drop},
             "123@s.whatsapp.net"
           ) == %{"123:7@s.whatsapp.net" => :keep}

    assert JIDUtils.identity("123:7@whatsapp.net") == JIDUtils.identity("123@s.whatsapp.net")
  end

  test "sync metadata recognizes server encodings without overwriting absent values" do
    store = Store.Memory.new()
    jid = "123@s.whatsapp.net"
    Chat.get_or_create(store, jid, name: "Alice")

    for {truthy, falsy} <- [{true, false}, {1, 0}, {"yes", "no"}, {"on", "off"}, {"1", "0"}] do
      assert :ok =
               Common.upsert_chat_from_sync_attrs(store, %{
                 "jid" => jid,
                 "pin" => truthy,
                 "archive" => falsy,
                 "mute" => 123,
                 "count" => 2
               })

      assert {:ok, %{pinned: true, archived: false, muted_until: 123, unread_count: 2}} =
               Chat.get(store, jid)

      assert :ok =
               Common.upsert_chat_from_sync_attrs(store, %{
                 "jid" => jid,
                 "pin" => falsy,
                 "archive" => truthy,
                 "mute" => 0
               })

      assert {:ok, %{pinned: false, archived: true, muted_until: nil}} = Chat.get(store, jid)
    end

    assert :ok = Common.upsert_chat_from_sync_attrs(store, :bad, %{})
    assert {:ok, %{name: "Alice", archived: true}} = Chat.get(store, jid)
    {:ok, parsed} = ExWapp.JID.parse(jid)
    assert Common.normalize_optional_text(parsed) == jid
    assert Common.normalize_jid_with_device(parsed) == jid
    assert Common.normalize_content([0, 1, 255]) == <<0, 1, 255>>
    assert Common.normalize_content([nil, %{}]) == nil
    assert Common.normalize_content(nil) == nil

    for value <- [nil, -1, "bad", "1tail"] do
      assert Common.parse_non_neg_integer(value) == nil
    end

    assert Common.parse_non_neg_integer(12) == 12
    assert Common.parse_enc_version(2) == 2
    assert Common.parse_enc_version("bad") == nil
    assert Common.parse_enc_version(nil) == nil
  end

  test "group creation metadata has stable fallbacks when optional fields are absent" do
    alias ExWapp.Binary.Node

    group = %Node{
      tag: "create",
      content: [%Node{tag: "group", attrs: %{"name" => "Project", "creation" => 123}}]
    }

    assert Common.extract_group_subject([group]) == "Project"
    assert Common.extract_group_event_timestamp([group]) == 123
    assert Common.extract_group_subject(nil) == nil
    assert Common.extract_group_event_timestamp(nil) == nil
    assert Common.extract_group_event_timestamp([]) == nil
    assert Common.strip_device_from_jid(nil) == ""
    refute Common.lid_jid?(nil)
    assert Common.chat_target(nil, %{store: :invalid}) == nil
    assert Common.chat_target(self(), %{}) == self()
    assert Common.chat_target(self(), %{store: :invalid}) == self()
    pid = spawn(fn -> :ok end)
    monitor = Process.monitor(pid)
    assert_receive {:DOWN, ^monitor, :process, ^pid, _}
    assert Common.resolve_store_from_target(pid) == nil
  end
end
