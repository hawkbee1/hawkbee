# Session M3.5: World changes

**Issue:** `apps/battle_team/plan/milestones/m3-pathfinding.md`, Issue 5. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_pathfinding` (`hawkbee1/battle_pathfinding`) · **Branch:** `bt/m3-05-world-changes` · **Depends on:** M3.3.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): MAP-06, MAP-07, MAP-09, MAP-28, MAP-37 in `plan/specs/10-map-and-terrain.md`; `plan/stack/05-map-format.md` (craters, world-change budget); P-07 in `plan/milestones/performance-tests.md`.

## Notes
- A crater is a delta entry (centre, radius, depth) sampled on the cells it covers; the base heights never change (stack decision 5).
- Prove that an incremental update equals a recompute from scratch with seeded random sequences of changes.
- Measure the time of one update for P-07 (target: under 10 ms on the host) and record it in the session log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m3-pathfinding.md, Issue 5).
- [ ] The P-07 measurement is in the session log.
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
_Written by the session agent when it finishes._
