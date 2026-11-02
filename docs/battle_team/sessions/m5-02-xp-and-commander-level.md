# Session M5.2: XP, section XP and commander level

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 2. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m5-02-xp` · **Depends on:** M4 (merged).
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/20-units-and-progression.md` §5; `plan/data/units.yaml` `progression`; decisions 77, 79, 92, 127, 144, 179; the M4.10 session log (capture pot contributions).

## Notes
- Diminishing returns (UNIT-10) count repeats per (attacker, target) and per (engineer, build spot) inside `diminishing.window_s`. If what makes two build spots "the same" is unclear, ask the user (agent-workflow §2).
- "Near the commander" (UNIT-08): if no rule gives the distance, ask the user before using the aura radius.
- The section share is moved, not copied: the unit keeps 1 − `section_xp_share` (UNIT-14).

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 2).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
