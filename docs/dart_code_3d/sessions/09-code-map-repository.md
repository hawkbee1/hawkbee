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
  final Uint8List bytes;        // a .dc3d file: CodeMapCodec.encodeToBytes (gzipped .fscene)
  final ProjectInfo project;
}

class CodeMapRepository {
  CodeMapRepository({required CodeSourceClient sourceClient, required EngineRunner engineRunner,
                     CodeLayoutEngine? layoutEngine, required CodeMapStore store});
  Stream<BuildEvent> build(CodeSource source, AnalysisRules rules, {CancelToken? cancel});
  Future<CodeMap> open(CodeMapFile file);         // decode + validate
  Future<CodeMapFile> importBytes(String fileName, Uint8List bytes); // .dc3d or plain .fscene
  Uint8List exportForSharing(CodeMapFile file);   // the .dc3d bytes (file name: <name>.dc3d)
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
- file format: **decided in session 03**, a `.dc3d` file is a gzip-compressed `.fscene`
  (`CodeMapCodec.encodeToBytes` / `decodeFromBytes`, architecture §4). Record the real
  `.dc3d` sizes of the AltMe and flutter_scene maps in the session log.

## Tests (100% coverage)

- Fakes for the source client and runner. Success path, each failure type,
  cancel at each stage, snapshot disposal.
- Import: `.dc3d`, plain `.fscene`, garbage bytes → typed failure; files from a newer
  `schemaVersion` → typed failure with a clear message.
- An integration-style test (tag `slow`) building a map from the `basic_app` engine
  fixture end-to-end with the real engine and layout.

## Acceptance criteria

- [x] Repository API as above, documented. Analyze/format clean, 100% coverage.
- [x] AltMe and flutter_scene end-to-end build times (CLI or slow test) and file sizes are in the session log.

## Session log

**2026-10-04. Run by Claude Opus 5.5 (the planning model), not by a session agent.** Stacked on
session 08.

### Built
- `packages/code_map_repository`: public repo
  [hawkbee1/code_map_repository](https://github.com/hawkbee1/code_map_repository), submodule +
  workspace member (pure Dart).
- API as planned, with: `CodeMapFile` (`id`, `name`, `bytes` = `.dc3d`, `project`, `summary`),
  `CodeMapSummary` (JSON for store indexes), `BuildFailure` (`kind` + `message` + `details`;
  also `invalidGitUrl` and `invalidFile` kinds), `load(id)`, and `exportForSharing` returning
  `(fileName, bytes)`.
- `MapWorker` (`InlineMapWorker`, `IsolateMapWorker` via `Isolate.run`, `defaultMapWorker()`
  through a conditional export): layout + encoding and decoding off the UI thread.
- `importBytes` re-compresses a plain `.fscene` so every stored map is a `.dc3d`.

### Measured (building from a local folder, isolates)
| Dataset | Build | Analysis | Layout + encoding | `.dc3d` | Open (decode) |
|---|---|---|---|---|---|
| flutter_scene | 7.8 s | 1.8 s | 6.0 s | 1.64 MB | 0.89 s |
| AltMe | 7.6 s | 1.3 s | 6.2 s | 1.50 MB | 0.82 s |

31 tests, coverage 100%. A JS build builds a map from a zip (inline worker).

### Bugs found by the tests (fixed)
- **Temp folder leak**: cancelling during the download dropped the `FetchDone` snapshot before
  it was stored, so it was never disposed. The snapshot is now taken first.
- **Engine (session 07)**: `IsolateEngineRunner` cancelled the caller's `CancelToken` whenever
  the stream completed, because `StreamController.onCancel` also runs on normal completion.
  Fixed in `code_analysis_engine` (branch `dc3d/s09-repository`, PR stacked on the session 07 PR),
  with a test that checks the token after a normal finish.

### Things the next agents must know
- **UX (session 15)**: layout + encoding take ~6 s for AltMe-sized maps while progress stays at
  80%. The progress screen must show activity during "laying out" (an indeterminate bar or an
  animated stage), or layout must report progress across the isolate.
- `build` does not save: call `save(file)` on success.
- Dart 3.13 allows private named initializing formals (`required this._store`, used as `store:`).
