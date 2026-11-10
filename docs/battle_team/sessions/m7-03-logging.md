# Session M7.3: Logging

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 3. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `apps/battle_team`, `packages/battle_client`, `packages/appwrite_api_client` (in hawkbee itself, not a submodule) · **Branch:** `bt/m7-03-logging` · **Depends on:** M7.1.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:license-compliance`.
**Read** (`plan/` is `apps/battle_team/plan/`): decision 237; `.claude/skills/watch-debug-session/SKILL.md` (hawkbee root; the format must serve its parser — read how it reads logcat); hawkbee1/hawkbee#69's description (the TEMP prints that were reverted show what the phone debugging needed: attempts, credential kind, host address, socket end reasons, cookie trouble); the session logs of M6.7 (`BattleClient` lifecycle) and M7.1.

## Steps
1. **Dependency**: `package:logging` (BSD-3; check with `packages_check_licenses`) in the three packages. No other logging library.
2. **One setup** in the app, `lib/logging/` (`configureLogging({required bool release})`): root level, one formatter (`[bt] <level> <logger> <message>`, one line, errors with their stack on following lines prefixed too), print to the console in debug/profile, nothing in release. Call it from `bootstrap.dart`.
3. **`battle_client`**: a `Logger('battle_client.BattleClient')` and one per adapter; log `connecting (attempt n)`, `credential <kind>`, `host address <uri>`, `socket open`, `sign-in accepted`/`refused <code>`, `socket closed: <reason>`, `command <requestId> refused <code>`, `host lost, retry in <s>`. Levels: lifecycle `INFO`, refusals `WARNING`, exceptions `SEVERE`. The library never configures the root logger (it is a library): it only logs.
4. **`appwrite_api_client`**: `signIn` and `createJwt` log start and failure (never the password, never the JWT or cookie values).
5. **The app**: `AppBlocObserver` logs bloc errors; the battle cubit logs each order sent and its answer (request ID, order type, refusal code). Nothing of unit positions or hidden state.
6. **Decision 237 test**: feed the client a recorded stream holding an unseen hit and a unit out of sight; capture the log records (`Logger.root.onRecord`); assert no record names the hidden unit or the shooter.
7. **Verify on a real run** if you can (web build, or the owner on the phone with `adb logcat | grep '\[bt\]'`): sign-in, host lookup, socket, one order, and a forced failure (host down) must be readable. Paste the lines in the log.
8. **Gates** for the three packages (§4, §6), then **finish** (§5): `battle_client` PR, then hawkbee (carries `appwrite_api_client` and the `battle_team` pointer), then `battle_team`.

## Tests to write
- Formatter: level, logger name and message on one line; an error's stack on prefixed lines.
- `battle_client`: each lifecycle step emits its record (use the fake transport of its tests and `Logger.root.onRecord`); a refused command logs `WARNING` with the code.
- `decision 237 logs name nothing the section does not see`.
- Release mode emits nothing (configure with `release: true`).

## Stop and ask when
- The `watch-debug-session` skill expects a format incompatible with one line per event: ask which to change, the skill or the format.

## Pitfalls
- `logging` in a library: never set `hierarchicalLoggingEnabled` or levels there; the app decides.
- `coverage`: `onRecord` listeners in tests must be cancelled in `tearDown`, or records leak between tests.
- Do not reintroduce `print`: `avoid_print` is enforced.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 3).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log

**Built** (branch `bt/m7-03-logging`, stacked on `bt/m7-01-normal-launch`; neither M7.1 nor M7.2 was merged when this ran, M7.2 is independent and not under it):
- `package:logging` ^1.3.0 (BSD-3-Clause; `packages_check_licenses` on the workspace: 30 packages, BSD-3-Clause and MIT only) in `battle_client`, `appwrite_api_client` and `battle_team`. It was already in the lock file as a transitive package.
- `apps/battle_team/lib/logging/`: `formatLogRecord` (`[bt] <LEVEL> <logger> <message>`; an error then its stack on following lines with the same prefix; a blank stack line is dropped), `configureLogging({required bool release, printLine})` (root level `ALL` and `debugPrint` in debug and profile; level `OFF` and no listener in release; returns the listener so tests cancel it), `AppBlocObserver` (moved here from `bootstrap.dart` so it is tested; logs `onError` as `SEVERE`), `logFlutterError` (the `FlutterError.onError` handler). `bootstrap.dart` calls `configureLogging(release: kReleaseMode)` and stays one-liners.
- `battle_client`: `Logger('battle_client.BattleClient')` and one per adapter (`AppwriteHostFinder`, `WebSocketTransport`, both `fine`). Records: `connecting (attempt n)`, `credential <kind>`, `host address <uri>`, `socket open`, `sign-in accepted`, `WARNING sign-in refused <reason>`, `command <id> sent: <OrderType>` / `held until sign-in` / `resent`, `command <id> accepted`, `WARNING command <id> refused <code>`, `socket closed: <reason>` (`closed by the host`, `socket failed`, `unreadable frame`, `goodbye <reason>`, `sign-in refused <reason>`, `client closed`), `host lost, retry in <s> s`, `stopped`, `WARNING host lookup refused: HostLookupException(<status> <code>)`, `SEVERE connecting failed` and `SEVERE socket failed` with error and stack. The library sets no level.
- `appwrite_api_client`: `sign-in: started/done/failed`, `sign-in: the session is already open`, `create JWT: started/done/failed`; failures `SEVERE` with error and stack. Never the email, password, JWT or cookie.
- `BattleCubit`: `signing in`, `signed in`, `SEVERE sign-in failed`, `connection <status>`, `order <name> sent/accepted`, `WARNING order <name> refused <code>`, `SEVERE order <name> failed`. No state, no unit, no position.

**Tests**: `battle_client` 92 (`battle_client_logging_test.dart`: lifecycle in order, refusal levels, held/resent commands, secrets, decision 237), `appwrite_api_client` 16, `battle_team` 101; 100 % in the three, `dart analyze --fatal-infos` and `dart format` clean. Decision 237 is tested twice: in `battle_client` (the recorded `clear_s-2`/`fog_s-2` streams plus an unseen hit, no record names a unit the fog hides) and in the app over the real repository, client and cubit (`test/logging/battle_logs_test.dart`: also no position, JWT or password). **No recorded stream holds an unseen hit** (all eight have `unseenHits` empty), so both tests append one hand-written `TickUpdate` to the recording; if M6's samples get a recording with one, switch to it.

**Choices and deviations**
- **Request ID.** The cubit does not know the request ID (the repository returns only the refusal). `battle_client` logs it with the order type (`command 17 sent: Move`, `command 17 refused no_ap`), the cubit logs the order name and the code: the two correlate by order. Changing `BattleRepository.send` to return the answer would touch every M7.1 test for one number.
- **`AppBlocObserver` logs errors only.** Its `onChange` used to `log` every state: a state holds units and positions, and decision 237 says logs hold none.
- **`watch-debug-session` skill**: one line per event suits it, so I did not stop. I added `[bt] (SEVERE|WARNING)` to its alert grep and a note on the format (its section 3 said bloc errors do not reach logcat; for Battle Team they now do).
- **Exceptions are `SEVERE`, a host that is down included** (`connecting failed` with its error and stack, as the brief says), so a host down is five lines with the stack, then `host lost, retry in …`.
- **Coverage quirk, not understood.** With `test/logging/configure_logging_test.dart` added, the full suite reported 99.85 %: line 9 of `backend_status_indicator.dart`, the `const new` of `BackendStatusIndicator`, had no hit, though that file's own test passes alone and reaches it. Without that one file the line was hit; with `concurrency: 1` it was not. I made `backend_status_indicator_test.dart` build the widget at run time (`BackendStatusIndicator()` with an `ignore` comment) so the constructor always runs. If a later session sees an unrelated constructor line lose its hit, this is the same thing.
- `check_ignore: true` fails on the Flutter packages (`appwrite_api_client`, `battle_team`): it is for `dart: true` only.

**Docs touched**: `agent-workflow.md` §6 (Logging), `playtest.md` (Logs), the README row, the `watch-debug-session` skill.

**Real run: not done.** The local Appwrite does not answer from the container (as in M7.1), so there was no live host and no phone. What follows is the **real `BattleClient` and the real formatter over an in-memory host** (a throwaway script, not committed): sign-in, an order the host refuses, then the host going down (the socket breaks, two connections are refused, the third opens). It is the format, not a live run.

```
[bt] INFO battle_client.BattleClient connecting (attempt 1)
[bt] INFO battle_client.BattleClient credential jwt
[bt] INFO battle_client.BattleClient host address wss://host.example/v1/socket
[bt] INFO battle_client.BattleClient socket open
[bt] INFO battle_client.BattleClient sign-in accepted
[bt] INFO battle_client.BattleClient command 1837187481600540 sent: Reload
[bt] WARNING battle_client.BattleClient command 1837187481600540 refused no_ap
[bt] SEVERE battle_client.BattleClient socket failed
[bt] SEVERE battle_client.BattleClient error: Bad state: connection reset
[bt] INFO battle_client.BattleClient socket closed: socket failed
[bt] INFO battle_client.BattleClient host lost, retry in 0.379 s
[bt] INFO battle_client.BattleClient connecting (attempt 2)
[bt] INFO battle_client.BattleClient credential jwt
[bt] INFO battle_client.BattleClient host address wss://host.example/v1/socket
[bt] SEVERE battle_client.BattleClient connecting failed
[bt] SEVERE battle_client.BattleClient error: Bad state: connection refused
[bt] SEVERE battle_client.BattleClient #0      FakeTransport.connect (…)
[bt] INFO battle_client.BattleClient host lost, retry in 0.897 s
[bt] INFO battle_client.BattleClient connecting (attempt 3)
```
(The stack lines after the second error are cut here; the first one printed an empty stack line, which the formatter now drops.)

**To do on the owner's side:** run the development flavor on the phone with `adb logcat | grep '\[bt\]'` (`playtest.md`, "Logs"): sign-in, host lookup, socket, one move, then stop the host and read the retries. Paste the lines here.
