# dart_code_3D — after the MVP (backlog)

These are known future directions. The MVP architecture must keep them possible.
Sessions must **not** implement them unless the owner asks.

## Full-resolution analysis mode (settings option, with a warning)

- `AnalyzerResolver` implementing `ReferenceResolver` (`architecture.md` §5.2), using
  `package:analyzer`'s resolved AST through an in-memory `ResourceProvider`
  (`MemoryResourceProvider`, which works without `dart:io`).
- Needs: a **Dart SDK summary** bundled as an app asset (matching the analyzer
  version), and the **dependency sources**: resolve the project's `pubspec.lock` and
  download each package archive from pub.dev (`https://pub.dev/api/archives/<pkg>-<version>.tar.gz`),
  cached between runs. Flutter SDK packages (`flutter`, `flutter_test`, …) are not on
  pub.dev: bundle or download the matching Flutter SDK `packages/` sources.
- Warning in settings: slow, large downloads, high memory use (especially on phones and
  web), may fail on projects that need code generation.
- Enables: exact call targets, ghost parent chains (StatelessWidget → Widget → …),
  types of `var` locals, extension method resolution.

## Private git repositories

- User authentication: GitHub/GitLab OAuth device flow or personal access token, stored
  with `flutter_secure_storage`. Archive download with `Authorization` header.
- Optional pure-Dart git client for other hosts.

## External package models

- An external package sphere becomes enterable: its interior is that package's own code
  map, loaded as a **lazy prefab** (`.fscene` prefabs with `LoadPolicy.lazy`) built by
  analyzing the package source (pub.dev archive) with the same engine.
- Cache of package maps keyed by `name@version`, shareable.

## Design-pattern detection

- `GraphAnnotator`s (`architecture.md` §5.1 stage 8) detecting Bloc/Cubit, Repository,
  data client, Page/View split, Factory, Singleton, Observer/Stream, Adapter…
- Annotations drive the representation: the viewer picks shapes, colours or groupings
  per pattern role (e.g. a Bloc as a hub with events/states orbiting it).
- Rules to enable/disable detectors and tune confidence thresholds.

## Sharing through the hawkbee Appwrite backend

- Accounts, upload of `.fscene` files to a Storage bucket, share links, permissions.
  Follow `docs/project-setup.md` (repositories over `appwrite_api_client`).

## Smaller items

- Web persistence of maps (IndexedDB).
- Gamepad navigation; VR/AR later.
- Re-layout from the viewer with different layout options (no re-analysis needed).
- Diff two code maps (two commits) and highlight changes (`diffScene` exists in `package:scene`).
- Show source code of the selected node (needs embedding sources or keeping the snapshot).
- Analysis of languages other than Dart.
- Local folders on Android and iOS: a picked folder is a scoped-storage URI or a security-scoped
  bookmark, not a path `dart:io` can read, so the folder source is hidden there (session 15). It needs
  a snapshot source that reads through the platform (SAF / bookmarks), or copies the folder first.
- Keep the screen awake during an analysis on phones (`wakelock_plus`; not a dependency yet).
- Report the layout's progress across the isolate, instead of the indeterminate bar of the "laying
  out" stage (`MapWorker.layoutAndEncode` has no progress stream yet).
- Share a map by link instead of a file (see the Appwrite item above).
