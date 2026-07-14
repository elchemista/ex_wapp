defmodule ExWapp.JIDProtocolParityTest do
  use ExUnit.Case, async: true

  alias ExWapp.JID

  describe "parse/1" do
    test "parses user, server and linked-device forms" do
      assert {:ok, %JID{user: "1234", server: "s.whatsapp.net", device: 0}} =
               JID.parse("1234@s.whatsapp.net")

      assert {:ok, %JID{user: "1234", server: "s.whatsapp.net", device: 7}} =
               JID.parse("1234:7@s.whatsapp.net")
    end

    test "keeps server-only JIDs used by protocol attributes" do
      assert {:ok, %JID{user: "", server: "s.whatsapp.net"}} = JID.parse("s.whatsapp.net")
    end

    test "malformed device segments degrade safely instead of raising" do
      assert {:ok, %JID{user: "1234", device: 0, server: "s.whatsapp.net"}} =
               JID.parse("1234:xx@s.whatsapp.net")

      assert {:ok, %JID{user: "1234", device: 0}} =
               JID.parse("1234:-1@s.whatsapp.net")
    end

    test "rejects non-binary and ambiguous JIDs" do
      assert {:error, :invalid_jid} = JID.parse(nil)
      assert {:error, :invalid_jid} = JID.parse(1234)
      assert {:error, :invalid_jid} = JID.parse("a@b@c")
    end
  end

  describe "predicates" do
    test "recognizes user, group and broadcast servers" do
      assert JID.user?("1234@s.whatsapp.net")
      assert JID.group?("1203630@g.us")
      assert JID.broadcast?("status@broadcast")

      refute JID.user?("1203630@g.us")
      refute JID.group?("1234@s.whatsapp.net")
      refute JID.broadcast?("1234@s.whatsapp.net")
    end

    test "handles structs, nil and non-binary input" do
      assert JID.group?(%JID{user: "1203630", server: "g.us"})
      assert JID.user?(%JID{user: "1234", server: "s.whatsapp.net"})

      refute JID.group?(nil)
      refute JID.broadcast?(%{})
      refute JID.user?([])
    end
  end

  describe "AD JID domain mapping" do
    test "maps WhatsApp, LID and hosted agents without changing the public API" do
      whatsapp = JID.new_ad("1234", 0, 2)
      lid = JID.new_ad("1234", 1, 3)
      hosted = JID.new_ad("1234", 128, 4)

      assert %JID{server: "s.whatsapp.net", raw_agent: 0, device: 2} = whatsapp
      assert %JID{server: "lid", raw_agent: 0, device: 3} = lid
      assert %JID{server: "hosted", raw_agent: 128, device: 4} = hosted

      assert JID.actual_agent(whatsapp) == 0
      assert JID.actual_agent(lid) == 1
      assert JID.actual_agent(hosted) == 128
    end

    test "renders device and hosted-agent forms deterministically" do
      assert JID.to_string(%JID{user: "1234", device: 5}) ==
               "1234:5@s.whatsapp.net"

      assert JID.new_ad("1234", 128, 2) |> JID.to_string() ==
               "1234.128:2@hosted"
    end
  end

  test "with_device/2 and with_integrator/2 only replace the requested component" do
    jid =
      JID.new("1234", "interop")
      |> JID.with_device(9)
      |> JID.with_integrator(17)

    assert %JID{user: "1234", server: "interop", device: 9, integrator: 17} = jid
  end

  test "String.Chars uses the canonical wire representation" do
    jid = %JID{user: "1234", device: 2, server: "lid"}
    assert "#{jid}" == "1234:2@lid"
  end
end
