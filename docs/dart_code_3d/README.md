# dart_code_3D — project documentation

dart_code_3D analyzes a Dart code base (local folder, zip, or public git repository),
writes the result as a flutter_scene `.fscene` file, and lets you **fly through it in
3D**: classes are spheres sized by their code, methods and subclasses live inside them,
calls are links.

This folder drives the build. **Each file in `sessions/` is one agent work session**
that ends with one pull request.

| File | Read it when |
|---|---|
| [architecture.md](architecture.md) | Always, first. All product and technical decisions. |
| [agent-workflow.md](agent-workflow.md) | Always. How to branch, test, commit, open the PR, hand off. |
| [sessions/](sessions/) | Your session file + the previous one's "Session log". |
| [future.md](future.md) | Only to know what **not** to build yet. |

## How to start a session (for the owner)

Open Claude Code in `/volume/hawkbee` and say:

> Run the dart_code_3D session `docs/dart_code_3d/sessions/NN-….md`. Follow
> `docs/dart_code_3d/agent-workflow.md`.

One session per conversation. Review and merge the PR before starting the next
session, unless the dependency table below says they are independent.

## Prerequisites (owner, once)

- [ ] Merge `init-appwrite-project` into `main` (sessions branch from `main`).
- [ ] Add to the `factory1` container image (needed for Linux builds and 3D visual tests,
      sessions 01–02):
      `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev xvfb libgl1-mesa-dri libegl-mesa0 libgles2 mesa-vulkan-drivers`
      (+ the Node 22 / appwrite-cli items already listed in `docs/project-setup.md` §8).
- [ ] During session 01, run the one `flutter create --platforms=linux` command the agent
      gives you (the VGV hook blocks it for agents).
- [ ] Optional: Android SDK in the container for Android builds; phones/browser for the
      performance numbers requested in sessions 11 and 16.

## Sessions

| # | Session | Depends on | Status |
|---|---|---|---|
| 01 | [Workspace, submodule, app scaffold, first sphere](sessions/01-workspace-and-app-scaffold.md) | prerequisites | todo |
| 02 | [Visual test harness (2D goldens + 3D screenshots)](sessions/02-visual-test-harness.md) | 01 | todo |
| 03 | [`code_graph`: model + `.fscene` codec](sessions/03-code-graph-model-and-fscene-codec.md) | 01 | todo |
| 04 | [`code_source_client`: folder / zip / public git](sessions/04-code-source-client.md) | 03 | todo |
| 05 | [Engine 1: rules, parsing, declarations, containment](sessions/05-engine-rules-parse-declarations.md) | 03, 04 | todo |
| 06 | [Engine 2: reference resolution and links](sessions/06-engine-resolution-and-links.md) | 05 | todo |
| 07 | [Engine 3: CLI, performance, isolates, AltMe](sessions/07-engine-cli-performance.md) | 06 | todo |
| 08 | [`code_layout`: 3D placement](sessions/08-layout.md) | 03 (07 for real data) | todo |
| 09 | [`code_map_repository`: orchestration, save/open/share](sessions/09-code-map-repository.md) | 04, 07, 08 | todo |
| 10 | [App shell, theme, settings + rules editor](sessions/10-app-shell-theme-settings.md) | 02, 05 | todo |
| 11 | [Viewer foundation: load, instanced spheres, entry point](sessions/11-viewer-foundation.md) | 02, 03, 08, 10 | todo |
| 12 | [Fly mode: keyboard arrows, touch trackball, collisions](sessions/12-viewer-fly-navigation.md) | 11 | todo |
| 13 | [Entering spheres, interior/window view, links](sessions/13-viewer-inside-spheres-and-links.md) | 12 | todo |
| 14 | [Selection, info panel, labels, search, minimap](sessions/14-viewer-selection-hud-minimap.md) | 13 | todo |
| 15 | [New analysis flow, recent maps, open & share](sessions/15-analysis-flow-and-files.md) | 09, 10, 11 | todo |
| 16 | [MVP hardening: AltMe end-to-end, perf, a11y, docs](sessions/16-mvp-hardening.md) | all | todo |

Sessions that can run in parallel once their dependencies are merged: **02 ∥ 03**,
**08 ∥ 04–07**, **10 ∥ 06–09**, **15 ∥ 12–14**.

Status values: `todo` → `in progress` → `PR open #N` → `merged`. The session agent
updates its own row.

## Datasets

- **flutter_scene** (first dev dataset): the submodule `packages/flutter_scene`, ~620
  non-generated files, ~206k lines, ~1,700 classes.
- **AltMe** (scale reference): https://github.com/TalaoDAO/AltMe, ~1,050 non-generated
  files, ~108k lines, ~1,100 classes. Clone into a scratch folder; never commit it.
