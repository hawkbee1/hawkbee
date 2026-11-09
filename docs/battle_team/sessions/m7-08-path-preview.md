# Session M7.8: Move: path preview and AP cost

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 8. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `packages/battle_client` (pre-check), `apps/battle_team` · **Branch:** `bt/m7-08-path-preview` · **Depends on:** M7.1 (M7.2 for fast testing).
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): COMBAT-03, COMBAT-06; `plan/specs/10-map-and-terrain.md` sections 3 and 4; decision 236; `plan/stack/08-workload-placement.md` (the pre-check is display only); the session logs of M3.6 (pathfinding), M6.7 (the pre-check was planned there) and M7.1.

## Notes
- The pre-check lives in `battle_client` on `battle_rules` and `battle_pathfinding`, behind a port fed the client's map data; the app draws the preview line and its AP cost against the unit's AP, with COMBAT-06's wait when AP run short.
- The host's answer wins: show a divergence, never argue it. Test preview cost against the host's boundary on scripted cases (grass, slope, road, water).
- The moving unit keeps gliding to its arrival time (decision 236).
- End with a recording in this log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 8).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
