# Session M7.3: Logging

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 3. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `apps/battle_team`, `packages/battle_client`, `packages/appwrite_api_client` · **Branch:** `bt/m7-03-logging` · **Depends on:** M7.1.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:license-compliance` (package:logging).
**Read** (`plan/` is `apps/battle_team/plan/`): decision 237; the `watch-debug-session` skill (hawkbee `.claude/`), whose parser the format must serve; hawkbee1/hawkbee#69 (the reverted TEMP prints show what the phone debugging needed).

## Notes
- `package:logging`: per-class loggers, one formatter (stable prefixes, one line per event, errors marked), quiet in release, pure Dart in `battle_client` (web included).
- `battle_client` logs the connection lifecycle the reverted traces covered: attempts, credential kind, host address, socket end reasons, refusals. The app logs bloc errors (`AppBlocObserver`) and order refusals.
- Decision 237 applies to logs: test that no log line names what the section does not see.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 3).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
