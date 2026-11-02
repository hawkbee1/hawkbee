# Session M4.7: Hit chance and first-person shots

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 7. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-07-hit-chance` · **Depends on:** M4.5, M4.6.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/70-combat-and-ap.md` §2; `plan/data/combat.yaml` `hit_chance`, `aim`, `miss_scatter`, weapons; `hit_box_m` in `units.yaml` and `battle.yaml`; decisions 62, 65, 95, 135, 152, 154 and 183; `plan/stack/08-workload-placement.md` (Client trust).

## Notes
- First-person shots (decision 183): the inputs are the shooter's position, the aim direction and the fire time. The rules core adds the spread with the injected `SeededRandom`, flies the projectile at `projectile_speed_mps`, and returns the first hit volume or obstacle on its path.
- Targets are given with their motion during the flight (for example position and velocity at fire time), so a target can leave the line. Obstacles come from an injected query, as sight lines do in M4.5. Plain vector maths, no 3D engine.
- This is the code the host runs: a client never decides a hit (stack decision 8).

## Acceptance criteria
- [x] The acceptance criteria of the issue (m4-rules-core.md, Issue 7).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-01), stacked on M4.10 (not merged yet), in `packages/battle_rules/lib/src/combat/`:
- `seeded_random.dart`: the `SeededRandom` port (stack decision 7) and `DartSeededRandom(seed)`.
- `hit_chance.dart`: `HitChance(combat)` with `of(weapon:, attack:, morale:, defense:, targetArmor:, targetSpeedMps:, distanceM:, cover:)` (the clamped formula; `Cover` none, partial, full), `moraleFactor`, `HitChance.roll` → `HitRoll(roll, chance)` (`hits`, `missImportance`), `HitChance.canTargetPosition` (indirect fire on a position seen by the section or relayed by a radio, within range), `landingPoint` (decision 154 scatter, pulled back to the range).
- `vec3.dart`: `Vec3`, plain vector maths.
- `first_person.dart`: `FirstPersonShots(combat)` with `spreadDeg`, `deviate` (uniform over the spread cone) and `fire(weapon:, origin:, aim:, fireTime:, attack:, morale:, random:, targets:, obstacles:)` → `ShotHitsTarget`, `ShotHitsObstacle` or `ShotMisses`. `ShotTarget` (position, `hit_box_m` turned by its heading, velocity during the flight); `ObstacleQuery` port for terrain and objects. The projectile flies straight at `projectile_speed_mps` up to `range_m`; moving boxes are met with a slab test in their own axes.

Checks: analyze `--fatal-infos` clean, format clean, 379 tests pass, coverage 100 % (1235/1235 lines). Statistical test: 10,000 rolls with seed 7 on real data hit within 1 % of the chance.

Deviations and choices:
- The morale factor is linear over `morale.range` (`at_0` at its lowest, `at_100` at its highest), which is 0 to 100 in the data.
- Spread: `base × (1 − reduction × attack) ÷ morale factor`, then `min_spread_deg` (the floor comes last). The deviation is uniform over the cone's opening.
- Shots fly in a straight line (no drop); a shot that reaches its range stops.
- COMBAT-16 (both modes give comparable results) is a balancing target: the test checks that attack and morale move the hit chance and the spread the same way. Measuring the averages belongs to the scenario harness (M4.11).
