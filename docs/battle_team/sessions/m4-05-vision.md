# Session M4.5: Vision

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 5. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-05-vision` · **Depends on:** M4.2.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/10-map-and-terrain.md` (vision, MAP-26 to MAP-35); COMBAT-11, UNIT-34; `plan/data/terrain.yaml` `vision` and `weather`; decisions 59, 87 and 119.

## Notes
- The input is an abstract sight line, with no geometry (the issue). The host builds sight lines from the map later (M5).
- Weather is a state of the battle, passed in.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m4-rules-core.md, Issue 5).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-01), stacked on M4.4 (not merged yet), in `packages/battle_rules/lib/src/vision/vision.dart`:
- `SightLine(distanceM, observerTerrain, heightAboveTargetM, forestCrossedM, obstacles)`; obstacles are `TerrainObstacle(type)` or `ObjectObstacle(type, destroyed:)` (sealed).
- `Vision(terrain)`: `effectiveRange(visionRange:, weather:, line:, observeBonusM:)` = `(visionRange + observe bonus) × weather × terrain + height bonus (only when higher, capped) − forest × cost`; `blocks(obstacle)` (`blocks_los`, unless destroyed and `destroyed_objects_block` is false); `sees(...)`; `unitSees(unit:, ..., observation:)`; `canFireAt(unit:, weapon:, ...)` (own sight and weapon range, COMBAT-11); `Vision.sectionSees(sightings)` (MAP-29).
- `Observation(role, startedAt)`: `endsAt`, `isActiveAt`, `bonusAt`, `allowsMovingAt` (the scout cannot move while observing).

Checks: analyze `--fatal-infos` clean, format clean, 259 tests pass, coverage 100 % (857/857 lines).

Question raised and decided by the owner (2026-11-01): where the observe bonus goes. Owner: added to `vision_range`, before the weather and terrain factors. Recorded in battle_team on `bt/m4-05-vision`: decision 184, Q-UNIT-23, UNIT-34 and the effective-vision formula of spec 10.

Deviations:
- A lower observer gets no height bonus and no penalty: `height_bonus_m_per_m` is "per metre the observer stands above the target".
- `canFireAt` covers direct fire only. M4.7 adds indirect fire on a position seen by the section or relayed by a radio, and the radio relay itself (MAP-29's second half, awareness).
- MAP-29 is the plain "any unit of the section sees it": positions and relay ranges need the map (M5).
