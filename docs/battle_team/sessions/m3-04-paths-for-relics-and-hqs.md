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
- [x] The acceptance criteria of the issue (m3-pathfinding.md, Issue 4).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02), stacked on M3.3 (not merged yet), in `packages/battle_pathfinding/lib/src/path_search.dart` (the same `Pathfinder`):
- A relic is `PathMover(apPerM: push.pot_ap_per_m, modes: ['push'])`, the HQ `PathMover(apPerM: hq.ap_per_m, modes: ['push'])`. The injected cost's `push` column makes forests, towns, mountains and water impassable; `push` is a ground-like mode, so walls and buildings stop it and roads carry it.
- `PathRules.reinforcedOnlyModes` (`push`): over water and up to islands only on reinforced bridges (constructions and links).
- `PathRules.fallModes` (`push`): a step from an island cell to a ground cell next to it that the island does not cover is a fall. `FoundPath.falls` and `PathPasses.falls` list the landing cells.

Checks: analyze `--fatal-infos` clean, format clean, 84 tests pass, coverage 100 % (324/324 lines).

Assumption (owner asleep): Q-MAP-16 in battle_team on `bt/m3-04-relic-paths`: the fall is free, it lands on the ground cell next to the edge whatever its terrain, and the path goes on from there. Units never go over an edge.

For the next sessions: units standing in the path are not a path question (M4.10 crushes or ends the order).
