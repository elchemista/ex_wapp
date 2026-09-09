Application.put_env(:ex_wapp, :json_library, JSON)

# Exercise diagnostic logging too: log_redaction_test and the protocol integration
# tests assert that debug output never contains message bodies or private keys.
# Capture per-test output so successful runs remain readable.
Logger.configure(level: :debug)
ExUnit.start(capture_log: true)

Code.require_file("support/protocol_peer.exs", __DIR__)
Code.require_file("support/fault_store.exs", __DIR__)
