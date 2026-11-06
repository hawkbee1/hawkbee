import 'package:battle_protocol/battle_protocol.dart';
import 'package:battle_rules/battle_rules.dart';
import 'package:battle_stats/battle_stats.dart';

/// What a statistics row is about: a battle, a war or the game.
enum StatsScope {
  /// One battle.
  battle,

  /// One war: its battles added up.
  war,

  /// The game: a player's wars added up.
  game,
}

/// Whose a statistics row is.
enum StatsSubject {
  /// A unit.
  unit,

  /// A section.
  section,

  /// A player.
  player,
}

/// {@template stats_row}
/// The [stats] of [subjectId], a [subject], over [scopeId], a [scope]; a
/// battle's and a war's rows name their war [warId].
/// {@endtemplate}
final class StatsRow {
  /// {@macro stats_row}
  const new({
    required this.scope,
    required this.scopeId,
    required this.subject,
    required this.subjectId,
    required this.stats,
    this.warId,
  });

  /// What it is about.
  final StatsScope scope;

  /// The battle, the war, or `game`.
  final String scopeId;

  /// Whose it is.
  final StatsSubject subject;

  /// The unit, section or account.
  final String subjectId;

  /// The stats.
  final Stats stats;

  /// The war of a battle's or a war's row.
  final String? warId;
}

/// Where the uploaded log of a battle is read (a port).
abstract interface class LogReader {
  /// The whole log of [battleId], from its start.
  Future<List<LogEntry>> read(String battleId);
}

/// Where the results go (a port). Each write replaces the row of the same
/// key, so a run made again writes the same rows.
abstract interface class StatsStore {
  /// Writes [row].
  Future<void> putStats(StatsRow row);

  /// The rows of [scope] with the values given.
  Future<List<StatsRow>> findStats({
    required StatsScope scope,
    String? warId,
    StatsSubject? subject,
    String? subjectId,
  });

  /// Writes the [medal] of [accountId]: a war medal of [warId], or a game
  /// medal when it is null. A medal written stays.
  Future<void> putMedal({
    required String accountId,
    required Medal medal,
    String? warId,
  });

  /// Writes the [flag] of [battleId].
  Future<void> putFlag(String battleId, FlaggedHitRate flag);
}

/// {@template daily_report}
/// What a run wrote.
/// {@endtemplate}
final class DailyReport {
  /// {@macro daily_report}
  const new({
    required this.entries,
    required this.rows,
    required this.medals,
    required this.flags,
  });

  /// The log entries read.
  final int entries;

  /// The statistics rows written.
  final int rows;

  /// The medals written.
  final int medals;

  /// The hit-rate flags written.
  final int flags;

  /// This report as JSON values.
  Map<String, int> toJson() => {
    'entries': entries,
    'rows': rows,
    'medals': medals,
    'flags': flags,
  };
}

/// {@template daily_stats}
/// The daily run of one battle of a war (decision 143, stack decision 8):
/// it reads the battle's log, writes the battle's statistics per unit,
/// section and player, adds up the war's battles and each player's wars,
/// writes the war and game medals they reach (SOC-24 to SOC-26) and the
/// hit rates far above the norm of each battle-day (decision 230).
///
/// It reads the whole log each time and replaces its rows, so a run made
/// again, or a missed day, gives the same results.
/// {@endtemplate}
final class DailyStats {
  /// {@macro daily_stats}
  new({required this.logs, required this.store, required MedalsData medals})
    : _medals = MedalRules(medals),
      _flags = HitRateFlags(medals.hitRateFlag);

  /// Where the logs are read.
  final LogReader logs;

  /// Where the results go.
  final StatsStore store;

  final MedalRules _medals;
  final HitRateFlags _flags;

  /// Runs on [battleId], a battle of [warId].
  Future<DailyReport> run({
    required String battleId,
    required String warId,
  }) async {
    final entries = await logs.read(battleId);
    final tally = BattleTally()..addAll(entries);
    var rows = 0;
    Future<void> put(StatsRow row) async {
      await store.putStats(row);
      rows++;
    }

    for (final (subject, all) in [
      (StatsSubject.unit, tally.units),
      (StatsSubject.section, tally.sections),
      (StatsSubject.player, tally.players),
    ]) {
      for (final MapEntry(key: id, value: stats) in all.entries) {
        await put(
          StatsRow(
            scope: StatsScope.battle,
            scopeId: battleId,
            warId: warId,
            subject: subject,
            subjectId: id,
            stats: stats,
          ),
        );
      }
    }

    final war = <(StatsSubject, String), List<Stats>>{};
    for (final row in await store.findStats(
      scope: StatsScope.battle,
      warId: warId,
    )) {
      (war[(row.subject, row.subjectId)] ??= []).add(row.stats);
    }
    final warStats = <String, Stats>{};
    for (final MapEntry(key: (subject, id), value: all) in war.entries) {
      final stats = Stats.sum(all);
      if (subject == StatsSubject.player) warStats[id] = stats;
      await put(
        StatsRow(
          scope: StatsScope.war,
          scopeId: warId,
          warId: warId,
          subject: subject,
          subjectId: id,
          stats: stats,
        ),
      );
    }

    var medals = 0;
    for (final account in tally.players.keys) {
      final game = Stats.sum([
        for (final row in await store.findStats(
          scope: StatsScope.war,
          subject: StatsSubject.player,
          subjectId: account,
        ))
          row.stats,
      ]);
      await put(
        StatsRow(
          scope: StatsScope.game,
          scopeId: 'game',
          subject: StatsSubject.player,
          subjectId: account,
          stats: game,
        ),
      );
      for (final (warOf, stats) in [
        (warId, warStats[account]!),
        (null, game),
      ]) {
        for (final medal in _medals.of(stats)) {
          await store.putMedal(accountId: account, warId: warOf, medal: medal);
          medals++;
        }
      }
    }

    var flags = 0;
    for (final day in tally.aimedDays) {
      for (final flag in _flags.of(day, tally.aimedShotsOn(day))) {
        await store.putFlag(battleId, flag);
        flags++;
      }
    }
    return DailyReport(
      entries: entries.length,
      rows: rows,
      medals: medals,
      flags: flags,
    );
  }
}
