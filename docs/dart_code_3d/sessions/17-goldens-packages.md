# Session 17 — Goldens from the shared packages, images in one tree

**Branch:** `dc3d/s17-goldens-packages` · **Depends on:** G1 and G2 of [`docs/goldens/`](../../goldens/README.md).
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read:** [`docs/goldens/README.md`](../../goldens/README.md) (the tree, the packages) and the session logs of G1 and G2.

## Goal

dart_code_3D tests its screens with `screen_goldens` and its 3D frames with
`flutter_scene_goldens`, and every image of the app is under `apps/dart_code_3d/goldens/`.
The app's own harness code goes.

## Checklist

1. **2D.** `test/flutter_test_config.dart` calls `ScreenGoldens.configure` (themes `light`
   and `dark`, default locale `en`, `wrap` built on the app's `pumpApp`).
   `test/helpers/goldens.dart` becomes a thin wrapper over `screenGoldenTest`, keeping
   its app parameters (`settingsBloc`, `router`, `repository`, `capabilities`).
2. **Move the images**: `git mv` the 430 goldens to `goldens/screens/…` and the 48
   baselines of `visual_baselines/` to `goldens/scenes/…`, by a script kept in the
   session log. The bytes do not change.
3. **3D.** `integration_test/visual/` keeps only the app's scenarios, as
   `SceneScenario`s; `visual_test.dart`, `frame_stats.dart`,
   `test_driver/visual_driver.dart` and `test_driver/image_compare.dart` go. Delete
   hawkbee `tool/visual_test.sh`: `dart run flutter_scene_goldens:capture` replaces it.
4. **Prove nothing changed**: the whole unit suite and the 3D capture pass **without**
   updating a single image.
5. **Docs** to the new paths and commands: `architecture.md` §9, `agent-workflow.md` §5
   (pitfalls, regenerating) and §6 (the PR template's image links), `README.md`.
6. **Gates** and **finish** (`agent-workflow.md` §5, §6).

## Stop and ask when

- An image differs after the move: say which and why. Never regenerate to make it pass,
  unless G1's log records that the owner chose to adopt golden_screenshot's rendering:
  then regenerate all 2D goldens once, in a commit of its own, and look at a sample of
  each screen.

## Acceptance criteria

- [ ] Every PNG of the app is under `goldens/`; `visual_baselines/` and the per-test
      `goldens/` folders are gone; failures and captures go to `build/goldens/`.
- [ ] The unit suite (100 % coverage) and the 3D capture pass with the images unchanged.
- [ ] `tool/visual_test.sh` and the app's copies of the harness are deleted; the docs
      name the new commands.

## Session log
