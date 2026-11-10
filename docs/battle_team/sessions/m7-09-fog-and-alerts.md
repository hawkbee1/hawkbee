# Session M7.9: Fog shading and alerts

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 9. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `packages/battle_protocol`, `packages/battle_host`, `packages/battle_client`, `apps/battle_team` · **Branch:** `bt/m7-09-fog` · **Depends on:** M7.4.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`; read `packages/flutter_scene/MATERIALS.md` and the `flutter_scene-procedural` skill (`packages/flutter_scene/packages/flutter_scene/skills/`) for a custom ground material.
**Read** (`plan/` is `apps/battle_team/plan/`): MAP-27, MAP-29, MAP-33, MAP-49; RELIC-10, RELIC-16; decisions 21, 232, 233, 235, 237; `battle_protocol` `messages.dart` (what a `SectionView`/`TickUpdate` says about sight: units in and out, alerts, the countdown); the session logs of M6.3 (what the host computes: the visible set, never sent as an area) and M6.4 (alerts, late delivery), M7.4.

## What the client knows, and what it must be sent
The host sends **units** in and out of sight, never a visibility area (M6.3/M6.4). Fog shading needs the area, and sight depends on the terrain (MAP-26, decision 235): the client therefore runs `battle_rules`' vision — the same code the host runs in `FogOfWar`/`SectionSight` (M6.3, `battle_rules`' `GroundObstacle`) — over the map heights it already holds for the mesh, **for display only** (stack decision 8). Its inputs are the section's **own** units only: their positions (in the view) plus two things the view lacks today and this session adds under M6's conventions: each own unit's **effective sight range** (`UnitPrivate.sightRangeM`, after skills and observe) and the battle's **weather** (on `SectionView`, updated by `TickUpdate` when it changes). Nothing of other units feeds the shading (decision 237).

## Steps
1. **Protocol first** (`battle_protocol` → `battle_host` → `battle_client`): `UnitPrivate.sightRangeM` and the weather on `SectionView`/`TickUpdate`; frozen samples, both encodings, sizes next to `stack/03`; the host fills them from the effective stats it already computes (M5.1, M6.3). Read M6.2's log for the procedure.
2. **Fog model** in the battle feature (pure Dart, tested): `FogModel` with `isLit(x, y)` computed on a coarse grid (one 10 m cell, stack decision 5) by `battle_rules`' vision from each own unit (position, `sightRangeM`, the weather, the terrain heights from the loaded tiles). Recompute only when an own unit moves, its range or the weather changes. Three states per cell: lit now, seen once (kept for the session), never seen.
3. **Ground shading** through the `BattleWorld` seam: `showFog(FogModel)`; `FakeWorld` records it; the GPU class renders it as a ground overlay or material parameter (coarse texture updated on change, not per frame). Units out of sight already vanish (M7.1 test).
4. **Alerts**: a bloc listening to alert messages: the relic alert (RELIC-10, also delivered on connect — decision 233) and the victory countdown (RELIC-16); MAP-49's facts (relic owners, countdown) shown permanently in a status strip. Alerts appear as a dismissible banner, localized en + fr.
5. **Decision 237 proof**: a bloc test over a recorded stream: the fog model lights only around own units; an unseen hit lights nothing; an enemy leaving sight leaves no mark.
6. **Gates** (§4, §6) for the four packages; **show it** (recording with two sections' views — run two clients on the fake host or two accounts on the playtest battle); **finish** (§5): protocol, host, client PRs first.

## Tests to write
- `MAP-26 / decision 235 a hill between an own unit and a cell leaves it dark` (fixture heights); `MAP-27 the fog model lights the own units' sight ranges`; `MAP-29 nothing outside the lit area is drawn`; `MAP-33 seen-once differs from never-seen`.
- `RELIC-10 / decision 233 the relic alert shows once, also when received on connect`; `RELIC-16 the countdown shows for every section`; `MAP-49 relic owners show whatever the fog`.
- `decision 237 fog gives no clue about unseen units or hits`.
- `M7.9 the client's lit cells equal the host's visible set` on M5.15's scripted battle (own units' sight only, both sides).
- Widget tests: banner, status strip, en and fr.

## Stop and ask when
- The vision computation over the whole 1 km map is too slow in the app (measure once): propose the host sending a visibility mask instead (traffic cost on big maps) and ask; do not ship a slow frame.
- The host's `FogOfWar` and the client's model disagree on the scripted battle: find why (same code, same inputs: they must agree); if the host's inputs are richer than what the view sends, ask what else to send.

## Pitfalls
- The fog grid is view state, not game state: never send it, never log it.
- Update the fog texture when the model changes, not every frame (frame budget, stack decision 4).

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 9).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log
