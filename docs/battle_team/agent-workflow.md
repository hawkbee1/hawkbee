# Battle Team: how to run a work session

You are an agent running **one** session file from `docs/battle_team/sessions/`. Each session implements **one milestone issue** of `apps/battle_team/plan/milestones/`. When something is unclear, contradictory or impossible, **stop and ask the user**. Never guess a rule.

The mechanics shared with the other hawkbee projects (repositories, submodules, container hooks, PR flow) are in `docs/dart_code_3d/agent-workflow.md`, cited below as "dc3d §N". This file says what differs. `plan/` means `apps/battle_team/plan/`.

## 1. Before writing any code
1. Read, in this order:
   1. `docs/battle_team/README.md` (which sessions are merged);
   2. `apps/battle_team/AGENTS.md`, then `plan/README.md`;
   3. the milestone file of your issue: its goal, its "Conventions" and **your issue entirely**. The issue is the specification of the session;
   4. every rule the issue lists, in `plan/specs/` (each ID prefix has its file: `MAP` 10, `UNIT` 20, `RELIC` 30, `SOC` 40, `HQ` 50, `ECO` 60, `COMBAT` 70, `AI` 80), and the decisions they cite in `plan/specs/00-overview.md` when a rule is not clear alone;
   5. the data the issue uses, in `plan/data/`, comments included;
   6. `plan/stack/07-engineering-principles.md` (principles, patterns, packages);
   7. your session file, and the "Session log" of each session it depends on;
   8. for an M7 session, §6 of this file and `docs/battle_team/playtest.md`.
2. Check that the sessions you depend on are merged (README table, `git log origin/main`). If not, ask the user whether to wait or to stack your branch.
3. Branch from an up-to-date `main`, with the same name in hawkbee and in the package repository (dc3d §2): `bt/<branch of your session file>`.
4. Load the skills your session lists. Check any library API you are not sure of (context7, the Dart MCP package tools). Do not invent APIs.

## 2. Rules for Battle Team code
- **Rule IDs everywhere.** A test name starts with the rule ID it checks (`COMBAT-06 moves at regen speed at 0 AP`), and the doc comment of the code that implements a rule cites it. Every rule the issue lists has at least one test.
- **Numbers only in `plan/data`.** No game number in `lib/`. Tests on real values read the real files from the hawkbee checkout, `../../apps/battle_team/plan/data/` relative to the package (stack decision 7), through the test helper of M4.1. Synthetic cases use fixtures in `test/`.
- **No I/O in `lib/`.** The caller passes YAML text, maps and time. Only command-line tools in `bin/` read files. The exceptions are `battle_host` (M5) and `battle_client` (M6): their I/O lives in adapters behind ports, and their core follows this rule.
- **Deterministic.** Time comes from an injected `Clock` or as an argument; randomness from an injected `SeededRandom`. No `DateTime.now()`, no unseeded `Random`, no global state, no singletons.
- **Immutable models, sealed types** for variants (commands, events, states) with exhaustive `switch`. Use a Gang of Four pattern only where stack decision 7 names it, and cite it in the doc comment.
- **Pure Dart:** no Flutter dependency — in the packages. The app (`apps/battle_team`, milestone M7) is Flutter: §6 says what differs there.
- **An unclear or contradictory rule:** stop and propose a question for `plan/specs/95-open-questions.md` to the user. Write it only with the user's agreement: it is a change in the `battle_team` repository, on the same branch name, with its own PR.
- Never change `plan/specs` or `plan/data` to make code pass.

## 3. Repositories, tooling, commits
- Repositories, submodules, the new-package procedure and its pitfalls: dc3d §2. Battle Team packages are `packages/battle_*`, each in its own repository `hawkbee1/battle_*`.
- Tooling in the container: dc3d §3 (the Very Good CLI MCP `test` tool with `dart: true`; hooks).
- Commits: dc3d §4 (small steps, Conventional Commits, no `Co-Authored-By`).

## 4. Definition of done
For every package you touched:
1. format clean and `dart analyze --fatal-infos` clean;
2. all tests pass, with **100 % line coverage** (`green-gate` skill);
3. every rule listed in the issue has a test whose name starts with its ID;
4. every acceptance criterion of the issue and of the session file is checked.

M3 to M6 are headless: no goldens and no 3D tests. M7 sessions add the app checks of §6.

## 5. Finishing
1. Append a **"Session log"** to your session file: what you built (main types and functions), deviations and why, questions raised, and any numbers the session asked for.
2. Update your row in `docs/battle_team/README.md`.
3. Push and open the PRs as in dc3d §6: the package repository first, then hawkbee (and `battle_team` if the plan changed). Title: `bt <session>: <title>`, for example `bt M4.3: Simulation clock and AP pool`. In the hawkbee PR body, use the dc3d template without the goldens section and the 3D line, and add a "Rules covered" list: each rule ID with its test file.
4. Do not merge. No AI attribution anywhere.

## 6. M7: sessions in the app (`apps/battle_team`)
The app is a Flutter project in its own repository `hawkbee1/battle_team` (a submodule, like a package). Everything above applies, with these differences. Read `docs/battle_team/playtest.md` too: the app you extend is the playtest.

**Structure.** VGV layers (`vgv-ai-flutter-plugin:layered-architecture`): a feature folder per screen under `lib/<feature>/` with `cubit/` or `bloc/`, `view/`, `widgets/`; data access through a repository class over `battle_client` and `appwrite_api_client`; no `package:appwrite` import outside `appwrite_api_client`; no rule computed in the app (decision 3) — the host answers, `battle_rules` pre-checks for display only. Blocs hold no widgets; widgets hold no logic beyond layout. State classes are immutable (`Equatable`), events and states sealed where they vary.

**The 3D seam.** flutter_scene needs a GPU, which tests have not. The pattern the playtest set, keep it: an `abstract interface class` for what the scene does (`PlaytestWorld` today: `show(...)`, `tick(...)`), one implementation on flutter_scene marked `// coverage:ignore-file` with a comment saying why, and a fake in `test/helpers/` (`FakeWorld`) that records what it was told to draw. Blocs, pages and widgets are tested against the fake; the GPU file holds only drawing. Every new drawing capability (fog shading, shots, the first-person camera) extends the interface first, then the fake, then the GPU class. Name the pattern in the doc comment (Strategy for swappable renderers, Observer for the view listening to the bloc).

**Tests and coverage.** The Very Good CLI MCP `test` tool with `directory: apps/battle_team`, `coverage: true`, `optimization: false` (the app's suite breaks under optimization). The hook blocks `flutter test` in Bash. 100 % line coverage of everything not `coverage:ignore`d; the only ignores allowed are the GPU drawing class, generated files (`lib/gen`, `lib/l10n/gen`) and platform glue with a reason. Widget tests use `test/helpers/pump_app.dart`; blocs use `bloc_test`; mocks use `mocktail` (register fallback values for sealed types once in `test/helpers/mocks.dart`). Streams from the host: reuse `test/helpers/fake_host.dart` and the recorded streams `battle_client` ships in its fixtures; never hand-write host messages when a recording exists.

**Rules in tests.** As §2: a test name starts with the rule ID it checks; UI-only behaviour cites the issue instead (`M7.6 storage view lists stored units`). A test for decision 237 is required whenever a session draws, lists or logs state: feed a view with an unseen hit or an out-of-sight unit and assert nothing of it shows.

**Localization.** Two ARB files, `lib/l10n/arb/app_en.arb` and `app_fr.arb`; every user-facing string goes through `context.l10n` (`vgv-ai-flutter-plugin:internationalization`). The `MaterialApp` must carry `material_ui`'s localization delegates beside the app's (`lib/app/view/app.dart`): without them non-English locales break at runtime, which no widget test catches — run the app in French once. Add `app_fr.arb` in the first session that lacks it.

**Running it.** The app runs against the local Appwrite and a host in `factory1` as `docs/battle_team/playtest.md` says; the M7.2 playtest tool creates testing battles. From the container you can build for the web and check in headless Chromium when available (the playtest PR did); you cannot run on a phone. For the screenshot or recording a session asks for: take it yourself if a web build renders, otherwise write the exact launch steps in the log and ask the owner to run it and paste the picture. Never describe a picture you did not see.

**Repositories.** `apps/battle_team` is the submodule for both the plan and the app code, so one branch `bt/<session>` carries both; the hawkbee PR bumps its pointer. Flavors: `development`, `staging`, `production`, plus `playtest` (`lib/main_playtest.dart`). Launch configurations live only in the root `.vscode/launch.json`. Dart 3.13 constructors: `new(...)`, `new named(...)`, `factory fromJson(...)`. Push through `gh` as the credential helper (`git -c credential.helper= -c credential.helper='!gh auth git-credential' push`); a 500/502 from GitHub often still succeeded — check the remote before retrying; `gh pr edit` fails on these repositories, use `gh api -X PATCH repos/<owner>/<repo>/pulls/<n> -F body=@file`.

**While M7's plan PRs are open** (battle_team #39, hawkbee #70, stacked on #38 and #69), branch from `bt/m7-plan` in both repositories and open PRs against `main` whose first line is `Stacked on #N: merge it first`.
