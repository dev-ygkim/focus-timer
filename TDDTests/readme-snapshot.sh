#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUTPUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/focus-timer-readme-snapshot.XXXXXX")"
trap 'rm -rf "$OUTPUT_DIR"' EXIT

test -f "$ROOT_DIR/Tools/FocusTimerReadmeSnapshot/main.swift"
grep -Fq 'FocusTimerReadmeSnapshot' "$ROOT_DIR/Package.swift"

for panel in timer settings profiles; do
  output="$OUTPUT_DIR/$panel.png"
  swift run FocusTimerReadmeSnapshot "$output" "$panel" >/dev/null
  test -s "$output"
  file "$output" | grep -Fq 'PNG image data'
done

printf 'README snapshot test passed.\n'
