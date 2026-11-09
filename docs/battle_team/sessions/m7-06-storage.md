# Session M7.6: Storage: view, store, unstore

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 6. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `apps/battle_team` · **Branch:** `bt/m7-06-storage` · **Depends on:** M7.1 (M7.2 for fast testing).
**Skills:** `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:accessibility`.
**Read** (`plan/` is `apps/battle_team/plan/`): HQ-29, HQ-31 to HQ-36, HQ-39, HQ-46; decisions 110, 120, 125, 204; `plan/data/battle.yaml` (`storage:`); the session log of M7.1 (where the playtest's Deploy lives).

## Notes
- The storage view: stored units, the portal, deploy cost (10 AP), the 24-hour lock with remaining time, the blocked-by-enemy state, prisoners.
- `Store` (instant within `store_radius_m`, else the recall delay), `Recall`, `Deploy`; the playtest's Deploy button moves into this view.
- Every state the view shows comes from the section's own private view: nothing of other sections (HQ-29).
- End with a screenshot in this log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 6).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
