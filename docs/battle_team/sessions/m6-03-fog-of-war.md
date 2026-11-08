# Session M6.3: Fog of war per section

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 3. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_host` (`hawkbee1/battle_host`) · **Branch:** `bt/m6-03-fog` · **Depends on:** M5 (M5.19 #57, M5.21 #58); not on M6.1.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/10-map-and-terrain.md` section 5 (vision); UNIT-34, UNIT-36, HQ-29, COMBAT-11, COMBAT-12; decisions 21, 59, 184; MAP-49 (decision 232); `plan/stack/01-simulation-host.md` (tick, load); the session logs of M4.5 (vision), M5.1 (effective stats), M5.11 (scouts' reports for artillery, sight lines) and M5.19 (load test).
**Measure** with `battle_host/bin/load_test.dart`, AOT.

## Notes
- The visible sets are derived state: not in the log, not in the snapshot. A recovered host recomputes them.
- Keep the cost in check with a spatial index of the units (a grid by vision range), and re-check only pairs where an observer or a target moved, appeared, or changed its sight (observe, weather). Report peak and average per tick at 1,000 units in P-02.
- Factor the scouts' reports of COMBAT-12 (M5.11) and the radio relay into one computation; artillery keeps firing at what it fired at before.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m6-networking.md, Issue 3).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-08), stacked on M5.21 (`bt/appwrite-prefix`, hawkbee #58) and the M6 plan (`bt/m6-plan`, hawkbee #59), none merged yet:
- **`battle_host`**:
  - `lib/src/fog/fog_of_war.dart`: `FogOfWar` (on `CommandHandler.fog`) and `SectionSight` (`units`, `hqs`, `relics`). `of(section)` gives what a section knows: its own units wherever they are; the units on the field of other sections, allies included, that one of its units sees; the enemies and enemy HQs its team's reporting scouts see; its own HQ; every relic (MAP-29, MAP-49, decisions 21, 232). `reportingScouts(team)`, the scouts within the relay range of a radio of the team, is the one computation of the relay: the fog uses it, and so does artillery (COMBAT-12, `_fireAt`). `seesGround` is artillery's sight of a position.
  - `sync()` keeps, per unit, a key of what its sight depends on (cell on the field, flying, section, effective vision range, observe bonus, hit volume height), the pairs it sees and the units that see it, and a grid of squares as wide as the greatest base reach. A sync checks again only the units whose key changed (moved, appeared, left the field, observe started or ended, changed section), those within reach of the cells a world change touched (`BattleWorld.takeTouched`), and every unit when the weather changes; an HQ that moves or is eliminated is checked again by the units around it. A section's set is rebuilt only when one of its inputs changed. A sync with the same state returns at once unless an observation starts or ends meanwhile.
  - `SimulationHost.advance({see = true})` runs `see()` after the battles advance: every battle's fog is synced once per tick. The sets are derived state: neither logged nor in the snapshot.
  - `World.sightLine` takes `fromHeightM` and `toHeightM`: a line runs from the top of the observer's hit volume to the top of the target's; where the ground in between rises above it, it carries a `GroundObstacle` (MAP-26). Shots (`_aim`) use the same line, so a unit never fires at what its fog says it does not see.
  - `BattleLoad` and `bin/load_test.dart` time the fog apart (`bench=host_fog`).
  - Tests: `test/src/fog/fog_of_war_test.dart` on a new 800 × 200 m test map (`test/helpers/plain.dart`: a wood, a 20 m grass ridge, a building), with a randomised run that checks the kept sets against a fresh fog after every step.
- **`battle_rules`**: `GroundObstacle`, a sight obstacle that always blocks (MAP-26).
- **`battle_team`**: P-02 and `stack/01` (fog cost); Q-MAP-25 assumed.

Checks: analyze `--fatal-infos` and format clean; tests pass with 100 % line coverage, test optimization off: `battle_host` 318, `battle_rules` 630.

Numbers (P-02, `load_test` AOT on `saint_lo`, 1,000 units, one simulated day): the fog costs **1.3 s of one core per day**; per tick 15 µs on average, 0.43 ms at p99, 1.0 ms at p99.9, **22 ms at the busiest tick** after the first (4 s in, the opening burst); 402,000 sight lines checked. The first tick computes every set: 0.35 s (the same after a recovery). The hill check on shots makes the host's own work about 5 % dearer: 4.0 s a day against 3.8 s for M5.19's code run again on the same machine (busiest second 231 ms against 227 ms there).

Choices:
- A radio of **any section** of the team relays (UNIT-36, `shares_with: all_sections_of_team`); M5.11's artillery check took only the artillery's own section's radios. Scouts report enemies only (UNIT-34): an allied unit is known only through the section's own sight (decision 21).
- Artillery keeps its own-section sight of the position as in M5.11, from every unit on the field, carried ones included.
- A moving unit is seen at the cell the host holds for it, its destination, as shots already treat it (M5.11).

Question raised, with an assumed answer (`95-open-questions.md`): **Q-MAP-25** sight line heights (top of the hit volumes; the ground blocks where it rises above the line) and carried units (they see from their transport and are not seen on their own, COMBAT-54).
