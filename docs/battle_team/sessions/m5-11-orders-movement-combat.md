# Session M5.11: Orders for movement and combat

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 11. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m5-11-orders` · **Depends on:** M5.10.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/07-engineering-principles.md` (Facade, Chain of Responsibility, Decorator); `plan/stack/08-workload-placement.md` (path check, first-person shots, client trust); `plan/specs/80-ai-and-automation.md`; the session logs of M3.3, M4.3 to M4.10 and M4.11 ("Deferred to M5").

## Notes
- Every order of the M4 rules goes through the one handler; tests drive the handler, not the rules directly.
- Re-check at the end of an AP wait (deferred from M4.11): a waiting order keeps its command and runs the checks again at `at`.
- Merge the three refusal enums into one sealed type in `battle_rules` (on the same branch name there) or wrap them in the host: say which in the session log.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m5-simulation-host.md, Issue 11).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02 to 2026-11-04), after M5.9 and M5.10 were merged:
- **`battle_host`**:
  - `lib/src/orders/`: `CommandHandler` carries out every order of the M4 rules on the battle state; `order_chain.dart` holds the links (`SenderCheck`, `RightCheck`, `RulesCheck`, `ApCheck`, Chain of Responsibility) and the sealed `OrderPlan` (refused, waits until a time, ready); `refusal.dart` the sealed `OrderRefusal` (`RateRefused`, `SenderRefused`, `RightRefused`, `RuleRefused`, `ApRefused`) with its `CheckLink` and wire code; `command_sinks.dart` the `CommandSink` port, `BattleCommands` (Facade: origin tagging, sequence numbers, logging, Decorator) and `RateLimitedCommands` (Decorator); `rate_limit.dart` a token bucket per sender; `world.dart` the map geometry (cell under a position, sight lines, first obstacle of a first-person shot).
  - `lib/src/ports/log_sink.dart`: `LogSink` and `MemoryLogSink`.
  - `SimulationHost.submit(battleId, command, origin:)` is the one entry; `Battle` gains the timers `RunOrder` (an order that waited for AP is checked again on the state at the end of its wait), `WorkEnds` and `FlightEnds`.
  - `SectionSetup.medals` and `UnitSetup.weapon`; `TeamSetup` no longer names a manager.
- **`battle_rules`**: `TeamRules.afterLogIn` (HQ-07, decision 220). `hqManager` draws only on an exact tie, so it uses the random only then. Q-SOC-18 citations now cite decision 221.
- **`battle_protocol`**: the order `EnterBattle`, sent by the server when a player logs in to the battle, with its v1 samples. `ManagerChanged` covers logins too.
- **`battle_team`**: decisions 220 (HQ manager at login, Q-HQ-11) and 221 (guild levels, Q-SOC-18); Q-HQ-12, since answered by decision 227; HQ-07, HQ-08, SOC-29, SOC-47, R-07, M5 Issues 6 and 11; P-02 records that the map's memory is left to a later optimisation.

Checks: analyze `--fatal-infos` and format clean; tests pass with 100 % coverage: `battle_host` 110, `battle_rules` 615, `battle_protocol` 582.

Choices:
- The three refusal enums of M4 are **wrapped** in the host's sealed `OrderRefusal`, not merged in `battle_rules`, so the rules core stays usable alone. The host's own reasons are `HostRule`.
- Orders of later sessions (storage, purchases, transfers, offers, delegation) are refused at the rules link with `not_available_yet`.
- The rate limit does not apply to the server's own commands (logins, server-managed sections): it stops floods from players and AI agents (AI-03).
- A first-person shot leaves from the middle of the shooter's hit volume. A carried unit is no target of its own: it takes its share of its transport's hits (COMBAT-54).
- The explosive charge goes off on a point within its range that its engineer sees; only artillery uses the section's sight and the scouts' reports (COMBAT-12, decision 152).
- A unit reaches one cell around it (1.5 cells) to heal, repair, embark or build: no rule gives this distance.
- An encampment refuses a goal or a client path on a floating island (MAP-38). On the valley map the reinforced bridge to `sky` is too steep for every ground class anyway.
- A command whose plan waits is logged with `OrderDelayed`. Its outcome is logged when the wait ends, as an entry without a command.

Questions raised: Q-HQ-12 (does a player who logs in take the role from a delegated manager; who keeps it on an exact tie), answered by the owner: decision 227. A player who logs in is compared with the team's holder of the role by rank (`TeamState.holderAccountId`), the player who would manage the HQ had nobody delegated it; an exact tie is drawn (decision 211). Delegation changes the manager only.
