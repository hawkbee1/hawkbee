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
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 1).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
