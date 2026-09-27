import 'package:appwrite_api_client/appwrite_api_client.dart';

/// {@template backend_unreachable_exception}
/// Thrown when the backend does not answer.
/// {@endtemplate}
class BackendUnreachableException implements Exception {
  /// {@macro backend_unreachable_exception}
  const new(this.reason);

  /// Human-readable cause, useful when diagnosing a misconfigured endpoint.
  final String reason;

  @override
  String toString() => 'BackendUnreachableException: $reason';
}

/// {@template backend_status_repository}
/// Reports whether the Appwrite backend is reachable.
/// {@endtemplate}
class BackendStatusRepository {
  /// {@macro backend_status_repository}
  const new({required this._apiClient});

  final AppwriteApiClient _apiClient;

  /// Completes when the backend answers.
  ///
  /// Throws a [BackendUnreachableException] when it does not.
  Future<void> checkConnection() async {
    try {
      await _apiClient.ping();
    } on AppwritePingFailure catch (failure, stackTrace) {
      Error.throwWithStackTrace(
        BackendUnreachableException('${failure.error}'),
        stackTrace,
      );
    }
  }
}
