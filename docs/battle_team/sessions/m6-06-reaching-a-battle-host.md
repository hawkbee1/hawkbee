# Session M6.6: Reaching a battle's host

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 6. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`docker/`), hawkbee `backend/`, `hawkbee_schema` · **Branch:** `bt/m6-06-host-address` · **Depends on:** M6.5.
**Skills:** `appwrite:cli`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/01-simulation-host.md` (hosting, placement); `plan/stack/02-persistence.md` (resource IDs, `bt_` prefix); `docs/project-setup.md` §4 to §6 (local Appwrite); the session logs of M5.18, M5.19 and M5.21.

## Notes
- Needs the Docker host and the local Appwrite. From the dev container `factory1`, the endpoint is `http://appwrite-traefik/v1`, but there is no Docker socket: do the code steps there and leave the image build and the compose run to the owner, with the commands in the log (as M5.19 did). The tooling API key rule of M5.21 applies.
- Table permissions: a player reads the address of the battles they play in, nothing more. Check what Appwrite 2.7.1 row permissions allow before choosing between a column on `bt_battles` and a hosts table.
- The live reverse proxy and its certificates belong to the live provider, which the owner leaves open: write the local setup and what live needs, nothing provider-specific.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m6-networking.md, Issue 6).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
