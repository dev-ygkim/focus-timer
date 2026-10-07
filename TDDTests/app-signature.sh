#!/usr/bin/env bash
set -euo pipefail

# 링커 서명만 있는 번들은 macOS가 번들 ID로 식별하지 못해 알림 권한을 거부합니다(UNErrorDomain Code=1).
# build.sh가 번들 전체를 서명해 Info.plist와 번들 ID가 서명에 묶였는지 확인합니다.
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
APP="$ROOT_DIR/dist/FocusTimer.app"

if [[ ! -d "$APP" ]]; then
  echo "먼저 ./build.sh를 실행해야 합니다." >&2
  exit 1
fi

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Contents/Info.plist")"
SIGNATURE="$(codesign -dv "$APP" 2>&1)"

codesign --verify --strict "$APP"
grep -Fxq "Identifier=$BUNDLE_ID" <<< "$SIGNATURE"
if grep -Fq 'Info.plist=not bound' <<< "$SIGNATURE"; then
  echo "Info.plist가 서명에 묶여 있지 않습니다." >&2
  exit 1
fi

printf 'App signature test passed.\n'
