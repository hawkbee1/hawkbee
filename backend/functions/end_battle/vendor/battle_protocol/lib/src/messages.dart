import 'package:battle_protocol/src/command.dart';
import 'package:battle_protocol/src/events.dart';
import 'package:battle_protocol/src/values.dart';
import 'package:equatable/equatable.dart';

// The messages between the host and its clients over the socket (stack
// decision 3, M6 Issue 2), beside the commands, events and log entries.
// Every message carries the format version, as every encoded message does.

/// A message from a client (a player's app or an AI agent) to the host.
sealed class ClientMessage extends Equatable {
  const new();
}

/// How a client proves who it is (stack decision 6).
enum CredentialKind {
  /// A short-lived Appwrite JWT of a player's session.
  jwt,

  /// An account's API key, for an AI agent (AI-04).
  apiKey,
}

/// {@template sign_in}
/// The first message on a socket: the client signs in to [battleId] with a
/// [credential] of [kind]. Its protocol version is the message's own: a
/// host that does not speak it says goodbye
/// ([GoodbyeReason.unsupportedVersion]).
/// {@endtemplate}
final class SignIn extends ClientMessage {
  /// {@macro sign_in}
  const new({
    required this.battleId,
    required this.kind,
    required this.credential,
  });

  /// The battle.
  final String battleId;

  /// What [credential] is.
  final CredentialKind kind;

  /// The JWT or the API key.
  final String credential;

  @override
  List<Object?> get props => [battleId, kind, credential];

  /// The credential is hidden.
  @override
  String toString() => 'SignIn($battleId, $kind)';
}

/// {@template send_command}
/// A [command] with a [requestId] the client chose: the host answers with
/// the same ID ([CommandAccepted], [CommandRefused]), and answers a command
/// resent with an ID it already answered with the first answer again. The
/// host takes the sender from the sign-in, whatever [command] says.
/// {@endtemplate}
final class SendCommand extends ClientMessage {
  /// {@macro send_command}
  const new({required this.requestId, required this.command});

  /// The client's ID for this request.
  final int requestId;

  /// The command.
  final Command command;

  @override
  List<Object?> get props => [requestId, command];
}

/// {@template resync_request}
/// The client asks for its section's whole view again ([SectionView]), for
/// example after it missed updates.
/// {@endtemplate}
final class ResyncRequest extends ClientMessage {
  /// {@macro resync_request}
  const new();

  @override
  List<Object?> get props => const [];
}

/// {@template heartbeat}
/// The client is still there: the host closes an idle socket.
/// {@endtemplate}
final class Heartbeat extends ClientMessage {
  /// {@macro heartbeat}
  const new();

  @override
  List<Object?> get props => const [];
}

/// A message from the host to one client.
sealed class HostMessage extends Equatable {
  const new();
}

/// {@template sign_in_accepted}
/// The sign-in is accepted: the socket is bound to [accountId] and its
/// section [sectionId] of [team], at the battle time [battleTime]. The
/// section's whole view follows.
/// {@endtemplate}
final class SignInAccepted extends HostMessage {
  /// {@macro sign_in_accepted}
  const new({
    required this.accountId,
    required this.sectionId,
    required this.team,
    required this.battleTime,
  });

  /// The signed-in account.
  final String accountId;

  /// Its section in the battle.
  final String sectionId;

  /// The section's team.
  final String team;

  /// The battle time when it signed in.
  final Duration battleTime;

  @override
  List<Object?> get props => [accountId, sectionId, team, battleTime];
}

/// Why a sign-in is refused.
enum SignInRefusal {
  /// The JWT or the API key is not valid, expired or revoked.
  invalidCredential,

  /// The account has no section in the battle.
  noSection,

  /// The battle does not run on this host.
  battleNotFound,
}

/// {@template sign_in_refused}
/// The sign-in is refused for [reason]; the host closes the socket.
/// {@endtemplate}
final class SignInRefused extends HostMessage {
  /// {@macro sign_in_refused}
  const new(this.reason);

  /// Why.
  final SignInRefusal reason;

  @override
  List<Object?> get props => [reason];
}

/// {@template command_accepted}
/// The command of [requestId] is accepted, with the sequence number [seq],
/// once its log entry is on disk (stack decision 2).
/// {@endtemplate}
final class CommandAccepted extends HostMessage {
  /// {@macro command_accepted}
  const new({required this.requestId, required this.seq});

  /// The client's ID for the request.
  final int requestId;

  /// The command's sequence number in the battle.
  final int seq;

  @override
  List<Object?> get props => [requestId, seq];
}

/// {@template command_refused}
/// The command of [requestId] is refused for [reason], the host's refusal
/// code (as in [OrderRefused], for example `not_enough_ap`).
/// {@endtemplate}
final class CommandRefused extends HostMessage {
  /// {@macro command_refused}
  const new({required this.requestId, required this.reason});

  /// The client's ID for the request.
  final int requestId;

  /// The refusal code.
  final String reason;

  @override
  List<Object?> get props => [requestId, reason];
}

/// {@template section_view}
/// The whole view of a section at the battle time [at] (MAP-29, MAP-49):
/// sent after the sign-in, on a resync, and to a section that comes back.
/// The updates of the next ticks build on it.
/// {@endtemplate}
final class SectionView extends HostMessage {
  /// {@macro section_view}
  const new({
    required this.at,
    required this.section,
    required this.units,
    required this.hqs,
    required this.relics,
    required this.world,
    this.hold,
  });

  /// The battle time.
  final Duration at;

  /// The section's own state.
  final SectionPrivate section;

  /// Its own units, wherever they are, with their private state, and the
  /// other units it sees.
  final List<UnitView> units;

  /// Its team's HQ and the enemy HQs it sees.
  final List<HqView> hqs;

  /// Every relic (MAP-49).
  final List<RelicView> relics;

  /// The running victory countdown, when a team holds (RELIC-16).
  final HoldView? hold;

  /// The whole delta layer (MAP-08): the world events since the battle
  /// started, in order ([StructureBuilt], [ObjectDamaged],
  /// [ObjectDestroyed], [CraterDug]).
  final List<BattleEvent> world;

  @override
  List<Object?> get props => [at, section, units, hqs, relics, hold, world];
}

/// {@template tick_update}
/// What changed for a section in the tick that ended at the battle time
/// [at]: nothing that did not change is sent (stack decision 3).
/// {@endtemplate}
final class TickUpdate extends HostMessage {
  /// {@macro tick_update}
  const new({
    required this.at,
    this.moved = const [],
    this.appeared = const [],
    this.gone = const [],
    this.events = const [],
    this.bursts = const [],
    this.unseenHits = const [],
    this.fired = const [],
    this.ownUnits = const [],
    this.section,
    this.hqs = const [],
    this.hqsGone = const [],
    this.relics = const [],
  });

  /// The battle time.
  final Duration at;

  /// The positions of the units it sees that moved: sent when a unit's
  /// position changes (stack decision 3, decision 236).
  final List<UnitPosition> moved;

  /// The units that came into its sight, whole.
  final List<UnitView> appeared;

  /// The units that went out of its sight, by ID.
  final List<String> gone;

  /// The events it may see, cut down to what it sees (COMBAT-57).
  final List<BattleEvent> events;

  /// Each unit's shots of the tick, grouped.
  final List<Burst> bursts;

  /// The hits on units it sees by shooters it does not see: the unit hit
  /// and the damage, nothing of the shooter (COMBAT-57, COMBAT-58,
  /// decisions 234 and 237).
  final List<UnseenHit> unseenHits;

  /// The shots of units it sees whose outcome it does not see whole: the
  /// shooter fired, and only the hits on units it sees are given
  /// (COMBAT-58, decision 237).
  final List<Fired> fired;

  /// Its own units whose private state changed, whole.
  final List<UnitView> ownUnits;

  /// Its own state, when it changed.
  final SectionPrivate? section;

  /// The HQs that came into its sight or changed, whole.
  final List<HqView> hqs;

  /// The teams whose HQ went out of its sight.
  final List<String> hqsGone;

  /// The relics that moved or changed owner (MAP-49).
  final List<RelicView> relics;

  @override
  List<Object?> get props => [
    at,
    moved,
    appeared,
    gone,
    events,
    bursts,
    unseenHits,
    fired,
    ownUnits,
    section,
    hqs,
    hqsGone,
    relics,
  ];
}

/// {@template relic_alert}
/// [relicId] changed owner at the battle time [at]: [team] took it from
/// the team alerted (RELIC-10). The host sends it at once to that team's
/// connected players, and to each of the others when they next connect
/// (decision 233).
/// {@endtemplate}
final class RelicAlert extends HostMessage {
  /// {@macro relic_alert}
  const new({required this.at, required this.relicId, required this.team});

  /// When it changed owner.
  final Duration at;

  /// The relic.
  final String relicId;

  /// Its new owner.
  final String team;

  @override
  List<Object?> get props => [at, relicId, team];
}

/// Why the host closes a socket.
enum GoodbyeReason {
  /// The battle ended.
  battleEnded,

  /// The API key the socket signed in with was revoked.
  keyRevoked,

  /// The host does not speak the client's protocol version.
  unsupportedVersion,

  /// The client read too slowly: it catches up with its whole view when it
  /// comes back.
  slowClient,

  /// The client sent nothing, not even a heartbeat, for too long.
  idle,
}

/// {@template goodbye}
/// The host closes the socket for [reason].
/// {@endtemplate}
final class Goodbye extends HostMessage {
  /// {@macro goodbye}
  const new(this.reason);

  /// Why.
  final GoodbyeReason reason;

  @override
  List<Object?> get props => [reason];
}

// The values of a section's view.

/// Where a unit is (HQ-29, COMBAT-37): only its own section learns it.
enum UnitPlace {
  /// On the field.
  deployed,

  /// In a transport.
  carried,

  /// In storage.
  stored,

  /// A prisoner of another section.
  prisoner,
}

/// {@template ap_view}
/// An AP pool as of its last update: [value] at the battle time [at],
/// recovering [perHour] up to [max]. The client computes the AP at any
/// later time from it (COMBAT-02, stack decision 8).
/// {@endtemplate}
final class ApView extends Equatable {
  /// {@macro ap_view}
  const new({
    required this.value,
    required this.at,
    required this.perHour,
    required this.max,
  });

  /// The AP at [at].
  final double value;

  /// The battle time of its last update.
  final Duration at;

  /// The AP it recovers per hour.
  final double perHour;

  /// Its maximum.
  final double max;

  @override
  List<Object?> get props => [value, at, perHour, max];
}

/// {@template unit_private}
/// What only a unit's own section knows of it.
/// {@endtemplate}
final class UnitPrivate extends Equatable {
  /// {@macro unit_private}
  const new({
    required this.place,
    required this.ap,
    required this.morale,
    required this.rounds,
    required this.xpEarned,
    required this.xpUnspent,
    this.transportId,
    this.movingUntil,
    this.busyUntil,
    this.observingUntil,
  });

  /// Where it is.
  final UnitPlace place;

  /// Its AP pool.
  final ApView ap;

  /// Its morale.
  final double morale;

  /// The rounds in its magazine.
  final int rounds;

  /// Its XP earned.
  final double xpEarned;

  /// Its XP left to spend.
  final double xpUnspent;

  /// Its transport, while carried.
  final String? transportId;

  /// The battle time its move ends, while it moves.
  final Duration? movingUntil;

  /// The battle time its reload, unload or swap ends, while one goes on.
  final Duration? busyUntil;

  /// The battle time its observation ends, while it observes (UNIT-34).
  final Duration? observingUntil;

  @override
  List<Object?> get props => [
    place,
    ap,
    morale,
    rounds,
    xpEarned,
    xpUnspent,
    transportId,
    movingUntil,
    busyUntil,
    observingUntil,
  ];
}

/// {@template unit_view}
/// A unit as a section knows it: what anyone who sees it sees, and, for
/// its own section only, its [private] state. A stored unit or a prisoner
/// has no [position].
/// {@endtemplate}
final class UnitView extends Equatable {
  /// {@macro unit_view}
  const new({
    required this.unitId,
    required this.unitType,
    required this.sectionId,
    required this.team,
    required this.hp,
    required this.maxHp,
    this.position,
    this.flying = false,
    this.weapon,
    this.private,
  });

  /// The unit.
  final String unitId;

  /// Its type.
  final String unitType;

  /// Its section.
  final String sectionId;

  /// Its section's team: a unit seen shows whether it is a friend
  /// (Q-MAP-27, assumed).
  final String team;

  /// Its hit points.
  final double hp;

  /// Its hit points at full health.
  final double maxHp;

  /// Where it stands, on the field.
  final Position? position;

  /// Whether it flies.
  final bool flying;

  /// The weapon in its slot; null when empty.
  final String? weapon;

  /// Its private state, for its own section only.
  final UnitPrivate? private;

  @override
  List<Object?> get props => [
    unitId,
    unitType,
    sectionId,
    team,
    hp,
    maxHp,
    position,
    flying,
    weapon,
    private,
  ];
}

/// {@template unit_position}
/// Where the unit [unitId] moved to (stack decision 3, decision 236),
/// quantised to the centimetre as [Position] is.
/// {@endtemplate}
final class UnitPosition extends Equatable {
  /// {@macro unit_position}
  const new(this.unitId, this.position);

  /// The unit.
  final String unitId;

  /// Its position.
  final Position position;

  @override
  List<Object?> get props => [unitId, position];
}

/// {@template burst}
/// The [shots] [attackerId] of [sectionId] fired with [weapon] in one tick,
/// grouped into one message (stack decision 3): [hits] of them hit, and
/// [impacts] holds each unit hit once, with the damage of all those shots
/// and its last result. The battle log keeps every shot ([Attacked]).
/// {@endtemplate}
final class Burst extends Equatable {
  /// {@macro burst}
  const new({
    required this.attackerId,
    required this.sectionId,
    required this.weapon,
    required this.shots,
    required this.hits,
    required this.impacts,
  });

  /// The shooter.
  final String attackerId;

  /// Its section.
  final String sectionId;

  /// Its weapon.
  final String weapon;

  /// The shots fired in the tick.
  final int shots;

  /// The shots that hit.
  final int hits;

  /// The units hit, each once.
  final List<Impact> impacts;

  @override
  List<Object?> get props => [
    attackerId,
    sectionId,
    weapon,
    shots,
    hits,
    impacts,
  ];
}

/// {@template unseen_hit}
/// [targetId], a unit the section sees, was hit for [damage] with
/// [result] by a shooter the section does not see: nothing of the shooter,
/// not even whether it is a friend (COMBAT-57, decision 234).
/// {@endtemplate}
final class UnseenHit extends Equatable {
  /// {@macro unseen_hit}
  const new({
    required this.targetId,
    required this.damage,
    required this.result,
  });

  /// The unit hit.
  final String targetId;

  /// The damage it took.
  final double damage;

  /// What became of it.
  final ImpactResult result;

  @override
  List<Object?> get props => [targetId, damage, result];
}

/// {@template fired}
/// [attackerId] of [sectionId], a unit the section sees, fired [shots]
/// with [weapon], and the section does not see their whole outcome: their
/// target, or whether they hit, is unknown to it. [impacts] are only the
/// hits on units it sees (COMBAT-58, decision 237).
/// {@endtemplate}
final class Fired extends Equatable {
  /// {@macro fired}
  const new({
    required this.attackerId,
    required this.sectionId,
    required this.weapon,
    required this.shots,
    this.impacts = const [],
  });

  /// The shooter.
  final String attackerId;

  /// Its section.
  final String sectionId;

  /// Its weapon.
  final String weapon;

  /// The shots fired in the update.
  final int shots;

  /// The hits it sees.
  final List<Impact> impacts;

  @override
  List<Object?> get props => [attackerId, sectionId, weapon, shots, impacts];
}

/// {@template hq_view}
/// The HQ of [team] as a section knows it: its own team's always, an enemy
/// HQ while seen or reported (MAP-49). Its [ap] is for its own team only.
/// {@endtemplate}
final class HqView extends Equatable {
  /// {@macro hq_view}
  const new({
    required this.team,
    required this.position,
    required this.hp,
    required this.maxHp,
    this.ap,
  });

  /// The team.
  final String team;

  /// Where it stands.
  final Position position;

  /// Its hit points.
  final double hp;

  /// Its hit points at full health.
  final double maxHp;

  /// Its AP pool, for its own team (HQ-14).
  final ApView? ap;

  @override
  List<Object?> get props => [team, position, hp, maxHp, ap];
}

/// {@template relic_view}
/// A relic, its position and its [owner] team, null before its first
/// capture: every section knows them (MAP-49).
/// {@endtemplate}
final class RelicView extends Equatable {
  /// {@macro relic_view}
  const new({required this.relicId, required this.position, this.owner});

  /// The relic.
  final String relicId;

  /// Where it lies.
  final Position position;

  /// Its owner team.
  final String? owner;

  @override
  List<Object?> get props => [relicId, position, owner];
}

/// {@template hold_view}
/// The victory countdown: [team] has held enough relics since [since] and
/// wins at [winsAt] unless it drops below (RELIC-14, RELIC-16).
/// {@endtemplate}
final class HoldView extends Equatable {
  /// {@macro hold_view}
  const new({required this.team, required this.since, required this.winsAt});

  /// The holding team.
  final String team;

  /// When its hold started.
  final Duration since;

  /// When it wins.
  final Duration winsAt;

  @override
  List<Object?> get props => [team, since, winsAt];
}

/// {@template section_private}
/// A section's own state: only the section receives it.
/// {@endtemplate}
final class SectionPrivate extends Equatable {
  /// {@macro section_private}
  const new({
    required this.money,
    required this.xp,
    this.lockedUntil,
    this.storedWeapons = const [],
    this.prisoners = const [],
    this.offers = const [],
  });

  /// Its money, in whole w€.
  final int money;

  /// Its section XP.
  final double xp;

  /// The end of its full storage lock (HQ-35); null without one.
  final Duration? lockedUntil;

  /// Its spare weapons (decision 151).
  final List<String> storedWeapons;

  /// The units of other sections it holds prisoner, with their types.
  final List<JoinedUnit> prisoners;

  /// The prisoner offers it posted or received, still open.
  final List<OfferPosted> offers;

  @override
  List<Object?> get props => [
    money,
    xp,
    lockedUntil,
    storedWeapons,
    prisoners,
    offers,
  ];
}
