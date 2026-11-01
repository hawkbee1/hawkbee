# Session M3.1: `battle_pathfinding`: project scaffold

**Issue:** `apps/battle_team/plan/milestones/m3-pathfinding.md`, Issue 1. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_pathfinding` (`hawkbee1/battle_pathfinding`) · **Branch:** `bt/m3-01-scaffold` · **Depends on:** M4.1 (both edit the hawkbee root files).
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/07-engineering-principles.md` (package layout); the M4.1 session log (pitfalls met while scaffolding).

## Notes
- Very Good CLI MCP `create`: `subcommand: dart_package`, `name: battle_pathfinding`, `output_directory: packages`, `workspace: true`, a description without a colon. Add the package to the root `workspace:` list and to the melos `format` list.
- The repository `hawkbee1/battle_pathfinding` already exists and is empty (created by the owner on 2026-11-01). In the procedure of dc3d §2 step 2, replace `gh repo create` with `git remote add origin https://github.com/hawkbee1/battle_pathfinding.git` and `git push -u origin main`, then run the `gh repo edit` line (merge commits only), `git submodule add` and `git submodule absorbgitdirs`.
- Apply the new-package pitfalls of dc3d §2: delete `.github/workflows/` and `.github/dependabot.yaml`, fix the `test` constraint, write Dart 3.13 constructors, delete the generated `.vscode/`.
- `README.md`: what the package is (pure Dart, no I/O in `lib/`), the "Part of hawkbee" section, how to run the tests, and where its specification is (`apps/battle_team/plan/milestones/m3-pathfinding.md`).
- M3 tests use fixture maps and an injected cost: this package never reads `plan/data`.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m3-pathfinding.md, Issue 1).
- [x] The package is in the root `workspace:` list, the melos `format` list and `.gitmodules`.
- [x] `dart pub deps` shows no `flutter`.
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-01):
- `packages/battle_pathfinding`: Very Good CLI `dart_package`, own public repository `hawkbee1/battle_pathfinding` (merge commits only), submodule of hawkbee, in the root `workspace:` and melos `format` lists. `.github/workflows/` and `dependabot.yaml` deleted, `test: ^1.31.0`. The template generated no `.vscode/` and already writes `const new()`.
- `lib/`: only the template placeholder `BattlePathfinding`, with its placeholder test. M3.2 replaces it with the navigation model.
- README: what the package is (injected movement cost, no game data), "Part of hawkbee", the specification paths, how to run the tests.

Checks: analyze `--fatal-infos` clean, format clean, 1 test passes, coverage 100 % (1/1 line in `lib/`). `dart pub deps` for `battle_pathfinding`: `mocktail`, `test`, `very_good_analysis` only, no `flutter`.

Deviations: none. Questions raised: none.

Pitfall: the MCP `create` tool reports a failure because its `dart pub get` runs before the package is in the root `workspace:` list. The files are generated: add the package to the list, then run `flutter pub get` at the root.
