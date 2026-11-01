# Session M3.2: Navigation model

**Issue:** `apps/battle_team/plan/milestones/m3-pathfinding.md`, Issue 2. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_pathfinding` (`hawkbee1/battle_pathfinding`) · **Branch:** `bt/m3-02-nav-model` · **Depends on:** M3.1.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/10-map-and-terrain.md` (MAP-02, MAP-16, MAP-22, MAP-23, MAP-36, MAP-37); `plan/stack/05-map-format.md` (cells, tiles, objects, craters).

## Notes
- The real map format and its loader come in M5 (`battle_map`). Here: the model and a small fixture format for tests.
- Cells are 10 m (stack decision 5). Keep the cell size a parameter of the model: M3.6 benchmarks it.
- Terrain types are names given to the model; the package does not read `plan/data`.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m3-pathfinding.md, Issue 2).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
_Written by the session agent when it finishes._
