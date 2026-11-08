# Session M6.1: Protocol spike, dashwire against M5's protocol

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 1. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** none merged; the result goes to `apps/battle_team/plan/stack/03-networking.md` (`hawkbee1/battle_team`) · **Branch:** `bt/m6-01-protocol-spike` · **Depends on:** M5 (M5.19 #57, M5.21 #58).
**Skills:** `vgv-ai-flutter-plugin:license-compliance`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/03-networking.md` (options 3 and 5); `plan/stack/04-client-and-rendering.md` (`flutter_scene_net`); `plan/stack/01-simulation-host.md`; the session log of M5.9 (encodings, sizes).

## Notes
- Read dashwire's packages with the Dart MCP package tools (`read_package_uris`, `rip_grep_packages`) after adding them to a scratch package outside the workspace. Its `server` library and `dashwire_replication`'s relevancy are the parts that matter. Do not trust a README: check the code or its tests.
- The scratch code is not merged. Commit it on the branch of a scratch folder in the scratchpad, or describe it in the log. Only `stack/03` changes.
- The decision is the designer's. If the spike recommends dashwire, stop after writing it up and ask: it changes M6 Issues 2 to 8. If it recommends option 3, write "Assumed" in the log and the PR, and the next sessions go on (owner's rule of 2026-11-02).

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m6-networking.md, Issue 1).

## Session log
