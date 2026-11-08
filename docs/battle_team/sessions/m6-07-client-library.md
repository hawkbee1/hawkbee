# Session M6.7: Client library

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 7. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_client` (`hawkbee1/battle_client`, new) · **Branch:** `bt/m6-07-client` · **Depends on:** M6.2, M6.4 (tests against M6.5's endpoints once it is merged or stacked).
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:license-compliance`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/03-networking.md`; `plan/stack/07-engineering-principles.md` (ports, packages); `plan/stack/08-workload-placement.md` (what the client computes); the session logs of M5.9 (codecs on the web), M6.2, M6.4 and M6.5.

## Notes
- New package: the procedure of dc3d §2 with the Very Good CLI MCP `create` (`subcommand: dart_package`, `name: battle_client`, `output_directory: packages`, `workspace: true`, a description without a colon). Create `hawkbee1/battle_client` with `gh repo create --public`, add it to the root `workspace:` and melos `format` lists, and apply the new-package pitfalls of dc3d §2.
- Pure Dart, no Flutter. The transport adapter on `web_socket_channel` runs on native and web; check its API with context7 and its licence. Time comes from an injected `Clock`, backoff jitter from an injected random.
- The JavaScript check: compile with dart2js and run the view tests' recorded streams on Node, as M5.9 did for the codec.
- The order pre-check with `battle_rules` (stack decision 8) is M7's, in this package.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m6-networking.md, Issue 7).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
