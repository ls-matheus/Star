#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Forward the Star development web server to an authorized Android phone via ADB.
set -euo pipefail

PORT="${STAR_ANDROID_PORT:-3000}"
case "$PORT" in
  3000|8088) ;;
  *) printf '%s\n' "Use STAR_ANDROID_PORT=3000 or STAR_ANDROID_PORT=8088" >&2; exit 2 ;;
esac

if command -v adb >/dev/null 2>&1; then
  ADB="$(command -v adb)"
elif [[ -x "$HOME/.local/bin/adb" ]]; then
  ADB="$HOME/.local/bin/adb"
else
  printf '%s\n' 'ADB not found. Install Android Platform Tools first.' >&2
  exit 1
fi

SERIAL="${STAR_ANDROID_SERIAL:-}"
if [[ -z "$SERIAL" ]]; then
  SERIAL="$("$ADB" devices | awk '$2 == "device" && $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:/ { print $1; exit }')"
fi
if [[ -z "$SERIAL" ]]; then
  printf '%s\n' 'No authorized wireless Android device found. Use adb connect first.' >&2
  exit 1
fi

"$ADB" -s "$SERIAL" reverse "tcp:$PORT" "tcp:$PORT" >/dev/null
printf 'ADB reverse active for %s: phone tcp:%s -> Mac tcp:%s\n' "$SERIAL" "$PORT" "$PORT"

URL="http://127.0.0.1:$PORT/"
if ! curl --noproxy '*' -fsS -o /dev/null --max-time 2 "$URL"; then
  printf 'Star is not serving %s yet. Start the development server before opening Chrome.\n' "$URL"
  exit 0
fi

"$ADB" -s "$SERIAL" shell am start -a android.intent.action.VIEW -d "$URL"
printf 'Opened Star in Android browser: %s\n' "$URL"
