# Session M7.6: Storage: view, store, unstore

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 6. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `apps/battle_team` · **Branch:** `bt/m7-06-storage` · **Depends on:** M7.1 (M7.2 for fast manual runs).
**Skills:** `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:accessibility`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): HQ-29, HQ-31 to HQ-36, HQ-39, HQ-46, MAP-50; decisions 110, 120, 125, 204, 240; `plan/data/battle.yaml` (`storage:`); `battle_protocol` `orders.dart` (`Store`, `Recall`, `Deploy`) and the private view (`UnitPrivate.place`, locks, prisoners); the session logs of M5.4/M5.12 (storage rules and orders) and M7.1 (where the playtest's Deploy button is).

## Steps
1. **Storage screen** (`lib/storage/`, a bloc on the same `BattleRepository`, or a panel of the battle feature — choose the one that keeps the battle cubit small; say why): stored units with type and HP, the portal, the deploy cost (`deploy_ap`), the lock (HQ-35) with remaining time, "blocked: enemy within 20 m" (HQ-36), the recall in progress with its remaining time, prisoners.
2. **Orders**: `Store` from a selected own unit on the field (instant within `store_radius_m`, else the recall delay — show which before sending), `Recall`, `Deploy` from the storage list (the playtest's Deploy moves here; remove the old button).
3. **Private state only**: the view reads `UnitPrivate` and the section's private state; nothing of other sections (HQ-29). Deploy places the unit at the nearest free place to the portal (MAP-50): the UI shows the host's answer, it computes nothing.
4. **Refusals** (locked, blocked, not stored, cost above AP) surfaced with their reasons, localized en + fr.
5. **Accessibility**: labels on every button, the list readable by a screen reader (`vgv-ai-flutter-plugin:accessibility`).
6. **Gates** (§4, §6); **show it** (screenshot of the storage screen with a lock and a blocked state — drive the state from a recorded stream or the fake host); **finish** (§5).

## Tests to write
- `HQ-33 deploy sends Deploy for a stored unit and shows its cost`; `HQ-35 a locked section shows the lock and disables deploy`; `HQ-36 an enemy within 20 m shows blocked`.
- `HQ-31/32 store within store_radius_m is instant, farther shows the recall delay`.
- `HQ-29 the storage view shows only the section's own stored units` (a stream with another section's units).
- Widget tests: list, buttons, disabled states, en and fr.

## Stop and ask when
- The private view lacks the lock's end time or the nearest-enemy state: ask whether this session may extend `battle_protocol` (M6 conventions) or shows what it has.

## Pitfalls
- Remaining times come from the host's battle time (`BattleClient.battleTime`), not `DateTime.now()`.
- Keep numbers out of `lib/`: `deploy_ap`, `store_radius_m` come from the view/data, never a literal.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 6).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log
