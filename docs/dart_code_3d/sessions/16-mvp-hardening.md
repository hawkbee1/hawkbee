# Session 16 — MVP hardening: AltMe end-to-end, performance, accessibility, docs

**Branch:** `dc3d/s16-mvp-hardening` · **Depends on:** 01–15.
**Skills:** `vgv-ai-flutter-plugin:green-gate`, `…:accessibility`, `…:static-security`,
`…:license-compliance`, `vgv-wingspan:review`.

## Goal

Prove the MVP works on the **reference project AltMe**, fix what that reveals, and
leave the project documented and green.

## Checklist

1. **AltMe end-to-end** in the app (Linux desktop), using the analysis flow with
   `https://github.com/TalaoDAO/AltMe` (default branch): record fetch, analysis,
   layout and save times, node and link counts, file size, load time in the viewer,
   frame times at the top level and inside the largest container. Do the same with
   flutter_scene. Compare with the budgets in `architecture.md` §1 and §7.3 and fix
   the biggest gap first (profile before optimizing; follow `flutter_scene-performance`).
2. **Web build** (`flutter build web --release`, also try `--wasm`): open the AltMe
   `.dc3d` exported in step 1. Record load time and frame times in Chromium (via the
   hermes-playwright container if the owner has set up remote access, otherwise ask the
   owner to measure in their browser).
3. **Phones**: ask the owner to run a profile build on the Android phone and the iPhone 11
   with the AltMe map, and to report fps (the debug overlay shows it). Fix blocking issues.
4. **Accessibility pass** (`accessibility` skill) on every 2D screen: semantics, focus
   order, contrast in both themes, text scale 2.0, keyboard-only use of home/settings/
   analysis. The 3D world itself is exempt, but the info panel and search must work
   with screen readers.
5. **Security pass** (`static-security` skill): zip extraction limits, URL handling,
   no secrets, no logging of file contents.
6. **License check** (`license-compliance` skill) of all dependencies, including the
   bundled font.
7. **Green gate** on every package we own: analyze, format, tests, 100% coverage, and
   all goldens and 3D baselines up to date.
8. **Docs**:
   - `apps/dart_code_3d/README.md`: what the app does, how to run it per platform
     (Flutter GPU flags), how to run tests, goldens and `tool/visual_test.sh`, how to
     use the engine CLI;
   - update `architecture.md` wherever reality diverged (every deviation recorded in
     session logs);
   - update `future.md` with everything postponed during sessions 01–15.
9. Run `vgv-wingspan:review` on the whole `dart_code_3d` area. Fix what's actionable
   and list the rest in the PR.

## Acceptance criteria

- [x] AltMe analyzable and flyable in the app: analyzed from GitHub through the UI on Linux, opened
      in 3D (numbers below). Flown on a real GPU: **not done**, see "Measured".
- [x] Web build opens an AltMe map (Chromium, software WebGL, in the dev container): 5.3 s to open,
      but **2.9 fps** there: a software-rendering floor, **to be measured by the owner in a browser
      with a GPU**.
- [x] Every package green (table below).
- [x] Docs updated (`apps/dart_code_3d/README.md`, `architecture.md` §12), `future.md` complete.

Not done, because it needs the owner: the **phone runs** (item 3: Android phone and iPhone 11,
profile build, F3 overlay) and a **browser measurement on real hardware**.

## Session log

**2026-10-04. Run by Claude (the planning model), not by a session agent.** Stacked on
session 15 (branch `dc3d/s16-mvp-hardening` from `dc3d/s15-analysis-flow`).

### Measured

All on Linux in the dev container, **software rendering** (Mesa llvmpipe under Xvfb, 1440×900, profile
build): a lower bound that shows where the work goes, not what a device does.

**AltMe end to end through the UI** (`DC3D_E2E_URL=https://github.com/TalaoDAO/AltMe
tool/e2e_test.sh`, default branch): 11,012 nodes, 7,414 links, **1.50 MB**; **71.7 s** from Analyze to the
viewer: fetch **61.8 s** (the download from GitHub, the network of this container), analysis 0.5 s
by the progress events, layout **9.1 s**, encoding and saving 0.2 s. flutter_scene @
`flutter_scene-0.23.0`: 11,050 nodes, 17,609 links, **1.64 MB**; **25.6 s**: fetch 12.9 s, analysis
1.3 s, layout 11.2 s, saving 0.2 s. Decoding the map in the viewer takes about 1.1 s for both (off
the UI thread in the app).

**Frame rate** (`tool/perf_test.sh`, 5 s of frames, at the start view and inside the container with
the most members), before the changes of this session → after:

| Map | Top level | Inside the busiest container |
|---|---|---|
| sample (159 nodes) | 53.2 → 58.8 fps | StatelessWidget (14): 18.0 → 22.8 |
| AltMe | 24.6 → **36.6** | AppLocalizations (1,038): 6.4 → **16.8** |
| flutter_scene | 8.4 → **27.2** | PhysicallyBasedMaterial (227): 7.2 → 9.2 |

The UI thread is not the limit (build 0.5 ms median); the rasterizer is. Profiling by experiment:
the cost followed the **triangle count** (every sphere was 48×24 = 2,300 triangles, 5.8 M per frame
on flutter_scene), then the full-screen PBR dome.

**Web** (`flutter build web --release` and `--wasm`, both compile; `tool/web_perf.mjs`, Playwright
Chromium with software WebGL, 1440×900): AltMe opens in **5.3 s** (7.2 s with `--wasm`) and flies at
**2.9 fps** (median frame 350 ms), the same for both builds: the software WebGL is the limit.

### Changed
- **Sphere level of detail** (`SphereDetail`, `CodeWorld`): three instanced meshes per material (12×6,
  24×12, 48×24), the spheres dealt out by `radius / distance` (about 20 and 80 px across), at most ten
  times a second. A flat 32×16 was faster still but a sphere filling the screen showed polygon edges
  (seen in the `inside_interior` capture): the detail has to follow the size on screen.
- **Shells are unlit flat tints** (were PBR): the dome covers the screen, and shading it was a cost
  for nothing. `inside_interior` and `inside_window` baselines moved (a flatter tint); the other 3D
  baselines did not.
- **Perf harness**: also measures inside the busiest container. **E2E**: records stage times and counts
  and copies the map; `tool/web_perf.mjs` is new.
- **Security** (`static-security` checklist): `AppBlocObserver` logged `$change`, and in debug builds
  Equatable prints every field, so it dumped whole decoded maps and a picked zip's bytes into the log
  (and took seconds): it logs types only now, tested. `android:allowBackup="false"` (the stored maps
  hold users' code). Checked and fine: zip entries (absolute paths, `..`, symlinks refused; archive
  and extracted size limits), local folders (links not followed), only HTTPS to GitHub/GitLab hosts
  from a validated URL, store ids cannot leave their folder, no secrets, no sensitive data in
  `SharedPreferences` (theme, rules, touch mode only), no `badCertificateCallback`.
- **Accessibility** (WCAG 2.2 **AA**, assumed: nobody was there to ask; all platforms): failure
  titles are live regions and headings, the running stage is announced, titles are headings. New
  `test/a11y`: contrast, tap target and label guidelines on home, new analysis and settings in both
  themes at text 1× and 2×; the theme's text colors at 4.5:1; keyboard-only use of the form and the
  cancel dialog. Flutter's contrast guideline reads the wrong pixels on a text field's helper text
  (its rectangle is in the field's own coordinates), so the form's text is checked from the theme.
  The 3D world is exempt; the info panel and search have semantics (session 14).
- **Licenses**: `very_good packages check licenses` passes (26 direct: BSD-3 and MIT). All 186 hosted
  packages of the lockfile read as BSD (124), MIT (48) or Apache-2.0 (13), plus **`dbus` 0.8.0, MPL-2.0**
  (weak, file-level copyleft; fine unmodified), which `file_picker_linux` brings. The bundled Roboto is
  Apache-2.0 with its license file in `assets/fonts`.

### After the review: room to fly inside spheres
The owner found the spheres inside a sphere too big to fly between. `scaleNested` (applied when the
viewer opens a map) draws every level of nesting at half the size of the level above, and the same
rule again for what those contain: top-level spheres unchanged, their children ×0.5, theirs ×0.25.
Offsets inside a parent shrink with the parent, so children keep their places and each container keeps
its size. Because levels get small fast, the near plane (`nearDepthFor`) and the speed floor now follow the
current sphere. Existing stored maps need no re-analysis. `inside_interior` and `inside_window`
baselines were refreshed (I looked at before and after); 2D goldens: `viewer_inside_window` and
`minimap_inside`.

### Green gate
| Package | Tests | Coverage |
|---|---|---|
| code_graph | 64 | 100% |
| code_source_client | 73 (+1 network, opt-in) | 100% |
| code_layout | 29 | 100% |
| code_analysis_engine | 98 | 100% |
| settings_repository | 8 | 100% |
| code_map_repository | 40 | 100% |
| dart_code_3d | 758 (+430 goldens, 48 3D captures, 1 e2e) | 100% |

Analyze (`--fatal-infos`) and format are clean everywhere.

### Review
A self-review against the VGV standards (no sub-agent was run). Fixed: the logging and backup
findings above. Left, listed for the PR: `NewAnalysisPage` and `HomePage` read services from the
context in `create` (the repository pattern, fine) but have no widget-level test of "storage
failure while listing" beyond the failure state; the e2e fills the form's controllers directly
because `enterText` does not reach a field in a live Linux run (typing is covered by widget tests).

### Things the next agents must know
- Measure on real hardware before optimizing further (`future.md`): software rendering rewards fewer
  triangles and pixels, a GPU may not.
- A `CodeWorld` must not touch the GPU in its constructor or in a field initializer: unit tests build
  one. Anything that needs the GPU is lazy and inside the `coverage:ignore` block.
- A `Bloc` keeps the `Bloc.observer` in place when it is created; set it first in tests.
