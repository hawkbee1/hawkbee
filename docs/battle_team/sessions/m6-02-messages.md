# Session M6.2: Messages between the host and its clients

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 2. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_protocol` (`hawkbee1/battle_protocol`) · **Branch:** `bt/m6-02-messages` · **Depends on:** M6.1.
**Skills:** `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/03-networking.md` (update policy, traffic estimate); `plan/stack/08-workload-placement.md` (what the client computes); MAP-49, RELIC-10, COMBAT-57 (decisions 232 to 234); the session logs of M5.9 (codecs, samples, sizes), M5.11 (refusal codes), M5.14 (the delta layer) and M6.1.

## Notes
- The messages are a family of their own beside commands, events and log entries, with the same `FieldWriter`/`FieldReader` codecs. The log format of M5.9 does not change.
- A section's view reuses the events' and the snapshot's value types where they fit; the snapshot itself (M5.15) is the host's private format and is never sent.
- Positions of moving units: quantised as `Position` is; say in the log whether a tick sends positions only or positions with the path and speed, and why.
- Record the grouping of shots per unit per tick and the first-person move rate in `stack/03` (battle_team, same branch name).

## Acceptance criteria
- [x] The acceptance criteria of the issue (m6-networking.md, Issue 2).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-08), stacked on M6.1 (`bt/m6-01-protocol-spike`, hawkbee #60), none of M5.19 to M6.1 merged yet:
- **`battle_protocol`** (from `main`):
  - `lib/src/messages.dart`: sealed `ClientMessage`: `SignIn` (battle, `CredentialKind` jwt or apiKey, the credential; its `toString` hides it), `SendCommand` (the client's request ID and a `Command`), `ResyncRequest`, `Heartbeat`. Sealed `HostMessage`: `SignInAccepted` (account, section, team, battle time), `SignInRefused` (`SignInRefusal`: invalid credential, no section, battle not found), `CommandAccepted` (request ID, sequence number), `CommandRefused` (request ID, M5.11's refusal code), `SectionView`, `TickUpdate`, `RelicAlert` (time, relic, new owner), `Goodbye` (`GoodbyeReason`: battle ended, key revoked, unsupported version, slow client, idle).
  - The view's values: `UnitView` (ID, type, section, HP and max, position when on the field, flying, weapon, and `UnitPrivate` for its own section only: place, `ApView` with its rate, morale, rounds, XP, transport, end of move, of reload, of observation), `HqView` (AP for its own team only), `RelicView`, `HoldView` (the countdown), `SectionPrivate` (money, XP, lock, spare weapons, prisoners as `JoinedUnit`, open offers as `OfferPosted`). The delta layer is the list of world events (`StructureBuilt`, `ObjectDamaged`, `ObjectDestroyed`, `CraterDug`).
  - `TickUpdate`: positions of moving units (`UnitPosition`), units that came into sight (whole) and went out (IDs), events, `Burst`s, `unseenHits` (COMBAT-57), own units whose private state changed (whole), the section's state when it changed, HQs in and out of sight, relics that moved or changed owner.
  - `lib/src/codec/wire_messages.dart` (a part of `wire.dart`, sharing its impact and joined-unit codecs): the fields and tags; `ProtocolCodec` gains `encode`/`decodeClientMessage` and `encode`/`decodeHostMessage` in both encodings. A message of another version throws `UnsupportedVersionException` (a `ProtocolException` with the `version`), so the host can answer with a goodbye.
  - `test/fixtures/v1/client_messages.*` and `host_messages.*`: committed samples of every message (`test/helpers/message_samples.dart`, `tool/write_samples.dart`); the M5.9 samples and log format are unchanged. `tool/message_sizes.dart` prints the sizes below.
- **`battle_team`**: `stack/03` update policy and sizes.

Checks: analyze `--fatal-infos` and format clean; 732 tests pass, 100 % line coverage, test optimization off. `battle_host` and `battle_backend` still analyze clean against it.

Sizes (binary, no WebSocket frame header), next to `stack/03`'s estimates: a tick with nothing but its time 19 bytes; one moving unit 18 bytes more (estimate 16); a tick with ten moving vehicles 199 bytes (estimate 160); a rifle shot as an event 55 bytes, 73 as a whole tick (estimate 40 per event); a hit by an unseen shooter 47 bytes as a tick; the whole view of a 16-unit section with its private state and 8 relics 2,239 bytes (5,833 in JSON). A fight stays under 12 kbit/s down.

Choices (recorded in `stack/03`):
- **Positions only**, at 5 Hz while a unit moves, quantised to the centimetre: a path or a speed would show where an enemy goes beyond what the section sees (MAP-29), and a section's own paths are the ones it sent.
- **One burst per unit per tick** in the updates: weapon, shots, hits, each unit hit once with the summed damage and its last result. The log keeps every shot.
- **First-person moves: 5 a second** while the player holds a direction, the cadence of the position updates.
- A hit by an unseen shooter is its own list in the tick (`unseenHits`): `Attacked` names its shooter, so it cannot be the cut-down form.
- The sign-in's protocol version is the message's own (every encoded message starts with it), not a field of `SignIn`.
- `Goodbye` also has `slowClient` and `idle`, which M6.5 needs (a bounded queue, an idle timeout); adding them now spares a later tag.

Questions raised: none.
