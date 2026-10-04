# dart_code_3D — architecture reference

Status: plan, 2026-10-03. **Every session agent reads this file first.** It holds
the decisions taken with the product owner. Do not re-open a decision listed
here; if one turns out to be impossible, stop, explain why in the PR, and ask.

---

## 1. What we are building

dart_code_3D is a Flutter app (every Flutter platform: Android, iOS, macOS,
Windows, Linux, web) that:

1. **gets source code** from a local folder, a zip file, or a **public** git
   repository, into a temporary folder;
2. **analyzes** it with a configurable set of **rules** (the *engine*);
3. writes the result as a **`.dc3d` file** (a gzip-compressed flutter_scene `.fscene`
   scene document),
   which can be stored and shared;
4. lets the user **fly** through the result in 3D (the *viewer*).

Everything runs **inside the app**. There is no backend in the MVP.

### The 3D language (decided)

| Code concept | 3D representation |
|---|---|
| Class, mixin, enum, extension, extension type | **Sphere**. Its size grows with the length of the code inside it. |
| Method, constructor, getter/setter | Small sphere **inside** its class sphere. |
| Top-level function | Sphere at top level (clustered with its file). |
| `class B extends A` (A in the project) | Sphere B **inside** sphere A. Multi-level: C extends B → C inside B inside A. |
| `class W extends StatelessWidget` (parent outside the project) | A **ghost parent sphere** "StatelessWidget" contains W and every other project class that extends it. Enterable, but it shows no external internals. |
| External package (`package:flutter`, `package:bloc`, …) | **Package sphere** that **cannot be entered** (the camera bumps into it). Later: it will hold that package's own 3D model (see `future.md`). |
| Function / method call | **Link** (line) between two spheres. |
| `import` | Link of kind *import*. Excluded by default (rule). |
| `implements`, `with` | Links of kind *implements* / *mixin*. |
| Files and folders | **No sphere.** They only pull their declarations close together (clusters). |

- The world has **no depth limit**.
- The camera starts in front of the **entry point**: `main()` in `lib/main.dart`
  (see the `entry.point` rule for the fallback chain).
- **Entering a sphere** shows what is inside it. Inside a sphere the user picks
  between:
  - **Interior view**: only the sphere's content is visible, the shell is a dome;
  - **Window view**: the shell turns transparent and the rest of the world is
    visible from inside ("the sphere becomes the point of view").

### Scale target

The reference project is **[TalaoDAO/AltMe](https://github.com/TalaoDAO/AltMe)**:
~1,050 non-generated Dart files, ~108k lines, ~1,100 classes, which comes to
**~15–25k nodes** with members. The first development dataset is
**flutter_scene itself** (~620 files, ~206k lines, ~1,700 classes), available
locally as the git submodule `packages/flutter_scene`.

Consequences for the design (non-negotiable):

- the analysis runs off the UI thread (isolate on native platforms) and reports progress;
- the layout uses an `O(n log n)` force simulation (Barnes–Hut), not `O(n²)`;
- the viewer renders only what the current context needs (§7.3) and uses
  GPU instancing for spheres if the measured frame rate requires it.

---

## 2. Platform facts that shaped the design (verified 2026-10-03)

- **flutter_scene 0.23.0** runs on iOS, Android, macOS, Windows, Linux and
  **web** (WebGL2 backend). It needs **Flutter ≥ 3.47.1** (we use 3.47.1).
  Native platforms need **Flutter GPU enabled** (`--enable-flutter-gpu` per run, or
  per-platform settings, see session 01). Web needs nothing.
- flutter_scene is a monorepo. The submodule at `packages/flutter_scene` contains
  `packages/flutter_scene` (the Flutter package) and `packages/scene` (the
  **pure-Dart** `.fscene` document model: `SceneDocument`, `NodeSpec`,
  `ComponentSpec`, `writeFscene`, `readFscene`, `writeFsceneb`, prefabs, diffing).
  A `path:` dependency on these packages resolves correctly inside our pub workspace.
  That was tested.
- flutter_scene ships **agent skills** (`packages/flutter_scene/packages/flutter_scene/skills/`):
  `flutter_scene-idioms`, `flutter_scene-verification-loop`, `flutter_scene-performance`, …
  **Read `flutter_scene-idioms/SKILL.md` before writing any rendering code.** It lists the
  API traps (e.g. `package:vector_math/vector_math.dart`, not `vector_math_64`;
  whole-value `node.position = …`; `SceneView`; `Scene.initializeStaticResources()`).
- Useful flutter_scene APIs: `FlyCameraController` (+ `CameraControls` widget),
  `SphereGeometry`/`IcosphereGeometry`, `InstancedMeshComponent`,
  `LineSegmentsGeometry` (GPU-expanded segments; use it for links),
  `PolylineGeometry`, `Scene.raycast`, `realizeScene` / `FsceneComponentRegistry`.
- **3D frames can be screenshot-tested.** flutter_scene's CI renders scenes in
  `integration_test` (`flutter drive -d linux --enable-impeller --enable-flutter-gpu`
  under **Xvfb + Mesa llvmpipe**, and web under SwiftShader) and captures PNGs with
  `RenderRepaintBoundary.toImage`. Plain `flutter test` widget tests have **no GPU
  context**, so 3D goldens go through `integration_test`. See
  `examples/smoke_render` in the submodule. Our harness is session 02.
- **`package:analyzer`'s parser (`parseString`) compiles to JS and Wasm and runs**
  (tested). Parse-only analysis therefore works on every platform. **Full type
  resolution does not**: it needs the Dart SDK libraries and every dependency's
  source, which phones and browsers don't have.
- Browsers block downloads from GitHub (no CORS headers on archive downloads).
  The web build therefore cannot fetch a git repo. It analyzes a **zip** the user
  picks, or opens an existing `.dc3d` / `.fscene`.

---

## 3. Repository layout (new parts)

```
hawkbee/
├── apps/
│   └── dart_code_3d/                 # Flutter app (VGV flutter_app template), org com.hawkbee
│       ├── lib/
│       │   ├── app/                  # App widget, MultiRepositoryProvider, theme wiring
│       │   ├── home/                 # recent maps, "new analysis", "open file"
│       │   ├── analysis/             # source picker, rules summary, progress, cancel
│       │   ├── viewer/               # 3D world, fly controls, HUD, selection, inside/outside
│       │   ├── settings/             # theme + engine rules editor
│       │   └── main_{development,staging,production}.dart
│       ├── integration_test/         # 3D visual tests (screenshots), session 02
│       ├── test/                     # unit, bloc, widget + 2D golden tests
│       └── visual_baselines/         # committed 3D screenshot baselines (per size)
├── packages/
│   ├── flutter_scene/                # GIT SUBMODULE (bdero/flutter_scene @ flutter_scene-0.23.0)
│   ├── code_graph/                   # pure Dart · graph model + placement + .fscene codec
│   ├── code_source_client/           # pure Dart · fetch folder / zip / public git → SourceSnapshot
│   ├── code_analysis_engine/         # pure Dart · rules + analysis pipeline + dev CLI
│   ├── code_layout/                  # pure Dart · 3D layout (radii, nesting, clustering)
│   ├── code_map_repository/          # pure Dart · orchestrates fetch → analyze → layout → .fscene
│   └── settings_repository/          # Flutter pkg · theme mode + rules persistence
├── tool/visual_test.sh               # runs the 3D integration tests under Xvfb
└── docs/dart_code_3d/                # this folder
```

Package names are **lowercase snake_case** (Dart requires it): the app is
`dart_code_3d`, displayed as "dart_code_3D".

**Repositories (owner decision, 2026-10-03):** the app and every package above
(except the third-party `flutter_scene`) each have their **own public repository**
`github.com/hawkbee1/<name>` and are **git submodules** of hawkbee at the paths shown.
hawkbee keeps the workspace root (`pubspec.yaml`, melos scripts, overrides), `tool/`
and these docs. The sub-repositories only build inside a hawkbee checkout.
Procedure and PR flow: `agent-workflow.md` §2.

### Layers (VGV, see `docs/project-setup.md` §3)

| Layer | Packages | Notes |
|---|---|---|
| Presentation | `apps/dart_code_3d/lib/*/view/`, the 3D world classes in `viewer/` | flutter_scene code lives **only** here. |
| Business logic | `apps/dart_code_3d/lib/*/bloc|cubit/` | Bloc/Cubit, sealed states, Equatable. |
| Repository | `code_map_repository`, `settings_repository` | Domain API used by blocs. |
| Data | `code_source_client`, `code_analysis_engine`, `code_layout`, `code_graph` | Pure Dart, no Flutter, no business rules of the app. |

Dependency direction (arrows = "depends on"):

```
app ──► code_map_repository ──► code_source_client
 │                         ├──► code_analysis_engine ──► code_graph ──► scene (submodule)
 │                         ├──► code_layout ───────────► code_graph
 │                         └──► code_graph
 ├──► settings_repository ──► code_analysis_engine (rule definitions only)
 ├──► code_graph            (deviation: the viewer reads graph types and decodes the
 │                           .fscene; code_graph is a pure model package, no I/O)
 └──► flutter_scene (submodule, presentation only)
```

**Deviation (accepted):** the app imports `code_graph` directly. It is a pure,
immutable model package, like a shared "domain models" package. The app must
**not** import `code_source_client`, `code_analysis_engine` or `code_layout`.

### Dependencies on the submodule

- `apps/dart_code_3d/pubspec.yaml`:
  `flutter_scene: { path: ../../packages/flutter_scene/packages/flutter_scene }`
- `packages/code_graph/pubspec.yaml`:
  `scene: { path: ../flutter_scene/packages/scene }`
- Root `pubspec.yaml`: `dependency_overrides: { scene: { path: packages/flutter_scene/packages/scene } }`
  so flutter_scene and code_graph share the same local `scene`.
- The submodule's packages are **not** workspace members, and our tooling (format,
  analyze, tests, coverage) must **never** touch them.

---

## 4. The output file: `.fscene`

The analysis artifact is a **flutter_scene scene document** (`.fscene`, JSON, written
with `writeFscene` from `package:scene`). Reasons:

- the viewer loads it with flutter_scene's own loader (`readFscene` → `realizeScene`);
- it is human-readable and can be opened in the **Flutter Scene Editor** for debugging;
- it has a format version, feature flags (`featuresUsed` / `featuresRequired`),
  a binary twin (`.fsceneb`) for large payloads, **prefabs with lazy loading**
  (the future "enter an external package and see its own model"), and diffing.

### Content

| Part | How it is stored |
|---|---|
| Spheres | One `NodeSpec` per code node, nested exactly like the containment tree (class → subclass → methods). Transform = position relative to the parent, scale = radius. Mesh = shared procedural sphere geometry resource + one material resource per node kind. |
| Code semantics | A custom component **`dc3d.code_element`** on each node: `id`, `kind`, `name`, `qualifiedName`, `filePath`, `startLine`, `endLine`, `loc`, `enterable`, `external`, `packageName?`, `annotations` (list, empty in MVP). |
| Links | One component **`dc3d.code_links`** on the root node: a list of `{from, to, kind, resolution, count}`. The viewer builds link geometry at runtime because which links are visible depends on where the camera is. |
| Project metadata | Component **`dc3d.project`** on the root node: `schemaVersion` (int, start at 1), `generator` (`dart_code_3d <version>`), `source` (descriptor: folder name / git URL + ref + commit if known), `rules` (JSON of the rule values used), `entryNodeId`, `createdAt` (ISO 8601 UTC), `stats` (files, nodes, links, duration ms). |
| Feature flag | `featuresUsed` contains `dc3d.v1`. |

`code_graph` owns this codec in both directions:
`CodeMap (graph + placement) → SceneDocument` and `SceneDocument → CodeMap`.
Re-layout or re-theme therefore never needs a re-analysis.

**Files are `.dc3d` = gzip-compressed `.fscene` (decided in session 03, measured).**
The JSON is verbose: 20,000 nodes + 60,000 links = 52.6 MB of `.fscene` JSON (the
binary `.fsceneb` is the same size, it wraps the JSON), but **2.0 MB gzipped**, in
~0.2 s more. `CodeMapCodec.encodeToBytes` writes `.dc3d`; `decodeFromBytes` reads
`.dc3d` and plain `.fscene` (gzip detected by its magic bytes) and reports any
unreadable input as `CodeMapFormatException`. `gunzip` turns a `.dc3d` into a plain
`.fscene` for the Flutter Scene Editor. Links are stored as columns of node indices
(`from`, `to`, `kind`, `resolution`, `count`) with name tables, not one map per link.

---

## 5. The engine (`code_analysis_engine`)

### 5.1 Pipeline

```
SourceSnapshot ─► 1 collect files ─► 2 parse ─► 3 declarations ─► 4 containment
             ─► 5 resolve references ─► 6 links ─► 7 metrics ─► 8 annotate (future) ─► CodeGraph
```

1. **Collect files**: walk the snapshot, apply the file rules (§5.3), detect local
   packages (every `pubspec.yaml` in the snapshot = a project package, so the
   flutter_scene monorepo counts as one project with several packages).
2. **Parse**: `parseString(content:, path:, throwIfDiagnostics: false)` from
   `package:analyzer/dart/analysis/utilities.dart`. Group `part` files with their library.
3. **Declarations**: build a **symbol table**: libraries → top-level declarations →
   members, with declared types of fields, parameters, getters and return types;
   `import` / `export` directives with prefixes and `show`/`hide`. **Exports are
   followed transitively** (VGV barrels re-export everything).
4. **Containment**: methods inside their class; `extends` nesting for project parents;
   ghost parent nodes for external parents; external package nodes from `package:` imports.
5. **Resolve references** through a **`ReferenceResolver` strategy** (§5.2).
6. **Links**: calls (with resolution quality), and imports / implements / mixins per rules.
   Duplicate links between the same pair are merged with a `count`.
7. **Metrics**: `loc` = non-blank, non-comment lines of the declaration's own body
   (a class's `loc` excludes the `loc` of nested subclasses, which are separate
   declarations anyway).
8. **Annotate**: a list of `GraphAnnotator`s runs on the finished graph. The MVP
   ships **none**, but the interface exists: future design-pattern detectors
   (Bloc, Repository, Factory, Observer…) add `Annotation(patternId, role,
   confidence)` to nodes, and the viewer will later choose a representation from them.

Stages 2–3 are the slow part. They run in batches and report `AnalysisProgress`
(`stage`, `done`, `total`, `currentFile`) through a `Stream`. The engine API is
**cancellable**.

### 5.2 Resolution modes (strategy pattern)

```dart
abstract interface class ReferenceResolver {
  /// Resolves the target of an invocation/identifier found in [context].
  ResolvedReference resolve(ReferenceSite site, ResolverContext context);
}
```

| Mode | Class | Status | What it does |
|---|---|---|---|
| `parseOnly` (**default, MVP**) | `DeclaredTypeResolver` | MVP | Uses our own symbol table: declared types of fields/params/typed locals, `final x = Foo(...)` inference, `this`/`super`, static calls `Foo.bar()`, constructor calls, top-level functions through imports/exports. Unresolvable → fall back to name matching (`resolution: byName`), or `ambiguous`. Same result on every platform. |
| `fullResolution` | `AnalyzerResolver` | **post-MVP** (`future.md`) | Uses analyzer's resolved AST. Needs the Dart SDK summary bundled in the app plus dependency sources downloaded from pub.dev. Exact but slow and heavy. Settings will offer it **with a warning**. |

**Architecture rule:** nothing outside the resolver may depend on how a target was
found. The rest of the pipeline consumes `ResolvedReference(targetNodeId?,
resolution: exact | byName | ambiguous | external(packageName) | unresolved)`.
The future `AnalyzerResolver` then plugs in without touching other stages.

### 5.3 Rules

A rule is a typed, described, persisted parameter. The settings screen renders
rules **generically** from their definitions, so adding a rule never needs new UI code.

```dart
sealed class RuleParameter<T> { String id; String title; String description; T defaultValue; }
// BoolParameter, EnumParameter<E>, EnumSetParameter<E>, GlobListParameter, StringParameter
class AnalysisRules { /* immutable map id → value, toJson/fromJson, copyWith, defaults */ }
```

MVP rule set (ids are stable; they are stored in settings and in `.fscene` files):

| id | type | default | meaning |
|---|---|---|---|
| `files.exclude_generated` | bool | `true` | Skip files matching `files.generated_patterns`. |
| `files.generated_patterns` | glob list | `["**/*.g.dart"]` | What counts as generated. The user can add e.g. `**/*.freezed.dart`. |
| `files.exclude_tests` | bool | `true` | Skip `test/`, `integration_test/`, `test_driver/` and `*_test.dart`. |
| `files.extra_excludes` | glob list | `[]` | Extra excludes. `.dart_tool/`, `build/` and hidden folders are **always** excluded. |
| `links.calls` | bool | `true` | Function/method calls are links. |
| `links.imports` | bool | `false` | Imports are links. A file is represented by its largest top-level node; the link goes from that node to the imported file's largest top-level node, or to the external package sphere. |
| `links.implements` | bool | `true` | `implements` as links. |
| `links.mixins` | bool | `true` | `with` as links. |
| `links.ambiguous_calls` | enum `skip \| uniqueName \| all` | `uniqueName` | When the receiver type is unknown: drop the call, link only if exactly one project member has that name, or link to every candidate. |
| `nodes.external_packages` | bool | `true` | Show external package spheres (non-enterable). |
| `nodes.dart_sdk` | bool | `false` | Treat `dart:` libraries as an external package sphere named `dart`. |
| `nodes.ghost_parents` | bool | `true` | External superclasses become ghost parent spheres. When false, such classes sit at top level with an *extends* link to the package sphere. |
| `nodes.private` | bool | `true` | Include `_private` declarations. |
| `nodes.member_kinds` | enum set | `{method, constructor, getter, setter}` | Which members become spheres. Fields are not spheres in the MVP. |
| `entry.point` | string | `lib/main.dart` | Entry file. Fallback chain: that file's `main()` → any `lib/main_*.dart` `main()` (VGV flavors) → any top-level `main()` under `lib/` → the largest top-level node → origin. |
| `analysis.resolution_mode` | enum `parseOnly \| fullResolution` | `parseOnly` | Only `parseOnly` is selectable in the MVP; `fullResolution` is shown disabled with "coming later". |

There is **no depth limit** rule.

---

## 6. Layout (`code_layout`)

Input: `CodeGraph`. Output: `Placement` per node (`position` relative to its
parent's center, `radius`). Pure Dart, **deterministic** (seeded from a hash of
the graph, independent of node order) on a given platform; VM and JavaScript agree
to ~1e-12 (maps are laid out once and stored). Tested.

1. **Radii, bottom-up.** Leaf: `r = clamp(k · cbrt(loc), rMin, rMax)`, so volume
   grows linearly with code length. Container: `R = max(r_own, packingRadius(children) · margin)`,
   where `packingRadius ≈ cbrt(Σ r_i³ / density)`, then grown until the children fit.
2. **Inside a container** (members + nested subclasses): seed positions on Fibonacci
   shells, largest first, then relax (overlap repulsion, containment, weak attraction
   along sibling links) for a fixed number of iterations. Children never touch the shell.
3. **Top level** (top-level classes, functions, ghost parents, package spheres): 3D
   force simulation with a **Barnes–Hut octree**:
   - repulsion between all nodes, collision by radius;
   - attraction to the centroid of the same file (strong), same directory (medium),
     same package (weak); this produces the clusters;
   - springs along call links, aggregated to top-level ancestors (weight = log of count);
   - the **entry node is pinned at the origin**;
   - external package spheres are pushed to an outer shell; ghost parents sit
     between their subclasses' cluster and their package sphere.
4. Final pass removes residual overlaps.

---

## 7. The viewer (app `viewer/` feature)

### 7.1 Loading

`.dc3d` / `.fscene` bytes → `CodeMapCodec.decodeFromBytes` → `CodeMap`. Rendering builds the scene
**from the `CodeMap`** in a `CodeWorld` class (imperative flutter_scene style: a plain
Dart class that owns the `Scene`; see the idioms skill, "Choosing declarative or
imperative"). Spheres are drawn with **GPU instancing** (`InstancedMesh` +
`InstancedMeshComponent`, one shared sphere geometry, per-instance colour), rebuilt
when the visible set changes. The mesh nodes stored in the `.fscene` exist for
the Flutter Scene Editor and other tools; the viewer does not `realizeScene` the whole
document. Picking uses our own ray–sphere intersection (instances are not
individually raycastable).

### 7.2 Navigation ("fly mode")

- Base: flutter_scene `FlyCameraController`.
- **Desktop/web with keyboard:** arrow keys ↑/↓ forward/back, ←/→ strafe,
  Page Up/Page Down (or Q/E) up/down, Shift boost, mouse drag to look.
- **Touch (mobile):** an on-screen **trackball** (drag area that rotates the view) plus
  a forward/back control. Show the touch controls when no hardware keyboard is detected
  or on mobile platforms. A settings toggle can force them.
- Package spheres are **solid**: the camera stops at their surface.
- Speed adapts to the radius of the current container, so a tiny class interior
  and the huge top-level world are both navigable.

### 7.3 Context, visibility, performance

- **Current container** = the deepest enterable sphere containing the camera
  (or the world).
- Visible spheres: the children of the current container (their own children
  stay hidden behind their shell until entered). In **window view**, also the
  path of ancestors and their siblings, as closed shells.
- **Links**: only links with at least one endpoint visible. An endpoint hidden
  inside a closed shell is drawn to its **nearest visible ancestor** (aggregated
  with a count, thicker line).
- Labels: Flutter overlay text, projected from 3D, for the selected node and the
  N nearest visible nodes.
- Budget: **≥ 30 fps** on a mid-range phone and in the browser with AltMe loaded;
  ≥ 60 fps on desktop. Session 11 measures and records it.

### 7.4 Interaction

- Select: tap/click a sphere, or the crosshair target + Enter → info panel
  (name, kind, `file:line`, `loc`, incoming/outgoing link counts, resolution quality).
- "Fly to" a node from the info panel or from a search box.
- Toggles: link kinds visible, labels on/off, interior/window view (key `V`).
- 2D **minimap**: a top-down projection of the current container (CustomPainter).
  It helps orientation and makes the layout golden-testable.

---

## 8. Settings

- **Theme**: system / light / dark (Material 3; the 3D background and materials
  follow the theme).
- **Engine rules**: generic editor (§5.3), reset to defaults, persisted.
- Persistence: `settings_repository` over `shared_preferences` (`SharedPreferencesAsync`).

---

## 9. Testing standard (applies to every session)

- VGV conventions (`testing` and `bloc` skills): `mocktail`, `bloc_test`, `pumpApp` helper.
- **Coverage target 100%** for every package we own (use the `green-gate` skill).
- **2D golden tests** (plain `flutter test`): every screen, panel and overlay at
  **3 sizes** (phone 390×844, tablet 820×1180, desktop 1440×900, logical pixels,
  device pixel ratio 1) in **light and dark** themes, with **real fonts loaded**
  (not the Ahem test font), so a human can read the screenshots and judge the UX.
  Write them with `goldenTest()` (`test/helpers/goldens.dart`); the images land in
  `goldens/<name>/<device>_<theme>[_<locale>].png` next to the test file.
- **3D visual tests** (`integration_test`, Linux desktop under Xvfb with software
  rendering): fixed scenes and fixed camera paths captured at the same 3 sizes,
  compared to committed baselines in `apps/dart_code_3d/visual_baselines/` with a
  tolerance, plus reference-free sanity checks (not blank, corners = background,
  foreground lit). Run with `tool/visual_test.sh` (session 02).
- Fixtures: small hand-written Dart projects in `packages/code_analysis_engine/test/fixtures/`
  with **exact expected graphs**, plus smoke runs on the flutter_scene submodule
  (and AltMe from session 07 on).

---

## 10. Glossary

| Term | Meaning |
|---|---|
| Code node | Anything that becomes a sphere: class, mixin, enum, extension, extension type, method, constructor, getter, setter, top-level function, ghost parent, external package. |
| Container | A node with children (enterable sphere). |
| Ghost parent | Synthetic node for an external superclass that holds the project classes extending it. |
| Code map | `CodeGraph` + `Placement`s = what a `.dc3d` (gzipped `.fscene`) file holds. |
| Snapshot | The source files fetched into a temporary folder (or memory on web). |
