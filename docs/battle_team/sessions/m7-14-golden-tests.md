# Session M7.14: Battle Team's first goldens, 2D and 3D

**Issue:** none in the milestone: asked by the owner on 2026-11-16. This file and [`docs/goldens/README.md`](../../goldens/README.md) are the specification.
**Package:** `apps/battle_team` (+ `linux/` platform folder) · **Branch:** `bt/m7-14-goldens` · **Depends on:** G1 and G2 of `docs/goldens/`; shares `linux/` with M7.13 (whichever runs first adds it).
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:internationalization`.
**Read:** `docs/goldens/README.md` (the tree, the screens, the packages) and the session logs of G1 and G2; the README of both packages; `docs/battle_team/agent-workflow.md` §6; dc3d `agent-workflow.md` §5 (golden pitfalls).

## Steps
1. **Fix `docs/battle_team/agent-workflow.md`.** §6 "The 3D seam" says what is true: no GPU in `flutter test`, frames tested under `integration_test` with `flutter_scene_goldens`, `SceneBattleWorld` out of the unit coverage only. §4 and §6 require goldens for every screen and panel a session adds or changes, and 3D goldens for every drawing change.
2. **Fonts.** The app draws text in Poppins through `google_fonts` with runtime fetching off, so tests show boxes. Bundle Poppins (the weights the app uses; its OFL licence in `assets/licenses/` and in the credits) where `google_fonts` finds bundled fonts, so the fonts loader of `screen_goldens` loads it.
3. **Configure** `screen_goldens` in `test/flutter_test_config.dart`: its one theme, named `default` until the owner decides what it is (`docs/goldens/README.md`, "After the goldens exist"); default locale `en`; `wrap` on `test/helpers/pump_app.dart`.
4. **2D goldens** (`flutter test`, `FakeWorld` for the scene, so the 3D area is empty), at `phone`, `phoneLandscape`, `tablet` and `desktop`, in `en` and `fr`:
   - sign in, sign up, the battle list (in a battle, not in one, a map not bundled);
   - the battle view's overlays: the status strip with an alert, the toolbar, the selected unit with a previewed move and its cost, the weapon panel;
   - the side panel: Units (the HQ row for the manager and for another player, the HQ move armed, the tab counts, no unit on the field), Storage (a lock, a blocked portal, a recall), Shop (with and without a unit selected);
   - the settings page.
   Realistic content from `test/helpers/fake_host.dart` and the recorded streams; long names; empty states.
5. **`linux/`** if M7.13 has not added it: `tool/add_linux_platform.sh apps/battle_team battle_team <id>`, Flutter GPU on for Linux as for the other platforms.
6. **3D goldens** (`integration_test/scenes/`, `flutter_scene_goldens`): the real `SceneBattleWorld` on the bundled 1 km map, fed by a fixed `SectionView`, with no time passing (no unit interpolation, `LiveShots` frozen) and fixed cameras, at the four screens. Scenarios: `top_down_start` (units, HQs, relics), `first_person_commander`, `fog` (lit, seen once, never seen), `move_preview`, `shots` (tracer, muzzle flash, hit mark), and `battle_screen`: the whole `BattleView` with its overlays over the real scene, the image the owner looks at.
7. **Gates** (§4, §6; the suite stays at 100 % coverage, `optimization: false`) and **finish** (§5): list every new image in the PR with links to the raw files.

## Stop and ask when
- A 3D scenario is not deterministic (two runs differ beyond the tolerance): find the time source; do not raise the tolerance.
- llvmpipe cannot draw something the app needs (a shader, a blend mode): record the scenario and the error, leave it out, tell the owner.
- A golden shows a layout fault (overflow, clipped text, a panel over another) at one of the four screens: report it with the image; fix it only when the fix is small and local, else list it for the owner.

## Pitfalls
- Look at each new image (Read tool) before committing it: a golden of a broken layout protects the fault.
- Generate with the committed theme and fonts.
- `phoneLandscape` is short (390 logical pixels high): the side panel and the unit sheet share it. That is where faults will show.

## Acceptance criteria
- [ ] The 2D goldens of step 4 and the 3D scenarios of step 6 pass; every PNG is under `apps/battle_team/goldens/`.
- [ ] The workflow doc no longer says the scene cannot be tested, and asks for goldens.
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log
