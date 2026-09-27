// The Open Runtimes Dart executor passes an untyped `context`.
// ignore_for_file: avoid_dynamic_calls
import 'package:hawkbee_schema/hawkbee_schema.dart';

/// Body returned by every successful execution.
Map<String, Object> pingResponse() => {
  'status': 'ok',
  'databaseId': AppwriteIds.databaseId,
};

/// Appwrite Function entry point.
Future<dynamic> main(dynamic context) async {
  context.log('ping: ${context.req.method} ${context.req.path}');
  return context.res.json(pingResponse());
}
