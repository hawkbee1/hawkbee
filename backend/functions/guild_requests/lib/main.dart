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

/// Answers [execution] with [guilds]: the request `action` (a
/// [GuildAction]) of the caller's section `sectionId` on `guildId`, about
/// the section `other` if any.
Future<Json> respond(Execution execution, Guilds guilds) async {
  final Execution(:caller, :body) = execution;
  final action =
      GuildAction.values.asNameMap()[textOf(body, 'action')] ??
      (throw const Refused('unknown_action', status: 400));
  final guild = await guilds.request(
    caller: caller,
    action: action,
    sectionId: textOf(body, 'sectionId'),
    guildId: textOf(body, 'guildId'),
    other: body is Map<String, Object?> ? body['other'] as String? : null,
  );
  return guild?.toData() ?? {'disbanded': true};
}

/// The guilds on the tables of the project of [client].
Guilds appwriteGuilds(Client client) {
  final wars = appwriteWars(client);
  return Guilds(rows: wars.rows, wars: wars);
}

/// Appwrite Function entry point (SOC-46 to SOC-50).
Future<dynamic> main(dynamic context) => serve(
  context,
  Platform.environment,
  (execution) => respond(execution, appwriteGuilds(execution.client)),
);
