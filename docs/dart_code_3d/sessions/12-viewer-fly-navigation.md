# Session 12 — Fly mode: keyboard, touch trackball, collisions, adaptive speed

**Branch:** `dc3d/s12-fly-mode` · **Depends on:** 11.
**Skills:** `vgv-ai-flutter-plugin:testing`, `…:accessibility`.
**Read:** `packages/flutter_scene/packages/flutter_scene/lib/src/camera_controllers/fly_camera_controller.dart`
and `camera_controller.dart` in the submodule. Also `architecture.md` §7.2.

## Goal

The user flies through the world on every platform.

## 1. Navigation model (pure Dart, testable without GPU)

`viewer/navigation/fly_navigator.dart`:
- wraps flutter_scene's `FlyCameraController` (use it, don't rewrite it). Its
  default keys are WASD/QE/Shift; we map **our** inputs onto its API ("call `look`
  and set the move keys directly", per its doc comment). Read the source to find the exact methods;
- input state: `forward`, `back`, `left`, `right`, `up`, `down`, `boost`, `lookDelta`;
- `speed` = `baseSpeed × clamp(currentContainerRadius / 10, 0.05, 50)`, so flying
  inside a tiny class is as comfortable as flying across the whole world (the container
  radius comes from the bloc's `currentContainerId`, or the world radius at top level);
- **collisions** with `externalPackage` spheres: after each step, if the camera is
  inside `radius + margin` of a package sphere, push it back to the surface (pure
  function `resolveCollisions(position, obstacles)`, unit-tested). Package spheres are
  the only solid ones;
- the containing sphere is detected each frame (`findContainer(position, map)` = deepest
  enterable sphere containing the point). When it changes, add `ContainerChanged` to the
  bloc, throttled (no more than once per frame, only on change).

## 2. Desktop / web keyboard + mouse

| Input | Action |
|---|---|
| ↑ / ↓ | forward / back |
| ← / → | strafe left / right |
| Page Up / Page Down (also Q / E) | up / down |
| Shift | boost |
| Mouse drag (or right-drag) | look |
| `Home` | return to the start pose |

Implement with a `Focus` + `onKeyEvent` around the scene (handle key down/up and
repeat), so the arrow keys don't move focus to other widgets. The scene area must
request focus when the viewer opens and when it is clicked.

## 3. Touch: trackball + move control

- Show touch controls on Android/iOS, and anywhere when no hardware keyboard has been
  used yet and the last pointer was touch. A settings toggle "Touch controls: auto /
  always / never" goes in the settings screen (add it to `SettingsRepository`).
- **Trackball** (bottom-right): a circular pad; dragging inside it rotates the view
  (yaw/pitch proportional to the drag vector, continuous while held). Also allow
  one-finger drag anywhere on the scene to look.
- **Move control** (bottom-left): a vertical slider/joystick: up = forward, down = back,
  with proportional speed; plus two small buttons for up/down.
- Semantics labels, 48 px minimum targets, and haptic feedback on press (mobile).

## Tests (100% coverage) + visual

- Unit: input → pose after `dt` (forward moves along the look direction, strafe ignores
  pitch, boost multiplies), adaptive speed, collisions (inside, on the surface, multiple
  obstacles), `findContainer` (nested spheres, ghost parents count as enterable, packages don't).
- Widget: key events change the navigator's input state; focus handling; trackball and
  slider gestures (`tester.drag`) change look/move; settings toggle.
- Goldens (3 sizes × light/dark): viewer with touch controls visible (phone + tablet),
  without (desktop), the keyboard help overlay (`?` key or help button).
- 3D visual: scenario `fly_path`, a scripted input sequence from the start pose
  (e.g. forward 2 s, turn right 45°, forward 1 s) with a **fixed time step**
  (drive the navigator manually, not with real time). Capture the end frame at 3 sizes.

## Acceptance criteria

- [x] Arrow-key flight works on Linux desktop and web. Touch controls work (verified with widget tests; ask the owner to try on a phone).
- [x] The camera cannot enter external package spheres.
- [x] Analyze/format clean, 100% coverage, goldens and visual baselines committed.

## Session log

**2026-10-04. Run by Claude (the planning model), not by a session agent.** Branch
`dc3d/s12-fly-navigation` (the plan said `dc3d/s12-fly-mode`), created from
`dc3d/s11-viewer-foundation`.

### Built
- `viewer/navigation/fly_navigator.dart`: `FlyNavigator` wraps flutter_scene's
  `FlyCameraController`, attached to a plain `Node` and **stepped manually**
  (`step(dt)`). Our inputs (`NavigationInput`: forward/back/left/right/up/down/boost, a
  `throttle` for the touch slider, a `lookRate` for the trackball) are turned into the
  controller's own key events (it only takes `KeyEvent`s). `speed` follows the plan
  (`baseSpeed × clamp(radius / 10, 0.05, 50)`), with **`baseSpeed` = 2.5**: crossing any sphere
  takes about 8 s. At 5, the sample's top level (radius 79 because of the package shell) flew at
  39 units/s past everything.
- `collisions.dart`: `resolveCollisions` pushes the camera to `radius + 0.25` from every
  external package sphere (4 passes for touching obstacles). Pressing on, the camera slides
  along the surface and never enters.
- `containers.dart`: `findContainer` = the deepest non-package sphere containing the camera.
  The navigator reports changes (`onContainerChanged` → `ViewerContainerChanged`), only on
  change, at most once per step.
- `fly_controls.dart`: `FlyControls` (`Focus` + `onKeyEvent`: arrows, Page Up/Down, E/Q,
  Shift, Home, `?`; drag to look; focus on appear and on tap), `Trackball` (continuous turn,
  rate proportional to the distance from the center), `MoveControl` (proportional slider +
  hold-to-fly up/down buttons, haptics), `ControlsHelpDialog` (app bar button and `?`).
- Touch controls: `TouchControlsMode` auto/always/never in `settings_repository` (PR) and
  in `SettingsBloc`, with a "Viewer" section in Settings. Auto = Android/iOS, or the last
  pointer was touch and no key was pressed yet.
- 3D visual scenario **`fly_path`**: from the start pose with a fixed 1/30 s step, forward
  1 s (through `main()`), turn right 45°, forward 0.5 s. Scenarios gained
  `minCenterCoverage` (0 for `fly_path`: the flight ends between spheres).
- Tests: 140 unit/widget tests (100% coverage), 114 goldens, 20 3D captures.

### Bug found by the tests (fixed)
- `ViewerView` wrapped everything in an autofocus `Focus`, which took the focus before
  `FlyControls`. The arrow keys would only have worked after a click. The wrapper is gone; F3
  still reaches the viewer's `CallbackShortcuts` by bubbling up from the 3D area.

### Things the next agents must know
- `FlyCameraController` turns **left** for a positive horizontal `look` (drag the world).
  To turn right by an angle `a`, use `look(Offset(-a / 0.005, 0))`.
- vector_math is single precision: compare positions with `1e-4`, not `1e-9`.
- `CodeWorldView` keeps the navigator (the camera) when only the theme changes, and creates a
  new one when the map changes.
- Re-running `tool/visual_test.sh --update` rewrites PNGs whose pixels did not change
  (re-encoding). Check with a compare run before committing baseline changes.
- The owner should try the touch controls on a phone (widget-tested only here).
