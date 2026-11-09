# Session M7.10: Pings, map markers and team chat

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 10. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `packages/battle_protocol`, `packages/battle_host`, `packages/battle_client`, `apps/battle_team` · **Branch:** `bt/m7-10-chat` · **Depends on:** M7.1.
**Skills:** `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): SOC-34, SOC-36, SOC-37; decision 123; `plan/stack/03-networking.md` (sizes, update policy); the session logs of M6.2 (message conventions, samples) and M6.4 (fan-out).

## Notes
- New protocol messages under M6's conventions: committed samples, both encodings, sizes next to `stack/03`. Pings and markers to the team; team chat with history (SOC-36, a late joiner gets it with the view). Nothing crosses teams (SOC-34) — test with an enemy client receiving nothing.
- Design the chat message so the Discord sync (SOC-37, `battle_discord_bridge`, stack decision 7) plugs in later without a protocol change.
- App: ping and marker on the map, chat as a panel over the battle.
- End with a recording in this log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 10).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
