import 'package:api_keys/main.dart' as function;
import 'package:battle_backend/battle_backend.dart';
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
  group('api_keys function', () {
    late ApiKeys keys;

    setUp(() => keys = ApiKeys(rows: MemoryRows(), admins: _Admins()));

    test('AI-04 a player creates a key, shown once, and revokes it', () async {
      final created = await function.respond(
        _as('p-1', {'action': 'create'}),
        keys,
      );
      final key = created['key']! as String;
      expect(await keys.accountOf(key), 'p-1');

      expect(await function.respond(_as('p-1', {'action': 'revoke'}), keys), {
        'revoked': 'p-1',
      });
      expect(await keys.accountOf(key), isNull);
    });

    test('decision 161 an admin revokes the key of another account', () async {
      await keys.create(caller: 'p-1');

      expect(
        await function.respond(
          _as('admin', {'action': 'revoke', 'accountId': 'p-1'}),
          keys,
        ),
        {'revoked': 'p-1'},
      );
    });

    test('answers 400 to an unknown action', () async {
      final unknown = _Context({'action': 'steal'}, caller: 'p-1');
      await function.main(unknown);
      expect(unknown.res.status, 400);
    });

    test('runs on the tables of its project', () {
      expect(function.appwriteKeys(Client()).rows, isA<AppwriteRows>());
    });
  });
}
