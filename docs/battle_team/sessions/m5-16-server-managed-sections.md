# Session M5.16: Server-managed sections

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 16. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m5-16-server-sections` · **Depends on:** M5.11.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/80-ai-and-automation.md`; `plan/data/battle.yaml` `server_managed`; decisions 159, 160, 163 to 166, 196.

## Notes
- The check is a timer per unit every `check_interval_s`, not a roll on entering range (AI-07).
- Decision 159: the purpose of these sections stays out of the code's comments too.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 16).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
