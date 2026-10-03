# Session 01 — Workspace, flutter_scene submodule, app scaffold, first sphere

**Branch:** `dc3d/s01-workspace` · **Depends on:** owner merged `init-appwrite-project` into `main`.
**Skills:** `vgv-ai-flutter-plugin:create-project`, `…:layered-architecture`, `…:testing`.

## Goal

After this session the monorepo contains the flutter_scene submodule and a
`dart_code_3d` app that renders **one lit sphere** with flutter_scene on Linux
desktop, web, and (built, not necessarily run) Android/macOS/iOS/Windows. Our
tooling must ignore the submodule.

## Steps

### 1. Submodule

```bash
git submodule add https://github.com/bdero/flutter_scene.git packages/flutter_scene
git -C packages/flutter_scene fetch --tags
git -C packages/flutter_scene checkout flutter_scene-0.23.0   # commit 0dc6ee8
git add .gitmodules packages/flutter_scene
git commit -m "chore(workspace): add flutter_scene 0.23.0 as a git submodule"
```

Use the **https** URL (not ssh) so any clone works without keys.
Add to `README.md` (repo root) a line: clone with `git clone --recurse-submodules`,
or run `git submodule update --init --recursive` after cloning.

### 2. Keep our tooling out of the submodule

- Root `pubspec.yaml` → `melos.scripts.format`: today it runs `dart format … .`, which
  would format the submodule. Replace it with a version that formats only our code, e.g.
  ```yaml
  format:
    run: dart format --set-exit-if-changed apps packages/appwrite_api_client packages/backend_status_repository packages/hawkbee_schema tool backend
  ```
  and **add every new package of ours to this list** in later sessions (write that
  reminder as a YAML comment above the script). Verify with `melos run format`.
- Create a root `analysis_options.yaml` (if none exists) containing only:
  ```yaml
  analyzer:
    exclude:
      - packages/flutter_scene/**
  ```
- `melos run analyze` and `melos run test` iterate over workspace members only.
  Check that the submodule is not picked up (`melos list`).

### 3. Scaffold the app

Very Good CLI MCP `create` tool:
`subcommand: flutter_app`, `name: dart_code_3d`, `org_name: com.hawkbee`,
`output_directory: apps`, `workspace: true`,
`description: "Fly through a 3D map of a Dart code base."`.

- Check `apps/dart_code_3d/pubspec.yaml` has `resolution: workspace`, and add
  `apps/dart_code_3d` to `workspace:` in the root `pubspec.yaml`.
- The template has no **Linux** platform, and the VGV hook blocks `flutter create`.
  Add it with the repo script, which copies Flutter's own Linux runner template
  (tested: the result builds):
  ```bash
  tool/add_linux_platform.sh apps/dart_code_3d dart_code_3d com.hawkbee.dart_code_3d
  ```
  It creates only `apps/dart_code_3d/linux/` and refuses to run if that folder exists.
- Run `flutter pub get` at the root.
- Make the app its **own public repository** `hawkbee1/dart_code_3d` and add it to
  hawkbee as a submodule at `apps/dart_code_3d`, following the procedure in
  `agent-workflow.md` §2 (`git init` → `gh repo create --public --source=. --push` →
  merge-commit-only settings → `git submodule add`). Its README gets the "Part of hawkbee"
  section. From here on, app changes are committed **inside** `apps/dart_code_3d` on
  branch `dc3d/s01-workspace`, and hawkbee commits only bump the pointer.

### 4. Add flutter_scene

In `apps/dart_code_3d/pubspec.yaml`:
```yaml
dependencies:
  flutter_scene:
    path: ../../packages/flutter_scene/packages/flutter_scene
  vector_math: ^2.1.4
```
Root `pubspec.yaml`:
```yaml
dependency_overrides:
  scene:
    path: packages/flutter_scene/packages/scene
```
Then, in `apps/dart_code_3d/`: `dart run flutter_scene:init --skills`. Inspect
and commit what it created (`hook/build.dart`, `flutter_scene_generated/`,
pubspec `flutter: assets:` entry, installed skills). Read the installed
`flutter_scene-idioms` skill now.

### 5. Enable Flutter GPU on every native platform

| Platform | File | Add |
|---|---|---|
| iOS | `ios/Runner/Info.plist` | `<key>FLTEnableFlutterGPU</key><true/>` |
| Android | `android/app/src/main/AndroidManifest.xml`, inside `<application>` | `<meta-data android:name="io.flutter.embedding.android.EnableFlutterGPU" android:value="true" />` |
| macOS | `macos/Runner/Info.plist` | `<key>FLTEnableFlutterGPU</key><true/>` |
| Linux | `linux/runner/my_application.cc`, after `fl_dart_project_new()` | `fl_dart_project_set_enable_flutter_gpu(project, TRUE);` |
| Windows | `windows/runner/main.cpp`, on the `flutter::DartProject` | `project.set_enable_flutter_gpu(true);` |
| Web | nothing | |

### 6. First sphere

- Replace the template's counter feature with a temporary `viewer/` feature:
  `viewer/view/viewer_page.dart` showing a `SceneView` with one
  `SphereGeometry` + `PhysicallyBasedMaterial` and a `PerspectiveCamera`, built after
  `Scene.initializeStaticResources()` (copy the "Minimal scene" pattern from the
  idioms skill, with a sphere instead of a cuboid). Keep the template's `App`,
  bootstrap, flavors and l10n.
- Keep it minimal: session 11 replaces this view.

### 7. Verify

- `flutter build web --release -t lib/main_development.dart` succeeds.
- `flutter build linux -t lib/main_development.dart` succeeds. It needs clang, ninja,
  GTK dev headers, Xvfb and Mesa, which were installed on 2026-10-03. If the container
  was recreated and they are missing (`which clang xvfb-run`), stop and ask the owner
  (see README "Prerequisites").
- `flutter build apk --debug --flavor development -t lib/main_development.dart`
  succeeds if the Android SDK is present; otherwise note it in the PR.
- Unit/widget tests: update the template tests to the new viewer page (the
  `SceneView` itself cannot render in `flutter test`; test that the page builds
  and shows a placeholder until the scene is ready). 100% coverage.

## Acceptance criteria

- [x] `git submodule status` shows `packages/flutter_scene` at `0dc6ee8` (tag `flutter_scene-0.23.0`).
- [x] `apps/dart_code_3d` is a submodule pointing to the public repo `hawkbee1/dart_code_3d` (merge commits only), with a "Part of hawkbee" README section; one PR there + one PR in hawkbee.
- [x] `melos run format`, `melos run analyze` and `melos run test` do not touch the submodule and pass.
- [x] `apps/dart_code_3d` builds for web and Linux. A sphere renders (screenshot from
      the web build via the owner's browser, or from session 02's harness, attached to the PR).
- [x] Flutter GPU enabled in all 5 native platform files.
- [x] Coverage 100% for `apps/dart_code_3d`.

## Out of scope

Engine, real viewer, settings, goldens harness (session 02).

## Session log

**2026-10-03. Run by Claude Opus 5.5 (the planning model), not by a session agent.**

### Built
- `packages/flutter_scene`: submodule at `0dc6ee8` (tag `flutter_scene-0.23.0`), https URL.
- `apps/dart_code_3d`: Very Good CLI `flutter_app` (org `com.hawkbee`), its own public repo
  [hawkbee1/dart_code_3d](https://github.com/hawkbee1/dart_code_3d) (merge commits only), submodule
  of hawkbee, workspace member. Linux runner added with `tool/add_linux_platform.sh`.
- Root `pubspec.yaml`: `dependency_overrides: scene` → submodule copy. Melos `format` lists our
  code explicitly (now includes `apps/dart_code_3d`). Root `analysis_options.yaml` excludes the submodule.
- App: `flutter_scene` (path) + `vector_math` + `hooks` dependencies; `flutter_scene:init` →
  `hook/build.dart`, `flutter_scene_generated/`; Flutter GPU enabled in the 5 native platform files;
  Flutter constraint `^3.47.1`.
- Temporary `viewer/` feature (`ViewerPage`, `SphereSceneView`) replacing the template counter.
  `App.home`, `ViewerPage.sceneView`, `SphereSceneView.initialize/sceneBuilder` are injectable so
  widget tests avoid the GPU. `buildSphereScene` (GPU glue) is under `coverage:ignore` and is
  covered by the 3D visual tests from session 02.

### Verified
- `melos run format`, `melos run analyze`, `melos run test`: all 6 workspace packages pass, and the submodule is untouched.
- App tests: 10 passed, coverage 100%.
- `flutter build web --release`, `flutter build linux`, `flutter build apk --debug --flavor development`: all succeed.
- The Linux release build, run under Xvfb + llvmpipe with no command-line flag, renders the
  lit sphere: [screenshot](../screenshots/s01-linux-sphere.png).
- Not built: iOS, macOS, Windows (no toolchains in this Linux container). The web build was
  not opened in a browser.

### Deviations and things the next agents must know
- **The Very Good CLI 1.5.0 template uses new Dart 3.13 syntax and packages**: constructors
  are written `const new({super.key});`, and Material comes from **`package:material_ui/material_ui.dart`**
  (not `package:flutter/material.dart`). Follow the template's style.
- Removed the template's `.github/workflows` and `dependabot.yaml` from the app repo: the app only
  resolves inside hawkbee, so standalone CI would always fail. CI for hawkbee is not set up yet.
- flutter_scene's skills were installed into `.github/skills` (the installer writes to every agent
  folder already present). They were moved to **`apps/dart_code_3d/.claude/skills`**. As a result,
  `dart run flutter_scene:skills --check` reports them "not installed" for `.github`. That is expected.
- Android: the template pins Kotlin 2.2.10; Flutter 3.47.1 needs ≥ 2.2.20. Bumped to 2.2.20 (same as
  the other hawkbee apps).
- `dart format` indents the `// flutter_scene:init:start/end` markers in `hook/build.dart`. Harmless:
  flutter_scene finds them with a substring search.
- Fixed `directives_ordering` infos in the template's `l10n.dart` and `pump_app.dart`.
- **Locales are English and French** (owner decision): the template's Spanish ARB was replaced by
  `app_fr.arb`, and iOS `CFBundleLocalizations` lists `en`, `fr`.
- **Template l10n bug fixed:** the generated `AppLocalizations.localizationsDelegates` registers
  `flutter_localizations`' Material/Cupertino delegates, which do not serve `material_ui` widgets,
  so any non-English locale failed ("A MaterialLocalizations delegate that supports the fr locale
  was not found"). `lib/l10n/l10n.dart` now exposes `appLocalizationsDelegates`
  (`AppLocalizations.delegate` + `material_ui`'s `GlobalMaterialLocalizations.delegates`); use it
  everywhere. A test locks in `en`/`fr` and renders a French string.
- The template's `LICENSE` says "Copyright (c) 2026 com.hawkbee". The owner may want a real name there.
