---
name: appwrite-local
description: Read and change the local Appwrite server (2.7.1, project and database `hawkbee`) that Hawkbee and Battle Team use in development — tables and rows, users and labels, function runs and their logs, deployments, buckets and files, health — and push `backend/appwrite.config.json` to it. Runs on Sonnet in its own sub-agent and reports back. Use it whenever a task needs to look at or change something on the dev backend, such as "what's in bt_wars", "give toto btadmin", "run bt_create_war as blue", "why did that execution fail", "is Appwrite up", "push the tables", even when Appwrite is not named. Not for Appwrite Cloud (staging, production).
argument-hint: <what to read or change on the local Appwrite>
model: sonnet
context: fork
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/aw.sh *), Bash(${CLAUDE_SKILL_DIR}/scripts/schema_drift.sh *), Bash(jq *)
---

# Local Appwrite

Your task: $ARGUMENTS

You work in the dev container `factory1` against the owner's local Appwrite
**2.7.1**: endpoint `http://appwrite-traefik/v1`, project `hawkbee`, one
database `hawkbee`. Do the task, then end with the report in §6. Whoever
called you sees only that report, not your tool output.

## 1. Rules

- **Local server only.** There is no key for Appwrite Cloud (the staging and
  production endpoints in `env/*.json`). If the task needs Cloud, stop and say so.
- **The key never shows.** `aw.sh` reads `LOCAL_TOOLING_API_KEY` from
  `/volume/soul/dockers/appwrite/appwrite-local.env` by itself. Never `cat`,
  `source`, `grep` or `echo` that file or the key, never put the key on a
  command line, and never write it or a JWT into the repo or your report. The
  CLI's `~/.appwrite/prefs.json` is off limits too.
- **Read freely, write only what the task asks.** Each write must be one the
  task names. Delete rows, users, files, deployments or executions only when
  the task names that exact thing. When unsure, do not write: say in the
  report what you would do.
- **The schema is code.** Tables, columns, indexes, buckets, functions,
  permissions and project settings live in `backend/appwrite.config.json` and
  reach the server through `appwrite push` (§5). Never create, change or delete
  them through the API. Schema changes are additive only: add optional columns,
  never rename or delete one (`docs/project-setup.md` §4).
- **Users.** `toto` (label `btadmin`) is the owner's account: read it, change
  its labels only when asked, never delete it or touch its password or
  sessions. `bt-blue` and `bt-red` are the playtest accounts that
  `packages/battle_host/tool/playtest.dart` recreates on each run.
- **If the server does not answer**, the stack is down on the owner's laptop.
  You cannot start it (no Docker socket) or read its container logs. Do not try
  `localhost` or other hosts; report it.

## 2. The helper

`aw.sh` below means `${CLAUDE_SKILL_DIR}/scripts/aw.sh`. Always call it by that
full path, not through a variable, so its permission applies.

```
aw.sh [--as <userId>] [-q '<query json>']... [-o <file>] <METHOD> <path> [<json body>]
```

- `<path>` is relative to `/v1`: `aw.sh GET /tablesdb/hawkbee/tables`.
- stdout is the JSON answer, with `password`, `hash`, `secret`, `jwt` and
  provider tokens replaced by `"<redacted>"`. stderr gets `HTTP <code>`. The
  exit code is 1 for 400 and above. On an error, read Appwrite's `message` and
  `type`: they name the problem (unknown column, missing scope, bad query).
- A wrong path answers an HTML page; the helper prints one line with its
  error type (`general_route_not_found`) instead.
- Pipe into `jq` to keep only what you need:
  `| jq -c '.rows[] | {id: ."$id", status}'`. Lists answer
  `{"total": n, "<items>": [...]}`, 25 items unless you add a `limit`.
- `-q` adds one query; repeat it for more (§3).
- `--as <userId>` calls with a 15-minute JWT of that user instead of the key:
  the call gets that user's rights, and functions see the user as the caller.
  Use it to check what a player may read or write, and to run functions that
  act for a player (§4).
- `-o <file>` saves the answer to a file, for downloads. Use your scratchpad
  directory, never the repo.

## 3. Queries

One JSON object per `-q`:

```
-q '{"method":"equal","attribute":"status","values":["running"]}'
-q '{"method":"contains","attribute":"labels","values":["btadmin"]}'
-q '{"method":"orderDesc","attribute":"$createdAt"}'
-q '{"method":"limit","values":[100]}'
-q '{"method":"select","values":["$id","name"]}'
```

Other methods: `notEqual`, `lessThan`, `lessThanEqual`, `greaterThan`,
`greaterThanEqual`, `between` (two values), `isNull`, `isNotNull`,
`startsWith`, `endsWith`, `search` (needs a fulltext index), `orderAsc`,
`offset`, `cursorAfter`. `select` works on rows only. Column names come from
`backend/appwrite.config.json` or `GET /tablesdb/hawkbee/tables/<table>/columns`;
`packages/hawkbee_schema/lib/src/appwrite_ids.dart` holds the IDs the code uses.

## 4. Recipes

`R` is `/tablesdb/hawkbee/tables/<table>/rows`.

| Task | Call |
|---|---|
| Server up, version | `GET /health/version`, `GET /health`, `GET /health/db` |
| Tables (with columns and indexes) | `GET /tablesdb/hawkbee/tables` |
| One table's columns, indexes | `GET /tablesdb/hawkbee/tables/<table>/columns`, `…/indexes` |
| Rows | `GET R` with queries |
| One row | `GET R/<rowId>` |
| Add a row | `POST R '{"rowId":"unique()","data":{…}}'`, plus `"permissions":["read(\"user:<id>\")"]` when needed |
| Change some columns | `PATCH R/<rowId> '{"data":{…}}'` |
| Delete a row | `DELETE R/<rowId>` |
| Users | `GET /users`, with `-q` on `email`, `name` or `labels` |
| One user, prefs, sessions | `GET /users/<id>`, `…/prefs`, `…/sessions` |
| Set labels | `PUT /users/<id>/labels '{"labels":["btadmin"]}'` |
| What a user sees | `--as <id> GET /account`, `--as <id> GET R` |
| Functions | `GET /functions`, `GET /functions/<id>` |
| Builds | `GET /functions/<id>/deployments` with `orderDesc $createdAt`: `status` (`ready`, `building`, `failed`) and `buildLogs` |
| Run a function | `POST /functions/<id>/executions '{"body":"…","async":false,"method":"POST","path":"/"}'` |
| Past runs | `GET /functions/<id>/executions` with `orderDesc $createdAt` and a `limit` |
| One run's logs | `GET /functions/<id>/executions/<executionId>` (with the key) |
| Buckets, files | `GET /storage/buckets`, `GET /storage/buckets/<bucket>/files` |
| Download a file | `-o <file> GET /storage/buckets/<bucket>/files/<fileId>/download` |

Things that trip people up:

- **The key bypasses permissions.** A row you can read with the key may be
  hidden from a player. Check with `--as`.
- **Labels are replaced, not merged.** `PUT …/labels` sets the whole list: read
  the user's current labels first and send them back with your change. Labels
  are letters and digits only.
- **An execution's `body` is a string.** JSON inside it is escaped:
  `'{"body":"{\"action\":\"create\"}","async":false}'`. The answer has
  `status`, `responseStatusCode`, `responseBody`, `logs`, `errors` and
  `duration`.
- **Battle Team functions need a caller.** They read the user from the
  `x-appwrite-user-id` header that Appwrite sets for a signed-in call. With the
  key there is none, and they answer `not_signed_in` (401). Run them with
  `--as <userId>`. Admin actions also need the label `btadmin`, or they answer
  `not_admin` (403).
- **A user's run hides its logs.** After a run with `--as`, `logs` and
  `errors` come back empty. Read them with the key:
  `GET /functions/<id>/executions/<executionId>`.
- **Function IDs and folders differ.** The `path` of each function in
  `backend/appwrite.config.json` maps its ID to its folder: `bt_create_war` →
  `backend/functions/create_war`. The shared request handling is in
  `packages/battle_backend`.
- **Battle files are gzip.** `bt_battle_logs` (`.btlg.gz`) and
  `bt_battle_snapshots` (`.btsn.gz`): `gunzip -c <file>`.
- For a route not listed here, the REST path follows the server SDK method
  (`tablesDB.listRows` → `GET /tablesdb/{databaseId}/tables/{tableId}/rows`).
  The `appwrite:dart` and `appwrite:cli` skills, and `appwrite <service>
  --help` run in `backend/`, list the methods and their parameters.

## 5. Pushing `backend/appwrite.config.json`

Push only when the task asks for it, and only the kind of resource it names.
Run the CLI from `backend/`: it reads the project and endpoint from the
config, and its key is already stored. If it says the project is not set, you
are not in `backend/`. If it says the key is missing, stop and report; the
owner sets it up.

1. **Check the drift first** (tables and buckets):
   `${CLAUDE_SKILL_DIR}/scripts/schema_drift.sh`. It lists what the push would
   add, delete (`DELETE`) or recreate (`RETYPE`). `--force` skips the CLI's
   confirmations, so if the check exits 1, do not push: report the `DELETE`
   and `RETYPE` lines.
2. Push:

   | What | Command (in `backend/`) |
   |---|---|
   | Tables, columns, indexes | `appwrite push table --all --force` |
   | Buckets | `appwrite push bucket --all --force` |
   | One function | `dart run tool/vendor_packages.dart` in the repo root first, then `appwrite push function --function-id <id> --force` |
   | Everything | `melos run backend:deploy`, only when the task asks for a full deploy |

3. **Confirm on the server.** Run the drift check again: it should say
   `no difference`. New columns must reach `"status":"available"`. A function's
   newest deployment must reach `ready` (a build takes about a minute; check
   `buildLogs` if it is `failed`), then run it once if that is safe (`ping`
   always is: it answers `{"status":"ok","databaseId":"hawkbee"}`).

The live test suites (`dart test --tags appwrite --run-skipped test/live`) need
the owner's permission for each run. They are not part of this skill.

## 6. Report

End with a short report:

- The answer first, in a few lines. Quote IDs and values; for a long list,
  give the count and the items that matter.
- Each write you made: method, path, HTTP code, and the ID it created or
  changed.
- What you did not do and why: it needs Cloud, the owner, a delete the task did
  not name, or a schema change.
- Never a key, JWT, password hash or session secret.
