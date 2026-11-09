import 'dart:convert';
import 'dart:typed_data';

import 'package:battle_protocol/src/codec/fields.dart';
import 'package:battle_protocol/src/values.dart';

/// {@template binary_field_writer}
/// Writes fields in order, without their names, on bytes. Integers are
/// zigzag LEB128 varints written with arithmetic, not 64-bit operations,
/// so the web client writes the same bytes; floating-point numbers are
/// little-endian IEEE 754 doubles; strings are UTF-8 after their length; an
/// optional field is a byte 0 or 1 before its value; a list is its length
/// before its items.
/// {@endtemplate}
final class BinaryFieldWriter implements FieldWriter {
  /// {@macro binary_field_writer}
  new();

  final _bytes = BytesBuilder(copy: false);
  final _float = ByteData(8);

  /// The bytes written so far; the writer is empty afterwards.
  Uint8List takeBytes() => _bytes.takeBytes();

  /// Writes [bytes] as they are.
  void raw(List<int> bytes) => _bytes.add(bytes);

  /// Writes a count or a length: an unsigned varint.
  void count(int value) {
    var rest = value;
    while (rest >= 0x80) {
      _bytes.addByte(rest % 0x80 + 0x80);
      rest ~/= 0x80;
    }
    _bytes.addByte(rest);
  }

  @override
  void integer(String key, int value) {
    checkWireInt(value);
    count(value >= 0 ? value * 2 : -value * 2 - 1);
  }

  @override
  void number(String key, double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, key, 'must be finite');
    }
    _float.setFloat64(0, value, Endian.little);
    _bytes.add(Uint8List.fromList(_float.buffer.asUint8List()));
  }

  @override
  void text(String key, String value) {
    final bytes = utf8.encode(value);
    count(bytes.length);
    _bytes.add(bytes);
  }

  @override
  void flag(String key, {required bool value}) => _bytes.addByte(value ? 1 : 0);

  @override
  void time(String key, Duration value) => integer(key, value.inMicroseconds);

  @override
  void choice(String key, Enum value) => count(value.index);

  @override
  void position(String key, Position value) {
    integer(key, value.xCm);
    integer(key, value.yCm);
    integer(key, value.zCm);
  }

  @override
  void direction(String key, Direction value) {
    integer(key, value.xMicro);
    integer(key, value.yMicro);
    integer(key, value.zMicro);
  }

  void _cell(String key, Cell value) {
    integer(key, value.x);
    integer(key, value.y);
    maybe(key, value.island, (w, k, v) => w.text(k, v));
  }

  @override
  void texts(String key, List<String> values) {
    count(values.length);
    for (final value in values) {
      text(key, value);
    }
  }

  @override
  void cells(String key, List<Cell> values) {
    count(values.length);
    for (final value in values) {
      _cell(key, value);
    }
  }

  @override
  void item<T>(String key, T value, void Function(FieldWriter, T) write) =>
      write(this, value);

  @override
  void items<T>(
    String key,
    List<T> values,
    void Function(FieldWriter, T) write,
  ) {
    count(values.length);
    for (final value in values) {
      write(this, value);
    }
  }

  @override
  void maybe<T extends Object>(
    String key,
    T? value,
    void Function(FieldWriter, String, T) write,
  ) {
    flag(key, value: value != null);
    if (value != null) write(this, key, value);
  }
}

/// {@template binary_field_reader}
/// Reads the fields a [BinaryFieldWriter] wrote, checking every length
/// against the bytes left so that no input makes it allocate more than the
/// input's size.
/// {@endtemplate}
final class BinaryFieldReader implements FieldReader {
  /// {@macro binary_field_reader}
  new(this._bytes);

  final Uint8List _bytes;
  var _offset = 0;

  /// Whether every byte was read.
  bool get atEnd => _offset == _bytes.length;

  /// Throws unless every byte was read.
  void expectEnd() {
    if (!atEnd) {
      throw ProtocolException(
        '${_bytes.length - _offset} bytes left after the message',
      );
    }
  }

  /// The next [length] bytes, as they are.
  Uint8List raw(int length) {
    if (length > _bytes.length - _offset) {
      throw const ProtocolException('unexpected end of input');
    }
    final bytes = Uint8List.sublistView(_bytes, _offset, _offset + length);
    _offset += length;
    return bytes;
  }

  int _byte() => raw(1)[0];

  /// A count or a length: an unsigned varint in its shortest form, at most
  /// [maxWireInt].
  int count() {
    var value = 0;
    var scale = 1;
    for (var length = 1; length <= 8; length++) {
      final byte = _byte();
      value += (byte % 0x80) * scale;
      if (byte < 0x80) {
        if (byte == 0 && length > 1) {
          throw const ProtocolException('varint not in its shortest form');
        }
        if (value > maxWireInt) {
          throw const ProtocolException('integer out of range');
        }
        return value;
      }
      scale *= 0x80;
    }
    throw const ProtocolException('varint longer than 8 bytes');
  }

  int _length() {
    final length = count();
    if (length > _bytes.length - _offset) {
      throw const ProtocolException('length beyond the end of input');
    }
    return length;
  }

  @override
  int integer(String key) {
    final zigzag = count();
    return zigzag.isEven ? zigzag ~/ 2 : -((zigzag + 1) ~/ 2);
  }

  @override
  double number(String key) {
    final value = ByteData.sublistView(raw(8)).getFloat64(0, Endian.little);
    if (!value.isFinite) {
      throw ProtocolException('$key is not a finite number');
    }
    return value;
  }

  @override
  String text(String key) {
    final bytes = raw(_length());
    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw ProtocolException('$key is not valid UTF-8');
    }
  }

  @override
  bool flag(String key) => switch (_byte()) {
    0 => false,
    1 => true,
    _ => throw ProtocolException('$key is not a boolean'),
  };

  @override
  Duration time(String key) => Duration(microseconds: integer(key));

  @override
  T choice<T extends Enum>(String key, List<T> values) {
    final index = count();
    if (index >= values.length) {
      throw ProtocolException('$key has no value $index');
    }
    return values[index];
  }

  @override
  Position position(String key) =>
      Position(integer(key), integer(key), integer(key));

  @override
  Direction direction(String key) =>
      Direction(integer(key), integer(key), integer(key));

  Cell _cell(String key) =>
      Cell(integer(key), integer(key), island: maybe(key, (r, k) => r.text(k)));

  @override
  List<String> texts(String key) =>
      List.generate(_length(), (_) => text(key), growable: false);

  @override
  List<Cell> cells(String key) =>
      List.generate(_length(), (_) => _cell(key), growable: false);

  @override
  T item<T>(String key, T Function(FieldReader) read) => read(this);

  @override
  List<T> items<T>(String key, T Function(FieldReader) read) =>
      List.generate(_length(), (_) => read(this), growable: false);

  @override
  T? maybe<T extends Object>(
    String key,
    T Function(FieldReader, String) read,
  ) => flag(key) ? read(this, key) : null;
}
