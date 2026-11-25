#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
STORE="$ROOT_DIR/Sources/FocusTimerUI/PomodoroStore.swift"
CONTROLLER="$ROOT_DIR/Sources/FocusTimerUI/MenuBarController.swift"
TIMER="$ROOT_DIR/Sources/FocusTimerUI/TimerPopoverView.swift"
SETTINGS="$ROOT_DIR/Sources/FocusTimerUI/SettingsView.swift"

# 자연 종료 전환에서만 깜빡입니다: 소리·배너를 보내는 바로 그 자리에서만, 설정이 켜져 있을 때만 요청합니다.
test "$(grep -c 'flashRequests.send' "$STORE")" -eq 1
grep -A3 'alertService.send(alert, settings: alertSettings)' "$STORE" | grep -Fq 'if alertSettings.flashEnabled'
grep -A4 'alertService.send(alert, settings: alertSettings)' "$STORE" | grep -Fq 'flashRequests.send(alert)'

# 창이 닫혀 있어도 띄우되, 다른 앱에서 입력 중인 포커스는 빼앗지 않습니다(키 윈도우로 만들지 않음).
grep -Fq 'timerStore.flashRequests' "$CONTROLLER"
grep -A12 'private func flash(' "$CONTROLLER" | grep -Fq 'showPanel(makeKey: false)'
grep -A20 'private func showPanel(' "$CONTROLLER" | grep -Fq 'panel.orderFrontRegardless()'
# 항상 켜두기로 투명도를 낮췄어도 깜빡이는 동안은 100%로 보이고, 끝나면 되돌립니다.
grep -A12 'private func flash(' "$CONTROLLER" | grep -Fq 'panel.alphaValue = 1'
grep -A12 'private func flash(' "$CONTROLLER" | grep -Fq 'TimerPopoverView.flashDuration'
# 창이 닫히면 단계 색 테두리도 사라집니다.
grep -A4 'private func hidePanel()' "$CONTROLLER" | grep -Fq 'flashAlert = nil'

# 단계 색으로 3회 깜빡임, 동작 줄이기 중에는 한 번만. 깜빡이는 동안 클릭은 아래 버튼(중지·종료)에 닿지 않고 깜빡임만 멈춥니다.
grep -Fq 'accessibilityDisplayShouldReduceMotion' "$TIMER"
grep -Fq '.task(id: flashCount)' "$TIMER"
# 창을 닫았다 다시 열 때 지난 깜빡임이 되풀이되지 않도록, 닫힐 때 비워지는 알림이 있을 때만 깜빡입니다.
grep -Fq 'guard flashCount > 0, flashAlert != nil' "$TIMER"
grep -Fq '.allowsHitTesting(flashOpacity > 0)' "$TIMER"
grep -Fq 'flashAlert?.flashTitle' "$TIMER"

# 설정의 알림 묶음에서 켜고 끕니다.
grep -Fq 'toggleRow(title: "화면 깜빡임 알림"' "$SETTINGS"
grep -Fq 'flashEnabled: flashEnabled' "$SETTINGS"

printf 'Flash alert test passed.\n'
