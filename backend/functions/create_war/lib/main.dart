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

/// Answers [execution] with [wars]: an admin creates a war (`create`, with
/// `warId` and `minStartingMoney`), a player joins one (`join`, `warId`).
Future<Json> respond(Execution execution, Wars wars) async {
  final Execution(:caller, :body) = execution;
  return switch (textOf(body, 'action')) {
    'create' => (await wars.create(
      caller: caller,
      warId: textOf(body, 'warId'),
      minStartingMoney: integerOf(body, 'minStartingMoney'),
    )).toData(),
    'join' => {
      'sectionId': (await wars.join(
        caller: caller,
        warId: textOf(body, 'warId'),
      )).id,
    },
    _ => throw const Refused('unknown_action', status: 400),
  };
}

/// Appwrite Function entry point (SOC-16, SOC-30).
Future<dynamic> main(dynamic context) => serve(
  context,
  Platform.environment,
  (execution) => respond(execution, appwriteWars(execution.client)),
);
