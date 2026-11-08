import 'package:battle_backend/battle_backend.dart';
import 'package:battle_host/main.dart' as function;
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:hawkbee_schema/hawkbee_schema.dart';
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
  final logs = <String>[];

  void log(String message) => logs.add(message);
}

final class _Admins implements Admins {
  @override
  Future<bool> isAdmin(String accountId) async => false;
}

Execution _as(String caller, Object? body) =>
    Execution(caller: caller, body: body, client: Client());

void main() {
  group('battle_host function', () {
    late MemoryRows rows;
    late BattleHosts hosts;

    setUp(() async {
      rows = MemoryRows();
      hosts = BattleHosts(
        rows: rows,
        keys: ApiKeys(rows: rows, admins: _Admins()),
      );
      await rows.put(
        AppwriteIds.battlesTableId,
        'b-1',
        const BattleRow(
          id: 'b-1',
          warId: 'w-1',
          mapId: 'saint_lo',
          seed: 1,
          status: BattleStatus.running,
          teams: {
            't-1': ['s-1'],
          },
          host: 'host-a',
        ).toData(),
      );
      await rows.put(
        AppwriteIds.sectionsTableId,
        's-1',
        const SectionRow(
          id: 's-1',
          warId: 'w-1',
          accountId: 'p-1',
          kept: KeptSection(money: 0, xp: 0),
        ).toData(),
      );
      await rows.put(
        AppwriteIds.hostsTableId,
        'host-a',
        HostRow(
          address: 'http://host-a:8080',
          seenAt: DateTime.utc(2026, 11, 8),
        ).toData(),
      );
    });

    test('M6 Issue 6 a player gets the address of their battle', () async {
      expect(await function.respond(_as('p-1', {'battle': 'b-1'}), hosts), {
        'address': 'http://host-a:8080',
      });
    });

    test('AI-04 an agent gets it with the key in the body', () async {
      final key = await hosts.keys.create(caller: 'p-1');

      expect(
        await function.respond(_as('', {'battle': 'b-1', 'key': key}), hosts),
        {'address': 'http://host-a:8080'},
      );
      expect(
        () => function.respond(_as('', {'battle': 'b-1', 'key': 3}), hosts),
        throwsA(isA<Refused>()),
      );
    });

    test('anyone may call it; without a battle it answers 400', () async {
      final nobody = _Context({'key': 'btk_secret'});
      await function.main(nobody);

      expect(nobody.res.status, 400);
      expect(nobody.logs.join(), isNot(contains('btk_secret')));
    });

    test('runs on the tables of its project', () {
      expect(function.appwriteHosts(Client()).rows, isA<AppwriteRows>());
    });
  });
}
