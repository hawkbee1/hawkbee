import 'package:battle_rules/battle_rules.dart';
import 'package:battle_stats/src/stats.dart';
import 'package:equatable/equatable.dart';

/// {@template medal}
/// A medal: the [tier] reached on a [track] (SOC-26).
/// {@endtemplate}
final class Medal extends Equatable {
  /// {@macro medal}
  const new({required this.track, required this.tier});

  /// The track: `kills.<unit type>`, `actions.<kind>` or `friendly_kills`.
  final String track;

  /// The tier: `bronze`, `silver` or `gold` in the plan.
  final String tier;

  @override
  List<Object?> get props => [track, tier];
}

/// {@template medal_rules}
/// Medals earned at the thresholds of `medals.yaml` (SOC-24 to SOC-26,
/// decisions 105, 231): one track per target unit type of enemy kills, one
/// per kind of action and one of friendly kills, which never count toward a
/// kill medal. Each tier reached is a medal of its own (assumed,
/// Q-SOC-19). The same rules give the war medals, from a player's stats in
/// one war (SOC-24), and the game medals, from all of them (SOC-25).
/// {@endtemplate}
final class MedalRules {
  /// {@macro medal_rules}
  const new(this.medals);

  /// The `medals.yaml` data.
  final MedalsData medals;

  /// The medals [stats] reach, in track order, lowest tier first.
  List<Medal> of(Stats stats) => [
    for (final MapEntry(key: type, value: count) in stats.kills.entries)
      if (type != hqTargetType)
        ..._reached(
          'kills.$type',
          count,
          medals.killThresholds[type] ?? medals.killThresholds['default']!,
        ),
    for (final kind in medals.actionKinds)
      ..._reached(
        'actions.$kind',
        stats.actions[kind] ?? 0,
        medals.actionThresholds,
      ),
    ..._reached(
      'friendly_kills',
      stats.friendlyKillCount,
      medals.friendlyKillThresholds,
    ),
  ];

  /// The medal points of [held] (SOC-29, decision 121).
  int points(Iterable<Medal> held) =>
      held.fold(0, (sum, medal) => sum + medals.points[medal.tier]!);

  List<Medal> _reached(String track, int count, Map<String, int> thresholds) =>
      [
        for (final tier in medals.tiers)
          if (count >= thresholds[tier]!) Medal(track: track, tier: tier),
      ];
}
