# Session 03 — `code_graph`: model, placement, `.fscene` codec

**Branch:** `dc3d/s03-code-graph` · **Depends on:** 01 (02 recommended).
**Skills:** `vgv-ai-flutter-plugin:layered-architecture`, `…:testing`.
**Read:** `architecture.md` §1 (3D language), §4 (file format). In the submodule:
`packages/scene/lib/src/scene_document.dart`, `specs.dart`, `property_value.dart`,
`json/fscene_json.dart`, and the sample `examples/scenes/cube.fscene`.

## Goal

A pure-Dart package that defines **what a code map is** and converts it to and from
a flutter_scene `SceneDocument` (`.fscene` JSON). Every other package depends on it.

## Create the package

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

- [ ] Package created, in workspace and melos format list, analyze/format clean, 100% coverage.
- [ ] `tiny.fscene` committed and readable. It is accepted by `readFscene` (tested).
- [ ] 20k-node round-trip time and size recorded in the session log.
- [ ] No Flutter dependency (`dart pub deps` shows no `flutter`).

## Session log

_(to be filled by the agent)_
