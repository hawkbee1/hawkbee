# Session M5.21: Local Appwrite deployment

**Issue:** none in the milestone: deploy the M5.17 to M5.19 backend to the local Appwrite and prove it there.
**Package:** hawkbee `backend/`, `hawkbee_schema`, `battle_backend`, `battle_host` · **Branch:** `bt/appwrite-prefix` · **Depends on:** M5.19 (#57).
**Read:** `docs/project-setup.md` §4 to §6 (local Appwrite 2.7.1); `plan/stack/02-persistence.md` "Resource IDs"; the session logs of M5.18 and M5.19.

## Notes
- The local Appwrite runs on the owner's laptop (Docker host). From the dev container `factory1` on `hermes-net`, the endpoint is `http://appwrite-traefik/v1`; from the laptop, `http://localhost/v1`. An environment that reaches neither (a cloud session) cannot do the deploy steps: do the code steps there and leave the deploy to a session on the laptop or in `factory1`.
- The tooling API key (`local-tooling`, all scopes plus the legacy `collections.*`, `attributes.*`, `documents.*`) is `LOCAL_TOOLING_API_KEY` in `appwrite/appwrite-local.env` of the owner's private repo `hawkbee1/dockers`. Never copy it into this repo or print it. Configure the CLI with `appwrite client --endpoint <endpoint> --project-id hawkbee --key "$LOCAL_TOOLING_API_KEY"`.
- Appwrite CLI 28.11.0 or later. It still creates columns through the deprecated Databases API, which is why the key needs the legacy scopes. Push non-interactively with `--all --force`.
- The live opt-in suites (`battle_backend` `test/live`, `battle_host` `test/live`) read `APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID` and `APPWRITE_API_KEY` from the environment. The Very Good CLI MCP test tool cannot pass them, and a hook blocks `dart test` in Bash: ask the owner how to run them.

## Acceptance criteria
- [x] Battle Team's Appwrite resources carry the `bt_` prefix (label `btadmin`), the rule in `plan/stack/02-persistence.md`.
- [x] Local Appwrite 2.7.1 installed, project ID `hawkbee`, Web platform `localhost`, runtime `dart-3.13`, SMTP to maildev.
- [x] `appwrite push table` and `appwrite push bucket`: 9 tables, 46 columns, 12 indexes available; a second push detects no change.
- [x] `appwrite push function --all --force` from `backend/` (after `dart run tool/vendor_packages.dart`); every deployment `ready`; executing `ping` answers `{"status":"ok","databaseId":"hawkbee"}`.
- [x] The live opt-in suites of `battle_backend` and `battle_host` pass against the local Appwrite.
- [ ] The owner's account carries the label `btadmin`; `bt_create_war` run as that account creates a war.
- [x] `appwrite` (Flutter SDK) bumped from `^27.0.0` to the 28.x line, which targets server 2.7.x; the apps still ping.

## Session log
Started (2026-11-06 to 2026-11-07) on `bt/m5-19-load-test`.

- **`bt_` prefix**: the Hawkbee apps share one Appwrite project and its `hawkbee` database, so Battle Team's tables, buckets and functions are `bt_…` and its admin label is `btadmin` (labels allow only letters and digits). `AppwriteIds` holds every ID, the snapshots bucket included (`battle_host` no longer hard-codes its buckets); the tests use the constants. Function folders keep their names (`backend/functions/create_war`), mapped to the `bt_` IDs in `appwrite.config.json`.
- **`appwrite.config.json`**: float columns are `double`, the type name the CLI accepts.
- **`docs/project-setup.md` §6**: the official 2.7.1 installer (`--publish 20080:20080` for its web page), why phones use `http://<LAN_IP>/v1` (the API answers any host), what `.env` may change after the first start, and creating the project ID `hawkbee` with the CLI when the Console offers no ID field.

Checks: analyze `--fatal-infos` clean; tests pass with 100 % coverage, optimization off: `hawkbee_schema` 8, `battle_backend` 29, `battle_host` 294, the seven functions.

Continued (2026-11-07 to 2026-11-08) in `factory1`, where `http://appwrite-traefik/v1` reaches the local Appwrite.

- **Function scope**: Appwrite 2.7 names the scope `executions.write`; `execution.write` is a legacy alias that a key holding only the current scopes cannot grant, so `appwrite push function` refused the five functions asking for it. `appwrite.config.json` uses the current name; the key needs no extra scope. The seven deployments are `ready`; `ping` answers `{"status":"ok","databaseId":"hawkbee"}`. The CLI warns that it skips default domain rules without a Console session: functions run through the API, so they need none.
- **Function endpoint**: Appwrite passes functions `APPWRITE_FUNCTION_API_ENDPOINT=http://<_APP_DOMAIN>/v1`. With `_APP_DOMAIN=localhost`, `bt_create_war` called itself and failed (connection refused), and function containers on `runtimes` could not reach the router anyway. Fix chosen by the owner, on the Docker side with no code change: `_APP_DOMAIN=appwrite-traefik`, `_APP_CONSOLE_DOMAIN=localhost` (2.7 keeps the Console on its own host), and `traefik` also on `runtimes`; `docs/project-setup.md` §1, §6.3 and §6.4 say so.
- **Live suites**: run once in Bash with the owner's permission (the MCP test tool cannot pass `APPWRITE_API_KEY`): `battle_backend` 2 and `battle_host` 8 pass against the local Appwrite.
- **Flutter SDK**: `appwrite_api_client` takes `appwrite: ^28.3.0`, which targets server 2.7.x. 28.x is a Flutter plugin with Android push code: its `flutter_local_notifications` needs core library desugaring, now enabled in the Android app of `hawkbee` and `battle_team` (`desugar_jdk_libs` 2.1.4). Both web builds show "Connected to Appwrite" against the local server; `pubspec.lock` also gains `dart_appwrite` and `sentry`, which were missing.
- Battle Team's web preloader (`web/flutter_bootstrap.js`, from the template) fetches `assets/<path>` where Flutter serves `assets/assets/<path>`: four 404s it ignores before starting the app. Left as it is, outside this session.
