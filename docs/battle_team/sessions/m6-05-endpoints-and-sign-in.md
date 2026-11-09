# Session M6.5: Endpoints and sign-in

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 5. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m6-05-endpoints` · **Depends on:** M6.2, M6.4.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:static-security`, `appwrite:dart`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/03-networking.md` (consequences: JWT, endpoints); `plan/stack/06-accounts-and-services.md` (API keys, origins); `plan/stack/08-workload-placement.md` (client trust); `plan/specs/80-ai-and-automation.md`; HQ-07; the session logs of M5.9 (API key format), M5.11 (rate limit, `EnterBattle`), M5.15 (acknowledgement after the write-ahead log), M5.18 (`ApiKeys`), M5.19 (`serve`), M5.21 (`bt_` resources, the local Appwrite) and M6.4.

## Notes
- Endpoints on `dart:io` `HttpServer` (WebSocket upgrade included), or a package checked with context7 and `packages_check_licenses`. They are adapters: the sign-in, the request-ID memory and the queues are core code tested without sockets.
- The JWT check: `dart_appwrite` with `setJWT` and `Account.get`. The API key check: the hash lookup of `battle_backend`'s `ApiKeys`. One port, one contract suite, a fake and the Appwrite adapter; the Appwrite run is tagged and opt-in (M5.21's notes say how the live suites run).
- Record the rate-limit values in `stack/03` (battle_team, same branch name), and whether AI agents may hold a socket (the issue assumes they may, so they get the same fog-filtered view as players, AI-03).
- How long the host remembers request IDs, and the queue bound of a slow client: say which and why in the log.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m6-networking.md, Issue 5).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-08), stacked on M6.4 (`bt/m6-04-stream`, hawkbee #63): the hawkbee, `battle_host` and `battle_team` branches start from M6.4's.
- **`battle_host`**:
  - `lib/src/ports/account_check.dart`: the `AccountCheck` port (`jwt`, `apiKey`) and the fake `MemoryAccountCheck` (JWTs in a map, keys through `battle_backend`'s `ApiKeys` on `MemoryRows`). `lib/src/adapters/appwrite_account_check.dart`: `AppwriteAccountCheck` (a client per sign-in with `setJWT`, then `Account.get`; 400 and 401 refuse, any other error is rethrown; keys by their hash in `bt_api_keys`). One contract suite (`test/helpers/endpoints.dart`) runs on the fake, on the adapter over a mocked `Account`, and on the local Appwrite (`test/live/appwrite_sign_in_test.dart`, tagged `appwrite`).
  - `lib/src/endpoints/`: `Endpoints` (Facade, no sockets): `seat` (the sign-in: battle here, credential, the account's section; origin `player` for a JWT, `ai` for a key), `enter` (`SignInAccepted`, then the subscription of M6.4, then the server's `EnterBattle`), `command` (the sender replaced by the seat's, the request-ID memory, `SimulationHost.submit`), `call` (HTTPS), `tick` (idle sockets, ended or failed battles, key re-check), `closeAll`. `Connection` (a `SectionSubscriber`): frames handled in order, the bounded queue, goodbyes. `RequestMemory`. `ClientSocket` is the port the WebSocket adapter implements.
  - `lib/src/adapters/host_server.dart`: `HostServer` on `dart:io`: `GET /v1/socket` and `POST /v1/battles/<battle>/commands`. The WebSocket handshake is done by hand (`detachSocket`, `WebSocket.fromUpgradedSocket`) so that the host holds the raw socket and cuts one stuck on a write 5 s after closing it.
  - `serve` gains `--address` and `--port` (8080, `EXPOSE`d in the Dockerfile); `HostService.tick` ticks the endpoints. `HandledOrder.seq` gives `CommandAccepted` its sequence number. `RateLimit` defaults to 500 at once and 10 a second. New dependency `crypto` (BSD-3, already used by `battle_protocol` and `battle_backend`).
- **`battle_team`**: `stack/03` (endpoints, the values below); `stack/07`'s ports; `performance-tests.md` (P-02's rate-limit note); Q-AI-12 assumed.

Checks: analyze `--fatal-infos` and format clean; `battle_host` 394 tests pass with 100 % line coverage, optimization off (and on); the two Appwrite suites are opt-in and skipped.

Acceptance criteria (`test/src/endpoints/endpoints_test.dart`, `test/src/adapters/host_server_test.dart` on the loopback interface):
- Sign-in with a fake JWT and with a key; refused: a bad JWT, a key not one, a battle not on this host, a battle the account has no section in, an unknown protocol version (a goodbye, in the encoding it came in), a key revoked between two HTTPS calls (401 on the second), a command for another section (`not_your_unit`; the sender the client wrote is replaced by the signed-in one).
- An order over the socket logged with the origin `player`, one over HTTPS with `ai`.
- A resent command carried out once, on the socket and on HTTPS with the same request ID; a flood of 2,000 orders in a second throttled to the bucket (at most 511 handled) while a section's whole action plus two machine guns emptying their pools at 500 rounds a minute is never throttled.
- Heartbeats and the idle timeout; a slow client dropped and caught up with its whole view; a socket that closes changes nothing in the battle (AI-02).
- The sign-in with a JWT of the local Appwrite (`appwrite-traefik`, 2.7.1): run by the owner on 2026-11-08, passes. The container holds no API key, so it runs outside the MCP test tool (the key needs `users.read`, `users.write`, `rows.read`, `rows.write`; the test creates two users and deletes them; their key rows stay in `bt_api_keys`):
  ```sh
  cd packages/battle_host
  APPWRITE_API_KEY=<key> dart test --tags appwrite --run-skipped test/live/appwrite_sign_in_test.dart
  ```

Choices and numbers:
- **Rate limit** (`stack/03`): 500 orders at once, 10 a second, per account. A section's whole AP spent at once on 1-AP machine-gun shots is 480 orders, so no real burst is throttled; a steady flood is.
- **Request IDs** are remembered 15 minutes, the life of a sign-in JWT: a client that comes back resends within it (M6.7). Bounded by the rate limit (at most about 9,500 answers per sender). Every answer is kept, a throttled one too, so a client that resends gets what it got. The memory is not in the log or the snapshot: after a crash between a command's write and its acknowledgement, a resent command runs again. Fixing it needs the request ID in the log entry (version 2), noted in `stack/03`.
- **Slow client**: 1 MiB may wait behind the oldest waiting message. The oldest is not counted, so a whole view of any size (the delta layer grows with the battle) goes out; a client whose updates pile up behind it is dropped. Measured on the loopback interface: a client that stops reading holds about 6.5 MB in the system's buffers before the host's writes wait.
- **Idle**: a client sends a heartbeat every 20 s; 60 s of silence closes a socket, signed in or not. A key-signed socket's key is checked again every 60 s (`GoodbyeReason.keyRevoked`, decision 161); JWT sockets are checked once (stack decision 3).
- **AI agents hold sockets** with the same fog-filtered view as players (AI-03). Sockets accept JSON in text frames too, answered in JSON. A socket's sign-in, JWT or key, logs the account in (`EnterBattle`): **Q-AI-12**, assumed; HTTPS calls do not.
- `EnterBattle` is submitted after the subscription, so the player's waiting alerts go out once with the view (decision 233). The section's update of an accepted order goes out before the order's `CommandAccepted`, since `submit` flushes the stream.
- A sign-in or a call whose Appwrite check fails (Appwrite down) is reported; the socket closes with 1011, HTTPS answers 500.
- Messages: this issue adds none, so no new size or "nothing hidden" proof; `SignInAccepted` names the account's own section only.

Not done / next:
- WebSocket compression (the handshake is the host's own): M6.8 measures whether the late join needs it.
- A sign-in flood by a valid client logs an `EnterBattle` each time; the rate limit does not count sign-ins.
- M6.7 chooses request IDs that do not repeat within 15 minutes across its restarts.

