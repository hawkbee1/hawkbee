# Session M5.18: Appwrite data and functions around battles

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 18. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** hawkbee `backend/`, `packages/hawkbee_schema` · **Branch:** `bt/m5-18-appwrite` · **Depends on:** M5.7, M5.13.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `appwrite:dart`, `vgv-ai-flutter-plugin:static-security`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/02-persistence.md`, `plan/stack/06-accounts-and-services.md`, `plan/stack/08-workload-placement.md`; hawkbee `docs/project-setup.md`; `backend/appwrite.config.json`; the session logs of M5.7, M5.9 and M5.13.

## Notes
- Tables and functions are declared in `backend/appwrite.config.json` and deployed with the Appwrite CLI to the local instance only. Never deploy to Appwrite Cloud.
- Admins are an Appwrite team or label, checked in the function (stack decision 6).
- Record in the session log what the 30-second synchronous limit turned out to be on the local instance.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 18).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
