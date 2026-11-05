import 'dart:io';

import 'package:battle_protocol/battle_protocol.dart';
import 'package:battle_stats/battle_stats.dart';
import 'package:daily_stats/src/daily_stats.dart';

/// The committed log fixture of `battle_stats`, in the hawkbee checkout.
List<LogEntry> fixtureLog() => const BinaryProtocolCodec().decodeLog(
  File('../../../packages/battle_stats/test/fixtures/battle.log')
      .readAsBytesSync(),
);

/// Logs in memory, by battle.
final class MemoryLogReader implements LogReader {
  new(this.logs);

  final Map<String, List<LogEntry>> logs;

  @override
  Future<List<LogEntry>> read(String battleId) async => logs[battleId] ?? [];
}

/// Results in memory, each keyed as the Appwrite store keys them.
final class MemoryStatsStore implements StatsStore {
  final stats = <(StatsScope, String, StatsSubject, String), StatsRow>{};
  final medals = <(String, String?, Medal)>{};
  final flags = <(String, FlaggedHitRate)>{};

  @override
  Future<void> putStats(StatsRow row) async =>
      stats[(row.scope, row.scopeId, row.subject, row.subjectId)] = row;

  @override
  Future<List<StatsRow>> findStats({
    required StatsScope scope,
    String? warId,
    StatsSubject? subject,
    String? subjectId,
  }) async => [
    for (final row in stats.values)
      if (row.scope == scope &&
          (warId == null || row.warId == warId) &&
          (subject == null || row.subject == subject) &&
          (subjectId == null || row.subjectId == subjectId))
        row,
  ];

  @override
  Future<void> putMedal({
    required String accountId,
    required Medal medal,
    String? warId,
  }) async => medals.add((accountId, warId, medal));

  @override
  Future<void> putFlag(String battleId, FlaggedHitRate flag) async =>
      flags.add((battleId, flag));

  /// The stats of [subjectId], a [subject], over [scopeId], a [scope].
  Stats? of(
    StatsScope scope,
    String scopeId,
    StatsSubject subject,
    String subjectId,
  ) => stats[(scope, scopeId, subject, subjectId)]?.stats;
}
