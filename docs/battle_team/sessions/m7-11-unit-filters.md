# Session M7.11: Unit filters

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 11. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `apps/battle_team` (`battle_protocol` + `battle_host` + `battle_client` only if the view lacks the guild of a friendly section) · **Branch:** `bt/m7-11-filters` · **Depends on:** M7.1.
**Skills:** `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): Q-MAP-27, decisions 21, 237; `UnitView` in `battle_protocol` (`sectionId`, `team`; is there a guild?); SOC-40 to SOC-53 for what a guild is; the session logs of M6.2, M6.7 and M7.1.

## Steps
1. **Check the data first**: `UnitView` has `sectionId` and `team`. "My guild's units" needs the guild of each friendly *section*; look for it in `SectionView`/private state. If absent: see "Stop and ask" before any protocol work.
2. **Filter model**: `UnitFilter { all, mine, friendly, enemy, guild }` in the battle cubit state; `visibleUnits` is a pure function of the view and the filter (tested alone). A filter hides; it never adds: the input is always the host's view.
3. **UI**: a segmented control over the map (and in the unit list if there is one), localized en + fr; the choice remembered for the session only (no persistence).
4. **Drawing** through the `BattleWorld` seam: `show(units: filtered…)`; `FakeWorld` already records what is drawn.
5. **Gates** (§4, §6); **show it** (one screenshot per filter on a view with two teams and two friendly sections — drive it from a recorded stream or the fake host); **finish** (§5).

## Tests to write
- `M7.11 mine shows only the section's units`, `… friendly shows the team's`, `… enemy shows the other teams'`, `… guild shows the guild's sections` (pure function tests).
- `decision 237 a filter never shows a unit the view does not hold`.
- `Q-MAP-27 the team of a seen unit decides friend or enemy`.
- Widget test: the control switches the filter; labels in en and fr.

## Stop and ask when
- The guild of friendly sections is not in the view: propose adding `guildId` to the friendly sections the section sees (M6 conventions: samples, sizes) and ask whether this session may touch three packages or the guild filter waits.

## Pitfalls
- Keep the filter out of the fog logic (M7.9): fog decides what is known, the filter what is shown.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 11).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log
