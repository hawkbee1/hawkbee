# Session M6.5: Endpoints and sign-in

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 5. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m6-05-endpoints` · **Depends on:** M6.2, M6.4.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:static-security`, `appwrite:dart`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/03-networking.md` (consequences: JWT, endpoints); `plan/stack/06-accounts-and-services.md` (API keys, origins); `plan/stack/08-workload-placement.md` (client trust); `plan/specs/80-ai-and-automation.md`; HQ-07; the session logs of M5.9 (API key format), M5.11 (rate limit, `EnterBattle`), M5.15 (acknowledgement after the write-ahead log), M5.18 (`ApiKeys`), M5.19 (`serve`), M5.21 (`bt_` resources, the local Appwrite) and M6.4.

## Notes
- Endpoints on `dart:io` `HttpServer` (WebSocket upgrade included), or a package checked with context7 and `packages_check_licenses`. They are adapters: the sign-in, the request-ID memory and the queues are core code tested without sockets.
- The JWT check: `dart_appwrite` with `setJWT` and `Account.get`. The API key check: the hash lookup of `battle_backend`'s `ApiKeys`. One port, one contract suite, a fake and the Appwrite adapter; the Appwrite run is tagged and opt-in (M5.21's notes say how the live suites run).
- Record the rate-limit values in `stack/03` (battle_team, same branch name), and whether AI agents may hold a socket (the issue assumes they may, so they get the same fog-filtered view as players, AI-03).
- How long the host remembers request IDs, and the queue bound of a slow client: say which and why in the log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m6-networking.md, Issue 5).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
