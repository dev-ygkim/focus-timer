#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
THEME="$ROOT_DIR/Sources/FocusTimerUI/FocusTheme.swift"
TIMER="$ROOT_DIR/Sources/FocusTimerUI/TimerPopoverView.swift"
SETTINGS="$ROOT_DIR/Sources/FocusTimerUI/SettingsView.swift"
PROFILES="$ROOT_DIR/Sources/FocusTimerUI/ProfileListView.swift"

test -f "$THEME"
grep -Fq 'FocusPrimaryButtonStyle' "$THEME"
grep -Fq 'FocusSecondaryButtonStyle' "$THEME"
grep -Fq 'FocusTheme.background' "$TIMER"
grep -Fq 'Circle()' "$TIMER"
grep -Fq 'FocusPrimaryButtonStyle' "$TIMER"
grep -Fq '@FocusState private var isPrimaryActionFocused' "$TIMER"
grep -Fq '.focused($isPrimaryActionFocused)' "$TIMER"
grep -Fq 'isPrimaryActionFocused = false' "$TIMER"
grep -Fq 'FocusTheme.background' "$SETTINGS"
grep -Fq 'FocusPrimaryButtonStyle' "$SETTINGS"
grep -Fq 'FocusTheme.background' "$PROFILES"
grep -Fq 'FocusPrimaryButtonStyle' "$PROFILES"

if grep -Fq '.buttonStyle(.borderedProminent)' "$TIMER" || grep -Fq 'Form {' "$SETTINGS"; then
  echo "기본 SwiftUI 버튼 또는 Form이 남아 있습니다." >&2
  exit 1
fi

printf 'Custom menu UI style test passed.\n'
