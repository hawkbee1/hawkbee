import 'package:battle_backend/battle_backend.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:guild_requests/main.dart' as function;
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
  group('guild_requests function', () {
    late Guilds guilds;
    late String section;

    setUp(() async {
      final wars = Wars(
        rows: MemoryRows(),
        admins: _Admins(),
        data: function.planData,
      );
      guilds = Guilds(rows: wars.rows, wars: wars);
      await wars.create(caller: 'admin', warId: 'w-1');
      section = (await wars.join(caller: 'p-1', warId: 'w-1')).id;
      await wars.rows.put('sections', section, {
        ...(await wars.rows.get('sections', section))!,
        'kept': '{"money": 500, "xp": 30000, "weapons": [], "units": []}',
      });
    });

    test('SOC-46 a section creates a guild, then disbands it', () async {
      Map<String, Object?> ask(String action) => {
        'action': action,
        'sectionId': section,
        'guildId': 'g-1',
      };

      final created = await function.respond(_as('p-1', ask('create')), guilds);
      final disbanded = await function.respond(
        _as('p-1', ask('disband')),
        guilds,
      );

      expect(created['roles'], contains(section));
      expect(disbanded, {'disbanded': true});
    });

    test('answers 400 to an unknown action', () async {
      final unknown = _Context({'action': 'rule'}, caller: 'p-1');
      await function.main(unknown);
      expect(unknown.res.status, 400);
      expect(
        () => function.respond(
          _as('p-1', {
            'action': 'accept',
            'sectionId': section,
            'guildId': 'g-1',
            'other': 's-2',
          }),
          guilds,
        ),
        throwsA(isA<Refused>()),
      );
    });

    test('runs on the tables of its project', () {
      expect(function.appwriteGuilds(Client()).rows, isA<AppwriteRows>());
    });
  });
}
