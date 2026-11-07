import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:battle_protocol/battle_protocol.dart';
import 'package:battle_stats/battle_stats.dart';
import 'package:daily_stats/src/appwrite_stores.dart';
import 'package:daily_stats/src/daily_stats.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart' as models;
import 'package:hawkbee_schema/hawkbee_schema.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'helpers.dart';

class _MockStorage extends Mock implements Storage;

class _MockTables extends Mock implements TablesDB;

models.Row _row(String id, Map<String, Object?> data) => models.Row(
  $id: id,
  $sequence: '1',
  $tableId: AppwriteIds.statsTableId,
  $databaseId: 'hawkbee',
  $createdAt: '',
  $updatedAt: '',
  $permissions: const [],
  data: data,
);

void main() {
  group(AppwriteLogReader, () {
    late _MockStorage storage;
    final log = fixtureLog();
    Uint8List batch(List<LogEntry> entries) => Uint8List.fromList(
      gzip.encode(const BinaryProtocolCodec().encodeLog(entries)),
    );

    setUp(() => storage = _MockStorage());

    void serve(String fileId, Uint8List data) => when(
      () => storage.getFileDownload(
        bucketId: AppwriteIds.battleLogsBucketId,
        fileId: fileId,
      ),
    ).thenAnswer((_) async => data);

    test(
      'follows the batches by ID from the start until one is missing',
      () async {
        serve('b-1-000000000000', batch(log.sublist(0, 3)));
        serve('b-1-000000000003', batch(log.sublist(3)));
        when(
          () => storage.getFileDownload(
            bucketId: AppwriteIds.battleLogsBucketId,
            fileId: 'b-1-${log.length.toString().padLeft(12, '0')}',
          ),
        ).thenThrow(AppwriteException('not found', 404));

        expect(await AppwriteLogReader(storage).read('b-1'), log);
      },
    );

    test('stops at an empty batch, and passes other errors on', () async {
      serve('b-1-000000000000', batch(const []));
      when(
        () => storage.getFileDownload(
          bucketId: AppwriteIds.battleLogsBucketId,
          fileId: 'b-2-000000000000',
        ),
      ).thenThrow(AppwriteException('down', 503));

      expect(await AppwriteLogReader(storage).read('b-1'), isEmpty);
      expect(
        () => AppwriteLogReader(storage).read('b-2'),
        throwsA(isA<AppwriteException>()),
      );
    });
  });

  group(AppwriteStatsStore, () {
    late _MockTables tables;
    late AppwriteStatsStore store;
    final stats = Stats(kills: const {'jeep': 2});

    setUp(() {
      tables = _MockTables();
      store = AppwriteStatsStore(tables);
      when(
        () => tables.upsertRow(
          databaseId: any(named: 'databaseId'),
          tableId: any(named: 'tableId'),
          rowId: any(named: 'rowId'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => _row('x', const {}));
    });

    Map<dynamic, dynamic> written(String table, String rowId) =>
        verify(
              () => tables.upsertRow(
                databaseId: 'hawkbee',
                tableId: table,
                rowId: rowId,
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as Map<dynamic, dynamic>;

    test('a row ID is a hash of its key, the same each time', () {
      final id = AppwriteStatsStore.rowId(['stats', 'war', 'w-1']);

      expect(id, hasLength(32));
      expect(id, AppwriteStatsStore.rowId(['stats', 'war', 'w-1']));
      expect(id, isNot(AppwriteStatsStore.rowId(['stats', 'war', 'w-2'])));
    });

    test('writes a stats row under the hash of its key', () async {
      await store.putStats(
        StatsRow(
          scope: StatsScope.war,
          scopeId: 'w-1',
          warId: 'w-1',
          subject: StatsSubject.player,
          subjectId: 'acc-red',
          stats: stats,
        ),
      );

      expect(
        written(
          AppwriteIds.statsTableId,
          AppwriteStatsStore.rowId([
            AppwriteIds.statsTableId,
            'war',
            'w-1',
            'player',
            'acc-red',
          ]),
        ),
        {
          'scope': 'war',
          'scope_id': 'w-1',
          'war_id': 'w-1',
          'subject': 'player',
          'subject_id': 'acc-red',
          'stats': jsonEncode(stats.toJson()),
        },
      );
    });

    test('writes medals and flags', () async {
      await store.putMedal(
        accountId: 'acc-red',
        medal: const Medal(track: 'kills.jeep', tier: 'gold'),
      );
      await store.putFlag(
        'b-1',
        const FlaggedHitRate(
          day: 2,
          accountId: 'acc-red',
          weapon: 'rifle',
          shots: Shots(fired: 60, hits: 59),
          mean: 0.5,
          sigma: 0.1,
        ),
      );

      expect(
        written(
          AppwriteIds.medalsTableId,
          AppwriteStatsStore.rowId([
            AppwriteIds.medalsTableId,
            'acc-red',
            null,
            'kills.jeep',
            'gold',
          ]),
        ),
        {
          'account_id': 'acc-red',
          'war_id': null,
          'track': 'kills.jeep',
          'tier': 'gold',
        },
      );
      expect(
        written(
          AppwriteIds.hitRateFlagsTableId,
          AppwriteStatsStore.rowId([
            AppwriteIds.hitRateFlagsTableId,
            'b-1',
            2,
            'acc-red',
            'rifle',
          ]),
        )['hits'],
        59,
      );
    });

    test('finds rows page by page with their filters', () async {
      Map<String, Object?> data(int i) => {
        'scope': 'battle',
        'scope_id': 'b-$i',
        'war_id': 'w-1',
        'subject': 'player',
        'subject_id': 'acc-red',
        'stats': jsonEncode(stats.toJson()),
      };
      when(
        () => tables.listRows(
          databaseId: 'hawkbee',
          tableId: AppwriteIds.statsTableId,
          queries: any(named: 'queries'),
        ),
      ).thenAnswer((invocation) async {
        final queries = invocation.namedArguments[#queries] as List<String>;
        final second = queries.any((query) => query.contains('cursorAfter'));
        return models.RowList(
          total: 101,
          rows: second
              ? [_row('r-100', data(100))]
              : [for (var i = 0; i < 100; i++) _row('r-$i', data(i))],
        );
      });

      final found = await store.findStats(
        scope: StatsScope.battle,
        warId: 'w-1',
        subject: StatsSubject.player,
        subjectId: 'acc-red',
      );

      expect(found, hasLength(101));
      expect(found.last.scopeId, 'b-100');
      expect(found.last.stats, stats);
      final pages = verify(
        () => tables.listRows(
          databaseId: 'hawkbee',
          tableId: AppwriteIds.statsTableId,
          queries: captureAny(named: 'queries'),
        ),
      ).captured.cast<List<String>>();
      expect(pages.first, [
        Query.equal('scope', 'battle'),
        Query.equal('war_id', 'w-1'),
        Query.equal('subject', 'player'),
        Query.equal('subject_id', 'acc-red'),
        Query.limit(100),
      ]);
      expect(pages.last.last, Query.cursorAfter('r-99'));
    });
  });
}
