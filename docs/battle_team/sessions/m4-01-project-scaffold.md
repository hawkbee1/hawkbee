# Session M4.1: `battle_rules`: project scaffold

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 1. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-01-scaffold` · **Depends on:** prerequisites.
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/07-engineering-principles.md` (package layout, game data in packages).

## Notes
- Very Good CLI MCP `create`: `subcommand: dart_package`, `name: battle_rules`, `output_directory: packages`, `workspace: true`, a description without a colon. Add the package to the root `workspace:` list and to the melos `format` list.
- The repository `hawkbee1/battle_rules` already exists and is empty (created by the owner on 2026-11-01). In the procedure of dc3d §2 step 2, replace `gh repo create` with `git remote add origin https://github.com/hawkbee1/battle_rules.git` and `git push -u origin main`, then run the `gh repo edit` line (merge commits only), `git submodule add` and `git submodule absorbgitdirs`.
- Apply the new-package pitfalls of dc3d §2: delete `.github/workflows/` and `.github/dependabot.yaml`, fix the `test` constraint, write Dart 3.13 constructors, delete the generated `.vscode/`.
- `README.md`: what the package is (pure Dart, no I/O in `lib/`), the "Part of hawkbee" section, how to run the tests, and where its specification is (`apps/battle_team/plan/milestones/m4-rules-core.md`).
- Add the test helper that reads one data file from `../../apps/battle_team/plan/data/` (relative to the package, stack decision 7), with a test that it finds `units.yaml`. M4.2 and later sessions use it.
- No dependency beyond the template's yet: `yaml` comes with M4.2.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m4-rules-core.md, Issue 1).
- [x] The package is in the root `workspace:` list, the melos `format` list and `.gitmodules`.
- [x] `dart pub deps` shows no `flutter`.
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-01):
- `packages/battle_rules`: Very Good CLI `dart_package`, own public repository `hawkbee1/battle_rules` (merge commits only), submodule of hawkbee, in the root `workspace:` and melos `format` lists. `.github/workflows/` and `dependabot.yaml` deleted, `test: ^1.31.0`. The template generated no `.vscode/`.
- `lib/`: only the template placeholder `BattleRules` (`const new()`), with its placeholder test. M4.2 replaces it with the data models.
- `test/helpers/plan_data.dart`: `planDataPath` (`../../apps/battle_team/plan/data`) and `readPlanData(fileName)`, which returns the file's text and throws a `StateError` naming the path when the package is outside a hawkbee checkout. `plan_data_test.dart` checks that it finds `units.yaml` and the error message.
- README: what the package is, "Part of hawkbee", the specification paths, how to run the tests.

Checks: analyze `--fatal-infos` clean, format clean, 3 tests pass, coverage 100 % (1/1 line in `lib/`). `dart pub deps` for `battle_rules`: `mocktail`, `test`, `very_good_analysis` only, no `flutter`.

Deviations: none. Questions raised: none.

For the next sessions: the helper test lives in `test/helpers/`, so tests that need real data import `../helpers/plan_data.dart` (relative to `test/src/`). Tests run with the package folder as working directory.
