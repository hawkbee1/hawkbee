import 'package:battle_backend/battle_backend.dart';
import 'package:create_battle/main.dart' as function;
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:test/test.dart';

class _Request {
  new(this.bodyJson, this.headers);

  final Object? bodyJson;
  final Map<String, String> headers;
}

class _Response {
  int? status;
  Object? body;

  Object json(Object data, int status) {
    this.status = status;
    return body = data;
  }
}

class _Context {
  new(Object? body, {String? caller})
    : req = _Request(body, {'x-appwrite-user-id': ?caller});

  final _Request req;
  final res = _Response();

  void log(String message) {}
}

final class _Admins implements Admins {
  @override
  Future<bool> isAdmin(String accountId) async => accountId == 'admin';
}

Execution _as(String caller, Object? body) =>
    Execution(caller: caller, body: body, client: Client());

void main() {
  group('create_battle function', () {
    test('SOC-16 SOC-20 an admin plans a battle and starts it', () async {
      final wars = Wars(
        rows: MemoryRows(),
        admins: _Admins(),
        data: function.planData,
      );
      await wars.create(caller: 'admin', warId: 'w-1');

      final planned = await function.respond(
        _as('admin', {
          'action': 'plan',
          'warId': 'w-1',
          'battleId': 'b-1',
          'mapId': 'valley',
          'seed': 3,
        }),
        wars,
      );
      final started = await function.respond(
        _as('admin', {'action': 'start', 'battleId': 'b-1'}),
        wars,
      );

      expect(planned['status'], 'planned');
      expect(planned['seed'], 3);
      expect(started['status'], 'running');
    });

    test('COMBAT-02 UNIT-44 a testing battle carries its settings', () async {
      final wars = Wars(
        rows: MemoryRows(),
        admins: _Admins(),
        data: function.planData,
      );
      await wars.create(caller: 'admin', warId: 'w-1');

      final planned = await function.respond(
        _as('admin', {
          'action': 'plan',
          'warId': 'w-1',
          'battleId': 'b-1',
          'mapId': 'valley',
          'seed': 3,
          'settings': {
            'ap': {'recovery_delay_s': 1},
            'test_units': true,
          },
        }),
        wars,
      );

      expect(
        planned['settings'],
        '{"ap":{"recovery_delay_s":1},"test_units":true}',
      );
      expect((await wars.battle('b-1')).settings['test_units'], isTrue);
    });

    test('answers 400 to an unknown action', () async {
      final unknown = _Context({'action': 'win'}, caller: 'admin');
      await function.main(unknown);
      expect(unknown.res.status, 400);
    });

    test('runs on the tables of its project', () {
      expect(function.appwriteWars(Client()).rows, isA<AppwriteRows>());
    });
  });
}
