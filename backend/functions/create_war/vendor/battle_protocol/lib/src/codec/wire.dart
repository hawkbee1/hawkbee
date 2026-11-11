import 'package:battle_protocol/src/codec/fields.dart';
import 'package:battle_protocol/src/command.dart';
import 'package:battle_protocol/src/events.dart';
import 'package:battle_protocol/src/log_entry.dart';
import 'package:battle_protocol/src/messages.dart';
import 'package:battle_protocol/src/orders.dart';
import 'package:battle_protocol/src/values.dart';

part 'wire_messages.dart';

// The fields of every message, in order, written and read once for both
// encodings. The order of the fields and of the tags below is version 1 of
// the format: a new order or event is added at the end of its tags; any
// other change breaks the committed samples and needs a new version.

/// The `type` of an order: its index is its binary tag, its snake-case
/// name its JSON type.
enum _OrderTag {
  move,
  fire,
  fireAtPosition,
  fireAimed,
  reload,
  unloadWeapon,
  swapWeapon,
  pickUpWeapon,
  land,
  takeOff,
  embark,
  disembark,
  build,
  repair,
  resume,
  heal,
  observe,
  capture,
  push,
  store,
  recall,
  deploy,
  buyNode,
  moveHq,
  buyUnit,
  buyWeapon,
  buyGuildCamp,
  transferMoney,
  offerExchange,
  offerRansom,
  acceptOffer,
  refuseOffer,
  delegateHq,
  enterBattle,
  admitSection,
}

/// The `type` of an event.
enum _EventTag {
  orderRefused,
  orderDelayed,
  moveStarted,
  moveStopped,
  attacked,
  crushed,
  weaponDropped,
  weaponPickedUp,
  weaponSwapped,
  timeOnlyStarted,
  embarked,
  disembarked,
  buildStarted,
  repairStarted,
  workResumed,
  workInterrupted,
  structureBuilt,
  repaired,
  unitHealed,
  observationStarted,
  addedToCapture,
  addedToPush,
  captureLost,
  relicCaptured,
  relicLost,
  victoryHoldStarted,
  victoryHoldReset,
  eliminated,
  unitStored,
  recallBegan,
  unitDeployed,
  sectionLocked,
  unitPurchased,
  weaponPurchased,
  moneyTransferred,
  nodePurchased,
  offerPosted,
  offerAccepted,
  offerRefused,
  managerChanged,
  battleStarted,
  battleEnded,
  objectDamaged,
  objectDestroyed,
  craterDug,
  sectionJoined,
}

/// Writes a log entry.
void writeEntry(FieldWriter w, LogEntry entry) {
  w
    ..time('at_us', entry.at)
    ..maybe('command', entry.command, (w, k, v) => w.item(k, v, writeCommand))
    ..items('events', entry.events, writeEvent);
}

/// Reads a log entry.
LogEntry readEntry(FieldReader r) => LogEntry(
  at: r.time('at_us'),
  command: r.maybe('command', (r, k) => r.item(k, readCommand)),
  events: r.items('events', readEvent),
);

/// Writes a command.
void writeCommand(FieldWriter w, Command command) {
  w
    ..maybe('seq', command.seq, (w, k, v) => w.integer(k, v))
    ..maybe('origin', command.origin, (w, k, v) => w.choice(k, v))
    ..item('sender', command.sender, _writeSender)
    ..time('sent_at_us', command.sentAt)
    ..item('order', command.order, writeOrder);
}

/// Reads a command.
Command readCommand(FieldReader r) => Command(
  seq: r.maybe('seq', (r, k) => r.integer(k)),
  origin: r.maybe('origin', (r, k) => r.choice(k, Origin.values)),
  sender: r.item('sender', _readSender),
  sentAt: r.time('sent_at_us'),
  order: r.item('order', readOrder),
);

void _writeSender(FieldWriter w, Sender sender) => w
  ..text('account', sender.accountId)
  ..text('section', sender.sectionId);

Sender _readSender(FieldReader r) =>
    Sender(accountId: r.text('account'), sectionId: r.text('section'));

void _writePath(FieldWriter w, String key, List<Cell> path) =>
    w.cells(key, path);

List<Cell> _readPath(FieldReader r, String key) => r.cells(key);

void _writeOptionalText(FieldWriter w, String key, String value) =>
    w.text(key, value);

String _readOptionalText(FieldReader r, String key) => r.text(key);

/// Writes an order: its type, then its fields.
void writeOrder(FieldWriter w, Order order) {
  switch (order) {
    case Move(:final unitId, :final to, :final path):
      w
        ..choice('type', _OrderTag.move)
        ..text('unit', unitId)
        ..position('to', to)
        ..maybe('path', path, _writePath);
    case Fire(:final unitId, :final targetId):
      w
        ..choice('type', _OrderTag.fire)
        ..text('unit', unitId)
        ..text('target', targetId);
    case FireAtPosition(:final unitId, :final target):
      w
        ..choice('type', _OrderTag.fireAtPosition)
        ..text('unit', unitId)
        ..position('target', target);
    case FireAimed(:final unitId, :final aim, :final fireTime):
      w
        ..choice('type', _OrderTag.fireAimed)
        ..text('unit', unitId)
        ..direction('aim', aim)
        ..time('fire_time_us', fireTime);
    case Reload(:final unitId):
      _unit(w, _OrderTag.reload, unitId);
    case UnloadWeapon(:final unitId):
      _unit(w, _OrderTag.unloadWeapon, unitId);
    case SwapWeapon(:final unitId, :final weapon):
      w
        ..choice('type', _OrderTag.swapWeapon)
        ..text('unit', unitId)
        ..text('weapon', weapon);
    case PickUpWeapon(:final unitId, :final droppedId):
      w
        ..choice('type', _OrderTag.pickUpWeapon)
        ..text('unit', unitId)
        ..text('dropped', droppedId);
    case Land(:final unitId):
      _unit(w, _OrderTag.land, unitId);
    case TakeOff(:final unitId):
      _unit(w, _OrderTag.takeOff, unitId);
    case Embark(:final unitId, :final transportId):
      w
        ..choice('type', _OrderTag.embark)
        ..text('unit', unitId)
        ..text('transport', transportId);
    case Disembark(:final unitId):
      _unit(w, _OrderTag.disembark, unitId);
    case Build(:final unitId, :final structure, :final cells):
      w
        ..choice('type', _OrderTag.build)
        ..text('unit', unitId)
        ..text('structure', structure)
        ..cells('cells', cells);
    case Repair(:final unitId, :final targetId):
      w
        ..choice('type', _OrderTag.repair)
        ..text('unit', unitId)
        ..text('target', targetId);
    case Resume(:final unitId, :final workId):
      w
        ..choice('type', _OrderTag.resume)
        ..text('unit', unitId)
        ..text('work', workId);
    case Heal(:final unitId, :final targetId):
      w
        ..choice('type', _OrderTag.heal)
        ..text('unit', unitId)
        ..text('target', targetId);
    case Observe(:final unitId):
      _unit(w, _OrderTag.observe, unitId);
    case Capture(:final unitId, :final relicId):
      w
        ..choice('type', _OrderTag.capture)
        ..text('unit', unitId)
        ..text('relic', relicId);
    case Push(:final unitId, :final relicId, :final path):
      w
        ..choice('type', _OrderTag.push)
        ..text('unit', unitId)
        ..text('relic', relicId)
        ..maybe('path', path, _writePath);
    case Store(:final unitId):
      _unit(w, _OrderTag.store, unitId);
    case Recall(:final unitId):
      _unit(w, _OrderTag.recall, unitId);
    case Deploy(:final unitId):
      _unit(w, _OrderTag.deploy, unitId);
    case BuyNode(:final unitId, :final stat, :final step):
      w
        ..choice('type', _OrderTag.buyNode)
        ..text('unit', unitId)
        ..text('stat', stat)
        ..integer('step', step);
    case MoveHq(:final to, :final path):
      w
        ..choice('type', _OrderTag.moveHq)
        ..position('to', to)
        ..maybe('path', path, _writePath);
    case BuyUnit(:final unitType):
      w
        ..choice('type', _OrderTag.buyUnit)
        ..text('unit_type', unitType);
    case BuyWeapon(:final weapon):
      w
        ..choice('type', _OrderTag.buyWeapon)
        ..text('weapon', weapon);
    case BuyGuildCamp():
      w.choice('type', _OrderTag.buyGuildCamp);
    case TransferMoney(:final toSectionId, :final amount):
      w
        ..choice('type', _OrderTag.transferMoney)
        ..text('to_section', toSectionId)
        ..integer('amount', amount);
    case OfferExchange(:final ownerSectionId, :final released, :final wanted):
      w
        ..choice('type', _OrderTag.offerExchange)
        ..text('owner_section', ownerSectionId)
        ..texts('released', released)
        ..texts('wanted', wanted);
    case OfferRansom(:final ownerSectionId, :final released, :final price):
      w
        ..choice('type', _OrderTag.offerRansom)
        ..text('owner_section', ownerSectionId)
        ..texts('released', released)
        ..integer('price', price);
    case AcceptOffer(:final offerId):
      w
        ..choice('type', _OrderTag.acceptOffer)
        ..integer('offer', offerId);
    case RefuseOffer(:final offerId):
      w
        ..choice('type', _OrderTag.refuseOffer)
        ..integer('offer', offerId);
    case DelegateHq(:final accountId):
      w
        ..choice('type', _OrderTag.delegateHq)
        ..text('account', accountId);
    case EnterBattle():
      w.choice('type', _OrderTag.enterBattle);
    case AdmitSection(:final team, :final money, :final units):
      w
        ..choice('type', _OrderTag.admitSection)
        ..text('team', team)
        ..integer('money', money)
        ..items('units', units, _writeAdmittedUnit);
  }
}

void _unit(FieldWriter w, _OrderTag tag, String unitId) => w
  ..choice('type', tag)
  ..text('unit', unitId);

/// Reads an order.
Order readOrder(FieldReader r) {
  String unit() => r.text('unit');
  return switch (r.choice('type', _OrderTag.values)) {
    _OrderTag.move => Move(
      unitId: unit(),
      to: r.position('to'),
      path: r.maybe('path', _readPath),
    ),
    _OrderTag.fire => Fire(unitId: unit(), targetId: r.text('target')),
    _OrderTag.fireAtPosition => FireAtPosition(
      unitId: unit(),
      target: r.position('target'),
    ),
    _OrderTag.fireAimed => FireAimed(
      unitId: unit(),
      aim: r.direction('aim'),
      fireTime: r.time('fire_time_us'),
    ),
    _OrderTag.reload => Reload(unitId: unit()),
    _OrderTag.unloadWeapon => UnloadWeapon(unitId: unit()),
    _OrderTag.swapWeapon => SwapWeapon(
      unitId: unit(),
      weapon: r.text('weapon'),
    ),
    _OrderTag.pickUpWeapon => PickUpWeapon(
      unitId: unit(),
      droppedId: r.text('dropped'),
    ),
    _OrderTag.land => Land(unitId: unit()),
    _OrderTag.takeOff => TakeOff(unitId: unit()),
    _OrderTag.embark => Embark(
      unitId: unit(),
      transportId: r.text('transport'),
    ),
    _OrderTag.disembark => Disembark(unitId: unit()),
    _OrderTag.build => Build(
      unitId: unit(),
      structure: r.text('structure'),
      cells: r.cells('cells'),
    ),
    _OrderTag.repair => Repair(unitId: unit(), targetId: r.text('target')),
    _OrderTag.resume => Resume(unitId: unit(), workId: r.text('work')),
    _OrderTag.heal => Heal(unitId: unit(), targetId: r.text('target')),
    _OrderTag.observe => Observe(unitId: unit()),
    _OrderTag.capture => Capture(unitId: unit(), relicId: r.text('relic')),
    _OrderTag.push => Push(
      unitId: unit(),
      relicId: r.text('relic'),
      path: r.maybe('path', _readPath),
    ),
    _OrderTag.store => Store(unitId: unit()),
    _OrderTag.recall => Recall(unitId: unit()),
    _OrderTag.deploy => Deploy(unitId: unit()),
    _OrderTag.buyNode => BuyNode(
      unitId: unit(),
      stat: r.text('stat'),
      step: r.integer('step'),
    ),
    _OrderTag.moveHq => MoveHq(
      to: r.position('to'),
      path: r.maybe('path', _readPath),
    ),
    _OrderTag.buyUnit => BuyUnit(unitType: r.text('unit_type')),
    _OrderTag.buyWeapon => BuyWeapon(weapon: r.text('weapon')),
    _OrderTag.buyGuildCamp => const BuyGuildCamp(),
    _OrderTag.transferMoney => TransferMoney(
      toSectionId: r.text('to_section'),
      amount: r.integer('amount'),
    ),
    _OrderTag.offerExchange => OfferExchange(
      ownerSectionId: r.text('owner_section'),
      released: r.texts('released'),
      wanted: r.texts('wanted'),
    ),
    _OrderTag.offerRansom => OfferRansom(
      ownerSectionId: r.text('owner_section'),
      released: r.texts('released'),
      price: r.integer('price'),
    ),
    _OrderTag.acceptOffer => AcceptOffer(offerId: r.integer('offer')),
    _OrderTag.refuseOffer => RefuseOffer(offerId: r.integer('offer')),
    _OrderTag.delegateHq => DelegateHq(accountId: r.text('account')),
    _OrderTag.enterBattle => const EnterBattle(),
    _OrderTag.admitSection => AdmitSection(
      team: r.text('team'),
      money: r.integer('money'),
      units: r.items('units', _readAdmittedUnit),
    ),
  };
}

void _writeAdmittedUnit(FieldWriter w, AdmittedUnit unit) => w
  ..text('unit', unit.unitId)
  ..text('type', unit.unitType);

AdmittedUnit _readAdmittedUnit(FieldReader r) =>
    AdmittedUnit(unitId: r.text('unit'), unitType: r.text('type'));

void _writeImpact(FieldWriter w, Impact impact) => w
  ..text('target', impact.targetId)
  ..text('target_type', impact.targetType)
  ..number('damage', impact.damage)
  ..flag('friendly', value: impact.friendly)
  ..choice('result', impact.result);

Impact _readImpact(FieldReader r) => Impact(
  targetId: r.text('target'),
  targetType: r.text('target_type'),
  damage: r.number('damage'),
  friendly: r.flag('friendly'),
  result: r.choice('result', ImpactResult.values),
);

/// Writes an event: its type, then its fields.
void writeEvent(FieldWriter w, BattleEvent event) {
  switch (event) {
    case OrderRefused(:final seq, :final reason):
      w
        ..choice('type', _EventTag.orderRefused)
        ..integer('seq', seq)
        ..text('reason', reason);
    case OrderDelayed(:final seq, :final until):
      w
        ..choice('type', _EventTag.orderDelayed)
        ..integer('seq', seq)
        ..time('until_us', until);
    case MoveStarted(:final moverId, :final arrivesAt):
      w
        ..choice('type', _EventTag.moveStarted)
        ..text('mover', moverId)
        ..time('arrives_at_us', arrivesAt);
    case MoveStopped(:final moverId, :final at):
      w
        ..choice('type', _EventTag.moveStopped)
        ..text('mover', moverId)
        ..position('at', at);
    case Attacked(
      :final attackerId,
      :final sectionId,
      :final weapon,
      :final hit,
      :final impacts,
    ):
      w
        ..choice('type', _EventTag.attacked)
        ..text('attacker', attackerId)
        ..text('section', sectionId)
        ..text('weapon', weapon)
        ..flag('hit', value: hit)
        ..items('impacts', impacts, _writeImpact);
    case Crushed(:final byId, :final unitId, :final unitType):
      w
        ..choice('type', _EventTag.crushed)
        ..text('by', byId)
        ..text('unit', unitId)
        ..text('unit_type', unitType);
    case WeaponDropped(
      :final droppedId,
      :final weapon,
      :final at,
      :final goneAt,
    ):
      w
        ..choice('type', _EventTag.weaponDropped)
        ..text('dropped', droppedId)
        ..text('weapon', weapon)
        ..position('at', at)
        ..time('gone_at_us', goneAt);
    case WeaponPickedUp(:final unitId, :final droppedId):
      w
        ..choice('type', _EventTag.weaponPickedUp)
        ..text('unit', unitId)
        ..text('dropped', droppedId);
    case WeaponSwapped(:final unitId, :final weapon, :final readyAt):
      w
        ..choice('type', _EventTag.weaponSwapped)
        ..text('unit', unitId)
        ..text('weapon', weapon)
        ..time('ready_at_us', readyAt);
    case TimeOnlyStarted(:final unitId, :final action, :final endsAt):
      w
        ..choice('type', _EventTag.timeOnlyStarted)
        ..text('unit', unitId)
        ..choice('action', action)
        ..time('ends_at_us', endsAt);
    case Embarked(:final unitId, :final transportId):
      w
        ..choice('type', _EventTag.embarked)
        ..text('unit', unitId)
        ..text('transport', transportId);
    case Disembarked(:final unitId, :final at):
      w
        ..choice('type', _EventTag.disembarked)
        ..text('unit', unitId)
        ..position('at', at);
    case BuildStarted(
      :final unitId,
      :final siteId,
      :final structure,
      :final cells,
      :final endsAt,
    ):
      w
        ..choice('type', _EventTag.buildStarted)
        ..text('unit', unitId)
        ..text('site', siteId)
        ..text('structure', structure)
        ..cells('cells', cells)
        ..time('ends_at_us', endsAt);
    case RepairStarted(:final unitId, :final targetId, :final endsAt):
      w
        ..choice('type', _EventTag.repairStarted)
        ..text('unit', unitId)
        ..text('target', targetId)
        ..time('ends_at_us', endsAt);
    case WorkResumed(:final unitId, :final workId, :final endsAt):
      w
        ..choice('type', _EventTag.workResumed)
        ..text('unit', unitId)
        ..text('work', workId)
        ..time('ends_at_us', endsAt);
    case WorkInterrupted(:final unitId, :final workId):
      w
        ..choice('type', _EventTag.workInterrupted)
        ..text('unit', unitId)
        ..text('work', workId);
    case StructureBuilt(:final siteId, :final structure, :final cells):
      w
        ..choice('type', _EventTag.structureBuilt)
        ..text('site', siteId)
        ..text('structure', structure)
        ..cells('cells', cells);
    case Repaired(:final targetId, :final hp):
      w
        ..choice('type', _EventTag.repaired)
        ..text('target', targetId)
        ..number('hp', hp);
    case UnitHealed(:final unitId, :final targetId, :final hp):
      w
        ..choice('type', _EventTag.unitHealed)
        ..text('unit', unitId)
        ..text('target', targetId)
        ..number('hp', hp);
    case ObservationStarted(:final unitId, :final endsAt):
      w
        ..choice('type', _EventTag.observationStarted)
        ..text('unit', unitId)
        ..time('ends_at_us', endsAt);
    case AddedToCapture(
      :final unitId,
      :final relicId,
      :final potAp,
      :final capturedAt,
    ):
      w
        ..choice('type', _EventTag.addedToCapture)
        ..text('unit', unitId)
        ..text('relic', relicId)
        ..number('pot_ap', potAp)
        ..maybe('captured_at_us', capturedAt, (w, k, v) => w.time(k, v));
    case AddedToPush(:final unitId, :final relicId, :final potAp):
      w
        ..choice('type', _EventTag.addedToPush)
        ..text('unit', unitId)
        ..text('relic', relicId)
        ..number('pot_ap', potAp);
    case CaptureLost(:final relicId, :final team):
      w
        ..choice('type', _EventTag.captureLost)
        ..text('relic', relicId)
        ..text('team', team);
    case RelicCaptured(:final relicId, :final team, :final previousOwner):
      w
        ..choice('type', _EventTag.relicCaptured)
        ..text('relic', relicId)
        ..text('team', team)
        ..maybe('previous_owner', previousOwner, _writeOptionalText);
    case RelicLost(:final relicId, :final previousOwner):
      w
        ..choice('type', _EventTag.relicLost)
        ..text('relic', relicId)
        ..maybe('previous_owner', previousOwner, _writeOptionalText);
    case VictoryHoldStarted(:final team, :final winsAt):
      w
        ..choice('type', _EventTag.victoryHoldStarted)
        ..text('team', team)
        ..time('wins_at_us', winsAt);
    case VictoryHoldReset(:final team):
      w
        ..choice('type', _EventTag.victoryHoldReset)
        ..text('team', team);
    case Eliminated(:final team, :final loss):
      w
        ..choice('type', _EventTag.eliminated)
        ..text('team', team)
        ..choice('loss', loss);
    case UnitStored(:final unitId):
      w
        ..choice('type', _EventTag.unitStored)
        ..text('unit', unitId);
    case RecallBegan(:final unitId, :final storedAt):
      w
        ..choice('type', _EventTag.recallBegan)
        ..text('unit', unitId)
        ..time('stored_at_us', storedAt);
    case UnitDeployed(:final unitId, :final at):
      w
        ..choice('type', _EventTag.unitDeployed)
        ..text('unit', unitId)
        ..position('at', at);
    case SectionLocked(:final sectionId, :final until):
      w
        ..choice('type', _EventTag.sectionLocked)
        ..text('section', sectionId)
        ..time('until_us', until);
    case UnitPurchased(
      :final sectionId,
      :final unitId,
      :final unitType,
      :final price,
    ):
      w
        ..choice('type', _EventTag.unitPurchased)
        ..text('section', sectionId)
        ..text('unit', unitId)
        ..text('unit_type', unitType)
        ..integer('price', price);
    case WeaponPurchased(:final sectionId, :final weapon, :final price):
      w
        ..choice('type', _EventTag.weaponPurchased)
        ..text('section', sectionId)
        ..text('weapon', weapon)
        ..integer('price', price);
    case MoneyTransferred(
      :final fromSectionId,
      :final toSectionId,
      :final received,
      :final fee,
    ):
      w
        ..choice('type', _EventTag.moneyTransferred)
        ..text('from_section', fromSectionId)
        ..text('to_section', toSectionId)
        ..integer('received', received)
        ..integer('fee', fee);
    case NodePurchased(:final unitId, :final stat, :final step):
      w
        ..choice('type', _EventTag.nodePurchased)
        ..text('unit', unitId)
        ..text('stat', stat)
        ..integer('step', step);
    case OfferPosted(
      :final offerId,
      :final captorSectionId,
      :final ownerSectionId,
      :final released,
      :final wanted,
      :final price,
    ):
      w
        ..choice('type', _EventTag.offerPosted)
        ..integer('offer', offerId)
        ..text('captor_section', captorSectionId)
        ..text('owner_section', ownerSectionId)
        ..texts('released', released)
        ..texts('wanted', wanted)
        ..integer('price', price);
    case OfferAccepted(:final offerId):
      w
        ..choice('type', _EventTag.offerAccepted)
        ..integer('offer', offerId);
    case OfferRefused(:final offerId):
      w
        ..choice('type', _EventTag.offerRefused)
        ..integer('offer', offerId);
    case ManagerChanged(:final team, :final accountId):
      w
        ..choice('type', _EventTag.managerChanged)
        ..text('team', team)
        ..text('account', accountId);
    case BattleStarted(:final battleId, :final mapId, :final seed):
      w
        ..choice('type', _EventTag.battleStarted)
        ..text('battle', battleId)
        ..text('map', mapId)
        ..integer('seed', seed);
    case BattleEnded(:final winner, :final kind, :final eliminated):
      w
        ..choice('type', _EventTag.battleEnded)
        ..text('winner', winner)
        ..choice('kind', kind)
        ..texts('eliminated', eliminated);
    case ObjectDamaged(:final object, :final cells, :final hp):
      w
        ..choice('type', _EventTag.objectDamaged)
        ..text('object', object)
        ..cells('cells', cells)
        ..number('hp', hp);
    case ObjectDestroyed(:final object, :final cells):
      w
        ..choice('type', _EventTag.objectDestroyed)
        ..text('object', object)
        ..cells('cells', cells);
    case CraterDug(:final at, :final radiusM, :final depthM):
      w
        ..choice('type', _EventTag.craterDug)
        ..position('at', at)
        ..number('radius_m', radiusM)
        ..number('depth_m', depthM);
    case SectionJoined(
      :final sectionId,
      :final accountId,
      :final team,
      :final units,
    ):
      w
        ..choice('type', _EventTag.sectionJoined)
        ..text('section', sectionId)
        ..text('account', accountId)
        ..text('team', team)
        ..items('units', units, _writeJoinedUnit);
  }
}

void _writeJoinedUnit(FieldWriter w, JoinedUnit unit) => w
  ..text('unit', unit.unitId)
  ..text('unit_type', unit.unitType);

JoinedUnit _readJoinedUnit(FieldReader r) =>
    JoinedUnit(unitId: r.text('unit'), unitType: r.text('unit_type'));

/// Reads an event.
BattleEvent readEvent(FieldReader r) {
  String unit() => r.text('unit');
  return switch (r.choice('type', _EventTag.values)) {
    _EventTag.orderRefused => OrderRefused(
      seq: r.integer('seq'),
      reason: r.text('reason'),
    ),
    _EventTag.orderDelayed => OrderDelayed(
      seq: r.integer('seq'),
      until: r.time('until_us'),
    ),
    _EventTag.moveStarted => MoveStarted(
      moverId: r.text('mover'),
      arrivesAt: r.time('arrives_at_us'),
    ),
    _EventTag.moveStopped => MoveStopped(
      moverId: r.text('mover'),
      at: r.position('at'),
    ),
    _EventTag.attacked => Attacked(
      attackerId: r.text('attacker'),
      sectionId: r.text('section'),
      weapon: r.text('weapon'),
      hit: r.flag('hit'),
      impacts: r.items('impacts', _readImpact),
    ),
    _EventTag.crushed => Crushed(
      byId: r.text('by'),
      unitId: unit(),
      unitType: r.text('unit_type'),
    ),
    _EventTag.weaponDropped => WeaponDropped(
      droppedId: r.text('dropped'),
      weapon: r.text('weapon'),
      at: r.position('at'),
      goneAt: r.time('gone_at_us'),
    ),
    _EventTag.weaponPickedUp => WeaponPickedUp(
      unitId: unit(),
      droppedId: r.text('dropped'),
    ),
    _EventTag.weaponSwapped => WeaponSwapped(
      unitId: unit(),
      weapon: r.text('weapon'),
      readyAt: r.time('ready_at_us'),
    ),
    _EventTag.timeOnlyStarted => TimeOnlyStarted(
      unitId: unit(),
      action: r.choice('action', TimeOnly.values),
      endsAt: r.time('ends_at_us'),
    ),
    _EventTag.embarked => Embarked(
      unitId: unit(),
      transportId: r.text('transport'),
    ),
    _EventTag.disembarked => Disembarked(unitId: unit(), at: r.position('at')),
    _EventTag.buildStarted => BuildStarted(
      unitId: unit(),
      siteId: r.text('site'),
      structure: r.text('structure'),
      cells: r.cells('cells'),
      endsAt: r.time('ends_at_us'),
    ),
    _EventTag.repairStarted => RepairStarted(
      unitId: unit(),
      targetId: r.text('target'),
      endsAt: r.time('ends_at_us'),
    ),
    _EventTag.workResumed => WorkResumed(
      unitId: unit(),
      workId: r.text('work'),
      endsAt: r.time('ends_at_us'),
    ),
    _EventTag.workInterrupted => WorkInterrupted(
      unitId: unit(),
      workId: r.text('work'),
    ),
    _EventTag.structureBuilt => StructureBuilt(
      siteId: r.text('site'),
      structure: r.text('structure'),
      cells: r.cells('cells'),
    ),
    _EventTag.repaired => Repaired(
      targetId: r.text('target'),
      hp: r.number('hp'),
    ),
    _EventTag.unitHealed => UnitHealed(
      unitId: unit(),
      targetId: r.text('target'),
      hp: r.number('hp'),
    ),
    _EventTag.observationStarted => ObservationStarted(
      unitId: unit(),
      endsAt: r.time('ends_at_us'),
    ),
    _EventTag.addedToCapture => AddedToCapture(
      unitId: unit(),
      relicId: r.text('relic'),
      potAp: r.number('pot_ap'),
      capturedAt: r.maybe('captured_at_us', (r, k) => r.time(k)),
    ),
    _EventTag.addedToPush => AddedToPush(
      unitId: unit(),
      relicId: r.text('relic'),
      potAp: r.number('pot_ap'),
    ),
    _EventTag.captureLost => CaptureLost(
      relicId: r.text('relic'),
      team: r.text('team'),
    ),
    _EventTag.relicCaptured => RelicCaptured(
      relicId: r.text('relic'),
      team: r.text('team'),
      previousOwner: r.maybe('previous_owner', _readOptionalText),
    ),
    _EventTag.relicLost => RelicLost(
      relicId: r.text('relic'),
      previousOwner: r.maybe('previous_owner', _readOptionalText),
    ),
    _EventTag.victoryHoldStarted => VictoryHoldStarted(
      team: r.text('team'),
      winsAt: r.time('wins_at_us'),
    ),
    _EventTag.victoryHoldReset => VictoryHoldReset(team: r.text('team')),
    _EventTag.eliminated => Eliminated(
      team: r.text('team'),
      loss: r.choice('loss', HqLoss.values),
    ),
    _EventTag.unitStored => UnitStored(unitId: unit()),
    _EventTag.recallBegan => RecallBegan(
      unitId: unit(),
      storedAt: r.time('stored_at_us'),
    ),
    _EventTag.unitDeployed => UnitDeployed(
      unitId: unit(),
      at: r.position('at'),
    ),
    _EventTag.sectionLocked => SectionLocked(
      sectionId: r.text('section'),
      until: r.time('until_us'),
    ),
    _EventTag.unitPurchased => UnitPurchased(
      sectionId: r.text('section'),
      unitId: unit(),
      unitType: r.text('unit_type'),
      price: r.integer('price'),
    ),
    _EventTag.weaponPurchased => WeaponPurchased(
      sectionId: r.text('section'),
      weapon: r.text('weapon'),
      price: r.integer('price'),
    ),
    _EventTag.moneyTransferred => MoneyTransferred(
      fromSectionId: r.text('from_section'),
      toSectionId: r.text('to_section'),
      received: r.integer('received'),
      fee: r.integer('fee'),
    ),
    _EventTag.nodePurchased => NodePurchased(
      unitId: unit(),
      stat: r.text('stat'),
      step: r.integer('step'),
    ),
    _EventTag.offerPosted => OfferPosted(
      offerId: r.integer('offer'),
      captorSectionId: r.text('captor_section'),
      ownerSectionId: r.text('owner_section'),
      released: r.texts('released'),
      wanted: r.texts('wanted'),
      price: r.integer('price'),
    ),
    _EventTag.offerAccepted => OfferAccepted(offerId: r.integer('offer')),
    _EventTag.offerRefused => OfferRefused(offerId: r.integer('offer')),
    _EventTag.managerChanged => ManagerChanged(
      team: r.text('team'),
      accountId: r.text('account'),
    ),
    _EventTag.battleStarted => BattleStarted(
      battleId: r.text('battle'),
      mapId: r.text('map'),
      seed: r.integer('seed'),
    ),
    _EventTag.battleEnded => BattleEnded(
      winner: r.text('winner'),
      kind: r.choice('kind', WinKind.values),
      eliminated: r.texts('eliminated'),
    ),
    _EventTag.objectDamaged => ObjectDamaged(
      object: r.text('object'),
      cells: r.cells('cells'),
      hp: r.number('hp'),
    ),
    _EventTag.objectDestroyed => ObjectDestroyed(
      object: r.text('object'),
      cells: r.cells('cells'),
    ),
    _EventTag.craterDug => CraterDug(
      at: r.position('at'),
      radiusM: r.number('radius_m'),
      depthM: r.number('depth_m'),
    ),
    _EventTag.sectionJoined => SectionJoined(
      sectionId: r.text('section'),
      accountId: r.text('account'),
      team: r.text('team'),
      units: r.items('units', _readJoinedUnit),
    ),
  };
}
