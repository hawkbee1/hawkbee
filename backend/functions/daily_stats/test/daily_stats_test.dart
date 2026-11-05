import 'package:battle_protocol/battle_protocol.dart';
import 'package:battle_rules/battle_rules.dart';
import 'package:battle_stats/battle_stats.dart';
import 'package:daily_stats/src/daily_stats.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Medals at low thresholds: bronze at 1, silver at 2, gold at 5; a flag
/// at any rate above the mean.
const _medals = MedalsData(
  version: 1,
  tiers: ['bronze', 'silver', 'gold'],
  points: {'bronze': 1, 'silver': 3, 'gold': 10},
  killThresholds: {
    'default': {'bronze': 1, 'silver': 2, 'gold': 5},
  },
  actionThresholds: {'bronze': 100, 'silver': 200, 'gold': 300},
  actionKinds: ['hit'],
  friendlyKillThresholds: {'bronze': 1, 'silver': 2, 'gold': 5},
  hitRateFlag: HitRateFlag(sigmas: 0, minShots: 1),
);

/// Two players, each with one first-person shot: one hits.
List<LogEntry> _duel() => [
  const LogEntry(
    at: Duration.zero,
    events: [
      SectionJoined(
        sectionId: 's-a',
        accountId: 'acc-a',
        team: 'a',
        units: [JoinedUnit(unitId: 'u-a', unitType: 'soldier')],
      ),
      SectionJoined(
        sectionId: 's-b',
        accountId: 'acc-b',
        team: 'b',
        units: [JoinedUnit(unitId: 'u-b', unitType: 'soldier')],
      ),
    ],
  ),
  for (final (seq, unit, section, hit) in [
    (1, 'u-a', 's-a', true),
    (2, 'u-b', 's-b', false),
  ])
    LogEntry(
      at: const Duration(seconds: 5),
      command: Command(
        sender: Sender(accountId: 'acc', sectionId: section),
        sentAt: Duration.zero,
        order: FireAimed(
          unitId: unit,
          aim: Direction.of(1, 0, 0),
          fireTime: Duration.zero,
        ),
        seq: seq,
      ),
      events: [
        Attacked(
          attackerId: unit,
          sectionId: section,
          weapon: 'rifle',
          hit: hit,
          impacts: const [],
        ),
      ],
    ),
];

void main() {
  group('decision 143 the daily statistics of a battle', () {
    late MemoryStatsStore store;
    late DailyStats daily;

    setUp(() {
      store = MemoryStatsStore();
      daily = DailyStats(
        logs: MemoryLogReader({
          'b-1': fixtureLog(),
          'b-2': fixtureLog(),
          'b-3': fixtureLog(),
          'duel': _duel(),
        }),
        store: store,
        medals: _medals,
      );
    });

    test(
      'SOC-22 writes the battle stats of each unit, section and player',
      () async {
        final report = await daily.run(battleId: 'b-1', warId: 'w-1');

        expect(report.entries, fixtureLog().length);
        // 7 units, 3 sections and 3 players, for the battle and the war; 3
        // players for the game.
        expect(report.rows, 13 + 13 + 3);
        final tally = BattleTally()..addAll(fixtureLog());
        expect(
          store.of(StatsScope.battle, 'b-1', StatsSubject.player, 'acc-red'),
          tally.players['acc-red'],
        );
        expect(
          store.of(StatsScope.battle, 'b-1', StatsSubject.unit, 'art-r'),
          tally.units['art-r'],
        );
        expect(
          store.stats.values.where((row) => row.scope == StatsScope.battle),
          everyElement(
            isA<StatsRow>().having((row) => row.warId, 'war', 'w-1'),
          ),
        );
      },
    );

    test('adds up the battles of a war, and the wars of a player for the '
        'game', () async {
      await daily.run(battleId: 'b-1', warId: 'w-1');
      await daily.run(battleId: 'b-2', warId: 'w-1');
      await daily.run(battleId: 'b-3', warId: 'w-2');
      final once = (BattleTally()..addAll(fixtureLog())).players['acc-red']!;

      expect(
        store.of(StatsScope.war, 'w-1', StatsSubject.player, 'acc-red'),
        once + once,
      );
      expect(
        store.of(StatsScope.war, 'w-1', StatsSubject.section, 's-red'),
        once + once,
      );
      expect(
        store.of(StatsScope.game, 'game', StatsSubject.player, 'acc-red'),
        once + once + once,
      );
    });

    test('a run made again writes the same results', () async {
      await daily.run(battleId: 'b-1', warId: 'w-1');
      final first = {...store.stats};
      await daily.run(battleId: 'b-1', warId: 'w-1');

      expect(store.stats.keys, first.keys);
      expect(
        store.of(StatsScope.war, 'w-1', StatsSubject.player, 'acc-red'),
        first[(StatsScope.war, 'w-1', StatsSubject.player, 'acc-red')]!.stats,
      );
    });

    test('SOC-24 SOC-25 writes the war medals and the game medals each player '
        'reaches', () async {
      final report = await daily.run(battleId: 'b-1', warId: 'w-1');

      // acc-red: a soldier, a jeep, and one friendly kill.
      for (final war in ['w-1', null]) {
        expect(
          store.medals,
          contains((
            'acc-red',
            war,
            const Medal(track: 'kills.jeep', tier: 'bronze'),
          )),
        );
        expect(
          store.medals,
          contains((
            'acc-red',
            war,
            const Medal(track: 'friendly_kills', tier: 'bronze'),
          )),
        );
      }
      expect(report.medals, store.medals.length);
      expect(store.medals.where((medal) => medal.$1 == 'acc-blue'), isEmpty);
    });

    test('decision 230 writes the hit rates far above the norm of each '
        'battle-day', () async {
      final report = await daily.run(battleId: 'duel', warId: 'w-1');

      expect(report.flags, 1);
      final (battle, flag) = store.flags.single;
      expect(battle, 'duel');
      expect(flag.accountId, 'acc-a');
      expect(flag.day, 0);
      expect(report.toJson(), {
        'entries': 3,
        'rows': report.rows,
        'medals': 0,
        'flags': 1,
      });
    });
  });
}
