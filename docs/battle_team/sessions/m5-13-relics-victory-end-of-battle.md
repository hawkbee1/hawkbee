# Session M5.13: Relics, victory and the end of a battle

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 13. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m5-13-relics-end` · **Depends on:** M5.5, M5.11.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): the session logs of M5.5 and M5.11; `plan/specs/30-special-units-and-victory.md`; `plan/specs/50-hq.md` §3, §4; decision 138.

## Notes
- The end-of-battle event is what `end_battle` (M5.18) reads: give it the winner, the eliminations in order and the time, and version it with the log format (M5.9).
- `VictoryRules` (M5.5) returns the events; the host applies `StorageRules.atElimination` to an eliminated team's units, and the order chain refuses that team's orders: it is out of the battle (HQ-18).

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 13).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-04), stacked on M5.12 (hawkbee #48, not merged yet), in `packages/battle_host`:
- `lib/src/orders/relics.dart`: `Relics`, a `BattleListener`, handles:
  - pushes: started by enough pushers, moved along the push path, crushing on arrival (RELIC-24, RELIC-25), falls from an island that kill the units under the relic and empty its pot (RELIC-22, decision 176), a stuck relic (RELIC-28);
  - captures: the 30-minute timer, the owner change and its alert (RELIC-05, RELIC-10 to RELIC-12), a capture lost when an enemy enters the radius (RELIC-08);
  - victory: the hold and its timer (RELIC-14 to RELIC-18), eliminations that store the team's units on the field (HQ-18 to HQ-20, decision 208), `bridgeDestroyed` for M5.14 (RELIC-26, HQ-23), and `BattleEnded`.
- New timers: `CaptureEnds`, `RelicArrives`, `HoldEnds`.
- State: `BattleState.victory` (the rules core's `VictoryState`) and `eliminated`, in order; a relic's pushers and `RelicPush`; `TeamState.out`.
- `CommandHandler.crush` and `_dies`: one way to die for shots, crushes and falls, with the weapon drop and the commander's resurrection. `alongOf` measures a path cell by cell.
- An HQ moved over an island's edge kills the units it lands on (HQ-48), which do not block it (HQ-12).
- `Rewards`: capture XP shared by the AP put in (UNIT-07, decision 179); victory XP for every unit of the winning team (UNIT-11).
- The order chain refuses every order once the battle has ended (`battle_over`). A destroyed HQ is no longer a target.

Plan (`battle_team`): Q-REL-15, open with an assumed answer.

Checks: analyze `--fatal-infos` and format clean; 157 tests pass with 100 % coverage.

For `end_battle` (M5.18): `BattleEnded` carries the winner, how it won and the eliminated teams in order. Its log entry gives the time, and the log format carries the version (M5.9).

Choices:
- The pushers are the units that put AP into the pot since it was last empty and are still on the field (assumed, Q-REL-15).
- A push is planned when it starts: the relic stands where it will stop, like a unit's move. The units then on its path, met where the relic enters their cell, are crushed when it arrives. A relic stops on the last whole cell it reaches.
- A path measures each cell step with its own samples: a step gives two half-cell samples, a fall none. The M5.11 HQ move counted one sample per step; it is fixed.
- Listeners hear the events of those before them: `Relics`, then `Rewards`, then `StorageLocks`. An eliminated team's sections are not locked.
- The valley's river is impassable for a push, so the tests push along row 0 and over the edge of `sky`.
