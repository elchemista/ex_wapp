defmodule ExWapp.DiagnosticsContractTest do
  @moduledoc """
  Covers the seams that decide how long a protocol bug takes to find: whether a
  rejection carries a usable reason, whether redacted logs can still be joined
  together, and whether a stale default or a half-implemented adapter announces
  itself instead of degrading in silence.
  """

  use ExUnit.Case, async: true

  alias ExWapp.Config
  alias ExWapp.Error.Ack
  alias ExWapp.JID
  alias ExWapp.Log
  alias ExWapp.Store
  alias ExWapp.Store.Memory

  describe "ack rejection vocabulary" do
    test "463 is retriable but only after repairing the session" do
      assert %Ack{category: :session, retriable?: true, detail: detail} = Ack.classify("463")
      assert detail =~ "session"
    end

    test "a transient server refusal is retriable" do
      assert %Ack{category: :transient, retriable?: true} = Ack.classify("479")
    end

    test "an authorization refusal is not retriable" do
      assert %Ack{category: :permanent, retriable?: false} = Ack.classify("403")
    end

    test "an unrecognised code is not retriable" do
      # The conservative direction matters: retrying into a policy refusal is
      # how a number gets rate limited, whereas failing a transient send costs
      # one message.
      assert %Ack{category: :unknown, retriable?: false} = Ack.classify("799")
      assert %Ack{category: :unknown, retriable?: false} = Ack.classify("")
      assert %Ack{category: :unknown, retriable?: false} = Ack.classify(nil)
    end

    test "the raw code survives classification" do
      # Whatever we failed to classify must still reach the operator's logs.
      assert %Ack{code: "799"} = Ack.classify("799")
    end
  end

  describe "log correlation under redaction" do
    test "a correlation key fingerprints to the same value as a direct reference" do
      # This is the property that makes a redacted log debuggable: the `to` on
      # the wire node and the recipient in the send line must resolve to one
      # token, or the two halves of a send cannot be tied together.
      jid = "70000004444@lid"
      assert Log.attrs(%{"to" => jid})["to"] == Log.reference(jid)
    end

    test "a JID struct fingerprints identically to the same JID as a string" do
      # Attributes arrive parsed in some paths and raw in others; if those
      # produce different tokens the correlation silently breaks for exactly
      # the identities worth correlating.
      string = "70000004444@lid"
      {:ok, struct} = JID.parse(string)

      assert Log.attrs(%{"from" => struct})["from"] == Log.reference(string)
    end

    test "payload attributes stay blanked rather than fingerprinted" do
      # A short secret is brute-forceable from its fingerprint, and correlating
      # message text has no diagnostic value, so these must not become tokens.
      secret = "private-message-text"
      redacted = Log.attrs(%{"text" => secret, "auth" => "token"})

      assert redacted["text"] == "[FILTERED]"
      assert redacted["auth"] == "[FILTERED]"
    end

    test "no correlation token contains the value it stands for" do
      jid = "15550004444@s.whatsapp.net"
      refute Log.attrs(%{"to" => jid})["to"] =~ "15550004444"
    end

    test "distinct identities do not collide onto one token" do
      a = Log.attrs(%{"to" => "111@lid"})["to"]
      b = Log.attrs(%{"to" => "222@lid"})["to"]
      refute a == b
    end
  end

  describe "client version staleness" do
    test "the built-in default reports its age" do
      assert {status, age} = Config.client_version_status(Config.default_client_version())
      assert status in [:ok, :stale]
      assert is_integer(age)
    end

    test "the built-in default eventually reports itself stale" do
      far_future = Date.add(Date.utc_today(), 5_000)

      assert {:stale, _age} =
               Config.client_version_status(Config.default_client_version(), far_future)
    end

    test "a caller-supplied version is never judged" do
      # The library has no basis for an opinion about a version it did not ship.
      supplied = %{primary: 2, secondary: 3000, tertiary: 1_043_423_438}

      assert :overridden =
               Config.client_version_status(supplied, Date.add(Date.utc_today(), 5_000))
    end
  end

  describe "store adapter capability reporting" do
    defmodule BareAdapter do
      @moduledoc false
      @behaviour ExWapp.Store
      defstruct []

      @impl true
      def new(_opts), do: %__MODULE__{}
      @impl true
      def load(_store), do: {:ok, %{}}
      @impl true
      def persist(_store, _data), do: :ok
    end

    test "the reference adapter implements every callback whose fallback would diverge" do
      # `Memory` legitimately omits `flush/1` — there is nothing to flush — and
      # the generic no-op is the right behaviour there. What must never be
      # missing are the message callbacks, whose fallbacks operate on different
      # state than a real implementation would.
      missing = Store.missing_optional_callbacks(Memory.new())

      refute {:update_message_status, 4} in missing
      refute {:update_message_status_by_id, 3} in missing
      refute {:find_message, 3} in missing
      refute {:upsert_messages, 3} in missing
    end

    test "an adapter missing message callbacks names them" do
      # Without this the substitution is invisible: the generic fallback has
      # different semantics and there is no compile-time signal at all.
      missing = Store.missing_optional_callbacks(%BareAdapter{})

      assert {:update_message_status, 4} in missing
      assert {:find_message, 3} in missing
      assert {:upsert_messages, 3} in missing
    end
  end
end
