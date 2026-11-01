# Session M4.11: Scenario harness

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 11. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-11-scenarios` · **Depends on:** M4.3 to M4.10.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): the session logs of M4.3 to M4.10; R-08 and R-09 in `plan/specs/96-design-risks.md` (tuning notes); `plan/milestones/performance-tests.md` (conventions, P-02).

## Notes
- `bin/scenario.dart` reads a scenario file and the data directory (`--data`, default `../../apps/battle_team/plan/data`). File reading stays in `bin/`.
- Scenarios are YAML files committed in `scenarios/`. The tests run them through `lib/`, not as a process, so coverage counts.
- Besides the readable summary, print one machine-readable line per run (performance-tests conventions).
- Record in the session log the numbers R-08 discusses: time to spend a full pool, sustained speeds, a push's progress per hour.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m4-rules-core.md, Issue 11).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-01 and 2026-11-02), stacked on M4.9 (not merged yet), in `packages/battle_rules`:
- `lib/src/scenario/scenario.dart`: `Scenario.parse(text)`: units on a line (`type`, `team`, optional `section` and `flying`, `position` in metres), `seed`, `weather`, `terrain`, and timed orders (`FireOrder`, `ArtilleryOrder` with optional `spotter` and `radio`, `MoveOrder`, `PushOrder`), sorted by time then file order. Errors are `GameDataException`s with the file name `scenario`.
- `lib/src/scenario/scenario_runner.dart`: `ScenarioRunner(data).run(scenario)` → `ScenarioReport(events, summary, endsAt)` with `text` and `machineLine`. Fire orders go through vision (`canFireAt`), `Armory` (rate of fire, AP, automatic reloads), `HitChance` with the seeded random, `Damage` and `ZeroHp`. Artillery orders check section sight or a scout's report through a radio in relay range, roll, land (scatter) and splash every unit around the impact. Move orders use `MovementCost`; push orders fill the pot from each pusher, then `PushingRules.move` (crushed units die).
- `bin/scenario.dart`: `dart run bin/scenario.dart <file> [--data <dir>]`; reads the six data files (`economy.yaml` from `milestones/`).
- `scenarios/`: `rifle_squad_vs_jeep.yaml`, `artillery_radio_relay.yaml`, `relic_push_crushing.yaml`, with expected summaries checked by `test/src/scenario/scenario_test.dart`.
- `DataReader.mapList` (lists of maps).

Checks: analyze `--fatal-infos` clean, format clean, 417 tests pass, coverage 100 % (1578/1578 lines).

Summaries on the current data (machine lines):
- `scenario="rifle squad vs jeep" seed=1 shots=77 hits=43 damage=215.20 deaths=1 spared=0 crushed=0 ap_used=137.00 ends_at_s=31.9`: four rifles spend their pools on the jeep (180 HP) without destroying it; the jeep's machine gun kills one soldier.
- `scenario="artillery with a radio-relayed target" seed=3 shots=2 hits=1 damage=38.50 deaths=0 spared=0 crushed=0 ap_used=30.00 ends_at_s=10.0`
- `scenario="relic push with crushing" seed=5 shots=0 hits=0 damage=0.00 deaths=2 spared=0 crushed=2 ap_used=120.00 ends_at_s=4320.0`

R-08 numbers (current data, default rate of 1 AP per hour):
- Time to spend a full pool on flat grass: soldier 30 m in 6.0 s, scout 4.3 s, engineer 7.5 s; tank 150 m in 10.7 s; jeep 300 m in 10.7 s; truck 300 m in 13.6 s; artillery 150 m in 12.5 s; radio 150 m in 30 s; guild camp 150 m in 150 s.
- Sustained speed once the pool is spent: infantry 1 m/h on grass, 0.5 m/h in mud; tracked vehicles 5 m/h (2.5 in mud); wheeled vehicles 10 m/h (2.5 in mud).
- A pushed relic: 5 m/h, 120 m a day; its pot pays 50 AP/h on grass, 100 AP/h in mud. The HQ: 5 m/h, 1 AP/h on grass (what it recovers), 2 AP/h in mud.
- Shots per full pool: rifle 15, machine gun 30, anti-tank 3, artillery 2, anti-air 5, explosive charge 1.

Choices:
- Orders run one after another, in time order; orders given at the same time are not interleaved. A hurt unit's AP are read at the later of the hit and its pool's last update.
- Units start with full AP, full HP, base morale and their default weapon loaded; positions are on one line, and the terrain under every unit is the scenario's `terrain`.
- A unit at 0 HP leaves the scenario whatever the outcome; defections and prisoners are counted as `spared`.
- The runner assumes the attacker's section has room for a defector.
