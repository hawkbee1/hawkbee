/// IDs of the Appwrite resources declared in `backend/appwrite.config.json`.
///
/// Keep these in sync with that file: apps and functions refer to resources
/// through these constants, never through string literals.
abstract final class AppwriteIds {
  /// The main TablesDB database.
  static const databaseId = 'hawkbee';

  /// Health-check function, used to verify a deployment.
  static const pingFunctionId = 'ping';

  /// The daily statistics, medals and hit-rate flags of a battle, from its
  /// uploaded log (decision 143).
  static const dailyStatsFunctionId = 'daily_stats';

  /// The batches of the battle logs, uploaded by the simulation host.
  static const battleLogsBucketId = 'battle_logs';

  /// Statistics per unit, section and player, for a battle, a war and the
  /// game.
  static const statsTableId = 'stats';

  /// The medals of each player: war medals and game medals.
  static const medalsTableId = 'medals';

  /// Hit rates far above the norm, for the moderation tools.
  static const hitRateFlagsTableId = 'hit_rate_flags';
}
