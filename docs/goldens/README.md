# Golden tests across hawkbee

Every app of the workspace gets image tests of its screens (2D) and of its flutter_scene frames (3D), from two shared packages, with all the images of a project in one folder tree. This folder holds what is common; each app's own work is a session in its own docs folder.

| Session | What | Where | Depends on | Status |
|---|---|---|---|---|
| [G1](sessions/g1-screen-goldens.md) | `screen_goldens`: goldens at several screen sizes, themes and locales | new package | none | todo |
| [G2](sessions/g2-flutter-scene-goldens.md) | `flutter_scene_goldens`: image tests of flutter_scene frames | new package | G1 | todo |
| [dc3d 17](../dart_code_3d/sessions/17-goldens-packages.md) | dart_code_3D onto both packages, its images into one tree | `apps/dart_code_3d` | G1, G2 | todo |
| [M7.14](../battle_team/sessions/m7-14-golden-tests.md) | Battle Team's first goldens, 2D and 3D | `apps/battle_team` | G1, G2 | todo |

One session per conversation, in this order; dc3d 17 and M7.14 can run in parallel. G1 and G2 follow `docs/dart_code_3d/agent-workflow.md` (§2 repositories and the new-package procedure, §3 tooling, §4 commits, §5 tests, §6 PRs); branches `goldens/g1-screen-goldens` and `goldens/g2-flutter-scene-goldens`. The session agent updates its own row.

## Why
- **Battle Team has no golden and no 3D image test.** Its workflow said flutter_scene cannot be tested because tests have no GPU. That holds for `flutter test` only: dart_code_3D renders flutter_scene frames in `integration_test` on Linux desktop under Xvfb with Mesa llvmpipe (`flutter drive -d linux --enable-impeller --enable-flutter-gpu`), as flutter_scene's own CI does, and compares them with committed baselines.
- **dart_code_3D's harness is app code.** Its golden helper hard-wires the app's `pumpApp`; its 3D runner and driver name the app. Two packages make it reusable. The screen sizes serve any Flutter project, with or without flutter_scene.
- **Images are scattered.** dc3d keeps 430 2D goldens in `goldens/` folders next to each test file and 48 3D baselines in `visual_baselines/`.

## The image tree (every project)
```
<project>/goldens/
  screens/<test path under test/, without _test.dart>/<name>/<screen>_<theme>[_<locale>][_x<scale>].png
  scenes/<scenario>/<screen>_<theme>[_<locale>].png
<project>/build/goldens/     # failures, 3D captures, _diff.png files and reports; never committed
```
- No PNG anywhere else in `test/` or `integration_test/`.
- `<theme>` is the name the project gives each of its themes (dc3d: `light`, `dark`; Battle Team has one today), so adding a theme adds files and renames none.
- The locale suffix is left out for the project's default locale.

## Screens
Logical sizes at device pixel ratio 1: `phone` 390×844, `phoneLandscape` 844×390, `tablet` 820×1180, `desktop` 1440×900. A project picks from them and can add its own. Battle Team is played in portrait and in landscape: it uses all four.

## The packages
- **`screen_goldens`** has no flutter_scene dependency: the screens, the variant matrix, the comparator that owns the tree, real fonts.
- **`flutter_scene_goldens`** depends on it: scenarios, the capture run under `integration_test`, the sanity checks of a frame, the image compare, the command that runs it under Xvfb.
- Both must work outside hawkbee: other workspaces of the owner will use them. They depend on nothing of hawkbee but each other.

## Third-party packages looked at (2026-11-16)
- **[golden_screenshot](https://pub.dev/packages/golden_screenshot)** 12.2.0 (MIT, verified publisher, about 26,000 downloads a month, released 2026-11-08, needs Flutter 3.47 like us, uses `material_ui` like us). It has device definitions with optional frames, `testGoldens` (real shadows), a fuzzy comparator with a set tolerance, and `tester.loadAssets()` for fonts and images. It does not have our matrix (screen × theme × locale), and its files go to `<folder>/<device folder>/<name>.png` relative to the test file, not to one tree per project. Twelve major versions: its API moves. **Candidate for the inside of `screen_goldens`** (fonts, shadows, fuzzy compare, devices), never a direct dependency of an app, so a breaking release touches one package. G1 decides with a spike.
- **[golden_lens](https://pub.dev/packages/golden_lens)** 0.2.0 (MIT, 2 versions, one maintainer, about 340 downloads a month, last change 2026-06). It wraps the golden comparator and, when a golden fails, reports which widget and source line changed, as HTML and JSON an agent can read. It changes no result. 2D only: a flutter_scene frame is one widget. **Optional failure report**, not a dependency of the packages: young and little used. G1 tries it.

## After the goldens exist
- **Battle Team's theme.** It has one theme, which looks dark. With the images in hand, the owner decides: call it the dark theme and design a light one, or keep it and add a dark one. Not in these sessions.
