import 'dart:math' as math;

import 'package:battle_rules/battle_rules.dart';
import 'package:battle_stats/src/battle_tally.dart';
import 'package:battle_stats/src/stats.dart';
import 'package:equatable/equatable.dart';

/// {@template flagged_hit_rate}
/// A player's hit rate far above the norm, for the moderation tools: the
/// [shots] of [accountId] with [weapon] on the battle-day [day], against
/// the [mean] and standard deviation [sigma] of all players' rates.
/// {@endtemplate}
final class FlaggedHitRate extends Equatable {
  /// {@macro flagged_hit_rate}
  const new({
    required this.day,
    required this.accountId,
    required this.weapon,
    required this.shots,
    required this.mean,
    required this.sigma,
  });

  /// The battle-day, from the battle's start.
  final int day;

  /// The player.
  final String accountId;

  /// The weapon.
  final String weapon;

  /// The player's first-person shots with it that day.
  final Shots shots;

  /// The mean hit rate of the players with that weapon that day.
  final double mean;

  /// Their standard deviation.
  final double sigma;

  @override
  List<Object?> get props => [day, accountId, weapon, shots, mean, sigma];
}

/// {@template hit_rate_flags}
/// Hit rates far above the norm (decision 230): over a battle-day, a
/// player's hit rate with a weapon, on first-person shots, more than
/// `sigmas` standard deviations above the mean of all players with that
/// weapon that day, among the players with at least `min_shots` shots.
/// {@endtemplate}
final class HitRateFlags {
  /// {@macro hit_rate_flags}
  const new(this.flag);

  /// The `hit_rate_flag` of `medals.yaml`.
  final HitRateFlag flag;

  /// The flags of the battle-day [day], from its first-person [shots].
  List<FlaggedHitRate> of(int day, AimedShots shots) {
    final byWeapon = <String, Map<String, Shots>>{};
    for (final MapEntry(key: account, value: weapons) in shots.entries) {
      for (final MapEntry(key: weapon, value: fired) in weapons.entries) {
        if (fired.fired >= flag.minShots) {
          (byWeapon[weapon] ??= {})[account] = fired;
        }
      }
    }
    return [
      for (final MapEntry(key: weapon, value: players) in byWeapon.entries)
        ..._flagged(day, weapon, players),
    ];
  }

  List<FlaggedHitRate> _flagged(
    int day,
    String weapon,
    Map<String, Shots> players,
  ) {
    final rates = [for (final shots in players.values) shots.rate];
    final mean = rates.reduce((a, b) => a + b) / rates.length;
    final sigma = math.sqrt(
      rates.map((rate) => math.pow(rate - mean, 2)).reduce((a, b) => a + b) /
          rates.length,
    );
    return [
      for (final MapEntry(key: account, value: shots) in players.entries)
        if (shots.rate > mean + flag.sigmas * sigma)
          FlaggedHitRate(
            day: day,
            accountId: account,
            weapon: weapon,
            shots: shots,
            mean: mean,
            sigma: sigma,
          ),
    ];
  }
}
