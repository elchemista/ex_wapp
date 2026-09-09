defmodule ExWapp.IQCompatibilityTest do
  use ExUnit.Case, async: true
  alias ExWapp.Binary.{Node, Raw}
  alias ExWapp.Session.IQ
  @moduletag capture_log: true

  test "incomplete directory results cannot create unusable Signal bundles" do
    device = ExWapp.Test.SignalDevice.new()
    valid = ExWapp.Test.SignalDevice.user(device, "123:7@s.whatsapp.net")

    invalid = [
      %Node{tag: "user"},
      %Node{tag: "user", content: []},
      %{valid | content: Enum.reject(valid.content, &(&1.tag == "identity"))},
      %{valid | content: replace_child(valid.content, "skey", nil)},
      %{valid | content: replace_child(valid.content, "identity", [nil])}
    ]

    for user <- invalid do
      assert {:error, :no_valid_bundles_in_response} =
               IQ.parse_prekey_response(result([%Node{tag: "list", content: [user]}]))

      assert {:ok, [bundle]} =
               IQ.parse_prekey_response(result([%Node{tag: "list", content: [user, valid]}]))

      assert bundle.device_jid == "123:7@s.whatsapp.net"
      assert bundle.identity_key == device.identity.public
    end

    assert {:error, :no_list_in_response} = IQ.parse_prekey_response(result([]))

    assert %Node{content: [%Node{content: [%Node{attrs: %{"jid" => "123:7@s.whatsapp.net"}}]}]} =
             IQ.build_prekey_request("123:7@s.whatsapp.net", "request")
  end

  test "legacy raw wrappers and key-id widths preserve key material" do
    device = ExWapp.Test.SignalDevice.new()
    valid = ExWapp.Test.SignalDevice.user(device, "123:7@s.whatsapp.net")

    for {wrap, registration, expected_reg, id, expected_id} <- [
          {fn b -> b end, <<123::32, 0>>, 123, <<0, 1, 0, 1>>, 65537},
          {fn b -> {:raw, b} end, <<1>>, 0, <<42>>, 42},
          {fn b -> [%Raw{data: b}] end, <<123::32>>, 123, <<257::24>>, 257}
        ] do
      content =
        Enum.map(valid.content, fn
          %Node{tag: "registration"} = node ->
            %{node | content: wrap.(registration)}

          %Node{tag: "identity"} = node ->
            %{node | content: wrap.(device.identity.public)}

          %Node{tag: "skey", content: children} = node ->
            %{node | content: replace_child(children, "id", wrap.(id))}

          node ->
            node
        end)

      assert {:ok, [bundle]} =
               IQ.parse_prekey_response(
                 result([%Node{tag: "list", content: [%{valid | content: content}]}])
               )

      assert bundle.registration_id == expected_reg
      assert bundle.signed_prekey.id == expected_id
      assert bundle.signed_prekey.public == device.signed.public
      assert bundle.identity_key == device.identity.public
    end
  end

  test "device lists tolerate missing accounts and primary-only users" do
    users = [
      %Node{tag: "user"},
      %Node{
        tag: "user",
        attrs: %{"jid" => "123@s.whatsapp.net"},
        content: [
          %Node{
            tag: "devices",
            content: [
              %Node{
                tag: "device-list",
                content:
                  Enum.map([7, "0", "garbage", nil], &%Node{tag: "device", attrs: %{"id" => &1}})
              }
            ]
          }
        ]
      },
      %Node{tag: "user", attrs: %{"jid" => "456@s.whatsapp.net"}}
    ]

    assert {:ok, devices} =
             IQ.parse_usync_device_response(
               result([%Node{tag: "usync", content: [%Node{tag: "list", content: users}]}])
             )

    assert devices["123@s.whatsapp.net"] == [
             "123:7@s.whatsapp.net",
             "123@s.whatsapp.net",
             "123@s.whatsapp.net",
             "123@s.whatsapp.net"
           ]

    assert devices["456@s.whatsapp.net"] == ["456@s.whatsapp.net"]
    assert map_size(devices) == 2
    assert {:ok, %{}} = IQ.parse_usync_device_response(result([]))
    assert {:ok, %{}} = IQ.parse_usync_device_response(result([%Node{tag: "usync"}]))
  end

  test "media host lookup traverses containers and excludes empty hostnames" do
    hosts = [
      %Node{tag: "host", attrs: %{"hostname" => "cdn.example.test"}},
      %Node{tag: "host", attrs: %{"name" => "backup.example.test"}},
      %Node{tag: "host", attrs: %{"hostname" => ""}},
      %Node{tag: "other"},
      "unknown"
    ]

    response =
      result([
        %Node{tag: "unknown"},
        %Node{
          tag: "wrapper",
          content: [%Node{tag: "media_conn", attrs: %{"auth" => "token"}, content: hosts}]
        }
      ])

    assert {:ok,
            %{
              auth: "token",
              hosts: [%{hostname: "cdn.example.test"}, %{hostname: "backup.example.test"}]
            }} = IQ.parse_media_conn_response(response)

    assert {:error, :media_conn_not_found} = IQ.parse_media_conn_response(result([]))
    error = %Node{tag: "iq", attrs: %{"type" => "error"}}
    assert {:error, {:media_conn_error, ^error}} = IQ.parse_media_conn_response(error)
    assert {:error, {:usync_error, ^error}} = IQ.parse_usync_device_response(error)
    assert {:error, {:iq_error, ^error}} = IQ.parse_prekey_response(error)

    for value <- [nil, [], "bad", %Node{tag: "iq"}] do
      assert {:error, :invalid_media_conn_response} = IQ.parse_media_conn_response(value)
      assert {:error, :invalid_usync_response} = IQ.parse_usync_device_response(value)
      assert {:error, :invalid_response} = IQ.parse_prekey_response(value)
    end
  end

  defp result(children), do: %Node{tag: "iq", attrs: %{"type" => "result"}, content: children}

  defp replace_child(children, tag, content),
    do:
      Enum.map(children, fn node ->
        if node.tag == tag, do: %{node | content: content}, else: node
      end)
end
