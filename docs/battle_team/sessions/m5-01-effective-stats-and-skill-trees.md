# Session M5.1: Effective stats and skill trees

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 1. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m5-01-trees` · **Depends on:** M4 (merged).
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/20-units-and-progression.md` §6 and UNIT-36; COMBAT-52; `plan/data/units.yaml` `trees`; decisions 118, 167, 178; the M4.11 session log ("Deferred to M5").

## Notes
- A unit's tree is the count of bought steps per stat. Effective value = base × (1 + steps × `step_bonus`), never above `stat_cap_of_base` × base.
- Replace the reads of base `UnitType` stats in the M4 rules with an effective-stats view, so the host passes evolved units. Keep the M4 tests green unchanged: an unevolved unit is the base unit.
- XP spent on nodes is the unit's own unspent XP (UNIT-18). XP earning is M5.2: take the unit's XP as an input here.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m5-simulation-host.md, Issue 1).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02) in `packages/battle_rules`:
- `lib/src/progression/evolution.dart`: `EvolvableStat` (hp, attack, defense, move speed, vision range; the role values relay range, aura radius, transport weight, heal), `SkillTree` (steps bought per stat, unmodifiable), `Evolution(trees)` with `statsOf(type)`, `maxSteps`, `stepCost(n)`, `factor(steps)`, `buy(type:, tree:, stat:, step:, unspentXp:)` → `NodePurchase` (sealed: `NodeBought(tree, xpLeft)`, `NodeRefused(NodeRefusal)`), and `evolve(type, tree)` → the `UnitType` the unit plays.
- `UnitType.withValues`, `UnitStats.withEvolvable`, `UnitRole.withEvolvable` build that type; `UnitType.stats` and `role` now document that they may hold a unit's effective values.
- `GameData.parse` checks `trees`: only evolvable stats (AP maximum is not, UNIT-22), no role value in the default tree, an extra stat is a role value its type has, overrides name unit types, `step_bonus` above 0 and `stat_cap_of_base` at least 1.

How the M4 rules read effective stats (deferred from M4.11): `evolve` returns a `UnitType` whose `stats` and `role` are the evolved values, so every M4 rule that takes a `UnitType` (movement, vision, heal, damage) uses them with no signature change; hit chance already took numbers. A unit with no node plays its base type itself.

Checks: analyze `--fatal-infos` clean, format clean, 453 tests pass, coverage 100 % (test optimization off).

Deviations:
- A 21st step is refused (`aboveCap`) rather than bought for nothing; `evolve` still clamps at the cap.
- Relay range, aura radius and transport weight have no consumer in `battle_rules` yet (the scenario runner reads relay range from the type, so an evolved radio relays farther there). Their tests check the evolved values; the host uses them (M5.11).

For M5.2 (question to ask the owner then): XP spent on nodes leaves the unit's unspent XP. Do target scaling (UNIT-09) and team power (UNIT-12) count the XP a unit earned, or only what it has left?
