# Session M5.2: XP, section XP and commander level

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 2. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m5-02-xp` · **Depends on:** M4 (merged).
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/20-units-and-progression.md` §5; `plan/data/units.yaml` `progression`; decisions 77, 79, 92, 127, 144, 179; the M4.10 session log (capture pot contributions).

## Notes
- Diminishing returns (UNIT-10) count repeats per (attacker, target) and per (engineer, build spot) inside `diminishing.window_s`. Same build spot: within `same_spot_radius_m` (decision 198).
- Target scaling and team power use earned XP, spent or not (decision 197). No XP for time near the commander (decision 199).
- The section share is moved, not copied: the unit keeps 1 − `section_xp_share` (UNIT-14).

## Acceptance criteria
- [x] The acceptance criteria of the issue (m5-simulation-host.md, Issue 2).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02), stacked on M5.1 (not merged yet), in `packages/battle_rules/lib/src/progression/`:
- `xp.dart`: `UnitXp(earned, unspent)` with `gained` and `spent` (spending keeps earned XP); `XpOrigin` (sealed: `FromTarget(id)`, `FromBuild(xM, yM)`); `XpHistory` (awards still in the window); `XpEvent` (sealed: `HitXp`, `KillXp`, `RoleActionXp`); `XpRules(progression)` with `targetScaling`, `earn(event, history:, at:)` → `XpAward(xp, history)`, `captureShares(pot)`, `victoryXp`, `split(xp)` → `(unit:, section:)`.
- `section_level.dart`: `SectionLevel(progression)` with `levelFor(sectionXp)`, `cap(level)`, `maxUnits(level)`.
- `Diminishing.sameSpotRadiusM`; `XpSources.nearCommanderPerMin` removed.

Decisions by the owner (2026-11-02), recorded in battle_team on `bt/m5-02-xp`:
- Decision 197: target scaling (UNIT-09) and team power (UNIT-12, SOC-05) use earned XP, spent or not.
- Decision 198: a build within 10 m of one of the unit's builds in the window is at the same spot (`diminishing.same_spot_radius_m`).
- Decision 199: no XP for time near the commander; UNIT-08 and `near_commander_per_min` deleted (revises decision 8).

Checks: analyze `--fatal-infos` clean, format clean, 475 tests pass, coverage 100 % (test optimization off).

Choices:
- An award counts as a repeat of each earlier award from the same origin less than `window_s` before it, and each repeat multiplies by `factor_per_repeat`: 2, 1, 0.5 XP for three hits on one target with the defaults.
- "The same target" covers every XP that comes from a unit: hits, kills, heals, repairs and spotting reports.
- Hits and kills are separate events; whether a killing shot also earns the hit XP (and the hit money of M5.3) is for the host to decide in M5.12, with the owner if no rule says.
- The section share is taken from every award, victory XP and capture shares included; the unit keeps the rest as earned and unspent XP.
