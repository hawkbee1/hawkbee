# Session 14 — Selection, info panel, labels, search & fly-to, minimap

**Branch:** `dc3d/s14-selection-hud` · **Depends on:** 13.
**Skills:** `vgv-ai-flutter-plugin:bloc`, `…:accessibility`, `…:animations`, `…:testing`.

## Goal

The user can **identify** what they see: labels, selection with details, search, an
animated fly-to, and a 2D minimap.

## 1. Picking (pure Dart)

Instanced meshes are not individually raycastable, and our spheres are exact
spheres anyway, so pick with **our own ray–sphere intersection** over the
`VisibleWorld.visibleSpheres` (world positions + radii): `pick(ray, visible) → nodeId?`
(nearest hit; ignore the current container's shell). Build the ray from the camera
and the tap position (perspective unprojection; unit-test the math).
- Tap/click → `NodeSelected(id)`; tap on empty space → deselect.
- Keyboard: `Enter` selects the sphere under the centre crosshair; `Esc` deselects.

## 2. Info panel

Side sheet (desktop/tablet) or bottom sheet (phone):
- name, kind (icon + text), qualified name, `file:line–line`, `loc`;
- incoming / outgoing link counts by kind, with the **resolution quality** (exact /
  by name / ambiguous / external) so the user knows how far to trust the links;
- for containers: number of members / nested subclasses; for ghost parents: the
  package (or "unknown"); for external packages: "Package model not available yet";
- actions: **Fly to**, **Enter** (containers), **Show only its links** (focus mode
  from session 13), **Copy path**.
- Selected sphere gets a highlight (colour from `CodeWorldColors.selection`, slight
  scale pulse gated on `disableAnimations`).

## 3. Labels

Flutter overlay (not 3D text): project world positions to screen each frame for the
selected node + the N (default 25) nearest visible spheres in front of the camera.
Hide labels whose spheres are smaller than ~12 px on screen, and avoid overlaps
(simple greedy: sort by distance, skip a label whose rect intersects an already
placed one). Labels toggle (`L` key + HUD button) via `LabelsToggled`.

## 4. Search & fly-to

- Search field (`/` or Ctrl/Cmd+F): fuzzy match on names and qualified names over the
  whole map, results show kind + file.
- Choosing a result: **fly-to** animation that moves the camera (ease-in-out, 0.6–1.5 s
  depending on distance) through the containment path: leaves containers, then
  enters the target's ancestors, ends facing the target. It is instant if
  `disableAnimations`. Implement the path as a pure function (list of waypoints), unit-tested.

## 5. Minimap

`viewer/view/widgets/minimap.dart`: a `CustomPainter` drawing a top-down (x/z)
projection of the current container's visible spheres (circles, kind colours), the
camera position and view direction, and the selected node. Tap to fly-to the tapped
sphere. Collapsible. It is fully golden-testable, which makes it the main 2D
picture of the layout in PRs.

## Tests (100% coverage) + visual

- Unit: unprojection + ray–sphere picking, label placement, fuzzy search ranking,
  fly-to waypoints.
- Bloc + widget tests for every interaction (tap, keys, search flow, panel actions).
- Goldens (3 sizes × light/dark): info panel for each node kind (class, method,
  ghost, external, function), search results (empty, many, no match), minimap on
  the sample map (top level and inside a container), labels layer over a blank
  scene with a fake projection.
- 3D visual: `selected_class` (highlight + labels) at 3 sizes.

## Acceptance criteria

- [x] Selecting, searching and flying to any node of the sample works on Linux (unit, widget and
      3D visual tests). **Web was not run** (no browser in the dev container).
- [x] Panel reports link resolution quality.
- [x] Analyze/format clean, 100% coverage, goldens + baselines committed.

## Session log

**2026-10-04. Run by Claude (the planning model), not by a session agent.** Stacked on
session 13, now merged (branch `dc3d/s14-selection-hud` from `main`).

### Built
- **Picking** (`viewer/world/view_camera.dart`, `picking.dart`): `ViewCamera` projects a world point
  to the screen and builds the ray under a pixel (right-handed, vertical FOV, same maths as the
  GPU camera); `pick` is a ray–sphere test over the visible spheres, nearest hit, shells ignored.
  Tap selects (empty space deselects), **Enter** selects what is under the crosshair, **Esc**
  deselects. The 3D area's tap `GestureDetector` is `excludeFromSemantics`.
- **Selection in 3D** (`CodeWorld.select/highlighted`): instances cannot be outlined, so a hidden
  proxy node (an unit sphere, scaled and moved onto the selected sphere) carries
  `Node.highlightColor`, flutter_scene's screen-space outline (`scene.highlightStyle.thickness = 4`).
  The colour is `CodeWorldColors.selection`, passed as **sRGB** (the outline takes it as is). A slight
  scale pulse is skipped with `disableAnimations`.
- **Info panel** (`NodeDetails` + `InfoPanel`): name, kind (icon + text), qualified name,
  `file:line–line`, loc, members / nested types, ghost parent package, "model not available yet"
  for packages; link counts in / out **by kind and by resolution quality** (exact, by name,
  ambiguous, external); actions **Fly to**, **Enter** (containers only), **Show only its links**
  (the focus mode of session 13, now `ViewerFocusToggled` / `focusOnSelected`), **Copy path**.
  Side sheet 360 px from 720 px wide, bottom sheet (half the height, at most 420) below; the touch
  controls hide under a bottom sheet. Outlined, not shadowed.
- **Labels** (`label_layout.dart`, `LabelsLayer`): the selected sphere first, then the nearest
  visible ones in front of the camera, up to 25; spheres under ~12 px on screen get none; greedy
  overlap avoidance. `L` and a HUD button toggle them (`ViewerLabelsToggled`).
- **Search** (`SearchIndex`, `SearchOverlay`): `/` or Ctrl/Cmd+F; ranks exact, prefix, word-start,
  acronym (`wc` → `WeatherCache`), substring and subsequence matches over names and qualified
  names of the whole map, best 30, each with kind and file. Arrows move (and wrap), Enter picks the
  first or the chosen one, Esc closes. The index is built once per map (`SearchIndex.of`).
- **Fly-to** (`fly_plan.dart`, `FlyNavigator.flyAlong`, `WorldController.flyToNode`): a pure
  function turns the target into waypoints that leave the containers the camera is in, enter the
  target's ancestors and end facing it; the flight follows that polyline with the session-12
  smoothstep and `flightDuration` (0.6–1.5 s). Instant with `disableAnimations`. The navigator and
  the controller are now `ChangeNotifier`s.
- **Minimap** (`minimap_geometry.dart`, `Minimap`): a top-down circle per sphere of the current
  container in its kind color, the camera as a triangle that follows it, the selection ringed
  (the sphere that holds it when it is not drawn). **Fitted to the code only**: the package spheres
  sit far away and made the code a speck, so they are pinned as small dots on the edge where they
  lie (`MinimapProjection.place`, also what `minimapHit` taps). Collapsible; tap flies there.
- Tests: 505 unit and widget tests (100% coverage, generated `*.g.dart` excluded), 450 goldens
  (new: info panel × 7 node kinds/states, search × 4, minimap × 3, labels, selected viewer × 2),
  **8 scenarios = 48 3D captures** (new `selected_class`; `sample_start` re-baselined because the
  real view now draws labels).

### Bugs found (fixed)
- **No outline at all** on the first try: the highlight was set up inside the `scene` getter before
  `_scene` was assigned. `_updateHighlight(Scene)` is now called with the scene in hand.
- The outline came out red-orange: the colour was passed linear to a path that expects sRGB.
- **The search field never got the keyboard**: `autofocus` does not take the focus away from the 3D
  area (a real bug, found by a test that mimics it); `initState` now calls `requestFocus()`.
  The arrow keys were swallowed by the text field's own shortcuts: the handler is on the field's
  `FocusNode.onKeyEvent`.
- The panel and the search card had a harsh black outline in goldens: Material's default shadow is
  drawn hard-edged under `flutter_test`. Both use a thin `outlineVariant` border instead.
- The crosshair was drawn over the labels and crossed out a name in the middle of the view.
- `dart fix` removes the `!` of expressions whose types are still unresolved (new files before the
  first analysis): re-read the diff after it.

### Things the next agents must know
- The 3D area's `Focus` holds the keyboard; any overlay with a text field must `requestFocus()`
  itself and handle special keys on its `FocusNode.onKeyEvent`.
- `Node.highlightColor` works on **mesh nodes only**, takes sRGB as is, and `thickness` is on the
  scene's `highlightStyle`. Instances never get one: use the proxy node in `CodeWorld`.
- `WorldController.flyToNode(id)` is the one way to fly to a node (search, panel, minimap); the
  caller selects it first (`flyTo` in `viewer_page.dart`).
- `ViewerReady.visible` honours `focusOnSelected`: selecting alone no longer filters the links.
- 2D goldens must be regenerated with the **theme file unmodified**: the seed colors every golden.
- A map with only packages still fits all of them (`Minimap._fitted`).
- Not done on purpose: label collision with the HUD panels (they sit above the labels), search by
  link or by file path only.
