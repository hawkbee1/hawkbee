import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// {@template api_key}
/// An account's API key (AI-04, decision 158, stack decision 6): `btk_`
/// then 43 base64url characters, 256 random bits. The server generates
/// it (`ApiKey.generate`), shows [value] once, and stores only its [hash].
/// A caller sends it as a bearer token; the host hashes it and looks the
/// hash up, so a revoked key, whose hash is gone, is refused on its next
/// call.
///
/// The hash is a plain SHA-256, neither salted nor slow, by choice: a slow
/// salted hash protects passwords, which people choose from a small space.
/// A key of 256 random bits cannot be guessed or found in a precomputed
/// table, so salt and stretching add nothing, and a fast hash keeps the
/// check of every call cheap.
/// {@endtemplate}
final class ApiKey {
  const new _(this.value);

  /// A new key from [random], which must be cryptographically secure:
  /// `Random.secure()`. The caller passes it, so that this package does no
  /// I/O and tests can check the format.
  factory generate(Random random) {
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return ApiKey._('$_prefix${base64Url.encode(bytes).replaceAll('=', '')}');
  }

  /// The key [text], as a caller sent it.
  ///
  /// Throws a [FormatException], which does not repeat [text], when it is
  /// not a key.
  factory parse(String text) {
    if (!_format.hasMatch(text)) {
      throw const FormatException('not an API key');
    }
    return ApiKey._(text);
  }

  static const _prefix = 'btk_';
  static final _format = RegExp(r'^btk_[A-Za-z0-9_-]{43}$');

  /// The key, shown once to its owner.
  final String value;

  /// The SHA-256 of [value] in lowercase hexadecimal: what the server
  /// stores and looks up.
  String get hash => sha256.convert(utf8.encode(value)).toString();

  /// Hides the key, so that it never reaches a log.
  @override
  String toString() => 'ApiKey($_prefix…)';
}
