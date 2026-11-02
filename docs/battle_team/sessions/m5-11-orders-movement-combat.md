# Session M5.11: Orders for movement and combat

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 11. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m5-11-orders` · **Depends on:** M5.10.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/07-engineering-principles.md` (Facade, Chain of Responsibility, Decorator); `plan/stack/08-workload-placement.md` (path check, first-person shots, client trust); `plan/specs/80-ai-and-automation.md`; the session logs of M3.3, M4.3 to M4.10 and M4.11 ("Deferred to M5").

## Notes
- Every order of the M4 rules goes through the one handler; tests drive the handler, not the rules directly.
- Re-check at the end of an AP wait (deferred from M4.11): a waiting order keeps its command and runs the checks again at `at`.
- Merge the three refusal enums into one sealed type in `battle_rules` (on the same branch name there) or wrap them in the host: say which in the session log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 11).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).
