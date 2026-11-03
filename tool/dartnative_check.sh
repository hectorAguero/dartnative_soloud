#!/usr/bin/env bash
# Checks the DartNative fork after merging upstream (see DARTNATIVE.md).
#
#   tool/dartnative_check.sh           imports + analysis
#   tool/dartnative_check.sh --build   also builds dn_example for iOS sim + Android
set -euo pipefail

cd "$(dirname "$0")/.."

DN="$(command -v dn || echo "$HOME/zero/bin/dn")"
DART="$(dirname "$DN")/dart"
[ -x "$DN" ] || { echo "dn not found: install DartNative or add it to PATH" >&2; exit 1; }

echo "== Flutter-only imports in lib/"
# Upstream code must reach Flutter APIs through lib/src/dartnative/.
leaks="$(grep -rnE "^import '(package:flutter/|package:path_provider/|dart:ui')" lib || true)"
if [ -n "$leaks" ]; then
  echo "$leaks"
  echo "Route these through lib/src/dartnative/flutter_compat.dart." >&2
  exit 1
fi
echo "none"

echo "== Analyze package"
# dn resolves the package, then exits non-zero over the upstream Flutter
# example/ (flutter_test), which the fork keeps on purpose. A real resolution
# failure still shows up in the analysis below.
"$DN" pub get >/dev/null 2>&1 || true
"$DART" analyze lib

echo "== Analyze dn_example"
(cd dn_example && "$DN" pub get >/dev/null && "$DN" analyze --no-fatal-infos)

if [ "${1:-}" = "--build" ]; then
  echo "== Build dn_example"
  (cd dn_example && "$DN" build ios --simulator --debug && "$DN" build apk --debug)
fi

echo "OK"
