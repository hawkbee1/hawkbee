import 'dart:convert';

import 'package:hawkbee_schema/hawkbee_schema.dart';
import 'package:test/test.dart';

void main() {
  const unit = KeptUnit(
    id: 'cmd-1',
    type: 'commander',
    xpEarned: 12.5,
    xpUnspent: 2,
    tree: {'hp': 2},
    weapon: 'rifle',
  );
  const kept = KeptSection(
    money: 900,
    xp: 40.5,
    weapons: ['mortar'],
    units: [
      unit,
      KeptUnit(id: 'sol-1', type: 'soldier'),
    ],
  );

  /// The data of [data] once written to a table and read back as JSON.
  RowData stored(RowData data) =>
      jsonDecode(jsonEncode(data)) as Map<String, Object?>;

  group('row models', () {
    test('a war reads back what it writes', () {
      const war = WarRow(
        id: 'w-1',
        minStartingMoney: 1000,
        planned: ['b-2'],
        current: 'b-1',
        sections: {'acc-1': 's-1'},
      );
      final again = WarRow.fromData('w-1', stored(war.toData()));

      expect(again.toData(), war.toData());
      expect(again.id, 'w-1');
    });

    test('a battle reads back what it writes, its result included', () {
      const battle = BattleRow(
        id: 'b-1',
        warId: 'w-1',
        mapId: 'valley',
        seed: 7,
        status: BattleStatus.ended,
        teams: {
          'team-1': ['s-1'],
          'team-2': [],
        },
        host: 'host-1',
        winner: 'team-1',
        result: BattleResult(
          winner: 'team-1',
          sections: {'s-1': kept},
          earned: {'s-1': 4.5},
        ),
      );
      final again = BattleRow.fromData('b-1', stored(battle.toData()));

      expect(again.toData(), battle.toData());
      expect(again.result!.sections['s-1']!.units.first.tree, {'hp': 2});
      expect(
        again.copyWith(teams: const {'team-1': []}).toData()['status'],
        'ended',
      );
      expect(
        again.copyWith(status: BattleStatus.closed, statsDone: true).toData(),
        {...battle.toData(), 'status': 'closed', 'stats_done': true},
      );
      expect(
        again
            .copyWith(
              host: () => 'host-2',
              winner: 'team-2',
              result: const BattleResult(winner: 'team-2', sections: {}),
            )
            .toData(),
        {
          ...battle.toData(),
          'host': 'host-2',
          'winner': 'team-2',
          'result': '{"winner":"team-2","sections":{},"earned":{}}',
        },
      );
      expect(again.copyWith(host: () => null).toData()['host'], isNull);
      expect(
        BattleRow.fromData(
          'b-2',
          stored(
            const BattleRow(
              id: 'b-2',
              warId: 'w-1',
              mapId: 'valley',
              seed: 1,
            ).toData(),
          ),
        ).result,
        isNull,
      );
    });

    test('a section, a guild and an API key read back what they write', () {
      const section = SectionRow(
        id: 's-1',
        warId: 'w-1',
        accountId: 'acc-1',
        guildId: 'g-1',
        kept: kept,
      );
      const guild = GuildRow(
        id: 'g-1',
        warId: 'w-1',
        roles: {'s-1': 'chief'},
        xp: 3,
        optedIn: true,
      );
      const key = ApiKeyRow(accountId: 'acc-1', hash: 'ab', revoked: true);

      expect(
        SectionRow.fromData('s-1', stored(section.toData())).toData(),
        section.toData(),
      );
      expect(
        section.copyWith(guildId: () => null).toData()['guild_id'],
        isNull,
      );
      expect(
        GuildRow.fromData('g-1', stored(guild.toData())).toData(),
        guild.toData(),
      );
      expect(ApiKeyRow.fromData(stored(key.toData())).toData(), key.toData());
    });

    test('a host reads back what it writes, in UTC', () {
      final host = HostRow(
        address: 'http://host-saint-lo:8080',
        seenAt: DateTime.utc(2026, 11, 8, 10),
      );
      // Appwrite answers a datetime column with its offset.
      final again = HostRow.fromData({
        ...host.toData(),
        'seen_at': '2026-11-08T11:00:00.000+01:00',
      });

      expect(HostRow.fromData(stored(host.toData())).toData(), host.toData());
      expect(again.seenAt, host.seenAt);
      expect(again.seenAt.isUtc, isTrue);
      expect(
        host.aliveAt(
          DateTime.utc(2026, 11, 8, 10, 0, 59),
          const Duration(minutes: 1),
        ),
        isTrue,
      );
      expect(
        host.aliveAt(
          DateTime.utc(2026, 11, 8, 10, 1),
          const Duration(minutes: 1),
        ),
        isFalse,
      );
      expect(
        () => HostRow.fromData({...host.toData(), 'seen_at': 'yesterday'}),
        throwsFormatException,
      );
    });

    test('refuse data that is not a row of theirs', () {
      final war = stored(const WarRow(id: 'w', minStartingMoney: 1).toData());
      final battle = stored(
        const BattleRow(id: 'b', warId: 'w', mapId: 'm', seed: 1).toData(),
      );
      final section = stored(
        const SectionRow(
          id: 's',
          warId: 'w',
          accountId: 'a',
          kept: kept,
        ).toData(),
      );

      for (final damaged in <void Function()>[
        () => WarRow.fromData('w', {...war, 'over': 'no'}),
        () => WarRow.fromData('w', {...war, 'planned': '[1]'}),
        () => WarRow.fromData('w', {...war, 'sections': '{"a": 1}'}),
        () => BattleRow.fromData('b', {...battle, 'status': 'lost'}),
        () => BattleRow.fromData('b', {...battle, 'teams': '{"t": [1]}'}),
        () => SectionRow.fromData('s', {
          ...section,
          'kept': '{"money": 1, "xp": 0, "weapons": [2], "units": []}',
        }),
        () => SectionRow.fromData('s', {
          ...section,
          'kept': '{"money": 1, "xp": 0, "weapons": [], "units": 3}',
        }),
      ]) {
        expect(damaged, throwsFormatException);
      }
    });
  });
}
