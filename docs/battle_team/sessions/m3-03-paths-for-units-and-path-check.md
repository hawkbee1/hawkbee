# Session M3.3: Paths for units, path check

**Issue:** `apps/battle_team/plan/milestones/m3-pathfinding.md`, Issue 3. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_pathfinding` (`hawkbee1/battle_pathfinding`) · **Branch:** `bt/m3-03-unit-paths` · **Depends on:** M3.2.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/10-map-and-terrain.md` (movement, water, islands); COMBAT-03, UNIT-01, UNIT-02; decisions 68, 86, 133, 142 and 169; `plan/stack/08-workload-placement.md` (paths: the client computes, the host checks).

## Notes
- The cost is injected, with the signature of M4.4: `(AP per metre, class or profile, terrain type, signed slope) → AP per metre, or impassable`. Tests use fixture costs.
- The path check (stack decision 8) uses the same cost and walks the given path cell by cell; it returns the cost or the first invalid step.
- The flying altitude limit is a number passed in (the map's highest point + `flying_max_above_highest_terrain_m`).

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m3-pathfinding.md, Issue 3).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
_Written by the session agent when it finishes._
