/// Commands, events, the battle-log format and the API key format of
/// Battle Team, shared by the host, the client and the functions.
///
/// Pure Dart with no I/O. Two encodings of version 1 of the format: compact
/// binary for the battle log and the socket, JSON for HTTPS calls.
library;

export 'src/api_key.dart';
export 'src/codec/codecs.dart';
export 'src/codec/fields.dart' show ProtocolException, protocolVersion;
export 'src/command.dart';
export 'src/events.dart';
export 'src/log_entry.dart';
export 'src/orders.dart';
export 'src/values.dart';
