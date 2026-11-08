# Session M6.2: Messages between the host and its clients

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 2. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_protocol` (`hawkbee1/battle_protocol`) · **Branch:** `bt/m6-02-messages` · **Depends on:** M6.1.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/03-networking.md` (update policy, traffic estimate); `plan/stack/08-workload-placement.md` (what the client computes); MAP-49, RELIC-10, COMBAT-57 (decisions 232 to 234); the session logs of M5.9 (codecs, samples, sizes), M5.11 (refusal codes), M5.14 (the delta layer) and M6.1.

## Notes
- The messages are a family of their own beside commands, events and log entries, with the same `FieldWriter`/`FieldReader` codecs. The log format of M5.9 does not change.
- A section's view reuses the events' and the snapshot's value types where they fit; the snapshot itself (M5.15) is the host's private format and is never sent.
- Positions of moving units: quantised as `Position` is; say in the log whether a tick sends positions only or positions with the path and speed, and why.
- Record the grouping of shots per unit per tick and the first-person move rate in `stack/03` (battle_team, same branch name).

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m6-networking.md, Issue 2).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
