import 'package:appwrite/appwrite.dart';
import 'package:logging/logging.dart';

/// Why a call to Appwrite failed, read from the answer or the lack of one.
///
/// What a kind means depends on the call: [unauthorized] is a wrong password
/// for a sign-in, [conflict] an email already used for a sign-up.
enum AppwriteFailureKind {
  /// 400: Appwrite refused what was sent (a password too short, an email that
  /// is not one).
  invalidInput,

  /// 401: no session, or the credentials do not match an account.
  unauthorized,

  /// 409: the thing already exists (an account with that email).
  conflict,

  /// 429: too many requests; try again later.
  tooManyRequests,

  /// No answer: the server is down or the network is.
  unreachable,

  /// 5xx: the server failed.
  serverError,

  /// Anything else.
  other,
}

AppwriteFailureKind _kindOf(Object error) => switch (error) {
  AppwriteException(code: null) => AppwriteFailureKind.unreachable,
  AppwriteException(code: 400) => AppwriteFailureKind.invalidInput,
  AppwriteException(code: 401) => AppwriteFailureKind.unauthorized,
  AppwriteException(code: 409) => AppwriteFailureKind.conflict,
  AppwriteException(code: 429) => AppwriteFailureKind.tooManyRequests,
  AppwriteException(:final code?) when code >= 500 =>
    AppwriteFailureKind.serverError,
  _ => AppwriteFailureKind.other,
};

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

  /// Why it failed.
  AppwriteFailureKind get kind => _kindOf(error);

  @override
  String toString() => 'AppwriteSignInFailure: $error';
}

/// {@template appwrite_account_failure}
/// Thrown when an account cannot be created, read, or signed out.
/// {@endtemplate}
class AppwriteAccountFailure implements Exception {
  /// {@macro appwrite_account_failure}
  const new(this.error);

  /// The underlying error raised by the Appwrite SDK or the network stack.
  final Object error;

  /// Why it failed.
  AppwriteFailureKind get kind => _kindOf(error);

  @override
  String toString() => 'AppwriteAccountFailure: $error';
}

/// {@template appwrite_rows_failure}
/// Thrown when rows cannot be read.
/// {@endtemplate}
class AppwriteRowsFailure implements Exception {
  /// {@macro appwrite_rows_failure}
  const new(this.error);

  /// The underlying error raised by the Appwrite SDK or the network stack.
  final Object error;

  /// Why it failed.
  AppwriteFailureKind get kind => _kindOf(error);

  @override
  String toString() => 'AppwriteRowsFailure: $error';
}

/// {@template appwrite_account}
/// The signed-in account: what Appwrite Auth knows of it that the app shows.
/// {@endtemplate}
class AppwriteAccount {
  /// {@macro appwrite_account}
  const new({required this.id, required this.email, required this.name});

  /// The account ID, the one Battle Team's sections are filed under.
  final String id;

  /// The email it signs in with.
  final String email;

  /// The name it was created with.
  final String name;
}

/// {@template appwrite_row}
/// A row of a table: its ID and its columns.
/// {@endtemplate}
class AppwriteRow {
  /// {@macro appwrite_row}
  const new({required this.id, required this.data});

  /// The row ID.
  final String id;

  /// The columns, by name (a text column holding JSON is still text).
  final Map<String, Object?> data;
}

/// {@template appwrite_api_client}
/// Talks to an Appwrite project through the Appwrite client SDK.
///
/// This is the only package allowed to import `package:appwrite`.
///
/// It logs on `appwrite_api_client.AppwriteApiClient` when [signIn],
/// [signUp], [signOut], [currentAccount], [createJwt] and [findRows] start,
/// end and fail. Never the password, an email, a JWT or a cookie.
///
/// The SDK keeps the session in its cookie jar, so an account stays signed in
/// across the app's restarts until [signOut].
/// {@endtemplate}
class AppwriteApiClient {
  /// {@macro appwrite_api_client}
  ///
  /// [selfSigned] accepts the endpoint's self-signed certificate, for a local
  /// Appwrite behind Traefik's default certificate.
  new({
    required String endpoint,
    required String projectId,
    bool selfSigned = false,
  }) : this.withClient(
         Client()
             .setEndpoint(endpoint)
             .setProject(projectId)
             .setSelfSigned(status: selfSigned),
       );

  /// Creates an [AppwriteApiClient] backed by an existing [Client], with its
  /// [account] and [tables] services (ones on [_client] by default).
  new withClient(this._client, {Account? account, TablesDB? tables})
    : _account = account ?? Account(_client),
      _tables = tables ?? TablesDB(_client);

  static final _log = Logger('appwrite_api_client.AppwriteApiClient');

  final Client _client;
  final Account _account;
  final TablesDB _tables;

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
      _guard('sign-in', AppwriteSignInFailure.new, () async {
        try {
          if ((await _account.get()).email == email) {
            _log.info('sign-in: the session is already open');
            return;
          }
          await _account.deleteSession(sessionId: 'current');
        } on AppwriteException catch (error) {
          if (error.code != 401) rethrow;
        }
        await _account.createEmailPasswordSession(
          email: email,
          password: password,
        );
      });

  /// Creates the account [email] with [password] and [name], and signs it in.
  /// A session still open is closed first, since Appwrite opens no second one.
  ///
  /// Throws an [AppwriteAccountFailure] when it cannot: of kind
  /// [AppwriteFailureKind.conflict] when the email already has an account,
  /// [AppwriteFailureKind.invalidInput] when Appwrite refuses the email or
  /// the password.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) => _guard('sign-up', AppwriteAccountFailure.new, () async {
    await _closeSession();
    await _account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name,
    );
    await _account.createEmailPasswordSession(email: email, password: password);
  });

  /// The signed-in account, or null when there is no session.
  ///
  /// Throws an [AppwriteAccountFailure] when Appwrite cannot say.
  Future<AppwriteAccount?> currentAccount() =>
      _guard('current account', AppwriteAccountFailure.new, () async {
        try {
          final user = await _account.get();
          return AppwriteAccount(
            id: user.$id,
            email: user.email,
            name: user.name,
          );
        } on AppwriteException catch (error) {
          if (error.code == 401) return null;
          rethrow;
        }
      });

  /// Closes the current session. No session is already signed out.
  ///
  /// Throws an [AppwriteAccountFailure] when it cannot.
  Future<void> signOut() =>
      _guard('sign-out', AppwriteAccountFailure.new, _closeSession);

  Future<void> _closeSession() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (error) {
      if (error.code != 401) rethrow;
    }
  }

  /// A JWT of the signed-in account, valid 15 minutes: what a Battle Team
  /// host checks at sign-in.
  ///
  /// Throws an [AppwriteSignInFailure] when there is no session.
  Future<String> createJwt() => _guard(
    'create JWT',
    AppwriteSignInFailure.new,
    () async => (await _account.createJWT()).jwt,
  );

  /// The first [limit] rows of [tableId] in [databaseId] whose every column
  /// of [equal] holds one of the values listed for it. The signed-in account
  /// reads what the table's permissions let it.
  ///
  /// Throws an [AppwriteRowsFailure] when it cannot.
  Future<List<AppwriteRow>> findRows({
    required String databaseId,
    required String tableId,
    Map<String, List<String>> equal = const {},
    int limit = 100,
  }) => _guard('read rows', AppwriteRowsFailure.new, () async {
    final found = await _tables.listRows(
      databaseId: databaseId,
      tableId: tableId,
      queries: [
        for (final MapEntry(:key, :value) in equal.entries)
          Query.equal(key, value),
        Query.limit(limit),
      ],
    );
    return [
      for (final row in found.rows) AppwriteRow(id: row.$id, data: row.data),
    ];
  });

  static Future<T> _guard<T>(
    String what,
    Exception Function(Object error) failure,
    Future<T> Function() work,
  ) async {
    _log.info('$what: started');
    try {
      final result = await work();
      _log.info('$what: done');
      return result;
    } on Object catch (error, stackTrace) {
      _log.severe('$what: failed', error, stackTrace);
      Error.throwWithStackTrace(failure(error), stackTrace);
    }
  }
}
