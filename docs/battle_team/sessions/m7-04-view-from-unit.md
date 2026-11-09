# Session M7.4: View from a unit

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 4. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `apps/battle_team` · **Branch:** `bt/m7-04-view-from-unit` · **Depends on:** M7.3.
**Skills:** `vgv-ai-flutter-plugin:animations`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `flutter_scene` skills in `packages/flutter_scene`.
**Read** (`plan/` is `apps/battle_team/plan/`): decision 5, MAP-04, COMBAT-14; `plan/stack/04-client-and-rendering.md` (cameras, frame budget); `plan/stack/03-networking.md` (move stream rate, clock sync); the session logs of M7.1 and M6.7.

## Notes
- Both camera modes behind M7.1's camera seam (flutter_scene `CameraComponent`/controllers); enter first person from the selected unit, leave back to top-down.
- The AP shown between updates comes from `battle_client` (stack decision 8); record the first-person rate and its traffic next to `stack/03`'s estimate.
- Nothing the section does not see is drawn in either mode.
- End with a phone recording in this log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 4).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
