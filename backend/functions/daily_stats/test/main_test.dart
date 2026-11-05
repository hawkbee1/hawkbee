import 'package:battle_backend/battle_backend.dart';
import 'package:battle_rules/battle_rules.dart';
import 'package:daily_stats/main.dart' as function;
import 'package:daily_stats/src/daily_stats.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:hawkbee_schema/hawkbee_schema.dart';
import 'package:plan_data/plan_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

class _Request {
  new(this.bodyJson);

  final Object? bodyJson;
  final headers = <String, String>{'x-appwrite-key': 'key'};
}

class _Response {
  int? status;

  Object json(Object data, int status) {
    this.status = status;
    return data;
  }
}

class _Context {
  new(Object? body) : req = _Request(body);

  final _Request req;
  final res = _Response();

  void log(String message) {}
}

Execution _execution(Object? body) =>
    Execution(caller: '', body: body, client: Client());

void main() {
  late MemoryStatsStore store;
  late DailyStats daily;

  setUp(() {
    store = MemoryStatsStore();
    daily = DailyStats(
      logs: MemoryLogReader({
        for (final id in ['b-1', 'b-2', 'b-3', 'b-4']) id: fixtureLog(),
      }),
      store: store,
      medals: MedalsData.parse(medalsYaml),
    );
  });

  group('daily_stats function', () {
    test('runs the battle and war the body names', () async {
      final body = await function.respond(
        _execution({'battleId': 'b-1', 'warId': 'w-1'}),
        daily,
        MemoryRows(),
      );

      expect(body['battleId'], 'b-1');
      expect(body['entries'], fixtureLog().length);
      expect(store.stats, isNotEmpty);
    });

    test('decision 143 on its schedule, runs every battle running and the '
        'ended ones whose statistics are not final, which then are', () async {
      final rows = MemoryRows();
      Future<void> battle(
        String id,
        BattleStatus status, {
        bool done = false,
      }) => rows.put(
        AppwriteIds.battlesTableId,
        id,
        BattleRow(
          id: id,
          warId: 'w-1',
          mapId: 'valley',
          seed: 1,
          status: status,
          statsDone: done,
        ).toData(),
      );
      await battle('b-1', BattleStatus.running);
      await battle('b-2', BattleStatus.closed);
      await battle('b-3', BattleStatus.closed, done: true);
      await battle('b-4', BattleStatus.planned);

      final body = await function.respond(_execution(null), daily, rows);

      expect(body['battles'], ['b-1', 'b-2']);
      final closed = BattleRow.fromData(
        'b-2',
        (await rows.get(AppwriteIds.battlesTableId, 'b-2'))!,
      );
      expect(closed.statsDone, isTrue);
      expect(await function.respond(_execution(null), daily, rows), {
        'battles': ['b-1'],
      });
    });

    test('answers 400 to a battle without its war', () async {
      final context = _Context({'battleId': 'b-1'});

      await function.main(context);

      expect(context.res.status, 400);
    });

    test('runs on the Appwrite project of its execution', () {
      final daily = function.appwriteDailyStats(Client());

      expect(daily.store, isA<StatsStore>());
    });
  });
}
