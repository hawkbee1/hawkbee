# Session M5.7: Wars, sections and guilds

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 7. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m5-07-wars-guilds` · **Depends on:** M5.6.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/40-newcomers-and-social.md` §2b, §4, §5; UNIT-24, UNIT-30 to UNIT-32; `plan/data/units.yaml` `guild_creation_min_level`, `guild_size`, `commander_levels`; `plan/data/battle.yaml` `battle_start`; Q-SOC-18 (assumed guild levels); decisions 83, 104, 107, 108, 122, 124, 146, 153, 155.

## Notes
- These rules run in Appwrite Functions (stack decision 8): pure functions over plain models, no host types.
- Guild size follows Q-SOC-18 (assumed, placeholders in `guild_size`): cite the question in the doc comment.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m5-simulation-host.md, Issue 7).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02) on `main` (M5.6 merged), in `packages/battle_rules`:
- `lib/src/war/war.dart`: `War(id, minStartingMoney, planned, current, sections, over)` with `plan`, `startBattle`, `endBattle` and `join` → `WarChange` (sealed: `WarChanged`, `WarRefused(WarRefusal)`); `WarRules(battle:, morale:)` with `atBattleStart(type)`.
- `lib/src/war/guild.dart`: `Guild(id, roles, xp, optedIn)` with `GuildRole` (chief, member, trainee); `GuildRules(progression)` with `levelOf`, `maxSections`, `hasRoom`, `create`, `apply`, `accept`, `refuse`, `leave`, `handOver`, `disband`, `optIn` and `earned` → `GuildChange` (sealed: `GuildChanged`, `GuildRefused(GuildRefusal)`).
- `units.yaml` `progression.guild_size` is now read (`GuildSize`, assumed, Q-SOC-18). `GameData.parse` checks that `battle_start` restores full AP and HP and base morale, the only values with a rule.

Decisions by the owner (2026-11-02), recorded in battle_team on `bt/m5-07-wars-guilds`:
- Decision 212: every battle starts with all units in storage, the guild camp included; until the chief deploys the camp next to the HQ, the guild uses the HQ portal.
- Decision 213: trainees count toward a guild's size; a full guild takes no trainee and is not offered to newcomers.
- Decision 214: the camp follows the chief on a handover and is destroyed on disband.
- Decision 215: only the chief opts the guild in or out of the newcomer list.

Checks: analyze `--fatal-infos` clean, format clean, 607 tests pass, coverage 100 % (test optimization off).

Choices:
- A war ends at the end of a battle when no other battle is planned (SOC-17): the admin plans the next battle before the running one ends.
- Battles of a war run one at a time, so a section is in one battle at a time (SOC-42, SOC-43).
- A section applies only to a guild of its team while a battle runs (guild sections stay together, SOC-20); between battles any guild of the war.
- A guild's XP counts every XP point its sections' units earn while in it, trainees' included (assumed, Q-SOC-18). It never drops.
- What a section keeps between battles (units, XP, evolution, weapons, money, prisoners) lives in the section's data, which these rules leave unchanged; no section model here (the host and the functions hold it).
