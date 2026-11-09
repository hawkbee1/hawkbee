# Session M6.8: A battle over the network, P-04

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 8. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host`, `packages/battle_client` · **Branch:** `bt/m6-08-network-load` · **Depends on:** M6.5, M6.7.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/milestones/performance-tests.md` (P-02, P-04); `plan/stack/01-simulation-host.md` (load, battles per process); `plan/stack/03-networking.md` (traffic estimate); the session logs of M5.19 (load script, `saint_lo`), M6.5 and M6.7.
**Measure** AOT, on the loopback interface, on `saint_lo`.

## Notes
- Drive M5.19's load script through `battle_client`s instead of `SimulationHost.submit`: the same orders, now with sign-in, acknowledgements and the update stream. Measure the clients' CPU apart from the host's.
- Count bytes on the wire per socket, compressed and not, if the WebSocket compression is on.
- Replace `stack/03`'s traffic estimate with the measurement and fill P-04 (battle_team, same branch name); change the 5 Hz cadence or the grouping only with the measurement, and say so in the log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m6-networking.md, Issue 8).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
