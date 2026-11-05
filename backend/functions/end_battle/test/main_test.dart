import 'package:battle_backend/battle_backend.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:end_battle/main.dart' as function;
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
  group('end_battle function', () {
    test('UNIT-30 carries over the battle whose row was updated', () async {
      final wars = Wars(
        rows: MemoryRows(),
        admins: _Admins(),
        data: function.planData,
      );
      await wars.create(caller: 'admin', warId: 'w-1');
      await wars.plan(
        caller: 'admin',
        warId: 'w-1',
        battleId: 'b-1',
        mapId: 'valley',
        seed: 1,
      );

      expect(await function.respond(_as('', {r'$id': 'b-1'}), wars), {
        'carried': false,
      });
    });

    test('answers 400 to an update that names no battle', () async {
      final event = _Context(const {'status': 'ended'});
      await function.main(event);
      expect(event.res.status, 400);
    });

    test('runs on the tables of its project', () {
      expect(function.appwriteWars(Client()).rows, isA<AppwriteRows>());
    });
  });
}
