# Session M5.5: Relic ownership and victory

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 5. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m5-05-victory` · **Depends on:** M5.4.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/30-special-units-and-victory.md` §2 to §5; `plan/specs/50-hq.md` §4, §6; `plan/data/battle.yaml` `victory`, `capture`; decisions 45, 46c, 99, 100, 116; the M4.10 session log.

## Notes
- The victory timer is state with a start time, not a countdown ticked every second: "held since t" is enough to show the countdown and to detect the win at t + `hold_s`.
- Owner changes and eliminations are returned as events (Observer); the host logs them and M6 sends the alert.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 5).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
