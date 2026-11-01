# Session M4.11: Scenario harness

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 11. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-11-scenarios` · **Depends on:** M4.3 to M4.10.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): the session logs of M4.3 to M4.10; R-08 and R-09 in `plan/specs/96-design-risks.md` (tuning notes); `plan/milestones/performance-tests.md` (conventions, P-02).

## Notes
- `bin/scenario.dart` reads a scenario file and the data directory (`--data`, default `../../apps/battle_team/plan/data`). File reading stays in `bin/`.
- Scenarios are YAML files committed in `scenarios/`. The tests run them through `lib/`, not as a process, so coverage counts.
- Besides the readable summary, print one machine-readable line per run (performance-tests conventions).
- Record in the session log the numbers R-08 discusses: time to spend a full pool, sustained speeds, a push's progress per hour.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m4-rules-core.md, Issue 11).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
_Written by the session agent when it finishes._
