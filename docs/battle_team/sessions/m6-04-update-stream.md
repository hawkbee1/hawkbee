# Session M6.4: The update stream of a section

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 4. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m6-04-stream` · **Depends on:** M6.2, M6.3.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/03-networking.md` (update policy); `plan/stack/07-engineering-principles.md` (Observer); MAP-08, MAP-49, RELIC-10, RELIC-16, COMBAT-57; decisions 232 to 234; the session logs of M5.13 (relic owner changes, victory timer), M5.14 (the delta layer), M5.15 (scripted battle, recovery), M6.2 and M6.3.

## Notes
- Subscribers are in-process objects here; sockets come in M6.5. A subscriber is a port the endpoints implement.
- The "nothing hidden" test runs over the whole scripted battle of M5.15, for every section, at every update.
- An event that names a unit the section does not see: cut it down or drop it, and say per event type which one in the log.
- The alerts a player has not received yet (decision 233) are battle state: they must survive a restart. Derive them from the log (owner changes and `EnterBattle` entries) or keep them in the snapshot, and say which in the log. An alert is delivered once per player, on the player's next connection. A case no rule (COMBAT-57 among them) covers is a new question with "Assumed:" in `95-open-questions.md`.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m6-networking.md, Issue 4).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-08), stacked on M6.2 (`bt/m6-02-messages`, hawkbee #62) and M6.3 (`bt/m6-03-fog`, hawkbee #61): the hawkbee and `battle_team` branches start from M6.3's and merge M6.2's; `battle_host` from M6.3's; `battle_protocol` stays on M6.2's.
- **`battle_host`**, `lib/src/stream/`:
  - `SectionSubscriber`: the port the endpoints of M6.5 implement (`send(HostMessage)`).
  - `UpdateStream` (Observer), one per battle in `SimulationHost`: it hears every log entry (`BattleCommands` now takes a `record` callback: the journal, then the stream), and `flush()` sends each subscribed section a `TickUpdate` with what changed since its last message, if anything did. The host flushes after each accepted order (`submit`) and each tick (`see()`, after the fog). `subscribe` sends the whole `SectionView` first, delta layer included, then the player's waiting alerts; `SimulationHost.subscribe`/`unsubscribe`.
  - What an update holds: moved units (a seen unit whose position changed), units that came into sight (whole) and went out, events cut to what the section may see, bursts, unseen hits, own units whose private state changed, the section's state when it changed, HQs in and out of sight, relics that changed.
  - `SectionViews`: state to `UnitView` (private state for its own section), `HqView` (AP for its own team), `RelicView`, `SectionPrivate`, the countdown, the delta layer as world events (craters in order, structures built, objects damaged, objects destroyed) and the whole `SectionView`.
  - `PendingAlerts` (decision 233), on `Battle.alerts`: a relic captured from a team alerts each of its players, at once when subscribed, else on their next connection. **Kept in the snapshot** (`alerts`, beside the state; written only when some wait), and rebuilt after it from the replayed entries in `SimulationHost.recover` (nobody is connected then). A player's `EnterBattle` entry is a connection and clears its alerts. After a crash, a player connected when a relic changed owner since the last snapshot, and not connected again since, receives that alert once more: never lost, possibly twice.
- **`battle_team`**: decision 236 (Q-MAP-26), the M7 outline and M8 topic 5; decision 237 (Q-CBT-39) and COMBAT-58; `stack/03`'s update policy.

Per event type (`UpdateStream._visibility`): **cut down**: `Attacked` (a seen shooter's shot that hit only units the section knows stays whole; any other becomes `Fired` with only the hits it knows, COMBAT-58; an unseen shooter's hits on units it knows become `UnseenHit`s, COMBAT-57). **Dropped** unless the section knows every unit it names: `MoveStarted`, `MoveStopped`, `Crushed`, `WeaponPickedUp`, `Repaired`, `UnitHealed`. **Own section only**: `OrderRefused`, `OrderDelayed` (by the sequence number's sender), the unit actions (`WeaponSwapped`, `TimeOnlyStarted`, `Embarked`, `Disembarked`, `BuildStarted`, `RepairStarted`, `WorkResumed`, `WorkInterrupted`, `ObservationStarted`, `AddedToCapture`, `AddedToPush`, `UnitStored`, `RecallBegan`, `UnitDeployed`, `NodePurchased`), `SectionLocked`, `UnitPurchased`, `WeaponPurchased`, `SectionJoined`. **The sections concerned**: `MoneyTransferred`, the offers, `ManagerChanged` (the team). **Every section** (MAP-49): the world events, captures and relics, the countdown, eliminations, the battle's start and end. `WeaponDropped`: the sections whose units see where it fell. Two or more such whole shots of one unit in one update become a `Burst`, a lone one stays an `Attacked`; `Fired` groups a unit's shots of unknown outcome the same way.

Checks: analyze `--fatal-infos` and format clean; `battle_host` 338 tests pass with 100 % line coverage, test optimization off.

Acceptance criteria, on M5.15's scripted battle in clear weather and in fog: a subscriber that joins halfway, and one that leaves and comes back, hold the same view at the end as one present from the start (units, positions, HP, HQs, relics, section, countdown, delta layer); at every message to every section, no unit is named outside what it saw before or after, but its own. A relic captured alerts the previous owner team's connected player at once and nobody else; a player of that team who connects afterwards receives it once, also after a restart, from the snapshot or from the log after it.

Choices and questions:
- **Q-MAP-26**, answered by the owner on 2026-11-08: decision 236. M5 places a moving unit at its destination as its move starts (sight and shots use that cell), so the stream sends that position once; the client animates the move with Flutter's animation system (M7 outline). Following units along their paths on the host, at 5 Hz in the stream, is planned in M8 (topic 5).
- **Q-CBT-39**, answered by the owner on 2026-11-08: decision 237 and COMBAT-58, the unseen leaves no clue and players know they do not know. A hit by an unseen shooter on a unit the section sees is an `UnseenHit` (unit, damage, result: not even whether the shooter is a friend). A seen unit's shot shows as `Attacked`, or in a `Burst`, only when it hit and every unit it hit is seen; otherwise it is `Fired`, outcome unknown, with only the hits the section sees (a miss is `Fired` too: saying it missed would tell that its hidden target was not hit). A weapon dropped where none of its units sees is not shown. `battle_protocol` gained `UnseenHit` and `Fired` on M6.2's branch.
- A seen unit's HP and other values change in the client from the events (hits, heals, repairs), not by sending the unit again: the issue's update holds positions, units in and out, events and private state.
- An update goes after each accepted order as well as each tick, so an order's events reach the section at once; the 5 Hz cadence applies to positions only, and the host holds one per move.
