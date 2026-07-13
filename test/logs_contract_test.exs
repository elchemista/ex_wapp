defmodule ExWapp.LogsContractTest do
  use ExUnit.Case, async: true

  @jid_pattern ~r/\b\d{6,}(?::\d+)?@(?:s\.whatsapp\.net|whatsapp\.net|lid|hosted\.lid)\b/
  @jid_capture_pattern ~r/\b(\d{6,})(?::\d+)?@(?:s\.whatsapp\.net|whatsapp\.net|lid|hosted\.lid)\b/
  @raw_number_pattern ~r/\b\d{10,15}\b/

  @event_patterns [
    {:usync_query, ~r/\[USYNC\] Querying device list/},
    {:usync_map, ~r/\[SEND\] USync device map:/},
    {:prekey_request, ~r/\[PREKEY\] Sending batch prekey request/},
    {:session_created, ~r/\[SIGNAL\] Session created with X3DH \+ initial ratchet/},
    {:self_chat, ~r/\[SEND\] Self-chat detected:/},
    {:encrypt_attempt, ~r/\[ENCRYPTION\] Attempting to encrypt message/},
    {:encrypted, ~r/\[ENCRYPTION\] Encrypted!/},
    {:sent_message, ~r/\[SEND\] Sent encrypted message/},
    {:message_node, ~r/Sending node: <message /},
    {:ack_message, ~r/\[ACK\].*(?:class=message.*id=|id=.*class=message)/}
  ]

  @simulated_send_call_log """
  [USYNC] Querying device list for ["<JID_BASE>"]
  [SEND] USync device map: %{"<JID_BASE>" => ["<JID_BASE>", "<JID_DEVICE>"]}
  [PREKEY] Sending batch prekey request for 2 devices
  [SIGNAL] Session created with X3DH + initial ratchet
  [ENCRYPTION] Attempting to encrypt message for <JID_BASE> (sync)
  [ENCRYPTION] Encrypted! type=prekey, size=217
  [SEND] Sent encrypted message to <JID_BASE> id=<MESSAGE_ID>
  Sending node: <message id="<MESSAGE_ID>" to="<JID_BASE>" type="text"><participants>...</participants></message>
  [ACK] class=message type= id=<MESSAGE_ID> from=<JID_BASE> to=
  """

  test "tracked source/docs/tests do not leak sensitive phone identifiers from logs" do
    {_path, raw_log} = load_log_source()
    sensitive_numbers = sensitive_numbers_from_log(raw_log)

    files =
      [
        "lib/**/*.ex",
        "test/**/*.exs",
        "*.md"
      ]
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.filter(&File.regular?/1)
      |> Enum.uniq()

    offenders =
      Enum.flat_map(files, fn path ->
        content = File.read!(path)
        leaked = Enum.filter(sensitive_numbers, &String.contains?(content, &1))

        if leaked == [] do
          []
        else
          [{path, leaked}]
        end
      end)

    assert offenders == [],
           "sensitive phone identifiers from logs leaked into tracked files: #{inspect(offenders)}"
  end

  test "log redaction strips jid-like values from raw logs" do
    {_path, raw_log} = load_log_source()
    sensitive_numbers = sensitive_numbers_from_log(raw_log)
    redacted = redact_sensitive(raw_log)

    refute Regex.match?(@jid_pattern, redacted)

    Enum.each(sensitive_numbers, fn number ->
      refute String.contains?(redacted, number)
    end)
  end

  test "simulated send-call flow matches real log flow shape" do
    {_path, raw_log} = load_log_source()

    real_signature =
      raw_log
      |> redact_sensitive()
      |> flow_signature()

    simulated_signature = flow_signature(@simulated_send_call_log)

    assert subsequence?(real_signature, simulated_signature),
           "expected simulated flow #{inspect(simulated_signature)} to appear in real flow #{inspect(real_signature)}"
  end

  defp load_log_source do
    candidates = [
      "tmp/logs_10.txt",
      "tmp/logs_9.txt",
      "tmp/logs.txt",
      "test/fixtures/send_flow_contract.log"
    ]

    case Enum.find(candidates, &File.exists?/1) do
      nil ->
        flunk("no log source found (checked #{inspect(candidates)})")

      path ->
        {path, File.read!(path)}
    end
  end

  defp redact_sensitive(log_text) when is_binary(log_text) do
    log_text
    |> then(&Regex.replace(@jid_pattern, &1, "<JID>"))
    |> then(&Regex.replace(@raw_number_pattern, &1, "<NUM>"))
  end

  defp flow_signature(log_text) when is_binary(log_text) do
    log_text
    |> String.split("\n", trim: true)
    |> Enum.map(&detect_event/1)
    |> Enum.reject(&is_nil/1)
    |> dedupe_consecutive()
  end

  defp detect_event(line) do
    Enum.find_value(@event_patterns, fn {event, regex} ->
      if Regex.match?(regex, line), do: event, else: nil
    end)
  end

  defp dedupe_consecutive(events) do
    events
    |> Enum.reduce([], fn event, acc ->
      case acc do
        [^event | _] -> acc
        _ -> [event | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp subsequence?(_events, []), do: true
  defp subsequence?([], _expected), do: false

  defp subsequence?([event | rest], [event | expected_rest]),
    do: subsequence?(rest, expected_rest)

  defp subsequence?([_event | rest], expected),
    do: subsequence?(rest, expected)

  defp sensitive_numbers_from_log(raw_log) do
    @jid_capture_pattern
    |> Regex.scan(raw_log, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
  end
end
