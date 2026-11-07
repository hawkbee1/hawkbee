/// IDs of the Appwrite resources declared in `backend/appwrite.config.json`.
///
/// Keep these in sync with that file: apps and functions refer to resources
/// through these constants, never through string literals.
///
/// The Hawkbee apps share one Appwrite project, so each app's tables,
/// buckets, functions and labels carry the app's prefix: `bt_` for Battle
/// Team (`bt` for labels, which allow only letters and digits).
abstract final class AppwriteIds {
  /// The main TablesDB database.
  static const databaseId = 'hawkbee';

  /// Health-check function, used to verify a deployment.
  static const pingFunctionId = 'ping';

  /// The daily statistics, medals and hit-rate flags of a battle, from its
  /// uploaded log (decision 143).
  static const dailyStatsFunctionId = 'bt_daily_stats';

  /// The batches of the battle logs, uploaded by the simulation host.
  static const battleLogsBucketId = 'bt_battle_logs';

  /// The snapshots of the running battles, uploaded by the simulation host.
  static const battleSnapshotsBucketId = 'bt_battle_snapshots';

  /// Statistics per unit, section and player, for a battle, a war and the
  /// game.
  static const statsTableId = 'bt_stats';

  /// The medals of each player: war medals and game medals.
  static const medalsTableId = 'bt_medals';

  /// Hit rates far above the norm, for the moderation tools.
  static const hitRateFlagsTableId = 'bt_hit_rate_flags';

  /// Wars (SOC-16).
  static const warsTableId = 'bt_wars';

  /// Battles of the wars.
  static const battlesTableId = 'bt_battles';

  /// Sections of the wars: each player's, with what it keeps.
  static const sectionsTableId = 'bt_sections';

  /// Guilds of the wars.
  static const guildsTableId = 'bt_guilds';

  /// Purchases of cosmetics, one row per payment (SOC-27).
  static const purchasesTableId = 'bt_purchases';

  /// API keys, hashed (AI-04).
  static const apiKeysTableId = 'bt_api_keys';

  /// The Appwrite label of admins (SOC-16, decision 161).
  static const adminLabel = 'btadmin';

  /// Creates wars and lets players join them (SOC-16, SOC-30).
  static const createWarFunctionId = 'bt_create_war';

  /// Plans and starts battles (SOC-16, SOC-20).
  static const createBattleFunctionId = 'bt_create_battle';

  /// Carries the sections of an ended battle over (UNIT-30).
  static const endBattleFunctionId = 'bt_end_battle';

  /// Guild requests between battles.
  static const guildRequestsFunctionId = 'bt_guild_requests';

  /// Creates and revokes API keys (decisions 158, 161).
  static const apiKeysFunctionId = 'bt_api_keys';
}
