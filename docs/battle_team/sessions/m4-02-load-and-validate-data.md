# Session M4.2: Load and validate the data files

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 2. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-02-data` · **Depends on:** M4.1.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): every file of `plan/data/`, comments included; the rules the issue lists (specs 10, 20, 70).

## Notes
- Add `yaml`. The public API takes the **text** of each file and returns typed, immutable models; it never opens a file (stack decision 7). Tests read the real files through the M4.1 helper.
- Models cover units, weapons, the damage table, hit chance, aim, terrain and the slope rows (classes and the `flying`, `sail` and `push` profiles), battle settings (with `ap`, `capture`, `push`, `hq`), economy and medals. Keep each file's `version`.
- The checks are the issue's list. They include the latest decisions: the `push` column and slope row (175), `hit_box_m` for every unit and the HQ, `projectile_speed_mps` for every flying shot (183), base speed caps (174, 178).
- The test on the real files guards against drift. If it fails after a data change, fix the parser or ask the user. Never change the data to pass.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m4-rules-core.md, Issue 2).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-01), in `packages/battle_rules/lib/src/data/`:
- `GameData.parse(units:, combat:, terrain:, battle:, economy:, medals:)` takes the text of the six files, parses each and runs the checks between them. Its constructor is private, so a `GameData` is always checked. Flyweight (stack decision 7).
- One immutable model per file, each with `XData.parse(text)` (types and required keys only): `UnitsData` (`UnitType`, `UnitStats`, `WeaponLoadout`, `UnitRole`, `ObserveRole`, `FlightTimes`, `Progression`, `CommanderLevels`, `SectionSize`, `EvolutionTrees`), `CombatData` (`WeaponType`, `multipliers`, `HitChanceRules`, `AimRules`, `MoraleRules`, `ZeroHpRules`, `RoleActions`, `PushRules`, ...), `TerrainData` (`SlopeRule`, `TerrainType` with `apMultiplier` where null is impassable, `TerrainObject` with `Construction`, `VisionRules`, `movementModes`), `BattleSettings` (`ApSettings`, `CaptureSettings`, `HqSettings`, ...), `EconomyData`, `MedalsData`. Every key of the files is modelled; each keeps its file's `version`. Enums: `UnitAction` (the six actions), `Capability` (`flying`, `sail`), `MovementProfile` (`flying`, `sail`, `push`).
- `GameDataException(file, key, value, problem)`: every parse and check error names the file, the dotted key path and the value.
- `DataReader` (internal): typed reads of a YAML map; `game_data_validation.dart` (internal): the checks of the issue, in its order.
- Test helpers: `test/helpers/plan_data.dart` now has `readPlanFile`, `readPlanData`, `readPlanEconomy` and `parsePlanData()` (the real data, for later sessions); `test/helpers/fixtures.dart` has `readFixture(file, {old: new})`, `parseFixtures(...)` and the `throwsDataError` matcher. `test/fixtures/` holds a small valid set of the six files; each validation test breaks one value.

Checks: analyze `--fatal-infos` clean, format clean, 131 tests pass, coverage 100 % (685/685 lines). `dart pub deps`: `yaml` added, no `flutter`.

Questions raised and decided by the owner (2026-11-01):
- `economy.yaml` is in `plan/milestones/`, not `plan/data/` (moved in battle_team commit 0196133). Owner: read it from there. `readPlanEconomy()` does; the specs still cite `data/economy.yaml`.
- "`ap_max` is 30" would put a game number in `lib/`. Owner: add one value to the data. battle_team PR on `bt/m4-02-data`: `battle.yaml` `ap.max: 30` (version 8), the `units.yaml` comment and the issue text point to it. The check is: every unit's `ap_max` equals `ap.max`.

Deviations:
- Up-front AP per action (UNIT-38), derived from COMBAT-07/08: capture = `battle.yaml` `capture.contribution_ap`; push = `combat.yaml` `push.contribution_ap`; repair = `actions.repair.ap`; heal = the unit's `role.heal_ap`; observe = `role.observe.ap`; build = the dearest construction in `role.build` (`terrain.yaml` objects). A unit that lists heal, observe or build without those values fails.
- "In increasing order" for `section_xp` is read as strictly increasing.
- One check beyond the issue's list, from the architecture review: a unit's `movement_class` must be one of `terrain.yaml` `movement_classes` (MAP-15), so a typo cannot make a unit impassable everywhere.
- Tests on rules the issue's "Rules" line does not list but whose checks it asks for: COMBAT-01 (`ap_max`), COMBAT-03 (`ap_per_m`), COMBAT-14 (hit box, projectile speed), COMBAT-15 (size factor), HQ-22 (HQ hit box). The speed caps cite decisions 174, 178 (no rule ID).
- The flying and sailing speed caps name the `jeep` and the `tank` in `lib/`, as decision 174 does.

For the next sessions:
- Real data in tests: `parsePlanData()` from `test/helpers/plan_data.dart`. Synthetic cases: `parseFixtures(units: {'old text': 'new text'})`; each key must occur exactly once in the fixture.
- Weapons mirror the file: `indirectFire`, `neverMisses`, nullable `baseAccuracy` and `projectileSpeedMps`. The architecture review suggested a sealed fire mode (direct, indirect, never misses); M4.6 or M4.7 can introduce it with the hit chance, and check that every weapon that can miss has a `base_accuracy`.
- Not checked yet (not in the issue): `zero_hp.never_spared` names, `objects.*.built_by`, `battle.yaml` `weather.states` against `terrain.yaml` `weather`, medal `kills` keys.
