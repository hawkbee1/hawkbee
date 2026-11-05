import 'dart:io';

import 'package:battle_backend/battle_backend.dart';
import 'package:battle_rules/battle_rules.dart';
import 'package:daily_stats/src/appwrite_stores.dart';
import 'package:daily_stats/src/daily_stats.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:hawkbee_schema/hawkbee_schema.dart';
import 'package:plan_data/plan_data.dart';

/// The run on the project of [client].
DailyStats appwriteDailyStats(Client client) => DailyStats(
  logs: AppwriteLogReader(Storage(client)),
  store: AppwriteStatsStore(TablesDB(client)),
  medals: MedalsData.parse(medalsYaml),
);

/// Answers [execution] with [daily]: the battle `battleId` of the war
/// `warId` when the body names one; otherwise, as the daily schedule, the
/// battles due in [rows] ([runDue]).
Future<Json> respond(Execution execution, DailyStats daily, Rows rows) async {
  final body = execution.body;
  if (body is Map<String, Object?> && body.containsKey('battleId')) {
    final battleId = textOf(body, 'battleId');
    final report = await daily.run(
      battleId: battleId,
      warId: textOf(body, 'warId'),
    );
    return {'battleId': battleId, ...report.toJson()};
  }
  return {'battles': await runDue(rows, daily)};
}

/// Runs [daily] on the battles due (decision 143): every battle running,
/// and every battle ended whose statistics are not final yet, which then
/// are. Gives their IDs.
Future<List<String>> runDue(Rows rows, DailyStats daily) async {
  final done = <String>[];
  for (final status in [
    BattleStatus.running,
    BattleStatus.ended,
    BattleStatus.closed,
  ]) {
    for (final row in await rows.find(AppwriteIds.battlesTableId, {
      'status': status.name,
    })) {
      final battle = BattleRow.fromData(row.id, row.data);
      if (battle.statsDone) continue;
      await daily.run(battleId: battle.id, warId: battle.warId);
      if (status != BattleStatus.running) {
        await rows.put(
          AppwriteIds.battlesTableId,
          battle.id,
          battle.copyWith(statsDone: true).toData(),
        );
      }
      done.add(battle.id);
    }
  }
  return done;
}

/// Appwrite Function entry point: daily on its schedule, or for one battle
/// of a war (decision 143, stack decision 8).
Future<dynamic> main(dynamic context) => serve(
  context,
  Platform.environment,
  (execution) => respond(
    execution,
    appwriteDailyStats(execution.client),
    AppwriteRows(TablesDB(execution.client)),
  ),
  anyone: true,
);
