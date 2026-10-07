#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DIST_DIR/FocusTimer.app"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/focus-timer-dmg.XXXXXX")"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

rm -rf "$DIST_DIR"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"

swift build --package-path "$ROOT_DIR" --configuration release --product FocusTimer
BIN_DIR="$(swift build --package-path "$ROOT_DIR" --configuration release --show-bin-path)"
BINARY_PATH="$BIN_DIR/FocusTimer"

if [[ ! -x "$BINARY_PATH" ]]; then
  echo "빌드 실행 파일을 찾을 수 없습니다: $BINARY_PATH" >&2
  exit 1
fi

ditto "$BINARY_PATH" "$APP_PATH/Contents/MacOS/FocusTimer"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
ditto "$ROOT_DIR/Resources/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
ditto "$ROOT_DIR/Resources/transition.wav" "$APP_PATH/Contents/Resources/transition.wav"
plutil -lint "$APP_PATH/Contents/Info.plist" >/dev/null

# 번들 전체를 ad-hoc 서명해 Info.plist와 번들 ID를 서명에 묶습니다.
# 링커 서명만 있으면 macOS가 앱을 번들 ID로 식별하지 못해 알림 권한을 거부합니다(UNErrorDomain Code=1).
codesign --force --sign - "$APP_PATH"
codesign --verify --strict "$APP_PATH"

mkdir -p "$STAGING_DIR"
ditto "$APP_PATH" "$STAGING_DIR/FocusTimer.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "Focus Timer" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DIST_DIR/FocusTimer.dmg" >/dev/null
hdiutil verify "$DIST_DIR/FocusTimer.dmg" >/dev/null

printf 'Created:\n  %s\n  %s\n' "$APP_PATH" "$DIST_DIR/FocusTimer.dmg"
