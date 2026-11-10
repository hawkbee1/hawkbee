# Session M7.8: Move: path preview and AP cost

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 8. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `packages/battle_client` (pre-check), `apps/battle_team` · **Branch:** `bt/m7-08-path-preview` · **Depends on:** M7.1 (M7.2 for fast manual runs).
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): COMBAT-03, COMBAT-06, MAP-20, MAP-47, MAP-50, `plan/specs/10-map-and-terrain.md` §3 and §4; decisions 169, 180, 236, 240; `plan/stack/08-workload-placement.md`; `plan/data/terrain.yaml` (`ap_multiplier`, slopes), `plan/data/units.yaml` (`ap_per_m`, movement classes); the session logs of M3.3 (unit paths, path check), M3.6 (long paths, search data), M4.4 (movement cost), M6.7 (the pre-check was deferred here), M7.1.

## Steps
1. **Where the map is**: the app loads `saint_lo_1km`'s built tiles (`battle_map`, `lib/battle/map_assets.dart`). `battle_pathfinding` builds its `NavigationMap` from the same tiles (M3.2, M5.8): check the loader exposes what the client has; if it needs the full map in memory, note the cost (P-06, M7.13).
2. **Pre-check port in `battle_client`**: `MovePreview previewMove(unitId, destination)` → path points, AP cost, arrival time, or a `MoveRefusal` (unreachable, occupied by a seen unit — MAP-50, cutting corners — MAP-47). Implemented on `battle_pathfinding` + `battle_rules` behind a port (`PathPlanner`), so tests inject a fake and the app injects the real one. Display only: the doc comment says the host decides.
3. **UI**: on tapping the ground with a unit selected, draw the preview (a line through the `BattleWorld` seam: `showPath(points)`, `FakeWorld` records it) with the AP cost against the unit's AP and, when AP run short, the wait COMBAT-06 implies; a Confirm button sends `Move`; a refused preview shows why and sends nothing. A seen occupant at the destination shows "occupied" (MAP-50); unseen ones are unknown to the client by design.
4. **Divergence**: when the host refuses or replies with another arrival, the UI shows the host's answer and drops the preview; it never argues.
5. **Scripted checks**: grass, slope, road, water (boat vs. foot), a wall corner, an occupied cell: the preview's cost and refusal match what `battle_host` answers for the same order (reuse the host's test map or the recorded streams; where the host's answer is not available in a recording, run the host's rules in the test).
6. **Gates** (§4, §6) for `battle_client` and the app; **show it** (recording: a long preview, a refused one); **finish** (§5): `battle_client` PR first.

## Tests to write
- `COMBAT-03 preview cost equals ap_per_m × terrain × slope along the path` (real data, fixture map).
- `MAP-47 a path never cuts a wall's corner`; `MAP-50 a destination held by a seen unit is refused before sending`.
- `COMBAT-06 a cost above the AP shows the wait at the recovery delay`.
- `decision 236 the unit glides to its arrival time after confirmation` (already in M7.1's tests; extend).
- Widget tests: confirm/cancel, cost label (en, fr), refusal label.

## Stop and ask when
- The client cannot build the navigation model from the assets it has (memory or missing data): ask whether to download a prepared model or defer the preview to the host (a `PreviewMove` request would be a protocol change).

## Pitfalls
- `battle_pathfinding` is pure Dart and may be slow on a 1 km map in debug: measure once and write the number in the log; do not optimise in this session.
- Two sources of truth for movement cost are forbidden: call `battle_rules`, copy no table.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 8).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log
