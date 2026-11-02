# Session M5.9: Commands, events and the battle log

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 9. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_protocol` (`hawkbee1/battle_protocol`, new) · **Branch:** `bt/m5-09-protocol` · **Depends on:** M4 (merged).
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:static-security`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/02-persistence.md` (what is logged); `plan/stack/03-networking.md` (what orders carry); `plan/stack/06-accounts-and-services.md` (API keys, origins); `plan/stack/07-engineering-principles.md` (Command pattern); AI-05; decisions 162, 166, 183; the session logs of M4.3 to M4.11 (the orders and outcomes that exist).

## Notes
- New package: the procedure of dc3d §2 with the Very Good CLI MCP `create` (`subcommand: dart_package`, `name: battle_protocol`, `output_directory: packages`, `workspace: true`, a description without a colon). Create `hawkbee1/battle_protocol` with `gh repo create --public`, add it to the root `workspace:` and melos `format` lists, and apply the new-package pitfalls of dc3d §2 (and of the M4.1 and M3.1 session logs).
- The package depends on no other battle package: commands carry IDs and plain values (positions, cells, amounts). The host maps them to rules.
- Binary encoding: write it by hand on `ByteData`, or use a package after checking it with context7; positions are quantised (stack decision 3).
- The hash of an API key: a slow, salted hash is not needed for a random 256-bit key; state the choice in the doc comment (static-security skill).

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 9).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
