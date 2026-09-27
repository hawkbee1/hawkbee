---
name: watch-debug-session
description: Watch a Flutter app running in debug on an Android device while the user drives it by hand (sign-up, login, any flow that talks to Appwrite), record its logs, get alerted on errors live, then reconstruct what happened and find the root cause of each failure. Use this whenever the user says they are launching / testing / running the app on a phone and asks you to watch, follow, monitor, observe, "keep an eye on" or check what happens, or says "I'll tell you when I'm done" — even if they never mention logcat, adb or logs.
---

# Watching a live debug session

The user drives the app on a real device; you watch silently, then explain what
happened. The value you add is a precise timeline and a root cause for each
failure, with the evidence, and a clear statement of who has to fix it (app
code, app config, or the backend).

## 1. Attach without disturbing the user

Find the device and the app, then start recording. Never restart, reload or tap
anything yourself — the user is mid-flow, and a hot restart would throw them back
to the start of the app.

```bash
bash .claude/skills/watch-debug-session/scripts/start_recording.sh <scratchpad>/device.log
```

Run it with `run_in_background: true`. It picks the device (or `$ANDROID_SERIAL`),
prints the foreground package and PID — check it is the app under test (the
user may have switched apps; the flavour packages look like
`com.hawkbee.hawkbee.dev`), or pass `APP_PACKAGE` — and appends the app's `flutter`,
`AndroidRuntime` and `DartVM` logcat lines to the file. It filters by tag, not by
PID, so it survives a hot restart or a full relaunch.

**The file is the source of truth.** Everything below reads it. Keep it in the
scratchpad: it can contain session secrets, JWTs and user data, so quote
only the parts you need and never paste full tokens back to the user.

## 2. Live alerts (best effort)

Arm a `Monitor` on the file for errors and HTTP traffic, with the maximum
timeout, and re-arm on expiry while the user is still testing. Poll the file
rather than piping `tail -F` into filters:

```bash
LOG=<log>; n=$(wc -l < "$LOG"); while true; do m=$(wc -l < "$LOG"); if [ "$m" -gt "$n" ]; then sed -n "$((n+1)),${m}p" "$LOG" | grep -aE '⛔|ERROR\[|Exception|FATAL|failed|Unhandled|RESPONSE\[[0-9]+\] => PATH|REQUEST\[[A-Z]+\] => PATH' | sed 's/\x1b\[[0-9;]*m//g' | cut -c1-300; n=$m; fi; sleep 2; done
```

Each poll runs a short pipeline that exits, so its output is flushed every
time. A long-running `tail -F | grep | awk` pipeline delivered nothing in two
sessions here — once because `cut` buffered, once for no reason that could be
found even with every stage line-buffered. Treat alerts as a heads-up; when
the user says they are done, read the file anyway.

When an alert shows a failure mid-test, say so in one or two lines (what failed,
the error text) so the user can react, then keep watching.

## 3. Know what this app does *not* log

Silence in the log is not success. Check the app's code before trusting the log:

- `dart:developer`'s `log()` goes to the VM service (DevTools), **not** to
  logcat. In hawkbee, `AppBlocObserver` in `lib/bootstrap.dart` logs every
  Bloc change and error that way, so the recorder does not see them. They
  appear in DevTools' Logging view; the Dart MCP server's
  `get_runtime_errors` also reports runtime errors if it is connected.
- `print` and `debugPrint` do reach logcat under the `flutter` tag.
- The Appwrite SDK does not log its requests. An `AppwriteException` shows up
  only where the app logs or displays it (format:
  `AppwriteException: <type>, <message> (<code>)`).
- Errors shown on screen and not logged are invisible here. If a flow stops
  with no error line, ask the user what the screen said, or add a
  `debugPrint` in the relevant `catch` and have them retry.

If you add logging, say which reload it needs: anything built once at startup
(clients and repositories built in `bootstrap.dart` / `main_<flavor>.dart`,
Blocs provided in `app.dart`) needs a **hot restart**; a hot reload will not
pick it up. Ask the user to do it — do not trigger it yourself.

## 4. Reconstruct and diagnose

Strip ANSI colours and drop noise before reading:

```bash
sed 's/\x1b\[[0-9;]*m//g' <log> | grep -v "IMPORTANT:flutter" | cut -c1-500
```

Split the log into attempts, using app restarts and screen changes as
boundaries. For each attempt, find the first failure and explain it from the
evidence before proposing a fix.

**Logcat cuts every line at about 4 KB.** Long JWTs and headers get truncated.
`scripts/jwt_from_log.py` decodes what survives: the header, the payload if
present, and any `x5c` certificates (or their readable issuer and subject
strings when truncated):

```bash
python3 .claude/skills/watch-debug-session/scripts/jwt_from_log.py <log> <key>
```

Common Appwrite causes worth checking first: the endpoint in
`env/<flavor>.json` is not reachable from the device (`localhost` on a phone,
wrong LAN IP), the platform (package name / bundle ID) is not registered in the
Appwrite project, cleartext HTTP blocked outside the development flavor, or a
missing table/row permission (401/403).

Look past the main goal too. Anything off in the log — an unreachable host, a
malformed URL, a 4xx that the app retried around — is worth a line in the
report, marked as blocking or not.

## 5. Report

When the user says they are done:

- One short paragraph per attempt: what worked (name the steps), where it
  stopped, the exact error text with its timestamp.
- The root cause, with the evidence (the log line, the decoded certificate).
- Who has to fix it: app code, app config (`env/<flavor>.json`, platform
  setup), or the backend (Appwrite project settings, permissions, functions).
  Say plainly when the app is behaving correctly and the fix is elsewhere.
- Other issues found, marked as blocking or harmless.
- Any code you changed during the session (logging, temporary bypasses) and
  whether it needs reverting.

## 6. Stop cleanly

When the user pauses or ends the session, stop the recorder and every monitor.
Kill them **by PID** (`pgrep -a adb | grep logcat`, `pgrep -a tail | grep
<log>`, then `kill <pid>`). `pkill -f "<pattern>"` matches the shell running it
too, because its own command line contains the pattern, and kills your command.
