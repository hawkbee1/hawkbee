# Session M7.10: Pings, map markers and team chat

**Issue:** `apps/battle_team/plan/milestones/m7-client.md`, Issue 10. It is the specification of this session: read it entirely, with the milestone's "Conventions".
**Packages:** `packages/battle_protocol`, `packages/battle_host`, `packages/battle_client`, `apps/battle_team` · **Branch:** `bt/m7-10-chat` · **Depends on:** M7.1.
**Skills:** `vgv-ai-flutter-plugin:bloc`, `vgv-ai-flutter-plugin:testing`, `vgv-ai-flutter-plugin:green-gate`.
**Read** (`plan/` is `apps/battle_team/plan/`): SOC-34, SOC-36, SOC-37; decision 123; `plan/stack/03-networking.md` (sizes, update policy); `plan/stack/07-engineering-principles.md` (`battle_discord_bridge`); `packages/battle_protocol/lib/src/messages.dart` and its samples (`test/`), `codec/`; the session logs of M6.2 (how a message is added: both encodings, frozen samples, sizes), M6.4 (fan-out per section, `PendingAlerts` for late delivery), M6.5 (rate limit), M6.7 (`HeldView`).

## Steps, in this order (four packages, one PR each)
1. **`battle_protocol`**: client → host `Ping(position)`, `PlaceMarker(position, kind, label?)`, `RemoveMarker(id)`, `Chat(text)`; host → clients `TeamPing`, `TeamMarkers` (the team's current markers, whole), `TeamChat(messages)` (history on connect, then each new one). Text length capped by a constant in `plan/data`? No: a protocol limit is technical, put it in the codec with a doc comment. Samples in both encodings; sizes recorded.
2. **`battle_host`**: the commands go through the command handler like orders (rate-limited as any command, M6.5) but **change no battle state**: they are team state, kept per battle, in the snapshot (SOC-36 history survives a restart). Fan-out to the team's sections only (SOC-34) through the update stream (Observer, M6.4); a late joiner gets markers and history with its whole view. Design the chat message so the Discord bridge can read and inject (an `origin` field: `player`, `discord`), nothing more.
3. **`battle_client`**: `HeldView` keeps the team's markers and chat; `send` accepts the new commands.
4. **The app**: a ping button then a tap on the ground (a short-lived ring drawn through the `BattleWorld` seam); markers placed and removed on the map; a chat panel over the battle (list + field), localized en + fr.
5. **Loopback test** (in `battle_host`, as M6.7's `battle_client_test.dart`): two clients of one team exchange a ping, a marker and a message; a third client, enemy team, receives none of them.
6. **Gates** per package (§4, §6); sizes next to `stack/03` (one line on the `apps/battle_team` branch); **show it** (recording); **finish** (§5): protocol, host, client PRs, then battle_team and hawkbee.

## Tests to write
- Protocol: round trips and frozen samples for each message; sizes.
- `SOC-34 an enemy section receives no ping, marker or chat`; `SOC-36 chat history reaches a late joiner`; `SOC-37 chat is team-wide` (two sections of one team).
- Host: a chat command changes no unit, no AP, nothing in the battle log but itself; survives a snapshot + recovery.
- App: ping ring drawn (`FakeWorld`), markers listed, chat panel sends and shows, en and fr.

## Stop and ask when
- The owner may want pings visible to enemies within sight (a flare) — the rules say team only; ask only if a rule contradicts.
- Moderation of abusive chat is M8 topic 1: do not add it; ask only if the owner wants a cap now.

## Pitfalls
- A chat message is player text: never log its content (privacy), only its size.
- Markers are team state and survive reconnection: send them whole on connect, deltas afterwards.

## Acceptance criteria
- [ ] The acceptance criteria of the issue (m7-client.md, Issue 10).
- [ ] The definition of done (`docs/battle_team/agent-workflow.md` §4 and §6).

## Session log
