# Session G2: `flutter_scene_goldens`

**Package:** new, `packages/flutter_scene_goldens`, its own public repository `hawkbee1/flutter_scene_goldens` and a hawkbee submodule (dc3d §2). · **Branch:** `goldens/g2-flutter-scene-goldens` · **Depends on:** G1 (merged, or stacked on it).
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read:** [`docs/goldens/README.md`](../README.md); G1's session log; `apps/dart_code_3d/integration_test/visual/*.dart`, `test_driver/visual_driver.dart`, `test_driver/image_compare.dart` (what this package generalises); hawkbee `tool/visual_test.sh` and `tool/add_linux_platform.sh`; `packages/flutter_scene/examples/smoke_render` and flutter_scene's CI workflow.

## Goal
Image tests of flutter_scene frames, rendered by the real pipeline in software, into the project's `goldens/scenes/` tree. Depends on `screen_goldens` for the screens, the themes and the names; nothing else of hawkbee.

## Steps
1. **Create** the package as in G1.2. Description: "Image tests of flutter_scene frames in integration_test, under Xvfb and Mesa llvmpipe."
2. **`SceneScenario`** (from `VisualScenario`): id, `load` returning the builder of its view, the background colour, `clearCorners`, `minCenterCoverage`.
3. **`runSceneGoldens(scenarios, {screens, themes, locales, wrap})`** (from `visual_test.dart`'s `main`, without the app): the warm-up frame before `Scene.initializeStaticResources()`, the `OverflowBox` and `RepaintBoundary` at the exact screen size, the settle loop, `toImage`, the checks of `FrameStats` (corners clear, centre drawn, foreground lit), the captures reported to the driver. `--dart-define=SCENE_GOLDENS_ONLY=<id>` captures one scenario.
4. **The host side**: `sceneGoldensDriver()` (from `visual_driver.dart`) and `compareImages` (from `image_compare.dart`, same tolerances): captures and `_diff.png` under `build/goldens/scenes/`, baselines under `goldens/scenes/`; `SCENE_GOLDENS_UPDATE=1` replaces the baselines.
5. **`dart run flutter_scene_goldens:capture [--update] [--only <id>]`**, run from a project: checks `xvfb-run` and `flutter`, sets `LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe`, runs `flutter drive -d linux --enable-impeller --enable-flutter-gpu` under `xvfb-run`. It replaces hawkbee `tool/visual_test.sh`, which dc3d session 17 deletes.
6. **An example** app in the package (`example/`, Linux runner from `tool/add_linux_platform.sh`): one scenario, a lit sphere, with its baselines. It is the proof that the package renders, and what a new project copies.
7. **README** of the package: what the machine needs (dc3d `README.md`, Prerequisites), the three files a project adds (scenarios, the test entry, the driver), how to run, update and read a failure.
8. **Gates** and **finish** (dc3d §5, §6).

## Tests to write
- `FrameStats`: a blank frame, a frame with clear corners, a dark foreground, a drawn centre.
- `compareImages`: identical, within tolerance, beyond it (with the diff image), different sizes.
- Paths and names: a scenario and a variant give the README's path, for baselines and for captures.
- The command: its arguments, the environment and the `flutter drive` line it builds, a missing `xvfb-run` said clearly.
- The example's scenario, captured twice: the second run matches the first within the tolerance.
- 100 % coverage of what a unit test can load. The device runner runs only under `integration_test`: `// coverage:ignore-file` with that reason; the example covers it.

## Stop and ask when
- Two captures of the example differ beyond the tolerance: find the cause; do not raise the tolerance.
- The package cannot stay free of a hawkbee sibling other than `screen_goldens`.

## Acceptance criteria
- [ ] `hawkbee1/flutter_scene_goldens` exists and is a hawkbee submodule.
- [ ] The example's capture passes under `dart run flutter_scene_goldens:capture`, twice in a row, in the container.
- [ ] The tests above pass at 100 % coverage (the ignored runner aside); format and `dart analyze --fatal-infos` are clean.

## Session log
