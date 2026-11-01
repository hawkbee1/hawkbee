# Session M4.4: Movement cost

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 4. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-04-movement` · **Depends on:** M4.2.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/10-map-and-terrain.md` (movement); COMBAT-03 in `plan/specs/70-combat-and-ap.md`; `plan/data/terrain.yaml`; decisions 133, 169, 175, 177 and 180 in `plan/specs/00-overview.md`.

## Notes
- One function serves units, pushed relics and the HQ. The AP per metre is an input: the unit's `ap_per_m`, `push.pot_ap_per_m` for a relic, `hq.ap_per_m` for the HQ; the last two use the `push` profile (decisions 175, 177).
- Its shape is the cost M3 injects: `(AP per metre, class or profile, terrain type, signed slope) → AP per metre, or impassable`. Keep that signature: the two packages never depend on each other, a caller wires them.
- Time along a path is its length ÷ `move_speed`, whatever the terrain and slope (decision 180).

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m4-rules-core.md, Issue 4).
- [ ] A pushed relic and an HQ priced with the `push` profile on grass, mud, road and a slope.
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
_Written by the session agent when it finishes._
