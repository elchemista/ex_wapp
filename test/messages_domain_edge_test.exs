defmodule ExWapp.MessagesDomainEdgeTest do
  @moduledoc """
  Wire-format coverage for the message builders in `ExWapp.Messages`.

  The builders assemble protox structs generated from WhatsApp's official
  protos, but the receiving phone decodes bytes, not structs — so these
  assertions encode each payload and parse it back into
  `{field, wire_type, value}` triples, pinning every field to its protobuf
  number and wire type independently of the encoder implementation.
  """

  use ExUnit.Case, async: true

  import Bitwise

  alias ExWapp.Binary.Node
  alias ExWapp.Media.Upload
  alias ExWapp.Messages
  alias WAWebProtobufsE2E.ContextInfo

  @jid "15550001111@s.whatsapp.net"
  @group "120363000000000000@g.us"

  describe "generate_id/1" do
    # WhatsApp ties several server behaviors to the web-client id shape; ids
    # in another format are treated as coming from a different client class.
    test "ids are 3EB0 plus 18 uppercase hex characters" do
      for own_jid <- [nil, "", @jid, "15550001111:17@s.whatsapp.net"] do
        id = Messages.generate_id(own_jid)

        assert byte_size(id) == 22
        assert <<"3EB0", tail::binary-18>> = id
        assert tail =~ ~r/\A[0-9A-F]{18}\z/
      end
    end

    test "consecutive ids differ" do
      ids = for _ <- 1..64, do: Messages.generate_id(@jid)
      assert length(Enum.uniq(ids)) == 64
    end
  end

  describe "build_text_proto/2" do
    test "plain text rides the conversation field" do
      assert %{conversation: "ciao", extendedTextMessage: nil} =
               Messages.build_text_proto("ciao")
    end

    test "a quote upgrades the message to extendedTextMessage" do
      proto = Messages.build_text_proto("reply", quoted_id: "3EB0AA", quoted_participant: @jid)

      assert proto.conversation == nil
      assert proto.extendedTextMessage.text == "reply"

      assert %ContextInfo{stanzaID: "3EB0AA", participant: @jid} =
               proto.extendedTextMessage.contextInfo
    end

    test "mentions alone also upgrade the message and carry no stanza id" do
      proto = Messages.build_text_proto("hey @x", mentions: [@jid])

      assert proto.conversation == nil

      assert %ContextInfo{stanzaID: nil, mentionedJID: [@jid]} =
               proto.extendedTextMessage.contextInfo
    end
  end

  describe "build_context_info/1" do
    test "no quote and no mentions build no context at all" do
      # An empty ContextInfo still serializes to bytes the phone must parse;
      # nil keeps the message in its simplest form.
      assert Messages.build_context_info([]) == nil
      assert Messages.build_context_info(mentions: []) == nil
    end
  end

  describe "image proto wire format" do
    test "every populated field lands on its protobuf number and wire type" do
      upload = upload_fixture()

      payload =
        Messages.build_image_proto(upload,
          caption: "look",
          height: 480,
          width: 640,
          jpeg_thumbnail: <<0xFF, 0xD8>>,
          view_once: true
        )
        |> message_field(3)

      fields = decode_fields(payload)

      assert {1, :ld, upload.url} in fields
      assert {2, :ld, "image/jpeg"} in fields
      assert {3, :ld, "look"} in fields
      assert {4, :ld, upload.file_sha256} in fields
      assert {5, :varint, upload.file_length} in fields
      assert {6, :varint, 480} in fields
      assert {7, :varint, 640} in fields
      assert {8, :ld, upload.media_key} in fields
      assert {9, :ld, upload.file_enc_sha256} in fields
      assert {11, :ld, upload.direct_path} in fields
      assert {12, :varint, upload.media_key_timestamp} in fields
      assert {16, :ld, <<0xFF, 0xD8>>} in fields
      assert {25, :varint, 1} in fields
    end

    test "optional fields are absent rather than encoded empty" do
      # An empty caption field would render as a blank caption on the phone
      # instead of no caption.
      payload = Messages.build_image_proto(upload_fixture()) |> message_field(3)
      field_numbers = payload |> decode_fields() |> Enum.map(&elem(&1, 0))

      refute 3 in field_numbers
      refute 6 in field_numbers
      refute 16 in field_numbers
      refute 25 in field_numbers
    end

    test "a quoted reply embeds ContextInfo on field 17" do
      payload =
        Messages.build_image_proto(upload_fixture(),
          quoted_id: "3EB0AA",
          quoted_participant: @jid,
          mentions: ["15550002222@s.whatsapp.net"]
        )
        |> message_field(3)

      {17, :ld, context} = payload |> decode_fields() |> List.keyfind(17, 0)
      context_fields = decode_fields(context)

      assert {1, :ld, "3EB0AA"} in context_fields
      assert {2, :ld, @jid} in context_fields
      assert {15, :ld, "15550002222@s.whatsapp.net"} in context_fields
    end
  end

  describe "audio proto wire format" do
    test "duration falls back from :seconds to :duration to zero" do
      upload = upload_fixture()

      seconds = fn opts ->
        payload = Messages.build_audio_proto(upload, opts) |> message_field(8)
        {5, :varint, value} = List.keyfind(decode_fields(payload), 5, 0)
        value
      end

      assert seconds.(seconds: 12) == 12
      assert seconds.(duration: 7) == 7
      assert seconds.(seconds: 12, duration: 7) == 12
      assert seconds.([]) == 0
    end

    test "the push-to-talk flag is always present so a voice note is explicit" do
      upload = upload_fixture()

      ptt = fn opts ->
        payload = Messages.build_audio_proto(upload, opts) |> message_field(8)
        {6, :varint, value} = List.keyfind(decode_fields(payload), 6, 0)
        value
      end

      assert ptt.([]) == 0
      assert ptt.(ptt: true) == 1
    end

    test "the waveform rides field 19" do
      waveform = :binary.copy(<<7>>, 64)

      payload =
        Messages.build_audio_proto(upload_fixture(), waveform: waveform) |> message_field(8)

      assert {19, :ld, waveform} in decode_fields(payload)
    end
  end

  describe "document proto wire format" do
    test "a document without a name still carries one" do
      # WhatsApp displays field 8 as the file name; a missing field renders
      # as an unnamed attachment on some clients.
      payload = Messages.build_document_proto(upload_fixture()) |> message_field(7)

      assert {8, :ld, "document"} in decode_fields(payload)
    end

    test "title, page count and vcard flag land on their fields" do
      payload =
        Messages.build_document_proto(upload_fixture(),
          title: "Q3 report",
          file_name: "q3.pdf",
          page_count: 14,
          contact_vcard: true
        )
        |> message_field(7)

      fields = decode_fields(payload)
      assert {3, :ld, "Q3 report"} in fields
      assert {8, :ld, "q3.pdf"} in fields
      assert {6, :varint, 14} in fields
      assert {12, :varint, 1} in fields
    end

    test "the caption rides field 20, not the title field" do
      # DocumentMessage keeps title (3) and caption (20) distinct; a caption
      # landing on 3 would silently replace the display title.
      payload =
        Messages.build_document_proto(upload_fixture(), caption: "read me") |> message_field(7)

      fields = decode_fields(payload)
      assert {20, :ld, "read me"} in fields
      refute {3, :ld, "read me"} in fields
    end
  end

  describe "contact proto wire format" do
    test "display name and vcard land on fields 1 and 16 of message field 4" do
      vcard = "BEGIN:VCARD\nVERSION:3.0\nFN:Mario\nEND:VCARD"
      payload = Messages.build_contact_proto("Mario", vcard) |> message_field(4)

      fields = decode_fields(payload)
      assert {1, :ld, "Mario"} in fields
      assert {16, :ld, vcard} in fields
      refute List.keyfind(fields, 18, 0)
    end

    test "the self-contact flag rides field 18 only when requested" do
      payload =
        Messages.build_contact_proto("Me", "BEGIN:VCARD\nEND:VCARD", is_self_contact: true)
        |> message_field(4)

      assert {18, :varint, 1} in decode_fields(payload)
    end
  end

  describe "location proto wire format" do
    test "coordinates travel as little-endian doubles" do
      payload = Messages.build_location_proto(45.4642, 9.19, []) |> message_field(5)
      fields = decode_fields(payload)

      assert {1, :fixed64, <<45.4642::little-float-64>>} in fields
      assert {2, :fixed64, <<9.19::little-float-64>>} in fields
    end

    test "integer coordinates are promoted to doubles rather than varints" do
      # encode_double_field multiplies by 1.0; an integer slipping through as
      # a varint would shift every following byte.
      payload = Messages.build_location_proto(45, 9, []) |> message_field(5)
      fields = decode_fields(payload)

      assert {1, :fixed64, <<45.0::little-float-64>>} in fields
      assert {2, :fixed64, <<9.0::little-float-64>>} in fields
    end

    test "live-location extras use their exact wire types" do
      payload =
        Messages.build_location_proto(1.5, -2.5,
          name: "Piazza",
          is_live: true,
          accuracy: 12,
          speed: 3.5,
          bearing: 270
        )
        |> message_field(5)

      fields = decode_fields(payload)
      assert {3, :ld, "Piazza"} in fields
      assert {6, :varint, 1} in fields
      assert {7, :varint, 12} in fields
      assert {8, :fixed32, <<3.5::little-float-32>>} in fields
      assert {9, :varint, 270} in fields
    end

    test "address, url, comment and thumbnail land on 4, 5, 11 and 16" do
      payload =
        Messages.build_location_proto(1.5, -2.5,
          address: "Via Roma 1",
          url: "https://maps.example/x",
          comment: "meet here",
          jpeg_thumbnail: <<0xFF, 0xD8>>
        )
        |> message_field(5)

      fields = decode_fields(payload)
      assert {4, :ld, "Via Roma 1"} in fields
      assert {5, :ld, "https://maps.example/x"} in fields
      assert {11, :ld, "meet here"} in fields
      assert {16, :ld, <<0xFF, 0xD8>>} in fields
    end
  end

  describe "event proto wire format" do
    test "name and start time land on fields 3 and 7, DateTime included" do
      start = ~U[2026-07-29 18:00:00Z]
      {_ctx, payload} = Messages.build_event_proto("standup", start) |> event_fields()

      fields = decode_fields(payload)
      assert {3, :ld, "standup"} in fields
      assert {7, :varint, DateTime.to_unix(start)} in fields
    end

    test "a supplied 32-byte message secret is used verbatim" do
      secret = :binary.copy(<<0xAB>>, 32)

      {context, _payload} =
        Messages.build_event_proto("standup", 1_800_000_000, message_secret: secret)
        |> event_fields()

      assert decode_fields(context) == [{3, :ld, secret}]
    end

    test "an invalid secret is replaced by a random 32-byte one" do
      # A short secret would break the phone's message-secret handling; the
      # builder must never forward one.
      {context, _} =
        Messages.build_event_proto("standup", 1_800_000_000, message_secret: <<1, 2, 3>>)
        |> event_fields()

      assert [{3, :ld, secret}] = decode_fields(context)
      assert byte_size(secret) == 32
      refute secret == <<1, 2, 3>>
    end

    test "an event location nests a full location payload on field 5" do
      {_, payload} =
        Messages.build_event_proto("standup", 1_800_000_000,
          location: %{latitude: 45.4642, longitude: 9.19, name: "Piazza"}
        )
        |> event_fields()

      {5, :ld, location} = payload |> decode_fields() |> List.keyfind(5, 0)
      location_fields = decode_fields(location)

      assert {1, :fixed64, <<45.4642::little-float-64>>} in location_fields
      assert {2, :fixed64, <<9.19::little-float-64>>} in location_fields
      assert {3, :ld, "Piazza"} in location_fields
    end

    test "string-keyed location maps work too" do
      {_, payload} =
        Messages.build_event_proto("standup", 1_800_000_000,
          location: %{"latitude" => 1.0, "longitude" => 2.0, "name" => "HQ"}
        )
        |> event_fields()

      {5, :ld, location} = payload |> decode_fields() |> List.keyfind(5, 0)
      assert {3, :ld, "HQ"} in decode_fields(location)
    end

    test "a location without coordinates is dropped, not half-encoded" do
      {_, payload} =
        Messages.build_event_proto("standup", 1_800_000_000, location: %{name: "nowhere"})
        |> event_fields()

      refute payload |> decode_fields() |> List.keyfind(5, 0)
    end

    test "cancellation and reminders ride their optional fields" do
      {_, payload} =
        Messages.build_event_proto("standup", 1_800_000_000,
          canceled: true,
          end_time: 1_800_003_600,
          reminder_offset_seconds: 900
        )
        |> event_fields()

      fields = decode_fields(payload)
      assert {2, :varint, 1} in fields
      assert {8, :varint, 1_800_003_600} in fields
      assert {12, :varint, 900} in fields
    end
  end

  describe "placeholder resend proto" do
    test "a group request from a peer names the device-stripped participant" do
      proto =
        Messages.build_placeholder_resend_proto(
          @group,
          "15550002222:9@s.whatsapp.net",
          "3EB0AA"
        )

      key = extract_message_key(proto)
      assert {1, :ld, @group} in key
      assert {3, :ld, "3EB0AA"} in key
      assert {4, :ld, "15550002222@s.whatsapp.net"} in key
      # MessageKey is proto2: fromMe is an explicit optional bool, so a peer's
      # message carries fromMe=0 on the wire (whatsmeow encodes proto.Bool(false)
      # the same way) rather than omitting the field.
      assert {2, :varint, 0} in key
    end

    test "our own message carries fromMe and no participant" do
      proto =
        Messages.build_placeholder_resend_proto(@group, @jid, "3EB0AA", from_me: true)

      key = extract_message_key(proto)
      assert {2, :varint, 1} in key
      refute List.keyfind(key, 4, 0)
    end

    test "a direct chat never carries a participant" do
      proto = Messages.build_placeholder_resend_proto(@jid, @jid, "3EB0AA")

      refute proto |> extract_message_key() |> List.keyfind(4, 0)
    end

    test "a lid sender in a group is device-stripped the same way" do
      proto =
        Messages.build_placeholder_resend_proto(@group, "70000001111:3@lid", "3EB0AA")

      assert {4, :ld, "70000001111@lid"} in extract_message_key(proto)
    end

    test "a broadcast list also names the participant" do
      proto =
        Messages.build_placeholder_resend_proto(
          "1234567890@broadcast",
          "15550002222:9@s.whatsapp.net",
          "3EB0AA"
        )

      assert {4, :ld, "15550002222@s.whatsapp.net"} in extract_message_key(proto)
    end

    test "the protocol message is a peer data operation request" do
      proto = Messages.build_placeholder_resend_proto(@jid, @jid, "3EB0AA")

      assert proto.protocolMessage.type == :PEER_DATA_OPERATION_REQUEST_MESSAGE
      request = proto |> message_field(12) |> ld_field(16)
      # Operation type 4 = placeholder resend.
      assert {1, :varint, 4} in decode_fields(request)
    end
  end

  describe "receipt and chat-state nodes" do
    test "a receipt names the first id in attrs and every id in the list" do
      node = Messages.build_receipt_node(@jid, ["3EB0AA", "3EB0BB", "3EB0CC"], "read")

      assert %Node{tag: "receipt", attrs: %{"to" => @jid, "type" => "read", "id" => "3EB0AA"}} =
               node

      assert [%Node{tag: "list", content: items}] = node.content
      assert Enum.map(items, & &1.attrs["id"]) == ["3EB0AA", "3EB0BB", "3EB0CC"]
    end

    test "typing toggles between composing and paused" do
      assert %Node{tag: "chatstate", content: [%Node{tag: "composing"}]} =
               Messages.build_typing(@jid)

      assert %Node{tag: "chatstate", content: [%Node{tag: "paused"}]} =
               Messages.build_typing(@jid, false)
    end

    test "typing with a local identity carries from and to" do
      node = Messages.build_typing(@jid, "15550002222@s.whatsapp.net", true)

      assert node.attrs == %{"to" => @jid, "from" => "15550002222@s.whatsapp.net"}
    end

    test "presence subscription is a bare subscribe node" do
      assert %Node{tag: "presence", attrs: %{"to" => @jid, "type" => "subscribe"}, content: nil} =
               Messages.build_presence_subscribe(@jid)
    end
  end

  describe "message node envelope" do
    test "the enc child declares protocol v2 and carries the payload raw" do
      node = Messages.build_message_node(@jid, "3EB0AA", <<1, 2, 3>>, 1_700_000_000)

      assert node.tag == "message"
      assert node.attrs["id"] == "3EB0AA"
      assert node.attrs["to"] == @jid
      assert node.attrs["t"] == "1700000000"

      assert [%Node{tag: "enc", attrs: %{"v" => "2", "type" => "msg"}, content: content}] =
               node.content

      assert content == ExWapp.Binary.raw(<<1, 2, 3>>)
    end
  end

  # -- helpers ----------------------------------------------------------------

  defp upload_fixture do
    %Upload{
      url: "https://mmg.whatsapp.net/d/f/synthetic",
      direct_path: "/v/t62.7118-24/synthetic",
      media_key: :binary.copy(<<1>>, 32),
      file_sha256: :binary.copy(<<2>>, 32),
      file_enc_sha256: :binary.copy(<<3>>, 32),
      file_length: 4096,
      media_key_timestamp: 1_700_000_000
    }
  end

  defp extract_message_key(proto) do
    proto
    |> message_field(12)
    |> ld_field(16)
    |> ld_field(5)
    |> ld_field(1)
    |> decode_fields()
  end

  # Encodes the whole Message and returns the LD payload of one top-level
  # field, so assertions keep reading the exact bytes a phone would parse.
  defp message_field(proto, field_num) do
    proto
    |> WAWebProtobufsE2E.Message.encode!()
    |> IO.iodata_to_binary()
    |> ld_field(field_num)
  end

  defp ld_field(binary, field_num) do
    {^field_num, :ld, value} = binary |> decode_fields() |> List.keyfind(field_num, 0)
    value
  end

  defp event_fields(proto) do
    {message_field(proto, 35), message_field(proto, 75)}
  end

  # A minimal protobuf reader: enough to turn a payload back into
  # {field, wire_type, value} triples so the assertions above stay readable.
  defp decode_fields(binary), do: do_decode_fields(binary, [])

  defp do_decode_fields(<<>>, acc), do: Enum.reverse(acc)

  defp do_decode_fields(binary, acc) do
    {key, rest} = varint(binary)
    field = bsr(key, 3)

    case band(key, 0x07) do
      0 ->
        {value, rest} = varint(rest)
        do_decode_fields(rest, [{field, :varint, value} | acc])

      1 ->
        <<value::binary-8, rest::binary>> = rest
        do_decode_fields(rest, [{field, :fixed64, value} | acc])

      2 ->
        {length, rest} = varint(rest)
        <<value::binary-size(^length), rest::binary>> = rest
        do_decode_fields(rest, [{field, :ld, value} | acc])

      5 ->
        <<value::binary-4, rest::binary>> = rest
        do_decode_fields(rest, [{field, :fixed32, value} | acc])
    end
  end

  defp varint(binary, shift \\ 0, acc \\ 0)

  defp varint(<<1::1, chunk::7, rest::binary>>, shift, acc),
    do: varint(rest, shift + 7, acc + bsl(chunk, shift))

  defp varint(<<0::1, chunk::7, rest::binary>>, shift, acc),
    do: {acc + bsl(chunk, shift), rest}
end
