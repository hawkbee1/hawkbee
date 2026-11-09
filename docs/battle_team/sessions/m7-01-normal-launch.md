# Session M7.1: Normal launch, from the playtest

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 1. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `apps/battle_team` · **Branch:** `bt/m7-01-normal-launch` · **Depends on:** the playtest (merged); the plan PRs (see `agent-workflow.md` §6, last paragraph).
**Skills:** `vgv-ai-flutter-plugin:layered-architecture`, `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:internationalization`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `agent-workflow.md` §6; `docs/battle_team/playtest.md`; `plan/stack/04-client-and-rendering.md`; `plan/stack/07-engineering-principles.md`; the body of hawkbee1/battle_team#37 (the playtest PR); the whole of `apps/battle_team/lib/` and `test/` before changing anything.

## What exists
- `lib/playtest/`: `PlaytestCubit` (+ state) on `battle_client`; `PlaytestWorld` (interface), `BattleWorld` (flutter_scene, `coverage:ignore-file`), `TopDownCamera`, `battle_space.dart`; `PlaytestApp`, `PlaytestPage`, `PlaytestView`; `PlaytestSettings.fromEnvironment()` (sign-in and battle from `env/playtest.json`); `trust_host_*.dart`.
- `lib/game/` (Flame: unicorn, counter, audio), `lib/loading/`, `lib/title/`, `lib/backend_status/`, `lib/app/`: the VGV Flame template scaffold. `test/` mirrors all of it; `test/helpers/` has `FakeWorld`, `fake_host.dart`, `pump_app.dart`, `mocks.dart`.
- One ARB file (`app_en.arb`). `main_development/staging/production.dart` boot the Flame app; `main_playtest.dart` boots `PlaytestApp`.

## Steps
1. **Branch** from `bt/m7-plan` in `apps/battle_team` and in hawkbee (§6).
2. **Move the playtest into a `battle` feature**, by rename first, behaviour second: `lib/playtest/` → `lib/battle/` (`cubit/battle_cubit.dart`, `view/battle_page.dart`, `view/battle_view.dart`, `world/`), tests renamed with it. Run the suite: it must still pass before you change anything else.
3. **Layer it**: a `BattleRepository` (`lib/battle/data/` or a top-level `lib/repositories/` — pick one and say why in the log) wraps `BattleClient` creation, sign-in credential, and the streams the cubit consumes; the cubit depends on the repository, never on `BattleClient` directly. The rendering interface (`PlaytestWorld` → `BattleWorld` interface, GPU class renamed `SceneBattleWorld`) stays the 3D seam; write "Strategy" in its doc comment.
4. **Remove Flame**: delete `lib/game/`, `lib/loading/` (unless the new flow needs a loading screen; then keep only the widget, no Flame preload), their tests, `test/helpers/test_game.dart`, the `flame*` and `audioplayers` dependencies, `assets/audio/` and `assets/images/` if nothing uses them, and the Flame-specific `pubspec.yaml` description. Keep `backend_status` and `title` only if the new flow shows them.
5. **Normal launch**: `App` (lib/app) routes `title` → battle. `main_development/staging/production.dart` bootstrap the same `App` with settings from `env/` (for now the same `PlaytestSettings` keys, read by `fromEnvironment`; M7.12 replaces the sign-in). `main_playtest.dart` keeps `trustHost` + `trustSelfSigned` and boots the same `App`.
6. **Map attribution** (Q-MAP-22): a "Credits" entry on the battle screen showing `map.yaml`'s attribution text (the asset already ships; find where the playtest shows it and keep it reachable from the normal flow).
7. **Localization**: add `lib/l10n/arb/app_fr.arb` with every key of `app_en.arb`; every string you add or move goes through `context.l10n`.
8. **Gates** (§4, §6): tests via the MCP `test` tool (`optimization: false`), 100 % outside the ignores, analyze `--fatal-infos`, format.
9. **Show it**: a web build in headless Chromium if available (as #37 did) or the exact launch steps for the owner; the screenshot goes in the log.
10. **Finish** (§5): session log, README row, PRs (battle_team first, then hawkbee with the pointer), `Stacked on #N` if the plan PRs are still open.

## Tests to write or keep
- `BattleCubit`: the playtest cubit's tests, now against a mocked `BattleRepository` (bloc_test).
- `BattleRepository`: sign-in → credential → `BattleClient` wiring, with a fake transport from `test/helpers/fake_host.dart`.
- `App` routing: title → battle; `main_*` entry points are excluded from coverage only if they are one-liners.
- Decision 237: a view with an out-of-sight unit is not drawn by `FakeWorld` (keep the playtest's test; rename it with the decision).
- Credits entry shows the attribution text.

## Stop and ask when
- Removing a template screen would remove behaviour the owner may want (sound, the title animation): ask before deleting anything that is not Flame-only.
- The `env/` keys are not enough for the normal flavors (e.g. which battle to open): propose the smallest key set and ask.

## Pitfalls
- Rename first and run the tests before refactoring: a move + refactor in one step hides regressions.
- `material_ui` localization delegates must stay in `MaterialApp`, or the French locale breaks.
- `coverage:ignore-file` is only for the GPU class; moving code into it to pass coverage is not allowed.
- `.vscode` lives only at the hawkbee root; update `launch.json` there if the entry points change.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 1).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log
