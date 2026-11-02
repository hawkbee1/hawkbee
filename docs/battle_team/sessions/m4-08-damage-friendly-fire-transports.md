# Session M4.8: Damage, friendly fire, transports

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 8. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-08-damage` · **Depends on:** M4.2.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/70-combat-and-ap.md` (damage); UNIT-37, MAP-40, HQ-16, HQ-22; `plan/data/combat.yaml` `multipliers`, `splash`, transports; `plan/data/terrain.yaml` objects; decisions 57, 81, 136, 137 and 152.

## Notes
- The weapon × armor test is one table-driven test over the real table, so a new weapon or armor type is covered without new code.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m4-rules-core.md, Issue 8).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-01), stacked on M4.5 (not merged yet; its own dependency is only M4.2), in `packages/battle_rules/lib/src/combat/damage.dart`:
- `DamageTarget(armorType, flying:, friendly:)`: units, objects (their `armor_type`, MAP-40), the HQ (`hq`) and relics (`relic`).
- `Damage(combat)`: `hit(weapon, target)` = `base_damage × multipliers[weapon][armor]`, `× airborne_factor` when flying, `× friendly_fire.damage_factor` (0 when friendly fire is off) when friendly; `splashFactor(weapon, distance)` and `splash(...)` (linear from 1 to `damage_factor_at_edge`, 0 beyond `splash_radius_m`); `carriedHit(weapon, carried)` (`carried_damage_share` with the carried unit's armor); `ejection(stats)` (`ejection_damage_share_of_max_hp × hp`).
- `Health(current, max)`: `full`, `damaged` (not below 0), `isZero`.

Checks: analyze `--fatal-infos` clean, format clean, 279 tests pass, coverage 100 %. The weapon × armor test reads the real table through raw YAML, so a new weapon or armor type is covered without new code.

Deviations and open points:
- A carried unit is hit as flying when its transport flies (only the armor type changes, decision 81). Today only the truck and the boat carry; the helicopter may carry (MAP-18).
- Splash supports `falloff: linear` only, the one value of the data; another value throws.
- Open point for the owner: does friendly fire damage the own HQ? COMBAT-34 says friendly fire hurts allies like enemies; HQ-16 says "enemy units damage it". The code applies the friendly-fire factor to any friendly target, the HQ included.
- "Stored units can never be harmed" (UNIT-37) needs no code here: a stored unit is never a target.

For the next sessions: M4.9 turns `Health.isZero` into death, defection or prisoner; M4.7 hands `splash` the landing point of an artillery shot.
