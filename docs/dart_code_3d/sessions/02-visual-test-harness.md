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

- [x] `goldenTest(...)` helper exists, documented, with tests for the helper itself where sensible.
- [x] Goldens of the current page: 3 sizes × 2 themes, readable text.
- [x] `tool/visual_test.sh` passes, and `--update` regenerates baselines.
- [x] A deliberately broken scene (e.g. remove the mesh) makes the sanity check fail:
      try it locally and describe it in the PR, without committing it.
- [x] `docs/dart_code_3d/architecture.md` §9 still matches what you built. If not, update it.

## Session log

**2026-10-03. Run by Claude Opus 5.5 (the planning model), not by a session agent.**

### Built
- **2D goldens:** `test/helpers/goldens.dart` → `goldenTest(description, fileName:, builder:,
  devices:, themeModes:, locales:, pump:)` registers one test per device × theme × locale.
  Images go to `goldens/<fileName>/<device>_<theme>[_<locale>].png` next to the test.
  `GoldenDevice` = phone 390×844, tablet 820×1180, desktop 1440×900 (DPR 1).
  `test/flutter_test_config.dart` loads every font in `FontManifest.json` (Roboto,
  MaterialIcons). `TestTag.golden` is declared in `dart_test.yaml`, and `**/failures/` is git-ignored.
  `pumpApp` now takes `themeMode` and `locale` and uses the real `AppTheme`.
- **Font and theme:** Roboto Regular/Medium/Bold (Apache 2.0, copied from the Flutter SDK's
  material fonts, license next to them) is bundled. A minimal `AppTheme.light/dark` (seed color, Roboto)
  is used by `App`. Session 10 extends it.
- **Goldens:** viewer page loading (3 sizes × 2 themes + French phone) and ready (3 × 2).
- **3D visual tests:** `integration_test/visual/visual_test.dart` captures each
  `VisualScenario` (`visual_scenarios.dart`; for now `sphere`) at the 3 sizes × 2 themes on the
  theme's surface color, checks `FrameStats` (corners = background, center coverage > 5%,
  foreground luma > 20, exact width), and reports PNGs. `test_driver/visual_driver.dart` writes
  `build/visual/…`, compares with `visual_baselines/…` (`compareImages`: 8/255 per channel, ≤ 0.5%
  of pixels), writes `_diff.png` files, or refreshes the baselines with `VISUAL_UPDATE=1`.
  `tool/visual_test.sh [--update]` (hawkbee root) and `melos run visual:test` run it under Xvfb + llvmpipe.
- `FrameStats` and `compareImages` are plain Dart, unit-tested in `test/visual/`.

### Verified
- App: 34 tests pass (13 of them goldens), coverage 100%, analyze and format clean.
- `tool/visual_test.sh`: 6/6 pass. **Rendering is fully deterministic here: 0.000% of pixels
  differ** between runs. A run takes ~30 s.
- Negative controls (local, not committed): an empty scene fails all 6 sanity checks
  ("little or nothing drew in the center"); a red sphere instead of the blue one fails the
  comparison (54% of pixels differ) and the diff images mark the sphere in red.

### Deviations and things the next agents must know
- **`@Tags([TestTag.golden])` at library level does not work**: the test runner only accepts
  string literals there ("Expected a String literal"), even though the VGV testing skill shows
  it. `goldenTest()` tags each test instead.
- `OverflowBox` around the captured `RepaintBoundary` needs `minWidth: 0, minHeight: 0`;
  otherwise it inherits the window's tight width (1280 px) and phone/tablet captures come out
  too wide. Captures larger than the 1280×720 window work, because `toImage` renders the
  whole boundary.
- Indeterminate spinners are a dot on the first frame; goldens advance them 400 ms (`pump:`).
- **UX finding:** with the fixed 45° vertical FOV, the sphere overflows the width of a portrait
  phone (`visual_baselines/sphere/phone_*.png`). Recorded in session 11 (adapt the FOV to the aspect ratio).
- Dart 3.13 style: enum and class constructors are `new(...)`, and named factories are
  `factory of(...)` (the analyzer flags `FrameStats.of` with the type name).
- Web screenshots via the hermes-playwright container were not set up; Linux desktop under
  Xvfb is the only 3D capture path for now.
