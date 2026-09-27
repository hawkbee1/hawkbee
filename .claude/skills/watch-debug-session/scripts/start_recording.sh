#!/usr/bin/env bash
# Records the foreground Flutter app's logs from an Android device to a file.
#
# Usage: start_recording.sh <log file>
# Device: $ANDROID_SERIAL, else the first device `adb devices` lists as ready.
# App: $APP_PACKAGE, else the foreground app (only reported: recording is by tag).
# Filters by tag rather than PID, so a hot restart or relaunch keeps recording.
set -euo pipefail

log="${1:?usage: start_recording.sh <log file>}"

serial="${ANDROID_SERIAL:-$(adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')}"
if [[ -z "$serial" ]]; then
  echo "no Android device is connected and authorised (adb devices)" >&2
  exit 1
fi

activity="$(adb -s "$serial" shell dumpsys activity activities 2>/dev/null |
  grep -m1 -E 'topResumedActivity|mResumedActivity' || true)"
package="${APP_PACKAGE:-$(sed -E 's#.* ([a-zA-Z0-9_.]+)/.*#\1#' <<<"$activity")}"
pid="$(adb -s "$serial" shell pidof "$package" 2>/dev/null || true)"

echo "device:  $serial"
echo "package: ${package:-unknown}"
echo "pid:     ${pid:-not running}"
if ! grep -q FlutterFragmentActivity <<<"$activity" && [[ -z "${APP_PACKAGE:-}" ]]; then
  echo "warning: the foreground app is not a Flutter activity; check the package, or set APP_PACKAGE" >&2
fi
echo "log:     $log"

: >"$log"
exec adb -s "$serial" logcat -v time -T 1 flutter:V AndroidRuntime:E DartVM:V '*:S' >>"$log" 2>&1
