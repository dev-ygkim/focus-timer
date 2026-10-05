#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/Sources/FocusTimerUI/AppVersion.swift"
POPOVER="$ROOT_DIR/Sources/FocusTimerUI/TimerPopoverView.swift"
PLIST="$ROOT_DIR/Resources/Info.plist"

test -f "$VERSION_FILE"
CODE_VERSION="$(sed -n 's/.*static let current = "\(.*\)".*/\1/p' "$VERSION_FILE")"
PLIST_VERSION="$(plutil -extract CFBundleShortVersionString raw "$PLIST")"

if [[ ! "$CODE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "앱 버전은 MAJOR.MINOR.PATCH 형식이어야 합니다: '$CODE_VERSION'" >&2
  exit 1
fi

if [[ "$CODE_VERSION" != "$PLIST_VERSION" ]]; then
  echo "AppVersion.swift($CODE_VERSION)와 Info.plist($PLIST_VERSION)의 버전이 다릅니다." >&2
  exit 1
fi

grep -Fq 'Text("Focus Timer v\(AppVersion.current)")' "$POPOVER"

printf 'App version test passed.\n'
