import 'dart:convert';
import 'dart:io';

import 'package:hawkbee_schema/hawkbee_schema.dart';
import 'package:test/test.dart';

void main() {
  group(AppwriteIds, () {
    late Map<String, dynamic> config;

    setUpAll(() {
      final file = File('../../backend/appwrite.config.json');
      config = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    List<String> idsOf(String key) => [
      for (final resource in config[key] as List<dynamic>)
        (resource as Map<String, dynamic>)[r'$id'] as String,
    ];

    test('databaseId is declared in appwrite.config.json', () {
      expect(idsOf('tablesDB'), contains(AppwriteIds.databaseId));
    });

    test('pingFunctionId is declared in appwrite.config.json', () {
      expect(idsOf('functions'), contains(AppwriteIds.pingFunctionId));
    });

    test('the statistics IDs are declared in appwrite.config.json', () {
      expect(idsOf('functions'), contains(AppwriteIds.dailyStatsFunctionId));
      expect(
        idsOf('buckets'),
        containsAll([
          AppwriteIds.battleLogsBucketId,
          AppwriteIds.battleSnapshotsBucketId,
        ]),
      );
      expect(
        idsOf('tables'),
        containsAll([
          AppwriteIds.statsTableId,
          AppwriteIds.medalsTableId,
          AppwriteIds.hitRateFlagsTableId,
        ]),
      );
    });

    test('the battle IDs are declared in appwrite.config.json', () {
      expect(
        idsOf('tables'),
        containsAll([
          AppwriteIds.warsTableId,
          AppwriteIds.battlesTableId,
          AppwriteIds.sectionsTableId,
          AppwriteIds.guildsTableId,
          AppwriteIds.purchasesTableId,
          AppwriteIds.apiKeysTableId,
        ]),
      );
      expect(
        idsOf('functions'),
        containsAll([
          AppwriteIds.createWarFunctionId,
          AppwriteIds.createBattleFunctionId,
          AppwriteIds.endBattleFunctionId,
          AppwriteIds.guildRequestsFunctionId,
          AppwriteIds.apiKeysFunctionId,
        ]),
      );
    });
  });
}
