# Session M5.7: Wars, sections and guilds

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 7. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m5-07-wars-guilds` · **Depends on:** M5.6.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/40-newcomers-and-social.md` §2b, §4, §5; UNIT-24, UNIT-30 to UNIT-32; `plan/data/units.yaml` `guild_creation_min_level`, `guild_size`, `commander_levels`; `plan/data/battle.yaml` `battle_start`; Q-SOC-18 (assumed guild levels); decisions 83, 104, 107, 108, 122, 124, 146, 153, 155.

## Notes
- These rules run in Appwrite Functions (stack decision 8): pure functions over plain models, no host types.
- Guild size follows Q-SOC-18 (assumed, placeholders in `guild_size`): cite the question in the doc comment.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 7).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
