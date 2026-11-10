# Battle Team: work sessions

Battle Team is a 3D, massive, persistent, real-time team battle game. Its rules are in the app repository, `apps/battle_team/plan/`: specs, data, milestones and the stack records. This folder drives the code. **Each file in `sessions/` is one agent work session for one milestone issue.** It ends with one pull request in the package repository and one in hawkbee.

| File | Read it when |
|---|---|
| [agent-workflow.md](agent-workflow.md) | Always. How to read the plan, branch, test, open the PRs and hand off. |
| [playtest.md](playtest.md) | To play a battle yourself: a 1 km map, blue against red, in the app. |
| `apps/battle_team/AGENTS.md` | Always. How the plan works. |
| [sessions/](sessions/) | Your session file, and the "Session log" of the sessions it depends on. |

## How to start a session (for the owner)

Open Claude Code in `/volume/hawkbee` and say:

> Run the Battle Team session `docs/battle_team/sessions/<file>.md`. Follow `docs/battle_team/agent-workflow.md`.

One session per conversation. Review and merge its PRs before starting a session that depends on it.

## Prerequisites (owner)

- [x] Technical stack confirmed (milestone M2, 2026-11-01).
- [x] Empty public repositories `hawkbee1/battle_rules` and `hawkbee1/battle_pathfinding` (2026-11-01).

## Sessions

### M3 and M4 (done)

M3 (pathfinding) and M4 (rules core) do not depend on each other: the path search takes the movement cost as an injected function, and a caller wires M4's into it.

| Session | Issue | Package | Depends on | Status |
|---|---|---|---|---|
| [M4.1](sessions/m4-01-project-scaffold.md) | `battle_rules`: project scaffold | `battle_rules` | prerequisites | merged |
| [M3.1](sessions/m3-01-project-scaffold.md) | `battle_pathfinding`: project scaffold | `battle_pathfinding` | M4.1 (both edit the hawkbee root files) | merged |
| [M4.2](sessions/m4-02-load-and-validate-data.md) | Load and validate the data files | `battle_rules` | M4.1 | merged |
| [M4.3](sessions/m4-03-clock-and-ap-pool.md) | Simulation clock and AP pool | `battle_rules` | M4.2 | merged |
| [M4.4](sessions/m4-04-movement-cost.md) | Movement cost | `battle_rules` | M4.2 | merged |
| [M4.5](sessions/m4-05-vision.md) | Vision | `battle_rules` | M4.2 | merged |
| [M4.6](sessions/m4-06-weapons-and-firing-cycle.md) | Weapons and firing cycle | `battle_rules` | M4.3 | merged |
| [M4.7](sessions/m4-07-hit-chance-and-first-person-shots.md) | Hit chance and first-person shots | `battle_rules` | M4.5, M4.6 | merged |
| [M4.8](sessions/m4-08-damage-friendly-fire-transports.md) | Damage, friendly fire, transports | `battle_rules` | M4.2 | merged |
| [M4.9](sessions/m4-09-morale-and-zero-hp-outcomes.md) | Morale and 0-HP outcomes | `battle_rules` | M4.8 | merged |
| [M4.10](sessions/m4-10-role-actions-pushing-hq-moves.md) | Role actions, pushing, HQ moves, interruption | `battle_rules` | M4.3, M4.4 | merged |
| [M4.11](sessions/m4-11-scenario-harness.md) | Scenario harness | `battle_rules` | M4.3 to M4.10 | merged |
| [M3.2](sessions/m3-02-navigation-model.md) | Navigation model | `battle_pathfinding` | M3.1 | merged |
| [M3.3](sessions/m3-03-paths-for-units-and-path-check.md) | Paths for units, path check | `battle_pathfinding` | M3.2 | merged |
| [M3.4](sessions/m3-04-paths-for-relics-and-hqs.md) | Paths for relics and HQs | `battle_pathfinding` | M3.3 | merged |
| [M3.5](sessions/m3-05-world-changes.md) | World changes | `battle_pathfinding` | M3.3 | merged |
| [M3.6](sessions/m3-06-long-paths-on-big-maps.md) | Long paths on big maps | `battle_pathfinding` | M3.3, M3.5 | merged |

Parallel once their dependencies are merged: **M3 ∥ M4**; **M4.3 ∥ M4.4 ∥ M4.5 ∥ M4.8** after M4.2; **M4.6 ∥ M4.10** after M4.3 and M4.4; **M3.4 ∥ M3.5** after M3.3. Two parallel sessions of one package rebase on `main` before opening their PR.

### M5: simulation host and persistence

Milestone: `apps/battle_team/plan/milestones/m5-simulation-host.md`. Sessions M5.8, M5.9, M5.10 and M5.17 create a package and its public repository (dc3d §2).

| Session | Issue | Package | Depends on | Status |
|---|---|---|---|---|
| [M5.1](sessions/m5-01-effective-stats-and-skill-trees.md) | Effective stats and skill trees | `battle_rules` | M4 (merged) | merged |
| [M5.2](sessions/m5-02-xp-and-commander-level.md) | XP, section XP and commander level | `battle_rules` | M4 (merged) | merged |
| [M5.3](sessions/m5-03-money.md) | Money | `battle_rules` | M5.2 | merged |
| [M5.4](sessions/m5-04-storage-deployment-commander-death.md) | Storage, deployment and the commander's death | `battle_rules` | M5.2, M5.3 | merged |
| [M5.5](sessions/m5-05-relic-ownership-and-victory.md) | Relic ownership and victory | `battle_rules` | M5.4 | merged |
| [M5.6](sessions/m5-06-teams-newcomers-hq-manager.md) | Teams, newcomers and the HQ manager | `battle_rules` | M5.2 | merged |
| [M5.7](sessions/m5-07-wars-sections-guilds.md) | Wars, sections and guilds | `battle_rules` | M5.6 | merged |
| [M5.8](sessions/m5-08-map-format-and-loader.md) | Map format and loader | `battle_map` | M3 (merged) | merged |
| [M5.9](sessions/m5-09-commands-events-battle-log.md) | Commands, events and the battle log | `battle_protocol` | M4 (merged) | merged |
| [M5.10](sessions/m5-10-host-scaffold-battle-state.md) | Host scaffold, battle state and clock | `battle_host` | M5.1, M5.8, M5.9 | merged |
| [M5.11](sessions/m5-11-orders-movement-combat.md) | Orders for movement and combat | `battle_host` | M5.10 | merged |
| [M5.12](sessions/m5-12-orders-storage-money-xp-prisoners.md) | Orders for storage, money, XP and prisoners | `battle_host` | M5.3, M5.4, M5.11 | merged |
| [M5.13](sessions/m5-13-relics-victory-end-of-battle.md) | Relics, victory and the end of a battle | `battle_host` | M5.5, M5.11 | merged |
| [M5.14](sessions/m5-14-world-delta-layer.md) | World delta layer | `battle_host` | M5.11 | merged |
| [M5.15](sessions/m5-15-write-ahead-log-snapshots-recovery.md) | Write-ahead log, snapshots and recovery | `battle_host` | M5.11 | merged |
| [M5.16](sessions/m5-16-server-managed-sections.md) | Server-managed sections | `battle_host` | M5.11 | merged |
| [M5.17](sessions/m5-17-statistics-and-medals.md) | Statistics and medals | `battle_stats` | M5.9 | merged |
| [M5.18](sessions/m5-18-appwrite-data-and-functions.md) | Appwrite data and functions around battles | `backend`, `hawkbee_schema` | M5.7, M5.13 | merged |
| [M5.19](sessions/m5-19-load-test-and-hosting.md) | Load test and hosting | `battle_host` | M5.12 to M5.16 | merged |
| [M5.20](sessions/m5-20-first-map-from-real-data.md) | First map from real data | `battle_map` | M5.8 | merged |
| [M5.21](sessions/m5-21-local-appwrite-deploy.md) | Local Appwrite deployment | `backend`, `hawkbee_schema`, `battle_backend`, `battle_host`, `appwrite_api_client` | M5.19 | merged |

Parallel once their dependencies are merged: **M5.1 ∥ M5.2 ∥ M5.8 ∥ M5.9** at the start; **M5.3 ∥ M5.6** after M5.2; **M5.17** after M5.9 and **M5.20** after M5.8, beside the rest; **M5.12 to M5.16** after M5.11. Sessions that create a package edit the hawkbee root files: rebase on `main` before opening the PR.

### M6: networking

Milestone: `apps/battle_team/plan/milestones/m6-networking.md`. Session M6.7 creates a package and its public repository (dc3d §2).

| Session | Issue | Package | Depends on | Status |
|---|---|---|---|---|
| [M6.1](sessions/m6-01-protocol-spike.md) | Protocol spike, dashwire against M5's protocol | none (`stack/03`) | M5 | merged: option 3 confirmed |
| [M6.2](sessions/m6-02-messages.md) | Messages between the host and its clients | `battle_protocol` | M6.1 | merged |
| [M6.3](sessions/m6-03-fog-of-war.md) | Fog of war per section | `battle_host` | M5 | merged |
| [M6.4](sessions/m6-04-update-stream.md) | The update stream of a section | `battle_host` | M6.2, M6.3 | merged |
| [M6.5](sessions/m6-05-endpoints-and-sign-in.md) | Endpoints and sign-in | `battle_host` | M6.2, M6.4 | merged |
| [M6.6](sessions/m6-06-reaching-a-battle-host.md) | Reaching a battle's host | `battle_host`, `battle_client`, `battle_backend`, `backend`, `hawkbee_schema` | M6.5 | merged |
| [M6.7](sessions/m6-07-client-library.md) | Client library | `battle_client` | M6.2, M6.4 | merged |
| [M6.8](sessions/m6-08-network-load-test.md) | A battle over the network, P-04 | `battle_host`, `battle_client` | M6.5, M6.7 | todo |

Parallel once their dependencies are merged: **M6.1 ∥ M6.3** at the start; **M6.5 ∥ M6.7** after M6.4; **M6.6 ∥ M6.8** at the end.

### M7: client

Milestone: `apps/battle_team/plan/milestones/m7-client.md`. Sessions in the app follow `agent-workflow.md` §6.

| Session | Issue | Package | Depends on | Status |
|---|---|---|---|---|
| [M7.1](sessions/m7-01-normal-launch.md) | Normal launch, from the playtest | `battle_team` | the playtest (merged) | merged |
| [M7.2](sessions/m7-02-test-unit-ap-delay.md) | The test unit and the AP recovery delay | `battle_rules`, `battle_host`, `hawkbee_schema`, `battle_backend`, `battle_team` (data) | none | PR open #72 |
| [M7.3](sessions/m7-03-logging.md) | Logging | `battle_team`, `battle_client`, `appwrite_api_client` | M7.1 | merged |
| [M7.4](sessions/m7-04-view-from-unit.md) | View from a unit | `battle_team` | M7.3 | merged |
| [M7.5](sessions/m7-05-fire.md) | Fire | `battle_team`, `battle_client` | M7.4 | PR open #75 |
| [M7.6](sessions/m7-06-storage.md) | Storage: view, store, unstore | `battle_team`, `battle_client` | M7.5 (stacked; M7.1 needed) | PR open #76 |
| [M7.7](sessions/m7-07-buy.md) | Buy | `battle_protocol`, `battle_host`, `battle_client`, `battle_team` | M7.6 | todo |
| [M7.8](sessions/m7-08-path-preview.md) | Move: path preview and AP cost | `battle_client`, `battle_team` | M7.1 | todo |
| [M7.9](sessions/m7-09-fog-and-alerts.md) | Fog shading and alerts | `battle_protocol`, `battle_host`, `battle_client`, `battle_team` | M7.4 | todo |
| [M7.10](sessions/m7-10-pings-markers-chat.md) | Pings, map markers and team chat | `battle_protocol`, `battle_host`, `battle_client`, `battle_team` | M7.1 | todo |
| [M7.11](sessions/m7-11-unit-filters.md) | Unit filters | `battle_team` | M7.1 | todo |
| [M7.12](sessions/m7-12-accounts.md) | Accounts: sign up, sign in, log out | `battle_team`, `appwrite_api_client` | M7.1 | todo |
| [M7.13](sessions/m7-13-rendering-benchmarks.md) | P-05 and P-06, the rendering benchmarks | `battle_team` | M7.9, the owner's devices | todo |

Parallel once their dependencies are merged: **M7.1 ∥ M7.2** at the start; **M7.6 ∥ M7.8 ∥ M7.10 ∥ M7.11 ∥ M7.12** after M7.1, one at a time in the app to avoid rebases; M7.13 last. M6.8 stays open beside M7.

Status values: `todo` → `in progress` → `PR open #N` → `merged`. The session agent updates its own row.
