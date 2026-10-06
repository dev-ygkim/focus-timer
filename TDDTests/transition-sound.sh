#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ALERT_SERVICE="$ROOT_DIR/Sources/FocusTimerUI/AlertService.swift"
TIMER_STORE="$ROOT_DIR/Sources/FocusTimerUI/PomodoroStore.swift"
SETTINGS_VIEW="$ROOT_DIR/Sources/FocusTimerUI/SettingsView.swift"
MODELS="$ROOT_DIR/Sources/FocusTimerCore/Models.swift"
BUILD_SCRIPT="$ROOT_DIR/build.sh"
SOUND_FILE="$ROOT_DIR/Resources/transition.wav"

for system_sound in Basso Blow Bottle Frog Funk Glass Hero Morse Ping Pop Purr Sosumi Submarine Tink; do
  test -f "/System/Library/Sounds/$system_sound.aiff"
done

test -f "$SOUND_FILE"
grep -Fq 'enum AlertSoundChoice' "$MODELS"
grep -Fq 'case appDefault' "$MODELS"
grep -Fq 'case glass = "Glass"' "$MODELS"
grep -Fq 'soundChoice: AlertSoundChoice = .appDefault' "$MODELS"
grep -Fq 'systemSoundFileName' "$MODELS"
grep -Fq 'func playSound(_ soundChoice: AlertSoundChoice, repeatCount: Int)' "$ALERT_SERVICE"
grep -Fq 'playSound(settings.soundChoice, repeatCount: settings.soundRepeatCount)' "$ALERT_SERVICE"
# 소리가 끝나면(finished) 남은 횟수만큼 다시 재생하고, 새 소리가 시작되면 남은 반복을 취소합니다.
grep -Fq 'didFinishPlaying' "$ALERT_SERVICE"
grep -Fq 'cancelPreviousPerformRequests' "$ALERT_SERVICE"
grep -Fq '/System/Library/Sounds' "$ALERT_SERVICE"
grep -Fq 'func previewSound(_ soundChoice: AlertSoundChoice, repeatCount: Int)' "$TIMER_STORE"
grep -Fq 'playSound(soundChoice, repeatCount: repeatCount)' "$TIMER_STORE"
grep -Fq 'Picker("알림 사운드"' "$SETTINGS_VIEW"
grep -Fq 'AlertSoundChoice.allCases' "$SETTINGS_VIEW"
grep -Fq 'previewSound(soundChoice, repeatCount: soundRepeatCount)' "$SETTINGS_VIEW"
grep -Fq 'Picker("소리 반복"' "$SETTINGS_VIEW"
grep -Fq 'soundRepeatCount: soundRepeatCount' "$SETTINGS_VIEW"
grep -Fq 'soundChoice: soundChoice' "$SETTINGS_VIEW"
grep -Fq '소리 미리 듣기' "$SETTINGS_VIEW"
grep -Fq 'Resources/transition.wav' "$BUILD_SCRIPT"

printf 'Notification sound selection test passed.\n'
