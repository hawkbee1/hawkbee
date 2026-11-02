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
- [x] The acceptance criteria of the issue (m4-rules-core.md, Issue 10).
- [x] A capture pot records each contributor's AP.
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-01), stacked on M4.6 (not merged yet), in `packages/battle_rules/lib/src/actions/`:
- `role_actions.dart`: `TimedAction(ap, duration, progress, startedAt)` (`remainingAp`, `endsAt`, `progressAt`, `interruptedAt`: AP lost, progress kept); `RoleActionRules(combat:, terrain:)` with `startBuild` (structure AP and build time, only the role's structures), `startRepair`, `resume` (pays the part left; any unit may resume), `heal` (instant, `heal_ap` for `heal` HP, capped at max), `repairHp`. Heal and repair: friendly targets only, never the HQ (`ActionTarget`).
- `capture.dart`: `CapturePot(team, contributions by unit id, fullAt)`; `CaptureRules(settings)` with `contribute` (inside the radius, no enemy inside, `contribution_ap`, full at `pot_ap` and the timer starts), `withOccupants` (an enemy inside empties it, even with no unit of its team inside), `capturedAt`, `enemyInRadius` (every `Presence` counts).
- `push.dart`: `PushPot(owner, ap)` with `capturedBy` and `fallen`; `PushingRules(push:, cost:)` with `contribute` and `move` (needs `min_pushers`, pays `pot_ap_per_m` × `push` profile per metre, stops when the pot is empty, crushes the first `(pushers − min) × crush_units_per_extra_pusher` units it meets and stops at the next, decision 185). `PushMove(distanceM, endsAt, pot, crushed, stop)`.
- `hq_move.dart`: `moveHq(hq:, cost:, pool:, start:, path:, unitInPathAtM:)`: the HQ's own pool, `Mover.hq`, ended where a unit stands (`endedByUnit`); `pathUpTo`.
- `action_result.dart`: `ActionResult` (sealed): `ActionRefused(ActionRefusal)`, `TimedActionStarted`, `Healed`, `CaptureContributed`, `PushContributed`. `Health.healed` added to M4.8's `Health`.

Checks: analyze `--fatal-infos` clean, format clean, 342 tests pass, coverage 100 % (1105/1105 lines).

Questions raised and decided by the owner (2026-11-01), recorded in battle_team on `bt/m4-10-role-actions`:
- Decision 185 (Q-CBT-35, RELIC-25): with 10 + n pushers the relic crushes the first n units it meets, one by one, and stops at the next.
- Decision 186 (Q-CBT-36, HQ-16): own fire damages the own HQ. M4.8 already does.
- Decision 187 (Q-CBT-37, COMBAT-28, COMBAT-30): a swapped-in or picked-up weapon arrives unloaded; a new unit's default weapon comes loaded. M4.6 already does.

Deviations:
- A contribution adds the full `contribution_ap`; the pot is full once it holds at least `pot_ap` (the data's 50 and 5 divide exactly).
- Positions stay abstract: `insideRadius`, the occupants of the radius, the distances of the units in a path.
- The pusher count is fixed for one `move` call; the caller calls again when pushers come or go (the push stops while fewer than `min_pushers` push).
- The manager's right to order HQ moves (HQ-10) is an order check of M5; here the HQ moves on its own pool with the push profile.
