# Session 09 — `code_map_repository`: orchestration, save, open, share

**Branch:** `dc3d/s09-repository` · **Depends on:** 04, 07, 08.
**Skills:** `vgv-ai-flutter-plugin:layered-architecture`, `…:testing`.

## Goal

The repository the app's blocs talk to. It chains **fetch → analyze → layout →
encode** with one progress stream, handles cancellation and cleanup, and stores,
opens and lists code maps.

## Create the package (own repository + submodule: `agent-workflow.md` §2 procedure)

`dart_package` `code_map_repository` in `packages/` (pure Dart), `workspace: true`,
wired. Dependencies: `code_source_client`, `code_analysis_engine`, `code_layout`,
`code_graph`, `equatable`, `archive`.

## API

```dart
sealed class BuildEvent extends Equatable {}
class BuildProgress extends BuildEvent { final BuildStage stage; final double fraction; final String? detail; } // fetching, analyzing, layingOut, encoding
class BuildSucceeded extends BuildEvent { final CodeMapFile file; }
class BuildFailed extends BuildEvent { final BuildFailure failure; } // typed: sourceNotFound, privateOrMissingRepo, rateLimited, network, invalidArchive, unsupportedOnWeb, analysisError, cancelled

class CodeMapFile extends Equatable {
  final String name;            // 'AltMe @ main'
  final Uint8List fscene;       // encoded .fscene (UTF-8 JSON)
  final Uint8List? payload;     // optional .fsceneb (see below)
  final ProjectInfo project;
}

class CodeMapRepository {
  CodeMapRepository({required CodeSourceClient sourceClient, required EngineRunner engineRunner,
                     CodeLayoutEngine? layoutEngine, required CodeMapStore store});
  Stream<BuildEvent> build(CodeSource source, AnalysisRules rules, {CancelToken? cancel});
  Future<CodeMap> open(CodeMapFile file);         // decode + validate
  Future<CodeMapFile> importBytes(String fileName, Uint8List bytes); // .fscene or .dc3d.zip
  Uint8List exportForSharing(CodeMapFile file);   // .fscene alone, or .dc3d.zip when there is a payload
  Future<List<CodeMapSummary>> recent();          // newest first
  Future<void> save(CodeMapFile file);
  Future<void> delete(String id);
}

abstract interface class CodeMapStore { … }       // implemented in the app (session 15) with platform storage
class InMemoryCodeMapStore implements CodeMapStore { … } // tests + web fallback
```

Rules:
- the snapshot is **always disposed** (success, failure, cancel). Test it;
- layout runs in the same isolate/inline runner approach as the engine (reuse the
  `EngineRunner` pattern, or extend it to run layout + encoding too, so the UI thread
  only receives bytes);
- progress fractions are weighted per stage (fetch 0–20%, analyze 20–80%, layout
  80–95%, encode 95–100%) and never go backwards;
- payload split: measure the JSON size of AltMe and flutter_scene maps. If both are
  under 20 MB, keep a single `.fscene` and leave `payload` null (still support
  importing a `.dc3d.zip`). Write the decision and the numbers in the session log
  and in `architecture.md` §4.

## Tests (100% coverage)

- Fakes for the source client and runner. Success path, each failure type,
  cancel at each stage, snapshot disposal.
- Import: `.fscene`, `.dc3d.zip`, garbage bytes → typed failure; files from a newer
  `schemaVersion` → typed failure with a clear message.
- An integration-style test (tag `slow`) building a map from the `basic_app` engine
  fixture end-to-end with the real engine and layout.

## Acceptance criteria

- [ ] Repository API as above, documented. Analyze/format clean, 100% coverage.
- [ ] AltMe and flutter_scene end-to-end build times (CLI or slow test) and file sizes are in the session log.

## Session log

_(to be filled by the agent)_
