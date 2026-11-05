import 'package:equatable/equatable.dart';

/// The target type of an HQ in an attack's impact: a kill of it is no unit
/// kill.
const hqTargetType = 'hq';

/// The kinds of action the statistics count, one medal track each
/// (`medals.yaml` `actions.kinds`, SOC-26).
abstract final class ActionKind {
  /// A hit on an enemy unit.
  static const hit = 'hit';

  /// A construction finished.
  static const build = 'build';

  /// A repair finished.
  static const repair = 'repair';

  /// A heal.
  static const heal = 'heal';

  /// AP put into a capture pot.
  static const capture = 'capture';

  /// An observation started.
  static const observe = 'observe';

  /// AP put into a push pot.
  static const push = 'push';

  /// A hit on an enemy HQ.
  static const hqHit = 'hq_hit';

  /// An enemy unit taken prisoner (COMBAT-38).
  static const prisonerTaken = 'prisoner_taken';

  /// An enemy unit turned (COMBAT-38).
  static const defectionCaused = 'defection_caused';
}

/// Why a section lost a unit (decision 74).
enum Loss {
  /// Killed by a shot.
  killed,

  /// Taken prisoner.
  prisoner,

  /// Turned to the attacker's section.
  defected,

  /// Crushed by a relic.
  crushed,
}

/// {@template shots}
/// Shots [fired], of which [hits] hit.
/// {@endtemplate}
final class Shots extends Equatable {
  /// {@macro shots}
  const new({this.fired = 0, this.hits = 0});

  /// Shots fired.
  final int fired;

  /// Shots that hit.
  final int hits;

  /// The share of shots that hit; 0 when none was fired.
  double get rate => fired == 0 ? 0 : hits / fired;

  /// These shots and [other].
  Shots operator +(Shots other) =>
      Shots(fired: fired + other.fired, hits: hits + other.hits);

  @override
  List<Object?> get props => [fired, hits];
}

/// {@template stats}
/// What a unit, a section or a player did over a stretch of battles
/// (SOC-22, decisions 74, 143): its enemy kills and its friendly kills by
/// target type, its actions by kind, its losses by cause and its shots by
/// weapon. A section's and a player's add those of their units.
/// {@endtemplate}
final class Stats extends Equatable {
  /// {@macro stats}
  new({
    Map<String, int> kills = const {},
    Map<String, int> friendlyKills = const {},
    Map<String, int> actions = const {},
    Map<Loss, int> losses = const {},
    Map<String, Shots> shots = const {},
  }) : kills = Map.unmodifiable(kills),
       friendlyKills = Map.unmodifiable(friendlyKills),
       actions = Map.unmodifiable(actions),
       losses = Map.unmodifiable(losses),
       shots = Map.unmodifiable(shots);

  /// The stats [json] holds, as [toJson] writes them.
  ///
  /// Throws a [FormatException] for anything else.
  factory fromJson(Map<String, Object?> json) {
    Map<String, int> counts(String key) => {
      for (final MapEntry(key: name, :value) in _map(json[key], key).entries)
        name: _count(value, '$key.$name'),
    };
    return Stats(
      kills: counts('kills'),
      friendlyKills: counts('friendly_kills'),
      actions: counts('actions'),
      losses: {
        for (final MapEntry(key: name, :value) in counts('losses').entries)
          Loss.values.asNameMap()[name] ??
                  (throw FormatException('not a loss: $name')):
              value,
      },
      shots: {
        for (final MapEntry(key: weapon, :value) in _map(
          json['shots'],
          'shots',
        ).entries)
          weapon: switch (value) {
            [final int fired, final int hits] => Shots(
              fired: fired,
              hits: hits,
            ),
            _ => throw FormatException('not shots: shots.$weapon'),
          },
      },
    );
  }

  /// The sum of [all].
  factory sum(Iterable<Stats> all) => all.fold(Stats(), (sum, s) => sum + s);

  /// Enemy kills by target type: a unit type, or [hqTargetType].
  final Map<String, int> kills;

  /// Kills of the attacker's own team by target type (COMBAT-35).
  final Map<String, int> friendlyKills;

  /// Actions by kind ([ActionKind]).
  final Map<String, int> actions;

  /// Units lost by cause.
  final Map<Loss, int> losses;

  /// Shots by weapon.
  final Map<String, Shots> shots;

  /// Every friendly kill.
  int get friendlyKillCount =>
      friendlyKills.values.fold(0, (sum, count) => sum + count);

  /// These stats and [other] added.
  Stats operator +(Stats other) => Stats(
    kills: _add(kills, other.kills),
    friendlyKills: _add(friendlyKills, other.friendlyKills),
    actions: _add(actions, other.actions),
    losses: _add(losses, other.losses),
    shots: {
      ...shots,
      for (final MapEntry(key: weapon, :value) in other.shots.entries)
        weapon: (shots[weapon] ?? const Shots()) + value,
    },
  );

  /// These stats as JSON values: [Stats.fromJson] reads them back.
  Map<String, Object> toJson() => {
    'kills': kills,
    'friendly_kills': friendlyKills,
    'actions': actions,
    'losses': {
      for (final MapEntry(:key, :value) in losses.entries) key.name: value,
    },
    'shots': {
      for (final MapEntry(:key, :value) in shots.entries)
        key: [value.fired, value.hits],
    },
  };

  @override
  List<Object?> get props => [kills, friendlyKills, actions, losses, shots];

  static Map<K, int> _add<K>(Map<K, int> a, Map<K, int> b) => {
    ...a,
    for (final MapEntry(:key, :value) in b.entries) key: (a[key] ?? 0) + value,
  };

  static Map<String, Object?> _map(Object? value, String key) =>
      value is Map<String, Object?>
      ? value
      : throw FormatException('not a map: $key');

  static int _count(Object? value, String key) =>
      value is int ? value : throw FormatException('not a count: $key');
}
