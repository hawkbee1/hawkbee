# Session M5.6: Teams, newcomers and the HQ manager

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 6. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m5-06-teams` · **Depends on:** M5.2.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/40-newcomers-and-social.md` §1, SOC-29, SOC-30; `plan/specs/50-hq.md` §2; `plan/data/battle.yaml` `teams`; `plan/data/medals.yaml` `points`; decisions 47, 93, 101, 103, 121, 129.

## Notes
- Balancing by power with guilds kept together is a partition problem: a greedy largest-block-first method is enough if its worst case is stated in the doc comment and tested.
- Medal points come from the medals a player holds (M5.17 computes them); here they are an input.
- A newcomer's commander arrives next to his section's portal (HQ-46, decision 129; `StorageRules.placeOf`). Decision 205 refuses a purchase whose arrival is blocked, but a commander is not bought: ask the owner what happens when an enemy within 20 m blocks his arrival before coding it.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 6).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
