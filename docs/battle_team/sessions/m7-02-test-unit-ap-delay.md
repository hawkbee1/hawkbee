# Session M7.2: The test unit and the AP recovery delay

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 2. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `packages/battle_rules`, `packages/battle_host`, `apps/battle_team` (`plan/data`) · **Branch:** `bt/m7-02-test-unit` · **Depends on:** nothing (runs beside M7.1).
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): decisions 238, 239; COMBAT-01/02, UNIT-44, Q-UNIT-26; `plan/data/battle.yaml`, `plan/data/units.yaml`; `plan/stack/01-simulation-host.md` (lazy AP); the session logs of M5.4 (data loading) and M5.19 (playtest tool).

## Notes
- `ap.recovery_delay_s` already sits in `plan/data/battle.yaml`: `battle_rules` and `battle_host` must read it (and the battles row's settings override) before a host runs on the merged plan.
- The test unit goes into `plan/data/units.yaml` per Q-UNIT-26's assumptions; a `test_units` battle setting guards buying it. Check fixture copies of the data in battle_rules/battle_host tests.
- `battle_host tool/playtest.dart`: testing battles get `test_units` on, a short delay, a test unit in blue's opening.
- Rule IDs in test names (COMBAT-02, UNIT-44).

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 2).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
