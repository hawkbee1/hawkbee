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
- The template has no **Linux** platform. Ask the owner to run (hooks block it for you):
  ```
  ! cd /volume/hawkbee/apps/dart_code_3d && flutter create --platforms=linux --org com.hawkbee --project-name dart_code_3d .
  ```
  Then `git status`: **delete** any file `flutter create` added outside `linux/`
  (typically `lib/main.dart`, `test/widget_test.dart`) so the VGV structure stays intact.
- Run `flutter pub get` at the root. Commit.

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
- `flutter build linux -t lib/main_development.dart` succeeds (needs clang, ninja,
  GTK dev headers. If they are missing, stop and ask the owner to add them to the
  container image: `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
  xvfb libgl1-mesa-dri libegl-mesa0 libgles2 mesa-vulkan-drivers`).
- `flutter build apk --debug --flavor development -t lib/main_development.dart`
  succeeds if the Android SDK is present; otherwise note it in the PR.
- Unit/widget tests: update the template tests to the new viewer page (the
  `SceneView` itself cannot render in `flutter test`; test that the page builds
  and shows a placeholder until the scene is ready). 100% coverage.

## Acceptance criteria

- [ ] `git submodule status` shows `packages/flutter_scene` at `0dc6ee8` (tag `flutter_scene-0.23.0`).
- [ ] `melos run format`, `melos run analyze` and `melos run test` do not touch the submodule and pass.
- [ ] `apps/dart_code_3d` builds for web and Linux. A sphere renders (screenshot from
      the web build via the owner's browser, or from session 02's harness, attached to the PR).
- [ ] Flutter GPU enabled in all 5 native platform files.
- [ ] Coverage 100% for `apps/dart_code_3d`.

## Out of scope

Engine, real viewer, settings, goldens harness (session 02).

## Session log

_(to be filled by the agent)_
