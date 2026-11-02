# Session M4.4: Movement cost

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 4. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-04-movement` · **Depends on:** M4.2.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/10-map-and-terrain.md` (movement); COMBAT-03 in `plan/specs/70-combat-and-ap.md`; `plan/data/terrain.yaml`; decisions 133, 169, 175, 177 and 180 in `plan/specs/00-overview.md`.

## Notes
- One function serves units, pushed relics and the HQ. The AP per metre is an input: the unit's `ap_per_m`, `push.pot_ap_per_m` for a relic, `hq.ap_per_m` for the HQ; the last two use the `push` profile (decisions 175, 177).
- Its shape is the cost M3 injects: `(AP per metre, class or profile, terrain type, signed slope) → AP per metre, or impassable`. Keep that signature: the two packages never depend on each other, a caller wires them.
- Time along a path is its length ÷ `move_speed`, whatever the terrain and slope (decision 180).

## Acceptance criteria
- [x] The acceptance criteria of the issue (m4-rules-core.md, Issue 4).
- [x] A pushed relic and an HQ priced with the `push` profile on grass, mud, road and a slope.
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-01), stacked on M4.3 (not merged yet), in `packages/battle_rules/lib/src/movement/movement_cost.dart`:
- `MovementCost(terrain)`, Strategy (stack decision 7). `call(apPerM, mode, terrainType, slopeDegrees)` is the shape M3 injects: `apPerM × ap_multiplier[mode] × max(min_multiplier, 1 + slope × factor)`, null when the table says null or `|slope| > max_degrees`. Unknown terrain types and modes throw an `ArgumentError`.
- `Mover(apPerM, modes, speedMps)` with `Mover.unit(unit, flying:)`, `Mover.hq(hq)` and `Mover.relic(push)`: the last two use the `push` profile with `hq.ap_per_m` and `push.pot_ap_per_m`, at their speed per hour.
- `PathSample(terrainType, slopeDegrees, lengthM)`; `ofSample` (cheapest passable mode of the mover), `ofPath` (sum, null when a sample is impassable) and `move(mover:, pool:, start:, path:)`, which chains M4.3's `moveAlong` per sample and does not move at all when a sample is impassable.

Checks: analyze `--fatal-infos` clean, format clean, 238 tests pass, coverage 100 % (806/806 lines). The fixture terrain gained `mud` and `road` for the push-profile cases.

Deviations:
- An amphibious unit uses its ground class and `sail`, and each sample takes the cheaper passable one. "Whichever fits the terrain" does not say what happens where both pass; no terrain of the current data allows both (water is null for ground classes, land is null for `sail`).
- No amphibious unit exists in `units.yaml`: its test turns the fixture boat amphibious.

For the next sessions: M3's path search can take `MovementCost.call` as its injected cost. M4.10 uses `Mover.hq` and `Mover.relic` (`ofPath` prices a push from the pot).
