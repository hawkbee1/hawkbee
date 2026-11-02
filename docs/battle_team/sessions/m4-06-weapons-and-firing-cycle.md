# Session M4.6: Weapons and firing cycle

**Issue:** `apps/battle_team/plan/milestones/m4-rules-core.md`, Issue 6. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_rules` (`hawkbee1/battle_rules`) · **Branch:** `bt/m4-06-weapons` · **Depends on:** M4.3.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/specs/70-combat-and-ap.md` (weapons, COMBAT-26 to COMBAT-33, COMBAT-56); `plan/data/combat.yaml` weapons, `weapon_swap`, dropped weapons; decisions 52 to 55, 63, 64, 134, 150 and 151.

## Notes
- Timeline tests drive time through the injected clock.
- The weapons waiting in a section's storage (decision 151) are a plain immutable list on the section.

## Acceptance criteria
- [x] The acceptance criteria of the issue (m4-rules-core.md, Issue 6).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-01), stacked on M4.8 (not merged yet), in `packages/battle_rules/lib/src/combat/weapons.dart`:
- `WeaponState` (immutable, one slot): `weapon`, `rounds`, `loaded`, `busyUntil`, `nextShotAt`; `unarmed()`, `ready(weapon)`, `forNewUnit(unit, combat)` (the default weapon, loaded and full); `canMoveAt(t)` (`move_while_loaded: false` needs an unloaded, idle weapon).
- `Armory(combat)`: `fire` (waits for the weapon, the rate of fire and `ap_per_shot`; a 1-round weapon ignores its rate of fire, COMBAT-56), `reload` (full magazine, the rest discarded), `unload`, `swap` (at storage, allowed types, from `StoredWeapons`, `weapon_swap.time_s`), `drop` (vanishes after `despawn_after_s`), `pickUp` (`pickup_ap`, own weapon dropped). Each returns `WeaponDone(at, state, pool, storage?, dropped?)` or `WeaponRefused(WeaponRefusal)`.
- `StoredWeapons`: the section's spare weapons, an immutable list (decision 151). `DroppedWeapon(weapon, goneAt)`.

Checks: analyze `--fatal-infos` clean, format clean, 302 tests pass, coverage 100 % (962/962 lines). Timeline tests on real data: the machine gun empties its magazine at its rate of fire; artillery fires once per reload and must unload before moving.

Bug found by the tests and fixed: a 1-round weapon first waited for its rate of fire too (artillery 15 s instead of its 10 s reload); `combat.yaml` says the rate of fire is not used by 1-round weapons.

Deviations and open points:
- Time is passed as arguments, not through a `Clock` (see M4.3).
- A newly bought unit's weapon starts loaded with a full magazine; a swapped-in or picked-up weapon arrives unloaded and needs a reload. The specs do not say; open point for the owner.
- `loaded` is a state of its own: set by a reload, cleared by an unload, not by firing the last round. So artillery stays "loaded" after its shot and still has to unload before it moves.
- A reload, an unload or a swap ordered while the weapon is busy starts when it is free.
- Buying weapons (money, `economy.yaml` prices) is not here: `StoredWeapons.added` is where a bought weapon lands.
