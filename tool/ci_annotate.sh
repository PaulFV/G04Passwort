#!/usr/bin/env bash
# Runs a command; on failure its output is published as GitHub annotations
# (chunked, so long analyzer/test logs are fully visible in the checks UI).
# Usage: tool/ci_annotate.sh "<title>" <command...>
set -o pipefail
title="$1"; shift
log="$(mktemp)"
"$@" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
if [ "$status" -ne 0 ]; then
  # Prefer the relevant lines; fall back to the tail of the log.
  grep -E "error|warning|info -|Error|FAILED|Expected|Actual|\.dart:[0-9]+" "$log" | grep -v "^\s*$" > "$log.rel" || true
  [ -s "$log.rel" ] || tail -n 200 "$log" > "$log.rel"
  split -l 35 "$log.rel" "$log.part."
  n=0
  for part in "$log".part.*; do
    n=$((n+1)); [ $n -gt 9 ] && break
    msg=$(sed -e 's/%/%25/g' "$part" | awk '{printf "%s%%0A", $0}')
    echo "::error title=${title} (${n})::${msg}"
  done
fi
exit "$status"
