import 'dart:io';

import 'package:battle_backend/battle_backend.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// The API keys on the tables of the project of [client].
ApiKeys appwriteKeys(Client client) => ApiKeys(
  rows: AppwriteRows(TablesDB(client)),
  admins: AppwriteAdmins(Users(client)),
);

/// Answers [execution] with [keys]: a new key for the caller (`create`),
/// shown once, or the revocation of the key of `accountId`, the caller's
/// by default (`revoke`).
Future<Json> respond(Execution execution, ApiKeys keys) async {
  final Execution(:caller, :body) = execution;
  switch (textOf(body, 'action')) {
    case 'create':
      return {'key': await keys.create(caller: caller)};
    case 'revoke':
      final account = body is Map<String, Object?>
          ? body['accountId'] as String? ?? caller
          : caller;
      await keys.revoke(caller: caller, accountId: account);
      return {'revoked': account};
    default:
      throw const Refused('unknown_action', status: 400);
  }
}

/// Appwrite Function entry point (AI-04, decisions 158, 161).
Future<dynamic> main(dynamic context) => serve(
  context,
  Platform.environment,
  (execution) => respond(execution, appwriteKeys(execution.client)),
);
