#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ALERT_SERVICE="$ROOT_DIR/Sources/FocusTimerUI/AlertService.swift"
TIMER_STORE="$ROOT_DIR/Sources/FocusTimerUI/PomodoroStore.swift"
SETTINGS_VIEW="$ROOT_DIR/Sources/FocusTimerUI/SettingsView.swift"
BUILD_SCRIPT="$ROOT_DIR/build.sh"
SOUND_FILE="$ROOT_DIR/Resources/transition.wav"

test -f "$SOUND_FILE"
grep -Fq 'playTransitionSound()' "$ALERT_SERVICE"
grep -Fq 'url(forResource: "transition", withExtension: "wav")' "$ALERT_SERVICE"
grep -Fq 'func previewSound()' "$TIMER_STORE"
grep -Fq '소리 미리 듣기' "$SETTINGS_VIEW"
grep -Fq 'Resources/transition.wav' "$BUILD_SCRIPT"

printf 'Transition sound resource test passed.\n'
