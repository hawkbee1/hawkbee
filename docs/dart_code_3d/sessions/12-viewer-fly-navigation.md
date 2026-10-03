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

- [ ] Arrow-key flight works on Linux desktop and web. Touch controls work (verified with widget tests; ask the owner to try on a phone).
- [ ] The camera cannot enter external package spheres.
- [ ] Analyze/format clean, 100% coverage, goldens and visual baselines committed.

## Session log

_(to be filled by the agent)_
