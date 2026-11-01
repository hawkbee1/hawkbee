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
- [ ] The acceptance criteria of the issue (m4-rules-core.md, Issue 1).
- [ ] The package is in the root `workspace:` list, the melos `format` list and `.gitmodules`.
- [ ] `dart pub deps` shows no `flutter`.
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
_Written by the session agent when it finishes._
