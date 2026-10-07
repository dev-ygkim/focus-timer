#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CONTROLLER="$ROOT_DIR/Sources/FocusTimerUI/MenuBarController.swift"
TIMER="$ROOT_DIR/Sources/FocusTimerUI/TimerPopoverView.swift"
APP="$ROOT_DIR/Sources/FocusTimerApp/FocusTimerApp.swift"

# MenuBarExtra는 바깥 클릭 시 창을 강제로 닫으므로, 열려 있던 창을 그대로 고정하려면 직접 관리해야 합니다.
if grep -Fq 'MenuBarExtra' "$APP"; then
  echo "항상 켜두기는 MenuBarExtra 창을 유지할 수 없으므로 MenuBarController를 사용해야 합니다." >&2
  exit 1
fi
grep -Fq 'MenuBarController(' "$APP"

# 같은 창을 고정: 별도 창을 만들지 않고, 고정 중에는 바깥 클릭으로 닫지 않으며 플로팅 레벨로 올립니다.
test -f "$CONTROLLER"
grep -Fq 'NSStatusBar.system.statusItem' "$CONTROLLER"
grep -Fq 'addGlobalMonitorForEvents' "$CONTROLLER"
grep -Fq '!self.isPinned' "$CONTROLLER"
grep -Fq 'isPinned ? .floating : .popUpMenu' "$CONTROLLER"
test "$(grep -c 'TimerPopoverView(' "$CONTROLLER")" -eq 1

# 하단 체크박스와 종료 버튼: 간격을 벌리고 종료는 버튼 스타일로 표시합니다.
grep -Fq 'Toggle("항상 켜두기", isOn: $isPinned)' "$TIMER"
grep -Fq '.toggleStyle(.checkbox)' "$TIMER"
grep -A4 'Button("종료")' "$TIMER" | grep -Fq '.buttonStyle(FocusCompactButtonStyle(tint: FocusTheme.danger))'
grep -A6 'Button("종료")' "$TIMER" | grep -Fq '.padding(.leading, 20)'

# 고정 중에만 창 전체 투명도를 적용하고, 조절 바는 상단 가운데에 고정 중일 때만 보입니다.
grep -Fq 'panel.alphaValue = isPinned ? pinnedOpacity : 1' "$CONTROLLER"
grep -Fq 'UserDefaults.standard.set(pinnedOpacity, forKey: Self.pinnedOpacityKey)' "$CONTROLLER"
grep -Fq 'pinnedOpacity: $controller.pinnedOpacity' "$CONTROLLER"
grep -A3 'if isPinned {' "$TIMER" | grep -Fq 'Slider(value: $pinnedOpacity, in: 0.3...1)'

printf 'Always on top test passed.\n'
