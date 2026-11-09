# Session M7.13: P-05 and P-06, the rendering benchmarks

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 13. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `apps/battle_team` (+ `linux/` platform folder) · **Branch:** `bt/m7-13-benchmarks` · **Depends on:** M7.9 (fog and units drawn as they will be). Needs the designer's devices (`plan/stack/04`).
**Skills:** the `flutter_scene-performance` skill (`packages/flutter_scene`), `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/milestones/performance-tests.md` (P-05, P-06); `plan/stack/04-client-and-rendering.md` (devices, frame budget, floors); `plan/stack/05-map-format.md`; `packages/flutter_scene` `examples/stress_bench`.

## Notes
- Profile mode, UI and raster threads apart, on each device; the slowest measured becomes the reference. 1,000 units via a scripted battle or a synthetic scene matching the real draw path.
- P-06: tile load near the camera, first frame on a new map, tile memory, a crater applied within or off the frame budget.
- Add `linux/` (stack decision 4; shipped desktop needs Flutter ≥ 3.47.1).
- Results into `performance-tests.md`, `stack/04` (replace the risk paragraph) and `stack/05`; plan the fixes (instancing, LOD, culling, post-processing, materials, static shadows — in that order) as follow-up sessions through the conventions' seams.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 13).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
