#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
POPOVER="$ROOT_DIR/Sources/FocusTimerUI/TimerPopoverView.swift"
SETTINGS="$ROOT_DIR/Sources/FocusTimerUI/SettingsView.swift"
PROFILES="$ROOT_DIR/Sources/FocusTimerUI/ProfileListView.swift"

if grep -Fq '.sheet(' "$POPOVER"; then
  echo "MenuBarExtra 안에서 sheet를 사용하면 안 됩니다." >&2
  exit 1
fi

if grep -Fq '@Environment(\.dismiss)' "$SETTINGS" || grep -Fq '@Environment(\.dismiss)' "$PROFILES"; then
  echo "설정과 프로필은 sheet dismiss 대신 인라인 패널 닫기 동작을 사용해야 합니다." >&2
  exit 1
fi

grep -Fq 'private enum Panel' "$POPOVER"
grep -Fq 'case settings' "$POPOVER"
grep -Fq 'case profiles' "$POPOVER"
grep -Fq 'onClose: {' "$POPOVER"
grep -Fq 'let onClose: () -> Void' "$SETTINGS"
grep -Fq 'let onClose: () -> Void' "$PROFILES"
grep -Fq 'Button("취소")' "$POPOVER"
grep -Fq '일시정지하거나 취소한 뒤' "$SETTINGS"

if grep -Fq 'Button("재설정")' "$POPOVER" || grep -Fq '재설정' "$SETTINGS"; then
  echo "타이머 되돌리기 버튼 이름과 안내 문구는 '취소'여야 합니다." >&2
  exit 1
fi

printf 'Menu panel navigation test passed.\n'
