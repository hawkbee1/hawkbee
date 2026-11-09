# Session M7.5: Fire

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 5. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `apps/battle_team`, `packages/battle_client` (pre-check) · **Branch:** `bt/m7-05-fire` · **Depends on:** M7.4.
**Skills:** `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): COMBAT-11 to COMBAT-26, COMBAT-57/58, decisions 183, 234, 237; `plan/data/combat.yaml`, `plan/data/units.yaml` (weapons); the session logs of M6.2 (messages: `Fired`, `UnseenHit`, bursts) and M7.4.

## Notes
- Orders `Fire`, `FireAtPosition`, `FireAimed` (first person), `Reload`, `SwapWeapon`; weapon, ammunition and reload state on the selected unit.
- Draw from the stream's events only: bursts, hits, and unseen hits with nothing of the shooter (decisions 234, 237) — prove it over a scripted battle, and keep logs clean of it too.
- Surface refusals (AP, range, ammunition, UNIT-38) where the order was given, localized en + fr.
- A test unit (M7.2) makes manual runs fast. End with a recording in this log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 5).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
