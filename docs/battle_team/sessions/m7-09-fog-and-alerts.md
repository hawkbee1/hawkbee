# Session M7.9: Fog shading and alerts

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 9. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `apps/battle_team` · **Branch:** `bt/m7-09-fog` · **Depends on:** M7.4.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `flutter_scene` material skills (`packages/flutter_scene`).
**Read** (`plan/` is `apps/battle_team/plan/`): MAP-27, MAP-29, MAP-33, MAP-49; RELIC-10, RELIC-16; decisions 232, 233, 235, 237; the session logs of M6.3 (what the host computes) and M6.4 (what reaches the client).

## Notes
- Shade the ground by what the section sees now (the view's data only: the client never computes sight, stack decision 8); never-seen may differ from once-seen.
- Alerts: the relic alert (also delivered on connect, decision 233) and the victory countdown (RELIC-16), plus MAP-49's always-known facts.
- Decision 237 test: the shading and alerts over a scripted battle give no clue about the unseen.
- End with a recording of two sections seeing differently, in this log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 9).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
