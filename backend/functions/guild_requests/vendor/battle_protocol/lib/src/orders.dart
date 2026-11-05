import 'package:battle_protocol/src/values.dart';
import 'package:equatable/equatable.dart';

/// What a sender asks the host to do: the arguments of a `Command`. Every
/// sender uses the same orders: players, AI agents and the server (AI-03,
/// AI-09, stack decision 3). Orders carry IDs and plain values; the host
/// maps them to the rules.
sealed class Order extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}

/// {@template unit_order}
/// An order for one unit, [unitId], of the sender's section (or, for a
/// pick-up, any unit next to a dropped weapon).
/// {@endtemplate}
sealed class UnitOrder extends Order {
  /// {@macro unit_order}
  const new({required this.unitId});

  /// The unit.
  final String unitId;

  @override
  List<Object?> get props => [unitId];
}

/// {@template move}
/// Move [unitId] to [to], along the client's [path] when it sends one: the
/// host checks it cell by cell, or searches a path when it is absent (stack
/// decision 8). First-person movement is a stream of short moves (stack
/// decision 3).
/// {@endtemplate}
final class Move extends UnitOrder {
  /// {@macro move}
  const new({required super.unitId, required this.to, this.path});

  /// Where to go.
  final Position to;

  /// The client's path, from the unit's cell to the cell of [to].
  final List<Cell>? path;

  @override
  List<Object?> get props => [unitId, to, path];
}

/// {@template fire}
/// [unitId] fires at [targetId], a unit, an object or an HQ it sees
/// (COMBAT-11, COMBAT-15).
/// {@endtemplate}
final class Fire extends UnitOrder {
  /// {@macro fire}
  const new({required super.unitId, required this.targetId});

  /// The target.
  final String targetId;

  @override
  List<Object?> get props => [unitId, targetId];
}

/// {@template fire_at_position}
/// [unitId] fires at the ground position [target]: indirect fire
/// (COMBAT-12) or the explosive charge (COMBAT-55).
/// {@endtemplate}
final class FireAtPosition extends UnitOrder {
  /// {@macro fire_at_position}
  const new({required super.unitId, required this.target});

  /// The aimed point.
  final Position target;

  @override
  List<Object?> get props => [unitId, target];
}

/// {@template fire_aimed}
/// A first-person shot: [unitId] fires toward [aim] at [fireTime]; the
/// host applies the spread, flies and traces the projectile (COMBAT-14,
/// decision 183, stack decision 8).
/// {@endtemplate}
final class FireAimed extends UnitOrder {
  /// {@macro fire_aimed}
  const new({required super.unitId, required this.aim, required this.fireTime});

  /// The aim direction.
  final Direction aim;

  /// The battle time the player fired.
  final Duration fireTime;

  @override
  List<Object?> get props => [unitId, aim, fireTime];
}

/// {@template reload}
/// [unitId] reloads its weapon: a full magazine (COMBAT-33).
/// {@endtemplate}
final class Reload extends UnitOrder {
  /// {@macro reload}
  const new({required super.unitId});
}

/// {@template unload_weapon}
/// [unitId] unloads its weapon, for example artillery before it moves
/// (COMBAT-05).
/// {@endtemplate}
final class UnloadWeapon extends UnitOrder {
  /// {@macro unload_weapon}
  const new({required super.unitId});
}

/// {@template swap_weapon}
/// [unitId] takes [weapon] from its section's storage and puts its own
/// there (COMBAT-27, COMBAT-28).
/// {@endtemplate}
final class SwapWeapon extends UnitOrder {
  /// {@macro swap_weapon}
  const new({required super.unitId, required this.weapon});

  /// The weapon type taken, a key of `combat.yaml` `weapons`.
  final String weapon;

  @override
  List<Object?> get props => [unitId, weapon];
}

/// {@template pick_up_weapon}
/// [unitId] picks up the dropped weapon [droppedId] (COMBAT-30).
/// {@endtemplate}
final class PickUpWeapon extends UnitOrder {
  /// {@macro pick_up_weapon}
  const new({required super.unitId, required this.droppedId});

  /// The dropped weapon.
  final String droppedId;

  @override
  List<Object?> get props => [unitId, droppedId];
}

/// {@template land}
/// The flying unit [unitId] lands.
/// {@endtemplate}
final class Land extends UnitOrder {
  /// {@macro land}
  const new({required super.unitId});
}

/// {@template take_off}
/// The flying unit [unitId] takes off.
/// {@endtemplate}
final class TakeOff extends UnitOrder {
  /// {@macro take_off}
  const new({required super.unitId});
}

/// {@template embark}
/// [unitId] gets into the transport [transportId] (UNIT-37).
/// {@endtemplate}
final class Embark extends UnitOrder {
  /// {@macro embark}
  const new({required super.unitId, required this.transportId});

  /// The transport.
  final String transportId;

  @override
  List<Object?> get props => [unitId, transportId];
}

/// {@template disembark}
/// [unitId] gets off its transport.
/// {@endtemplate}
final class Disembark extends UnitOrder {
  /// {@macro disembark}
  const new({required super.unitId});
}

/// {@template build}
/// [unitId] builds [structure] on [cells] (COMBAT-07, UNIT-33).
/// {@endtemplate}
final class Build extends UnitOrder {
  /// {@macro build}
  const new({
    required super.unitId,
    required this.structure,
    required this.cells,
  });

  /// The structure, a key of `terrain.yaml`.
  final String structure;

  /// The cells it occupies; a bridge or a ladder from one end to the
  /// other.
  final List<Cell> cells;

  @override
  List<Object?> get props => [unitId, structure, cells];
}

/// {@template repair}
/// [unitId] repairs [targetId], a friendly unit or construction, never the
/// HQ (COMBAT-07, decision 139).
/// {@endtemplate}
final class Repair extends UnitOrder {
  /// {@macro repair}
  const new({required super.unitId, required this.targetId});

  /// What is repaired.
  final String targetId;

  @override
  List<Object?> get props => [unitId, targetId];
}

/// {@template resume}
/// [unitId] resumes the interrupted build or repair [workId], paying only
/// its remaining part (COMBAT-09).
/// {@endtemplate}
final class Resume extends UnitOrder {
  /// {@macro resume}
  const new({required super.unitId, required this.workId});

  /// The construction site, or the target of the repair.
  final String workId;

  @override
  List<Object?> get props => [unitId, workId];
}

/// {@template heal}
/// [unitId] heals [targetId] at once (COMBAT-07, UNIT-35).
/// {@endtemplate}
final class Heal extends UnitOrder {
  /// {@macro heal}
  const new({required super.unitId, required this.targetId});

  /// The healed unit.
  final String targetId;

  @override
  List<Object?> get props => [unitId, targetId];
}

/// {@template observe}
/// The scout [unitId] observes (UNIT-34).
/// {@endtemplate}
final class Observe extends UnitOrder {
  /// {@macro observe}
  const new({required super.unitId});
}

/// {@template capture}
/// [unitId] adds its contribution to the capture pot of [relicId]
/// (RELIC-05).
/// {@endtemplate}
final class Capture extends UnitOrder {
  /// {@macro capture}
  const new({required super.unitId, required this.relicId});

  /// The relic.
  final String relicId;

  @override
  List<Object?> get props => [unitId, relicId];
}

/// {@template push}
/// [unitId] adds its contribution to the push pot of [relicId]
/// (RELIC-24, COMBAT-08). The first push while the pot is empty sets the
/// relic's [path]; later pushes follow it until the pot is empty again
/// (decision 219).
/// {@endtemplate}
final class Push extends UnitOrder {
  /// {@macro push}
  const new({required super.unitId, required this.relicId, this.path});

  /// The relic.
  final String relicId;

  /// The path the pusher's player chooses, from the relic's cell; the host
  /// uses it only when the pot is empty.
  final List<Cell>? path;

  @override
  List<Object?> get props => [unitId, relicId, path];
}

/// {@template store}
/// Store [unitId] at once, within the storage radius of its storage place
/// (HQ-31).
/// {@endtemplate}
final class Store extends UnitOrder {
  /// {@macro store}
  const new({required super.unitId});
}

/// {@template recall}
/// Recall [unitId] from anywhere: it is stored after the recall time
/// (HQ-32).
/// {@endtemplate}
final class Recall extends UnitOrder {
  /// {@macro recall}
  const new({required super.unitId});
}

/// {@template deploy}
/// Deploy the stored unit [unitId] next to its storage place (HQ-33).
/// {@endtemplate}
final class Deploy extends UnitOrder {
  /// {@macro deploy}
  const new({required super.unitId});
}

/// {@template buy_node}
/// [unitId] buys step [step] of [stat] on its skill tree with its own XP
/// (UNIT-18, UNIT-23). Naming the step makes a repeated order harmless.
/// {@endtemplate}
final class BuyNode extends UnitOrder {
  /// {@macro buy_node}
  const new({required super.unitId, required this.stat, required this.step});

  /// The stat, a key of `units.yaml` `trees`.
  final String stat;

  /// The step bought, from 1.
  final int step;

  @override
  List<Object?> get props => [unitId, stat, step];
}

/// {@template move_hq}
/// The HQ manager moves the team's HQ to [to], along the client's [path]
/// when it sends one (HQ-09, HQ-10).
/// {@endtemplate}
final class MoveHq extends Order {
  /// {@macro move_hq}
  const new({required this.to, this.path});

  /// Where to go.
  final Position to;

  /// The client's path.
  final List<Cell>? path;

  @override
  List<Object?> get props => [to, path];
}

/// {@template buy_unit}
/// The commander buys a unit of [unitType], a radio included (ECO-04,
/// ECO-05).
/// {@endtemplate}
final class BuyUnit extends Order {
  /// {@macro buy_unit}
  const new({required this.unitType});

  /// The unit type, a key of `units.yaml`.
  final String unitType;

  @override
  List<Object?> get props => [unitType];
}

/// {@template buy_weapon}
/// The commander buys [weapon] for the section's storage (COMBAT-27).
/// {@endtemplate}
final class BuyWeapon extends Order {
  /// {@macro buy_weapon}
  const new({required this.weapon});

  /// The weapon type.
  final String weapon;

  @override
  List<Object?> get props => [weapon];
}

/// The guild chief buys the guild camp (ECO-06, HQ-42).
final class BuyGuildCamp extends Order {
  /// The guild chief buys the guild camp.
  const new();
}

/// {@template transfer_money}
/// The sender's section sends [amount] w€ to [toSectionId], with the fee
/// (ECO-08 to ECO-11).
/// {@endtemplate}
final class TransferMoney extends Order {
  /// {@macro transfer_money}
  const new({required this.toSectionId, required this.amount});

  /// The receiving section.
  final String toSectionId;

  /// The amount sent, in whole w€.
  final int amount;

  @override
  List<Object?> get props => [toSectionId, amount];
}

/// {@template offer_exchange}
/// The captor offers [ownerSectionId] to release its prisoners [released]
/// against [wanted], the captor's units it holds (COMBAT-44).
/// {@endtemplate}
final class OfferExchange extends Order {
  /// {@macro offer_exchange}
  const new({
    required this.ownerSectionId,
    required this.released,
    required this.wanted,
  });

  /// The section the offer is for.
  final String ownerSectionId;

  /// The prisoners released.
  final List<String> released;

  /// The captor's units asked back.
  final List<String> wanted;

  @override
  List<Object?> get props => [ownerSectionId, released, wanted];
}

/// {@template offer_ransom}
/// The captor offers [ownerSectionId] to release its prisoners [released]
/// for [price] w€ (COMBAT-44).
/// {@endtemplate}
final class OfferRansom extends Order {
  /// {@macro offer_ransom}
  const new({
    required this.ownerSectionId,
    required this.released,
    required this.price,
  });

  /// The section the offer is for.
  final String ownerSectionId;

  /// The prisoners released.
  final List<String> released;

  /// The ransom, in whole w€.
  final int price;

  @override
  List<Object?> get props => [ownerSectionId, released, price];
}

/// {@template accept_offer}
/// The prisoners' owner accepts the offer [offerId]: the sequence number
/// of the command that posted it.
/// {@endtemplate}
final class AcceptOffer extends Order {
  /// {@macro accept_offer}
  const new({required this.offerId});

  /// The offer.
  final int offerId;

  @override
  List<Object?> get props => [offerId];
}

/// {@template refuse_offer}
/// The prisoners' owner refuses the offer [offerId].
/// {@endtemplate}
final class RefuseOffer extends Order {
  /// {@macro refuse_offer}
  const new({required this.offerId});

  /// The offer.
  final int offerId;

  @override
  List<Object?> get props => [offerId];
}

/// {@template delegate_hq}
/// The HQ manager hands the role to the player [accountId] (HQ-05,
/// HQ-07).
/// {@endtemplate}
final class DelegateHq extends Order {
  /// {@macro delegate_hq}
  const new({required this.accountId});

  /// The new manager.
  final String accountId;

  @override
  List<Object?> get props => [accountId];
}

/// {@template enter_battle}
/// The player of the sender's section logs in to the battle. The server
/// sends it, so the log holds who may take the HQ manager role (HQ-07,
/// decision 220).
/// {@endtemplate}
final class EnterBattle extends Order {
  /// {@macro enter_battle}
  const new();
}
