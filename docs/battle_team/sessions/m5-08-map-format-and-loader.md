# Session M5.8: Map format and loader

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 8. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_map` (`hawkbee1/battle_map`, new) · **Branch:** `bt/m5-08-map` · **Depends on:** M3 (merged).
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:license-compliance`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/05-map-format.md` (all of it); MAP-01 to MAP-05, MAP-10, MAP-36, MAP-40; RELIC-02; HQ-01; `plan/data/terrain.yaml`; the M3.2 session log (`NavigationMap`, the fixture format).

## Notes
- A map has fewer than 2 × `victory.relics_to_hold` relics, so no tie is possible (RELIC-17); `VictoryRules.start` (M5.5) refuses others. Check it when validating a map.
- New package: the procedure of dc3d §2 with the Very Good CLI MCP `create` (`subcommand: dart_package`, `name: battle_map`, `output_directory: packages`, `workspace: true`, a description without a colon). Create `hawkbee1/battle_map` with `gh repo create --public`, add it to the root `workspace:` and melos `format` lists, and apply the new-package pitfalls of dc3d §2 (and of the M4.1 and M3.1 session logs).
- Check the image package's API with context7 before use, and its licence with `packages_check_licenses`.
- The loader builds `battle_pathfinding`'s `NavigationMap`; do not copy its model.
- Keep the committed test map small (a few tiles of a few cells is fine: make the tile size a parameter whose default is 256). Big synthetic maps are generated in tests, never committed.
- The `bin/` builder reads and writes files; `lib/` takes bytes and text.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m5-simulation-host.md, Issue 8).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02) in the new package `packages/battle_map` (public repository `hawkbee1/battle_map`, merge commits only, submodule of hawkbee, in the root `workspace:` and melos `format` lists; template CI and dependabot deleted, `test: ^1.31.0`, `mocktail` dropped):
- `lib/src/map_format.dart`: `MapSpec` (`map.yaml`: name, `cell_size_m`, `tile_size` default 256, `terrain_index`, `teams` by team count, `relics`; `width` and `depth` once built) and `MapFeatures` (`objects.yaml`: `objects`, `constructions`, `links`, `islands`), with `MapFormatException` naming the file and key. Cells are `[x, y]` on the ground and `[x, y, island]` on a floating island.
- `lib/src/map_data.dart`: `MapData` (heights as `Uint16List`, terrain indices as `Uint8List`, features), `fromSource` (whole-map images, the authoring form), `toBuilt` and `fromBuilt` (tiles `<column>_<row>`, edge tiles smaller), the PNG codecs (`package:image`, MIT, licences checked).
- `lib/src/map_check.dart`: `checkMap` and `buildMap` → `MapBuild` (sealed: `MapBuilt(files)`, `MapRefused(problems)`); each `MapProblem` names its tile, cell or object.
- `lib/src/map_loader.dart`: `MapLoader<T>` (Factory Method: `load` reads the tiles, `make` is each side's) and `HostMapLoader` → `HostMap(navigation, objects, hqStarts, relicStarts)`; equal cells are shared.
- `bin/build_map.dart` (`dart run battle_map:build_map <plan> <source> <output>`) and `bin/map_memory_bench.dart`; `test/fixtures/valley/`: a 12 × 8 map in tiles of 4 with a river and its bridge, a forest, a mountain, a road and the floating island `sky` reached by a ladder and a reinforced bridge.

Decisions by the owner (2026-11-02), recorded in battle_team on `bt/m5-08-map`:
- Decision 216: a relic may start on a floating island; an HQ starts on the ground.
- Decision 217: objects stand only on land, bridges only on water with land at both ends (new rule MAP-48).
- Decision 218: a map places from `relics_to_hold` relics to fewer than twice as many.

Checks: analyze `--fatal-infos` clean, format clean, 45 tests pass, coverage 100 % (test optimization off).

Measured (`benchmark_results/README.md`): one loaded 10 × 50 km synthetic map with 187,960 objects takes about 152 MB (RSS growth, an upper bound): 40 MB of ground and 111 MB of objects, against stack decision 1's 20 + 15 MB. Both come from `battle_pathfinding`'s `NavigationMap` model (one pointer per cell; a map entry and a set per occupied cell). Loading the 80 tiles takes 1.8 s.

Choices:
- A source map is whole-map images and one `objects.yaml`, as authored (stack decision 5); the builder writes the tiles. A feature goes in the tile of its first cell (a link: of its `from` end), an island in the tile of its first area's corner.
- Heights are whole metres (16-bit, stack decision 5): a slope between two cells moves in steps of about 5.7°.
- Water terrains are those with `crossable_by` in `terrain.yaml`; floating island terrains those with `access`.
- An object's id is its type and first cell (`tree@(3, 4)`): two objects of one type never share a cell.
- A link must reach a floating island; a bridge over water is a construction.
- The loader expects a map the builder passed; it checks only the format.
- `battle_pathfinding`'s `PathRules.roadConstruction` defaults to `road`, while the data names the object `road_segment`: the host (M5.10) sets it.
