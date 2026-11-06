# Session M5.20: First map from real data

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 20. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_map` (`hawkbee1/battle_map`) · **Branch:** `bt/m5-20-real-map` · **Depends on:** M5.8.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:license-compliance`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/05-map-format.md` (authoring, licences); MAP-01, MAP-02, MAP-04; the session log of M5.8.

## Notes
- Ask the user which 10 × 50 km area to use before downloading anything.
- Downloaded data is untrusted input: keep it outside the repository, in its own folder; commit only the builder code and, if the user agrees, the resulting tiles.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m5-simulation-host.md, Issue 20).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-05/06). Area chosen by the owner: Normandy bocage. The owner also agreed to commit the tiles.
- **`battle_map`** (battle_map #2, from `main`):
  - `package:battle_map/map_import.dart` (pure): `ImportSpec` (`import.yaml`: area in Lambert-93, terrain index, area/line/object rules, starting points), `Lambert93`, `OsmExtract` (Overpass `out geom`), the rasteriser (even-odd fill, 4-connected line walk, buffer), `importMap` (heights, terrain, bridges, objects, report, attribution), and the request builders for the IGN WMS and Overpass.
  - Tools: `fetch_map_sources`, `import_map`, `preview_map` and `source_map` (built map back to a source map).
  - `map.yaml` has an optional `attribution`, which the builder carries into the built map. `MapData.toSource()` is new. `YamlReader` is shared by the map and import files.
  - `maps/source/saint_lo/import.yaml` and `maps/built/saint_lo/` hold 80 tiles (12 MB): the Vire valley from south of Isigny-sur-Mer through Saint-Lô, Lambert-93 397–407 km E, 6,867–6,917 km N. It has 246k objects (46.5k buildings, 200k trees, 299 walls) and 51 bridges, 17 of them reinforced (one by hand). `maps/README.md` covers the licences, the workflow and the hand corrections.
- **`battle_host`** (battle_host #10, stacked on #9): `test/src/maps/saint_lo_test.dart` loads the map through `MapLibrary` and `DirectoryMapSource`, then starts a 5-team battle on it.
- **`battle_team`** (battle_team #26, stacked on #25): Q-MAP-20 to Q-MAP-23, assumed.

Checks: analyze `--fatal-infos` and format are clean. Tests pass with 100 % coverage, optimization off: `battle_map` 90, `battle_host` 272 (the Appwrite suite is opt-in and skipped). Dependency licences are BSD-3-Clause and MIT only; there's no new dependency.

Acceptance criteria:
- One real 10 × 50 km area turned into tiles: `saint_lo`, 1,000 × 5,000 cells. The tiles pass every check of the builder (`battle_map/test/src/maps/saint_lo_test.dart`) and load in the host (`battle_host/test/src/maps/saint_lo_test.dart`).
- Licences checked and attributions written with the map. OpenStreetMap is under ODbL 1.0: the built map is a derived database, offered under the ODbL. IGN RGE ALTI is under Licence Ouverte 2.0. Each `map.yaml` carries both lines, with the dates of the data. The Copernicus DEM licence is noted in `maps/README.md` for later maps.

Hand corrections (authoring steps 2 and 3):
- Starting points: HQs at both ends and spread between them for 3 to 5 teams. Eight relics sit two by two at the same distance from the middle row, one in Saint-Lô. All are on open grass or road with free cells around.
- `bridge@(499, 256)` is now a reinforced bridge. A flood fill found the north HQ's land (2.8 km², east of the Vire) linked to the rest only by bridges that relics and the HQ cannot cross. Wheeled and foot units reach every starting point.

Choices:
- Heights come from the IGN Géoplateforme WMS (layer `ELEVATION.ELEVATIONGRIDCOVERAGE.HIGHRES`, 32-bit BIL), one value per 10 m cell. This avoids downloading the RGE ALTI tiles of the département. Heights are in whole metres from zero.
- OpenStreetMap comes from the Overpass API, for the keys the rules read, in a WGS84 box around the map.
- Area rules are painted before line rules, a later rule over an earlier one, and land never covers water. Each element takes the first rule it matches in each list.
- A bridge is the stretch of water cells under a way tagged `bridge`, from land to land. When the way ends over water, the bridge continues along the road way joined at that end. Bridges of motorways, trunk, primary and secondary roads are reinforced (Q-MAP-21).
- Committed: the import file and the built tiles only. The source map comes back from the tiles with `source_map`. Re-importing gives newer OSM data and drops the hand corrections, which `maps/README.md` lists.
- Copernicus is not read yet (Q-MAP-23).

Not done: Q-MAP-20 to Q-MAP-23 are assumed, not asked. The map's memory is not measured again: with 246k objects, it is above M5.8's 152 MB synthetic figure (deferred by the owner).
