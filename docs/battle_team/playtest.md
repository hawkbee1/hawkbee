# Battle Team playtest

A first look at a battle in 3D, before M7 is planned: one player, blue, on a 1 × 1 km map, moving their section. Red is a second beginner who stays in the HQ. Everything goes through the real stack: Appwrite sign-in, `bt_battle_host` to find the host, the host's socket, the rules.

## Pieces
- **Map** `saint_lo_1km` (`battle_map` `maps/`): 1 × 1 km of the Vire valley inside `saint_lo`, imported from IGN and OpenStreetMap data, HQs north (blue) and south (red), five relics.
- **Setup** `battle_host` `tool/playtest.dart`: the accounts `blue@battleteam.local` and `red@battleteam.local` (a new password each run), a war and its battle on `saint_lo_1km` with teams `blue` and `red`, one beginner section each (a commander and 500 w€, SOC-15). The battle is a **testing battle** (decisions 238, 239): by default (`--fast`) its settings give a recovery delay of 1 s (`ap.recovery_delay_s`, one AP back every second, so a soldier moves continuously) and allow the `test_unit` (10,000 AP, every action, price 0); `--no-fast` plays the rules as written. Once a host runs it, blue buys four soldiers, a scout and, when fast, a test unit, and deploys them, through the socket as a player would. It writes blue's sign-in and the battle to `apps/battle_team/env/playtest.json` (not committed). Each run closes the playtest battles still running and starts new ones.
- **App** `apps/battle_team/lib/main_playtest.dart` boots the app with the self-signed certificate of the local Appwrite trusted and signs in as blue at once: it opens on the battle, and the sign-in page shows only when that sign-in fails (a stale password after a new run of the tool). The development flavor is the normal app (M7.12): the sign-in page, where an account signs up or in and plays the battle its section is in (`bt_sections`, then the running `bt_battles` with that section in a team); an account with no section sees "no section in a running battle yet". It trusts the same certificate. A **Log out** entry sits beside **Credits** in the battle. flutter_scene draws the ground (coloured by terrain, shaded by slope), trees, buildings, HQs, relics and the units the section sees; units glide to where the host puts them by their move's arrival time. Drag to pan, scroll or pinch to zoom, Q/E or two fingers to turn; tap one of your units, then the ground, to move it. Tap an enemy to target it, then **Fire** on the unit panel; **Fire at position** (artillery, the engineer's charge), then a tap on the ground, fires there; **Reload** and **Swap to …** are beside them. In the view from a unit, **Fire** shoots where the reticle points; the shots the section sees show for a moment (a tracer, a muzzle flash, a hit mark).

## Run it
In `factory1`, from `packages/battle_host`, with the tooling key (`LOCAL_TOOLING_API_KEY`, see `docs/project-setup.md`):
```sh
# 1. A host for the map, its public address on port 8091:
APPWRITE_ENDPOINT=http://appwrite-traefik/v1 APPWRITE_PROJECT_ID=hawkbee APPWRITE_API_KEY=<key> \
  dart run battle_host:battle_host serve --plan ../../apps/battle_team/plan \
  --maps ../battle_map/maps/built --map saint_lo_1km --data build/playtest \
  --host-id playtest --port 8091 --public-address http://localhost:8091
# 2. The accounts, the battle and blue's opening:
APPWRITE_API_KEY=<key> dart run tool/playtest.dart   # --no-fast: the rules as written
```
Then launch **battle_team (playtest)** (root `.vscode/launch.json`). With `env/development.json`'s `http://localhost/v1`, the app runs in a browser on the laptop (`-d web-server`): VS Code forwards the app's port and the host's 8091 to the laptop's `localhost`. On a phone, set the host's `--public-address` and the Appwrite endpoint to the laptop's LAN address, or use `adb reverse tcp:8091 tcp:8091`. For a phone, put the LAN `APPWRITE_ENDPOINT` (https) in `env/playtest.json` next to the sign-in keys, and launch **battle_team (playtest)**: it reads that file last, so it wins over `env/development.json`, and it trusts the self-signed certificate. The *development* entries (debug, profile, release) do not read `env/playtest.json`, so a browser keeps `http://localhost/v1`; **battle_team (phone)** is the normal app, with the sign-in page, that reads it last for the LAN endpoint.

The host is a process in `factory1`, not a service: it stops when the session that started it ends, and the app then shows "Host lost, coming back…". Start it again with the same command in the background, output to a log file (`nohup … > host.log 2>&1 &`). It recovers the battle from its last snapshot and uploads, and the app reconnects by itself within half a minute. Check `curl http://localhost:8091` answers before blaming the app.

### With the Docker host `host-saint-lo-1`
The compose host (`packages/battle_host/docker/compose.yaml`, container `battle_host-host-saint-lo-1`, port 8081) serves `saint_lo` and `saint_lo_1km`, so it can run the playtest battle and survives the end of a session. It needs an image that holds the 1 km map. On the laptop, from `packages/battle_host`:
```sh
docker/prepare.sh saint_lo saint_lo_1km
docker build -f docker/Dockerfile -t battle_host build/docker
# The address clients reach it at must work for the setup tool in factory1 and
# for the app on the laptop or phone: the laptop's LAN address, not localhost.
HOST_SAINT_LO_ADDRESS=http://<LAN_IP>:8081 APPWRITE_API_KEY=<key> \
  docker compose -f docker/compose.yaml up -d host-saint-lo
docker logs battle_host-host-saint-lo-1 2>&1 | grep 'address='   # what it registered
```
Then, in `factory1`, step 2 above only (`dart run tool/playtest.dart`): the host that serves `saint_lo_1km` claims the new battle at its next look (10 s), and blue's opening goes through it. Check `curl -i http://localhost:8081/v1/socket` answers `426` (it waits for a WebSocket) before blaming the app.

## Logs
The app logs on `package:logging` (`apps/battle_team/lib/logging/`), printed to the console in debug and profile, nothing in release. One line per event, `[bt] <LEVEL> <logger> <message>`; an error and its stack follow on lines with the same prefix. On a phone:
```sh
adb logcat | grep '\[bt\]'
```
A run reads, in order: `connecting (attempt n)`, `credential jwt`, `host address wss://…`, `socket open`, `sign-in accepted`, `command <id> sent: Move`, `command <id> accepted` (or `WARNING … refused <code>`). With the host down: `SEVERE … connecting failed` with the error, `host lost, retry in <s> s`, then the next attempt. `SEVERE` is an exception, `WARNING` a refusal. Sign-in with Appwrite logs `sign-in: started/done/failed` and `create JWT: …` (never the password or the JWT). Nothing of the units or the section's view is logged (decision 237).

## What the rules make of it
A foot unit holds 30 AP, spends 1 AP a metre and gets 1 AP back an hour (`data/units.yaml`, `data/battle.yaml`): a soldier dashes 30 m, then waits. That is the game as written (`--no-fast`). The default playtest battle overrides the delay with its own settings (`bt_battles.settings`), so a soldier gets 1 AP a second and a test unit never runs out.

The `settings` column is new in `bt_battles`: run `appwrite push tables` once (from `backend/`) before the first playtest on a local Appwrite that does not have it. A host started before M7.2 recovers no snapshot of the old format (`snapshotVersion` 2): clear its `--data` folder (`build/playtest`).

## Not done
- Selecting, moving, firing, reloading, swapping, storing, recalling, deploying (from the Storage panel, M7.6) and buying units and weapons (from the Shop panel, M7.7: the host's roster, the test unit only in a battle with `test_units`). Not the guild camp, not skill nodes.
- A tap on the ground previews the move (M7.8): the path, its AP cost and the wait for AP, from the built map in the app's assets; Confirm sends it with the path, which the host checks. The preview knows the map as built: structures built or destroyed in the battle are not applied to it. From a unit's eyes a move still goes at once.
- No fog shading: the map shows whole; units the section does not see are not drawn.
