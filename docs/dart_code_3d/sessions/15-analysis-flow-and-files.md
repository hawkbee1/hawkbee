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
  bar, the current file name (ellipsized in the middle), elapsed time.
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

- [ ] From an empty install: analyze a public GitHub repo → fly in it → restart → it is in the recent list → share it → open the shared file elsewhere (web build).
- [ ] Web: zip upload and `.dc3d` open work; git option hidden with the explanation.
- [ ] Analyze/format clean, 100% coverage, goldens committed.

## Session log

_(to be filled by the agent)_
