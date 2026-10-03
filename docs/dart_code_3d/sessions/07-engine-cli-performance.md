# Session 07 — Engine part 3: dev CLI, performance, isolates, AltMe

**Branch:** `dc3d/s07-engine-perf` · **Depends on:** 06.
**Skills:** `vgv-ai-flutter-plugin:testing`.

## Goal

Make the engine fast and observable on real projects: a **developer CLI**, timing
per stage, batching and progress, and a run on **AltMe** (the scale reference) and
**flutter_scene**.

## 1. Developer CLI

`packages/code_analysis_engine/bin/analyze.dart`:

```
dart run code_analysis_engine:analyze <folder> [--rules rules.json] [--out graph.json] [--stats]
```

- Reads the folder with `CodeSourceClient().fetch(LocalFolderSource(path))` from
  `code_source_client` (no need for a CLI-only snapshot). `bin/` may import `dart:io`;
  `lib/` may not.
- `--stats` prints: files kept/skipped, parse errors, nodes per kind, links per kind ×
  resolution, duration per stage, peak RSS (`ProcessInfo.maxRss`).
- `--out` writes the `CodeGraph` as JSON (debug format, not the `.fscene`; layout comes later).
- This CLI is a dev tool for agents and the owner. The app never uses it.

## 2. Performance work

- Measure first (CLI `--stats`) on `packages/flutter_scene` and on AltMe (clone it into
  the session scratchpad: `git clone --depth 1 https://github.com/TalaoDAO/AltMe.git`).
  **Do not commit AltMe.**
- Typical hotspots: re-reading files, rebuilding namespaces per lookup (cache them),
  string concatenation of ids in hot loops, quadratic link merging (use a map keyed by
  `from|to|kind`).
- Targets on this container (record the actual numbers):
  - AltMe end-to-end (engine only, files already on disk) **< 30 s**;
  - flutter_scene **< 45 s**;
  - memory **< 1.5 GB** peak.
- Progress events at least every 100 files or 250 ms, and cancellation reacts within 250 ms.

## 3. Running off the UI thread

The engine stays platform-agnostic. Add to `code_analysis_engine` a small
`EngineRunner` API:
- native: `Isolate.run`-based runner. The snapshot paths and contents are sent to
  the isolate in chunks, and progress comes back through a `SendPort`. Cancellation
  goes through a message;
- web: inline runner that yields to the event loop between batches
  (`await Future<void>.delayed(Duration.zero)`), so the UI stays responsive.
Use conditional imports (`runner_io.dart` / `runner_web.dart`) so `lib/` never
imports `dart:isolate` on web.

## 4. Regression guard

A test tagged `slow` runs the engine on the flutter_scene submodule and asserts:
node count within ±10% of the number recorded in this session (store it in a
constant with a comment), no exception, and duration below 2× the target. Skip it
by default and document how to run it.

## Acceptance criteria

- [ ] CLI works on both datasets. The full `--stats` output for both goes into the session log.
- [ ] Targets met, or the gap explained with a profile (`dart run --observe` + DevTools CPU profile summary).
- [ ] Isolate runner (native) and inline runner (web) tested; cancellation tested.
- [ ] Analyze/format clean, 100% coverage of `lib/` (exclude `bin/` from coverage if needed and say so).

## Session log

_(to be filled by the agent)_
