# Session M7.5: Fire

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 5. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `apps/battle_team`, `packages/battle_client` (pre-check) · **Branch:** `bt/m7-05-fire` · **Depends on:** M7.4 (M7.2 for fast manual runs).
**Skills:** `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:animations`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): COMBAT-11 to COMBAT-26 (`plan/specs/70-combat-and-ap.md` §2 to §4), COMBAT-57, COMBAT-58, UNIT-38; decisions 183, 234, 237; `plan/data/combat.yaml`, the weapon entries of `plan/data/units.yaml`; `packages/battle_protocol/lib/src/orders.dart` (`Fire`, `FireAtPosition`, `FireAimed`, `Reload`, `SwapWeapon`) and `messages.dart` (`Fired`, `UnseenHit`, bursts in `TickUpdate`); the session logs of M6.2 (what a section learns of a shot), M6.7 (`HeldView` hits and bursts), M7.4.

## Steps
1. **Read the five orders and the hit/burst messages** in `battle_protocol` before designing: the UI shows exactly what `HeldView` holds, nothing more.
2. **Weapon panel** on the selected own unit: weapon name, rounds (`UnitPrivate.rounds`), reload state, the swap list; buttons Fire (at the selected target), Fire at position (then tap the ground), Reload, Swap. In first person (M7.4): an aim reticle and `FireAimed` with the aim direction the camera gives.
3. **Pre-check in `battle_client`** (stack decision 8, display only): range and AP for a shot from `battle_rules` on the view's data; the button shows "out of range"/"no AP" before sending. The host's answer wins: a refusal that the pre-check missed is shown as the host's.
4. **Drawing** through the `BattleWorld` seam: `showShots(Iterable<ShotEffect>)` — a tracer from the shooter to the target or position for a seen `Fired`, a hit mark on a seen unit for a hit, and for an `UnseenHit` only the hit mark on the own/seen unit: no origin, no direction (decisions 234, 237). `FakeWorld` records the effects; the GPU class draws them with Flutter's animation system (`vgv-ai-flutter-plugin:animations`), short-lived.
5. **Refusals** (AP, range, rounds, UNIT-38, target not seen) surfaced on the panel, localized en + fr.
6. **Decision 237 proof**: a bloc test over a recorded stream with unseen hits and a `Fired` whose target is unseen: the effects hold no shooter for the first and no target for the second.
7. **Gates** (§4, §6) for `battle_client` and the app; **show it** (recording: a test unit firing each way); **finish** (§5): `battle_client` PR first.

## Tests to write
- `COMBAT-11 fire needs a seen target` (pre-check and UI state), `COMBAT-12 fire at position for indirect-fire units only`.
- `COMBAT-14 aimed fire from first person sends FireAimed with the camera's direction`.
- `COMBAT-57 / decision 234 an unseen hit shows the hit, not the shooter`; `COMBAT-58 / decision 237 a shot at an unseen target shows the shooter firing, outcome unknown`.
- `UNIT-38 an action the unit lacks is refused before sending`.
- `Reload` and `SwapWeapon` update the panel from the next `UnitPrivate`.
- Widget tests of the panel (buttons, localized labels, disabled states).

## Stop and ask when
- `HeldView` lacks a field the panel needs (e.g. the weapon list of a unit): propose the protocol change (M6 conventions) and ask before touching `battle_protocol`.

## Pitfalls
- Shot effects are transient view state; keep them out of the persistent cubit state or they replay on rebuilds. A separate `ShotEffects` controller (Observer) is fine — name the pattern.
- Range checks use the host's distance rule (3D positions, decision 235); copy nothing, call `battle_rules`.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 5).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log
