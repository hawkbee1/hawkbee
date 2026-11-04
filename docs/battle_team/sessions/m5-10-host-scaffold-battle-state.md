# Session M5.10: Host scaffold, battle state and clock

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 10. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`, new) · **Branch:** `bt/m5-10-host` · **Depends on:** M5.1, M5.8, M5.9.
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/01-simulation-host.md`; `plan/stack/06-accounts-and-services.md` (Sentry); `plan/stack/07-engineering-principles.md`; COMBAT-01, COMBAT-02, UNIT-31; the "Deferred" notes of the M3.6 and M4.11 session logs.

## Notes
- New package: the procedure of dc3d §2 with the Very Good CLI MCP `create` (`subcommand: dart_cli`, `name: battle_host`, `output_directory: packages`, `workspace: true`, a description without a colon). Create `hawkbee1/battle_host` with `gh repo create --public`, add it to the root `workspace:` and melos `format` lists, and apply the new-package pitfalls of dc3d §2 (and of the M4.1 and M3.1 session logs).
- The host's core holds no I/O: it takes a `Clock`, a `SeededRandom` and the ports. Adapters live in `lib/src/adapters/` and are the only code that touches files, Appwrite or Sentry.
- Lazy state: a unit's AP and morale are read at time t from their last update and rates; the tick never touches idle units.
- Sentry: check the `sentry` package API with context7. The DSN comes from the environment, never from the code.
- Separate the shared definitions from each battle's settings (deferred from M4.11): `GameData` now fuses them.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m5-simulation-host.md, Issue 10).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02), stacked on M5.9 (hawkbee #45, not merged yet):
- **New package `packages/battle_host`** (public repository `hawkbee1/battle_host`, merge commits only, submodule of hawkbee, in the root `workspace:` and melos `format` lists; template CI, dependabot, self-update, sample command and build_runner removed; dependencies `battle_rules`, `battle_map`, `battle_pathfinding`, `args`, `mason_logger`, `sentry` 10.3, licences checked):
  - `lib/src/ports/`: `Clock` and `ManualClock`, `ErrorReporter`, `MapSource`.
  - `lib/src/core/`: `TimerQueue<T>` (seconds to days, ties in scheduling order); `BattleSetup` (teams, sections, units with type, tree and XP, the battle's own settings, seed); `BattleState` (units with location, lazy AP pool, health and morale; sections with money, XP and lock; teams with their HQ; relics with owner and pots); `Battle.start` and `advanceTo`, `apOf`, `hqApOf`, `schedule`, `change`; the sealed `BattleTimer` with its first variant `SectionUnlocks` (HQ-35); `MapLibrary` and `SharedMap` (Flyweight); `SimulationHost` (several battles, one clock, failures reported and isolated).
  - `lib/src/adapters/`: `SystemClock`, `SentryErrorReporter`, `LoggerErrorReporter`, `DirectoryMapSource`, `readPlan`.
  - `lib/src/cli/` and `bin/battle_host.dart`: `battle_host run --plan --maps --map [--days] [--seed] [--teams]`.
- **`battle_pathfinding`** (deferred from M3.6): `GroundGrid` holds the ground arrays (heights, blocking objects, effective terrain per mode) and the working arrays of a search, shared by every `GroundSearch.on(grid, ...)`; a search keeps only its cost memo, flat-ground tables and block prices. `GroundGrid.apply` updates every search on it. `GroundSearch(map:, ...)` still builds a grid of its own.
- **`battle_rules`** (deferred from M4.11): `GameData.checkSettings(settings)` checks one battle's own settings against the shared definitions (AP maximum, up-front AP, teams, battle start); `GameData.battle` holds the defaults of `battle.yaml`.

Checks: analyze `--fatal-infos` and format clean in the three packages; tests pass with 100 % coverage (test optimization off): `battle_host` 37, `battle_pathfinding` 124, `battle_rules` 611; `battle_map` still passes (45). The AOT executable runs a simulated day on `battle_map`'s valley map (built with `build_map`) in 3 ms.

Measured (10 m synthetic map, 5 million cells, AOT; `battle_pathfinding/benchmark_results/README.md`):
- Six movers (foot, tracked, wheeled, amphibious, boat, push) with one fast path each: about **104 MB** on one shared grid, about **355 MB** with a grid each.
- P-01, 2 km paths: median 23 to 24 ms (15 ms before), within the 50 ms target. Stand bits for diagonal steps are now computed from small per-terrain tables instead of a stored array per mover.

Choices:
- Timers fire at their exact battle time, not at the next whole second, so a replay is exact. With no orders nothing needs the 1 Hz tick: `advanceTo` fires the timers due and skips the rest. Combat and vision join the tick with the orders (M5.11).
- A battle that throws is stopped and reported; the other battles go on. Restarting it from its snapshot is M5.15's.
- One `GroundGrid` serves every battle of a map while their worlds are the map's. Once a battle changes its world (M5.14), it needs a grid of its own (copy on write).
- `terrain.yaml` has no flag for the road construction, so the host names `road_segment` and refuses to load when the data has no such object. The flying altitude limit is the map's highest point (islands included) plus `flying_max_above_highest_terrain_m` (decision 142).
- Relics are `relic-1`, `relic-2`… in the map's order.
- Sentry goes through a `Hub` of the adapter's own, not the global `Sentry`; a report carries the battle ID as a tag and no personal data. The DSN comes from `SENTRY_DSN`.
- Unit positions are not in the state yet: every unit starts in storage (decision 212); positions come with deployment and moves (M5.11, M5.12).
- The CLI gives each team one new section, its commander and the starting money (UNIT-41).

No rule question in this session.
