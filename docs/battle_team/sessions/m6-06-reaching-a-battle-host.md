# Session M6.6: Reaching a battle's host

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 6. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`docker/`), hawkbee `backend/`, `hawkbee_schema` · **Branch:** `bt/m6-06-host-address` · **Depends on:** M6.5.
**Skills:** `appwrite:cli`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/01-simulation-host.md` (hosting, placement); `plan/stack/02-persistence.md` (resource IDs, `bt_` prefix); `docs/project-setup.md` §4 to §6 (local Appwrite); the session logs of M5.18, M5.19 and M5.21.

## Notes
- Needs the Docker host and the local Appwrite. From the dev container `factory1`, the endpoint is `http://appwrite-traefik/v1`, but there is no Docker socket: do the code steps there and leave the image build and the compose run to the owner, with the commands in the log (as M5.19 did). The tooling API key rule of M5.21 applies.
- Table permissions: a player reads the address of the battles they play in, nothing more. Check what Appwrite 2.7.1 row permissions allow before choosing between a column on `bt_battles` and a hosts table.
- The live reverse proxy and its certificates belong to the live provider, which the owner leaves open: write the local setup and what live needs, nothing provider-specific.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m6-networking.md, Issue 6).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-08), stacked on M6.7 (`bt/m6-07-client`, hawkbee #65): the hawkbee, `battle_host`, `battle_client` and `battle_team` branches start from M6.7's, `battle_backend` from M5.21's (`bt/appwrite-prefix`).

- **Permissions, checked first** (Appwrite docs, TablesDB permissions): a user reads a row granted either by its table or by the row itself. `bt_battles` grants `read("users")`, so an address column there would reach every user; and an AI agent signs in with its API key, which gives no Appwrite session to read rows with. So the address lives in a new table `bt_hosts` (no permission for any client), and a function is the only way to it.
- **`hawkbee_schema`**: `HostRow` (`address`, `seen_at` in UTC, `aliveAt`); `AppwriteIds.hostsTableId`, `battleHostFunctionId`; `BattleRow.copyWith(host:)` takes a function so the host can be cleared.
- **hawkbee `backend/`**: `bt_hosts` (`address` varchar 2048, `seen_at` datetime) and the function `bt_battle_host` (`functions/battle_host`, execute `any`, scope `rows.read`, timeout 15 s); every function's vendored copies refreshed (they also lacked M6.2's and M6.3's `battle_protocol` and `battle_rules`).
- **`battle_backend`**: `BattleHosts.addressOf`: the caller from Appwrite's header, or the account of an API key in the body; the address only for an account with a section in one of the battle's teams. Refusals `not_signed_in` 401, `unknown_battle` 404, `not_your_battle` 403, `not_running` 409, `no_host` 503.
- **`battle_host`**:
  - `BattlePlacement` writes `bt_hosts` (its `address`, the time) at each sync; claims a running battle whose host's row is older than `lease` (60 s) or missing; discards its own write-ahead log of a battle it claims (`WriteAheadLog.discard`, new in the port), since another host may have run it since; stops running a battle whose row names another host (`SimulationHost.release`; the endpoints close its sockets at their next tick); `leave` lets go of the battles all uploaded (`SimulationHost.saved`, `Journal.saved`) and deletes its row. `HostService.stop` ends with `leave`.
  - `serve --public-address` (`http://<host-id>:<port>` by default, `https://…` live; an http or https URL, no query) and `--lease` (60, more than `--poll`). A stop whose Appwrite calls fail is reported, and the process still ends.
  - `docker/compose.yaml`: endpoint `http://appwrite-traefik/v1` (M5.21's name; it still said `appwrite`), the public address, port 8080 published as 8081, and a spare container of `saint_lo` (profile `spare`, 8082) for the move.
- **`battle_client`**: `AppwriteHostFinder.socketOf(battle, credential)` on `package:http` (BSD-3, runs on the web): the JWT as Appwrite's JWT header, a key in the execution body; `socketAddress` (`https` → `wss`, `/v1/socket`); `HostLookupException` (`lasting` below 500). `BattleClient`'s address callback now takes the credential, asked first; a lasting refusal stops the client (`lookupRefused`, `ClientStoppedException.lookupRefused`), `no_host` and server errors are asked again after the backoff. The example agent finds its host through `--appwrite` (`--host` still overrides). New dependencies `hawkbee_schema` and `http`.
- **`battle_team`**: `stack/03` "Finding a battle's host" (the function, permissions, TLS live and locally, moves); `stack/01`'s placement with the hosts, the lease and the release.

Checks: analyze `--fatal-infos` and format clean in every touched package and function. 100 % line coverage, optimization off: `hawkbee_schema` 9 tests, `battle_backend` 34 (the live suite opt-in, skipped), `battle_client` 78, `battle_host` 409 (three live suites opt-in, skipped), `bt_battle_host` 4; the other six functions pass on their refreshed vendored copies.

Acceptance criteria:
- **A client given only a battle ID opens a socket to its host and signs in**: `test/src/hosting/host_moves_test.dart` on the loopback interface (the lookup is `BattleHosts` over the same tables), and on the local stack: `test/live/appwrite_host_address_test.dart`, run once with the owner's permission on 2026-11-08, passes. It writes a war, two sections and a running battle in the local Appwrite's tables, runs two placements with `HostServer` on the loopback interface, and the client signs in with a JWT of a new user after asking the deployed `bt_battle_host` (its two executions answered the first host's address, then the second's). Everything it created is deleted.
- **A host restarted on another container: the client reaches the battle again**: the same live test stops the first host (a planned stop: last snapshot, `leave`), starts a second with another ID and port, and the client signs in there and gets an answer to a command. `host_moves_test.dart` also covers a crash: within the lease the battle stays with its host; after it, a third container takes it from the uploads and the client follows.
- Pushed to the local Appwrite with the tooling key: `bt_hosts` (`appwrite push tables`; the other tables unchanged, the `host` column and the buckets were already there since M5.21) and `bt_battle_host` (`appwrite push function --function-id bt_battle_host`, deployment ready). An anonymous execution answers 400 `no_battle` and 401 `not_signed_in`; Appwrite keeps no execution body, so an agent's key never shows in the executions.

Not done here (no Docker socket in `factory1`); for the owner, from `packages/battle_host`:
```sh
docker/prepare.sh saint_lo
docker build -f docker/Dockerfile -t battle_host build/docker
APPWRITE_API_KEY=<key with tables and storage> dabocker compose -f docker/compose.yaml up -d
docker compose -f docker/compose.yaml --profile spare up -d host-saint-lo-b
docker compose -f docker/compose.yaml stop host-saint-lo   # the spare takes its battles
```
For phones on the LAN, set `HOST_SAINT_LO_ADDRESS=http://<LAN_IP>:8081`.

Choices and numbers:
- **A function, not a readable table**: it covers both JWTs and API keys, any number of players (row permissions would need one per player), and leaves `bt_battles` as it is. A lookup costs one execution per connection, not per order.
- **Lease 60 s, look every 10 s**: one slow look moves nothing. A planned stop lets its battles go at once, so a restart behind `restart: unless-stopped` or a spare takes them at the next look (about 10 s). A crash costs up to 60 s plus a look before another host runs the battle, and loses what was not uploaded (stack decision 2's accepted 10-second window).
- **A claimed battle starts from its uploads**: a host keeps using its write-ahead log only for a battle still named to it when it starts again. A battle it claims (free, or from a host past its lease) may have run elsewhere, and replaying its stale entries would diverge.
- **The function does not check the lease**: an address of a host that has just stopped makes the client fail to connect and ask again after the backoff, which is what `no_host` would do too.
- **TLS live**: one `https://` name per container behind the proxy (or one name with a path per container: `socketAddress` keeps the path). The proxy forwards WebSocket upgrades and keeps idle sockets longer than the 60 s idle timeout. Nothing provider-specific.

Not done / next:
- A host that loses its lease while still alive (Appwrite unreachable from it for 60 s) may upload a batch after another host has recovered the battle; it stops at its next look, when it sees the row. Fencing the uploads (a host's claim in each batch's name) closes this if it ever happens.
- `bt_battles` gives every signed-in user every battle's `seed`. With the seed and the log order a player could predict the battle's random draws. Not this issue's; worth a row-security or column change before M8.
- An ended battle is never unloaded from its host (M5.19's note stands).

