# Session 11 — Viewer foundation: load a code map, render spheres, start at the entry point

**Branch:** `dc3d/s11-viewer-foundation` · **Depends on:** 02, 03, 08, 10 (09 helps).
**Skills:** `vgv-ai-flutter-plugin:bloc`, `…:testing`, `…:layered-architecture`.
**Read first:** in `packages/flutter_scene/packages/flutter_scene/skills/`:
`flutter_scene-idioms/SKILL.md` + `references/what-exists.md` + `references/architecture.md`,
and `flutter_scene-performance/SKILL.md`. Also `architecture.md` §7.

## Goal

Open a `.dc3d` code map and see the **top level of the world**: one sphere per
top-level node, sized and coloured by kind, with the camera in front of the entry
node. Render with **GPU instancing** from the start (decided: AltMe has ~1–2k top-level
spheres and up to thousands inside large containers; instancing collapses them to a
few draws, per the flutter_scene performance skill).

## 1. Sample data

- Add `apps/dart_code_3d/assets/samples/sample.dc3d`, produced with the engine CLI
  (`--layout --out`) from the engine fixture `vgv_feature` (or a slightly larger
  hand-made fixture with ~40 classes so it looks like an app). Document the exact
  command in `assets/samples/README.md`.
- Home gets an **"Open sample"** action (all flavors; useful for demos).
- For performance work only: in the **development** flavor, `--dart-define=DC3D_OPEN=<path>`
  opens a local `.dc3d` at startup (native only). Never ship it in production.

## 2. Business logic (`viewer/bloc/`)

`ViewerBloc`:
- events: `ViewerOpened(CodeMapSource)` (asset/bytes), `ContainerChanged(String? id)`,
  `NodeSelected(String? id)`, `ViewModeToggled()`, `LinkKindToggled(LinkKind)`,
  `LabelsToggled()` (the last four are only stored for now; sessions 13–14 use them);
- state: sealed `ViewerLoading` / `ViewerReady(map, currentContainerId, selectedId,
  viewMode, visibleLinkKinds, labelsOn)` / `ViewerFailure(message)`.
- Decoding big maps must not freeze the UI: decode in `compute`/isolate on native
  (through `CodeMapRepository.open`, or a small decode helper in the app if session 09
  is not merged; note that in the log).

## 3. Presentation (`viewer/view/`, `viewer/world/`)

- `ViewerPage` (provides the bloc) / `ViewerView` (renders state).
- `CodeWorld` (`viewer/world/code_world.dart`): a plain Dart class that owns the
  `Scene` (imperative style from the idioms skill):
  - `Future<void> load(CodeMap map, CodeWorldColors colors)` after
    `Scene.initializeStaticResources()`;
  - computes **world positions** from relative placements (pure function in
    `viewer/world/world_transforms.dart`, unit-tested);
  - builds one `InstancedMesh(geometry: shared IcosphereGeometry or SphereGeometry,
    material: shared PhysicallyBasedMaterial)` per visible set, `addInstance(matrix,
    color: kindColor)` per sphere (scale = radius). Check the exact `InstancedMesh`
    and `addInstance` signatures in `what-exists.md` / the source; do not guess;
  - this session renders the **top level only** (children appear in session 13);
  - environment: soft studio lighting, background from `CodeWorldColors`, light and dark;
    keep post-processing minimal (performance skill step 4).
- Camera: `PerspectiveCamera` positioned at `entryPosition + (0, r, 3r)` looking at the
  entry node (r = its radius, with sensible minimum). No navigation yet (session 12).
  **Adapt the field of view to the aspect ratio.** `PerspectiveCamera.fovRadiansY` is a
  *vertical* FOV (45° by default), so on a portrait phone the scene gets cropped left and
  right. Session 02's `sphere/phone_*` baselines show it: the sphere fills the width.
  Keep a minimum *horizontal* FOV (e.g. ~60°) by computing
  `fovY = 2·atan(tan(fovX/2) / aspect)` when the view is taller than wide, and add the
  phone-size captures to the visual tests to prove it.
- Debug overlay (development flavor, toggle with F3): fps, frame build/raster times
  (`SchedulerBinding.addTimingsCallback`), instance count, draw count if available.

## 4. Measure (record everything in the session log)

On Linux desktop (profile build, Xvfb + llvmpipe is a *lower bound*) and the web
build, with the sample, the flutter_scene map and the AltMe map (built with the CLI):
load time (decode + scene build) and frame times. Write instructions in the PR for the
owner to run the profile build on a phone and in a browser, and ask for the numbers.

## Tests (100% coverage) + visual

- Unit: world transform math, colour mapping, camera start pose (incl. missing entry → origin).
- Bloc tests; widget tests of loading/failure/ready states (the 3D area itself is blank
  in widget tests).
- Goldens (3 sizes × light/dark): loading, failure ("This file is not a code map" with
  action), ready HUD over the (blank) scene area.
- **3D visual tests** (session 02 harness): scenario `sample_start` = sample map at the
  start pose, 3 sizes, light + dark. Look at the baselines yourself before committing.

## Acceptance criteria

- [x] Sample opens and shows the top level with the entry node in view, on Linux and web. (Linux: 3D visual test; web: release build compiles, the owner checks it in a browser.)
- [x] Instanced rendering; the instance count matches the top-level node count (tested via `CodeWorld` API).
- [x] Measurements recorded; the owner was asked for device numbers (in the PR).
- [x] Analyze/format clean, 100% coverage (exclude only genuine GPU glue, with comments).

## Session log

**2026-10-04. Run by Claude (the planning model), not by a session agent.** Stacked on
session 10 (branch created from `dc3d/s10-settings`).

### Built
- **Sample**: `assets/samples/sample.dc3d`, a hand-written weather app (46 top-level
  declarations, 155 nodes, 108 links, 4 external packages). Its source is a single text bundle,
  `tool/sample/sample_source.txt`, so no stray `.dart` or `pubspec.yaml` files sit in the app.
  `tool/sample/build_sample.sh` unpacks it and runs the engine and layout CLIs. Home: **Open
  sample** replaces the session 01 "3D demo".
- **`ViewerBloc`** (sealed `ViewerLoading` / `ViewerReady` / `ViewerFailure`, every event from
  the plan) decodes through the new `CodeMapRepository.openBytes` (code_map_repository PR,
  isolate on native). Asset and local file bytes are read through injected functions.
- **`CodeWorld`**: positions (`world_transforms.dart`), instances (`sphere_instance.dart`, sRGB
  theme colors converted to linear), start pose and FOV (`camera_pose.dart`), and the scene:
  **one `InstancedMesh`** (`SphereGeometry` 48×24, shared `PhysicallyBasedMaterial`) for the
  top level. Everything but the scene is plain Dart, so it is unit-tested.
- **Camera**: `entry + (0, r, 3r)` with `r = max(radius, 1.5)`, origin without an entry node.
  **FOV adapts to the aspect ratio**: `fovY = max(45°, 2·atan(tan(30°)/aspect))`, so portrait
  screens keep 60° horizontally (visible in the `sample_start/phone_*` baselines).
- `ViewerView`: loading, failure ("This file is not a code map" + details + Back to home) and
  ready (3D area + HUD with node and link counts); **F3** debug overlay in the development flavor
  (fps, median build/raster times, sphere count).
- Development flavor: `--dart-define=DC3D_OPEN=<path>` opens `/viewer?file=<path>` at startup
  (ignored in other flavors). `AppFlavor` is provided by `App`; `bootstrap.dart` has
  `buildApp(flavor)` so the three `main_*.dart` files no longer repeat the wiring.
- 3D visual scenario **`sample_start`** (3 sizes × light/dark). The capture background is now the
  world background (`CodeWorldColors.background`), so the `sphere` baselines were refreshed too.
  Scenarios gained `clearCorners` (false for a world that reaches the edges).
- `integration_test/perf` + `tool/perf_test.sh`: opening time and frame times in a profile build.
- Tests: 100 unit/widget tests (100% coverage, `*.g.dart` excluded; only `CodeWorld.scene` and
  `buildCodeWorldScene` are GPU glue, marked `coverage:ignore`), 102 goldens, 14 3D captures.

### Measured (2026-10-04, this container: profile build, Xvfb + Mesa llvmpipe, 1440×900)
| Map | Nodes | Top-level spheres | Open (decode, isolate) | Scene build | Start view fps | UI build (median) | Raster (median) |
|---|---|---|---|---|---|---|---|
| sample | 155 | 30 | 16 ms | < 1 ms | 59 (vsync) | 0.39 ms | 7.6 ms |
| AltMe | 11,012 | 439 | 1.01 s | 1 ms | 26 | 0.39 ms | 4.6 ms |
| flutter_scene | 11,050 | 2,542 | 1.14 s | 4 ms | 9.4 | 0.39 ms | 4.2 ms |

- The UI thread is idle (0.4 ms). The low fps on big maps comes from llvmpipe rasterizing
  ~2,300 triangles per sphere on the CPU (flutter_scene: ~5.9 M triangles per frame). The frame
  phases do not include that wait, so judge by fps here. A real GPU should be far faster: device
  numbers were requested from the owner.
- Web: `flutter build web --release` builds; no browser in this container to measure.

### Things the next agents must know
- **Performance (session 16)**: if devices confirm the cost, draw small or far spheres with a
  low-poly geometry (a second `InstancedMesh` per tessellation level). flutter_scene's
  `LodComponent` works on meshes, not instanced batches. Only the top level is drawn today, but
  entering a big container (session 13) can also show thousands of children.
- flutter_scene's `PerspectiveCamera` defaults to `fovFar = 1000`: `CodeWorld.camera` sets the
  far plane from the world radius (AltMe's world is a few hundred units wide).
- `CodeWorldView` rebuilds the `CodeWorld` (and its `Scene`) only when the map instance or the
  theme colors change.
- Unnamed factory constructors in Dart 3.13 are written `factory (…)`.
- Phones have no F3: measure on devices with DevTools (profile build), or run the perf test on
  the device (`flutter drive --profile … -d <device>`; it measures the bundled sample).
