# Session 05 — Engine part 1: rules, file collection, parsing, declarations, containment

**Branch:** `dc3d/s05-engine-declarations` · **Depends on:** 03, 04.
**Skills:** `vgv-ai-flutter-plugin:layered-architecture`, `…:testing`.
**Read:** `architecture.md` §1 (3D language), §5 entirely.

## Goal

Create `code_analysis_engine` and implement pipeline stages **1–4 and 7** (collect,
parse, declarations, containment, metrics). The output is a `CodeGraph` with every
node and the containment tree, but **no call links yet** (session 06).

## Create the package (own repository + submodule: `agent-workflow.md` §2 procedure)

`dart_package` `code_analysis_engine` in `packages/`, `workspace: true`, wired into
the workspace and the melos format list. Dependencies: `analyzer` (latest
version compatible with Dart 3.13; import only `package:analyzer/dart/analysis/utilities.dart`
and `package:analyzer/dart/ast/*.dart`), `glob`, `path`, `code_graph`,
`code_source_client` (only for the `SourceSnapshot` interface), `equatable`, `meta`.

**Web constraint:** the engine must compile to JS/Wasm. Never import `dart:io` or
`package:analyzer/file_system/physical_file_system.dart`. Only `parseString` is
allowed from the analyzer (tested: it runs on the web).

## Rules (`lib/src/rules/`)

Implement `RuleParameter` (sealed: `BoolParameter`, `EnumParameter`, `EnumSetParameter`,
`GlobListParameter`, `StringParameter`) and `AnalysisRules` exactly as in
`architecture.md` §5.3, with **all MVP rules and defaults from that table**, ids as
constants (`RuleIds.excludeGenerated = 'files.exclude_generated'`, …). Also provide:
- `AnalysisRules.defaults()`, `copyWith(id, value)`, `toJson()` / `fromJson()` (unknown
  ids ignored, missing ids → default, wrong types → default and a warning list);
- `RuleCatalog.all`: ordered list of definitions with `title`, `description`, `group`
  (`files`, `links`, `nodes`, `entry`, `analysis`) for the settings UI;
- `analysis.resolution_mode` exposes `fullResolution` with `enabled: false` and the note
  "coming later" (`architecture.md` §5.2).

## Pipeline stages

`class CodeAnalysisEngine { Stream<AnalysisEvent> analyze(SourceSnapshot snapshot, AnalysisRules rules, {CancelToken? cancel}); }`
Events: `AnalysisProgress(stage, done, total, currentPath)`, then `AnalysisDone(CodeGraph)`
or `AnalysisFailed(error)`. Check `cancel` between files.

1. **Collect** (`FileCollector`): filter `snapshot.paths` with the file rules. Find every
   `pubspec.yaml` → `ProjectPackage(name, rootDir)` (read `name:` with a tiny line-based
   parse; no YAML dependency needed). A file belongs to the deepest package root containing it.
2. **Parse**: `parseString(content: text, path: '/$path', throwIfDiagnostics: false)`.
   Keep the `CompilationUnit` and line info. Merge `part` files into their library
   (`part of` / `part`). A file that fails to parse is reported in the stats
   (`parseErrors`) and skipped, without failing the run.
3. **Declarations** (`SymbolTable`): for every library, record top-level declarations
   (class, mixin, enum, extension, extension type, function, top-level variable with its
   declared type) and their members (methods, constructors incl. named/factory, getters,
   setters, fields with declared types). Record `import`/`export` directives with URI,
   prefix, `show`/`hide`. Resolve URIs: relative → path; `package:<p>/<x>` where `<p>`
   is a project package → `<root>/lib/<x>`; other `package:` → external package `<p>`;
   `dart:<lib>` → SDK.
   Compute each library's **export namespace transitively** (with show/hide; guard
   against export cycles). Session 06 needs it.
4. **Containment**:
   - members → parent class node (only kinds enabled in `nodes.member_kinds`);
   - `class B extends A`: if `A` resolves (through the library's import namespace) to a
     project class → `B.parentId = A`; else, if `nodes.ghost_parents` → parent =
     ghost node `ghost:<pkg>:<A>` (package guessed from imports: the single external
     package whose import could provide `A`; if several or none, `pkg = 'unknown'`);
     else top level + an `extendsExternal` link (session 06 adds links, so record the intent now);
   - `nodes.private == false` drops `_names`;
   - external package nodes `pkg:<name>` for every external package imported
     (if `nodes.external_packages`); `pkg:dart` only if `nodes.dart_sdk`.
5. **Entry node**: apply the `entry.point` fallback chain (`architecture.md` §5.3) and
   set `ProjectInfo.entryNodeId`.
6. **Metrics**: `loc` = non-blank lines in the declaration's source range that are not
   only comments. For a class, subtract the lines of its members (each member has its
   own `loc`).

## Tests (100% coverage) and fixtures

Create `test/fixtures/` with **small hand-written projects**, each with an
`expected.json` describing the exact expected nodes (ids, kinds, parents, loc).
Write a test helper that loads a fixture folder into an in-memory `SourceSnapshot`
(`MemorySnapshot` from `code_source_client`; reading a folder from disk:
`CodeSourceClient().fetch(LocalFolderSource(path))`).

| Fixture | Covers |
|---|---|
| `basic_app` | `lib/main.dart` with `main()`, two classes, methods, getters, constructors |
| `inheritance` | project chain C extends B extends A; class extending `StatelessWidget` (ghost); `nodes.ghost_parents=false` variant |
| `barrels` | VGV-style package with `lib/src/…` and a barrel `export`, `show`/`hide`, prefix imports |
| `parts` | `part` / `part of` |
| `monorepo` | two packages in one repo, one importing the other via `package:` (must be internal) |
| `filters` | `*.g.dart`, `test/`, `build/`, `.dart_tool/`, extra excludes, toggles |
| `entry_fallbacks` | no `lib/main.dart`, only `lib/main_development.dart`, … |
| `broken` | a file with syntax errors |

Also a **smoke test** on the real submodule source (`packages/flutter_scene`, read from
disk through a test-only snapshot): no exception, and it records node counts per kind.
Tag it `slow` and keep it under 60 s.

## Acceptance criteria

- [x] All fixtures pass with exact expectations.
- [x] `dart compile js` of a tiny entrypoint using the engine succeeds (prove web compatibility; document the command in the package README).
- [x] Smoke test on flutter_scene passes. Counts and duration are in the session log.
- [x] Analyze/format clean, 100% coverage.

## Session log

**2026-10-03. Run by Claude Opus 5.5 (the planning model), not by a session agent.** This
branch is stacked on session 04.

### Built
- `packages/code_analysis_engine`: public repo
  [hawkbee1/code_analysis_engine](https://github.com/hawkbee1/code_analysis_engine),
  submodule + workspace member. `analyzer: ^13.0.0` (13.3.0 was already resolved in the
  workspace), parser only.
- Rules: `RuleParameter` (`Bool`, `Enum`, `EnumSet`, `GlobList`, `String`) with
  `RuleOption` (enabled + note), `RuleCatalog.all` (every MVP rule of architecture §5.3,
  `fullResolution` shown disabled with "Coming later"), `RuleIds`, and `AnalysisRules`
  (immutable, `copyWith` validation, tolerant `fromJson` with warnings, typed getters,
  works with any catalog).
- Pipeline (`lib/src/pipeline/`): `FileCollector`, `UriResolver`, `ParsedFile` +
  `groupLibraries`, `SymbolTable` (transitive export namespaces, `lookupType` with package
  guessing), `buildContainment` (+ `findEntryNode`), `linesOfCode`.
- `CodeAnalysisEngine.analyze` → `AnalysisProgress` (every 25 files) then `AnalysisDone` |
  `AnalysisFailed` (`AnalysisCancelled` or a bug with its stack trace); `CancelToken`.
  `Containment.nodeIdsByAst` (syntax node → node id) and `externalSuperclasses` (classes
  extending external classes while ghost parents are off) are ready for session 06.

### Measured
- flutter_scene (submodule): 622 files, **11,050 nodes in ~1.6 s**, 0 parse errors, entry
  `examples/flutter_app/lib/main.dart#main`, 26 ghost parents, 34 packages.
- AltMe: 1,044 files, **11,012 nodes in ~1.0 s**, entry `lib/main.dart#main`, 19 ghost
  parents, 92 packages. Its generated localization files (not `*.g.dart`) contribute most
  of its 6,447 getters. A user can add their pattern to `files.generated_patterns`.
- 72 tests (incl. the smoke test), coverage 100%. A JS build analyzes a project in Node.

### Deviations and things the next agents must know
- **Analyzer 13 AST**: classes, enums and extension types expose their name through
  `namePart.typeName` and their members through `body.members`. A `PrimaryConstructorDeclaration`
  (Dart 3.13 `class Point(int x, int y)`) is the `namePart` itself, and becomes a constructor
  node. New-style `new()` constructors have `newKeyword` and no `typeName`.
- Fixtures are **text files** (`source.txt` with `=== path` sections), not `.dart` files, so
  the package's own analyze and format never see broken or unresolvable code. Expected
  results were generated, then reviewed line by line.
- Duplicate top-level names (broken code) keep the first declaration; duplicate members get
  `#2`, `#3` id suffixes.
- A primary constructor's line is not subtracted from its type's lines of code (it is the
  header). Annotations (`@override`) count as code.
- Two bugs found by tests and fixed: iterating a map while removing from it
  (`groupLibraries`), and a non-deterministic tie in the "largest declaration" entry fallback.
- `analyzer`'s own `Declaration` class clashes with ours: import the analyzer with
  `hide Declaration` where both are used.
