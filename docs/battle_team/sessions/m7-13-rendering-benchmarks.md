# Session M7.13: P-05 and P-06, the rendering benchmarks

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 13. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `apps/battle_team` (+ `linux/` platform folder) · **Branch:** `bt/m7-13-benchmarks` · **Depends on:** M7.9; **needs the owner**: the devices of `plan/stack/04` (iPhone 11, Pixel 6, the Mac, the main laptop under Linux and Windows, the old Lenovo, browsers on both laptops). The agent prepares, the owner runs, the agent records.
**Skills:** the `flutter_scene-performance` skill (`packages/flutter_scene/packages/flutter_scene/skills/`), `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/milestones/performance-tests.md` (P-05, P-06, their targets); `plan/stack/04-client-and-rendering.md` (frame budget, floors, devices, the risk paragraph to replace); `plan/stack/05-map-format.md` (tiles, craters); `packages/flutter_scene/examples/stress_bench` (the method); `apps/dart_code_3d` `tool/perf_test.sh` and `tool/web_perf.mjs` (how dc3d measured); the session log of M7.9.

## Steps
1. **A benchmark entry point** `lib/main_benchmark.dart` + `--dart-define=BT_BENCH=<scenario>`: scenarios `units_1000_top_down`, `units_1000_first_person`, `tiles_load`, `crater_apply`, fed by a synthetic `SectionView` (1,000 units spread over the 1 km map, mixed types, 10 % moving) through the same `BattleWorld` seam the app uses — no special rendering path. It prints frame timings (UI and raster threads apart: `SchedulerBinding.addTimingsCallback`) for 30 s, then the summary (average, p95, worst) as one JSON line.
2. **Launch configurations** in the root `.vscode/launch.json` (profile mode) and a `tool/bench.sh` for the owner (`flutter run --profile …` per platform; web via `web_perf.mjs`'s approach).
3. **`linux/`**: add the platform folder with `tool/add_linux_platform.sh` (no `flutter create`), switch Flutter GPU on for Linux as the playtest did for the others.
4. **The owner runs** each scenario on each device and pastes the JSON lines; you record them in `performance-tests.md` (P-05, P-06 tables: device, scenario, average, p95, worst, fps floors met or not) and name the slowest device as the reference. P-06: tile load time near the camera, first frame on a new map, memory of tiles in view, crater apply time (within the frame budget or off-frame).
5. **Replace** `stack/04`'s risk paragraph with the measurements; set P-06's target in `stack/05`.
6. **Plan the fixes**, from the measurements, in the order of the performance skill (instancing, LOD, culling, post-processing, materials, static shadows): one proposed session per fix needed, as a list at the end of your log for the owner. Change no rendering code in this session.
7. **Gates** (§4, §6: the benchmark code is covered like any feature; the GPU parts stay in the ignored class); **finish** (§5).

## Tests to write
- The synthetic view generator: 1,000 units, deterministic from a seed, valid positions on the map.
- The timing summary: average/p95/worst from a known series.
- The entry point parses its scenario define and refuses an unknown one.

## Stop and ask when
- A device cannot run profile mode (web on the old Lenovo, say): record "not measurable" with the reason, never a guessed number.
- The floors are missed on the reference device: report it plainly; the owner decides which fix sessions to run.

## Pitfalls
- Profile mode only; debug numbers are meaningless — refuse to record them.
- The same seam as the app: a benchmark that bypasses `BattleWorld` measures nothing the game does.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 13).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log
