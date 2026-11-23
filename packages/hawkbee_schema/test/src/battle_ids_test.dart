import 'package:hawkbee_schema/hawkbee_schema.dart';
import 'package:test/test.dart';

void main() {
  group('isBattleId', () {
    test('accepts letters, digits, dots, dashes and underscores', () {
      expect(isBattleId('saint-lo-1km-1123-1'), isTrue);
      expect(isBattleId('b.2_x'), isTrue);
      expect(isBattleId('9'), isTrue);
    });

    test('accepts up to maxBattleIdLength characters, not one more', () {
      expect(isBattleId('a' * maxBattleIdLength), isTrue);
      expect(isBattleId('a' * (maxBattleIdLength + 1)), isFalse);
    });

    test('refuses an ID that cannot name a file', () {
      expect(isBattleId(''), isFalse);
      expect(isBattleId('-b'), isFalse);
      expect(isBattleId('../b'), isFalse);
      expect(isBattleId('b 1'), isFalse);
    });
  });
}
