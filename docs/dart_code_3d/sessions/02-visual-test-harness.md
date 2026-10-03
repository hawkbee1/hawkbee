# Session 02 — Visual test harness (2D goldens + 3D screenshots)

**Branch:** `dc3d/s02-visual-tests` · **Depends on:** 01.
**Skills:** `vgv-ai-flutter-plugin:testing`, `…:material-theming`.
**Read:** `packages/flutter_scene/examples/smoke_render/` (README, `integration_test/smoke_test.dart`,
`test_driver/integration_test.dart`) and `.github/workflows/smoke_render_jobs.yml` (job `linux`)
in the submodule. They are the model for the 3D part.

## Goal

Two reusable test harnesses that every later session uses, so the owner can **see**
the UX in every PR:

1. **2D goldens** in plain `flutter test`: one call produces a screen at 3 sizes ×
   light/dark with real fonts.
2. **3D screenshots** in `integration_test` on Linux desktop under Xvfb with software
   rendering: deterministic scenes captured at 3 sizes, compared to committed
   baselines with a tolerance, plus blank-frame sanity checks.

## Part A — 2D goldens

1. Add a real font to the app as an asset (e.g. Roboto or Inter TTF, OFL/Apache
   license; commit the license file next to it) and use it in the theme.
2. `apps/dart_code_3d/test/helpers/goldens.dart`:
   ```dart
   /// Sizes every golden is rendered at (logical pixels, DPR 1).
   enum GoldenDevice { phone(Size(390, 844)), tablet(Size(820, 1180)), desktop(Size(1440, 900)); … }

   /// Pumps [builder] for each device × theme and compares with
   /// `goldens/<name>/<device>_<theme>.png`.
   void goldenTest(String name, {required Widget Function() builder, …});
   ```
   - Load the font once with `FontLoader` in `flutter_test_config.dart` so goldens show
     readable text (also load `MaterialIcons` from the Flutter SDK fonts so icons render).
   - Set `tester.view.physicalSize` / `devicePixelRatio = 1` and reset them in `addTearDown`.
   - Wrap in the app's real `ThemeData` (light and dark) and localizations.
   - Tag golden tests `golden` (`dart_test.yaml`: declare the tag).
3. Add goldens for the current screen (viewer placeholder page). Note that the 3D area
   renders blank in `flutter test`, which is expected.
4. Golden PNGs are committed. `.gitignore` the `failures/` folders.

## Part B — 3D screenshots

1. Check the system packages (see session 01 §7). If Xvfb or Mesa is missing, stop and ask.
2. `apps/dart_code_3d/integration_test/visual/visual_test.dart`:
   - `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`.
   - A list of `VisualScenario`s: `id`, a builder producing a fixed scene (for now:
     the single sphere; later sessions add fixture code maps and camera poses), and
     the device sizes to capture.
   - For each scenario × size: pump a `SizedBox(width, height)` wrapped in a
     `RepaintBoundary` with a `GlobalKey`; `await Scene.initializeStaticResources()`
     **before** building the scene; settle ~20 frames (like smoke_render); capture with
     `boundary.toImage(pixelRatio: 1)`; compute sanity stats (corners = clear color,
     center coverage > 5%, foreground mean luma > 20); send the PNG to the driver
     through `binding.reportData`.
   - Determinism: no time-based animation in scenarios, and fixed camera.
3. `apps/dart_code_3d/test_driver/visual_driver.dart`: receives the PNGs, writes them to
   `build/visual/<id>/<size>.png`, then compares each to
   `visual_baselines/<id>/<size>.png`. Compare per pixel with a per-channel tolerance
   (e.g. ≤ 8/255) and fail when more than 0.5% of pixels differ. Write a diff image
   to `build/visual/<id>/<size>_diff.png` on failure. With `--update` (env var
   `VISUAL_UPDATE=1`), copy the captures to the baselines instead.
   Use `package:image` for PNG decode/encode (dev dependency).
4. `tool/visual_test.sh` (repo root, executable):
   ```bash
   #!/usr/bin/env bash
   # Runs dart_code_3D 3D visual tests on Linux desktop with software rendering.
   # Usage: tool/visual_test.sh [--update]
   set -euo pipefail
   cd "$(dirname "$0")/../apps/dart_code_3d"
   [[ "${1:-}" == "--update" ]] && export VISUAL_UPDATE=1
   export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe
   xvfb-run -a -s "-screen 0 1600x1200x24" flutter drive \
     --driver=test_driver/visual_driver.dart \
     --target=integration_test/visual/visual_test.dart \
     -d linux --enable-impeller --enable-flutter-gpu
   ```
   Add a melos script `visual:test` that calls it.
5. Create the first baselines (`--update`), **open them with the Read tool** to check that
   a lit sphere is visible, and commit them.

## Acceptance criteria

- [ ] `goldenTest(...)` helper exists, documented, with tests for the helper itself where sensible.
- [ ] Goldens of the current page: 3 sizes × 2 themes, readable text.
- [ ] `tool/visual_test.sh` passes, and `--update` regenerates baselines.
- [ ] A deliberately broken scene (e.g. remove the mesh) makes the sanity check fail:
      try it locally and describe it in the PR, without committing it.
- [ ] `docs/dart_code_3d/architecture.md` §9 still matches what you built. If not, update it.

## Session log

_(to be filled by the agent)_
