# Hawkbee — project organisation & local Appwrite setup

Status: draft, 2026-09-25; scaffold created 2026-09-27. Decisions still open are listed in [§9](#9-open-decisions).

Hawkbee is a monorepo of several Flutter apps (some built with Flame) that share
one Appwrite backend. Local development runs against a self-hosted Appwrite in
Docker; staging and production run on Appwrite Cloud. Apps ship to the App Store,
Google Play and possibly Huawei AppGallery.

---

## 1. Machines and networks

| Machine | Role |
|---|---|
| **Linux laptop** (`hawkbee-AORUS-15X`) | Docker host. Runs the local Appwrite and the dev containers. |
| `factory1` container (Docker network `hermes-net`, 172.24.0.5) | Where Claude Code works: Flutter 3.47.1 / Dart 3.13.1, `adb`, Node 22, Very Good CLI. No Docker socket, so it cannot start, stop or upgrade containers. |
| Other containers on `hermes-net` | `hermes`, `factory-agent`, `hermes-playwright-1` (can drive Flutter web builds in end-to-end tests), `hermes-searxng-1`. |
| **Mac** | iOS builds, App Store uploads, debugging on the iPhone. |
| **iPhone 11** | iOS device debugging. |
| Android phone(s) / emulator | Android debugging. |

Keep the **same Flutter version** (currently 3.47.1) on `factory1`, the Mac and CI.
Pin it with [FVM](https://fvm.app) (`.fvmrc` in the repo) or at least in CI.

### Which Appwrite URL to use from where

The app never runs inside `factory1`: it runs on a phone or in a browser. The
same Appwrite server is therefore reached through different addresses:

| Client | Appwrite endpoint |
|---|---|
| Tools in `factory1` (Appwrite CLI, MCP server, scripts) | `http://appwrite-traefik/v1` (via `hermes-net`) |
| Browser on the laptop (Flutter web, Console) | `http://localhost/v1` — Console at `http://localhost` |
| Real phones, the Mac, the iPhone | `http://<LAN_IP>/v1` |
| Android emulator running on the laptop | `http://10.0.2.2/v1` |

`<LAN_IP>` is the laptop's address on your Wi-Fi. Give it a fixed address with
a DHCP reservation on your router, otherwise every env file breaks when it changes.

---

## 2. Repository layout

We follow the **Very Good Ventures (VGV) layered architecture** (see §3), adapted
to host several apps and an Appwrite backend.

```
hawkbee/
├── apps/
│   ├── <game_name>/               # very_good create flame_game
│   └── <app_name>/                # very_good create flutter_app
│       └── lib/
│           ├── app/               # App widget, MultiRepositoryProvider
│           ├── <feature>/
│           │   ├── bloc/ | cubit/ # business logic
│           │   └── view/          # <feature>_page.dart + <feature>_view.dart
│           ├── main_development.dart
│           ├── main_staging.dart
│           └── main_production.dart
├── packages/
│   ├── hawkbee_schema/            # DATA · pure Dart · table/column IDs, row models (fromJson/toJson)
│   ├── appwrite_api_client/       # DATA · Flutter package · wraps the `appwrite` client SDK
│   ├── backend_status_repository/ # REPOSITORY · "is Appwrite reachable?" (first one, scaffold)
│   ├── <domain>_repository/       # REPOSITORY · one package per domain (auth, …)
│   └── hawkbee_ui/                # shared widgets + design tokens (VGV ui-package)
├── backend/
│   ├── appwrite.config.json       # tables, columns, indexes, permissions, buckets, functions
│   └── functions/
│       └── <function_name>/       # Dart runtime (dart-3.13); `ping` is the first one
│           └── vendor/hawkbee_schema/  # committed copy, refreshed by `melos run backend:vendor`
├── env/
│   ├── development.json           # local Appwrite: endpoint + project ID (no secrets)
│   ├── staging.json               # Appwrite Cloud staging project
│   └── production.json            # Appwrite Cloud production project
├── tool/vendor_schema.dart        # copies hawkbee_schema into each function
├── docs/
├── pubspec.yaml                   # melos config + pub workspace (lists every app/package)
└── .claude/                       # Claude Code project settings and skills
```

- Every new app or package is added to `workspace:` in the root `pubspec.yaml`
  and gets `resolution: workspace` in its own `pubspec.yaml`.
- Scaffold with Very Good CLI (`very_good create flutter_app | flame_game |
  dart_package | flutter_package`) so every package starts with VGV lints,
  tests and CI conventions.
- `env/*.json` is passed at build time:
  `flutter run --flavor development -t lib/main_development.dart --dart-define-from-file=../../env/development.json`.
  These files hold only the endpoint and project ID, which are not secrets.
  **API keys never go in the apps or in the repo.**

---

## 3. Architecture rules (VGV)

Four layers. Each layer depends only on the one directly below it.

| Layer | Lives in | Contains | Depends on |
|---|---|---|---|
| Presentation | `apps/*/lib/<feature>/view/` | Pages (provide the Bloc) and Views (render state). Flame `Game`/components live here too. | Business logic |
| Business logic | `apps/*/lib/<feature>/bloc\|cubit/` | All business rules; Bloc/Cubit with sealed states + Equatable | Repositories |
| Repository | `packages/<domain>_repository/` | Domain models, combines/transforms/caches data. No business rules. | Data packages |
| Data | `packages/*_api_client/`, `hawkbee_schema` | Talks to external sources; models mirror the wire format; zero business logic | External packages only |

Rules:

- Apps depend on **repositories only**, never on data packages directly.
- Repositories never import other repositories. Combine them in a Bloc if needed.
- Constructor injection everywhere. `main_<flavor>.dart` builds clients →
  repositories → `App(...)`.
- Local packages use `path:` dependencies. Each package exposes one barrel
  file, and nobody imports its `src/` folder.
- Lints come from `very_good_analysis`. The target is 100% test coverage
  (use the `green-gate` skill to drive analyze/format/test/coverage to green).
- **Flame:** a game is presentation. Game state that matters (progress, scores,
  inventory, settings) is held in Blocs (`flame_bloc`) and persisted through
  repositories, never by calling Appwrite from a component.

### Deviations for Appwrite (pending approval)

1. **`appwrite_api_client` is a Flutter package.** VGV wants data packages in
   pure Dart, but the Appwrite *client* SDK depends on Flutter. The server SDK
   (`dart_appwrite`) is pure Dart but uses API keys, so it must **never** ship in
   an app. We accept the exception and keep it contained to this one package.
2. **`hawkbee_schema` is pure Dart** so the row models and IDs can be shared by
   the apps (through `appwrite_api_client`) and by Appwrite Functions.
3. **Functions cannot use `path:` dependencies** that leave their folder. The
   Appwrite CLI uploads only the function's own folder. `melos run backend:vendor`
   copies `hawkbee_schema` into `backend/functions/<name>/vendor/` and the function
   depends on it with `path: vendor/hawkbee_schema`. The copy is **committed**, not
   git-ignored, because the CLI reads `.gitignore` when packaging a function and
   would silently drop it. `backend:vendor:check` catches a stale copy.
   Functions are therefore not pub workspace members.
4. **Repositories that use `appwrite_api_client` are Flutter packages too.** A
   package that depends on a Flutter package needs the Flutter SDK and
   `flutter_test`, even if its own code is plain Dart. They still import
   nothing from Flutter and never import `package:appwrite`.
5. **Build Appwrite `Client` after `WidgetsFlutterBinding.ensureInitialized()`.**
   Its constructor reads the documents directory through `path_provider`.
   `bootstrap.dart` does this before building the clients.

---

## 4. Backend as code

- The whole backend definition lives in `backend/appwrite.config.json`: databases,
  tables/columns/indexes (Appwrite's current model, formerly collections and
  documents), permissions, buckets, functions and messaging topics.
- `appwrite push` applies it to the selected project (local, Cloud staging, Cloud
  production). `appwrite pull` goes the other way after you experiment in the Console.
- **Old app versions stay installed for a long time**, and several apps share one
  database. Schema changes must be **additive**:
  - add optional columns;
  - never rename or delete a column that a shipped app still reads;
  - remove a column only after every app that uses it has dropped below the
    minimum supported version.
  Each app checks a "minimum supported version" setting at startup.
- **Permissions are the security layer**, because apps query the database
  directly. Use row-level permissions and teams. Put any logic that must be
  trusted in Functions.
- Keep the local Appwrite on the **same version as Appwrite Cloud** (2.3.0 as of
  2026-09-23) and the SDK versions matched to it.

---

## 5. Running and debugging

| Target | How |
|---|---|
| **Browser** | In `factory1`: `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 …`, then open `http://localhost:8080` on the laptop. This needs port 8080 published on `factory1`, which isn't set up yet. Register `localhost` as a Web platform in the Appwrite project. |
| **Android phone** | Enable Wireless debugging, then from `factory1`: `adb pair <phone-ip>:<pair-port>` and `adb connect <phone-ip>:<port>` (mDNS discovery doesn't work inside the container, so use explicit IPs). Alternatively, use the laptop's adb server: `ADB_SERVER_SOCKET=tcp:host.docker.internal:5037`. The `watch-debug-session` skill can then follow the logs while you use the app. |
| **iPhone 11** | On the Mac with Xcode: `flutter run --flavor development …` on the device. Endpoint `http://<LAN_IP>/v1`. |
| **Hot reload from Claude** | The Dart MCP server connects to a running debug app, so Claude can hot reload, read runtime errors and inspect the widget tree. |

Local Appwrite is plain HTTP, so the **development flavor only** needs:

- **Android:** `android:usesCleartextTraffic="true"` in the development/debug
  `AndroidManifest.xml`.
- **iOS:** `NSAppTransportSecurity › NSAllowsLocalNetworking = YES` and an
  `NSLocalNetworkUsageDescription` string. iOS asks the user for Local Network
  permission the first time the app reaches a LAN address. The flavors share
  one `Info.plist`, so these keys are in every flavor. That's harmless: they
  only allow plain HTTP to local addresses, and production never contacts one.

Done in the scaffold: `android/app/src/development/AndroidManifest.xml`,
`ios/Runner/Info.plist`, the `INTERNET` permission in the main Android manifest
(release builds need it), and `network.client` in the macOS entitlements.

Register one Appwrite **platform per app per flavor**: Android package name, iOS
bundle ID, and Web hostnames `localhost` and `<LAN_IP>`.

---

## 6. Fresh install of the local Appwrite (2.3.0) on `hermes-net`

Run all of this **on the laptop** (the Docker host), not in `factory1`.

### 6.1 Remove the old install

The new stack reuses the same network names (`appwrite`, `gateway`, `runtimes`).
If the new folder is also called `appwrite`, it also reuses the same volume
names (`appwrite_appwrite-uploads`, `appwrite_appwrite-config`, …). An old
network or volume left behind would either block the new stack or feed it stale data.

```bash
cd ~/<old-appwrite-folder>
# optional: back up anything you want to keep first
docker compose down -v      # stops the stack AND deletes its volumes (irreversible)
docker network ls | grep -E 'appwrite|gateway|runtimes'   # remove leftovers with: docker network rm <name>
docker volume ls | grep appwrite                         # remove leftovers with: docker volume rm <name>
```

### 6.2 Create the folder

```
~/appwrite/
├── docker-compose.yml            # the official 2.3.0 file, unchanged
├── .env                          # from env.txt, corrected (6.3)
└── docker-compose.override.yml   # our additions (6.4)
```

Leave `docker-compose.yml` untouched: Appwrite's `upgrade` command overwrites it.
Docker Compose loads `docker-compose.override.yml` automatically, so our
changes survive upgrades.

> **Alternative:** the official installer generates `docker-compose.yml` and a
> production `.env` with random secrets for you:
> ```bash
> docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock \
>   -v "$(pwd)"/appwrite:/usr/src/code/appwrite:rw --entrypoint="install" appwrite/appwrite:2.3.0
> ```
> If you use it, stop the stack afterwards, apply only 6.3's hostname, runtime and
> SMTP settings, add the override from 6.4, and start it again.

### 6.3 Fix the `.env`

The `env.txt` provided is Appwrite's **development sample**, not a
production-ready file. Change at least these values:

| Variable | Sample value | Set to | Why |
|---|---|---|---|
| `_APP_ENV` | `development` | `production` | Behave like Appwrite Cloud. Development mode is for people working on Appwrite itself. |
| `_APP_OPENSSL_KEY_V1` | `your-secret-key` | `openssl rand -hex 32` | Encrypts stored data. **Never change it after the first start.** |
| `_APP_EXECUTOR_SECRET`, `_APP_JOBS_SECRET`, `_APP_GEO_SECRET`, `_APP_NOTIFICATIONS_TRACKING_SECRET` | `your-secret-key` | a different `openssl rand -hex 32` each | Internal authentication between services |
| `_APP_DB_PASS`, `_APP_DB_ROOT_PASS` | `password`, `rootsecretpassword` | random | PostgreSQL credentials |
| `_APP_USAGE_PASS` | `appwrite` | random, **and** update the password inside `_APP_CONNECTIONS_DB_USAGE` and `_APP_CONNECTIONS_DB_EXECUTIONS` (`http://appwrite:<pass>@clickhouse:8123/appwrite`) | ClickHouse credentials |
| `_APP_DOMAIN` | `appwrite.test` | `<LAN_IP>` | The address phones and the Mac use. The Console is also served on it. |
| `_APP_CONSOLE_DOMAIN` | `localhost` | keep | Console at `http://localhost` on the laptop |
| `_APP_CONSOLE_HOSTNAMES` | `localhost,appwrite.io,*.appwrite.io` | `localhost,<LAN_IP>` | Don't trust appwrite.io hostnames on a local server |
| `_APP_CONSOLE_TRUSTED_PROJECTS` | `trusted-project,another-trusted-project` | *(empty)* | Test fixtures |
| `_APP_CONSOLE_WHITELIST_ROOT` | `disabled` | `enabled` | Only the first account can sign up to the Console |
| `_APP_DNS` | `172.16.238.100` | `1.1.1.1` | The sample points at a DNS server on Appwrite's test network |
| `_APP_DOMAIN_TARGET_A` | `203.0.0.1` | `<LAN_IP>` | |
| `_APP_DOMAIN_SITES` | `sites.localhost,rebranded.localhost` | `sites.localhost` | |
| `_APP_FUNCTIONS_RUNTIMES` | `node-22` | `node-22,dart-3.13` | Dart functions (3.13 matches our SDK) |
| `_APP_EXECUTOR_IMAGES` | `openruntimes/node:v5-22,openruntimes/static:v5-1` | `openruntimes/node:v5-22,openruntimes/dart:v5-3.13,openruntimes/static:v5-1` | Pre-pull the Dart runtime image |
| `_APP_ASSISTANT_OPENAI_API_KEY` | `your-openai-api-key` | *(empty)* | Only needed for the Console AI assistant |
| `_APP_SMTP_HOST` / `_APP_SMTP_PORT` | `maildev` / `1025` | keep | Served by the maildev container added in 6.4 |
| `_APP_SYSTEM_EMAIL_ADDRESS` | `noreply@appwrite.io` | e.g. `noreply@hawkbee.local` | |

If ports 80, 443, 8883 or 8084 are already used on the laptop, add
`_APP_HTTP_PORT=…`, `_APP_HTTPS_PORT=…`, `_APP_MQTT_PORT=…`, `_APP_MQTT_WSS_PORT=…`.
Every endpoint in §1 then needs that port too.

Keep `.env` out of git. It holds every secret of the local stack.

### 6.4 `docker-compose.override.yml`

```yaml
services:
  # Put the router (not the internals) on hermes-net so factory1 can reach the API.
  traefik:
    networks:
      - hermes-net

  # Function containers are started on the `runtimes` network
  # (_APP_COMPUTE_RUNTIMES_NETWORK), but the official file only puts the executor
  # on `appwrite`. Attach it to `runtimes` too, so it can reach them while
  # functions stay isolated from the database and Redis.
  openruntimes-executor:
    networks:
      - runtimes

  # Local mail catcher for verification emails, magic links, password resets.
  # Web UI: http://localhost:1080. On hermes-net so Claude can read emails
  # through its REST API in automated tests.
  maildev:
    image: maildev/maildev:2.1.0
    container_name: appwrite-maildev
    restart: unless-stopped
    ports:
      - "1080:1080"
    networks:
      - appwrite
      - hermes-net

  # Optional: read-only database access for debugging from factory1.
  # Never write to the database directly: it bypasses Appwrite's permissions and cache.
  # postgresql:
  #   networks:
  #     - hermes-net

networks:
  hermes-net:
    external: true
```

Only `appwrite-traefik` and `appwrite-maildev` join `hermes-net`. Appwrite's
internal service names (`redis`, `postgresql`, `clickhouse`, `orchestrator`)
therefore can't clash with other stacks on that network, and function code can't
reach `factory1`.

### 6.5 Start and verify

```bash
cd ~/appwrite
docker compose config --quiet && docker compose up -d
docker compose ps                                   # all services healthy / running
curl -s http://localhost/v1/health/version          # {"version":"2.3.0"}
```

From `factory1` (Claude can run this):

```bash
curl -s http://appwrite-traefik/v1/health/version   # {"version":"2.3.0"}
```

Then:

1. Open `http://localhost` and create the root Console account.
2. Create the project `hawkbee` and note its **project ID**.
3. Add the platforms (§5).
4. Create an **API key** for tooling, with database, users, teams, storage and
   functions scopes. Give it to Claude so it can wire up the local Appwrite MCP
   server and CLI. The key is stored in local user config, never in the repo.
5. Deploy a trivial Dart function and execute it. This confirms the executor ↔
   `runtimes` network fix from 6.4.

### 6.6 Upgrading later

```bash
cd ~                                        # the folder that contains appwrite/
# back up the volumes first; upgrade one minor version at a time
docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)"/appwrite:/usr/src/code/appwrite:rw --entrypoint="upgrade" appwrite/appwrite:<version>
cd appwrite && docker compose exec appwrite migrate
```

`docker-compose.override.yml` is kept across upgrades. Re-check it against the
new official file anyway, since service names can change between releases.

---

## 7. Appwrite Cloud (staging and production)

- One Cloud project per environment (`hawkbee-staging`, `hawkbee-production`),
  in the region closest to your users.
- The same `backend/appwrite.config.json` is pushed to each project with the CLI.
- Each project gets its own platforms (production package names and bundle IDs)
  and its own API keys.

---

## 8. AI tooling in `factory1`

| Tool | Provides |
|---|---|
| `vgv-ai-flutter-plugin` | VGV skills (layered architecture, bloc, testing, theming, navigation, i18n, security, accessibility, green-gate…), a Flutter reviewer agent, automatic `dart analyze`/`dart format` after every edit, the Dart MCP server (hot reload, runtime errors, widget inspector) and the Very Good CLI MCP server (scaffolding, tests) |
| `vgv-wingspan` | `/brainstorm`, `/plan`, `/build`, `/review`, `/hotfix`, `/create-pr`, `/debrief` workflows plus architecture and test-quality reviewers; Context7 MCP for up-to-date library documentation (including Flame) |
| `appwrite` plugin | Appwrite skills for the Dart SDK and CLI; hosted Appwrite MCP server for **Appwrite Cloud**. Run `/mcp` → appwrite once to log in. |
| Local Appwrite MCP *(todo)* | `uvx mcp-server-appwrite` with the local endpoint, project ID and API key, registered with `--scope local` so the key stays out of git. Needs `uv` in `factory1`. |

Node 22 was installed by hand in `factory1` (`/usr/local`). Add it to that
container's image so it survives rebuilds.

---

## 9. Open decisions

- [ ] Approve the Appwrite deviations from VGV (§3).
- [ ] App names and bundle ID / package name prefix. The scaffold uses app `hawkbee`
      with org `com.hawkbee` (Android `com.hawkbee.hawkbee` + `.dev` / `.stg`). Rename
      before the first store upload if needed.
- [ ] The laptop's fixed `<LAN_IP>`, and whether ports 80/443/8883/8084 are free on the laptop.
- [ ] Publish a port (e.g. 8080) on `factory1` for Flutter web debugging.
- [ ] Appwrite Cloud region and organisation.
- [ ] Huawei: needs a separate build without Google services (push through HMS
      Push Kit, no Google Sign-In or Maps). Decide once it's actually planned.
