# Session M6.3: Fog of war per section

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 3. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m6-03-fog` · **Depends on:** M5 (M5.19 #57, M5.21 #58); not on M6.1.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/10-map-and-terrain.md` section 5 (vision); UNIT-34, UNIT-36, HQ-29, COMBAT-11, COMBAT-12; decisions 21, 59, 184; Q-MAP-24; `plan/stack/01-simulation-host.md` (tick, load); the session logs of M4.5 (vision), M5.1 (effective stats), M5.11 (scouts' reports for artillery, sight lines) and M5.19 (load test).
**Measure** with `battle_host/bin/load_test.dart`, AOT.

## Notes
- The visible sets are derived state: not in the log, not in the snapshot. A recovered host recomputes them.
- Keep the cost in check with a spatial index of the units (a grid by vision range), and re-check only pairs where an observer or a target moved, appeared, or changed its sight (observe, weather). Report peak and average per tick at 1,000 units in P-02.
- Factor the scouts' reports of COMBAT-12 (M5.11) and the radio relay into one computation; artillery keeps firing at what it fired at before.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m6-networking.md, Issue 3).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
