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

  /// Wars (SOC-16).
  static const warsTableId = 'wars';

  /// Battles of the wars.
  static const battlesTableId = 'battles';

  /// Sections of the wars: each player's, with what it keeps.
  static const sectionsTableId = 'sections';

  /// Guilds of the wars.
  static const guildsTableId = 'guilds';

  /// Purchases of cosmetics, one row per payment (SOC-27).
  static const purchasesTableId = 'purchases';

  /// API keys, hashed (AI-04).
  static const apiKeysTableId = 'api_keys';

  /// The Appwrite label of admins (SOC-16, decision 161).
  static const adminLabel = 'admin';

  /// Creates wars and lets players join them (SOC-16, SOC-30).
  static const createWarFunctionId = 'create_war';

  /// Plans and starts battles (SOC-16, SOC-20).
  static const createBattleFunctionId = 'create_battle';

  /// Carries the sections of an ended battle over (UNIT-30).
  static const endBattleFunctionId = 'end_battle';

  /// Guild requests between battles.
  static const guildRequestsFunctionId = 'guild_requests';

  /// Creates and revokes API keys (decisions 158, 161).
  static const apiKeysFunctionId = 'api_keys';
}
