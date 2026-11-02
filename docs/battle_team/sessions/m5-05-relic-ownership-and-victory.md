# Session M5.5: Relic ownership and victory

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 5. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m5-05-victory` · **Depends on:** M5.4.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/30-special-units-and-victory.md` §2 to §5; `plan/specs/50-hq.md` §4, §6; `plan/data/battle.yaml` `victory`, `capture`; decisions 45, 46c, 99, 100, 116; the M4.10 session log.

## Notes
- The victory timer is state with a start time, not a countdown ticked every second: "held since t" is enough to show the countdown and to detect the win at t + `hold_s`.
- Owner changes and eliminations are returned as events (Observer); the host logs them and M6 sends the alert.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m5-simulation-host.md, Issue 5).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02) on `main` (M5.4 merged), in `packages/battle_rules`:
- `lib/src/victory/victory.dart`: `VictoryState(relicOwners, teams, hold, winner)`; `RelicHold(team, since, winsAt)` with `remainingAt` for the visible countdown; `VictoryRules(victory)` with `start(relics:, teams:)`, `captured`, `relicLost`, `hqLost(cause:)`, `at(now)` and `relicVictoryPossible`, each returning the new state and its events (Observer): `RelicOwnerChanged` (with the previous owner to alert), `RelicLeftBattle`, `HoldStarted`, `HoldReset`, `TeamEliminated`, `BattleWon(team, kind)`.
- `StorageRules.atElimination`: an eliminated team's units on the field are stored, its guild camps included; stored units and prisoners stay.

Decision by the owner (2026-11-02), recorded in battle_team on `bt/m5-05-victory`:
- Decision 208: an eliminated team's guild camp is stored with its units, the one exception to "never stored".

Checks: analyze `--fatal-infos` clean, format clean, 563 tests pass, coverage 100 % (test optimization off).

Choices:
- `start` refuses a map whose relics let two teams hold `relics_to_hold` at once (2 × `relics_to_hold` or more): RELIC-17 says no tie is possible. M5.8 should check it when it validates a map.
- A change at or after the hold's `winsAt` ends the battle on the hold first: the host calls `at` at `winsAt`. Every change once the battle is won throws.
- An eliminated team's relics keep their owner until another team captures them (RELIC-11). Its hold resets and it never holds again.
- A capture by a relic's owner changes nothing and sends no alert.
- RELIC-27 needs no code: every weapon's multiplier on `relic` is 0 (M4.8); a test checks it on the plan data.
