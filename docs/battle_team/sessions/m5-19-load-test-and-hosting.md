# Session M5.19: Load test and hosting

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 19. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m5-19-load-test` · **Depends on:** M5.12 to M5.16.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/milestones/performance-tests.md`; `plan/stack/01-simulation-host.md` (estimate, hosting); the session logs of M4.11 and M5.10 to M5.16.

## Notes
- Before starting, ask the user which live provider hosts the containers (stack decision 1); the session needs only local Docker, but the image targets that provider.
- The container has no Docker socket: write the `Dockerfile` and compose file, build the AOT executable in the container, and ask the user to build and run the image on the host.
- Update the estimates of `stack/01` and `performance-tests.md` with the measurements (battle_team, same branch name).

## Acceptance criteria
- [x] The acceptance criteria of the issue (m5-simulation-host.md, Issue 19).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-06) on `main` (M5.12 to M5.20 merged). The owner left the live provider open ("decide later"): the image runs on any linux/amd64 Docker host, and `stack/01` says the provider is still open.

- **`battle_host`**:
  - `package:battle_host/load.dart` (`lib/src/load/battle_load.dart`): `LoadSettings`, `loadSetup` (two teams, sections of 16 led by their commander, two machine guns per section, a share of server-managed sections), `placeLoad` (two lines 100 m apart across the middle row, each unit on a free open cell), `BattleLoad.run` (each unit spends its AP: half shots at the nearest enemy it can hit, half 10 m moves towards the enemy, a reload on an empty magazine; 40 % open fire together at the start), `LoadReport` (orders by kind, refusals by code, the host's microseconds per second of battle time). Only `SimulationHost.submit` and `advance` are timed.
  - `bin/load_test.dart`: P-01, P-02 and P-03 on a built map, one machine line per measure (`host_load`, `host_burst`, `host_memory`, `host_log`, `host_paths`), with `--battles`, `--server-managed` and `--wal`.
  - `Rewards._safetyNet` and `StorageLocks.hear` make one pass over the units instead of one per section. The results are unchanged, and an order costs 0.36 ms instead of 1.9 ms in a 1,000-unit battle.
  - `SectionSetup.weapons`: a section brings its spare weapons (UNIT-30).
  - Hosting: `BattlePlacement` (claims the running battles of its maps in the `battles` rows, runs those that name it, recovered or started from the `wars`, `sections` and `guilds` rows; writes status `ended`, the winner and the `BattleResult` for `end_battle`), `resultOf`, `HostService` (1 Hz tick, poll, `prepare` of every mover's search at start, snapshots on stop), `battle_host serve`. `bin/battle_host.dart` watches SIGTERM and SIGINT.
  - `docker/`: `prepare.sh` (AOT executable, plan data and maps into `build/docker`), `Dockerfile` (on the Dart image's `/runtime`, from scratch), `compose.yaml` (one container per map on `hermes-net`, endpoint `http://appwrite/v1`, a volume for the write-ahead logs).
- **`hawkbee_schema`**: `BattleRow.host`; `copyWith` also takes the host, the winner and the result.
- **hawkbee `backend/`**: the `host` column of `battles`; the vendored schema of every function regenerated.
- **`battle_team`**: P-01, P-02 and P-03 measured (`performance-tests.md`); `stack/01`'s load estimate replaced by the measurements, battle placement recorded, the provider still open; `stack/02` and `stack/08` with the measured figures.

Checks: analyze `--fatal-infos` and format clean; tests pass with 100 % coverage, optimization off (and on for `battle_host`): `battle_host` 294 (the Appwrite suite is opt-in and skipped), `hawkbee_schema` 8, `battle_backend` 29, `end_battle` 3.

Measured (AOT, `saint_lo`, one 1,000-unit battle over a simulated day; two identical runs):
- P-02: 7,301 orders (5,609 shots, 1,496 moves, 196 reloads), about **3.1 s of one core a day**: 36 µs per second on average, 0.2 ms at p99, 82 ms in the busiest second (465 orders). The first second takes 0.2 s after `prepare` (2.3 s and +47 MB at load). Map: 342 MB loaded, 389 MB prepared, up to about 670 MB once long paths have been priced for three movers. Each battle adds about 3 MB. Ten battles opening fire together take 0.9 s in their busiest second. 25 % server-managed sections: 3.9 s a day, no visible change. With the file write-ahead log, one `fsync` per order (about 2.3 ms here) makes it 21.6 s a day and 1.1 s in the busiest second.
- P-03: 7,837 entries (8,635 events), 115 bytes an entry, 0.86 MB a day; 836 uploads, 91 bytes compressed at the median, 73 kB at most; 0.24 MB uploaded. A 1,000-unit snapshot is 442 kB, 38 kB compressed.
- P-01 on the real map with shared search data: 2 km paths 21 to 30 ms at the median (target 50), up to 0.35 to 1.1 s. Across the map: jeep 0.23 s, soldier 1.3 to 2.5 s, tank 1.5 to 6.6 s (target 0.5 s). **Missed on real data.**

Acceptance criteria:
- P-02 and P-03 results committed in `performance-tests.md`; `stack/01`'s estimates replaced by the measurements.
- The Docker image: `docker/prepare.sh` ran here, and `battle_host serve` from the staged folder started, reported the unreachable Appwrite at each poll and stopped cleanly on SIGTERM. **Not done here:** the image build and the run next to the local Appwrite. The container has no Docker socket, so the owner has to run them on the host (commands below).
- Battle placement is recorded: in each battle's row (`host`), and how it works in `stack/01`.

To run on the host (owner), from `packages/battle_host` of the checkout:
```sh
docker/prepare.sh saint_lo
docker build -f docker/Dockerfile -t battle_host build/docker
APPWRITE_API_KEY=<key with tables and storage> docker compose -f docker/compose.yaml up -d
```
Before that: `appwrite push tables` (the `host` column) and `appwrite push buckets` (still pending from M5.15).

Choices:
- The scenario harness of M4 Issue 11 puts its units on one line with no map, so the load script is the host's own. It keeps the harness's shape (seeded, timed orders, a one-line summary) and runs through `SimulationHost.submit`, as players would.
- The units are placed by hand before the first snapshot, as the scripted battle of M5.15 does: 1,000 `Deploy` orders would all land on the HQ, 25 km from the front.
- The load test lifts the rate limit. The default (10 orders a second, 20 at once, per sender) would throttle a section's machine guns. That's noted for M6.
- A container serves fixed maps and claims battles in their rows. When two hosts write the claim at the same time, the last write wins and the other host lets the battle go. The `create_battle` function is unchanged.
- A battle's setup comes from its rows: the war's money floor, each section's kept money, XP, weapons and units, and its guild role. Its settings are `battle.yaml`'s, since the rows hold none. Medals do not reach the setup yet: the HQ-manager ranking by medals waits for M5.17's `medals` rows being read.
- `BattleResult.earned` is the section's XP gain divided by `section_xp_share` (UNIT-14), so the XP of units that died counts too.
- The image builds from a staged folder rather than from the source. The workspace includes Flutter apps, which a `dart` image cannot resolve.

Not done / next:
- P-01 across the map on real data: a hierarchical search (blocks with precomputed paths) is the next step.
- Group commit of the write-ahead log, if a burst must stay within a second on slow disks.
- Copying the state's unit map on every change is about 30 % of an order.
- A host never unloads an ended battle; it is not claimed again after a restart.

No rule question in this session.
