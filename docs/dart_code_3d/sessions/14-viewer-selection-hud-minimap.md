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

- [ ] Selecting, searching and flying to any node of the sample works on Linux and web.
- [ ] Panel reports link resolution quality.
- [ ] Analyze/format clean, 100% coverage, goldens + baselines committed.

## Session log

_(to be filled by the agent)_
