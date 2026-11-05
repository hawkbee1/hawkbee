import 'package:battle_rules/battle_rules.dart';
import 'package:daily_stats/main.dart' as function;
import 'package:daily_stats/src/daily_stats.dart';
import 'package:plan_data/plan_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

class _FakeRequest {
  new(this.bodyJson);

  final Object? bodyJson;
  final headers = <String, String>{'x-appwrite-key': 'key'};
}

class _FakeResponse {
  Object? body;
  int? status;

  Object json(Object data, int status) {
    this.status = status;
    return body = data;
  }
}

class _FakeContext {
  new(Object? body) : req = _FakeRequest(body);

  final _FakeRequest req;
  final res = _FakeResponse();
  final logs = <String>[];

  void log(String message) => logs.add(message);
}

const _environment = {
  'APPWRITE_FUNCTION_API_ENDPOINT': 'http://appwrite.test/v1',
  'APPWRITE_FUNCTION_PROJECT_ID': 'hawkbee',
};

void main() {
  group('daily_stats function', () {
    test('runs the battle and war the body names', () async {
      final store = MemoryStatsStore();
      final (status, body) = await function.respond(
        {'battleId': 'b-1', 'warId': 'w-1'},
        () => DailyStats(
          logs: MemoryLogReader({'b-1': fixtureLog()}),
          store: store,
          medals: MedalsData.parse(medalsYaml),
        ),
      );

      expect(status, 200);
      expect(body['battleId'], 'b-1');
      expect(body['entries'], fixtureLog().length);
      expect(store.stats, isNotEmpty);
    });

    test('answers an execution with the key it carries', () async {
      final context = _FakeContext({'battleId': 'b-1', 'warId': 'w-1'});
      String? key;

      await function.handle(
        context,
        _environment,
        make: (environment, given) {
          key = given;
          return DailyStats(
            logs: MemoryLogReader({'b-1': fixtureLog()}),
            store: MemoryStatsStore(),
            medals: MedalsData.parse(medalsYaml),
          );
        },
      );

      expect(key, 'key');
      expect(context.res.status, 200);
      expect(context.logs.single, startsWith('daily_stats: 200'));
    });

    test('answers 400 to a body that names no battle and war', () async {
      final context = _FakeContext({'battleId': 'b-1'});

      await function.main(context);

      expect(context.res.status, 400);
      expect(context.logs.single, startsWith('daily_stats: 400'));
    });

    test('runs on the Appwrite project of its environment', () {
      final daily = function.appwriteDailyStats(_environment, 'key');

      expect(daily.store, isA<StatsStore>());
      expect(daily.logs, isA<LogReader>());
    });
  });
}
