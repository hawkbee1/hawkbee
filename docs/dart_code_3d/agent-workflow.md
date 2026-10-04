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
   The previous session's PRs (hawkbee and sub-repositories) must be merged. If they are
   not, **ask the user** whether to wait or to stack your branch on the previous session's branch.
3. Create your branch from the up-to-date `main` (and the same branch in each
   sub-repository you will change, see §2):
   ```bash
   git switch main && git pull --ff-only
   git submodule update --init --recursive
   git switch -c dc3d/sNN-<slug>          # e.g. dc3d/s03-code-graph
   ```
4. Load the skills your session lists (Skill tool). Typical ones:
   `vgv-ai-flutter-plugin:layered-architecture`, `…:bloc`, `…:testing`,
   `…:material-theming`, `…:green-gate`. For any rendering code, also read
   `packages/flutter_scene/packages/flutter_scene/skills/flutter_scene-idioms/SKILL.md`
   and its `references/what-exists.md`.
5. For any library API you are not 100% sure about, look it up (Context7 MCP, the
   `read_package_uris` / `rip_grep_packages` Dart MCP tools, or the submodule source).
   **Do not invent APIs.** flutter_scene is not three.js, Unity or Godot.

## 2. Repositories: one per app/package, all submodules of hawkbee

The app and **every package this project creates** live in their **own public GitHub
repository** under `hawkbee1`, and hawkbee includes each as a **git submodule** at its
usual path:

| Path in hawkbee | Repository |
|---|---|
| `apps/dart_code_3d` | `hawkbee1/dart_code_3d` |
| `packages/code_graph`, `packages/code_source_client`, `packages/code_analysis_engine`, `packages/code_layout`, `packages/code_map_repository`, `packages/settings_repository` | `hawkbee1/<package name>` |
| `packages/flutter_scene` | `bdero/flutter_scene` (third party, read-only, pinned tag) |

hawkbee stays the **workspace**: root `pubspec.yaml` (workspace list, overrides, melos
scripts), `docs/dart_code_3d/`, `tool/`. The sub-repositories are not buildable
alone (`resolution: workspace`, `path:` dependencies to siblings). Each one's README
says so and explains how to clone hawkbee with `--recurse-submodules`.

### Creating a new app or package (procedure)

1. Scaffold it in place with the Very Good CLI MCP `create` tool (`workspace: true`),
   add it to the root `workspace:` and to the melos `format` list.
   **`.vscode` lives only at the melos root (owner rule):** delete the generated
   `<path>/.vscode/` folder and the `!.vscode/...` lines from `<path>/.gitignore`. For a
   new app, add its debug/profile/release entries to the root `.vscode/launch.json`
   instead (same shape as the existing ones).
2. Make it its own repository and publish it:
   ```bash
   cd <path>                                  # e.g. packages/code_graph
   git init -b main
   git add -A && git commit -m "chore: scaffold <name> with Very Good CLI"
   gh repo create hawkbee1/<name> --public --source=. --push \
     --description "<one line>. Part of the hawkbee monorepo (dart_code_3D)."
   gh repo edit hawkbee1/<name> --enable-squash-merge=false --enable-rebase-merge=false --delete-branch-on-merge=false
   cd -                                       # back to the hawkbee root
   git submodule add https://github.com/hawkbee1/<name>.git <path>   # adopts the existing repo in place
   git submodule absorbgitdirs <path>         # moves its .git into .git/modules like a normal clone
   git commit -m "chore(<name>): add <name> as a submodule"
   ```
   Only merge commits are allowed in the sub-repositories. A squash or rebase merge
   would rewrite the commit that hawkbee points to.
3. Add a README section "Part of hawkbee" (clone with
   `git clone --recurse-submodules https://github.com/hawkbee1/hawkbee.git`).

New-package pitfalls (found in session 03):
- **Delete the template's `.github/workflows/` and `.github/dependabot.yaml`**: the
  package only resolves inside hawkbee, so standalone CI would always fail.
- **Fix the template's dependency constraints** or `flutter pub get` fails for the whole
  workspace: `test: ^1.31.0` (Flutter pins `test_api`, `^1.32.0` does not resolve) and
  `equatable: ^3.0.0` (the other packages use 3.x).
- Dart 3.13 style: write constructors as `const new(...)`, named generative ones as
  `new named(...)` (**a space, not a dot**: `new._(…)` is a syntax error, write
  `new _(…)`), and factories as `factory fromJson(...)`;
  `dart fix --apply --code=unnecessary_type_name_in_constructor` converts them.
- **Coverage of `props` and the `const` trap**: two identical `const` instances are the
  same object, so an Equatable comparison of them never calls `props`, and coverage stays
  below 100%. Compare instances built at runtime, or call `.props` directly.
- The VGV hook scans **every line** of a Bash command, heredoc content included, so
  writing a file that contains `very_good test` or `flutter test` through `cat <<EOF`
  is denied. Use the Write tool for such files.
- The MCP `test` tool rejects `timeout_seconds` together with `dart: true`.
- Very Good CLI merges test files into one, which **drops library-level `@Tags`**. A file
  with its own tags (e.g. opt-in `network` tests) also needs the
  `skip_very_good_optimization` tag, declared in `dart_test.yaml` (see
  `code_source_client`).
- A description containing `:` breaks the generated `pubspec.yaml` (the create tool fails
  with a YAML error). Quote it, or avoid colons.

### Branches, commits and PRs across repositories

- Use the **same branch name** (`dc3d/sNN-<slug>`) in hawkbee and in every
  sub-repository you change: `git -C <path> switch -c dc3d/sNN-<slug>`.
- Commit inside the sub-repository (`git -C <path> commit …`), then record the new
  pointer in hawkbee (`git add <path> && git commit -m "chore: bump <name>"`).
  Bump the pointer at least before every push.
- Push the sub-repository branches **first**, then hawkbee.
- Open **one PR per changed sub-repository** (against its `main`) and **one hawkbee
  PR**. The hawkbee PR body links every sub-repository PR and carries the test status
  table and the goldens. Each sub-repository PR body links back to the hawkbee PR.
- Merge order (owner): sub-repository PRs first (merge commit), then the hawkbee PR.
- At the start of a session: `git submodule update --init --recursive`, then in each
  sub-repository you will change, `git -C <path> switch main && git -C <path> pull --ff-only`
  before branching.

## 3. Tooling rules in this container (`factory1`)

- Tests: use the **Very Good CLI MCP `test` tool** (`directory: <package>`,
  `coverage: true`, `dart: true` for pure-Dart packages). A hook blocks
  `flutter test` / `dart test` / `flutter create` / `very_good create` in Bash.
- Scaffolding: the **Very Good CLI MCP `create` tool** (`workspace: true`).
- Formatting/analysis: `dart format <paths>` and `dart analyze --fatal-infos <package>`
  run automatically after edits. Run them on the whole package before committing anyway.
- **Never** edit, format, analyze or run tests inside `packages/flutter_scene/`
  (the flutter_scene submodule). It is read-only for us.
- `flutter drive` (3D visual tests) runs through `tool/visual_test.sh` (from session 02 on).
- No Docker socket. No `sudo` (denied). If a system package is missing (Xvfb, clang,
  ninja, GTK, Mesa), stop and ask the user to add it to the container image.
- If you need the user to run a command the hooks block, ask them to type it with the
  `!` prefix. Never try to get around a hook. (Adding the Linux platform needs no
  `flutter create`: use `tool/add_linux_platform.sh`.)

## 4. While working

- Work in **small steps**. After each step: format, analyze, run the affected
  tests, then commit.
- Commit often, one logical change per commit, Conventional Commits:
  `feat(code_graph): add CodeNode model`, `test(engine): fixture for barrel exports`,
  `chore(workspace): add flutter_scene submodule`.
- Commits are authored by the configured git user. **Do not add a
  `Co-Authored-By` trailer** (owner preference).
- Never commit secrets, `build/`, `.dart_tool/`, coverage output, or files under
  the flutter_scene submodule.
- Respect the layer rules (`architecture.md` §3). If your task seems to need an
  import that breaks them, stop and ask.
- Keep **public APIs documented** (`///` doc comments), because `very_good_analysis` requires it.

## 5. Tests: the definition of done

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

Golden test pitfalls (found in session 02):
- Use `goldenTest()` from `test/helpers/goldens.dart`; it tags every test with
  `TestTag.golden`. **Do not** write a library-level `@Tags([TestTag.golden])`:
  the test runner only accepts string literals there and refuses to load the file
  (the VGV testing skill shows that pattern, but it does not work).
- Indeterminate animations (spinners) are captured on their first frame, where they
  are a dot. Pass `pump:` to advance them (see `viewer_page_golden_test.dart`).
- 3D scenarios go in `integration_test/visual/visual_scenarios.dart`; they must be
  deterministic (no time-based animation, fixed camera).

Pitfalls found later:
- **Re-run the whole unit suite as the last step before committing**, after any change made
  while iterating on 3D baselines (a speed constant changed in session 12 broke a test that
  nobody re-ran).
- A mock bloc (`MockBloc`) only rebuilds a widget through its stream: use `whenListen` to change
  its state in a test. A missing `registerFallbackValue` leaves mocktail stuck in `verify` and
  many unrelated tests fail afterwards: fix the **first** failure.
- `flutter_scene` blended (translucent) materials ignore `doubleSided`; see the session 13 log.
- `DC3D_SCENARIO=<id> tool/visual_test.sh` captures a single 3D scenario; after
  `--update`, a compare run (without `--update`) proves the baselines are stable.
- 2D goldens depend on the theme seed (the app bar color): an uncommitted theme edit makes every
  golden fail. Generate goldens with the committed theme.

When you intentionally change a golden or a 3D baseline, regenerate it
(`update_goldens: true` in the MCP test tool, or `tool/visual_test.sh --update`),
**look at the new image** (Read tool), and list it in the PR.

## 6. Finishing: PRs + handoff

1. Append a **"Session log"** section at the bottom of your session file:
   - what you built (packages, main classes);
   - deviations from the plan and why;
   - known limitations / TODOs for later sessions;
   - measured numbers if your session asked for them (timings, fps, node counts).
2. Update the status table in `docs/dart_code_3d/README.md` (your session → "PR open #N").
3. Push and open the PRs against `main` (§2: sub-repositories first, then hawkbee):
   ```bash
   # for each changed sub-repository
   git -C <path> push -u origin dc3d/sNN-<slug>
   gh pr create -R hawkbee1/<name> --base main --head dc3d/sNN-<slug> \
     --title "dc3d sNN: <title>" --body "Part of hawkbee1/hawkbee session NN (PR link added once it exists). …"
   # then hawkbee (submodule pointers bumped to the pushed commits)
   git push -u origin dc3d/sNN-<slug>
   gh pr create --base main --title "dc3d sNN: <title>" --body-file <tmpfile>
   # finally edit each sub-repository PR body to link the hawkbee PR. `gh pr edit` fails
   # on these repos (GraphQL "Projects (classic) is being deprecated"), so use REST:
   gh api -X PATCH repos/hawkbee1/<name>/pulls/<n> -F body=@<tmpfile>
   ```
   hawkbee PR body template:
   ```markdown
   ## Session
   docs/dart_code_3d/sessions/NN-<slug>.md

   ## Pull requests in sub-repositories
   - hawkbee1/dart_code_3d#N
   - hawkbee1/code_graph#N

   ## What changed
   - …

   ## Test status
   | Package | analyze | format | tests | coverage |
   |---|---|---|---|---|
   | code_graph | ✅ | ✅ | ✅ 42 passed | 100% |

   3D visual tests: ✅ 9/9 (or "n/a in this session")

   ## Goldens / screenshots
   <!-- one image per changed golden; the repos are public, so raw links render.
        Goldens live in the app repository, so link to its branch. -->
   ![home – phone – dark](https://github.com/hawkbee1/dart_code_3d/blob/dc3d/sNN-<slug>/test/<feature>/…/goldens/<name>/phone_dark.png?raw=true)

   ## Acceptance criteria
   - [x] …

   ## Notes for the next session
   - …
   ```
   Report failing or skipped checks **honestly** in the table. Never mark something ✅
   that you did not run. **No "Generated with Claude Code" footer or any other AI
   attribution** in PR descriptions, PR comments or commits (owner preference).
4. Do **not** merge the PRs yourself. The owner reviews and merges.
