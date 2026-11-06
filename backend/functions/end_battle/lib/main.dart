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

/// Answers [execution], the update of a battle's row, with [wars]: a
/// battle its host ended is carried over (UNIT-30, SOC-17).
Future<Json> respond(Execution execution, Wars wars) async => {
  'carried': await wars.end(textOf(execution.body, r'$id')),
};

/// Appwrite Function entry point, on the update of a battle's row.
Future<dynamic> main(dynamic context) => serve(
  context,
  Platform.environment,
  (execution) => respond(execution, appwriteWars(execution.client)),
  anyone: true,
);
