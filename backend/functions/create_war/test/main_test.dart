import 'package:battle_backend/battle_backend.dart';
import 'package:create_war/main.dart' as function;
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
  late Wars wars;

  setUp(
    () => wars = Wars(
      rows: MemoryRows(),
      admins: _Admins(),
      data: function.planData,
    ),
  );

  group('create_war function', () {
    test('SOC-16 an admin creates a war', () async {
      final war = await function.respond(
        _as('admin', {'action': 'create', 'warId': 'w-1'}),
        wars,
      );

      expect(war['min_starting_money'], 500);
    });

    test('SOC-30 a player joins it', () async {
      await wars.create(caller: 'admin', warId: 'w-1');

      final joined = await function.respond(
        _as('p-1', {'action': 'join', 'warId': 'w-1'}),
        wars,
      );

      expect(joined['sectionId'], sectionIdOf('w-1', 'p-1'));
    });

    test('answers 401 to nobody and 400 to an unknown action', () async {
      final nobody = _Context({'action': 'create'});
      await function.main(nobody);
      expect(nobody.res.status, 401);

      final unknown = _Context({'action': 'win'}, caller: 'p-1');
      await function.main(unknown);
      expect(unknown.res.status, 400);
    });

    test('runs on the tables of its project', () {
      expect(function.appwriteWars(Client()).rows, isA<AppwriteRows>());
    });
  });
}
