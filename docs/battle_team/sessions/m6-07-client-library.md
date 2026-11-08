# Session M6.7: Client library

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 7. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_client` (`hawkbee1/battle_client`, new) · **Branch:** `bt/m6-07-client` · **Depends on:** M6.2, M6.4 (tests against M6.5's endpoints once it is merged or stacked).
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:license-compliance`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/03-networking.md`; `plan/stack/07-engineering-principles.md` (ports, packages); `plan/stack/08-workload-placement.md` (what the client computes); the session logs of M5.9 (codecs on the web), M6.2, M6.4 and M6.5.

## Notes
- New package: the procedure of dc3d §2 with the Very Good CLI MCP `create` (`subcommand: dart_package`, `name: battle_client`, `output_directory: packages`, `workspace: true`, a description without a colon). Create `hawkbee1/battle_client` with `gh repo create --public`, add it to the root `workspace:` and melos `format` lists, and apply the new-package pitfalls of dc3d §2.
- Pure Dart, no Flutter. The transport adapter on `web_socket_channel` runs on native and web; check its API with context7 and its licence. Time comes from an injected `Clock`, backoff jitter from an injected random.
- The JavaScript check: compile with dart2js and run the view tests' recorded streams on Node, as M5.9 did for the codec.
- The order pre-check with `battle_rules` (stack decision 8) is M7's, in this package.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m6-networking.md, Issue 7).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-08), stacked on M6.5 (`bt/m6-05-endpoints`, hawkbee #64): the hawkbee, `battle_host` and `battle_team` branches start from M6.5's; `battle_protocol` from M6.2's (`bt/m6-02-messages`).
- **`battle_client`** (new package, public repository `hawkbee1/battle_client`, merge commits only, submodule of hawkbee, in the root `workspace:` and melos `format` lists; template CI, dependabot and placeholder code deleted; dependencies `battle_protocol`, `web_socket_channel` 3.0.3 and `args`, dev `fake_async`; licences BSD-3 and MIT):
  - `lib/src/ports/`: `Transport` and `TransportSocket` (binary frames), `Clock`. `lib/src/adapters/`: `WebSocketTransport` on `web_socket_channel` (`dart:io` natively, `package:web` in the browser), `SystemClock`.
  - `HeldView`: the section's view from its `SectionView`, then each `TickUpdate` (moves, units in and out, whole own units, hits from events, bursts, `Fired` and unseen hits, heals and repairs, the countdown, HQs, relics, the delta layer in the host's order). `apAt` (COMBAT-02).
  - `BattleClient`: sign-in with a `Credential` (JWT or API key) asked for at each connection, `send(Order)` → `CommandAnswer` by request ID, `resync`, heartbeats, reconnection with `Backoff`, `battleTime` and `apNow` from the host's last message, `statuses` and `messages` streams. `RequestIds`.
  - `NearestEnemyAgent` and `bin/nearest_enemy_agent.dart`: signs in with `BT_API_KEY`, each unit on the field with a weapon fires at the nearest enemy the section sees, one order in flight per unit.
- **`battle_protocol`**: `UnitView.team` (Q-MAP-27, assumed); the host message samples rewritten before merge, as for decision 237 (only the three samples with units changed).
- **`battle_host`**: `SectionViews` fills the team; `tool/record_streams.dart` writes the recorded streams; `test/src/adapters/battle_client_test.dart` runs `battle_client` against `HostServer` on the loopback interface; `battle_client` as a dev dependency.
- **`battle_team`**: Q-MAP-27; `stack/03` (the client's values, sizes with the team); `stack/07` (the `Transport` port).

Checks: analyze `--fatal-infos` and format clean in `battle_client`, `battle_host` and `battle_protocol`. `battle_client` 65 tests, 100 % line coverage, optimization off and on; `battle_host` 396 tests, 100 %, optimization off (the two Appwrite suites opt-in and skipped); `battle_protocol` 733 tests, 100 %.

Acceptance criteria:
- **A view fed a recorded stream equals the host's view of that section**: `test/src/held_view_test.dart` replays the eight streams of M5.15's scripted battle (clear and fog, `s-1` and `s-2`, from the start and from halfway) and each ends equal to the host's whole view at the end: units, HQs, relics, private state, countdown, delta layer.
- **A socket dropped with a command in flight**: `battle_host`'s `battle_client_test.dart` drops the socket right after a command goes out, so the host carries it out but the client never gets the answer; the client signs in again, resends it with its request ID, gets the first answer, the log holds the command once, and the view equals the host's. The same on a fake transport in `battle_client` (`battle_client_test.dart`).
- **The library compiles to JavaScript**: a check program (not committed) embedding the recorded streams, compiled with `dart compile js -O2` and run on Node 22 (with `globalThis.self = globalThis`, which dart2js output expects), and with `dart compile wasm` run on Node: every stream replays to the host's view, a request ID stays exact, and `WebSocketTransport` opens a browser WebSocket (refused on a closed port, as expected).
- The example agent signs in to the host with an API key and fires at an enemy, logged with the origin `ai` (`battle_client_test.dart` in `battle_host`).

Choices:
- **Q-MAP-27, assumed**: a client could not tell an ally from an enemy, which the agent and M7 need. A seen unit now carries its section's team (`UnitView.team`), as a hit already says whether it was friendly fire. The view of 16 units grows from 2,239 to 2,383 bytes.
- **Request IDs** (`stack/03`): wall-time milliseconds × 1,024 plus a random number below 1,024, above the last one; unique within 15 minutes across restarts.
- **Reconnection**: a battle not on the host it reached is looked for again (M6.6 moves battles); a refused credential or section, and the goodbyes for an ended battle, a revoked key or an unknown version, stop the client and fail its unanswered commands with `ClientStoppedException`. A JWT is asked for at each connection, since it lasts 15 minutes.
- Unanswered commands are resent before the status turns `signedIn`, so a command a status listener sends at that moment goes out once (found by the loopback test).
- The client has no idle timeout of its own: the host sends nothing while nothing changes, so silence is not a lost host.

Not done / next:
- The order pre-check with `battle_rules` (M7). Interpolation and drawing (M7).
- M6.8 plays the load test over sockets with this client; M6.6 gives `address` the battle's real host.

