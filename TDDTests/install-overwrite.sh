#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TEMP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/focus-timer-install-overwrite.XXXXXX")"
TARGET_APP="$TEMP_HOME/Applications/FocusTimer.app"

cleanup() {
  rm -rf "$TEMP_HOME"
}
trap cleanup EXIT

if [[ ! -d "$ROOT_DIR/dist/FocusTimer.app" ]]; then
  echo "먼저 ./build.sh를 실행해야 합니다." >&2
  exit 1
fi

mkdir -p "$TARGET_APP/Contents"
printf 'old app marker\n' > "$TARGET_APP/old-marker"

HOME="$TEMP_HOME" "$ROOT_DIR/install.sh" >/dev/null

test -x "$TARGET_APP/Contents/MacOS/FocusTimer"
test ! -e "$TARGET_APP/old-marker"
if compgen -G "$TEMP_HOME/Applications/.FocusTimer.backup.*.app" > /dev/null; then
  echo "교체 후 임시 백업 번들이 남아 있습니다." >&2
  exit 1
fi

printf 'Install overwrite test passed.\n'
