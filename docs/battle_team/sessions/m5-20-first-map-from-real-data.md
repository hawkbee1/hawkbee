# Session M5.20: First map from real data

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 20. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_map` (`hawkbee1/battle_map`) · **Branch:** `bt/m5-20-real-map` · **Depends on:** M5.8.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:license-compliance`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/05-map-format.md` (authoring, licences); MAP-01, MAP-02, MAP-04; the session log of M5.8.

## Notes
- Ask the user which 10 × 50 km area to use before downloading anything.
- Downloaded data is untrusted input: keep it outside the repository, in its own folder; commit only the builder code and, if the user agrees, the resulting tiles.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 20).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
