# Session M5.3: Money

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 3. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m5-03-money` · **Depends on:** M5.2.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/60-economy.md`; SOC-10 to SOC-15; COMBAT-27; `plan/milestones/economy.yaml` (it lives in `milestones/`, M4.2 log); decisions 102, 111, 112, 130.

## Notes
- Fees are a share of the amount: if the rounding of w€ amounts is not stated, ask the user.
- Purchases check free room with the cap of M5.2. Where the unit arrives is M5.4 (HQ-46).
- XP cannot be bought (ECO-21): no API offers it; a test shows that no purchase changes XP.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 3).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
