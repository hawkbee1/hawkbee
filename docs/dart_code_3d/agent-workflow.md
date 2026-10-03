# dart_code_3D — how to run a work session

You are an agent running **one** session file from `docs/dart_code_3d/sessions/`.
Follow this protocol exactly. When something is unclear or impossible, **stop and
ask the user** rather than guessing. Guesses cost more to undo than questions.

---

## 1. Before writing any code

1. Read, in this order:
   1. `docs/dart_code_3d/README.md` (status table: which sessions are done);
   2. `docs/dart_code_3d/architecture.md` (the decisions; do not re-open them);
   3. your session file, entirely, **including the "Session log" sections of the
      previous session file** (the handoff notes from the last agent);
   4. `docs/project-setup.md` §2–3 (monorepo and VGV rules).
2. Check the previous session is merged: `git fetch origin && git log origin/main --oneline | head`.
   The previous session's PR must be merged into `main`. If it is not, **ask the user**
   whether to wait or to stack your branch on the previous session's branch.
3. Create your branch from the up-to-date `main`:
   ```bash
   git switch main && git pull --ff-only
   git switch -c dc3d/sNN-<slug>          # e.g. dc3d/s03-code-graph
   git submodule update --init --recursive
   ```
4. Load the skills your session lists (Skill tool). Typical ones:
   `vgv-ai-flutter-plugin:layered-architecture`, `…:bloc`, `…:testing`,
   `…:material-theming`, `…:green-gate`. For any rendering code, also read
   `packages/flutter_scene/packages/flutter_scene/skills/flutter_scene-idioms/SKILL.md`
   and its `references/what-exists.md`.
5. For any library API you are not 100% sure about, look it up (Context7 MCP, the
   `read_package_uris` / `rip_grep_packages` Dart MCP tools, or the submodule source).
   **Do not invent APIs.** flutter_scene is not three.js, Unity or Godot.

## 2. Tooling rules in this container (`factory1`)

- Tests: use the **Very Good CLI MCP `test` tool** (`directory: <package>`,
  `coverage: true`, `dart: true` for pure-Dart packages). A hook blocks
  `flutter test` / `dart test` / `flutter create` / `very_good create` in Bash.
- Scaffolding: the **Very Good CLI MCP `create` tool** (`workspace: true`).
- Formatting/analysis: `dart format <paths>` and `dart analyze --fatal-infos <package>`
  run automatically after edits. Run them on the whole package before committing anyway.
- **Never** edit, format, analyze or run tests inside `packages/flutter_scene/`
  (the submodule). It is read-only for us.
- `flutter drive` (3D visual tests) runs through `tool/visual_test.sh` (from session 02 on).
- No Docker socket. No `sudo` (denied). If a system package is missing (Xvfb, clang,
  ninja, GTK, Mesa), stop and ask the user to add it to the container image.
- If you need the user to run a command the hooks block, ask them to type it with the
  `!` prefix. Never try to get around a hook. (Adding the Linux platform needs no
  `flutter create`: use `tool/add_linux_platform.sh`.)

## 3. While working

- Work in **small steps**. After each step: format, analyze, run the affected
  tests, then commit.
- Commit often, one logical change per commit, Conventional Commits:
  `feat(code_graph): add CodeNode model`, `test(engine): fixture for barrel exports`,
  `chore(workspace): add flutter_scene submodule`.
- Commits are authored by the configured git user. **Do not add a
  `Co-Authored-By` trailer** (owner preference).
- Never commit secrets, `build/`, `.dart_tool/`, coverage output, or files under
  the submodule.
- Respect the layer rules (`architecture.md` §3). If your task seems to need an
  import that breaks them, stop and ask.
- Keep **public APIs documented** (`///` doc comments), because `very_good_analysis` requires it.

## 4. Tests: the definition of done

A session is done only when **all** of these hold:

1. `dart format --set-exit-if-changed` is clean for every package you touched.
2. `dart analyze --fatal-infos` is clean for every package you touched.
3. All tests pass. **Coverage is 100%** for every package you touched (use the
   `green-gate` skill to loop until it is). A `// coverage:ignore-line` needs a
   comment explaining why, and is allowed only for genuinely untestable
   platform glue.
4. **Golden tests** exist for every screen/panel/overlay your session adds or changes:
   3 sizes × light/dark (helper from session 02). Goldens are not only regression
   guards. They show the owner what the UX looks like, so make the golden scenarios
   **realistic** (real-looking data, long names, empty states, error states, a
   loaded AltMe-like map), not trivial.
5. **3D visual tests** (from session 02 on) pass for every 3D change, and new
   viewpoints get new baselines.
6. Every acceptance criterion in your session file is checked.

When you intentionally change a golden or a 3D baseline, regenerate it
(`update_goldens: true` in the MCP test tool, or `tool/visual_test.sh --update`),
**look at the new image** (Read tool), and list it in the PR.

## 5. Finishing: PR + handoff

1. Append a **"Session log"** section at the bottom of your session file:
   - what you built (packages, main classes);
   - deviations from the plan and why;
   - known limitations / TODOs for later sessions;
   - measured numbers if your session asked for them (timings, fps, node counts).
2. Update the status table in `docs/dart_code_3d/README.md` (your session → "PR open #N").
3. Push and open the PR against `main`:
   ```bash
   git push -u origin dc3d/sNN-<slug>
   gh pr create --base main --title "dc3d sNN: <title>" --body-file <tmpfile>
   ```
   PR body template:
   ```markdown
   ## Session
   docs/dart_code_3d/sessions/NN-<slug>.md

   ## What changed
   - …

   ## Test status
   | Package | analyze | format | tests | coverage |
   |---|---|---|---|---|
   | code_graph | ✅ | ✅ | ✅ 42 passed | 100% |

   3D visual tests: ✅ 9/9 (or "n/a in this session")

   ## Goldens / screenshots
   <!-- one image per changed golden; the repo is public, so raw links render -->
   ![home – phone – dark](https://github.com/hawkbee1/hawkbee/blob/dc3d/sNN-<slug>/apps/dart_code_3d/test/goldens/…png?raw=true)

   ## Acceptance criteria
   - [x] …

   ## Notes for the next session
   - …

   🤖 Generated with [Claude Code](https://claude.com/claude-code)
   ```
   Report failing or skipped checks **honestly** in the table. Never mark something ✅
   that you did not run.
4. Do **not** merge the PR yourself. The owner reviews and merges.
