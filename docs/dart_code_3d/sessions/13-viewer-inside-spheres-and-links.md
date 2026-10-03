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

- [ ] Flying into a class shows its methods and nested subclasses; leaving hides them again.
- [ ] Interior/window toggle works and is visually distinct.
- [ ] Link count drawn stays bounded on AltMe (record max visible links in the log).
- [ ] Analyze/format clean, 100% coverage, goldens + baselines committed.

## Session log

_(to be filled by the agent)_
