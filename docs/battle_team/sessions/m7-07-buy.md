# Session M7.7: Buy

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 7. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `apps/battle_team` · **Branch:** `bt/m7-07-buy` · **Depends on:** M7.6.
**Skills:** `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): ECO-04 to ECO-07, HQ-42, HQ-46, COMBAT-27; `plan/data/units.yaml` and `plan/data/economy.yaml` (prices); the session log of M7.6.

## Notes
- Money shown; `BuyUnit` from the roster with prices from `plan/data`, `BuyWeapon` for a unit. `BuyGuildCamp` and `BuyNode` wait for a later progression session: leave them out.
- Refusals (money, room, lock, enemy at the portal, `test_units` off for the test unit) surfaced with their reasons, localized.
- End with a screenshot in this log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 7).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
