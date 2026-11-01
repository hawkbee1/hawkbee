# Session M4.3: Simulation clock and AP pool

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 3. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-03-clock-ap` · **Depends on:** M4.2.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/70-combat-and-ap.md` §1; `plan/data/battle.yaml` `ap`, `plan/data/combat.yaml` `ap`; `plan/stack/01-simulation-host.md` (Choice: lazy AP).

## Notes
- AP is lazy (stack decision 1): a pool keeps its value at its last update, and AP at time *t* is `min(ap_max, value + hours since × recovery_per_hour)`. No work per tick.
- The pool is not tied to units: the HQ has one too (`hq.ap_max`, decision 177), used in M4.10.
- "Waits until it has enough AP" means: return the time at which the action can start. Nothing sleeps.
- Movement at 0 AP: the speed is the recovery rate ÷ the AP per metre. Take the AP per metre as an input here; M4.4 computes it.
- The property test runs seeded random sequences of actions and time steps; no new dependency is needed.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m4-rules-core.md, Issue 3).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
_Written by the session agent when it finishes._
