/// Statistics and medals of Battle Team, computed from the battle logs
/// (decision 143): per unit, section and player, for a battle, a war and
/// the game; medals at the thresholds of `medals.yaml`; hit rates far above
/// the norm.
///
/// Pure Dart with no I/O: the caller passes the log entries and the
/// `medals.yaml` data.
library;

export 'src/battle_tally.dart';
export 'src/hit_rate_flags.dart';
export 'src/medals.dart';
export 'src/stats.dart';
