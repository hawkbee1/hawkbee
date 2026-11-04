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

## Session log
Built (2026-11-04), stacked on M5.13 (hawkbee #49, not merged yet):
- **`battle_host`**:
  - `lib/src/core/battle_world.dart`: `WorldDelta`, the delta layer in `BattleState.delta`: the world changes in order, the HP of the objects hit, the objects built and those destroyed (MAP-06). It is part of the state, so of the snapshot, and can be sent whole (MAP-08). `BattleState.structures` is gone: built structures are `delta.built`.
  - `BattleWorld`, `Battle.world`: the shared map until the battle's first change, then a navigation model and a ground grid of its own (copy on write). Every path, search, sight line and shot trace reads it. `BattleWorld.load(shared, delta)` rebuilds a battle's world from its delta layer, for M5.15.
  - `lib/src/orders/world_changes.dart`: `WorldChanges` makes these changes:
    - a built structure joins the world as an object, a construction or a link;
    - an object hit keeps its HP (`terrain.yaml`) until it is destroyed, then leaves the world and never regrows (MAP-09, MAP-10, MAP-28, MAP-37);
    - a destroyed reinforced bridge loses the relic or HQ on it (M5.13's `bridgeDestroyed`);
    - a bombard shot's splash hits objects, and a weapon that deforms terrain digs a crater as wide as its splash (MAP-46, capped at `max_depth_m`);
    - a first-person shot that stops on an object damages it;
    - a crater gives partial cover (MAP-07).
  - `SharedMap.objectsByCell` indexes the map's objects by cell.
  - `bin/world_change_bench.dart`: P-07 on the host.
- **`battle_pathfinding`** (deferred from M3.6):
  - `NavigationMap` keeps the authored objects and constructions as a base with the battle's changes on top, so a change copies only the changed cells.
  - `GroundSearch.fast` answers an unreachable goal at once with the connected parts of the ground, which it labels on the first need and again after a world change.
  - `GroundGrid.copy`.
  - A test for the flying altitude limit of the ground search, uncovered since M3.6 with optimization off.
- **`battle_protocol`**: the events `ObjectDamaged`, `ObjectDestroyed` and `CraterDug`, added after the other events with their v1 samples.
- **`battle_rules`**: `craters.depth_per_shot_m` is read; a weapon that `deforms_terrain` needs a `splash_radius_m`.
- **`battle_team`**: Q-MAP-19 (assumed), `craters.depth_per_shot_m` in `terrain.yaml`, P-07's host figures.

Checks: analyze `--fatal-infos` and format clean; tests pass with 100 % coverage, optimization off:

| Package | Tests |
|---|---|
| `battle_host` | 166 |
| `battle_pathfinding` | 129 |
| `battle_rules` | 616 |
| `battle_protocol` | 600 |

P-07 on the host (AOT, 10 × 50 km synthetic map, three runs): the first change of a battle takes 7 to 8 ms, since it copies the 5 M-cell grid. The next ones take 18 to 20 µs on average, 31 to 34 µs at p95 and at most 353 µs. Target: under 10 ms.

Deviation: the issue asks that a destroyed tree change a path. In the rules a tree stops no mover (MAP-44) and changes no terrain, so its destruction changes sight lines, cover and shot tracing but no path. The test checks that the path stays the same.

Choices:
- Which weapons dig is in the data (`deforms_terrain`: artillery). The size is assumed (Q-MAP-19): a bowl as wide as the weapon's splash, `craters.depth_per_shot_m` deep, never deeper than `max_depth_m`. A crater is dug only on the map's ground.
- An object takes a bombard shot's splash from its nearest cell, and a first-person shot that stops on it (assumed, Q-MAP-19). The ground takes nothing.
- An object is followed by its id, the loader's `<type>@(x, y)`, which built structures share with their site.
- A battle copies the shared grid on its first change; until then its searches are the map's.
