# Session M5.17: Statistics and medals

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 17. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_stats` (`hawkbee1/battle_stats`, new) · **Branch:** `bt/m5-17-stats` · **Depends on:** M5.9.
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `appwrite:dart`.
**Read** (`plan/` is `apps/battle_team/plan/`): decision 143; SOC-22, SOC-24 to SOC-26, SOC-29; COMBAT-35; `plan/data/medals.yaml`; `plan/stack/08-workload-placement.md` (functions, client trust); the session log of M5.9.

## Notes
- New package: the procedure of dc3d §2 with the Very Good CLI MCP `create` (`subcommand: dart_package`, `name: battle_stats`, `output_directory: packages`, `workspace: true`, a description without a colon). Create `hawkbee1/battle_stats` with `gh repo create --public`, add it to the root `workspace:` and melos `format` lists, and apply the new-package pitfalls of dc3d §2 (and of the M4.1 and M3.1 session logs).
- The `daily_stats` function goes in hawkbee `backend/functions/daily_stats/` with a vendored copy of the package (stack decision 8, as `ping` vendors `hawkbee_schema`).
- "Far above the norm" for hit rates: propose the threshold to the user before writing it to `plan/data`.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 17).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-05), stacked on M5.16 (hawkbee #53, not merged yet):
- **`battle_stats`**, a new package (public repository `hawkbee1/battle_stats`, merge commits only, submodule of hawkbee, in the root `workspace:` and melos `format` lists; template CI and dependabot deleted, `test: ^1.31.0`, `mocktail` dropped, `equatable` added):
  - `Stats`: enemy kills and friendly kills by target type, actions by kind (`ActionKind`, the kinds of `medals.yaml`), losses by cause (`Loss`, decision 74), shots by weapon; they add up (`+`, `Stats.sum`) and go to and from JSON.
  - `BattleTally`: reads a log in order and gives the stats of each unit, section and player. It learns whose each unit is from `SectionJoined`, purchases and defections. It also keeps the first-person shots of each battle-day per player and weapon.
  - `MedalRules`: the medals stats reach at the thresholds of `medals.yaml`: one track per target unit type of enemy kills, one per kind of action, one of friendly kills (decision 231). Also their points (SOC-29).
  - `HitRateFlags` (decision 230).
  - `test/fixtures/battle.log`: a committed log of a short battle, written by `tool/write_fixture.dart`, whose stats are checked against values worked out by hand.
- **`battle_protocol`**: the event `SectionJoined` (section, account, team, units with their type), a new tag at the end of version 1, with its committed samples.
- **`battle_host`**: a battle's log starts with an entry of `BattleStarted` and one `SectionJoined` per section, written before its first snapshot. A battle whose start entry cannot be written does not start.
- **`battle_rules`**: `MedalsData.friendlyKillThresholds` and `hitRateFlag`.
- **hawkbee**:
  - `backend/functions/daily_stats`: the function, an adapter around `battle_stats`. `DailyStats` reads a battle's whole log, writes the battle's rows, adds up the war's battles and each player's wars, writes the medals and the flags. The ports are `LogReader` and `StatsStore`, with Appwrite adapters (`AppwriteLogReader`, `AppwriteStatsStore`).
  - `backend/appwrite.config.json`: the tables `stats`, `medals` and `hit_rate_flags`, and the function.
  - `hawkbee_schema`: their IDs.
  - `tool/vendor_packages.dart` replaces `tool/vendor_schema.dart`. It vendors the packages a function's pubspec takes from `vendor/`, with their workspace dependencies, and `plan_data`, the plan's data files as Dart constants.
- **`battle_team`**: decisions 230 (the hit-rate flag) and 231 (friendly-kill medals), owner's answers of 2026-11-05; `medals.yaml` `friendly_kills` and `hit_rate_flag`; SOC-26; Q-SOC-19, open with an assumed answer.

Checks: analyze `--fatal-infos` and format clean; tests pass with 100 % coverage, optimization off: `battle_stats` 20, `battle_host` 270, `battle_protocol` 606, `battle_rules` 629, `daily_stats` 15.

Acceptance criteria:
- The statistics of the committed log fixture match the values worked out by hand: per unit, section and player, enemy and friendly kills by target type, actions by kind, losses, shots, and the first-person shots of each day.
- Each medal tier of the plan is reached at its threshold, and not one below: commander kills, other unit types, actions, friendly kills.

Not run: the function on the local Appwrite. `appwrite-traefik` did not resolve from the container, so neither the tables nor the function are pushed.

Choices:
- Decision 143 says the statistics come from the logs, so the log names every section, its player and its units at the start (`SectionJoined`); a newcomer joining later will be logged the same way. Units bought or turned are followed through `UnitPurchased` and `Attacked`.
- An HQ destroyed counts in the kills, by target type `hq`, but has no kill medal: the kill tracks are by target unit type. A friendly hit is no `hit` action.
- A first-person shot is an `Attacked` in the entry of a `FireAimed` order, or in the entry where a waiting one ends.
- The run is per battle, with the battle and its war in its body: the log does not name its war. Appwrite can schedule an execution with a body. Making the daily execution of each battle is left to the session that creates battles (M5.18), which knows the war.
- Each run reads the whole log and replaces its rows (a row's ID is a hash of its key), so a run made again, or a missed day, gives the same results. Medals are only added.
- The hit-rate mean and deviation are over the players with at least `min_shots` shots, the flagged one included. With few players, 3 deviations cannot be reached: about 11 players are needed.

Questions raised: Q-SOC-19 (does a gold medal come with the bronze and silver of its track; do war and game medals share thresholds), assumed: yes to both.
