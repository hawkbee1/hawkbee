import 'package:battle_protocol/battle_protocol.dart';
import 'package:battle_stats/src/stats.dart';

/// First-person shots per player and weapon, by account then weapon.
typedef AimedShots = Map<String, Map<String, Shots>>;

/// {@template battle_tally}
/// The statistics of one battle, from its log (SOC-22, decisions 74, 143):
/// per unit, per section and per player, read entry by entry in log order.
///
/// The start entry names every section, its player and its units
/// (`SectionJoined`); a purchase adds a unit to its section, and a
/// defection moves one to its captor's. An attack counts for its attacker:
/// an enemy hit, a kill or a friendly kill by target type, a prisoner, a
/// defection; and a loss for the victim's section. Builds, repairs, heals,
/// observations and pot contributions count for the unit that made them.
///
/// It also keeps the first-person shots of each battle-day per player and
/// weapon, which the hit-rate flag reads (decision 230).
/// {@endtemplate}
final class BattleTally {
  /// {@macro battle_tally}
  new();

  final _units = <String, Stats>{};
  final _sections = <String, Stats>{};
  final _players = <String, Stats>{};
  final _sectionOf = <String, String>{};
  final _accountOf = <String, String>{};
  final _workers = <String, String>{};
  final _aimed = <int, AimedShots>{};

  /// Waiting first-person orders, by sequence number: their unit and the
  /// end of their wait.
  final _waitingAimed = <int, (String, Duration)>{};

  /// The stats of each unit that did something, by unit ID.
  Map<String, Stats> get units => Map.unmodifiable(_units);

  /// The stats of each section, by section ID.
  Map<String, Stats> get sections => Map.unmodifiable(_sections);

  /// The stats of each player, by account.
  Map<String, Stats> get players => Map.unmodifiable(_players);

  /// The player of each section, by section ID.
  Map<String, String> get accounts => Map.unmodifiable(_accountOf);

  /// The first-person shots of the battle-day [day], from the battle's
  /// start, per player and weapon.
  AimedShots aimedShotsOn(int day) => Map.unmodifiable(_aimed[day] ?? {});

  /// The battle-days with first-person shots.
  Iterable<int> get aimedDays => _aimed.keys;

  /// Reads [entries], in log order.
  void addAll(Iterable<LogEntry> entries) => entries.forEach(add);

  /// Reads [entry], the next of the log.
  ///
  /// Throws a [StateError] for a unit or a section the log has not named.
  void add(LogEntry entry) {
    final aimedBy = switch (entry.command) {
      Command(order: FireAimed(:final unitId), :final seq) => (unitId, seq),
      _ => null,
    };
    for (final event in entry.events) {
      switch (event) {
        case SectionJoined(:final sectionId, :final accountId, :final units):
          _accountOf[sectionId] = accountId;
          _sections.putIfAbsent(sectionId, Stats.new);
          _players.putIfAbsent(accountId, Stats.new);
          for (final unit in units) {
            _sectionOf[unit.unitId] = sectionId;
          }
        case UnitPurchased(:final sectionId, :final unitId):
          _sectionOf[unitId] = sectionId;
        case OrderDelayed(:final seq, :final until)
            when aimedBy != null && aimedBy.$2 == seq:
          _waitingAimed[seq] = (aimedBy.$1, until);
        case OrderRefused(:final seq) when entry.command == null:
          _waitingAimed.remove(seq);
        case Attacked():
          final aimed =
              aimedBy?.$1 == event.attackerId ||
              (entry.command == null && _tookWaiting(event.attackerId, entry));
          _attacked(event, entry.at, aimed: aimed);
        case Crushed(:final unitId):
          _lose(unitId, Loss.crushed);
        case BuildStarted(:final unitId, :final siteId):
          _workers[siteId] = unitId;
        case RepairStarted(:final unitId, :final targetId):
          _workers[targetId] = unitId;
        case WorkResumed(:final unitId, :final workId):
          _workers[workId] = unitId;
        case StructureBuilt(:final siteId):
          _act(_workers[siteId]!, ActionKind.build);
        case Repaired(:final targetId):
          _act(_workers[targetId]!, ActionKind.repair);
        case UnitHealed(:final unitId):
          _act(unitId, ActionKind.heal);
        case ObservationStarted(:final unitId):
          _act(unitId, ActionKind.observe);
        case AddedToCapture(:final unitId):
          _act(unitId, ActionKind.capture);
        case AddedToPush(:final unitId):
          _act(unitId, ActionKind.push);
        case _:
          break;
      }
    }
  }

  /// Whether [unitId] had a first-person order waiting until this entry's
  /// time: it is that order's shot.
  bool _tookWaiting(String unitId, LogEntry entry) {
    for (final MapEntry(key: seq, value: (unit, until))
        in _waitingAimed.entries) {
      if (unit == unitId && until == entry.at) {
        _waitingAimed.remove(seq);
        return true;
      }
    }
    return false;
  }

  void _attacked(Attacked attack, Duration at, {required bool aimed}) {
    final shot = Shots(fired: 1, hits: attack.hit ? 1 : 0);
    var done = Stats(shots: {attack.weapon: shot});
    final account = _account(attack.sectionId);
    if (aimed) {
      final day = (_aimed[at.inDays] ??= {})[account] ??= {};
      day[attack.weapon] = (day[attack.weapon] ?? const Shots()) + shot;
    }
    for (final impact in attack.impacts) {
      final type = impact.targetType;
      final out = impact.result != ImpactResult.damaged;
      final action = switch (impact) {
        Impact(friendly: true) => null,
        Impact(result: ImpactResult.prisoner) => ActionKind.prisonerTaken,
        Impact(result: ImpactResult.defected) => ActionKind.defectionCaused,
        _ when type == hqTargetType => ActionKind.hqHit,
        _ => ActionKind.hit,
      };
      done += Stats(
        actions: {?action: 1},
        kills: {
          if (impact.result == ImpactResult.killed && !impact.friendly) type: 1,
        },
        friendlyKills: {
          if (impact.result == ImpactResult.killed && impact.friendly) type: 1,
        },
      );
      if (out && type != hqTargetType) {
        _lose(impact.targetId, switch (impact.result) {
          ImpactResult.prisoner => Loss.prisoner,
          ImpactResult.defected => Loss.defected,
          _ => Loss.killed,
        });
      }
      if (impact.result == ImpactResult.defected) {
        _sectionOf[impact.targetId] = attack.sectionId;
      }
    }
    _count(attack.attackerId, attack.sectionId, done);
  }

  void _act(String unitId, String kind) =>
      _count(unitId, _section(unitId), Stats(actions: {kind: 1}));

  void _lose(String unitId, Loss loss) {
    final section = _section(unitId);
    final lost = Stats(losses: {loss: 1});
    _sections[section] = _sections[section]! + lost;
    final account = _account(section);
    _players[account] = _players[account]! + lost;
  }

  void _count(String unitId, String sectionId, Stats done) {
    _units[unitId] = (_units[unitId] ?? Stats()) + done;
    _sections[sectionId] = _sections[sectionId]! + done;
    final account = _account(sectionId);
    _players[account] = _players[account]! + done;
  }

  String _section(String unitId) =>
      _sectionOf[unitId] ??
      (throw StateError('the log names $unitId before its section'));

  String _account(String sectionId) =>
      _accountOf[sectionId] ??
      (throw StateError('the log names $sectionId before it joined'));
}
