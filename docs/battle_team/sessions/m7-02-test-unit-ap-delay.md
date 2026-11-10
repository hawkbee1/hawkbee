# Session M7.2: The test unit and the AP recovery delay

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 2. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `packages/battle_rules`, `packages/battle_host`, `apps/battle_team` (`plan/data` only) · **Branch:** `bt/m7-02-test-unit` · **Depends on:** nothing in M7 (runs beside M7.1); the plan PRs for `battle.yaml` (`agent-workflow.md` §6, last paragraph).
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): decisions 167, 168, 172, 238, 239 in `plan/specs/00-overview.md`; COMBAT-01, COMBAT-02, COMBAT-06, MAP-20, UNIT-38, UNIT-44, Q-UNIT-26; `plan/data/battle.yaml` (`ap:`), `plan/data/units.yaml` (`common_stats`, the roster entries, their comments); `plan/stack/01-simulation-host.md` (lazy AP); the session logs of M4.2 (data loading and validation), M4.3 (AP pool), M5.12 (buying), M5.19 (`tool/playtest.dart`).

## What exists
- `battle_rules` loads `battle.yaml` and `units.yaml` (M4.2) and validates them; the AP pool (M4.3) recovers with `recovery_per_hour`; the host's `SectionOrders._buy` refuses unknown types; battles carry settings from their Appwrite row (M5.18).
- `plan/data/battle.yaml` **already** says `recovery_delay_s: 3600` (the plan PR renamed it): the code does not read it yet. A host started on the merged plan fails until this session lands.
- `battle_host/tool/playtest.dart` creates the playtest accounts, war and battle, and plays blue's opening.

## Steps
1. **Find every reader of `recovery_per_hour`**: `grep -rn recovery_per_hour packages/battle_rules packages/battle_host packages/battle_protocol packages/hawkbee_schema` (also test fixtures and `ApView.perHour` in the protocol — read M6.2's log before touching the protocol; if the message must change, follow M6's conventions: samples, both encodings, sizes).
2. **Rename to a delay** in `battle_rules`: the loader reads `ap.recovery_delay_s` (an integer ≥ 1), validation rejects the old key with a clear message, the AP pool recovers `seconds / delay` (stack decision 1's formula). Keep AP math in one place.
3. **Battle setting override**: the battle's settings (the row's settings map the host already loads) may hold `ap.recovery_delay_s`; the effective value is the row's, else the file's. Add `test_units: false` as a setting the same way.
4. **The test unit** in `plan/data/units.yaml`: id `test_unit`, `ap_max: 10000`, the values of Q-UNIT-26 (every action of UNIT-38, observe, heal, build/repair, radio, best sight and range of the roster, infantry movement class, price 0). Mind `common_stats`: every stat listed there is required. The validator's rule "every `ap_max` equals `ap.max`" gets its exception for `test_unit` (decision 239); nothing else relaxes.
5. **Host guard**: buying `test_unit` is refused with a host refusal code unless the battle's `test_units` setting is on (`SectionOrders._buy`, `refusal.dart`).
6. **Playtest tool**: `tool/playtest.dart` writes the battle with `test_units: true` and `ap.recovery_delay_s: 1` (a flag `--fast` on by default for the playtest; say so in `docs/battle_team/playtest.md`), and blue's opening buys one `test_unit`.
7. **Gates** per package (§4): `battle_rules` and `battle_host` 100 % (MCP `test` tool, `dart: true`), analyze, format. The data change has no code gate but the validator tests load the real files.
8. **Finish** (§5): logs, README row, PRs: `battle_rules`, `battle_host`, then `battle_team` (data only) and hawkbee.

## Tests to write
- `COMBAT-02 recovers one AP per recovery_delay_s` and `… the battle setting overrides the file`.
- `COMBAT-06 at 0 AP a unit moves at the recovery rate` updated to the delay.
- `decision 239 test_unit ap_max 10000 passes validation` and `decision 167 another unit with ap_max != ap.max fails validation`.
- `UNIT-44 buying test_unit is refused without test_units` and `… accepted with test_units`.
- The real `plan/data` files load (existing loader tests keep passing).

## Stop and ask when
- A protocol message (`ApView.perHour`) would change: the owner decides whether M7.2 may touch `battle_protocol` or M7.3+ carries it.
- Q-UNIT-26's assumed values do not fit the data model (e.g. one weapon slot): write the smallest consistent choice in the log and in Q-UNIT-26, as an assumption.

## Pitfalls
- Tests on real values read `../../apps/battle_team/plan/data/` relative to the package (§2): the submodule must be on `bt/m7-plan` or later to see `recovery_delay_s`.
- `battle_host` snapshots (M5.15) may serialise the setting: a recovered battle must keep its override; add that case to the recovery test.
- Never change `plan/specs` to make code pass (§2); the data change here is the plan's, not yours.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 2).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log

Branch `bt/m7-02-test-unit` in hawkbee, `battle_rules`, `battle_host`, `battle_backend` and `battle_team` (plan data only), all from `main`; hawkbee also merges `origin/bt/playtest-phone`, which holds the M7 session files `main` lacks. Independent of M7.1 (#71).

**Premise corrected, owner decided (2026-11-10).** The session said the battle row holds a settings map the host loads. It does not: `BattleRow` had none and `BattlePlacement.setupOf` used `battle.yaml` (M5.19 log). The owner chose a settings column on `bt_battles`. So this session also touches `hawkbee_schema`, `battle_backend` and `backend/` (beyond the packages listed above).

**Built**
- `battle_rules`
  - `ApPool` takes `recoveryDelayS` (int, at least 1) and holds all the AP recovery math: `apAt`, `recoveredIn(elapsed)`, `timeToRecover(ap)`. `moveAlong` uses the last two instead of its own copy of the formula.
  - `ApSettings.recoveryDelayS` reads `ap.recovery_delay_s` (an integer); `BattleSettings.parse` rejects `ap.recovery_per_hour` with a message naming the new key. `BattleSettings.testUnits` reads the new required top-level `test_units`.
  - `BattleSettings.overriddenBy(overrides)` lays a map in the shape of `battle.yaml` over the settings (a key that is no setting, a non-map where the file has one, or a wrong type throws a `GameDataException`); `GameData.settingsWith(overrides)` does it and runs `checkSettings`. `validateSettings` and `validateGameData` check the delay is at least 1; `_checkApMax` exempts `testUnitId` (`'test_unit'`, exported) and nothing else.
- `battle_host`
  - Pools take the delay from the battle's settings; `SectionOrders.buyUnit` refuses `test_unit` with the host refusal `test_units_off` unless `battle.settings.testUnits`, before any other purchase rule.
  - `BattlePlacement.setupOf` plays the battle with `definitions.settingsWith(row.settings)`; refused settings fail the start like any bad row (reported to the error reporter, retried at the next look).
  - Snapshots: pools write `recoveryDelayS`, so `snapshotVersion` is 2 (a host does not read version-1 snapshots); the settings in a snapshot already come back through `toData`, and a recovered battle keeps its override (tested).
  - `ApView.perHour` is unchanged: `SectionViews` sends `3600 / recoveryDelayS`, so the protocol, `battle_client` and the app did not change. M7.3+ may carry the delay itself if a client needs it.
  - `tool/playtest.dart`: `--fast` is on by default, `--no-fast` plays the rules as written. Fast writes the battle with `{ap: {recovery_delay_s: 1}, test_units: true}` and blue's opening also buys a `test_unit`.
- `hawkbee_schema`: `BattleRow.settings` (overrides only; empty for a battle that plays with the file's), a nullable text column `settings` in `bt_battles` (`backend/appwrite.config.json`).
- `battle_backend`: `Wars.plan(settings:)` checks the overrides with `settingsWith` and refuses bad ones (`bad_settings`, 400); `objectOf` reads an object field of a function body; the `create_battle` function passes `settings` through. The vendored copies in `backend/functions/*/vendor` are regenerated (`tool/vendor_packages.dart`).
- Plan data (`battle_team`): `test_unit` in `units.yaml`, price 0 in `milestones/economy.yaml`, `test_units: false` in `battle.yaml`. Two stale `recovery_per_hour` mentions (a comment in `combat.yaml`, a line of `specs/20-units-and-progression.md`) renamed; no rule changed. No `version` bumped (the plan PR that renamed the key did not either).

**The test unit (Q-UNIT-26, still an assumption, written in the question).** A soldier's stats with the scout's 300 m sight, `ap_max` 10,000, `foot`. One weapon slot: the rifle by default, the six weapon types allowed. All six actions, with the engineer's build list and repair, the scout's observe, the medic's heal (20 HP for 10 AP) and the radio's relay (150 m, all sections of the team). It does not earn money by healing.

**Not verified live.** The container reaches no local Appwrite, so `tool/playtest.dart` was not run, and the owner has to run `appwrite push tables` (the `settings` column) before the first fast playtest; a host with a version-1 snapshot folder (`build/playtest`) needs it cleared. The `create_battle` function test runs `respond` against in-memory rows, so the deployed function is not exercised with settings either; redeploy it (`appwrite push function`) to use them.

**Numbers.** `battle_rules` 648 tests, `battle_host` 416, `hawkbee_schema` 12, `battle_backend` 37 (1 live suite skipped), `create_battle` 4, `create_war`, `end_battle`, `guild_requests`, `daily_stats`, `battle_host` and `api_keys` green (`ping` only vendors `hawkbee_schema`; not run); 100 % line coverage in the four packages, `dart analyze --fatal-infos` and `dart format` clean. Rules covered (test file in each package's `test/`): COMBAT-02 `src/ap/ap_pool_test.dart`, `src/data/battle_settings_test.dart`, `src/data/game_data_test.dart`; COMBAT-06 `src/ap/movement_test.dart`; UNIT-44 and decisions 167, 238, 239 `src/data/game_data_test.dart`; UNIT-44 `battle_host` `src/orders/section_orders_test.dart`; decision 238 `battle_host` `src/hosting/battle_placement_test.dart`, `src/stream/section_views_test.dart`.

**For later.** The roster now has an 11th unit type everywhere the real `units.yaml` is read; tests that count unit types on real data would see it. A public war must never plan a battle with `test_units`: `Wars.plan` checks the values, not who plans (admins only); the real guard is "admins plan battles".

