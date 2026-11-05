# Session M5.16: Server-managed sections

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 16. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m5-16-server-sections` · **Depends on:** M5.11.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/80-ai-and-automation.md`; `plan/data/battle.yaml` `server_managed`; decisions 159, 160, 163 to 166, 196.

## Notes
- The check is a timer per unit every `check_interval_s`, not a roll on entering range (AI-07).
- Decision 159: the purpose of these sections stays out of the code's comments too.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 16).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-05), stacked on decisions 223 to 227 (hawkbee #52, not merged yet):
- **`battle_host`**:
  - `SectionSetup.serverManaged` and `SectionState.serverManaged`: the server runs the section. No event, refusal or wire value shows it.
  - `ServerSections` (`lib/src/orders/server_sections.dart`):
    - The fire check: the timer `ServerCheck`, one per unit, every `check_interval_s`. When it is due, a deployed unit that sees an enemy unit within its weapon's range draws `fire_chance` with the battle's random. If the draw passes, it gives a `Fire` order at the nearest such enemy, with the origin `server`, carried out by the command handler like any order.
    - A listener (Observer): a unit bought by such a section, or turned into it, gets its own check. The check of a unit that left the section or died is not scheduled again. Checks stop once its team is eliminated or the battle has ended.
  - `CommandHandler`: `_aim` holds a shot's checks (weapon, target, flying reach, range, sight), which `Fire` and the fire check (`shotDistance`) share.
  - `Battle.onEntry` replaces `onEvents`: a timer's entry can carry a command, the fire check's order. `replay` makes these entries again from the timers, with their sequence numbers, and checks them against the log.
  - The snapshot keeps the flag and the `ServerCheck` timers.
- **`battle_rules`**: `BattleSettings.serverManaged` (`server_managed` of `battle.yaml`, also in `toData`), checked: a chance from 0 to 1, an interval above 0. `ServerFireCheck`: the interval and the draw.
- **`battle_team`**: Q-AI-10 and Q-AI-11, open with assumed answers.

Checks: analyze `--fatal-infos` and format clean; tests pass with 100 % coverage, optimization off and on: `battle_host` 268 (and the opt-in Appwrite suite, skipped), `battle_rules` 626.

Acceptance criteria:
- The fire check runs every 30 minutes per unit. The battle's random is untouched when an enemy comes into range, and at a check that sees no enemy; it draws at the next check that sees one.
- A seeded run (seed 11, 3 hours, 18 checks) fires 8 shots, each at the nearest enemy it can fire at, each an `Attacked`.
- Every order the server gives its section is logged with the origin `server`: the fire checks' and the orders sent through `SimulationHost.submit`. A replay gives the same battle, and a host stopped between checks recovers the same snapshot and log as one that never stopped.

Choices:
- A check draws only when its unit sees an enemy in range, so a check with no enemy changes nothing in the battle's random.
- The fire check's order goes into the log with its command, from the timer. Replay makes it again from the timer, so it is never carried out twice.
- A unit in storage, carried or unarmed is not checked for a target, and keeps its check.
- The check of a unit stops once it leaves the section, dies, its team is eliminated or the battle ends.

Questions raised: Q-AI-10 (which enemy a fire check aims at) and Q-AI-11 (when a unit's first check is), with assumed answers.
