# Session M3.4: Paths for relics and HQs

**Issue:** `apps/battle_team/plan/milestones/m3-pathfinding.md`, Issue 4. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_pathfinding` (`hawkbee1/battle_pathfinding`) · **Branch:** `bt/m3-04-relic-paths` · **Depends on:** M3.3.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): RELIC-19 to RELIC-22, RELIC-26, RELIC-28 in `plan/specs/30-special-units-and-victory.md`; HQ-11, HQ-14, HQ-48 in `plan/specs/50-hq.md`; decisions 99, 116, 117, 148, 175 and 177.

## Notes
- Relics and the HQ use the `push` profile; the AP per metre is passed in: `push.pot_ap_per_m` for a relic, `hq.ap_per_m` for the HQ (decisions 175, 177).
- A path may go over a floating island's edge: the result marks where the relic or HQ falls.
- Units in the way are not a path question: a unit in the HQ's path ends the order in M4.10.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m3-pathfinding.md, Issue 4).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
_Written by the session agent when it finishes._
