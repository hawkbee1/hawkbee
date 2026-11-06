# Session M5.15: Write-ahead log, snapshots and recovery

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 15. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m5-15-wal` · **Depends on:** M5.11.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `appwrite:dart`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/02-persistence.md` (all of it); P-03 in `plan/milestones/performance-tests.md`; the session log of M5.9 (log format).

## Notes
- The local Appwrite instance: in-container tools reach it by its Docker name (hawkbee `docs/project-setup.md`). Tests that need it are tagged, opt-in, and carry `skip_very_good_optimization` (dc3d §2 pitfalls).
- Kill-and-recover tests run in process: stop the host object at a chosen entry, build a new one from the stores, compare states.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 15).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-05), stacked on M5.14 (hawkbee #50, not merged yet):
- **`battle_host`**:
  - `lib/src/ports/`: `WriteAheadLog` (an append is synced to disk before it returns) and `MemoryWriteAheadLog`; `LogSink` is now the log kept for good, in `LogBatch`es read back from the start of one, with `MemoryLogSink`; `SnapshotStore` with `BattleSnapshot` (log position, battle time, opaque data) and `MemorySnapshotStore`.
  - `lib/src/core/`:
    - `Battle.save` gives a `BattleMemento`; `Battle.restore` rebuilds the battle from it, its world with `BattleWorld.load`, its timers, random and sequence numbers where they were (Memento).
    - `encodeSnapshot` and `decodeSnapshot`: the snapshot format, version 1.
    - `Journal`: the write path. Each entry goes to the write-ahead log first; every 10 seconds the new entries are sealed into one batch, and every 5 minutes with new entries a snapshot is taken.
    - `replay`: the entries after a snapshot replayed, each checked against the log.
    - `SimulationHost.recover`, `snapshot` and `settle`. A failed log write stops the battle and the order is not acknowledged. `start` refuses the ID of a battle stopped by an error.
  - `lib/src/adapters/`: `FileWriteAheadLog` (one file per battle, `fsync` on each append, a torn last frame dropped); `AppwriteLogSink` (one gzip file per batch, ID `<battle>-<position on 12 digits>`); `AppwriteSnapshotStore` (two files per battle).
  - Tests: one contract suite per port, run on the memory stores and on the Appwrite adapters over an in-memory fake of `Storage`; the same suites on the local Appwrite, tagged `appwrite` and opt-in. A scripted battle: every M4 order, a purchase, storage, a recall and a 24-hour lock, over 34 hours. `expectReplay` (M5.11) now uses `replay` and compares whole snapshots; the `fingerprint` helper is gone.
- **`battle_rules`**: `XorshiftRandom.resume` and `state`; `BattleSettings.toData`, the shape of `battle.yaml`.
- **hawkbee `backend/appwrite.config.json`**: buckets `battle_logs` and `battle_snapshots`, with no client permission (the host's API key only), `.gz` files up to 30 MB.
- **`battle_team`**: decision 222 (Q-GEN-02); P-03 measured.

Checks: analyze `--fatal-infos` and format clean; tests pass with 100 % coverage, optimization off: `battle_host` 244 (and the opt-in Appwrite suite, skipped), `battle_rules` 619.

Acceptance criteria:
- The scripted battle stopped after each of its 43 steps, with the uploads under way landing or not at random, recovers to the same snapshot bytes, write-ahead log and uploaded log as a host that never stopped. Also checked: a restart on the same disk (file write-ahead log), a two-hour outage, and a lost disk (what was uploaded comes back, the rest is lost, and the battle goes on).
- `submit` returns, and the order is acknowledged, only after its entry is synced to the write-ahead log: a new reader of the file finds it. A failed write is not acknowledged.
- P-03 on the scripted battle: 57 bytes an entry, one upload per 10-second interval with entries, 53 to 312 bytes compressed. Details in `plan/milestones/performance-tests.md`.

Not run: the Appwrite suite on the local instance. `appwrite-traefik` did not resolve from the container on 2026-11-05. The buckets are in `appwrite.config.json` but not pushed yet (`appwrite push buckets`).

Choices:
- Two log ports. The local `WriteAheadLog` is synchronous: an order waits for its entry to be synced. The issue's `LogSink` with an Appwrite implementation is the kept log, uploaded in batches. `stack/07`'s list of ports gains `WriteAheadLog`.
- An entry holds the command and its events, so it is written right after the order is carried out in memory, and before the order is acknowledged. If the write fails, the in-memory battle is ahead of its log, so the battle stops. Recovery gives it back without that order, which was never acknowledged.
- Batches go up one at a time, in order. A failed batch is sent again unchanged, and an Appwrite 409 means it is already there. A snapshot is taken at a batch boundary and kept only once every batch before it is uploaded. So recovery reads the batches from the snapshot's position, and the uploaded log has no gap.
- No snapshot in a 5-minute interval without new entries. The state is then the last snapshot advanced in time, which recovery reaches by itself. The first snapshot is taken when the battle starts.
- Appwrite Storage: a batch's file ID comes from its log position, so recovery follows the batches by ID and needs no list query (none was tried against the instance). Snapshots use two files per battle and replace the older one, so the latest stays whole while the next is written. A battle ID has at most 23 characters, because a file ID has at most 36.
- The snapshot is JSON in UTF-8, gzipped by the adapter. It is exact (each double prints as the shortest text that reads back as the same double) and keeps the order of maps, so a restored battle walks its units in the same order. A unit's type is stored as its base type and tree, and evolved again. A waiting command uses the protocol's JSON.
- Battle time is wall time since the start, outages included (decision 222).
- `dart_appwrite` 31.1.0 targets Appwrite 2.6 (Cloud). No release targets the local 2.3. The adapters use only `createFile`, `getFileDownload` and `deleteFile`.
- The rate limit's buckets are not in the snapshot: a recovered host gives each sender a full burst.
- The `run` command keeps its stores in memory. The file write-ahead log and the Appwrite stores are wired for hosting in M5.19.

Questions raised: Q-GEN-02 (does a battle's time go on while its server is stopped), answered by the owner: yes (decision 222).
