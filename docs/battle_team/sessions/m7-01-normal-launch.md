# Session M7.1: Normal launch, from the playtest

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 1. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `apps/battle_team` · **Branch:** `bt/m7-01-normal-launch` · **Depends on:** the playtest (merged).
**Skills:** `vgv-ai-flutter-plugin:layered-architecture`, `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:internationalization`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/04-client-and-rendering.md`; `plan/stack/07-engineering-principles.md`; `docs/battle_team/playtest.md`; the session log of the playtest (hawkbee1/battle_team#37) and M6.7.

## Notes
- `lib/playtest/` becomes the battle feature: a repository over `battle_client`, a bloc, and the 3D view behind the rendering seams the milestone's conventions ask for (name the GoF pattern in the doc comment of each seam).
- Remove Flame: the dependency, `lib/game/`, and the scaffold screens tied to it (stack decision 4, designer 2026-11-09). Keep `backend_status`, `loading` and `title` only where the new flow still uses them.
- Flavors `development`/`staging`/`production` open into the configured battle; sign-in stays the `env/` file until M7.12. The playtest flavor stays a thin entry over the same feature.
- Map attribution from `map.yaml` in a credits entry (Q-MAP-22).
- End with a screenshot in this log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 1).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
