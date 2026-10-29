#!/usr/bin/env bash
# Downloads the drift web runtime (sqlite3.wasm + drift_worker.js) matching
# the resolved package versions into web/. Run after `flutter pub get`.
set -euo pipefail
cd "$(dirname "$0")/.."
ver() { awk -v pkg="  $1:" '$0==pkg{f=1} f&&/version:/{gsub(/"/,"",$2);print $2;exit}' pubspec.lock; }
DRIFT=$(ver drift)
SQLITE=$(ver sqlite3)
echo "drift $DRIFT · sqlite3 $SQLITE"
curl -fsSL -o web/sqlite3.wasm "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${SQLITE}/sqlite3.wasm"
curl -fsSL -o web/drift_worker.js "https://github.com/simolus3/drift/releases/download/drift-${DRIFT}/drift_worker.js"
echo "web/sqlite3.wasm and web/drift_worker.js updated."
