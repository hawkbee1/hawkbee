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
