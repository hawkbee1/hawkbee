import 'dart:io';

import 'package:battle_backend/battle_backend.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// Where the battles' hosts are, on the tables of the project of [client].
BattleHosts appwriteHosts(Client client) {
  final rows = AppwriteRows(TablesDB(client));
  return BattleHosts(
    rows: rows,
    keys: ApiKeys(rows: rows, admins: AppwriteAdmins(Users(client))),
  );
}

/// Answers [execution] with [hosts]: the address of the host of the battle
/// `battle`, for the signed-in caller or the account of the API key `key`.
/// The key comes in the body, which Appwrite does not keep with the
/// execution, and is never logged.
Future<Json> respond(Execution execution, BattleHosts hosts) async {
  final Execution(:caller, :body) = execution;
  final key = body is Map<String, Object?> ? body['key'] : null;
  return {
    'address': await hosts.addressOf(
      battleId: textOf(body, 'battle'),
      caller: caller,
      key: key is String ? key : null,
    ),
  };
}

/// Appwrite Function entry point (M6 Issue 6): anyone may execute it, a
/// player with their session or JWT, an AI agent with its key.
Future<dynamic> main(dynamic context) => serve(
  context,
  Platform.environment,
  (execution) => respond(execution, appwriteHosts(execution.client)),
  anyone: true,
);
