# Session M5.10: Host scaffold, battle state and clock

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 10. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`, new) · **Branch:** `bt/m5-10-host` · **Depends on:** M5.1, M5.8, M5.9.
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/01-simulation-host.md`; `plan/stack/06-accounts-and-services.md` (Sentry); `plan/stack/07-engineering-principles.md`; COMBAT-01, COMBAT-02, UNIT-31; the "Deferred" notes of the M3.6 and M4.11 session logs.

## Notes
- New package: the procedure of dc3d §2 with the Very Good CLI MCP `create` (`subcommand: dart_cli`, `name: battle_host`, `output_directory: packages`, `workspace: true`, a description without a colon). Create `hawkbee1/battle_host` with `gh repo create --public`, add it to the root `workspace:` and melos `format` lists, and apply the new-package pitfalls of dc3d §2 (and of the M4.1 and M3.1 session logs).
- The host's core holds no I/O: it takes a `Clock`, a `SeededRandom` and the ports. Adapters live in `lib/src/adapters/` and are the only code that touches files, Appwrite or Sentry.
- Lazy state: a unit's AP and morale are read at time t from their last update and rates; the tick never touches idle units.
- Sentry: check the `sentry` package API with context7. The DSN comes from the environment, never from the code.
- Separate the shared definitions from each battle's settings (deferred from M4.11): `GameData` now fuses them.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 10).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
