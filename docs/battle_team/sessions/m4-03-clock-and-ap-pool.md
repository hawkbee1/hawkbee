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
- [x] The acceptance criteria of the issue (m4-rules-core.md, Issue 3).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-01), stacked on M4.2 (not merged yet), in `packages/battle_rules/lib/src/ap/`:
- `ApPool` (immutable): `max`, `recoveryPerHour`, `value` at `updatedAt`. `apAt(t)` is lazy (stack decision 1); `readyAt(cost, from)` is the time a paid action can start, null above `max`; `payWhenReady(cost, from)` returns that time and the pool after paying (empty after a wait, so no rounding can make it negative); `ApPool.full(...)` for a battle start. The constructor rejects a non-positive `max` or rate and a value outside `[0, max]`. One pool type for units and the HQ.
- `Activity` (sealed): `PaidAction` (sealed: `Shot(weapon)`, `WeaponPickup(rules)`, `RoleActionStart(action, ap)`) and `TimeOnlyAction` (enum: reload, unload, swap, land, take off). `startActivity(unit:, pool:, activity:, now:)` returns `ActivityStarts(at, pool)` or `ActivityRefused(Refusal.notInActions | Refusal.costAboveApMax)`.
- `moveAlong(pool:, start:, lengthM:, apPerM:, speedMps:)` returns `Movement(arrivesAt, pool)`: arrival is `max(length / speed, (length × apPerM − AP at start) / rate)`. The pool recovers on the way, capped at `max`.
- Times are battle times: a `Duration` since the battle started, passed in by the caller.

Checks: analyze `--fatal-infos` clean, format clean, 159 tests pass, coverage 100 % (753/753 lines). Property test: 50 seeds × 200 random steps.

Deviations:
- No `Clock` port yet: every function takes the time as an argument, so nothing in the package reads a clock. The port comes with the first caller that needs "now" (the scenario harness, M4.11, or the host, M5).
- A paid action costing more than the pool's maximum is refused (`costAboveApMax`) instead of waiting forever.
- `RoleActionStart` takes its up-front AP from the caller: M4.10 computes it (the same mapping as the M4.2 check, UNIT-38).
- The spec example holds exactly: from a full pool, an infantry unit covers `ap_max / ap_per_m` metres at full speed, and each further metre takes `ap_per_m / recovery_per_hour` hours.

For the next sessions: M4.4 gives `moveAlong` its `apPerM` (unit `ap_per_m` × terrain and slope multipliers) per path sample and chains the calls; M4.6 builds `Shot` and `WeaponPickup` and the durations of the time-only actions.
