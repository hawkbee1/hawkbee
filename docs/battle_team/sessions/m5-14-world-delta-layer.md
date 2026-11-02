# Session M5.14: World delta layer

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 14. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m5-14-delta-layer` · **Depends on:** M5.11.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/10-map-and-terrain.md` §2; `plan/stack/05-map-format.md` (craters); P-07 in `plan/milestones/performance-tests.md`; the session logs of M3.5 and M3.6 ("Deferred, for M5").

## Notes
- Craters are entries (centre, radius, depth) applied with `NavigationMap.withCrater`; cap the depth at `craters.max_depth_m` (the package reads no data, M3.5 log).
- The deferred M3 items may need changes in `battle_pathfinding`: same branch name there, its own PR.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 14).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
