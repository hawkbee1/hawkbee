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
- [x] The acceptance criteria of the issue (m3-pathfinding.md, Issue 2).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02), in `packages/battle_pathfinding/lib/src/` (the package branches from its merged `main`; the hawkbee branch is stacked on M4.11 only to keep the README table free of conflicts):
- `navigation_map.dart`: `NavigationMap(cellSizeM, width, depth, ground, waterTerrains, islands, objects, constructions, links)`; `CellRef(x, y, surface:)` (ground or an island's name); `NavCell(height, terrain)`; `SurfaceLink(kind, from, to)` with `LinkKind` bridge, reinforced bridge, ladder. Methods: `cellAt`, `isWater`, `objectsAt`, `constructionsAt`, `stepLengthM` (side or diagonal), `slopeDegrees` (signed, `atan2(rise, step)`), `neighbours` (8, same surface), `linksFrom` (both ways).
- `navigation_fixture.dart`: `NavigationFixture.parse(text)`, a line-based test format (`cell`, `water`, `legend`, `terrain` and `heights` blocks, `island`, `build`, `link`), with `FormatException`s naming the line.
- `test/fixtures/valley.map`: a river with a bridge, a lake, a forest, a town, a wall, a mountain, a road and a floating island reached by a ladder and a bridge.
- Adds `meta` (`@immutable` on `CellRef`).

Checks: analyze `--fatal-infos` clean, format clean, 14 tests pass, coverage 100 % (150/150 lines).

Choices:
- Neighbours are 8-connected; a diagonal step is a cell diagonal long and its slope uses that length.
- Water is a property of terrain names the map declares (`water river lake`): the package reads no data.
- Constructions on cells (a bridge over a river, a road) are plain names here; M3.3 gives them their meaning (a bridge makes a water cell passable to ground classes). Links join cells that are not plain neighbours (ground to island).
