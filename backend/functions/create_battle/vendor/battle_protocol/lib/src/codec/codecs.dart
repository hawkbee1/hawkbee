import 'dart:convert';
import 'dart:typed_data';

import 'package:battle_protocol/src/codec/binary_fields.dart';
import 'package:battle_protocol/src/codec/fields.dart';
import 'package:battle_protocol/src/codec/json_fields.dart';
import 'package:battle_protocol/src/codec/wire.dart';
import 'package:battle_protocol/src/command.dart';
import 'package:battle_protocol/src/events.dart';
import 'package:battle_protocol/src/log_entry.dart';

/// Encodes and decodes the messages of the protocol in one encoding, each
/// with the format version (stack decision 2). Decoding throws a
/// [ProtocolException] for any input that is not a valid message, so the
/// host can read what a client sent without other failures.
abstract interface class ProtocolCodec<T> {
  /// [command] encoded.
  T encodeCommand(Command command);

  /// The command [data] encodes.
  Command decodeCommand(T data);

  /// [event] encoded.
  T encodeEvent(BattleEvent event);

  /// The event [data] encodes.
  BattleEvent decodeEvent(T data);

  /// [entry] encoded.
  T encodeEntry(LogEntry entry);

  /// The log entry [data] encodes.
  LogEntry decodeEntry(T data);
}

/// The first bytes of a battle log: `BTLG`.
const _logMagic = [0x42, 0x54, 0x4C, 0x47];

/// {@template binary_protocol_codec}
/// The compact binary encoding, for the battle log and the socket (stack
/// decisions 2 and 3): the version as a varint, then the fields in order.
///
/// A battle log is `BTLG`, the version, then one frame per entry: its
/// length, then the entry without a version. Frames let the host append
/// entries to its write-ahead log one at a time ([logHeader], [logFrame]).
/// {@endtemplate}
final class BinaryProtocolCodec implements ProtocolCodec<Uint8List> {
  /// {@macro binary_protocol_codec}
  const new();

  Uint8List _encode<M>(M message, void Function(FieldWriter, M) write) {
    final writer = BinaryFieldWriter()..count(protocolVersion);
    write(writer, message);
    return writer.takeBytes();
  }

  M _decode<M>(Uint8List data, M Function(FieldReader) read) {
    final reader = BinaryFieldReader(data);
    _checkVersion(reader.count());
    final message = read(reader);
    reader.expectEnd();
    return message;
  }

  @override
  Uint8List encodeCommand(Command command) => _encode(command, writeCommand);

  @override
  Command decodeCommand(Uint8List data) => _decode(data, readCommand);

  @override
  Uint8List encodeEvent(BattleEvent event) => _encode(event, writeEvent);

  @override
  BattleEvent decodeEvent(Uint8List data) => _decode(data, readEvent);

  @override
  Uint8List encodeEntry(LogEntry entry) => _encode(entry, writeEntry);

  @override
  LogEntry decodeEntry(Uint8List data) => _decode(data, readEntry);

  /// The start of a battle log: `BTLG` and the version.
  Uint8List logHeader() =>
      (BinaryFieldWriter()
            ..raw(_logMagic)
            ..count(protocolVersion))
          .takeBytes();

  /// One entry of a battle log: its length, then the entry.
  Uint8List logFrame(LogEntry entry) {
    final body = BinaryFieldWriter();
    writeEntry(body, entry);
    final bytes = body.takeBytes();
    return (BinaryFieldWriter()
          ..count(bytes.length)
          ..raw(bytes))
        .takeBytes();
  }

  /// A whole battle log of [entries].
  Uint8List encodeLog(List<LogEntry> entries) {
    final writer = BinaryFieldWriter()..raw(logHeader());
    for (final entry in entries) {
      writer.raw(logFrame(entry));
    }
    return writer.takeBytes();
  }

  /// The entries of the battle log [data].
  List<LogEntry> decodeLog(Uint8List data) {
    final reader = BinaryFieldReader(data);
    final magic = reader.raw(_logMagic.length);
    for (var i = 0; i < _logMagic.length; i++) {
      if (magic[i] != _logMagic[i]) {
        throw const ProtocolException('not a battle log');
      }
    }
    _checkVersion(reader.count());
    final entries = <LogEntry>[];
    while (!reader.atEnd) {
      final frame = BinaryFieldReader(reader.raw(reader.count()));
      entries.add(readEntry(frame));
      frame.expectEnd();
    }
    return entries;
  }
}

/// {@template json_protocol_codec}
/// The JSON encoding, for HTTPS calls (stack decision 3): an object with
/// the version under `v` and the fields under their names.
/// {@endtemplate}
final class JsonProtocolCodec implements ProtocolCodec<String> {
  /// {@macro json_protocol_codec}
  const new();

  String _encode<M>(M message, void Function(FieldWriter, M) write) {
    final writer = JsonFieldWriter()..integer('v', protocolVersion);
    write(writer, message);
    return jsonEncode(writer.json);
  }

  M _decode<M>(String data, M Function(FieldReader) read) {
    final Object? json;
    try {
      json = jsonDecode(data);
    } on FormatException {
      throw const ProtocolException('not JSON');
    }
    if (json is! Map<String, Object?>) {
      throw const ProtocolException('not a JSON object');
    }
    final reader = JsonFieldReader(json);
    _checkVersion(reader.integer('v'));
    final message = read(reader);
    reader.expectDone();
    return message;
  }

  @override
  String encodeCommand(Command command) => _encode(command, writeCommand);

  @override
  Command decodeCommand(String data) => _decode(data, readCommand);

  @override
  String encodeEvent(BattleEvent event) => _encode(event, writeEvent);

  @override
  BattleEvent decodeEvent(String data) => _decode(data, readEvent);

  @override
  String encodeEntry(LogEntry entry) => _encode(entry, writeEntry);

  @override
  LogEntry decodeEntry(String data) => _decode(data, readEntry);
}

void _checkVersion(int version) {
  if (version != protocolVersion) {
    throw ProtocolException('unsupported version $version');
  }
}
