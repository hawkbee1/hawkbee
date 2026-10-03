# Session 11 — Viewer foundation: load a code map, render spheres, start at the entry point

**Branch:** `dc3d/s11-viewer-foundation` · **Depends on:** 02, 03, 08, 10 (09 helps).
**Skills:** `vgv-ai-flutter-plugin:bloc`, `…:testing`, `…:layered-architecture`.
**Read first:** in `packages/flutter_scene/packages/flutter_scene/skills/`:
`flutter_scene-idioms/SKILL.md` + `references/what-exists.md` + `references/architecture.md`,
and `flutter_scene-performance/SKILL.md`. Also `architecture.md` §7.

## Goal

Open a `.fscene` code map and see the **top level of the world**: one sphere per
top-level node, sized and coloured by kind, with the camera in front of the entry
node. Render with **GPU instancing** from the start (decided: AltMe has ~1–2k top-level
spheres and up to thousands inside large containers; instancing collapses them to a
few draws, per the flutter_scene performance skill).

## 1. Sample data

- Add `apps/dart_code_3d/assets/samples/sample.fscene`, produced with the engine CLI
  (`--layout --out`) from the engine fixture `vgv_feature` (or a slightly larger
  hand-made fixture with ~40 classes so it looks like an app). Document the exact
  command in `assets/samples/README.md`.
- Home gets an **"Open sample"** action (all flavors; useful for demos).
- For performance work only: in the **development** flavor, `--dart-define=DC3D_OPEN=<path>`
  opens a local `.fscene` at startup (native only). Never ship it in production.

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

- [ ] Sample opens and shows the top level with the entry node in view, on Linux and web.
- [ ] Instanced rendering; the instance count matches the top-level node count (tested via `CodeWorld` API).
- [ ] Measurements recorded; the owner was asked for device numbers.
- [ ] Analyze/format clean, 100% coverage (exclude only genuine GPU glue, with comments).

## Session log

_(to be filled by the agent)_
