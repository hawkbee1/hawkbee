// The Open Runtimes Dart executor passes an untyped `context`.
// ignore_for_file: avoid_dynamic_calls
import 'dart:io';

import 'package:battle_rules/battle_rules.dart';
import 'package:daily_stats/src/appwrite_stores.dart';
import 'package:daily_stats/src/daily_stats.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:plan_data/plan_data.dart';

/// The run of [body], `{"battleId": …, "warId": …}`, on the [DailyStats]
/// that [daily] makes; a body that names no battle and war is answered
/// with 400.
Future<(int, Map<String, Object>)> respond(
  Object? body,
  DailyStats Function() daily,
) async {
  if (body case {
    'battleId': final String battleId,
    'warId': final String warId,
  }) {
    final report = await daily().run(battleId: battleId, warId: warId);
    return (200, {'battleId': battleId, ...report.toJson()});
  }
  return (400, {'error': 'the body names no battleId and warId'});
}

/// The run on the project of [environment], with the API key of the
/// execution, [key].
DailyStats appwriteDailyStats(Map<String, String> environment, String key) {
  final client = Client()
      .setEndpoint(environment['APPWRITE_FUNCTION_API_ENDPOINT']!)
      .setProject(environment['APPWRITE_FUNCTION_PROJECT_ID']!)
      .setKey(key);
  return DailyStats(
    logs: AppwriteLogReader(Storage(client)),
    store: AppwriteStatsStore(TablesDB(client)),
    medals: MedalsData.parse(medalsYaml),
  );
}

/// Answers the execution of [context] on the project of [environment],
/// with the run [make] gives for it.
Future<dynamic> handle(
  dynamic context,
  Map<String, String> environment, {
  DailyStats Function(Map<String, String>, String) make = appwriteDailyStats,
}) async {
  final key = context.req.headers['x-appwrite-key'] as String? ?? '';
  final (status, body) = await respond(
    context.req.bodyJson,
    () => make(environment, key),
  );
  context.log('daily_stats: $status $body');
  return context.res.json(body, status);
}

/// Appwrite Function entry point: one battle of a war, run daily with the
/// battle and its war in the body (decision 143, stack decision 8).
Future<dynamic> main(dynamic context) => handle(context, Platform.environment);
