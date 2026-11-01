# Session M4.7: Hit chance and first-person shots

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 7. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-07-hit-chance` · **Depends on:** M4.5, M4.6.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/70-combat-and-ap.md` §2; `plan/data/combat.yaml` `hit_chance`, `aim`, `miss_scatter`, weapons; `hit_box_m` in `units.yaml` and `battle.yaml`; decisions 62, 65, 95, 135, 152, 154 and 183; `plan/stack/08-workload-placement.md` (Client trust).

## Notes
- First-person shots (decision 183): the inputs are the shooter's position, the aim direction and the fire time. The rules core adds the spread with the injected `SeededRandom`, flies the projectile at `projectile_speed_mps`, and returns the first hit volume or obstacle on its path.
- Targets are given with their motion during the flight (for example position and velocity at fire time), so a target can leave the line. Obstacles come from an injected query, as sight lines do in M4.5. Plain vector maths, no 3D engine.
- This is the code the host runs: a client never decides a hit (stack decision 8).

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m4-rules-core.md, Issue 7).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
_Written by the session agent when it finishes._
