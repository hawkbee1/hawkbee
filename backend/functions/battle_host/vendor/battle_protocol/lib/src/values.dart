import 'package:equatable/equatable.dart';

/// {@template position}
/// A point of the map in centimetres: [xCm] east, [yCm] south (rows grow
/// toward the south, as in the map grid) and [zCm] up, from the map's
/// origin. Positions are quantised to the centimetre (stack decision 3), so
/// the binary and the JSON encodings carry the same value.
/// {@endtemplate}
final class Position extends Equatable {
  /// {@macro position}
  const new(this.xCm, this.yCm, this.zCm);

  /// The position at [x], [y] and [z] metres, rounded to the centimetre.
  ///
  /// Throws an [ArgumentError] for a value that is not finite.
  factory metres(double x, double y, double z) =>
      Position(_quantise(x, 100), _quantise(y, 100), _quantise(z, 100));

  /// Centimetres east of the origin.
  final int xCm;

  /// Centimetres south of the origin.
  final int yCm;

  /// Centimetres above the origin.
  final int zCm;

  /// Metres east of the origin.
  double get x => xCm / 100;

  /// Metres south of the origin.
  double get y => yCm / 100;

  /// Metres above the origin.
  double get z => zCm / 100;

  @override
  List<Object?> get props => [xCm, yCm, zCm];
}

/// {@template direction}
/// A direction in the axes of [Position], in millionths: [xMicro],
/// [yMicro] and [zMicro]. It need not be of unit length; the host
/// normalises it and refuses a zero direction. A millionth gives an aim
/// within about 2 mm at 2 km.
/// {@endtemplate}
final class Direction extends Equatable {
  /// {@macro direction}
  const new(this.xMicro, this.yMicro, this.zMicro);

  /// The direction of the vector ([x], [y], [z]), rounded to the
  /// millionth.
  ///
  /// Throws an [ArgumentError] for a value that is not finite.
  factory of(double x, double y, double z) => Direction(
    _quantise(x, 1000000),
    _quantise(y, 1000000),
    _quantise(z, 1000000),
  );

  /// The east component, in millionths.
  final int xMicro;

  /// The south component, in millionths.
  final int yMicro;

  /// The up component, in millionths.
  final int zMicro;

  /// The east component.
  double get x => xMicro / 1000000;

  /// The south component.
  double get y => yMicro / 1000000;

  /// The up component.
  double get z => zMicro / 1000000;

  @override
  List<Object?> get props => [xMicro, yMicro, zMicro];
}

int _quantise(double value, int perUnit) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, 'value', 'must be finite');
  }
  return (value * perUnit).round();
}

/// {@template cell}
/// A cell of the map grid: column [x] from the west, row [y] from the
/// north, on the ground or on the floating [island] of that name (the
/// `[x, y]` and `[x, y, island]` cells of the map format).
/// {@endtemplate}
final class Cell extends Equatable {
  /// {@macro cell}
  const new(this.x, this.y, {this.island});

  /// The column.
  final int x;

  /// The row.
  final int y;

  /// The floating island; null on the ground.
  final String? island;

  @override
  List<Object?> get props => [x, y, island];
}

/// Who acted (AI-05, decisions 162 and 166). The host sets it from how the
/// sender signed in: a player's session, an API key, or the server's own
/// identity for its sections.
enum Origin {
  /// A player, through a session.
  player,

  /// An AI agent, through the account's API key.
  ai,

  /// The server, for the sections it runs.
  server,
}

/// {@template sender}
/// Who sends a command: the account [accountId] and its section
/// [sectionId] in the battle.
/// {@endtemplate}
final class Sender extends Equatable {
  /// {@macro sender}
  const new({required this.accountId, required this.sectionId});

  /// The account.
  final String accountId;

  /// The account's section in this battle.
  final String sectionId;

  @override
  List<Object?> get props => [accountId, sectionId];
}
