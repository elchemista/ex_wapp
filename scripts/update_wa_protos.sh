#!/usr/bin/env bash
#
# Pulls WhatsApp's official proto definitions from whatsmeow upstream,
# regenerates the protox modules in lib/ex_wapp/wa_proto, and verifies the
# result compiles and still passes the wire-format tests.
#
# Usage:
#   scripts/update_wa_protos.sh              # fetch upstream, regenerate, verify
#   SKIP_FETCH=1 scripts/update_wa_protos.sh # regenerate from the local checkout
#
# Requirements: git, protoc, mix (protox is a project dependency).
#
# whatsmeow extracts these protos from the WhatsApp Web bundle and keeps them
# current; this script makes protocol updates a pull-regenerate-test loop.
# After running, review `git diff lib/ex_wapp/wa_proto` — new fields are
# routine, but renamed or renumbered fields deserve a close look.

set -euo pipefail
cd "$(dirname "$0")/.."

UPSTREAM_REPO="${UPSTREAM_REPO:-https://github.com/tulir/whatsmeow.git}"
UPSTREAM_DIR="tmp/whatsmeow_upstream"
OUT_DIR="lib/ex_wapp/wa_proto"

# Every proto set the project generates. waE2E transitively pulls in
# waCommon, waAdv, waCompanionReg, waMmsRetry, waStatusAttributions and
# waAICommon*; waHistorySync pulls in waSyncAction, waWeb and
# waChatLockSettings; waCert and waWa6 are standalone.
ENTRYPOINTS=(
  "$UPSTREAM_DIR/proto/waE2E/WAWebProtobufsE2E.proto"
  "$UPSTREAM_DIR/proto/waHistorySync/WAWebProtobufsHistorySync.proto"
  "$UPSTREAM_DIR/proto/waSyncAction/WAWebProtobufSyncAction.proto"
  "$UPSTREAM_DIR/proto/waCert/WACert.proto"
  "$UPSTREAM_DIR/proto/waWa6/WAWebProtobufsWa6.proto"
)

step() { printf '\n\033[1m== %s\033[0m\n' "$1"; }

step "Fetching upstream protos"
if [[ "${SKIP_FETCH:-0}" == "1" ]]; then
  echo "SKIP_FETCH=1 — using the existing checkout as-is"
elif [[ -d "$UPSTREAM_DIR/.git" ]]; then
  git -C "$UPSTREAM_DIR" fetch --depth 1 origin main
  git -C "$UPSTREAM_DIR" reset --hard origin/main --quiet
else
  rm -rf "$UPSTREAM_DIR"
  git clone --depth 1 "$UPSTREAM_REPO" "$UPSTREAM_DIR"
fi
echo "upstream at: $(git -C "$UPSTREAM_DIR" log -1 --format='%h %cs %s' 2>/dev/null || echo 'local snapshot')"

for entry in "${ENTRYPOINTS[@]}"; do
  [[ -f "$entry" ]] || { echo "missing entrypoint: $entry (upstream layout changed?)" >&2; exit 1; }
done

step "Regenerating protox modules"
# Generate into a staging dir and sync with --delete so modules that vanish
# upstream do not linger as stale files in lib.
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

mix protox.generate \
  --output-path="$STAGING" \
  --include-path="$UPSTREAM_DIR/proto" \
  --multiple-files \
  "${ENTRYPOINTS[@]}"

step "Declaring struct typespecs"
# protox emits no @type t, which would make every `Module.t()` in our specs an
# unknown type to dialyzer. Add it here rather than hand-editing the output.
elixir scripts/add_proto_typespecs.exs "$STAGING"

mkdir -p "$OUT_DIR"
rsync -a --delete "$STAGING"/ "$OUT_DIR"/
echo "generated $(ls "$OUT_DIR" | wc -l) modules"

step "Formatting"
mix format "$OUT_DIR/*.ex"

step "Compiling"
mix compile --warnings-as-errors

step "Running wire-format tests"
mix test test/wa_proto_e2e_parity_test.exs test/messages_domain_edge_test.exs \
  test/proto_message_media_test.exs test/whatsmeow_parity_test.exs

step "Done"
if [[ -z "$(git status --porcelain -- "$OUT_DIR")" ]]; then
  echo "wa_proto is already up to date — no changes."
else
  git diff --stat -- "$OUT_DIR" | tail -3
  echo "Review with: git diff $OUT_DIR"
  echo "Then run the full suite: mix test"
fi
