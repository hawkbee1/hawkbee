# Session M7.11: Unit filters

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 11. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `apps/battle_team` (and `packages/battle_protocol` + `packages/battle_host` only if the view lacks the guild) · **Branch:** `bt/m7-11-filters` · **Depends on:** M7.1.
**Skills:** `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): Q-MAP-27 (a seen unit shows its team), decisions 21, 237; the session log of M6.2 (`SectionView`, `UnitView`).

## Notes
- Filters over drawing and lists: my units / friendly / enemy / my guild's. A filter hides, never reveals.
- If `UnitView` lacks the guild of a friendly section, extend the protocol under M6's conventions (samples, sizes) — and only for friendly units the section sees.
- End with a screenshot per filter in this log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 11).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
