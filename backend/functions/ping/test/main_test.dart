import 'package:hawkbee_schema/hawkbee_schema.dart';
import 'package:ping/main.dart' as function;
import 'package:test/test.dart';

class _FakeRequest {
  final method = 'GET';
  final path = '/';
}

class _FakeResponse {
  Object? body;

  Object json(Object data) => body = data;
}

class _FakeContext {
  final req = _FakeRequest();
  final res = _FakeResponse();
  final logs = <String>[];

  void log(String message) => logs.add(message);
}

void main() {
  group('ping function', () {
    test('responds with the ok status and the database ID', () async {
      final context = _FakeContext();

      await function.main(context);

      expect(context.res.body, {
        'status': 'ok',
        'databaseId': AppwriteIds.databaseId,
      });
      expect(context.logs, ['ping: GET /']);
    });
  });
}
