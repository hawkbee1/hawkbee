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
Write a test helper that loads a fixture folder into an in-memory `SourceSnapshot`.

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

- [ ] All fixtures pass with exact expectations.
- [ ] `dart compile js` of a tiny entrypoint using the engine succeeds (prove web compatibility; document the command in the package README).
- [ ] Smoke test on flutter_scene passes. Counts and duration are in the session log.
- [ ] Analyze/format clean, 100% coverage.

## Session log

_(to be filled by the agent)_
