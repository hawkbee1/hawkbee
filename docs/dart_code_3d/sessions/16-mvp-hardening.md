# Session 16 — MVP hardening: AltMe end-to-end, performance, accessibility, docs

**Branch:** `dc3d/s16-mvp-hardening` · **Depends on:** 01–15.
**Skills:** `vgv-ai-flutter-plugin:green-gate`, `…:accessibility`, `…:static-security`,
`…:license-compliance`, `vgv-wingspan:review`.

## Goal

Prove the MVP works on the **reference project AltMe**, fix what that reveals, and
leave the project documented and green.

## Checklist

1. **AltMe end-to-end** in the app (Linux desktop), using the analysis flow with
   `https://github.com/TalaoDAO/AltMe` (default branch): record fetch, analysis,
   layout and save times, node and link counts, file size, load time in the viewer,
   frame times at the top level and inside the largest container. Do the same with
   flutter_scene. Compare with the budgets in `architecture.md` §1 and §7.3 and fix
   the biggest gap first (profile before optimizing; follow `flutter_scene-performance`).
2. **Web build** (`flutter build web --release`, also try `--wasm`): open the AltMe
   `.fscene` exported in step 1. Record load time and frame times in Chromium (via the
   hermes-playwright container if the owner has set up remote access, otherwise ask the
   owner to measure in their browser).
3. **Phones**: ask the owner to run a profile build on the Android phone and the iPhone 11
   with the AltMe map, and to report fps (the debug overlay shows it). Fix blocking issues.
4. **Accessibility pass** (`accessibility` skill) on every 2D screen: semantics, focus
   order, contrast in both themes, text scale 2.0, keyboard-only use of home/settings/
   analysis. The 3D world itself is exempt, but the info panel and search must work
   with screen readers.
5. **Security pass** (`static-security` skill): zip extraction limits, URL handling,
   no secrets, no logging of file contents.
6. **License check** (`license-compliance` skill) of all dependencies, including the
   bundled font.
7. **Green gate** on every package we own: analyze, format, tests, 100% coverage, and
   all goldens and 3D baselines up to date.
8. **Docs**:
   - `apps/dart_code_3d/README.md`: what the app does, how to run it per platform
     (Flutter GPU flags), how to run tests, goldens and `tool/visual_test.sh`, how to
     use the engine CLI;
   - update `architecture.md` wherever reality diverged (every deviation recorded in
     session logs);
   - update `future.md` with everything postponed during sessions 01–15.
9. Run `vgv-wingspan:review` on the whole `dart_code_3d` area. Fix what's actionable
   and list the rest in the PR.

## Acceptance criteria

- [ ] AltMe analyzable and flyable in the app. All numbers are in the session log.
- [ ] Web build opens an AltMe map.
- [ ] Every package green (table in the PR).
- [ ] Docs updated, `future.md` complete.

## Session log

_(to be filled by the agent)_
