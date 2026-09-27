/// IDs of the Appwrite resources declared in `backend/appwrite.config.json`.
///
/// Keep these in sync with that file: apps and functions refer to resources
/// through these constants, never through string literals.
abstract final class AppwriteIds {
  /// The main TablesDB database.
  static const databaseId = 'hawkbee';

  /// Health-check function, used to verify a deployment.
  static const pingFunctionId = 'ping';
}
