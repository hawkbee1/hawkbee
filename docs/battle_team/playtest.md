# Battle Team playtest

A first look at a battle in 3D, before M7 is planned: one player, blue, on a 1 × 1 km map, moving their section. Red is a second beginner who stays in the HQ. Everything goes through the real stack: Appwrite sign-in, `bt_battle_host` to find the host, the host's socket, the rules.

## Pieces
- **Map** `saint_lo_1km` (`battle_map` `maps/`): 1 × 1 km of the Vire valley inside `saint_lo`, imported from IGN and OpenStreetMap data, HQs north (blue) and south (red), five relics.
- **Setup** `battle_host` `tool/playtest.dart`: the accounts `blue@battleteam.local` and `red@battleteam.local` (a new password each run), a war and its battle on `saint_lo_1km` with teams `blue` and `red`, one beginner section each (a commander and 500 w€, SOC-15). Once a host runs it, blue buys four soldiers and a scout and deploys them, through the socket as a player would. It writes blue's sign-in and the battle to `apps/battle_team/env/playtest.json` (not committed). Each run closes the playtest battles still running and starts new ones.
- **App** `apps/battle_team/lib/main_playtest.dart` boots the app (title, then the battle) with the self-signed certificate of the local Appwrite trusted; **Start** signs in as blue and opens the battle. The development flavor does the same with `env/playtest.json` and no trust. flutter_scene draws the ground (coloured by terrain, shaded by slope), trees, buildings, HQs, relics and the units the section sees; units glide to where the host puts them by their move's arrival time. Drag to pan, scroll or pinch to zoom, Q/E or two fingers to turn; tap one of your units, then the ground, to move it.

## Run it
In `factory1`, from `packages/battle_host`, with the tooling key (`LOCAL_TOOLING_API_KEY`, see `docs/project-setup.md`):
```sh
# 1. A host for the map, its public address on port 8091:
APPWRITE_ENDPOINT=http://appwrite-traefik/v1 APPWRITE_PROJECT_ID=hawkbee APPWRITE_API_KEY=<key> \
  dart run battle_host:battle_host serve --plan ../../apps/battle_team/plan \
  --maps ../battle_map/maps/built --map saint_lo_1km --data build/playtest \
  --host-id playtest --port 8091 --public-address http://localhost:8091
# 2. The accounts, the battle and blue's opening:
APPWRITE_API_KEY=<key> dart run tool/playtest.dart
```
Then launch **battle_team (playtest)** (root `.vscode/launch.json`). With `env/development.json`'s `http://localhost/v1`, the app runs in a browser on the laptop (`-d web-server`): VS Code forwards the app's port and the host's 8091 to the laptop's `localhost`. On a phone, set the host's `--public-address` and the Appwrite endpoint to the laptop's LAN address, or use `adb reverse tcp:8091 tcp:8091`. For a phone, put the LAN `APPWRITE_ENDPOINT` (https) in `env/playtest.json` next to the sign-in keys, and launch **battle_team (playtest)**: it reads that file last, so it wins over `env/development.json`, and it trusts the self-signed certificate. The *development* entries read `env/playtest.json` first, so a browser keeps `http://localhost/v1`.

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

## What the rules make of it
A foot unit holds 30 AP, spends 1 AP a metre and gets 1 AP back an hour (`data/units.yaml`, `data/battle.yaml`): a soldier dashes 30 m, then waits. That is the game as written; a faster AP rate for playtests would be a battle setting, which the rows do not hold yet.

## Not done
- No fire, deploy or buy buttons: only selecting and moving.
- Moves go straight to the tapped point; the host checks and paths them.
- No fog shading: the map shows whole; units the section does not see are not drawn.
