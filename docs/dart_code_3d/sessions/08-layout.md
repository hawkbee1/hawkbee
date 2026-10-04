# Session 08 — `code_layout`: placing spheres in 3D

**Branch:** `dc3d/s08-layout` · **Depends on:** 03 (07 for real datasets).
**Skills:** `vgv-ai-flutter-plugin:testing`.
**Read:** `architecture.md` §1 (3D language) and §6 (layout).

## Goal

A pure-Dart, **deterministic** package that computes a `Placement` (position relative
to the parent centre + radius) for every node of a `CodeGraph`, producing a `CodeMap`.

## Create the package (own repository + submodule: `agent-workflow.md` §2 procedure)

`dart_package` `code_layout` in `packages/`, `workspace: true`, wired. Dependencies:
`code_graph`, `vector_math` (`package:vector_math/vector_math.dart`), `meta`.

## API

```dart
class LayoutOptions {
  final double locScale;        // k in r = k·cbrt(loc), default 0.5
  final double minRadius;       // 0.4
  final double maxLeafRadius;   // 8
  final double containerMargin; // 1.25
  final int innerIterations;    // 150
  final int topIterations;      // 400
  final double theta;           // Barnes–Hut opening angle, 0.8
  // file/directory/package attraction strengths, link spring strength, …
}

class CodeLayoutEngine {
  CodeMap layout(CodeGraph graph, {LayoutOptions options = const LayoutOptions(), void Function(double progress)? onProgress});
}
```

Seed every random choice with `Random(seedFrom(graph))`, where the seed is a stable
hash of sorted node ids (do **not** use `String.hashCode`, which is not stable across
runs or platforms; write a small FNV-1a hash).

## Algorithm (`architecture.md` §6)

1. **Radii bottom-up** (post-order on the containment tree):
   - leaf: `clamp(locScale · cbrt(max(loc,1)), minRadius, maxLeafRadius)`;
   - ghost parent / external package: radius from their children count / a fixed size
     (external spheres: `minRadius · 4`, they look like solid "planets");
   - container: `max(ownRadius, packingRadius(children) · containerMargin)` with
     `packingRadius = cbrt(Σ r_i³ / 0.55)`, then enlarged until step 2 fits.
2. **Inside each container** (pre-order): place children largest first on a Fibonacci
   sphere scaled to `R − r_i − gap`, then relax: pairwise overlap push (n is small per
   container; if n > 500, use a uniform grid for neighbour search), clamp each child
   inside `R − r_i − gap`, weak springs along sibling call links. Fixed iteration count.
3. **Top level**: Barnes–Hut 3D force simulation (write an `Octree` class with tests):
   - repulsion ~ `1/d²` between all top-level nodes, approximated by the octree;
   - collision: no overlap of radii;
   - cluster attraction to centroids: same file (strong), same directory (medium),
     same package (weak);
   - call links aggregated to top-level ancestors: spring with weight `log(1+count)`;
   - entry node's top-level ancestor **pinned at the origin**;
   - `externalPackage` nodes pushed to a shell outside the project's bounding sphere;
     ghost parents attracted to their package node a little, and to their children's
     cluster mostly;
   - cooling schedule (temperature decreasing linearly), fixed iterations.
4. **Overlap removal pass** on the final positions (top level and every container).

## Tests (100% coverage)

- Invariants on handmade graphs and on a generated 20k-node graph:
  - no two siblings overlap (`|p_i − p_j| ≥ r_i + r_j`);
  - every child is inside its parent: `|p| + r_child ≤ R_parent`;
  - the entry node's top-level ancestor is at (0,0,0);
  - determinism: same graph → bit-identical placements; shuffled insertion order →
    identical placements;
  - nodes of the same file are closer on average than nodes of different files.
- Octree unit tests (insertion, centre of mass, force vs brute force within tolerance).
- Performance: 20k-node generated graph lays out in **< 20 s** here (record the time),
  and the flutter_scene graph (from the session 07 CLI `--out`) too.

## Debug aid

Extend the session 07 CLI with `--layout --out map.dc3d` (engine → layout →
`CodeMapCodec.encodeToBytes` → file; `--out map.fscene` writes plain JSON). The owner can open the result in the Flutter Scene Editor.
Commit **no** large output files; describe how to produce them.

## Acceptance criteria

- [x] Invariant, determinism and performance tests pass. Timings are in the session log.
- [x] `map.dc3d` for flutter_scene produced by the CLI; its size is in the session log.
- [x] Analyze/format clean, 100% coverage.

## Session log

**2026-10-04. Run by Claude Opus 5.5 (the planning model), not by a session agent.** Stacked on
session 07.

### Built
- `packages/code_layout`: public repo [hawkbee1/code_layout](https://github.com/hawkbee1/code_layout),
  submodule + workspace member. Pure Dart; depends on `code_graph` (+ `args` for its CLI).
- `CodeLayoutEngine().layout(graph, {options, onProgress})`, `LayoutOptions` (with an extra
  `overlapIterations`), `Octree` (Barnes–Hut), `relaxOverlaps` / `hasNoOverlap` /
  `latticePacking`, `Vec3` + `fibonacciDirection`.
- **Invariants are guaranteed**: a container that relaxation cannot fill grows (up to 6×),
  then falls back to a cubic lattice; the top level spreads out by 10% until no overlap is left.
- `bin/layout.dart`: `dart run code_layout:layout graph.json --out map.dc3d|map.fscene`.

### Measured
| Input | Nodes | Layout | File | Overlaps | Outside parent |
|---|---|---|---|---|---|
| flutter_scene | 11,050 | 5.2 s | 1.6 MB `.dc3d` | 0 | 0 |
| AltMe | 11,012 | 4.7 s | 1.5 MB `.dc3d` | 0 | 0 |
| generated (tests) | 20,004 | 3.8 s | — | 0 | 0 |

Entry node at the origin in all of them. Top view of AltMe's top level:
[screenshots/s08-altme-top-level.png](../screenshots/s08-altme-top-level.png). Grey = ghost
parents, dark = packages, colours = folders, red = entry.

### Deviations and things the next agents must know
- **The layout CLI lives in `code_layout`** (`bin/layout.dart`, reading the engine CLI's graph
  JSON), not as `--layout` on the engine CLI: that would make the engine depend on the layout
  package.
- **`Vec3` instead of `vector_math`**: `vector_math`'s `Vector3` is single precision, which is not
  enough for exact overlap checks. Convert at the rendering boundary (`Placement.position`).
- Determinism is exact on a given platform; **VM and JavaScript differ around 1e-13** (`pow`,
  `sin`, `cos`). Checked, documented, harmless: maps are laid out once and stored.
- Fixed while looking at AltMe's top view: package spheres ended on a shell twice as far as
  needed (similar directions overlapped, and the shell grew 15% per try). They now switch to evenly
  spread directions after 3 tries, from the base radius.
- `dart fix` rewrites `0.0` → `0` and `1.0` → `1` (prefer_int_literals), which changes type
  inference (`fold(0, …)` becomes `int`, `List.filled(n, 1)` becomes `List<int>`). Add explicit
  type arguments when it complains.
