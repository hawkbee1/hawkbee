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
- [x] The acceptance criteria of the issue (m3-pathfinding.md, Issue 3).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02), stacked on M3.2 (not merged yet), in `packages/battle_pathfinding/lib/src/path_search.dart`:
- `MovementCostFunction`: `(apPerM, mode, terrainType, slopeDegrees) → AP per metre or null`, the shape of the rules core's `MovementCost.call` (M4.4).
- `PathMover(apPerM, modes)`: `['foot']`, `['sail']` (boat), `['wheeled', 'sail']` (amphibious), `['flying']`.
- `PathRules`: ground modes, ladder modes, the flying mode, bridge constructions and the bridge deck terrain, the road construction and terrain, blocking objects, the altitude limit (passed in: the map's highest point + `flying_max_above_highest_terrain_m`).
- `Pathfinder(map:, cost:, rules:)`: `find(mover:, from:, to:)` → `FoundPath(cells, samples, cost)` or null (stranded), Dijkstra over neighbours, links and (for flyers) changes of surface; `check(mover:, path:)` → `PathPasses(cost, samples)` or `PathFails(step, StepFailure)` (stack decision 8).
- `PathSample(terrainType, slopeDegrees, lengthM, mode)`: the first three are the rules core's samples.

Checks: analyze `--fatal-infos` clean, format clean, 69 tests pass, coverage 100 % (298/298 lines). Tests use a fixture cost shaped like the rules core's (`test/helpers/fixture_cost.dart`).

Assumptions (no rule says; owner asleep, told me to guess): recorded in battle_team on `bt/m3-03-unit-paths` as Q-MAP-11 to Q-MAP-15, each with "Assumed: …", and all are `PathRules` parameters:
- a step between neighbours is priced half on each cell's terrain, with the step's slope; each half takes the mover's cheapest passable mode, so an amphibious unit drives onto the shore and sails off it;
- a bridge deck costs as `road`;
- ladders are for foot units; climbing costs the height difference priced as flat ground of the arrival cell;
- intact buildings and walls stop ground units (a ground class cannot enter their cell); trees do not; flyers ignore objects;
- a flyer changes surface (up to an island, down from it) for free under the altitude limit.

Other choices: neighbours are 8-connected; a bridge or ladder link is crossed with one mode; a bridge link is priced over the straight run between its two cells, with the slope from their heights (so a short bridge up to a high island is too steep).
