import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:battle_protocol/battle_protocol.dart';
import 'package:battle_stats/battle_stats.dart';
import 'package:crypto/crypto.dart';
import 'package:daily_stats/src/daily_stats.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:hawkbee_schema/hawkbee_schema.dart';

/// {@template appwrite_log_reader}
/// A battle's uploaded log in Appwrite Storage (Adapter): the batches the
/// simulation host uploads, one gzipped log file each, named after the
/// battle and the position of their first entry on 12 digits. It follows
/// them by ID from position 0 until one is missing.
/// {@endtemplate}
final class AppwriteLogReader implements LogReader {
  /// {@macro appwrite_log_reader}
  const new(this.storage);

  /// The Storage service of a server client.
  final Storage storage;

  static const _codec = BinaryProtocolCodec();

  @override
  Future<List<LogEntry>> read(String battleId) async {
    final entries = <LogEntry>[];
    while (true) {
      final Uint8List data;
      try {
        data = await storage.getFileDownload(
          bucketId: AppwriteIds.battleLogsBucketId,
          fileId: '$battleId-${entries.length.toString().padLeft(12, '0')}',
        );
      } on AppwriteException catch (error) {
        if (error.code == 404) return entries;
        rethrow;
      }
      final batch = _codec.decodeLog(Uint8List.fromList(gzip.decode(data)));
      if (batch.isEmpty) return entries;
      entries.addAll(batch);
    }
  }
}

/// {@template appwrite_stats_store}
/// The results in Appwrite tables (Adapter): `stats`, `medals` and
/// `hit_rate_flags` of `backend/appwrite.config.json`. A row's ID is a hash
/// of its key, so writing it again replaces it.
/// {@endtemplate}
final class AppwriteStatsStore implements StatsStore {
  /// {@macro appwrite_stats_store}
  const new(this.tables);

  /// The TablesDB service of a server client.
  final TablesDB tables;

  /// The ID of the row of [key]: 32 hexadecimal digits.
  static String rowId(List<Object?> key) =>
      sha256.convert(utf8.encode(jsonEncode(key))).toString().substring(0, 32);

  Future<void> _upsert(
    String table,
    List<Object?> key,
    Map<String, Object?> data,
  ) => tables.upsertRow(
    databaseId: AppwriteIds.databaseId,
    tableId: table,
    rowId: rowId([table, ...key]),
    data: data,
  );

  @override
  Future<void> putStats(StatsRow row) => _upsert(
    AppwriteIds.statsTableId,
    [row.scope.name, row.scopeId, row.subject.name, row.subjectId],
    {
      'scope': row.scope.name,
      'scope_id': row.scopeId,
      'war_id': row.warId,
      'subject': row.subject.name,
      'subject_id': row.subjectId,
      'stats': jsonEncode(row.stats.toJson()),
    },
  );

  @override
  Future<List<StatsRow>> findStats({
    required StatsScope scope,
    String? warId,
    StatsSubject? subject,
    String? subjectId,
  }) async {
    final found = <StatsRow>[];
    final filters = [
      Query.equal('scope', scope.name),
      if (warId != null) Query.equal('war_id', warId),
      if (subject != null) Query.equal('subject', subject.name),
      if (subjectId != null) Query.equal('subject_id', subjectId),
    ];
    String? after;
    while (true) {
      final page = await tables.listRows(
        databaseId: AppwriteIds.databaseId,
        tableId: AppwriteIds.statsTableId,
        queries: [
          ...filters,
          Query.limit(100),
          if (after != null) Query.cursorAfter(after),
        ],
      );
      for (final row in page.rows) {
        final data = row.data;
        found.add(
          StatsRow(
            scope: StatsScope.values.byName(data['scope'] as String),
            scopeId: data['scope_id'] as String,
            warId: data['war_id'] as String?,
            subject: StatsSubject.values.byName(data['subject'] as String),
            subjectId: data['subject_id'] as String,
            stats: Stats.fromJson(
              jsonDecode(data['stats'] as String) as Map<String, Object?>,
            ),
          ),
        );
      }
      if (page.rows.length < 100) return found;
      after = page.rows.last.$id;
    }
  }

  @override
  Future<void> putMedal({
    required String accountId,
    required Medal medal,
    String? warId,
  }) => _upsert(
    AppwriteIds.medalsTableId,
    [accountId, warId, medal.track, medal.tier],
    {
      'account_id': accountId,
      'war_id': warId,
      'track': medal.track,
      'tier': medal.tier,
    },
  );

  @override
  Future<void> putFlag(String battleId, FlaggedHitRate flag) => _upsert(
    AppwriteIds.hitRateFlagsTableId,
    [battleId, flag.day, flag.accountId, flag.weapon],
    {
      'battle_id': battleId,
      'day': flag.day,
      'account_id': flag.accountId,
      'weapon': flag.weapon,
      'fired': flag.shots.fired,
      'hits': flag.shots.hits,
      'mean': flag.mean,
      'sigma': flag.sigma,
    },
  );
}
