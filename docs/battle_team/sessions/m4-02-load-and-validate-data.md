# Session M4.2: Load and validate the data files

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 2. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-02-data` · **Depends on:** M4.1.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): every file of `plan/data/`, comments included; the rules the issue lists (specs 10, 20, 70).

## Notes
- Add `yaml`. The public API takes the **text** of each file and returns typed, immutable models; it never opens a file (stack decision 7). Tests read the real files through the M4.1 helper.
- Models cover units, weapons, the damage table, hit chance, aim, terrain and the slope rows (classes and the `flying`, `sail` and `push` profiles), battle settings (with `ap`, `capture`, `push`, `hq`), economy and medals. Keep each file's `version`.
- The checks are the issue's list. They include the latest decisions: the `push` column and slope row (175), `hit_box_m` for every unit and the HQ, `projectile_speed_mps` for every flying shot (183), base speed caps (174, 178).
- The test on the real files guards against drift. If it fails after a data change, fix the parser or ask the user. Never change the data to pass.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m4-rules-core.md, Issue 2).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
_Written by the session agent when it finishes._
