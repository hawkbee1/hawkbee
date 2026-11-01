# Session M4.9: Morale and 0-HP outcomes

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 9. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-09-morale` · **Depends on:** M4.8.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/70-combat-and-ap.md` (morale, prisoners, defection); UNIT-39 and `progression.section_size` in `plan/data/units.yaml`; decisions 70 to 75, 94, 131 and 149.

## Notes
- Morale changes only through events the caller sends (aura per minute, kills, deaths, outnumbered per minute). There is no drift.
- Start with the spec examples of the issue as the first tests.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m4-rules-core.md, Issue 9).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-01), stacked on M4.7 (not merged yet; its own dependency is M4.8), in `packages/battle_rules/lib/src/combat/`:
- `morale.dart`: `MoraleEvent` (aura minute, nearby enemy killed, nearby ally killed, outnumbered minute); `Morale(rules)` with `base`, `after(morale, event, times:)` (clamped to `morale.range`, no drift), `isNearby`, `isOutnumbered`.
- `zero_hp.dart`: `ZeroHp(rules:, morale:)` with `sparedChance` (`k × ((max − morale)/(max − min) + (1 − AP/ap_max)) / 2`), `maySpare` (attacker category `only_when_final_blow_by`, enemy target, not `never_spared`) and `resolve(...)` → `ZeroHpOutcome` (death, defection, prisoner; `dropsWeapon` only for death). Two seeded draws: spared, then defection by `defection_share` if the section has room, prisoner otherwise. `PrisonerStorage` (unlimited).
- `SectionSize.capAt(level)` and `hasRoom(level:, activeUnits:)` (UNIT-39), on the M4.2 model.

Checks: analyze `--fatal-infos` clean, format clean, 400 tests pass, coverage 100 % (1267/1267 lines). The spec examples hold on real data: 51 % and 15 %.

Choices:
- The `100` of the 0-HP formula is the morale range (`morale.range`, 0 to 100), so no number sits in the code.
- Room for a defector means fewer active units than the cap (UNIT-39 counts active units).
- XP and evolution are kept by a defector because nothing resets them: there is no unit record yet (M5). The weapon rule is `dropsWeapon`.
