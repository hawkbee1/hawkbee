# Session M4.10: Role actions, pushing, HQ moves, interruption

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 10. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-10-actions` · **Depends on:** M4.3, M4.4.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/70-combat-and-ap.md` (role actions); `plan/specs/30-special-units-and-victory.md` (capture, push); `plan/specs/50-hq.md` §3 (moving the HQ); `plan/data/combat.yaml` `actions`, `push`; `plan/data/battle.yaml` `capture`, `hq`; decisions 66, 67, 97, 138, 140 and 170 to 179.

## Notes
- Pots: one capture pot per relic and team, one push pot per relic for its owner. Keep each contributor's AP in the pot: capture XP is split by it (decision 179, paid in M5).
- What empties a pot (decision 176): a push pot when another team captures the relic or the relic falls; a capture pot when an enemy enters the radius, from the first AP put in.
- HQ moves (decision 177): the HQ's own AP pool (M4.3), the cost of M4.4 with `hq.ap_per_m` and the `push` profile, `hq.speed_m_per_h`; any unit in its path ends the order.
- Positions stay abstract: distances, "inside the radius", "a unit in the path". Paths come from M3 and the map from M5.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m4-rules-core.md, Issue 10).
- [ ] A capture pot records each contributor's AP.
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
_Written by the session agent when it finishes._
