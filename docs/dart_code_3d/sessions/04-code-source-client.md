# Session 04 — `code_source_client`: getting the code

**Branch:** `dc3d/s04-code-source` · **Depends on:** 03.
**Skills:** `vgv-ai-flutter-plugin:layered-architecture`, `…:testing`, `…:static-security`.

## Goal

A pure-Dart data package that turns a **source** (local folder, zip file, public git
repository URL) into a **`SourceSnapshot`**: a read-only set of files in a temporary
folder (native) or in memory (web). Getting the code is **separated** from analyzing
it: the engine only ever sees a `SourceSnapshot`.

## Create the package (own repository + submodule: `agent-workflow.md` §2 procedure)

`dart_package` named `code_source_client` in `packages/`, `workspace: true`.
Add it to the root workspace and the melos format list. Dependencies: `http`,
`archive`, `path`, `equatable`, `code_graph` (for `SourceDescriptor`).

## API

```dart
sealed class CodeSource extends Equatable {}
class LocalFolderSource extends CodeSource { final String path; }          // native only
class ZipBytesSource extends CodeSource { final String fileName; final Uint8List bytes; } // all platforms
class GitRepositorySource extends CodeSource { final String url; final String? ref; }     // native only in MVP

abstract interface class SourceSnapshot {
  SourceDescriptor get descriptor;              // from code_graph
  /// Repo-relative paths with '/' separators, sorted.
  List<String> get paths;
  Future<String> readAsString(String path);     // UTF-8, malformed bytes replaced
  Future<void> dispose();                       // deletes the temp folder, if any
}

class CodeSourceClient {
  CodeSourceClient({http.Client? httpClient, TempStorage? tempStorage});
  /// Emits progress (bytes downloaded / files extracted) and completes with the snapshot.
  Stream<FetchEvent> fetch(CodeSource source);  // FetchProgress … then FetchDone(snapshot) or FetchFailed(error)
}
```

- `TempStorage` hides `dart:io` behind a conditional import (`temp_storage_io.dart` /
  `temp_storage_web.dart`). On web, files stay in memory.
- `LocalFolderSource`: **no copy**. The snapshot reads the folder in place (read-only)
  and `dispose()` does nothing. Skip symlinks that leave the folder.
- `ZipBytesSource`: extract into temp storage. If every entry shares one top folder
  (`AltMe-main/…`), strip it.
- Only `.dart` files, `pubspec.yaml`, and `analysis_options.yaml` are kept in the
  snapshot (the engine needs nothing else). Always skip `.git/`, `.dart_tool/`, `build/`.

## Git URL handling (`GitUrl.parse`)

Accept `https://github.com/<o>/<r>(.git)`, `git@github.com:<o>/<r>.git`,
`github.com/<o>/<r>`, and the same three forms for GitLab (`gitlab.com`). The MVP
fetches a public **archive over HTTPS**, without git:

| Host | Archive URL |
|---|---|
| GitHub | `https://api.github.com/repos/<o>/<r>/zipball/<ref>`; without a ref, omit `/<ref>` (default branch). The API redirects to `codeload.github.com`, so follow redirects. |
| GitLab | `https://gitlab.com/<o>/<r>/-/archive/<ref>/<r>-<ref>.zip`. Without a ref, first `GET https://gitlab.com/api/v4/projects/<o>%2F<r>` and read `default_branch`. |

- Errors become typed failures: `RepositoryNotFound` (404, which is also what a private
  repo returns, so the message must say "not found or private: private repositories
  come in a later version"), `RateLimited` (GitHub 403 with `X-RateLimit-Remaining: 0`),
  `NetworkFailure`, `ArchiveTooLarge` (default limit 500 MB, configurable), `InvalidArchive`.
- Record the commit in the descriptor when known (GitHub zipball top folder is
  `<o>-<r>-<sha7>`).
- Security: refuse zip entries with absolute paths or `..` (zip-slip). Cap the total
  extracted size. Never log URLs with credentials.
- **Web:** `GitRepositorySource` and `LocalFolderSource` throw `UnsupportedOnWeb`
  (browsers block GitHub archive downloads: no CORS). The UI will offer zip upload instead.

## Tests (100% coverage)

- `GitUrl.parse` table test (valid + invalid forms).
- Fetch with a `MockClient` (`package:http/testing.dart`) returning a small fixture zip
  built in the test with `package:archive`: progress events, top-folder stripping,
  filtering, descriptor, dispose deletes the temp folder.
- Every error path, including zip-slip and size cap.
- Local folder snapshot on a temp dir created in the test.
- One **opt-in** network test, tagged `network` and skipped by default, that downloads
  `bdero/flutter_scene` at tag `flutter_scene-0.23.0` and checks the file count is
  > 500. Document how to run it.

## Acceptance criteria

- [x] Package created and wired. Analyze/format clean, 100% coverage.
- [x] Compiles for web: add a test with `platform: chrome` for the web temp storage,
      or at least `dart compile js` a small entrypoint in CI notes.
- [x] Session log: time and size to fetch flutter_scene 0.23.0 and AltMe (`main`) with the opt-in test.

## Session log

**2026-10-03. Run by Claude Opus 5.5 (the planning model), not by a session agent.** This
branch is stacked on session 03.

### Built
- `packages/code_source_client`: public repo
  [hawkbee1/code_source_client](https://github.com/hawkbee1/code_source_client), submodule +
  workspace member.
- API as planned: `CodeSource` (`LocalFolderSource`, `ZipBytesSource`, `GitRepositorySource`),
  `SourceSnapshot` (+ `MemorySnapshot`), `CodeSourceClient.fetch` → `FetchProgress*` then
  `FetchDone` | `FetchFailed`, typed `FetchFailure`s (+ `InvalidGitUrl`), `GitUrl.tryParse`,
  `FileFilter`, `TempStorage` / `SnapshotBuilder` (`MemoryTempStorage`), `LocalFolderReader`.
- Platform defaults through a conditional export (`lib/src/platform/`): native = temp
  directory (`DirectoryTempStorage`, deleted on dispose) + `IoLocalFolderReader` + git;
  web = memory, no folders, no git. `localFoldersSupported` / `gitSupported` flags reproduce
  the web in VM tests.
- Opt-in `network` tests download flutter_scene and AltMe (skipped by default).

### Measured
- flutter_scene @ `flutter_scene-0.23.0`: 1.5 s, 12.7 MB downloaded, 944 files kept (914 Dart),
  commit `0dc6ee8` detected.
- AltMe @ default branch: 3.1 s, 64.6 MB downloaded, 1,349 files kept (1,347 Dart), commit `e1f596d`.
- 73 tests (+2 opt-in), coverage 100%. A JS build extracts a zip in memory and refuses git.

### Deviations and things the next agents must know
- **`ZipDecoder` never throws on bad input**: garbage, or a truncated zip, gives an empty archive.
  The extractor checks the `PK` signature, rejects empty archives, and catches the
  `FormatException` thrown when a **corrupt entry is decompressed (lazily, on `content`)**.
- A single top folder is stripped only if it is not a package layout folder (`lib`, `bin`,
  `test`, `tool`, `example`, `web`, `integration_test`, `test_driver`, `packages`, `apps`).
  Otherwise a zip of only `lib/` would lose `lib/`.
- Unexpected errors (bugs) are added to the stream as errors, not swallowed.
- Template quirks: a `:` in the create description breaks the YAML; Very Good CLI's test
  merging drops library `@Tags` (use `skip_very_good_optimization`). Both are now in
  `agent-workflow.md`.
- GitLab support is tested with mocks only (no opt-in GitLab download yet).
