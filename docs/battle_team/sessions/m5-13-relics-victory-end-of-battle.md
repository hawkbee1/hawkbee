# Session M5.13: Relics, victory and the end of a battle

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 13. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m5-13-relics-end` · **Depends on:** M5.5, M5.11.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): the session logs of M5.5 and M5.11; `plan/specs/30-special-units-and-victory.md`; `plan/specs/50-hq.md` §3, §4; decision 138.

## Notes
- The end-of-battle event is what `end_battle` (M5.18) reads: give it the winner, the eliminations in order and the time, and version it with the log format (M5.9).
- `VictoryRules` (M5.5) returns the events; the host applies `StorageRules.atElimination` to an eliminated team's units, and the order chain refuses that team's orders: it is out of the battle (HQ-18).

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 13).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
