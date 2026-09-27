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
  });
}
