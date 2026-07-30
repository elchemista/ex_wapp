# Warnings we accept, with the reason. Keep this list short: every entry hides a
# real dialyzer finding, so prefer fixing the code.
[
  # Signal.encrypt/2 currently cannot return an error tuple, so dialyzer reports
  # the {:error, _} branch as unreachable. The branch is deliberate and carries
  # its own comment at the call site: without it a CaseClauseError would escape
  # the encryptor's per-target error handling and abort the whole multi-device
  # fanout, instead of recording just that target as failed.
  {"lib/ex_wapp/signal/session_store.ex", :pattern_match}
]
