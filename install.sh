#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SOURCE_APP="$ROOT_DIR/dist/FocusTimer.app"
DESTINATION_DIR="$HOME/Applications"
DESTINATION_APP="$DESTINATION_DIR/FocusTimer.app"

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "빌드된 앱을 찾을 수 없습니다. 먼저 ./build.sh를 실행하세요: $SOURCE_APP" >&2
  exit 1
fi

mkdir -p "$DESTINATION_DIR"
STAGING_DIR="$(mktemp -d "$DESTINATION_DIR/.FocusTimer.install.XXXXXX")"
STAGED_APP="$STAGING_DIR/FocusTimer.app"
BACKUP_APP="$DESTINATION_DIR/.FocusTimer.backup.$$.app"
INSTALLED=false
HAD_EXISTING_APP=false

restore_backup() {
  if [[ -e "$BACKUP_APP" || -L "$BACKUP_APP" ]]; then
    rm -rf "$DESTINATION_APP"
    mv "$BACKUP_APP" "$DESTINATION_APP"
  fi
}

cleanup() {
  local exit_status=$?

  if [[ "$INSTALLED" != true ]]; then
    restore_backup || true
  fi

  rm -rf "$STAGING_DIR"

  if [[ "$INSTALLED" == true ]]; then
    rm -rf "$BACKUP_APP"
  fi

  exit "$exit_status"
}
trap cleanup EXIT

ditto "$SOURCE_APP" "$STAGED_APP"

if [[ -e "$DESTINATION_APP" || -L "$DESTINATION_APP" ]]; then
  HAD_EXISTING_APP=true
  mv "$DESTINATION_APP" "$BACKUP_APP"
fi

if ! mv "$STAGED_APP" "$DESTINATION_APP"; then
  echo "새 앱 교체에 실패했습니다. 기존 앱을 복원합니다." >&2
  restore_backup
  exit 1
fi

INSTALLED=true

if [[ "$HAD_EXISTING_APP" == true ]]; then
  printf 'Replaced: %s\n' "$DESTINATION_APP"
else
  printf 'Installed: %s\n' "$DESTINATION_APP"
fi
