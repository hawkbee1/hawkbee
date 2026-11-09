# Session M7.4: View from a unit

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 4. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `apps/battle_team` · **Branch:** `bt/m7-04-view-from-unit` · **Depends on:** M7.3.
**Skills:** `vgv-ai-flutter-plugin:animations`, `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`; read `packages/flutter_scene/packages/flutter_scene/skills/flutter_scene-idioms/SKILL.md` and its `references/what-exists.md` (cameras, controllers).
**Read** (`plan/` is `apps/battle_team/plan/`): decision 5, MAP-04, MAP-26, COMBAT-14, decision 235 (sight from the top of the hit box); `plan/stack/04-client-and-rendering.md` (two cameras, frame budget: 60 fps in first person on phones); `plan/stack/03-networking.md` (the first-person move stream rate); `plan/stack/08-workload-placement.md` (AP between updates is client-computed); `plan/data/units.yaml` (`hit_box_m.height` = eye height); the session logs of M7.1 (the 3D seam) and M6.7 (`apAt`, clock sync).

## What exists
- `TopDownCamera` in `lib/battle/world/` (pan, zoom, turn); the `BattleWorld` interface + `SceneBattleWorld` (GPU) + `FakeWorld`; the cubit's selection (tap a unit, tap the ground).

## Steps
1. **Camera seam**: an `abstract interface class BattleCamera` with `TopDownCamera` and a new `FirstPersonCamera` (eye at the unit's position + `hit_box_m.height`, yaw/pitch from drag or two fingers, FOV from a constant in a `const` class, not a game number). The world interface gains `useCamera(BattleCamera)`; `FakeWorld` records it. Pattern: State (camera mode) or Strategy — name one in the doc comment.
2. **Cubit state**: `viewMode` (`topDown` | `firstPerson(unitId)`); enter from the selected own unit (a button on the unit panel), leave with a button or when the unit dies, is stored or leaves sight. Everything the UI needs is in state; no camera object in the bloc.
3. **Movement in first person**: a move order from the view is the same `Move` order to the tapped/aimed ground point; the stream rate of `stack/03` applies to what the client *renders*, not to orders. The AP shown between updates comes from `BattleClient.apNow`/`apAt` (M6.7).
4. **Fog in first person**: the GPU class draws only the units in the view (as today); confirm with the `FakeWorld` test that entering first person changes no set of drawn units.
5. **Record** the rate and the bytes it costs (count `TickUpdate`s and sizes over a one-minute run on the playtest battle, or the recorded streams) next to `stack/03`'s estimate, in the log and in `plan/stack/03-networking.md` (one line, on the same branch in `apps/battle_team`).
6. **Gates** (§4, §6); **show it** (web build or the owner's phone: a recording entering and leaving first person); **finish** (§5).

## Tests to write
- `decision 5 first person enters from an own unit and leaves to top-down` (bloc_test).
- `MAP-04 / decision 235 the eye sits at the unit's hit box height` (camera unit test with `hit_box_m` from the real data).
- `decision 237 entering first person draws the same units as top-down` (`FakeWorld`).
- First person ends when the unit is stored/dies (state transition tests).
- Widget test: the enter/leave buttons exist and are localized (en, fr).

## Stop and ask when
- The 60 fps floor cannot be judged without a device: say so in the log; M7.13 measures.
- Aiming (COMBAT-14, `FireAimed`) tempts you: it is M7.5's; stop at the camera and the move.

## Pitfalls
- Camera math is pure Dart: test it without flutter_scene (vector_math only).
- A quaternion from yaw/pitch drifts if you compose incrementally; rebuild from angles each frame.
- Do not edit anything under `packages/flutter_scene/`.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 4).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log
