# Session M5.6: Teams, newcomers and the HQ manager

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 6. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m5-06-teams` · **Depends on:** M5.2.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/40-newcomers-and-social.md` §1, SOC-29, SOC-30; `plan/specs/50-hq.md` §2; `plan/data/battle.yaml` `teams`; `plan/data/medals.yaml` `points`; decisions 47, 93, 101, 103, 121, 129.

## Notes
- Balancing by power with guilds kept together is a partition problem: a greedy largest-block-first method is enough if its worst case is stated in the doc comment and tested.
- Medal points come from the medals a player holds (M5.17 computes them); here they are an input.
- A newcomer's commander arrives next to his section's portal (HQ-46, decision 129; `StorageRules.placeOf`), never blocked by an enemy (decision 210).

## Acceptance criteria
- [x] The acceptance criteria of the issue (m5-simulation-host.md, Issue 6).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02) on `main` (M5.5 merged), in `packages/battle_rules`:
- `lib/src/teams/teams.dart`: `TeamRules(battle:, medals:)` with `sectionPower`, `formTeams` (greedy, largest block first: a guild or a section without one), `newcomerTeam`, `guildOffer`, `medalPoints` and `hqManager`; `TeamSection`, `ManagerCandidate`; `HqManager.delegate` → `Delegation` (sealed: `Delegated`, `DelegationRefused`).
- `battle.yaml` `newcomers.guilds_offered` (the 4 of SOC-03) read as `BattleSettings.guildsOffered`; `GameData.parse` checks `teams.count` ≥ 2 and `guilds_offered` ≥ 1. battle_rules and battle_team merge together: the parser needs the new key.

Decisions by the owner (2026-11-02), recorded in battle_team on `bt/m5-06-teams`:
- Decision 209: a trainee section stays with its guild when teams are balanced.
- Decision 210: a new section's commander always arrives next to his portal; the enemy block is for bought units only.
- Decision 211: exact ties (newcomer team, HQ manager) are drawn with the seeded random.

Checks: analyze `--fatal-infos` clean, format clean, 584 tests pass, coverage 100 % (test optimization off).

Choices:
- Balancing worst case, stated in the doc comment and tested: the strongest team is ahead of the weakest by at most the power of the largest block. Ties between blocks go by id, so the same sections always form the same teams.
- A team stays empty when there are fewer blocks than teams; newcomers join it first. Open point: such a team has no HQ manager at the battle start (HQ-07 fixes him then), and nothing says who manages it once a newcomer joins.
- The offer lists the opted-in guilds first, then the others, each in drawn order. Guild ids are sorted before the draw, so a seed always draws the same.
- Team power counts every unit a section owns; the host passes their XP.
- A delegation goes to another player of the team, online or not (HQ-08 says only that nobody takes over).
