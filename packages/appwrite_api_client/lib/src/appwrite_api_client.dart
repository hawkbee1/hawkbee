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

/// {@template appwrite_sign_in_failure}
/// Thrown when the account cannot sign in or get a JWT.
/// {@endtemplate}
class AppwriteSignInFailure implements Exception {
  /// {@macro appwrite_sign_in_failure}
  const new(this.error);

  /// The underlying error raised by the Appwrite SDK or the network stack.
  final Object error;

  @override
  String toString() => 'AppwriteSignInFailure: $error';
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

  /// Creates an [AppwriteApiClient] backed by an existing [Client], and
  /// its [account] service (one on [_client] by default).
  new withClient(this._client, {Account? account})
    : _account = account ?? Account(_client);

  final Client _client;
  final Account _account;

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

  /// Signs in as [email] with [password], unless that account's session is
  /// already open. Another account's session is closed first: a JWT must
  /// be the account that was asked for.
  ///
  /// Throws an [AppwriteSignInFailure] when it cannot.
  Future<void> signIn({required String email, required String password}) =>
      _signInFailure(() async {
        try {
          if ((await _account.get()).email == email) return;
          await _account.deleteSession(sessionId: 'current');
        } on AppwriteException catch (error) {
          if (error.code != 401) rethrow;
        }
        await _account.createEmailPasswordSession(
          email: email,
          password: password,
        );
      });

  /// A JWT of the signed-in account, valid 15 minutes: what a Battle Team
  /// host checks at sign-in.
  ///
  /// Throws an [AppwriteSignInFailure] when there is no session.
  Future<String> createJwt() =>
      _signInFailure(() async => (await _account.createJWT()).jwt);

  static Future<T> _signInFailure<T>(Future<T> Function() work) async {
    try {
      return await work();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(AppwriteSignInFailure(error), stackTrace);
    }
  }
}
