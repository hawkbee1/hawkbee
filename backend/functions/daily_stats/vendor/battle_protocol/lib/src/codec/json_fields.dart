import 'package:battle_protocol/src/codec/fields.dart';
import 'package:battle_protocol/src/values.dart';

final _capital = RegExp('[A-Z]');

/// The JSON name of an enum value: its Dart name in snake case.
String wireName(Enum value) =>
    value.name.replaceAllMapped(_capital, (m) => '_${m[0]!.toLowerCase()}');

/// {@template json_field_writer}
/// Writes fields under their names into a JSON object. Positions are
/// `[x, y, z]` in metres, directions `[x, y, z]`, cells `[x, y]` or
/// `[x, y, island]`, enum values their snake-case names, times whole
/// microseconds; an absent optional field is left out.
/// {@endtemplate}
final class JsonFieldWriter implements FieldWriter {
  /// {@macro json_field_writer}
  new();

  /// The object written.
  final Map<String, Object?> json = {};

  @override
  void integer(String key, int value) {
    checkWireInt(value);
    json[key] = value;
  }

  @override
  void number(String key, double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, key, 'must be finite');
    }
    json[key] = value;
  }

  @override
  void text(String key, String value) => json[key] = value;

  @override
  void flag(String key, {required bool value}) => json[key] = value;

  @override
  void time(String key, Duration value) => integer(key, value.inMicroseconds);

  @override
  void choice(String key, Enum value) => json[key] = wireName(value);

  @override
  void position(String key, Position value) =>
      json[key] = [value.x, value.y, value.z];

  @override
  void direction(String key, Direction value) =>
      json[key] = [value.x, value.y, value.z];

  static List<Object> _cell(Cell value) {
    checkWireInt(value.x);
    checkWireInt(value.y);
    return [value.x, value.y, ?value.island];
  }

  @override
  void texts(String key, List<String> values) => json[key] = [...values];

  @override
  void cells(String key, List<Cell> values) =>
      json[key] = [for (final value in values) _cell(value)];

  @override
  void item<T>(String key, T value, void Function(FieldWriter, T) write) =>
      json[key] = _object(value, write);

  @override
  void items<T>(
    String key,
    List<T> values,
    void Function(FieldWriter, T) write,
  ) => json[key] = [for (final value in values) _object(value, write)];

  static Map<String, Object?> _object<T>(
    T value,
    void Function(FieldWriter, T) write,
  ) {
    final writer = JsonFieldWriter();
    write(writer, value);
    return writer.json;
  }

  @override
  void maybe<T extends Object>(
    String key,
    T? value,
    void Function(FieldWriter, String, T) write,
  ) {
    if (value != null) write(this, key, value);
  }
}

/// {@template json_field_reader}
/// Reads the fields of a JSON object a [JsonFieldWriter] wrote. A missing
/// field, a value of the wrong kind and, once the object is read
/// ([expectDone]), a field the message does not have are errors; a null
/// optional field counts as absent.
/// {@endtemplate}
final class JsonFieldReader implements FieldReader {
  /// {@macro json_field_reader}
  new(this._json, {this._path = ''});

  final Map<String, Object?> _json;
  final String _path;
  final _read = <String>{};

  /// Throws if the object has a field that was not read.
  void expectDone() {
    for (final key in _json.keys) {
      if (!_read.contains(key)) {
        throw ProtocolException('unknown field $_path$key');
      }
    }
  }

  Object? _take(String key) {
    if (!_json.containsKey(key)) {
      throw ProtocolException('missing field $_path$key');
    }
    _read.add(key);
    return _json[key];
  }

  ProtocolException _wrong(String key, String kind) =>
      ProtocolException('$_path$key is not $kind');

  int _int(String key, Object? value) {
    if (value is! int || value < minFieldInt || value > maxFieldInt) {
      throw _wrong(key, 'an integer in range');
    }
    return value;
  }

  int _scaled(String key, Object? value, int perUnit) {
    if (value is! num || !value.isFinite) throw _wrong(key, 'a number');
    final scaled = value * perUnit;
    if (scaled < minFieldInt || scaled > maxFieldInt) {
      throw _wrong(key, 'a number in range');
    }
    return scaled.round();
  }

  List<Object?> _list(String key, Object? value) {
    if (value is! List<Object?>) throw _wrong(key, 'a list');
    return value;
  }

  @override
  int integer(String key) => _int(key, _take(key));

  @override
  double number(String key) {
    final value = _take(key);
    if (value is! num || !value.isFinite) throw _wrong(key, 'a number');
    return value.toDouble();
  }

  @override
  String text(String key) {
    final value = _take(key);
    if (value is! String) throw _wrong(key, 'a string');
    return value;
  }

  @override
  bool flag(String key) {
    final value = _take(key);
    if (value is! bool) throw _wrong(key, 'a boolean');
    return value;
  }

  @override
  Duration time(String key) => Duration(microseconds: integer(key));

  @override
  T choice<T extends Enum>(String key, List<T> values) {
    final value = _take(key);
    for (final candidate in values) {
      if (wireName(candidate) == value) return candidate;
    }
    throw _wrong(key, 'one of ${values.map(wireName).join(', ')}');
  }

  List<int> _triple(String key, int perUnit) {
    final list = _list(key, _take(key));
    if (list.length != 3) throw _wrong(key, 'a list of 3 numbers');
    return [for (final value in list) _scaled(key, value, perUnit)];
  }

  @override
  Position position(String key) {
    final [x, y, z] = _triple(key, 100);
    return Position(x, y, z);
  }

  @override
  Direction direction(String key) {
    final [x, y, z] = _triple(key, 1000000);
    return Direction(x, y, z);
  }

  Cell _cell(String key, Object? value) {
    final list = _list(key, value);
    return switch (list) {
      [final x, final y] => Cell(_int(key, x), _int(key, y)),
      [final x, final y, final String island] => Cell(
        _int(key, x),
        _int(key, y),
        island: island,
      ),
      _ => throw _wrong(key, 'a cell [x, y] or [x, y, island]'),
    };
  }

  @override
  List<String> texts(String key) {
    final list = _list(key, _take(key));
    if (list.any((value) => value is! String)) {
      throw _wrong(key, 'a list of strings');
    }
    return list.cast<String>().toList(growable: false);
  }

  @override
  List<Cell> cells(String key) => [
    for (final value in _list(key, _take(key))) _cell(key, value),
  ];

  T _object<T>(String key, Object? value, T Function(FieldReader) read) {
    if (value is! Map<String, Object?>) throw _wrong(key, 'an object');
    final reader = JsonFieldReader(value, path: '$_path$key.');
    final result = read(reader);
    reader.expectDone();
    return result;
  }

  @override
  T item<T>(String key, T Function(FieldReader) read) =>
      _object(key, _take(key), read);

  @override
  List<T> items<T>(String key, T Function(FieldReader) read) => [
    for (final value in _list(key, _take(key))) _object(key, value, read),
  ];

  @override
  T? maybe<T extends Object>(String key, T Function(FieldReader, String) read) {
    if (_json[key] == null) {
      _read.add(key);
      return null;
    }
    return read(this, key);
  }
}
