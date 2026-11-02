# Session M5.9: Commands, events and the battle log

**Issue:** `apps/battle_team/plan/milestones/m5-simulation-host.md`, Issue 9. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** `packages/battle_protocol` (`hawkbee1/battle_protocol`, new) · **Branch:** `bt/m5-09-protocol` · **Depends on:** M4 (merged).
**Skills:** `vgv-ai-flutter-plugin:create-project`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`, `vgv-ai-flutter-plugin:static-security`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/02-persistence.md` (what is logged); `plan/stack/03-networking.md` (what orders carry); `plan/stack/06-accounts-and-services.md` (API keys, origins); `plan/stack/07-engineering-principles.md` (Command pattern); AI-05; decisions 162, 166, 183; the session logs of M4.3 to M4.11 (the orders and outcomes that exist).

## Notes
- New package: the procedure of dc3d §2 with the Very Good CLI MCP `create` (`subcommand: dart_package`, `name: battle_protocol`, `output_directory: packages`, `workspace: true`, a description without a colon). Create `hawkbee1/battle_protocol` with `gh repo create --public`, add it to the root `workspace:` and melos `format` lists, and apply the new-package pitfalls of dc3d §2 (and of the M4.1 and M3.1 session logs).
- The package depends on no other battle package: commands carry IDs and plain values (positions, cells, amounts). The host maps them to rules.
- Binary encoding: write it by hand on `ByteData`, or use a package after checking it with context7; positions are quantised (stack decision 3).
- The hash of an API key: a slow, salted hash is not needed for a random 256-bit key; state the choice in the doc comment (static-security skill).

## Acceptance criteria
- [x] The acceptance criteria of the issue (m5-simulation-host.md, Issue 9).
- [x] The definition of done (`docs/battle_team/agent-workflow.md` §4).

## Session log
Built (2026-11-02) in the new package `packages/battle_protocol` (public repository `hawkbee1/battle_protocol`, merge commits only, submodule of hawkbee, in the root `workspace:` and melos `format` lists; template CI and dependabot deleted, `test: ^1.31.0`, `mocktail` dropped; dependencies `equatable` and `crypto`, licences checked):
- `lib/src/values.dart`: `Position` (centimetres, `Position.metres`), `Direction` (millionths, `Direction.of`), `Cell(x, y, island:)`, `Origin` (player, ai, server), `Sender(accountId, sectionId)`.
- `lib/src/orders.dart`: sealed `Order`, 33 variants, with `UnitOrder` (sealed, `unitId`) for the 23 that act on one unit: `Move` (optional client path), `Fire`, `FireAtPosition`, `FireAimed` (aim and fire time), `Reload`, `UnloadWeapon`, `SwapWeapon`, `PickUpWeapon`, `Land`, `TakeOff`, `Embark`, `Disembark`, `Build`, `Repair`, `Resume`, `Heal`, `Observe`, `Capture`, `Push`, `Store`, `Recall`, `Deploy`, `BuyNode`; and `MoveHq`, `BuyUnit`, `BuyWeapon`, `BuyGuildCamp`, `TransferMoney`, `OfferExchange`, `OfferRansom`, `AcceptOffer`, `RefuseOffer`, `DelegateHq`. An offer's ID is the sequence number of the command that posted it.
- `lib/src/command.dart`: `Command(sender, sentAt, order, origin?, seq?)` (Command pattern); `stamped(origin:, seq:)` is what the host does on acceptance.
- `lib/src/events.dart`: sealed `BattleEvent`, 42 variants: order refused (a string code) or delayed for AP, moves, `Attacked` with its `Impact`s (target, target type, damage, friendly, result: damaged, killed, prisoner, defected), crushing, weapons, time-only actions, transports, builds and repairs, heals, observation, capture and push pots, relic owner changes, victory hold, elimination, storage, recall, deployment, lock, purchases, transfers, tree nodes, prisoner offers, the HQ manager, battle start (seed) and end (winner, kind, eliminated teams).
- `lib/src/log_entry.dart`: `LogEntry(at, command?, events)`.
- `lib/src/codec/`: `FieldWriter` and `FieldReader` (Strategy): each message lists its fields once (`wire.dart`) and both encodings write them. `BinaryProtocolCodec` (version varint, then the fields; `logHeader`, `logFrame`, `encodeLog`, `decodeLog`: `BTLG`, the version, one length-prefixed frame per entry) and `JsonProtocolCodec` (`"v": 1`). Decoders throw only `ProtocolException`.
- `lib/src/api_key.dart`: `ApiKey.generate(Random)` (`btk_` and 43 base64url characters, 256 bits), `ApiKey.parse`, `hash` (SHA-256, hexadecimal); `toString` hides the key.
- `test/fixtures/v1/`: binary (`.hex`) and JSON samples of every command, event and log entry, and a whole log; `tool/write_samples.dart` adds new samples and never changes committed ones.

Checks: analyze `--fatal-infos` clean, format clean, 576 tests pass (with and without test optimization), coverage 100 %. The codec compiled with dart2js and run on Node gives bytes identical to the committed samples and round-trips every sample and the integer extremes.

Choices:
- `Command` is the envelope (sender, sender's time, origin, sequence number) around a sealed `Order`, so the host stamps the origin and the number in one place. A client or an AI agent sends a command without them; the host checks the sender against the sign-in (M5.11).
- Exact values, so a replay can compare events: times in microseconds, doubles as IEEE 754 doubles; positions in centimetres and directions in millionths, quantised by the model itself so both encodings carry the same value. Integers from −2^52 to 2^52 − 1, varints written with arithmetic: the web client reads and writes the same bytes.
- JSON refuses fields a message does not have (an AI agent's typo is an error, not an ignored field); a `null` optional field counts as absent.
- Weapon unloading is an order (`UnloadWeapon`, COMBAT-05: artillery unloads before moving); the issue's "loading and unloading" are `Embark` and `Disembark`. `Store` and `Recall` are separate orders, as the issue lists them.
- A refusal reason is a string code: the sealed refusal type of the order chain is M5.11's.
- XP and money earned are not events: the host derives them from the events (M5.12), and the clients get their values with the state (M6).
- The API key's hash is a plain SHA-256: a slow salted hash protects low-entropy passwords, not 256 random bits, and every call checks it.

Not in version 1 (adding them later is a new tag at the end of its list, not a new version): the HQ manager's team-wide orders and map markers (HQ-09), guild requests during a battle (stack decision 8), a stop order.

Decision by the owner (2026-11-02), recorded in battle_team on `bt/m5-09-protocol`: decision 219 (Q-REL-14, RELIC-24), the player whose unit first tries to move a relic while its push pot is empty chooses its path. `Push` carries an optional `path`; the host uses it only when the pot is empty.

Sizes (binary, version 1, the committed samples, IDs of 6 to 14 characters): a `Fire` command 53 bytes, a `Move` with a 3-cell path 70; an `Attacked` with 4 impacts 145 (about 26 per impact); the log entry of an artillery shot with its outcome and a dropped weapon 230; `OrderRefused` 18. The same `Fire` command in JSON: 176 bytes. String IDs dominate: stack decision 3 assumed about 40 bytes per event. If P-03 (M5.15) needs smaller logs, a battle-wide ID table is a version 2 change.
