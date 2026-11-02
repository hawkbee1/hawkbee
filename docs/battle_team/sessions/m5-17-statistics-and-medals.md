# Session M5.17: Statistics and medals

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 17. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_stats` (`hawkbee1/battle_stats`, new) · **Branch:** `bt/m5-17-stats` · **Depends on:** M5.9.
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `appwrite:dart`.
**Read** (`plan/` is `apps/battle_team/plan/`): decision 143; SOC-22, SOC-24 to SOC-26, SOC-29; COMBAT-35; `plan/data/medals.yaml`; `plan/stack/08-workload-placement.md` (functions, client trust); the session log of M5.9.

## Notes
- New package: the procedure of dc3d §2 with the Very Good CLI MCP `create` (`subcommand: dart_package`, `name: battle_stats`, `output_directory: packages`, `workspace: true`, a description without a colon). Create `hawkbee1/battle_stats` with `gh repo create --public`, add it to the root `workspace:` and melos `format` lists, and apply the new-package pitfalls of dc3d §2 (and of the M4.1 and M3.1 session logs).
- The `daily_stats` function goes in hawkbee `backend/functions/daily_stats/` with a vendored copy of the package (stack decision 8, as `ping` vendors `hawkbee_schema`).
- "Far above the norm" for hit rates: propose the threshold to the user before writing it to `plan/data`.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 17).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
