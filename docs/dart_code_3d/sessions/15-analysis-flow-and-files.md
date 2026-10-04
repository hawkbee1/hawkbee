# Session 15 — New analysis flow, recent maps, open & share files

**Branch:** `dc3d/s15-analysis-flow` · **Depends on:** 09, 10, 11.
**Skills:** `vgv-ai-flutter-plugin:bloc`, `…:navigation`, `…:static-security`,
`…:accessibility`, `…:testing`.

## Goal

The full user journey: **pick a source → analyze with progress → open the 3D map**,
plus a list of recent maps, opening `.dc3d` / `.fscene` files, and sharing them.

## 1. Platform storage (`CodeMapStore` implementation, app side)

`apps/dart_code_3d/lib/app/storage/` (platform glue, the only place using
`path_provider` / `dart:io`, behind conditional imports):
- native: maps saved as files in the application support directory
  (`code_maps/<id>.dc3d` + `index.json` with summaries);
- web: `InMemoryCodeMapStore` (maps are lost on reload in the MVP; say so in the UI with
  a one-line notice and an **Export** button). Note IndexedDB persistence in `future.md`.

## 2. New analysis page (`analysis/`)

Source choices, shown according to platform support:

| Source | Native | Web | Widget |
|---|---|---|---|
| Public git repository | ✅ | ❌ (hidden; explain "browsers block GitHub downloads, use a zip") | URL field + optional branch/tag field. Validate with `GitUrl.parse`. Placeholder example: `https://github.com/TalaoDAO/AltMe` |
| Local folder | ✅ desktop; Android/iOS if `file_picker` directory picking returns a readable path, else hidden | ❌ | `file_picker` `getDirectoryPath()` |
| Zip file | ✅ | ✅ | `file_picker` `pickFiles(type: custom, allowedExtensions: ['zip'], withData: true)` |

- Below: a **rules summary** (non-default rules highlighted) + "Edit rules" → settings.
- "Analyze" starts `CodeMapRepository.build` through an `AnalysisBloc`.

## 3. Progress page

- Stage list (fetching → analyzing → laying out → saving) with a determinate progress
  bar, the current file name (ellipsized in the middle), elapsed time. **Layout + encoding
  take ~6 s on AltMe while the fraction stays at 80%** (session 09): animate the "laying
  out" stage (indeterminate bar) so the app never looks frozen.
- **Cancel** (confirmation) → `CancelToken`, back to the form, temp files gone.
- Failures map to clear messages with actions: not found/private ("Private
  repositories are not supported yet"), rate limited (retry later), network (retry),
  invalid archive, unsupported on web, analysis error (show details in an expandable box).
- Success → save → navigate to the viewer with the new map.
- Keep the screen awake during analysis on mobile only if a package is already a
  dependency. Otherwise skip it and note it in `future.md`.

## 4. Home: recent maps + open + share

- Recent list (newest first): name, source (folder / repo URL @ ref / zip), date,
  node count; tap → viewer; swipe/menu → delete (with undo snackbar), share.
- **Open file**: pick `.dc3d` or `.fscene` (`withData: true` on web) →
  `importBytes` → save → viewer. Errors: not a code map, newer format ("update the app").
- **Share/export**: mobile → `share_plus` (`ShareParams` with an `XFile`); desktop →
  `file_picker` `saveFile`; web → download (via `package:web` anchor with a blob URL, or
  `file_picker`'s web save if supported). Check each package's current API.
- Platform plumbing: Android `INTERNET` permission (release manifest); macOS entitlements
  `com.apple.security.network.client` + `com.apple.security.files.user-selected.read-write`;
  iOS: nothing for HTTPS.

## Tests (100% coverage) + visual

- Bloc tests for `AnalysisBloc` (all events, failures, cancel) and the home/recent bloc.
- Widget tests: URL validation, platform-dependent source options (use a
  `PlatformCapabilities` object injected in the widget tree; never call `kIsWeb`/`Platform`
  directly from widgets), progress, cancel dialog, every failure message.
- Storage tests with a temp directory (native implementation) and the in-memory one.
- Goldens (3 sizes × light/dark): new-analysis form (native and web variants, invalid URL
  error), progress at each stage with a long file path, each failure screen, home with
  6 recent maps (realistic names: AltMe, flutter_scene, …), empty home, web notice.
- E2E integration test (Linux desktop, tag `network`, opt-in): analyze
  `https://github.com/bdero/flutter_scene` @ `flutter_scene-0.23.0` through the UI,
  wait for the viewer, capture a 3D screenshot. Record the duration.

## Acceptance criteria

- [x] From an empty install: analyze a public GitHub repo, open it in 3D, find it in the recent
      list: run through the real UI on Linux (`tool/e2e_test.sh`, flutter_scene @
      `flutter_scene-0.23.0`: **25 s** from the tap on Analyze to the viewer, a 1.64 MB map). It
      survives a restart (store test). **Not run on a device**: sharing it, and opening the shared
      file in a web build (each piece is tested with fakes).
- [ ] Web: zip upload and `.dc3d` open work; git option hidden with the explanation. The git option
      is hidden with its explanation (widget tests and goldens) and `flutter build web` compiles,
      but **nothing was run in a browser** (none in the dev container). Tick it after a manual
      run.
- [x] Analyze/format clean, 100% coverage, goldens committed.

## Session log

**2026-10-04. Run by Claude (the planning model), not by a session agent.** Stacked on
session 14 (branch `dc3d/s15-analysis-flow`, created from `dc3d/s14-selection-hud`; the
`code_map_repository` branch is from its `main`, where session 11 is merged).

### Built
- **`code_map_repository`** (own PR): re-exports what the app needs to start a build (`CodeSource`
  and its variants, `GitUrl`, `CancelToken`), so the app does not import `code_source_client`
  (only the composition root, `bootstrap.dart`, does); `recent/load/save/delete` throw a
  `BuildFailure` of the new kind `storage`; `changes`, a stream that fires after a save or a
  delete. 40 tests, 100%.
- **Platform glue** (`lib/app/platform/`, `lib/app/storage/`): `PlatformCapabilities` (desktop,
  mobile, web: git, folders, persistent storage, how a map is exported) provided above the app,
  so widgets never ask `kIsWeb`; `FileDialogs` / `FileExporter` over `file_picker` 13 and
  `share_plus` 13 (thin classes, tested through fake platform implementations); `FileCodeMapStore`
  (`<id>.dc3d` + `index.json` holding each map's summary **and** project info, so listing and
  sharing never decode a map; atomic writes, one operation at a time, ids that cannot leave the
  folder) behind a conditional import (`createCodeMapStore`: files natively, memory on the web).
- **New analysis** (`/new-analysis`, one route, state-driven): `SourceFormCubit` (git URL +
  optional branch/tag validated with `GitUrl`, folder, zip), `AnalysisBloc` (progress, failure,
  retry, cancel, save), the form, the rules summary (changed rules as chips, "Edit rules" pushes
  the settings on top so the form is kept), the progress view (four stages, a determinate bar, the
  current file cut in the middle, elapsed time, **the "laying out" stage is indeterminate with a
  note**, so the app never looks frozen), the cancel dialog (also asked by the back button), and a
  failure screen per `BuildFailureKind` (localized; retry only where it can help; technical details
  folded). Success opens the viewer.
- **Home**: recent maps (newest first, swipe or menu to delete with an **undo** snackbar, tap to
  open, **Share** on phones / **Export** elsewhere), **Open file** (imports, stores and opens
  `.dc3d` / `.fscene`; says when a file is not a code map or comes from a newer app), a notice on the
  web that maps live in memory, a read-failure state. `HomeCubit` reloads on
  `CodeMapRepository.changes`.
- **Viewer**: opens a stored map by id (`/viewer?id=`); a map that is gone says so.
- **Plumbing**: Android `INTERNET` in the main manifest; macOS `network.client` and
  `files.user-selected.read-write`; plugin registrants regenerated (Linux, macOS, Windows).
- **E2E** (`tool/e2e_test.sh`, opt-in, network): see Measured.
- Tests: 730 unit and widget tests (100% coverage, generated routes excluded), 586 golden PNGs
  (new: the form in 7 states, the 4 progress stages, 10 failure screens, the cancel dialog, the home
  in 6 states; en and fr where the layout differs), 48 3D captures unchanged.

### Measured
End to end through the UI on Linux (profile build, software rendering, the network):
flutter_scene @ `flutter_scene-0.23.0` (11,050 spheres, 17,609 links): **25.1 s** from Analyze to
the viewer (download, analysis, layout, encoding, saving), the viewer's first frames **8.8 s**
later, **1,641,251 bytes** stored. The progress sat at 80% in "laying out" from about 10 s on,
which is why that stage is indeterminate.

### Bugs found (fixed)
- **`ViewerRoute` generated code was stale**: a page test saw `go('/viewer')` without `?id=`.
  Adding a field to a route needs `dart run build_runner build --delete-conflicting-outputs`.
- **The form's text controllers were `late final` with lazy initializers that read the context**:
  a form that never built the git fields (zip only, as on the web) created them during `dispose`,
  on a deactivated element. They are made in `initState`.
- Reviewing the goldens: the segmented buttons wrapped mid-word on a phone (short labels, no icons
  under 480 px), and the recent-map subtitle hid the size and date once the source line wrapped
  (two one-line texts).
- The middle ellipsis ate the file name (`…lared_type_resolver.dart`): it keeps three fifths from
  the end now.
- Test gotchas: `pumpAndSettle` never settles while a spinner runs (pump fixed durations);
  awaiting `StreamController.close()` of a stream nobody listened to never completes; a `const`
  instance is canonical, so `==` never reads an Equatable's `props`: assert them directly;
  stopping a `very_good test` MCP run leaves its `flutter test` process holding the lock, and every
  later run then hangs (kill it).
- `tester.enterText` does not reach the fields in a live Linux integration run, so the E2E fills
  the controllers and the form directly (typing is covered by the widget tests).

### Things the next agents must know
- The app imports data packages only through the repositories (`code_map_repository` re-exports
  the source types). `pumpApp` provides inert file services and a desktop's capabilities; give a
  `capabilities:` to test another platform.
- Anything that lists maps must listen to `CodeMapRepository.changes`: `go_router` keeps the home
  page alive under the viewer, so it would show a stale list.
- **Not verified on devices**: Android, iOS, macOS and Windows runs, the share sheet, the save
  dialog, and a browser (`flutter build web --release` compiles). The folder source is hidden on
  Android and iOS on purpose (see `future.md`).
- Opening a map from the recent list decodes it in the viewer (0.8 s for AltMe-sized maps, off the
  UI thread); the list itself never decodes.
- Skipped on purpose: keeping the screen awake during an analysis (no wakelock dependency), and
  IndexedDB persistence on the web: both are in `future.md`.
