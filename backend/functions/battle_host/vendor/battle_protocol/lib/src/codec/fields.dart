import 'package:battle_protocol/src/values.dart';

/// The version of the format every encoding writes and the only one the
/// decoders read. A change that breaks the committed samples needs a new
/// version (stack decision 2).
const protocolVersion = 1;

/// The largest varint the format carries: the largest integer a
/// JavaScript number holds exactly, so the web client reads what the host
/// wrote.
const maxWireInt = 9007199254740991;

/// The largest integer field: its zigzag form stays within [maxWireInt].
const maxFieldInt = 4503599627370495;

/// The smallest integer field.
const minFieldInt = -4503599627370496;

/// Throws an [ArgumentError] when [value] is outside the integers the
/// format carries, from [minFieldInt] to [maxFieldInt].
void checkWireInt(int value) {
  if (value < minFieldInt || value > maxFieldInt) {
    throw ArgumentError.value(value, 'value', 'out of the wire range');
  }
}

/// {@template protocol_exception}
/// Input that is not a valid message of the format: truncated, of another
/// version, with an unknown type, a missing or extra field, a value of the
/// wrong kind. Decoders throw nothing else for bad input.
/// {@endtemplate}
final class ProtocolException implements Exception {
  /// {@macro protocol_exception}
  const new(this.message);

  /// What is wrong, and where.
  final String message;

  @override
  String toString() => 'ProtocolException: $message';
}

/// {@template unsupported_version_exception}
/// A message of a format [version] the decoders do not read: the host
/// answers a client that speaks it with a goodbye.
/// {@endtemplate}
final class UnsupportedVersionException extends ProtocolException {
  /// {@macro unsupported_version_exception}
  new(this.version) : super('unsupported version $version');

  /// The version of the message.
  final int version;
}

/// Where a message writes its fields, by name and in order: the binary
/// writer keeps the order and drops the names, the JSON writer keeps the
/// names (Strategy, stack decision 7). Each message lists its fields once,
/// so both encodings carry the same ones.
abstract interface class FieldWriter {
  /// A whole number.
  void integer(String key, int value);

  /// A finite floating-point number, written exactly.
  void number(String key, double value);

  /// A string.
  void text(String key, String value);

  /// A boolean.
  void flag(String key, {required bool value});

  /// A battle time or a duration, to the microsecond.
  void time(String key, Duration value);

  /// A value of an enum.
  void choice(String key, Enum value);

  /// A position.
  void position(String key, Position value);

  /// A direction.
  void direction(String key, Direction value);

  /// A list of strings.
  void texts(String key, List<String> values);

  /// A list of cells.
  void cells(String key, List<Cell> values);

  /// A nested message, whose fields [write] writes.
  void item<T>(String key, T value, void Function(FieldWriter, T) write);

  /// A list of nested messages.
  void items<T>(
    String key,
    List<T> values,
    void Function(FieldWriter, T) write,
  );

  /// An optional field: [write] writes [value] under [key] when it is not
  /// null.
  void maybe<T extends Object>(
    String key,
    T? value,
    void Function(FieldWriter, String, T) write,
  );
}

/// Reads the fields a [FieldWriter] wrote, in the same order. Every method
/// throws a [ProtocolException] for bad input.
abstract interface class FieldReader {
  /// A whole number.
  int integer(String key);

  /// A finite floating-point number.
  double number(String key);

  /// A string.
  String text(String key);

  /// A boolean.
  bool flag(String key);

  /// A battle time or a duration.
  Duration time(String key);

  /// A value of the enum whose values are [values].
  T choice<T extends Enum>(String key, List<T> values);

  /// A position.
  Position position(String key);

  /// A direction.
  Direction direction(String key);

  /// A list of strings.
  List<String> texts(String key);

  /// A list of cells.
  List<Cell> cells(String key);

  /// A nested message, which [read] reads.
  T item<T>(String key, T Function(FieldReader) read);

  /// A list of nested messages.
  List<T> items<T>(String key, T Function(FieldReader) read);

  /// An optional field; null when it is absent.
  T? maybe<T extends Object>(String key, T Function(FieldReader, String) read);
}
