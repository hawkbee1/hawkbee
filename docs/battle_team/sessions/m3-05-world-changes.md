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
- [x] The acceptance criteria of the issue (m3-pathfinding.md, Issue 5).
- [x] The P-07 measurement is in the session log.
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02), stacked on M3.4 (not merged yet), in `packages/battle_pathfinding/lib/src/`:
- `world_change.dart`: `WorldChange` (sealed): `ObjectBuilt`, `ObjectDestroyed`, `ConstructionBuilt`, `ConstructionDestroyed`, `LinkBuilt`, `LinkDestroyed`, `CraterDug`. No change fills a crater or regrows an object (MAP-09). `applyChange(map, change)` → the new map and the cells it touches.
- `navigation_map.dart`: `Crater(centreXM, centreYM, radiusM, depthM)` with `depthAt` and `cells`; `NavigationMap.craters`. Base heights never change: `cellAt` returns the ground height minus the crater depth (stack decision 5).
- `path_search.dart`: `StepCache` (priced steps indexed by both end cells; `forget(cells)`), an optional `cache` on `Pathfinder`, and `LivePathfinder(map:, cost:, rules:)` with `find`, `check` and `apply(change)`, which forgets only the steps that touch the changed cells.
- `bin/world_change_bench.dart`: the P-07 benchmark.

Checks: analyze `--fatal-infos` clean, format clean, 96 tests pass, coverage 100 % (441/441 lines). Equivalence: 12 seeds × 15 random changes (walls, bridges, craters) × 3 pairs × 3 movers: incremental paths cost what a search from scratch on the changed map finds.

P-07 (one world change on a live 256 × 256-cell map, one tile, with 521,080 cached steps from four map-crossing paths; 200 changes: craters of 8 m, walls, roads), on the dev container:
- JIT (`dart run`): mean 55 µs, median 38 µs, p95 76 µs, max 1.5 ms.
- AOT (`dart compile exe`): mean 19 µs, median 20 µs, p95 31 µs, max 35 µs.
Target: under 10 ms on the host. Met with a wide margin. The re-pricing of forgotten steps happens on the next search, not in the update.

Assumption (owner asleep): Q-MAP-17 in battle_team on `bt/m3-05-world-changes`: a crater is a bowl `depth × (1 − (d/r)²)` sampled at cell centres; where craters overlap the deepest counts; craters dig the ground only, not islands. The 20 m depth cap (MAP-09, `craters.max_depth_m`) is the caller's to apply: the package reads no data.
