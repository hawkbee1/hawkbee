# Session 03 — `code_graph`: model, placement, `.fscene` codec

**Branch:** `dc3d/s03-code-graph` · **Depends on:** 01 (02 recommended).
**Skills:** `vgv-ai-flutter-plugin:layered-architecture`, `…:testing`.
**Read:** `architecture.md` §1 (3D language), §4 (file format). In the submodule:
`packages/scene/lib/src/scene_document.dart`, `specs.dart`, `property_value.dart`,
`json/fscene_json.dart`, and the sample `examples/scenes/cube.fscene`.

## Goal

A pure-Dart package that defines **what a code map is** and converts it to and from
a flutter_scene `SceneDocument` (`.fscene` JSON). Every other package depends on it.

## Create the package (own repository + submodule: `agent-workflow.md` §2 procedure)

Very Good CLI MCP `create`: `subcommand: dart_package`, `name: code_graph`,
`output_directory: packages`, `workspace: true`. Add it to the root `workspace:`
and to the melos `format` script list. Dependencies: `scene` (path
`../flutter_scene/packages/scene`), `equatable`, `meta`, `vector_math`
(`package:vector_math/vector_math.dart`).

## Model (immutable, Equatable, `toJson`/`fromJson` where noted)

```dart
enum CodeNodeKind {
  classDecl, mixinDecl, enumDecl, extensionDecl, extensionTypeDecl,
  method, constructor, getter, setter, function,
  ghostParent, externalPackage,
}

enum LinkKind { call, import, implementsLink, mixinLink, extendsExternal }
enum LinkResolution { exact, byName, ambiguous, external }

class SourceLocation { final String filePath; final int startLine; final int endLine; }   // repo-relative, '/' separators

class Annotation { final String patternId; final String role; final double confidence; }    // future design patterns

class CodeNode {
  final String id;              // stable: '<filePath>#<qualifiedName>' or 'pkg:<name>' or 'ghost:<pkg>:<Class>'
  final CodeNodeKind kind;
  final String name;            // 'save'
  final String qualifiedName;   // 'UserRepository.save'
  final String? parentId;       // containment parent (null = top level)
  final SourceLocation? location; // null for ghost/external
  final int loc;                // own lines of code (0 for ghost/external)
  final String? packageName;    // project package or external package name
  final List<Annotation> annotations;
  bool get isEnterable => …;    // containers that are not externalPackage
}

class CodeLink { final String fromId; final String toId; final LinkKind kind; final LinkResolution resolution; final int count; }

class ProjectInfo {
  final int schemaVersion;      // 1
  final String generator;       // 'dart_code_3d 0.1.0'
  final SourceDescriptor source;// sealed: LocalFolderDescriptor(name) | GitDescriptor(url, ref, commit?) | ZipDescriptor(fileName)
  final Map<String, Object?> rules; // rule id → JSON value (opaque here)
  final String? entryNodeId;
  final DateTime createdAt;     // UTC
  final GraphStats stats;       // files, nodes, links, durationMs
}

class CodeGraph {
  final ProjectInfo project;
  final Map<String, CodeNode> nodes;
  final List<CodeLink> links;
  // Derived, computed once (lazy): childrenOf(id), topLevel, ancestorsOf(id), depthOf(id),
  // linksFrom(id), linksTo(id). Validate on construction: every parentId and link endpoint
  // exists, no containment cycles (throw CodeGraphException with a clear message).
}

class Placement { final Vector3 position; /* relative to parent centre */ final double radius; }

class CodeMap { final CodeGraph graph; final Map<String, Placement> placements; }
```

Write a short `README.md` for the package that explains the model and the stable id scheme.

## Codec: `CodeMap` ⇄ `SceneDocument`

`class CodeMapCodec` with:
- `SceneDocument encode(CodeMap map)`
- `CodeMap decode(SceneDocument doc)`, throwing `CodeMapFormatException` when the
  document has no `dc3d.project` component or an unsupported `schemaVersion`
- `String encodeToJson(CodeMap)` / `CodeMap decodeFromJson(String)` using `writeFscene` / `readFscene`.

Encoding rules (`architecture.md` §4):
- a root node `"dc3d root"` carrying components `dc3d.project` and `dc3d.code_links`;
- one `NodeSpec` per `CodeNode`, nested by `parentId` (children of the root = top-level nodes);
  `TrsTransform` translation = placement position, uniform scale = radius;
- a `mesh` component referencing **one shared sphere geometry resource** and one
  material resource **per `CodeNodeKind`**. Find the exact component and resource shapes
  in `cube.fscene` and in `specs.dart`; do not guess field names. Colors per kind
  are a constant table in `code_graph` (`kindColors`). The viewer may override them by theme;
- a component `dc3d.code_element` on each node with the `CodeNode` fields as
  `PropertyValue`s (`StringValue`, `IntValue`, `BoolValue`, `ListValue`, `MapValue`);
- `featuresUsed` += `dc3d.v1`; `generator` = project generator.

Unknown component types are skipped (with a warning) by flutter_scene's realizer,
so our custom components do not break loading in the Flutter Scene Editor.

## Tests (100% coverage)

- Model: equality, JSON round trips, validation errors (missing parent, cycle,
  dangling link), derived indexes.
- Codec: **round trip** `decode(encode(map)) == map` on (a) a tiny handmade graph
  covering every node kind and link kind, and (b) a generated graph of 20,000 nodes
  and 60,000 links (assert it encodes + decodes in < 10 s on this machine and
  record the time and JSON size in the session log).
- Golden file: commit `test/fixtures/tiny.fscene` and assert `encodeToJson(tinyMap)`
  equals it byte for byte (canonical JSON makes this stable). It documents the format
  for humans.

## Acceptance criteria

- [x] Package created, in workspace and melos format list, analyze/format clean, 100% coverage.
- [x] `tiny.fscene` committed and readable. It is accepted by `readFscene` (tested).
- [x] 20k-node round-trip time and size recorded in the session log.
- [x] No Flutter dependency (`dart pub deps` shows no `flutter`).

## Session log

**2026-10-03. Run by Claude Opus 5.5 (the planning model), not by a session agent.** This
branch is stacked on session 02 (not yet merged when it started).

### Built
- `packages/code_graph`: public repo [hawkbee1/code_graph](https://github.com/hawkbee1/code_graph),
  submodule + workspace member. Dependencies: `scene` (submodule path), `archive`, `equatable` 3,
  `meta`, `vector_math`.
- Model as planned: `CodeNodeKind` (`isEnterable`: type declarations + ghost parents;
  `isExternal`), `CodeNode`, `SourceLocation`, `Annotation`, `CodeLink` (`LinkKind`,
  `LinkResolution`), `SourceDescriptor` (folder / git / zip, with `label`), `GraphStats`
  (+ `parseErrors`), `ProjectInfo` (`currentSchemaVersion = 1`), `CodeGraph` (validated:
  key = id, parents, link ends, no cycle, entry exists; indexes), `Placement`
  (doubles x/y/z/radius + `position`), `CodeMap` (exactly one placement per node). All with JSON.
- `stableHash` (FNV-1a 32-bit, identical on the web). Session 08 must use it for its seed.
- `CodeMapCodec`: `encode`/`decode` (`SceneDocument`), `encodeToJson`/`decodeFromJson`,
  **`encodeToBytes`/`decodeFromBytes` (`.dc3d` = gzip `.fscene`)**. Encoding is deterministic:
  the document id comes from a hash of the project, and the id allocator uses a fixed session.
- `test/fixtures/tiny.fscene` (every node and link kind), regenerated by
  `dart run test/fixtures/write_fixtures.dart`.

### Measured
- 20,000 nodes + 60,000 links: encode 0.9 s, decode 1.6 s, **52.6 MB JSON → 2.0 MB `.dc3d`**
  (gzip +1.1 s including encode). Without indentation the JSON would be 17.2 MB. `writeFsceneb`
  is also 52.6 MB (it wraps the JSON).
- 64 tests, coverage 100%. A JS build of the codec round-trips a map in Node.
  Flutter is not reachable in the dependency graph.

### Deviations and things the next agents must know
- **File format changed from the plan**: no `.fsceneb` payload or `.dc3d.zip`. Files are
  `.dc3d` = gzipped `.fscene`. architecture §4 and sessions 08, 09, 11, 15, 16 are updated.
- **Exact data lives in `dc3d.code_element`, not in transforms**: scene transforms are
  single precision (`vector_math` `Vector3` is Float32) and scale is inherited by children.
  Transforms are derived (`translation = position / parentRadius`, `scale = radius / parentRadius`)
  for renderers and the editor. `decode` reads only the components.
- Links are columns of node indices (`index` in each `dc3d.code_element`), with `kindNames` /
  `resolutionNames` tables, not one map per link (one map per link would be ~200 bytes).
- `decodeFromBytes` turns **any** failure into `CodeMapFormatException`: flutter_scene's
  `readFscene` throws `TypeError`s on malformed documents.
- Template fixes needed: `test ^1.31.0`, `equatable ^3.0.0`, CI/Dependabot removed (now in
  `agent-workflow.md`).
