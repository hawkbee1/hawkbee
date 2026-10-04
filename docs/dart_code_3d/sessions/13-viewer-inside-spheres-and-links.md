# Session 13 — Entering spheres, interior/window view, visibility, links

**Branch:** `dc3d/s13-inside-spheres` · **Depends on:** 12.
**Skills:** `vgv-ai-flutter-plugin:testing`.
**Read:** `architecture.md` §1 (entering spheres) and §7.3. In the submodule's
`what-exists.md`: `LineSegmentsGeometry`, `PolylineGeometry`, material blending /
transparency and face culling (find the exact property names for alpha blending and
double-sided / back-face rendering; do not guess).

## Goal

Flying into a sphere reveals what is inside. Inside, the user toggles **interior
view** / **window view** (key `V` + HUD button). Calls are drawn as **links**, limited
to what the current context needs.

## 1. Visibility resolver (pure Dart, the core of this session)

`viewer/world/visibility.dart`:

```dart
class VisibleWorld {
  final List<String> openContainers;   // ancestors of the camera, outermost first
  final List<String> visibleSpheres;   // drawn as closed spheres
  final List<VisibleLink> links;       // aggregated
}
class VisibleLink { final String fromId; final String toId; final LinkKind kind; final int count; final bool aggregated; }

VisibleWorld resolveVisibility({required CodeMap map, required String? containerId,
    required ViewMode mode, required Set<LinkKind> linkKinds, String? selectedId});
```

Rules (`architecture.md` §7.3):
- **Interior view**: visible = children of the current container. The container's
  shell is drawn from inside as a dome.
- **Window view**: visible = children of the current container + for each open
  ancestor, its children (as closed spheres) + the top level. The shells of open
  containers are drawn nearly transparent.
- Top level (no container): visible = top-level nodes; mode is irrelevant.
- **Links**: take every link of an enabled kind. Map each endpoint to its **nearest
  visible representative** (the node itself if visible, else its closest visible
  ancestor). Drop links whose two representatives are equal, or where neither endpoint
  maps to anything visible. Merge duplicates by summing counts (`aggregated: true` if
  any endpoint was remapped). If `selectedId` is set, keep only links touching the
  selected node's representative (focus mode).
- Performance: AltMe has up to ~100k links. Precompute per-node ancestor chains once
  per map, and make `resolveVisibility` < 30 ms for AltMe (benchmark test, tag `slow`).

## 2. Rendering in `CodeWorld`

- Rebuild instance buffers when `VisibleWorld` changes (container change, mode toggle,
  link toggles). The bloc computes `VisibleWorld` (pure) and the view passes it to `CodeWorld`.
- Sphere materials: closed spheres are opaque. The **current container shell**:
  interior view = back-face rendered, slightly tinted dome; window view = alpha ≈ 0.08
  plus a faint rim. Ghost parents always look distinct (lighter, translucent, dashed-looking
  rim if feasible). External packages are solid with a different material (e.g. metallic).
- Links: one `LineSegmentsGeometry` per `LinkKind` (colour from `CodeWorldColors`),
  width growing with `log(1 + count)` if per-segment width is possible, else
  2–3 width buckets. Links to/from external packages are dashed or dimmer. Ambiguous links
  are dimmer.
- Smooth transition when entering/leaving (fade the shell over ~200 ms). Gate it on
  `MediaQuery.disableAnimations`.

## 3. HUD

- Breadcrumb at the top: `World › UserRepository › CachedUserRepository` (open
  containers). Tapping a crumb flies out to that level (camera animation: move to just
  inside that container's shell, or just outside it for "World").
- View-mode toggle button (interior/window) shown only inside a container; key `V`.
- Link legend with per-kind toggles (filter chips), wired to `LinkKindToggled`.

## Tests (100% coverage) + visual

- `resolveVisibility` exhaustive unit tests on a handmade nested map: each mode,
  remapping to ancestors, aggregation counts, focus mode, toggled kinds, ghost parent
  and external package endpoints.
- Bloc: container/mode/link toggles produce the right `VisibleWorld`.
- Goldens: breadcrumb (short + very long names, truncation), legend, mode toggle,
  at 3 sizes × light/dark.
- 3D visual scenarios: `inside_interior` (camera inside a class with members and a
  nested subclass), `inside_window`, `links_top_level`, `links_focus_selected`,
  each at 3 sizes. Check every baseline visually and describe each one in the PR.

## Acceptance criteria

- [x] Flying into a class shows its methods and nested subclasses; leaving hides them again.
- [x] Interior/window toggle works and is visually distinct.
- [x] Link count drawn stays bounded on AltMe (record max visible links in the log).
- [x] Analyze/format clean, 100% coverage, goldens + baselines committed.

## Session log

**2026-10-04. Run by Claude (the planning model), not by a session agent.** Stacked on
session 12 (branch `dc3d/s13-inside-spheres`, created from `dc3d/s12-fly-navigation`).

### Built
- **`viewer/world/visibility.dart`**: `resolveVisibility` as specified, over a `VisibilityIndex`
  (ancestor chains, built once per map by `VisibilityIndex.of(map)` and shared by the bloc state and
  the 3D world) and `ViewMode` (moved here from the bloc). `VisibleLink` also carries `dim`
  (every merged link is ambiguous or external). `ViewerReady.visible` derives it from the state and
  is computed once per state.
- **Rendering** (`CodeWorld.show(visible, mode)`, content built by the pure `buildSceneContent`):
  one `InstancedMesh` per material: solid (declarations and members), **metallic** (external
  packages), **translucent** (ghost parents, alpha 0.35). One `LineSegmentsGeometry` per
  link kind × width bucket (1, 2–4, 5+ merged links) × dim. Links run from sphere surface to
  sphere surface, dimmer for ambiguous and external ones (no dashes).
- **Shells**: the current container is a dome seen from inside (tinted, alpha 0.25 in interior
  view); window view draws every open shell at alpha 0.08. They fade in over 0.2 s, or appear at
  once when `MediaQuery.disableAnimations`.
- **Link width follows the camera**: about two pixels wide on screen (0.2% of the distance to the
  middle of what is drawn), never thinner than 3% of the typical sphere nor wider than 1% of the
  level. A width fixed in world units was a hairline from far away and a fat ribbon next to
  `main()` (seen in the `sample_start` baseline).
- **HUD**: `Breadcrumb` (`World › UserRepository › CachedUserRepository`; names cut after 160 px, a
  long path wraps), `ViewModeToggle` (inside a sphere only; key `V`), `LinkLegend` (a chip per link
  kind **the map has**, in its link color), all on translucent `HudPanel`s.
- **Flying out**: tapping a crumb flies the camera there (`FlyNavigator.flyTo`: smoothstep, input
  takes the camera back, pushed out of packages on the way; instant with disabled animations).
  `exitPose` picks where to land: 94% of the radius inside a container, or 2.2 radii outside the
  top-level sphere for "World", on the camera's side when that is free and otherwise on the first
  Fibonacci direction that really is inside (not inside a child or a neighbour).
  `WorldController` lets the HUD drive the camera of a `CodeWorldView` it does not own.
- Sample: `WeatherCache` now has a nested subclass (`PersistentWeatherCache`) next to its three
  methods (159 nodes, was 155), so the layout, `sample_start` and `fly_path` baselines moved.
- Tests: 248 unit and widget tests (100% coverage; only the GPU glue is marked), 178 goldens,
  **7 scenarios = 42 3D captures** (new: `links_top_level`, `links_focus_selected`,
  `inside_interior`, `inside_window`), 2 `slow` benchmarks (+1 on a real map).
  Run one 3D scenario with `DC3D_SCENARIO=<id> tool/visual_test.sh`.

### Measured
`resolveVisibility`, median of 15 runs, Dart VM in `flutter test`:

| Map | Nodes | Links | Top level | Inside a class | Window view | Focus mode | Index (once) |
|---|---|---|---|---|---|---|---|
| synthetic, AltMe-sized | 10,500 | 7,400 | 2.2 ms | 1.3 ms | 2.5 ms | 1.5 ms | 6 ms |
| **AltMe** (real) | 11,012 | 7,414 | 1.5 ms | 1.0 ms | 1.7 ms | 1.1 ms | 5 ms |
| flutter_scene (real) | 11,050 | 17,609 | 3.8 ms | 1.8 ms | 3.4 ms | 2.3 ms | 2 ms |
| synthetic stress | 10,500 | 100,000 | 47–60 ms | 14 ms | 47–55 ms | 14–16 ms | 4 ms |

**Maximum links drawn** (the top level and the first 400 containers, both views): **AltMe 1,543**,
flutter_scene 5,434; with the synthetic 100,000 random links (no clustering) 97,672. Real code
clusters, so aggregation keeps the count low; there is **no cap** yet.
Profile start-view frame rates on the large maps are unchanged from session 11 (AltMe 24 fps,
flutter_scene 9 fps under llvmpipe, UI thread 0.5 ms): links and the extra materials cost almost
nothing next to rasterizing the spheres on the CPU.

### Bugs found (fixed)
- **Session 12's own unit test was stale.** After the `fly_path` baselines I lowered `baseSpeed`
  (5 → 2.5) without re-running the unit tests, so "stops at the surface of external package
  spheres" no longer reached the sphere in one second. Fixed on `dc3d/s12-fly-navigation` (and
  here): the test flies for 3 s.
- **A blended material ignores `doubleSided`** (`material.dart`: `doubleSided` only applies to
  opaque materials), so a translucent dome was invisible from inside. Fix: `invertedFaces`, a
  sphere whose normals and winding are reversed, so its inner faces are the front ones.
  `MeshData.transformed` with a mirror matrix does **not** do it: it compensates the winding of
  the mirror and gives an ordinary outward sphere again.
- New shells flashed at full opacity for a frame before fading in: they now start from the
  animation state.
- A `Semantics(container: true)` region merged its children's labels into one node, so crumbs
  and chips were not separate for screen readers: `explicitChildNodes: true`.

### Things the next agents must know
- **Selection (session 14)**: `ViewerNodeSelected` already drives focus mode (only the links
  touching the selected sphere's visible representative are drawn; a selection that is not visible
  is ignored, all links show). Nothing highlights the selected sphere yet: spheres are instances,
  so a highlight needs its own sphere or ring.
- `CodeWorld.tick(dt, animate:, cameraPosition:)` also sizes the links: a capture or test that
  builds a scene without ticking must call `tick(0, animate: false, cameraPosition: …)` first
  (the 3D scenarios do).
- `LineSegmentsGeometry.width` can change per frame (it rebuilds the bounds, O(segments)), so
  `tick` only sets it when it differs by more than 10%.
- 3D baselines do not depend on the theme seed (the world colors are `CodeWorldColors`); the 2D
  goldens do.
- If a device struggles with links on a big map, cap the segments (strongest first) in
  `resolveVisibility` and say so in the HUD; session 16 decides with the device numbers.
- Window view shows the top level and the open ancestors' children as **closed** spheres only: it
  does not open their children (by design, `architecture.md` §7.3).
