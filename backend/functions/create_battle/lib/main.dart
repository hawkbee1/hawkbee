import 'dart:io';

import 'package:battle_backend/battle_backend.dart';
import 'package:battle_rules/battle_rules.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:plan_data/plan_data.dart';

/// The plan's data, vendored.
final planData = GameData.parse(
  units: unitsYaml,
  combat: combatYaml,
  terrain: terrainYaml,
  battle: battleYaml,
  economy: economyYaml,
  medals: medalsYaml,
);

/// The wars on the tables of the project of [client].
Wars appwriteWars(Client client) => Wars(
  rows: AppwriteRows(TablesDB(client)),
  admins: AppwriteAdmins(Users(client)),
  data: planData,
);

/// Answers [execution] with [wars], for an admin: plans a battle (`plan`,
/// with `warId`, `battleId`, `mapId` and `seed`) or starts the next one
/// (`start`, `battleId`).
Future<Json> respond(Execution execution, Wars wars) async {
  final Execution(:caller, :body) = execution;
  final battle = switch (textOf(body, 'action')) {
    'plan' => await wars.plan(
      caller: caller,
      warId: textOf(body, 'warId'),
      battleId: textOf(body, 'battleId'),
      mapId: textOf(body, 'mapId'),
      seed: integerOf(body, 'seed') ?? 0,
    ),
    'start' => await wars.start(
      caller: caller,
      battleId: textOf(body, 'battleId'),
    ),
    _ => throw const Refused('unknown_action', status: 400),
  };
  return battle.toData();
}

/// Appwrite Function entry point (SOC-16, SOC-20).
Future<dynamic> main(dynamic context) => serve(
  context,
  Platform.environment,
  (execution) => respond(execution, appwriteWars(execution.client)),
);
