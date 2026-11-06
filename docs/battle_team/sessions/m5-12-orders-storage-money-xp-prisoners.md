# Session M5.12: Orders for storage, money, XP and prisoners

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 12. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m5-12-storage-orders` · **Depends on:** M5.3, M5.4, M5.11.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): the session logs of M5.1 to M5.4 and M5.11; `plan/specs/50-hq.md` §5; `plan/specs/60-economy.md`.

## Notes
- XP and money are paid by listeners on the events (Observer), not inside each order.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 12).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-04) on `main` (M5.11 merged), in `packages/battle_host`:
- `lib/src/orders/section_orders.dart`: `SectionOrders` holds every order a section gives about its units and money:
  - storage and recall, through the `RecallEnds` timer; deployment; purchases of a unit, a weapon or the guild camp; transfers; tree nodes;
  - prisoner offers, kept in `BattleState.offers` under the sequence number of the order that posted them; the HQ manager's delegation;
  - `commanderDied`: resurrection with its losses, the section's units on the field stored, other sections' passengers set down, and the money floor;
  - the section's portal (its guild's camp on the field, or the HQ) and its room under the cap.
- `lib/src/orders/rewards.dart`: the `BattleListener` interface (Observer), with two listeners:
  - `Rewards`: hit and kill XP and money, construction, repair and heal rewards, and the safety net of a section left with only its commander;
  - `StorageLocks`: the 24-hour lock once a section's last unit leaves the field.
  - `CommandHandler.react` runs both after every accepted order and after every timer except `RunOrder`, which reacts inside the handler.
- State: unit XP history, tree and evolved type; each section's guild and chief role; the open offers; the war's money floor (`BattleSetup.minStartingMoney`, by default `economy.yaml`'s).
- `HostRule` moved to `refusal.dart`; `refused` and `planAt` are shared by the order files. `not_available_yet` is gone: every protocol order now has a plan.

Plan (`battle_team`): Q-UNIT-24 and Q-UNIT-25, since answered by decisions 223 and 224.

Checks: analyze `--fatal-infos` and format clean; 139 tests pass with 100 % coverage.

Choices:
- XP and money come from the events, with the state before them (Observer). The listener finds the builder of a `StructureBuilt` and the repairer of a `Repaired` by the work they held, so the wire events need no new field.
- A killing shot's kill XP, and an HQ's destruction XP, is priced against the history from before its own hit, also for a unit with no history yet. Otherwise decision 201 would halve it as a repeat of the same target.
- A target taken prisoner or turned earns the kill's XP, not its money (decision 223). An HQ hit earns `xp_sources.hq_hit` and its destruction `hq_destruction`, unscaled; repeats on the same HQ shrink like any target's, and a friendly HQ earns nothing (UNIT-10, decision 224).
- A store order works only within the storage radius (`not_at_storage` beyond it); a recall works from anywhere, and within the radius it stores at once.
- A bought unit arrives on its portal's cell, with full AP and HP and base morale, as `unit-<seq>`.
- A stored unit may deploy and buy tree nodes; a prisoner buys nothing.
- No spotting XP yet: no event reports a spotting.
