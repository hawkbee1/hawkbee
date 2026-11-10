# Session M7.2: The test unit and the AP recovery delay

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 2. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `packages/battle_rules`, `packages/battle_host`, `apps/battle_team` (`plan/data` only) · **Branch:** `bt/m7-02-test-unit` · **Depends on:** nothing in M7 (runs beside M7.1); the plan PRs for `battle.yaml` (`agent-workflow.md` §6, last paragraph).
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): decisions 167, 168, 172, 238, 239 in `plan/specs/00-overview.md`; COMBAT-01, COMBAT-02, COMBAT-06, MAP-20, UNIT-38, UNIT-44, Q-UNIT-26; `plan/data/battle.yaml` (`ap:`), `plan/data/units.yaml` (`common_stats`, the roster entries, their comments); `plan/stack/01-simulation-host.md` (lazy AP); the session logs of M4.2 (data loading and validation), M4.3 (AP pool), M5.12 (buying), M5.19 (`tool/playtest.dart`).

## What exists
- `battle_rules` loads `battle.yaml` and `units.yaml` (M4.2) and validates them; the AP pool (M4.3) recovers with `recovery_per_hour`; the host's `SectionOrders._buy` refuses unknown types; battles carry settings from their Appwrite row (M5.18).
- `plan/data/battle.yaml` **already** says `recovery_delay_s: 3600` (the plan PR renamed it): the code does not read it yet. A host started on the merged plan fails until this session lands.
- `battle_host/tool/playtest.dart` creates the playtest accounts, war and battle, and plays blue's opening.

## Steps
1. **Find every reader of `recovery_per_hour`**: `grep -rn recovery_per_hour packages/battle_rules packages/battle_host packages/battle_protocol packages/hawkbee_schema` (also test fixtures and `ApView.perHour` in the protocol — read M6.2's log before touching the protocol; if the message must change, follow M6's conventions: samples, both encodings, sizes).
2. **Rename to a delay** in `battle_rules`: the loader reads `ap.recovery_delay_s` (an integer ≥ 1), validation rejects the old key with a clear message, the AP pool recovers `seconds / delay` (stack decision 1's formula). Keep AP math in one place.
3. **Battle setting override**: the battle's settings (the row's settings map the host already loads) may hold `ap.recovery_delay_s`; the effective value is the row's, else the file's. Add `test_units: false` as a setting the same way.
4. **The test unit** in `plan/data/units.yaml`: id `test_unit`, `ap_max: 10000`, the values of Q-UNIT-26 (every action of UNIT-38, observe, heal, build/repair, radio, best sight and range of the roster, infantry movement class, price 0). Mind `common_stats`: every stat listed there is required. The validator's rule "every `ap_max` equals `ap.max`" gets its exception for `test_unit` (decision 239); nothing else relaxes.
5. **Host guard**: buying `test_unit` is refused with a host refusal code unless the battle's `test_units` setting is on (`SectionOrders._buy`, `refusal.dart`).
6. **Playtest tool**: `tool/playtest.dart` writes the battle with `test_units: true` and `ap.recovery_delay_s: 1` (a flag `--fast` on by default for the playtest; say so in `docs/battle_team/playtest.md`), and blue's opening buys one `test_unit`.
7. **Gates** per package (§4): `battle_rules` and `battle_host` 100 % (MCP `test` tool, `dart: true`), analyze, format. The data change has no code gate but the validator tests load the real files.
8. **Finish** (§5): logs, README row, PRs: `battle_rules`, `battle_host`, then `battle_team` (data only) and hawkbee.

## Tests to write
- `COMBAT-02 recovers one AP per recovery_delay_s` and `… the battle setting overrides the file`.
- `COMBAT-06 at 0 AP a unit moves at the recovery rate` updated to the delay.
- `decision 239 test_unit ap_max 10000 passes validation` and `decision 167 another unit with ap_max != ap.max fails validation`.
- `UNIT-44 buying test_unit is refused without test_units` and `… accepted with test_units`.
- The real `plan/data` files load (existing loader tests keep passing).

## Stop and ask when
- A protocol message (`ApView.perHour`) would change: the owner decides whether M7.2 may touch `battle_protocol` or M7.3+ carries it.
- Q-UNIT-26's assumed values do not fit the data model (e.g. one weapon slot): write the smallest consistent choice in the log and in Q-UNIT-26, as an assumption.

## Pitfalls
- Tests on real values read `../../apps/battle_team/plan/data/` relative to the package (§2): the submodule must be on `bt/m7-plan` or later to see `recovery_delay_s`.
- `battle_host` snapshots (M5.15) may serialise the setting: a recovered battle must keep its override; add that case to the recovery test.
- Never change `plan/specs` to make code pass (§2); the data change here is the plan's, not yours.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 2).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
