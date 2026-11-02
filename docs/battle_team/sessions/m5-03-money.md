# Session M5.3: Money

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 3. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m5-03-money` · **Depends on:** M5.2.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/60-economy.md`; SOC-10 to SOC-15; COMBAT-27; `plan/milestones/economy.yaml` (it lives in `milestones/`, M4.2 log); decisions 102, 111, 112, 130.

## Notes
- Amounts are whole w€; a fee is rounded to the nearest whole w€, halves up, and taken from the amount (decisions 200, 203). Allies and the own HQ earn nothing (decision 202); a killing shot earns its hit and its kill (decision 201).
- Purchases check free room with the cap of M5.2. Where the unit arrives is M5.4 (HQ-46).
- XP cannot be bought (ECO-21): no API offers it; a test shows that no purchase changes XP.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m5-simulation-host.md, Issue 3).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02), stacked on M5.2 (not merged yet), in `packages/battle_rules`:
- `lib/src/economy/money.dart`: `Earning` (sealed: `HitEarning`, `KillEarning`, `HqHitEarning`, `HqDestroyedEarning`, `ConstructionEarning`, `HealEarning(healer)`); `MoneyRules(economy)` with `earned`, `buyUnit(type:, money:, hasRoom:, guildChief:, guildHasCamp:)` and `buyWeapon` → `Purchase` (sealed: `Bought(price, moneyLeft)`, `PurchaseRefused(PurchaseRefusal)`), `transfer(amount:, senderMoney:, sameTeam:, sameGuild:)` → `Transfer` (sealed: `Transferred(received, fee)`, `TransferRefused`), `startingMoney`, `afterCommanderDeath`, `afterUnitLost`.
- `SectionLevel.hasRoom(level:, active:, owned:)`: a bought unit arrives on the field, so it needs a place under the cap and under the units owned.
- `EconomyData` reads money as whole w€ (`int`): a price like 450.5 fails to load. `GameData.parse` checks `purchasable_by` (commander or guild chief) and that every price names a unit or weapon type.

Decisions by the owner (2026-11-02), recorded in battle_team on `bt/m5-03-money`:
- Decision 200: amounts are whole w€; a fee rounds to the nearest whole w€, halves up.
- Decision 201: a killing shot earns the hit's XP and money as well as the kill's.
- Decision 202: hitting an ally or the own HQ earns no money.
- Decision 203: the fee comes out of the amount sent.

Checks: analyze `--fatal-infos` clean, format clean, 503 tests pass, coverage 100 % (test optimization off).

Choices:
- A guild has one camp: buying one while it has a camp is refused (`campExists`), from "the guild encampment" and HQ-42 ("buy a new encampment" once destroyed).
- A commander is never bought (`notForSale`): a section has one, from its creation (UNIT-41, SOC-40). A type without `purchasable_by` is bought by the section's commander.
- Fees are computed in basis points so halves round exactly (5 % of 30 w€ is 2 w€, not 1).
- `afterUnitLost` takes the units the section still owns besides its commander; the host counts them (stored ones included).

Deviation: ECO-07 (where a bought unit arrives) is the storage place of HQ-46, built in M5.4.
