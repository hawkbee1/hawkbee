# Session M7.7: Buy

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 7. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `packages/battle_protocol`, `packages/battle_host`, `packages/battle_client`, `apps/battle_team` · **Branch:** `bt/m7-07-buy` · **Depends on:** M7.6.
**Skills:** `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): ECO-04 to ECO-07, HQ-42, HQ-46, COMBAT-27, UNIT-44; decisions 129, 130, 147, 205, 210, 239; `plan/data/units.yaml` (prices, `common_stats`), `plan/data/economy.yaml`; `battle_protocol` `orders.dart` (`BuyUnit`, `BuyWeapon`); the session logs of M5.3 (money), M5.12 (purchases) and M7.6.

## Steps
1. **The roster comes from the host** (designer, 2026-11-10): the app ships no `plan/data` copy and never will. Add a `Roster` host message in `battle_protocol` (unit types the battle allows — `test_unit` only when `test_units` is on — with price, display name key and category; the weapons with their prices), sent by `battle_host` with the whole view (M6.4's `SectionSubscriber`), held by `battle_client`'s `HeldView`. M6's conventions: frozen samples, both encodings, size recorded next to `stack/03`. Read M6.2's log for the procedure before writing the message.
2. **Shop screen** (`lib/shop/`, same repository): the section's money; the roster with prices (the `test_unit` only when the battle allows it, UNIT-44); `BuyUnit`; for a selected own unit, `BuyWeapon` with the weapon list and prices. `BuyGuildCamp` and `BuyNode` are out: do not add buttons for them.
3. **Refusals**: money, no room (`hasRoom`), lock, enemy at the portal, `test_units` off — each with its reason, localized en + fr.
4. **Arrival**: a bought unit appears at the nearest free place to the portal (HQ-46, MAP-50) through the normal stream; nothing to compute client-side.
5. **Gates** (§4, §6) for the four packages; **show it** (screenshot of the shop with one refusal visible); **finish** (§5): protocol, host, client PRs first.

## Tests to write
- `ECO-04 buying a unit sends BuyUnit and shows its price`; `ECO-05 not enough money is refused with the reason`.
- `HQ-46 a blocked or locked portal refuses a purchase`; `UNIT-44 test_unit is listed only when the battle allows test units`.
- `BuyWeapon` for a selected unit; money updates from the next private state.
- Widget tests: roster list, prices formatted by locale (fr uses a space and a comma), disabled states.

## Stop and ask when
- The host's roster would need more than types, prices and weapons (skill nodes, the camp): leave them out and say so in the log; ask only if the UI cannot work without them.

## Pitfalls
- Prices are integers in w€: format with `intl` per locale; never hard-code a currency string outside the ARB files.
- The section's money is private state; show nothing of other sections.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 7).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log
