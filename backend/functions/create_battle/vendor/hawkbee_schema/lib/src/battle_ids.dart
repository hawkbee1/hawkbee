/// The longest battle ID. The host names a battle's files in the Appwrite
/// buckets after it, and a log batch's file ID, at most 36 characters, adds
/// `-` and 12 digits to it.
const maxBattleIdLength = 23;

final _battleId = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');

/// Whether [id] can name a battle: letters, digits, `.`, `-` and `_`,
/// starting with a letter or a digit, at most [maxBattleIdLength]
/// characters, so that the host can name the battle's files after it.
bool isBattleId(String id) =>
    id.length <= maxBattleIdLength && _battleId.hasMatch(id);
