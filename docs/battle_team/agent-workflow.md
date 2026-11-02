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
   7. your session file, and the "Session log" of each session it depends on.
2. Check that the sessions you depend on are merged (README table, `git log origin/main`). If not, ask the user whether to wait or to stack your branch.
3. Branch from an up-to-date `main`, with the same name in hawkbee and in the package repository (dc3d §2): `bt/<branch of your session file>`.
4. Load the skills your session lists. Check any library API you are not sure of (context7, the Dart MCP package tools). Do not invent APIs.

## 2. Rules for Battle Team code
- **Rule IDs everywhere.** A test name starts with the rule ID it checks (`COMBAT-06 moves at regen speed at 0 AP`), and the doc comment of the code that implements a rule cites it. Every rule the issue lists has at least one test.
- **Numbers only in `plan/data`.** No game number in `lib/`. Tests on real values read the real files from the hawkbee checkout, `../../apps/battle_team/plan/data/` relative to the package (stack decision 7), through the test helper of M4.1. Synthetic cases use fixtures in `test/`.
- **No I/O in `lib/`.** The caller passes YAML text, maps and time. Only command-line tools in `bin/` read files. The exception is `battle_host` (M5): its I/O lives in adapters behind ports, and its core follows this rule.
- **Deterministic.** Time comes from an injected `Clock` or as an argument; randomness from an injected `SeededRandom`. No `DateTime.now()`, no unseeded `Random`, no global state, no singletons.
- **Immutable models, sealed types** for variants (commands, events, states) with exhaustive `switch`. Use a Gang of Four pattern only where stack decision 7 names it, and cite it in the doc comment.
- **Pure Dart:** no Flutter dependency.
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

M3 to M5 are headless: no goldens and no 3D tests.

## 5. Finishing
1. Append a **"Session log"** to your session file: what you built (main types and functions), deviations and why, questions raised, and any numbers the session asked for.
2. Update your row in `docs/battle_team/README.md`.
3. Push and open the PRs as in dc3d §6: the package repository first, then hawkbee (and `battle_team` if the plan changed). Title: `bt <session>: <title>`, for example `bt M4.3: Simulation clock and AP pool`. In the hawkbee PR body, use the dc3d template without the goldens section and the 3D line, and add a "Rules covered" list: each rule ID with its test file.
4. Do not merge. No AI attribution anywhere.
