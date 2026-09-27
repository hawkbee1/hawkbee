import 'package:appwrite/appwrite.dart';

/// {@template appwrite_ping_failure}
/// Thrown when the Appwrite server cannot be reached with the configured
/// endpoint and project ID.
/// {@endtemplate}
class AppwritePingFailure implements Exception {
  /// {@macro appwrite_ping_failure}
  const new(this.error);

  /// The underlying error raised by the Appwrite SDK or the network stack.
  final Object error;

  @override
  String toString() => 'AppwritePingFailure: $error';
}

/// {@template appwrite_api_client}
/// Talks to an Appwrite project through the Appwrite client SDK.
///
/// This is the only package allowed to import `package:appwrite`.
/// {@endtemplate}
class AppwriteApiClient {
  /// {@macro appwrite_api_client}
  new({required String endpoint, required String projectId})
    : this.withClient(Client().setEndpoint(endpoint).setProject(projectId));

  /// Creates an [AppwriteApiClient] backed by an existing [Client].
  new withClient(this._client);

  final Client _client;

  /// Checks that the Appwrite project answers.
  ///
  /// Throws an [AppwritePingFailure] when it does not.
  Future<void> ping() async {
    try {
      await _client.ping();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(AppwritePingFailure(error), stackTrace);
    }
  }
}
