# hawkbee

Flutter apps backed by one Appwrite project, in a Dart/Flutter monorepo managed
with [Melos](https://melos.invertase.dev) and Dart pub workspaces. It follows the
Very Good Ventures layered architecture. See
[docs/project-setup.md](docs/project-setup.md) for the full design.

## Layout

```
apps/hawkbee/                       Flutter app (flavors: development, staging, production)
apps/battle_team/                   Flame game, same flavors, same Appwrite project
packages/
  hawkbee_schema/                   pure Dart · Appwrite resource IDs, row models (shared with functions)
  appwrite_api_client/              Flutter · the only package importing package:appwrite
  backend_status_repository/        repository · "is the backend reachable?"
backend/
  appwrite.config.json              backend as code: database, tables, functions…
  functions/ping/                   Dart function (runtime dart-3.13), health check
env/<flavor>.json                   Appwrite endpoint + project ID per flavor (no secrets)
tool/vendor_schema.dart             copies hawkbee_schema into each function before deploy
```

Add each new app or package to `workspace:` in the root `pubspec.yaml` and give
it `resolution: workspace`. Appwrite Functions are **not** workspace members:
the Appwrite CLI uploads only the function's folder, so each one resolves its
own dependencies and ships a committed copy of `hawkbee_schema` under
`vendor/`.

## Getting started

```sh
dart pub get
```

## Scripts

```sh
dart run melos run analyze            # dart analyze in every workspace package
dart run melos run format             # formatting check
dart run melos run test               # tests in every workspace package

dart run melos run backend:vendor     # refresh functions/*/vendor/hawkbee_schema
dart run melos run backend:vendor:check  # fail if a vendored copy is stale (CI)
dart run melos run backend:analyze    # analyze the functions
dart run melos run backend:test       # test the functions
dart run melos run backend:deploy     # vendor, then `appwrite push all` from backend/
```

After changing `packages/hawkbee_schema`, run `backend:vendor` and commit the
updated `vendor/` folders.

## Connecting to Appwrite and deploying

Prerequisite: the Appwrite CLI (`npm install -g appwrite-cli`).

1. **Create the project.** In the Console, create a project with the custom ID
   `hawkbee`, the ID used by `backend/appwrite.config.json`,
   `env/development.json` and `hawkbee_schema`. If you pick another ID,
   update all three.
2. **Register platforms** (Overview → Add platform), one per flavor:
   - Android: `com.hawkbee.hawkbee` and `com.hawkbee.battle_team`, each also
     with `.dev` and `.stg` suffixes
   - iOS / macOS: the bundle IDs set in Xcode for each flavor
     (`com.hawkbee.hawkbee…`, `com.hawkbee.battle-team…`)
   - Web: `localhost` (and the laptop's LAN IP when testing from phones)
3. **Point the CLI at the server and log in** (from `backend/`):
   ```sh
   cd backend
   appwrite login --endpoint "http://appwrite-traefik/v1"   # from the factory1 container
   appwrite client --project-id hawkbee
   ```
4. **Deploy:** `dart run melos run backend:deploy`, which creates the `hawkbee`
   database and deploys the `ping` function.
5. **Verify the backend:**
   ```sh
   appwrite functions create-execution --function-id ping
   # → responseBody: {"status":"ok","databaseId":"hawkbee"}
   ```
6. **Verify the app:** set `APPWRITE_ENDPOINT` in `env/development.json` for
   the device you run on (see the endpoint table in
   [docs/project-setup.md](docs/project-setup.md#which-appwrite-url-to-use-from-where)),
   then run an app (see [apps/hawkbee/README.md](apps/hawkbee/README.md) and
   [apps/battle_team/README.md](apps/battle_team/README.md)). Hawkbee's home
   screen and Battle Team's title screen show "Connected to Appwrite" or the
   error returned.

For Appwrite Cloud (staging, production), fill in `env/staging.json` and
`env/production.json`, and push the same config with
`appwrite client --endpoint https://<REGION>.cloud.appwrite.io/v1 --project-id <ID>`.
