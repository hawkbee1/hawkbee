# Session M5.8: Map format and loader

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 8. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_map` (`hawkbee1/battle_map`, new) · **Branch:** `bt/m5-08-map` · **Depends on:** M3 (merged).
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:license-compliance`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/05-map-format.md` (all of it); MAP-01 to MAP-05, MAP-10, MAP-36, MAP-40; RELIC-02; HQ-01; `plan/data/terrain.yaml`; the M3.2 session log (`NavigationMap`, the fixture format).

## Notes
- New package: the procedure of dc3d §2 with the Very Good CLI MCP `create` (`subcommand: dart_package`, `name: battle_map`, `output_directory: packages`, `workspace: true`, a description without a colon). Create `hawkbee1/battle_map` with `gh repo create --public`, add it to the root `workspace:` and melos `format` lists, and apply the new-package pitfalls of dc3d §2 (and of the M4.1 and M3.1 session logs).
- Check the image package's API with context7 before use, and its licence with `packages_check_licenses`.
- The loader builds `battle_pathfinding`'s `NavigationMap`; do not copy its model.
- Keep the committed test map small (a few tiles of a few cells is fine: make the tile size a parameter whose default is 256). Big synthetic maps are generated in tests, never committed.
- The `bin/` builder reads and writes files; `lib/` takes bytes and text.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 8).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
