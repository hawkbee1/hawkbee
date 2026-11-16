# Session G1: `screen_goldens`

**Package:** new, `packages/screen_goldens`, its own public repository `hawkbee1/screen_goldens` and a hawkbee submodule (dc3d §2, "Creating a new app or package"). · **Branch:** `goldens/g1-screen-goldens` · **Depends on:** nothing.
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:license-compliance` (the third-party packages).
**Read:** [`docs/goldens/README.md`](../README.md) entirely (the tree, the screens, the third-party packages); `apps/dart_code_3d/test/helpers/goldens.dart`, `test/flutter_test_config.dart` and `test/helpers/test_tags.dart` (what this package generalises); dc3d `agent-workflow.md` §5 (golden pitfalls).

## Goal
Golden tests at several screen sizes, themes and locales, with real fonts, into the project's `goldens/screens/` tree. No flutter_scene, no app type, nothing of hawkbee.

## Steps
1. **Spike first, half a session at most: golden_screenshot and golden_lens.** In a scratch branch of dc3d, render three of its existing goldens (one per screen size) through golden_screenshot with no device frame at pixel ratio 1, its fonts loader, tolerance 0. Record in the session log: are the images byte-identical to dc3d's? What does its font loader change? Does its comparator compose with one that moves the files (step 5)? Then install golden_lens over the same comparator, break one golden on purpose and judge its report: right widget, right line, written where we say.
   - **Use golden_screenshot inside this package** when the three images are identical, or differ only by something the owner accepts (ask, with both images). Else write the helpers here (dc3d's code is the base) and say why.
   - **golden_lens** is at most an opt-in of `ScreenGoldens.configure` (`failureReports: true`), reports under `build/goldens/reports/`; drop it if its report is wrong or it does not compose.
2. **Create** the package (Very Good CLI `flutter_package`, `workspace: true`), its repository and submodule. Description: "Golden tests at several screen sizes, themes and locales, in one image tree per project."
3. **`GoldenScreen`**: a name and a logical size at pixel ratio 1, with the four presets of the README; a project adds its own.
4. **`GoldenVariant`**: screen × named theme × locale × text scale, and its file name by the README's rule.
5. **`ProjectGoldenComparator`**: resolves every golden under `<project>/goldens/screens/<test path>/` and writes failures under `build/goldens/failures/`, never next to the test.
6. **`ScreenGoldens.configure(...)`**, called once from the project's `test/flutter_test_config.dart`: the project's themes by name, its default locale, `wrap: (child, variant) => …` (the app around the widget: theme, locale, providers), the comparator, and `loadProjectFonts()` (every family of `FontManifest.json`).
7. **`screenGoldenTest(description, {name, builder, screens, themes, locales, textScales, setUp, pump})`**: one `testWidgets` per variant, tagged `golden`, sizing `tester.view` and resetting it. Keep dc3d's lessons: no library-level `@Tags`; `pump:` for indeterminate animations.
8. **README** of the package: install, the config file, one test, the tree, how to regenerate.
9. **Gates** and **finish** (dc3d §5, §6).

## Tests to write
- Variant names: every combination, the default locale left out, a text scale suffix.
- The comparator: a test at `test/a/b_test.dart` reads and writes `goldens/screens/a/b/…`; a failure lands under `build/goldens/failures/`.
- The matrix: the tests registered for a given set of screens, themes and locales, each tagged `golden`.
- Fonts: a family of the manifest is loaded; a missing manifest fails with a clear message.
- Goldens of a sample widget of the package itself, at the four screens, in its own tree.
- 100 % coverage.

## Stop and ask when
- golden_screenshot's images differ from dc3d's: show both, the owner decides (adopt and regenerate dc3d's 430 goldens in session 17, or not).
- A licence check flags a dependency.

## Acceptance criteria
- [ ] The spike's findings and the decision for each third-party package are in the session log.
- [ ] `hawkbee1/screen_goldens` exists, is a hawkbee submodule, and resolves and tests with no hawkbee sibling.
- [ ] The tests above pass at 100 % coverage; format and `dart analyze --fatal-infos` are clean.
- [ ] The package's own goldens are under its `goldens/screens/` and nowhere else.

## Session log
