# Session M6.4: The update stream of a section

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 4. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m6-04-stream` · **Depends on:** M6.2, M6.3.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/03-networking.md` (update policy); `plan/stack/07-engineering-principles.md` (Observer); MAP-08, MAP-49, RELIC-10, RELIC-16, COMBAT-57; decisions 232 to 234; the session logs of M5.13 (relic owner changes, victory timer), M5.14 (the delta layer), M5.15 (scripted battle, recovery), M6.2 and M6.3.

## Notes
- Subscribers are in-process objects here; sockets come in M6.5. A subscriber is a port the endpoints implement.
- The "nothing hidden" test runs over the whole scripted battle of M5.15, for every section, at every update.
- An event that names a unit the section does not see: cut it down or drop it, and say per event type which one in the log.
- The alerts a player has not received yet (decision 233) are battle state: they must survive a restart. Derive them from the log (owner changes and `EnterBattle` entries) or keep them in the snapshot, and say which in the log. An alert is delivered once per player, on the player's next connection. A case no rule (COMBAT-57 among them) covers is a new question with "Assumed:" in `95-open-questions.md`.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m6-networking.md, Issue 4).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
