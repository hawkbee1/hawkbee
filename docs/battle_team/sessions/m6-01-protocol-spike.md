# Session M6.1: Protocol spike, dashwire against M5's protocol

**Issue:** `apps/battle_team/plan/milestones/m6-networking.md`, Issue 1. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Package:** none merged; the result goes to `apps/battle_team/plan/stack/03-networking.md` (`hawkbee1/battle_team`) · **Branch:** `bt/m6-01-protocol-spike` · **Depends on:** M5 (M5.19 #57, M5.21 #58).
**Skills:** `vgv-ai-flutter-plugin:license-compliance`.
**Read** (`plan/` is `apps/battle_team/plan/`): `plan/stack/03-networking.md` (options 3 and 5); `plan/stack/04-client-and-rendering.md` (`flutter_scene_net`); `plan/stack/01-simulation-host.md`; the session log of M5.9 (encodings, sizes).

## Notes
- Read dashwire's packages with the Dart MCP package tools (`read_package_uris`, `rip_grep_packages`) after adding them to a scratch package outside the workspace. Its `server` library and `dashwire_replication`'s relevancy are the parts that matter. Do not trust a README: check the code or its tests.
- The scratch code is not merged. Commit it on the branch of a scratch folder in the scratchpad, or describe it in the log. Only `stack/03` changes.
- The decision is the designer's. If the spike recommends dashwire, stop after writing it up and ask: it changes M6 Issues 2 to 8. If it recommends option 3, write "Assumed" in the log and the PR, and the next sessions go on (owner's rule of 2026-11-02).

## Acceptance criteria
- [x] The acceptance criteria of the issue (m6-networking.md, Issue 1): the comparison, sizes and choice are in `stack/03`, option 5. The designer confirmed option 3 on 2026-11-08.

## Session log
Done 2026-11-08, stacked on `bt/m6-plan` (#59). Only `plan/stack/03-networking.md` changed (option 5's comparison, sizes and recommendation), and one line of `stack/04` that pointed at the open spike.

Spike (scratch package outside the workspace, not merged), on `dashwire` 0.1.0 and `dashwire_replication` 0.2.1, read in `~/.pub-cache`:
- `bin/fight.dart`: one scripted fight seen by section B (a tank moving 2 s at 5 Hz, three shots B sees, a grouped machine-gun burst, a shot from a forest B does not see, a death), encoded with `BinaryProtocolCodec` and with a `ReplicationHost` over a loopback connection whose sends are counted. Unit replica: position (`vec3`, 1 cm), HP (`f64`, on change), type and section (spawn only), AP (owner only), an `attacked` RPC. Fog through a `RelevancyFilter` holding B's set. Option 3's tick update is a stand-in (version, tag, time, then ID and position per unit) until M6.2.
- `bin/server.dart`: `dart compile exe`, a `Room` launched by `IsolateRoomPool` behind `WebSocketWireServer` on 127.0.0.1; a bad token refused (`SessionRejected(3)`), a client over the real socket received the moving unit.
- `bin/web_client.dart`: session, replication client and `battle_protocol` compiled with `dart compile js` (run on Node with a `self` shim) and `dart compile wasm` (run on Node 22 with `--experimental-wasm-imported-strings`); schema hash `f9cb9cb` on the VM, in JavaScript and in Wasm.
- `bin/samples.dart`: `battle_protocol`'s committed samples (86 commands, events and entries, and the 5-entry log) decoded and re-encoded in binary and JSON, and 2^52 − 1; identical on the VM, in JavaScript and in Wasm. A double prints `42` in JavaScript and `42.0` on the VM and in Wasm: dashwire's codec IDs guard against it; `battle_protocol` writes raw IEEE bytes and its JSON samples match on all three.
- `packages_check_licenses`: MIT (2). `bdero/dashwire`: 8 stars, last push 2026-08-16.

Sizes (bytes, binary, no WebSocket frame header): one moving unit 22 (option 3) against 25 (dashwire); ten moving vehicles 167 against 205; a rifle shot 53 against 43; a grouped burst of three impacts 112 against 99; a 16-unit whole view 649 against 784; the 2-second fight 469 against 431. dashwire's fixed costs: ping 10 B up and pong 21 B down four times a second, a 4-byte snapshot acknowledgement up per update. The hidden shot: option 3 cut down for B 40 B (full 53); dashwire sends no RPC for a replica B does not know, so B learns it only from the target's HP (21 B).

Findings beyond `stack/03`: a replica holds at most 32 fields; `NetIdAllocator.random()` uses `Random.secure`, so a host must pass its own allocator to stay deterministic; `Room` drives its tick from a wall-clock `Timer`, so `battle_host` would use `ReplicationHost` directly with its own clock.

Option 3 confirmed by the designer on 2026-11-08, after the comparison: M6.2 onwards follow it.

Questions raised: none on the rules.

