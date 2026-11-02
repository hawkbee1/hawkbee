# Session M5.15: Write-ahead log, snapshots and recovery

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 15. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m5-15-wal` · **Depends on:** M5.11.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `appwrite:dart`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/02-persistence.md` (all of it); P-03 in `plan/milestones/performance-tests.md`; the session log of M5.9 (log format).

## Notes
- The local Appwrite instance: in-container tools reach it by its Docker name (hawkbee `docs/project-setup.md`). Tests that need it are tagged, opt-in, and carry `skip_very_good_optimization` (dc3d §2 pitfalls).
- Kill-and-recover tests run in process: stop the host object at a chosen entry, build a new one from the stores, compare states.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 15).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
