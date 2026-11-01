# Battle Team: work sessions

Battle Team is a 3D, massive, persistent, real-time team battle game. Its rules are in the app repository, `apps/battle_team/plan/`: specs, data, milestones and the stack records. This folder drives the code. **Each file in `sessions/` is one agent work session for one milestone issue.** It ends with one pull request in the package repository and one in hawkbee.

| File | Read it when |
|---|---|
| [agent-workflow.md](agent-workflow.md) | Always. How to read the plan, branch, test, open the PRs and hand off. |
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

M3 (pathfinding) and M4 (rules core) do not depend on each other: the path search takes the movement cost as an injected function, and a caller wires M4's into it.

| Session | Issue | Package | Depends on | Status |
|---|---|---|---|---|
| [M4.1](sessions/m4-01-project-scaffold.md) | `battle_rules`: project scaffold | `battle_rules` | prerequisites | merged |
| [M3.1](sessions/m3-01-project-scaffold.md) | `battle_pathfinding`: project scaffold | `battle_pathfinding` | M4.1 (both edit the hawkbee root files) | merged |
| [M4.2](sessions/m4-02-load-and-validate-data.md) | Load and validate the data files | `battle_rules` | M4.1 | PR open #20 |
| [M4.3](sessions/m4-03-clock-and-ap-pool.md) | Simulation clock and AP pool | `battle_rules` | M4.2 | PR open #21 |
| [M4.4](sessions/m4-04-movement-cost.md) | Movement cost | `battle_rules` | M4.2 | PR open #22 |
| [M4.5](sessions/m4-05-vision.md) | Vision | `battle_rules` | M4.2 | PR open #23 |
| [M4.6](sessions/m4-06-weapons-and-firing-cycle.md) | Weapons and firing cycle | `battle_rules` | M4.3 | PR open #25 |
| [M4.7](sessions/m4-07-hit-chance-and-first-person-shots.md) | Hit chance and first-person shots | `battle_rules` | M4.5, M4.6 | todo |
| [M4.8](sessions/m4-08-damage-friendly-fire-transports.md) | Damage, friendly fire, transports | `battle_rules` | M4.2 | PR open #24 |
| [M4.9](sessions/m4-09-morale-and-zero-hp-outcomes.md) | Morale and 0-HP outcomes | `battle_rules` | M4.8 | todo |
| [M4.10](sessions/m4-10-role-actions-pushing-hq-moves.md) | Role actions, pushing, HQ moves, interruption | `battle_rules` | M4.3, M4.4 | in progress |
| [M4.11](sessions/m4-11-scenario-harness.md) | Scenario harness | `battle_rules` | M4.3 to M4.10 | todo |
| [M3.2](sessions/m3-02-navigation-model.md) | Navigation model | `battle_pathfinding` | M3.1 | todo |
| [M3.3](sessions/m3-03-paths-for-units-and-path-check.md) | Paths for units, path check | `battle_pathfinding` | M3.2 | todo |
| [M3.4](sessions/m3-04-paths-for-relics-and-hqs.md) | Paths for relics and HQs | `battle_pathfinding` | M3.3 | todo |
| [M3.5](sessions/m3-05-world-changes.md) | World changes | `battle_pathfinding` | M3.3 | todo |
| [M3.6](sessions/m3-06-long-paths-on-big-maps.md) | Long paths on big maps | `battle_pathfinding` | M3.3, M3.5 | todo |

Parallel once their dependencies are merged: **M3 ∥ M4**; **M4.3 ∥ M4.4 ∥ M4.5 ∥ M4.8** after M4.2; **M4.6 ∥ M4.10** after M4.3 and M4.4; **M3.4 ∥ M3.5** after M3.3. Two parallel sessions of one package rebase on `main` before opening their PR.

Status values: `todo` → `in progress` → `PR open #N` → `merged`. The session agent updates its own row.
