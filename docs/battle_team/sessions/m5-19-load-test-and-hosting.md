# Session M5.19: Load test and hosting

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 19. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m5-19-load-test` · **Depends on:** M5.12 to M5.16.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/milestones/performance-tests.md`; `plan/stack/01-simulation-host.md` (estimate, hosting); the session logs of M4.11 and M5.10 to M5.16.

## Notes
- Before starting, ask the user which live provider hosts the containers (stack decision 1); the session needs only local Docker, but the image targets that provider.
- The container has no Docker socket: write the `Dockerfile` and compose file, build the AOT executable in the container, and ask the user to build and run the image on the host.
- Update the estimates of `stack/01` and `performance-tests.md` with the measurements (battle_team, same branch name).

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 19).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
