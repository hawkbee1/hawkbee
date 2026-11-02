# Session M5.4: Storage, deployment and the commander's death

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 4. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m5-04-storage` · **Depends on:** M5.2, M5.3.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/50-hq.md` §1, §5; UNIT-28, UNIT-29, UNIT-42; COMBAT-37 to COMBAT-45 (prisoners); `plan/data/battle.yaml` `storage`, `commander_death`, `section_redeploy_lock_s`; decisions 80, 94, 110, 120, 125, 129, 130, 141.

## Notes
- Unit location is a State (stack decision 7): on the field, carried, stored, prisoner. Each state owns the actions it allows; cite the pattern in the doc comment.
- Positions stay abstract, as in M4: distances to the storage place, enemies inside a radius.
- Weapons in storage (M4.6 `StoredWeapons`) stay with the section when its units are stored.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m5-simulation-host.md, Issue 4).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02) on `main` (M5.1 to M5.3 merged), in `packages/battle_rules`:
- `lib/src/storage/unit_location.dart`: `UnitLocation`, a State (stack decision 7): `OnField` (sealed: `Deployed`, `Carried(transportId)`, with `recallDoneAt`, `takesPassengers`, `recalledUntil`, `at(now)`), `Stored`, `Prisoner(captorSectionId)`; `Carried.setDown()`.
- `lib/src/storage/storage_rules.dart`: `StorageRules(battle:, morale:)` with `placeOf`, `store` → `StoreOrder` (sealed: `StoredAtOnce`, `RecallStarted(location)`, `StoreRefused`), `blocks`, `isLocked`, `lockAfter`, `deploy` → `DeployOrder` (sealed: `DeployStarts(at, pool)`, `DeployRefused`), `atCommanderDeath` and `resurrect`.
- `lib/src/storage/prisoners.dart`: `PrisonerStorage` moved from `zero_hp.dart`; it now keeps each prisoner's owner section. `PrisonerOffer` (sealed: `ExchangeOffer`, `RansomOffer`) with `accept` → `PrisonerDeal` (sealed: `DealDone`, `DealRefused`).
- `MoneyRules.buyUnit` takes `locked:` and `arrivalBlocked:` (required), refused with `sectionLocked` and `arrivalBlocked` (decision 205).

Decisions by the owner (2026-11-02), recorded in battle_team on `bt/m5-04-storage`:
- Decision 204: the lock starts when the last unit leaves the field, however it leaves; only a commander's death never starts it.
- Decision 205: a blocked arrival, or a locked section, refuses the purchase.
- Decision 206: a transport is stored empty (new rule HQ-49); at a commander's death, other sections' passengers are set down where they are.
- Decision 207: the commander's XP loss lowers his earned XP too.

Checks: analyze `--fatal-infos` clean, format clean, 544 tests pass, coverage 100 % (test optimization off).

Choices:
- Decision 204 was asked for a death; capture and defection are treated the same way, since the unit leaves the field without being stored. The guild camp and the section's units held prisoner never hold the lock off.
- A deployment is a paid action: it waits for its AP (COMBAT-06). With `ap_loss_share` 1.0 a section redeploys about 10 hours after its commander's death. The host checks the block and the lock again when the wait ends (M5.11).
- A carried unit is on the field (UNIT-29): it is stored or recalled by its own order and leaves its transport.
- The resurrected commander has full HP and takes the same AP and morale losses as his units.
- An exchange is between two sections: each releases prisoners it holds from the other. An offer must release at least one prisoner and ask for a prisoner or a positive ransom. The ransom crosses teams with no fee (COMBAT-44 overrides ECO-10).
- A prisoner still belongs to its owner's section, so it counts among the units it owns (UNIT-40); otherwise a released prisoner might not fit in storage (HQ-30).
- COMBAT-45 (a prisoner lost at the end of the war) has no code here: the end of the war is M5.7.

Open point for M5.6: a newcomer's commander whose arrival is blocked (noted in that session).
