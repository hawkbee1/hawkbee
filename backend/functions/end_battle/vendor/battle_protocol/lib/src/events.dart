import 'package:battle_protocol/src/values.dart';
import 'package:equatable/equatable.dart';

/// An outcome the host produced: the result of an order, or what the host
/// did on its own (timers, captures, the end of a battle). Events are
/// logged with the order that caused them and sent to the players who may
/// see them (Observer, stack decision 7; stack decisions 2 and 3).
sealed class BattleEvent extends Equatable {
  const new();
}

// Orders.

/// {@template order_refused}
/// The order [seq] was refused for [reason] and changed nothing. [reason]
/// is the host's refusal code, for example `not_enough_ap`.
/// {@endtemplate}
final class OrderRefused extends BattleEvent {
  /// {@macro order_refused}
  const new({required this.seq, required this.reason});

  /// The refused order's sequence number.
  final int seq;

  /// Why, as a code.
  final String reason;

  @override
  List<Object?> get props => [seq, reason];
}

/// {@template order_delayed}
/// The order [seq] waits for AP until [until] (COMBAT-06); the host checks
/// it again then, and its outcome comes in a later entry.
/// {@endtemplate}
final class OrderDelayed extends BattleEvent {
  /// {@macro order_delayed}
  const new({required this.seq, required this.until});

  /// The waiting order's sequence number.
  final int seq;

  /// The battle time it is carried out.
  final Duration until;

  @override
  List<Object?> get props => [seq, until];
}

// Movement.

/// {@template move_started}
/// [moverId], a unit, an HQ or a pushed relic, started moving and arrives
/// at [arrivesAt].
/// {@endtemplate}
final class MoveStarted extends BattleEvent {
  /// {@macro move_started}
  const new({required this.moverId, required this.arrivesAt});

  /// What moves.
  final String moverId;

  /// The battle time it arrives.
  final Duration arrivesAt;

  @override
  List<Object?> get props => [moverId, arrivesAt];
}

/// {@template move_stopped}
/// [moverId] stopped at [at] before its goal: a unit in an HQ's path
/// (HQ-12), an empty push pot (RELIC-24), a unit the relic does not crush
/// (RELIC-25).
/// {@endtemplate}
final class MoveStopped extends BattleEvent {
  /// {@macro move_stopped}
  const new({required this.moverId, required this.at});

  /// What stopped.
  final String moverId;

  /// Where.
  final Position at;

  @override
  List<Object?> get props => [moverId, at];
}

// Combat.

/// What a hit did to its target.
enum ImpactResult {
  /// It lost HP and is still there.
  damaged,

  /// It died, or was destroyed for an object or an HQ.
  killed,

  /// It was taken prisoner by the attacker's section (COMBAT-38).
  prisoner,

  /// It joined the attacker's section (COMBAT-38).
  defected,
}

/// {@template impact}
/// [damage] dealt to [targetId], of type [targetType] (a unit type, an
/// object type or `hq`), [friendly] when it is on the attacker's team, and
/// what it did ([result]).
/// {@endtemplate}
final class Impact extends Equatable {
  /// {@macro impact}
  const new({
    required this.targetId,
    required this.targetType,
    required this.damage,
    required this.friendly,
    required this.result,
  });

  /// The target.
  final String targetId;

  /// Its type, for kills by target type (SOC-26).
  final String targetType;

  /// The HP it lost.
  final double damage;

  /// Whether it is on the attacker's team (COMBAT-35).
  final bool friendly;

  /// What the hit did.
  final ImpactResult result;

  @override
  List<Object?> get props => [targetId, targetType, damage, friendly, result];
}

/// {@template attacked}
/// The outcome of one attack, in the same log entry as the attack so that
/// statistics need no replay (stack decision 2): [attackerId] of
/// [sectionId] fired [weapon]; [hit] tells whether the roll or the
/// projectile hit what it aimed at, and [impacts] lists every target hurt,
/// splash and carried units included (COMBAT-54, COMBAT-55).
/// {@endtemplate}
final class Attacked extends BattleEvent {
  /// {@macro attacked}
  const new({
    required this.attackerId,
    required this.sectionId,
    required this.weapon,
    required this.hit,
    required this.impacts,
  });

  /// The attacker.
  final String attackerId;

  /// The attacker's section.
  final String sectionId;

  /// The weapon type fired.
  final String weapon;

  /// Whether it hit its aim.
  final bool hit;

  /// The targets hurt.
  final List<Impact> impacts;

  @override
  List<Object?> get props => [attackerId, sectionId, weapon, hit, impacts];
}

/// {@template crushed}
/// [unitId], of type [unitType], was killed by [byId], a relic that
/// crushed it (RELIC-25) or a relic or an HQ that fell on it (decision
/// 138).
/// {@endtemplate}
final class Crushed extends BattleEvent {
  /// {@macro crushed}
  const new({required this.byId, required this.unitId, required this.unitType});

  /// The relic or the HQ.
  final String byId;

  /// The killed unit.
  final String unitId;

  /// Its type.
  final String unitType;

  @override
  List<Object?> get props => [byId, unitId, unitType];
}

/// {@template weapon_dropped}
/// A [weapon] dropped at [at], as [droppedId], by a killed unit or one that
/// picked up another weapon; it vanishes at [goneAt] (COMBAT-29 to
/// COMBAT-31).
/// {@endtemplate}
final class WeaponDropped extends BattleEvent {
  /// {@macro weapon_dropped}
  const new({
    required this.droppedId,
    required this.weapon,
    required this.at,
    required this.goneAt,
  });

  /// The dropped weapon.
  final String droppedId;

  /// Its weapon type.
  final String weapon;

  /// Where it lies.
  final Position at;

  /// The battle time it vanishes.
  final Duration goneAt;

  @override
  List<Object?> get props => [droppedId, weapon, at, goneAt];
}

/// {@template weapon_picked_up}
/// [unitId] picked up [droppedId], which arrives unloaded (COMBAT-30).
/// {@endtemplate}
final class WeaponPickedUp extends BattleEvent {
  /// {@macro weapon_picked_up}
  const new({required this.unitId, required this.droppedId});

  /// The unit.
  final String unitId;

  /// The weapon it took.
  final String droppedId;

  @override
  List<Object?> get props => [unitId, droppedId];
}

/// {@template weapon_swapped}
/// [unitId] took [weapon] from storage; it is done at [readyAt]
/// (COMBAT-28).
/// {@endtemplate}
final class WeaponSwapped extends BattleEvent {
  /// {@macro weapon_swapped}
  const new({
    required this.unitId,
    required this.weapon,
    required this.readyAt,
  });

  /// The unit.
  final String unitId;

  /// The weapon type it took.
  final String weapon;

  /// The battle time the swap ends.
  final Duration readyAt;

  @override
  List<Object?> get props => [unitId, weapon, readyAt];
}

/// An action that costs only time (COMBAT-05), apart from the weapon swap.
enum TimeOnly {
  /// A reload.
  reload,

  /// A weapon unload.
  unloadWeapon,

  /// A landing.
  land,

  /// A take-off.
  takeOff,
}

/// {@template time_only_started}
/// [unitId] started [action], which ends at [endsAt].
/// {@endtemplate}
final class TimeOnlyStarted extends BattleEvent {
  /// {@macro time_only_started}
  const new({required this.unitId, required this.action, required this.endsAt});

  /// The unit.
  final String unitId;

  /// The action.
  final TimeOnly action;

  /// The battle time it ends.
  final Duration endsAt;

  @override
  List<Object?> get props => [unitId, action, endsAt];
}

// Transports.

/// {@template embarked}
/// [unitId] got into [transportId].
/// {@endtemplate}
final class Embarked extends BattleEvent {
  /// {@macro embarked}
  const new({required this.unitId, required this.transportId});

  /// The carried unit.
  final String unitId;

  /// The transport.
  final String transportId;

  @override
  List<Object?> get props => [unitId, transportId];
}

/// {@template disembarked}
/// [unitId] got off its transport at [at], by order or set down
/// (UNIT-29).
/// {@endtemplate}
final class Disembarked extends BattleEvent {
  /// {@macro disembarked}
  const new({required this.unitId, required this.at});

  /// The unit.
  final String unitId;

  /// Where it stands.
  final Position at;

  @override
  List<Object?> get props => [unitId, at];
}

// Role actions.

/// {@template build_started}
/// [unitId] started building [structure] on [cells], the site [siteId],
/// done at [endsAt] (COMBAT-07).
/// {@endtemplate}
final class BuildStarted extends BattleEvent {
  /// {@macro build_started}
  const new({
    required this.unitId,
    required this.siteId,
    required this.structure,
    required this.cells,
    required this.endsAt,
  });

  /// The builder.
  final String unitId;

  /// The construction site.
  final String siteId;

  /// The structure.
  final String structure;

  /// Its cells.
  final List<Cell> cells;

  /// The battle time it is built.
  final Duration endsAt;

  @override
  List<Object?> get props => [unitId, siteId, structure, cells, endsAt];
}

/// {@template repair_started}
/// [unitId] started repairing [targetId], done at [endsAt].
/// {@endtemplate}
final class RepairStarted extends BattleEvent {
  /// {@macro repair_started}
  const new({
    required this.unitId,
    required this.targetId,
    required this.endsAt,
  });

  /// The engineer.
  final String unitId;

  /// What is repaired.
  final String targetId;

  /// The battle time it is done.
  final Duration endsAt;

  @override
  List<Object?> get props => [unitId, targetId, endsAt];
}

/// {@template work_resumed}
/// [unitId] resumed the build or repair [workId], done at [endsAt]
/// (COMBAT-09).
/// {@endtemplate}
final class WorkResumed extends BattleEvent {
  /// {@macro work_resumed}
  const new({required this.unitId, required this.workId, required this.endsAt});

  /// The unit.
  final String unitId;

  /// The site or the repaired target.
  final String workId;

  /// The battle time it is done.
  final Duration endsAt;

  @override
  List<Object?> get props => [unitId, workId, endsAt];
}

/// {@template work_interrupted}
/// The build or repair [workId] of [unitId] stopped: its AP are lost, its
/// progress kept (COMBAT-09).
/// {@endtemplate}
final class WorkInterrupted extends BattleEvent {
  /// {@macro work_interrupted}
  const new({required this.unitId, required this.workId});

  /// The unit.
  final String unitId;

  /// The site or the repaired target.
  final String workId;

  @override
  List<Object?> get props => [unitId, workId];
}

/// {@template structure_built}
/// [structure] stands on [cells], as [siteId]: a change of the world's
/// delta layer (MAP-06).
/// {@endtemplate}
final class StructureBuilt extends BattleEvent {
  /// {@macro structure_built}
  const new({
    required this.siteId,
    required this.structure,
    required this.cells,
  });

  /// The construction.
  final String siteId;

  /// The structure.
  final String structure;

  /// Its cells.
  final List<Cell> cells;

  @override
  List<Object?> get props => [siteId, structure, cells];
}

/// {@template repaired}
/// The repair of [targetId] is done; it has [hp] HP.
/// {@endtemplate}
final class Repaired extends BattleEvent {
  /// {@macro repaired}
  const new({required this.targetId, required this.hp});

  /// What was repaired.
  final String targetId;

  /// Its HP.
  final double hp;

  @override
  List<Object?> get props => [targetId, hp];
}

/// {@template unit_healed}
/// [unitId] healed [targetId], which has [hp] HP (UNIT-35).
/// {@endtemplate}
final class UnitHealed extends BattleEvent {
  /// {@macro unit_healed}
  const new({required this.unitId, required this.targetId, required this.hp});

  /// The healer.
  final String unitId;

  /// The healed unit.
  final String targetId;

  /// Its HP.
  final double hp;

  @override
  List<Object?> get props => [unitId, targetId, hp];
}

/// {@template observation_started}
/// The scout [unitId] observes until [endsAt] (UNIT-34).
/// {@endtemplate}
final class ObservationStarted extends BattleEvent {
  /// {@macro observation_started}
  const new({required this.unitId, required this.endsAt});

  /// The scout.
  final String unitId;

  /// The battle time it ends.
  final Duration endsAt;

  @override
  List<Object?> get props => [unitId, endsAt];
}

// Relics.

/// {@template added_to_capture}
/// [unitId] added to the capture pot of [relicId], which holds [potAp];
/// once full, the relic is captured at [capturedAt] unless an enemy comes
/// (RELIC-05, RELIC-08).
/// {@endtemplate}
final class AddedToCapture extends BattleEvent {
  /// {@macro added_to_capture}
  const new({
    required this.unitId,
    required this.relicId,
    required this.potAp,
    this.capturedAt,
  });

  /// The contributor.
  final String unitId;

  /// The relic.
  final String relicId;

  /// The AP in the pot.
  final double potAp;

  /// The battle time of the capture; null while the pot is not full.
  final Duration? capturedAt;

  @override
  List<Object?> get props => [unitId, relicId, potAp, capturedAt];
}

/// {@template added_to_push}
/// [unitId] added to the push pot of [relicId], which holds [potAp]
/// (RELIC-24).
/// {@endtemplate}
final class AddedToPush extends BattleEvent {
  /// {@macro added_to_push}
  const new({required this.unitId, required this.relicId, required this.potAp});

  /// The pusher.
  final String unitId;

  /// The relic.
  final String relicId;

  /// The AP in the pot.
  final double potAp;

  @override
  List<Object?> get props => [unitId, relicId, potAp];
}

/// {@template capture_lost}
/// An enemy entered the radius of [relicId]: the capture by [team] loses
/// its progress and its pot (RELIC-08).
/// {@endtemplate}
final class CaptureLost extends BattleEvent {
  /// {@macro capture_lost}
  const new({required this.relicId, required this.team});

  /// The relic.
  final String relicId;

  /// The team that was capturing.
  final String team;

  @override
  List<Object?> get props => [relicId, team];
}

/// {@template relic_captured}
/// [team] captured [relicId]; [previousOwner], when there was one, is
/// alerted (RELIC-10, RELIC-11).
/// {@endtemplate}
final class RelicCaptured extends BattleEvent {
  /// {@macro relic_captured}
  const new({required this.relicId, required this.team, this.previousOwner});

  /// The relic.
  final String relicId;

  /// Its new owner.
  final String team;

  /// Its owner before; null when it had none.
  final String? previousOwner;

  @override
  List<Object?> get props => [relicId, team, previousOwner];
}

/// {@template relic_lost}
/// [relicId] was lost with a destroyed reinforced bridge and left the
/// battle (RELIC-26).
/// {@endtemplate}
final class RelicLost extends BattleEvent {
  /// {@macro relic_lost}
  const new({required this.relicId, this.previousOwner});

  /// The relic.
  final String relicId;

  /// Its owner then; null when it had none.
  final String? previousOwner;

  @override
  List<Object?> get props => [relicId, previousOwner];
}

// Victory.

/// {@template victory_hold_started}
/// [team] holds enough relics and wins at [winsAt] unless it drops below
/// (RELIC-14, RELIC-16).
/// {@endtemplate}
final class VictoryHoldStarted extends BattleEvent {
  /// {@macro victory_hold_started}
  const new({required this.team, required this.winsAt});

  /// The holding team.
  final String team;

  /// The battle time it wins.
  final Duration winsAt;

  @override
  List<Object?> get props => [team, winsAt];
}

/// {@template victory_hold_reset}
/// [team] dropped below the relics to hold: its countdown resets fully
/// (RELIC-15).
/// {@endtemplate}
final class VictoryHoldReset extends BattleEvent {
  /// {@macro victory_hold_reset}
  const new({required this.team});

  /// The team that held.
  final String team;

  @override
  List<Object?> get props => [team];
}

/// How a team lost its HQ.
enum HqLoss {
  /// The HQ was destroyed (HQ-16, HQ-18).
  destroyed,

  /// The HQ stood on a reinforced bridge that was destroyed (HQ-23).
  lostWithBridge,
}

/// {@template eliminated}
/// [team] is eliminated by the [loss] of its HQ (HQ-18, HQ-23).
/// {@endtemplate}
final class Eliminated extends BattleEvent {
  /// {@macro eliminated}
  const new({required this.team, required this.loss});

  /// The eliminated team.
  final String team;

  /// How it lost its HQ.
  final HqLoss loss;

  @override
  List<Object?> get props => [team, loss];
}

// Storage.

/// {@template unit_stored}
/// [unitId] is in storage: stored, recalled, sent there by its
/// commander's death or its team's elimination, or a released prisoner.
/// {@endtemplate}
final class UnitStored extends BattleEvent {
  /// {@macro unit_stored}
  const new({required this.unitId});

  /// The unit.
  final String unitId;

  @override
  List<Object?> get props => [unitId];
}

/// {@template recall_began}
/// [unitId] is recalled and is stored at [storedAt] unless it dies first
/// (HQ-32).
/// {@endtemplate}
final class RecallBegan extends BattleEvent {
  /// {@macro recall_began}
  const new({required this.unitId, required this.storedAt});

  /// The unit.
  final String unitId;

  /// The battle time it is stored.
  final Duration storedAt;

  @override
  List<Object?> get props => [unitId, storedAt];
}

/// {@template unit_deployed}
/// [unitId] is on the field at [at]: deployed, or a bought unit that
/// arrived (HQ-33, HQ-46).
/// {@endtemplate}
final class UnitDeployed extends BattleEvent {
  /// {@macro unit_deployed}
  const new({required this.unitId, required this.at});

  /// The unit.
  final String unitId;

  /// Where it stands.
  final Position at;

  @override
  List<Object?> get props => [unitId, at];
}

/// {@template section_locked}
/// [sectionId] has no unit left on the field and cannot deploy before
/// [until] (HQ-35).
/// {@endtemplate}
final class SectionLocked extends BattleEvent {
  /// {@macro section_locked}
  const new({required this.sectionId, required this.until});

  /// The section.
  final String sectionId;

  /// The battle time the lock ends.
  final Duration until;

  @override
  List<Object?> get props => [sectionId, until];
}

// Money and progression.

/// {@template unit_purchased}
/// [sectionId] bought [unitId], of [unitType], for [price] w€ (ECO-04 to
/// ECO-06).
/// {@endtemplate}
final class UnitPurchased extends BattleEvent {
  /// {@macro unit_purchased}
  const new({
    required this.sectionId,
    required this.unitId,
    required this.unitType,
    required this.price,
  });

  /// The buyer.
  final String sectionId;

  /// The new unit.
  final String unitId;

  /// Its type.
  final String unitType;

  /// What it cost, in whole w€.
  final int price;

  @override
  List<Object?> get props => [sectionId, unitId, unitType, price];
}

/// {@template weapon_purchased}
/// [sectionId] bought [weapon] for [price] w€ (COMBAT-27).
/// {@endtemplate}
final class WeaponPurchased extends BattleEvent {
  /// {@macro weapon_purchased}
  const new({
    required this.sectionId,
    required this.weapon,
    required this.price,
  });

  /// The buyer.
  final String sectionId;

  /// The weapon type.
  final String weapon;

  /// What it cost, in whole w€.
  final int price;

  @override
  List<Object?> get props => [sectionId, weapon, price];
}

/// {@template money_transferred}
/// [fromSectionId] sent money to [toSectionId], which received [received]
/// w€; the [fee] was destroyed (ECO-08 to ECO-11).
/// {@endtemplate}
final class MoneyTransferred extends BattleEvent {
  /// {@macro money_transferred}
  const new({
    required this.fromSectionId,
    required this.toSectionId,
    required this.received,
    required this.fee,
  });

  /// The sending section.
  final String fromSectionId;

  /// The receiving section.
  final String toSectionId;

  /// What it received, in whole w€.
  final int received;

  /// The fee, in whole w€.
  final int fee;

  @override
  List<Object?> get props => [fromSectionId, toSectionId, received, fee];
}

/// {@template node_purchased}
/// [unitId] bought step [step] of [stat] (UNIT-18).
/// {@endtemplate}
final class NodePurchased extends BattleEvent {
  /// {@macro node_purchased}
  const new({required this.unitId, required this.stat, required this.step});

  /// The unit.
  final String unitId;

  /// The stat.
  final String stat;

  /// The step.
  final int step;

  @override
  List<Object?> get props => [unitId, stat, step];
}

// Prisoners.

/// {@template offer_posted}
/// The offer [offerId] of [captorSectionId] to [ownerSectionId]: release
/// [released] against [wanted] (an exchange) or [price] w€ (a ransom)
/// (COMBAT-44).
/// {@endtemplate}
final class OfferPosted extends BattleEvent {
  /// {@macro offer_posted}
  const new({
    required this.offerId,
    required this.captorSectionId,
    required this.ownerSectionId,
    required this.released,
    required this.wanted,
    required this.price,
  });

  /// The offer, the sequence number of the order that posted it.
  final int offerId;

  /// The captor.
  final String captorSectionId;

  /// The prisoners' owner.
  final String ownerSectionId;

  /// The prisoners released.
  final List<String> released;

  /// The captor's units asked back; empty for a ransom.
  final List<String> wanted;

  /// The ransom in whole w€; 0 for an exchange.
  final int price;

  @override
  List<Object?> get props => [
    offerId,
    captorSectionId,
    ownerSectionId,
    released,
    wanted,
    price,
  ];
}

/// {@template offer_accepted}
/// The offer [offerId] was accepted: its prisoners return to their owners'
/// storage and the ransom goes to the captor.
/// {@endtemplate}
final class OfferAccepted extends BattleEvent {
  /// {@macro offer_accepted}
  const new({required this.offerId});

  /// The offer.
  final int offerId;

  @override
  List<Object?> get props => [offerId];
}

/// {@template offer_refused}
/// The offer [offerId] was refused.
/// {@endtemplate}
final class OfferRefused extends BattleEvent {
  /// {@macro offer_refused}
  const new({required this.offerId});

  /// The offer.
  final int offerId;

  @override
  List<Object?> get props => [offerId];
}

// The battle.

/// {@template manager_changed}
/// [accountId] manages the HQ of [team]: the first of its players to log
/// in, a higher-ranking one who logs in later, or the one the role is
/// delegated to (HQ-05, HQ-07, decision 220).
/// {@endtemplate}
final class ManagerChanged extends BattleEvent {
  /// {@macro manager_changed}
  const new({required this.team, required this.accountId});

  /// The team.
  final String team;

  /// The manager.
  final String accountId;

  @override
  List<Object?> get props => [team, accountId];
}

/// {@template battle_started}
/// The battle [battleId] started on [mapId] with the random [seed], the
/// input a replay needs besides the orders (stack decision 2).
/// {@endtemplate}
final class BattleStarted extends BattleEvent {
  /// {@macro battle_started}
  const new({required this.battleId, required this.mapId, required this.seed});

  /// The battle.
  final String battleId;

  /// Its map.
  final String mapId;

  /// The seed of its random.
  final int seed;

  @override
  List<Object?> get props => [battleId, mapId, seed];
}

/// How a battle is won.
enum WinKind {
  /// Only the winner's HQ remains (HQ-45).
  lastHq,

  /// The winner held the relics for the hold time (RELIC-14).
  relics,
}

/// {@template battle_ended}
/// The battle ended: [winner] won by [kind]; [eliminated] lists the
/// eliminated teams in their order.
/// {@endtemplate}
final class BattleEnded extends BattleEvent {
  /// {@macro battle_ended}
  const new({
    required this.winner,
    required this.kind,
    required this.eliminated,
  });

  /// The winning team.
  final String winner;

  /// How it won.
  final WinKind kind;

  /// The teams eliminated, first first.
  final List<String> eliminated;

  @override
  List<Object?> get props => [winner, kind, eliminated];
}

// The world (MAP-06 to MAP-10).

/// {@template object_damaged}
/// The [object] on [cells] took a hit and has [hp] HP left (MAP-10): a
/// tree, a building or a construction.
/// {@endtemplate}
final class ObjectDamaged extends BattleEvent {
  /// {@macro object_damaged}
  const new({required this.object, required this.cells, required this.hp});

  /// The object type.
  final String object;

  /// Where it stands: one cell, or both ends of a ladder or a bridge to an
  /// island.
  final List<Cell> cells;

  /// Its HP left.
  final double hp;

  @override
  List<Object?> get props => [object, cells, hp];
}

/// {@template object_destroyed}
/// The [object] on [cells] was destroyed: it stops blocking and never
/// regrows (MAP-09, MAP-28); a destroyed ladder or bridge may strand units
/// (MAP-37).
/// {@endtemplate}
final class ObjectDestroyed extends BattleEvent {
  /// {@macro object_destroyed}
  const new({required this.object, required this.cells});

  /// The object type.
  final String object;

  /// Where it stood.
  final List<Cell> cells;

  @override
  List<Object?> get props => [object, cells];
}

/// {@template crater_dug}
/// A shot dug a crater at [at], [radiusM] wide and [depthM] deep at its
/// centre (MAP-07, MAP-46).
/// {@endtemplate}
final class CraterDug extends BattleEvent {
  /// {@macro crater_dug}
  const new({required this.at, required this.radiusM, required this.depthM});

  /// Its centre, on the ground.
  final Position at;

  /// Its radius, in metres.
  final double radiusM;

  /// Its depth at the centre, in metres.
  final double depthM;

  @override
  List<Object?> get props => [at, radiusM, depthM];
}

/// {@template joined_unit}
/// A unit a section brings into the battle: its [unitId] and [unitType].
/// {@endtemplate}
final class JoinedUnit extends Equatable {
  /// {@macro joined_unit}
  const new({required this.unitId, required this.unitType});

  /// The unit.
  final String unitId;

  /// Its unit type.
  final String unitType;

  @override
  List<Object?> get props => [unitId, unitType];
}

/// {@template section_joined}
/// [sectionId], the section of the player [accountId], joined [team] with
/// its [units]: at the battle start, or later for a newcomer (SOC-30). The
/// statistics learn from it whose each unit is (decisions 74, 143).
/// {@endtemplate}
final class SectionJoined extends BattleEvent {
  /// {@macro section_joined}
  const new({
    required this.sectionId,
    required this.accountId,
    required this.team,
    required this.units,
  });

  /// The section.
  final String sectionId;

  /// Its player's account.
  final String accountId;

  /// Its team.
  final String team;

  /// Its units, the commander included.
  final List<JoinedUnit> units;

  @override
  List<Object?> get props => [sectionId, accountId, team, units];
}
