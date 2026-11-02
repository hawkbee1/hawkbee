# Session M5.4: Storage, deployment and the commander's death

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 4. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m5-04-storage` · **Depends on:** M5.2, M5.3.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/50-hq.md` §1, §5; UNIT-28, UNIT-29, UNIT-42; COMBAT-37 to COMBAT-45 (prisoners); `plan/data/battle.yaml` `storage`, `commander_death`, `section_redeploy_lock_s`; decisions 80, 94, 110, 120, 125, 129, 130, 141.

## Notes
- Unit location is a State (stack decision 7): on the field, carried, stored, prisoner. Each state owns the actions it allows; cite the pattern in the doc comment.
- Positions stay abstract, as in M4: distances to the storage place, enemies inside a radius.
- Weapons in storage (M4.6 `StoredWeapons`) stay with the section when its units are stored.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 4).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
