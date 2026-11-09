import 'dart:convert';

/// The data of a row, as Appwrite tables hold it: lists and maps are JSON
/// text columns.
typedef RowData = Map<String, Object?>;

T _as<T>(RowData data, String key) {
  final value = data[key];
  return value is T
      ? value
      : throw FormatException('not a row: $key is not a $T');
}

Object? _json(RowData data, String key) => jsonDecode(_as<String>(data, key));

List<String> _texts(RowData data, String key) => switch (_json(data, key)) {
  final List<Object?> list when list.every((item) => item is String) =>
    List.unmodifiable(list.cast<String>()),
  _ => throw FormatException('not a row: $key is not a list of texts'),
};

Map<String, T> _map<T>(Object? value, String key) => switch (value) {
  final Map<String, Object?> map when map.values.every((item) => item is T) =>
    Map.unmodifiable(map.cast<String, T>()),
  _ => throw FormatException('not a row: $key is not a map of $T'),
};

/// {@template war_row}
/// A war (SOC-16, SOC-17): its money floor, its battles planned in order,
/// the one running, each player's section, and whether it has ended.
/// {@endtemplate}
final class WarRow {
  /// {@macro war_row}
  const new({
    required this.id,
    required this.minStartingMoney,
    this.planned = const [],
    this.current,
    this.sections = const {},
    this.over = false,
  });

  /// The war [data] holds, with its row ID [id].
  ///
  /// Throws a [FormatException] for data that is not a war's.
  factory fromData(String id, RowData data) => WarRow(
    id: id,
    minStartingMoney: _as<int>(data, 'min_starting_money'),
    planned: _texts(data, 'planned'),
    current: _as<String?>(data, 'current'),
    sections: _map<String>(_json(data, 'sections'), 'sections'),
    over: _as<bool>(data, 'over'),
  );

  /// The war.
  final String id;

  /// The money floor of its sections (SOC-10).
  final int minStartingMoney;

  /// Its battles planned, in order.
  final List<String> planned;

  /// The battle running; null between battles.
  final String? current;

  /// Each player's section, by account.
  final Map<String, String> sections;

  /// Whether it has ended.
  final bool over;

  /// The row's data.
  RowData toData() => {
    'min_starting_money': minStartingMoney,
    'planned': jsonEncode(planned),
    'current': current,
    'sections': jsonEncode(sections),
    'over': over,
  };
}

/// What a battle is at.
enum BattleStatus {
  /// Planned by an admin.
  planned,

  /// Set up and running on a host.
  running,

  /// Ended by its host, with its result.
  ended,

  /// Its sections carried over to the next battle.
  closed,
}

/// {@template battle_row}
/// A battle of a war: its map and seed, its status, its teams once it
/// starts (team ID to section IDs), the host that runs it (its placement),
/// its winner and its result once it ends.
/// {@endtemplate}
final class BattleRow {
  /// {@macro battle_row}
  const new({
    required this.id,
    required this.warId,
    required this.mapId,
    required this.seed,
    this.status = BattleStatus.planned,
    this.teams = const {},
    this.host,
    this.winner,
    this.result,
    this.statsDone = false,
  });

  /// The battle [data] holds, with its row ID [id].
  ///
  /// Throws a [FormatException] for data that is not a battle's.
  factory fromData(String id, RowData data) {
    final teams = _map<Object?>(_json(data, 'teams'), 'teams');
    final result = _as<String?>(data, 'result');
    return BattleRow(
      id: id,
      warId: _as<String>(data, 'war_id'),
      mapId: _as<String>(data, 'map_id'),
      seed: _as<int>(data, 'seed'),
      status:
          BattleStatus.values.asNameMap()[_as<String>(data, 'status')] ??
          (throw const FormatException('not a row: status is unknown')),
      teams: {
        for (final MapEntry(:key, :value) in teams.entries)
          key: switch (value) {
            final List<Object?> list when list.every((id) => id is String) =>
              List<String>.unmodifiable(list.cast<String>()),
            _ => throw const FormatException('not a row: teams'),
          },
      },
      host: _as<String?>(data, 'host'),
      winner: _as<String?>(data, 'winner'),
      result: result == null
          ? null
          : BattleResult.fromJson(_map<Object?>(jsonDecode(result), 'result')),
      statsDone: _as<bool>(data, 'stats_done'),
    );
  }

  /// The battle.
  final String id;

  /// Its war.
  final String warId;

  /// Its map.
  final String mapId;

  /// The seed of its random.
  final int seed;

  /// What it is at.
  final BattleStatus status;

  /// Its teams once it runs: the section IDs of each team.
  final Map<String, List<String>> teams;

  /// The simulation host that runs it, once one claimed it: where it is
  /// placed (stack decision 1, hosting).
  final String? host;

  /// The team that won, once it ended.
  final String? winner;

  /// What its sections kept, once it ended.
  final BattleResult? result;

  /// Whether its statistics are final: computed after its end.
  final bool statsDone;

  /// This battle with the values given; [host] gives its new host, null
  /// for none.
  BattleRow copyWith({
    BattleStatus? status,
    Map<String, List<String>>? teams,
    String? Function()? host,
    String? winner,
    BattleResult? result,
    bool? statsDone,
  }) => BattleRow(
    id: id,
    warId: warId,
    mapId: mapId,
    seed: seed,
    status: status ?? this.status,
    teams: teams ?? this.teams,
    host: host == null ? this.host : host(),
    winner: winner ?? this.winner,
    result: result ?? this.result,
    statsDone: statsDone ?? this.statsDone,
  );

  /// The row's data.
  RowData toData() => {
    'war_id': warId,
    'map_id': mapId,
    'seed': seed,
    'status': status.name,
    'teams': jsonEncode(teams),
    'host': host,
    'winner': winner,
    'result': result == null ? null : jsonEncode(result!.toJson()),
    'stats_done': statsDone,
  };
}

/// {@template kept_unit}
/// A unit a section keeps from battle to battle (UNIT-30): its type, its
/// XP earned and unspent, its tree steps by stat and its weapon.
/// {@endtemplate}
final class KeptUnit {
  /// {@macro kept_unit}
  const new({
    required this.id,
    required this.type,
    this.xpEarned = 0,
    this.xpUnspent = 0,
    this.tree = const {},
    this.weapon,
  });

  /// The unit [json] holds.
  ///
  /// Throws a [FormatException] for anything else.
  factory fromJson(Map<String, Object?> json) => KeptUnit(
    id: _as<String>(json, 'id'),
    type: _as<String>(json, 'type'),
    xpEarned: _as<num>(json, 'xp_earned').toDouble(),
    xpUnspent: _as<num>(json, 'xp_unspent').toDouble(),
    tree: _map<int>(json['tree'], 'tree'),
    weapon: _as<String?>(json, 'weapon'),
  );

  /// The unit.
  final String id;

  /// Its unit type.
  final String type;

  /// The XP it earned.
  final double xpEarned;

  /// The XP it has left to spend.
  final double xpUnspent;

  /// Its tree: the steps bought, by stat.
  final Map<String, int> tree;

  /// Its weapon; null for its type's default.
  final String? weapon;

  /// This unit as JSON values.
  Map<String, Object?> toJson() => {
    'id': id,
    'type': type,
    'xp_earned': xpEarned,
    'xp_unspent': xpUnspent,
    'tree': tree,
    'weapon': weapon,
  };
}

/// {@template kept_section}
/// What a section keeps from battle to battle (UNIT-30): its money, its
/// section XP, its spare weapons and its units.
/// {@endtemplate}
final class KeptSection {
  /// {@macro kept_section}
  const new({
    required this.money,
    required this.xp,
    this.weapons = const [],
    this.units = const [],
  });

  /// The section [json] holds.
  ///
  /// Throws a [FormatException] for anything else.
  factory fromJson(Map<String, Object?> json) => KeptSection(
    money: _as<int>(json, 'money'),
    xp: _as<num>(json, 'xp').toDouble(),
    weapons: switch (json['weapons']) {
      final List<Object?> list when list.every((item) => item is String) =>
        List.unmodifiable(list.cast<String>()),
      _ => throw const FormatException('not a section: weapons'),
    },
    units: switch (json['units']) {
      final List<Object?> list => List.unmodifiable([
        for (final unit in list) KeptUnit.fromJson(_map<Object?>(unit, 'unit')),
      ]),
      _ => throw const FormatException('not a section: units'),
    },
  );

  /// Its money, in whole w€.
  final int money;

  /// Its section XP.
  final double xp;

  /// Its spare weapons.
  final List<String> weapons;

  /// Its units, the commander included.
  final List<KeptUnit> units;

  /// This section as JSON values.
  Map<String, Object?> toJson() => {
    'money': money,
    'xp': xp,
    'weapons': weapons,
    'units': [for (final unit in units) unit.toJson()],
  };
}

/// {@template battle_result}
/// What the host reports when a battle ends: the winning team, what each
/// section keeps, and the XP its units earned in the battle, by section
/// ID; a guild earns what its sections earned (SOC-47).
/// {@endtemplate}
final class BattleResult {
  /// {@macro battle_result}
  const new({
    required this.winner,
    required this.sections,
    this.earned = const {},
  });

  /// The result [json] holds.
  ///
  /// Throws a [FormatException] for anything else.
  factory fromJson(Map<String, Object?> json) => BattleResult(
    winner: _as<String>(json, 'winner'),
    sections: {
      for (final MapEntry(:key, :value) in _map<Object?>(
        json['sections'],
        'sections',
      ).entries)
        key: KeptSection.fromJson(_map<Object?>(value, 'sections.$key')),
    },
    earned: {
      for (final MapEntry(:key, :value) in _map<num>(
        json['earned'],
        'earned',
      ).entries)
        key: value.toDouble(),
    },
  );

  /// The team that won.
  final String winner;

  /// What each section keeps, by section ID.
  final Map<String, KeptSection> sections;

  /// The XP each section's units earned in the battle, by section ID.
  final Map<String, double> earned;

  /// This result as JSON values.
  Map<String, Object?> toJson() => {
    'winner': winner,
    'sections': {
      for (final MapEntry(:key, :value) in sections.entries)
        key: value.toJson(),
    },
    'earned': earned,
  };
}

/// {@template section_row}
/// A section of a war: its player, its guild and what it keeps from battle
/// to battle (SOC-18, UNIT-30).
/// {@endtemplate}
final class SectionRow {
  /// {@macro section_row}
  const new({
    required this.id,
    required this.warId,
    required this.accountId,
    required this.kept,
    this.guildId,
  });

  /// The section [data] holds, with its row ID [id].
  ///
  /// Throws a [FormatException] for data that is not a section's.
  factory fromData(String id, RowData data) => SectionRow(
    id: id,
    warId: _as<String>(data, 'war_id'),
    accountId: _as<String>(data, 'account_id'),
    guildId: _as<String?>(data, 'guild_id'),
    kept: KeptSection.fromJson(_map<Object?>(_json(data, 'kept'), 'kept')),
  );

  /// The section.
  final String id;

  /// Its war.
  final String warId;

  /// Its player's account.
  final String accountId;

  /// Its guild, if any.
  final String? guildId;

  /// What it keeps.
  final KeptSection kept;

  /// This section with [kept] and [guildId].
  SectionRow copyWith({KeptSection? kept, String? Function()? guildId}) =>
      SectionRow(
        id: id,
        warId: warId,
        accountId: accountId,
        kept: kept ?? this.kept,
        guildId: guildId == null ? this.guildId : guildId(),
      );

  /// The row's data.
  RowData toData() => {
    'war_id': warId,
    'account_id': accountId,
    'guild_id': guildId,
    'kept': jsonEncode(kept.toJson()),
  };
}

/// {@template guild_row}
/// A guild of a war (SOC-46 to SOC-50): each section's role (`chief`,
/// `member`, `trainee`), its XP, and whether it is on the newcomer list.
/// {@endtemplate}
final class GuildRow {
  /// {@macro guild_row}
  const new({
    required this.id,
    required this.warId,
    required this.roles,
    this.xp = 0,
    this.optedIn = false,
  });

  /// The guild [data] holds, with its row ID [id].
  ///
  /// Throws a [FormatException] for data that is not a guild's.
  factory fromData(String id, RowData data) => GuildRow(
    id: id,
    warId: _as<String>(data, 'war_id'),
    roles: _map<String>(_json(data, 'roles'), 'roles'),
    xp: _as<num>(data, 'xp').toDouble(),
    optedIn: _as<bool>(data, 'opted_in'),
  );

  /// The guild.
  final String id;

  /// Its war.
  final String warId;

  /// Each section's role, by section ID.
  final Map<String, String> roles;

  /// Its XP.
  final double xp;

  /// Whether it is on the newcomer list.
  final bool optedIn;

  /// The row's data.
  RowData toData() => {
    'war_id': warId,
    'roles': jsonEncode(roles),
    'xp': xp,
    'opted_in': optedIn,
  };
}

/// {@template api_key_row}
/// The API key of an account (AI-04, decisions 158, 161): stored only as
/// its hash; revoked keys stay, refused.
/// {@endtemplate}
final class ApiKeyRow {
  /// {@macro api_key_row}
  const new({
    required this.accountId,
    required this.hash,
    this.revoked = false,
  });

  /// The key [data] holds.
  ///
  /// Throws a [FormatException] for data that is not a key's.
  factory fromData(RowData data) => ApiKeyRow(
    accountId: _as<String>(data, 'account_id'),
    hash: _as<String>(data, 'hash'),
    revoked: _as<bool>(data, 'revoked'),
  );

  /// Its account.
  final String accountId;

  /// The SHA-256 of the key, in hexadecimal.
  final String hash;

  /// Whether it was revoked.
  final bool revoked;

  /// The row's data.
  RowData toData() => {
    'account_id': accountId,
    'hash': hash,
    'revoked': revoked,
  };
}

/// {@template host_row}
/// A simulation host (stack decision 1, hosting), by its host ID, the
/// `host` of the battles it runs: the public [address] its players and AI
/// agents reach it at, and when it was last [seenAt]. A host writes its row
/// at each look at its battles; one not seen for a lease has stopped, and
/// another host of its map may take its battles over.
/// {@endtemplate}
final class HostRow {
  /// {@macro host_row}
  const new({required this.address, required this.seenAt});

  /// The host [data] holds.
  ///
  /// Throws a [FormatException] for data that is not a host's.
  factory fromData(RowData data) => HostRow(
    address: _as<String>(data, 'address'),
    seenAt:
        DateTime.tryParse(_as<String>(data, 'seen_at'))?.toUtc() ??
        (throw const FormatException('not a row: seen_at is not a time')),
  );

  /// Its public address: the base URL of its endpoints, `https://…` live
  /// behind the reverse proxy, `http://…` on the local stack.
  final String address;

  /// When it last wrote its row, in UTC.
  final DateTime seenAt;

  /// Whether it was seen within [lease] before [now].
  bool aliveAt(DateTime now, Duration lease) => now.difference(seenAt) < lease;

  /// The row's data.
  RowData toData() => {
    'address': address,
    'seen_at': seenAt.toUtc().toIso8601String(),
  };
}
