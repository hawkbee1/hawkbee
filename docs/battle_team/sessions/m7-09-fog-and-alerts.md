# Session M7.9: Fog shading and alerts

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 9. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `apps/battle_team` · **Branch:** `bt/m7-09-fog` · **Depends on:** M7.4.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`; read `packages/flutter_scene/MATERIALS.md` and the `flutter_scene-procedural` skill (`packages/flutter_scene/packages/flutter_scene/skills/`) for a custom ground material.
**Read** (`plan/` is `apps/battle_team/plan/`): MAP-27, MAP-29, MAP-33, MAP-49; RELIC-10, RELIC-16; decisions 21, 232, 233, 235, 237; `battle_protocol` `messages.dart` (what a `SectionView`/`TickUpdate` says about sight: units in and out, alerts, the countdown); the session logs of M6.3 (what the host computes: the visible set, never sent as an area) and M6.4 (alerts, late delivery), M7.4.

## What the client knows
The host sends **units** in and out of sight, never a visibility map (M6.3/M6.4). The client therefore shades from what it can derive without computing sight: the positions and sight ranges of its **own** units (their `vision_range` from the view), and nothing else. Read M6.3's log to confirm what the view carries; if the client lacks the effective sight range, see "Stop and ask".

## Steps
1. **Fog model** in the battle feature (pure Dart, tested): `FogModel` with `isLit(x, y)` from the own units' positions and sight ranges (circles, no terrain: the client does not compute sight lines — decision 237 forbids guessing further). Three states per spot: lit now, seen once (keep a coarse grid of what was lit), never seen.
2. **Ground shading** through the `BattleWorld` seam: `showFog(FogModel)`; `FakeWorld` records it; the GPU class renders it as a ground overlay or material parameter (coarse texture updated on change, not per frame). Units out of sight already vanish (M7.1 test).
3. **Alerts**: a bloc listening to alert messages: the relic alert (RELIC-10, also delivered on connect — decision 233) and the victory countdown (RELIC-16); MAP-49's facts (relic owners, countdown) shown permanently in a status strip. Alerts appear as a dismissible banner, localized en + fr.
4. **Decision 237 proof**: a bloc test over a recorded stream: the fog model lights only around own units; an unseen hit lights nothing; an enemy leaving sight leaves no mark.
5. **Gates** (§4, §6); **show it** (recording with two sections' views — run two clients on the fake host or two accounts on the playtest battle); **finish** (§5).

## Tests to write
- `MAP-27 the fog model lights the own units' sight ranges`; `MAP-29 nothing outside the lit area is drawn`; `MAP-33 seen-once differs from never-seen`.
- `RELIC-10 / decision 233 the relic alert shows once, also when received on connect`; `RELIC-16 the countdown shows for every section`; `MAP-49 relic owners show whatever the fog`.
- `decision 237 fog gives no clue about unseen units or hits`.
- Widget tests: banner, status strip, en and fr.

## Stop and ask when
- The view does not carry each own unit's effective sight range (weather, observe, height): propose adding it to the own units' private state (M6 conventions) and ask; do not compute it client-side from `units.yaml`.

## Pitfalls
- The fog grid is view state, not game state: never send it, never log it.
- Update the fog texture when the model changes, not every frame (frame budget, stack decision 4).

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 9).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log
