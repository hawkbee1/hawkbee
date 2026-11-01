# Session M4.6: Weapons and firing cycle

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 6. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-06-weapons` · **Depends on:** M4.3.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/70-combat-and-ap.md` (weapons, COMBAT-26 to COMBAT-33, COMBAT-56); `plan/data/combat.yaml` weapons, `weapon_swap`, dropped weapons; decisions 52 to 55, 63, 64, 134, 150 and 151.

## Notes
- Timeline tests drive time through the injected clock.
- The weapons waiting in a section's storage (decision 151) are a plain immutable list on the section.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m4-rules-core.md, Issue 6).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
_Written by the session agent when it finishes._
