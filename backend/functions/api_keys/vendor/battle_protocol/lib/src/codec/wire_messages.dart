part of 'wire.dart';

// The fields of the messages between the host and its clients (M6 Issue 2),
// in order. As for commands and events, the order of the fields and of the
// tags is version 1: a new message is added at the end of its tags.

/// The `type` of a client message.
enum _ClientTag { signIn, sendCommand, resyncRequest, heartbeat }

/// The `type` of a host message.
enum _HostTag {
  signInAccepted,
  signInRefused,
  commandAccepted,
  commandRefused,
  sectionView,
  tickUpdate,
  relicAlert,
  goodbye,
  roster,
}

/// Writes a client message: its type, then its fields.
void writeClientMessage(FieldWriter w, ClientMessage message) {
  switch (message) {
    case SignIn(:final battleId, :final kind, :final credential):
      w
        ..choice('type', _ClientTag.signIn)
        ..text('battle', battleId)
        ..choice('kind', kind)
        ..text('credential', credential);
    case SendCommand(:final requestId, :final command):
      w
        ..choice('type', _ClientTag.sendCommand)
        ..integer('request', requestId)
        ..item('command', command, writeCommand);
    case ResyncRequest():
      w.choice('type', _ClientTag.resyncRequest);
    case Heartbeat():
      w.choice('type', _ClientTag.heartbeat);
  }
}

/// Reads a client message.
ClientMessage readClientMessage(FieldReader r) =>
    switch (r.choice('type', _ClientTag.values)) {
      _ClientTag.signIn => SignIn(
        battleId: r.text('battle'),
        kind: r.choice('kind', CredentialKind.values),
        credential: r.text('credential'),
      ),
      _ClientTag.sendCommand => SendCommand(
        requestId: r.integer('request'),
        command: r.item('command', readCommand),
      ),
      _ClientTag.resyncRequest => const ResyncRequest(),
      _ClientTag.heartbeat => const Heartbeat(),
    };

/// Writes a host message: its type, then its fields.
void writeHostMessage(FieldWriter w, HostMessage message) {
  switch (message) {
    case SignInAccepted(
      :final accountId,
      :final sectionId,
      :final team,
      :final battleTime,
    ):
      w
        ..choice('type', _HostTag.signInAccepted)
        ..text('account', accountId)
        ..text('section', sectionId)
        ..text('team', team)
        ..time('battle_time_us', battleTime);
    case SignInRefused(:final reason):
      w
        ..choice('type', _HostTag.signInRefused)
        ..choice('reason', reason);
    case CommandAccepted(:final requestId, :final seq):
      w
        ..choice('type', _HostTag.commandAccepted)
        ..integer('request', requestId)
        ..integer('seq', seq);
    case CommandRefused(:final requestId, :final reason):
      w
        ..choice('type', _HostTag.commandRefused)
        ..integer('request', requestId)
        ..text('reason', reason);
    case SectionView(
      :final at,
      :final weather,
      :final section,
      :final units,
      :final hqs,
      :final relics,
      :final hold,
      :final world,
    ):
      w
        ..choice('type', _HostTag.sectionView)
        ..time('at_us', at)
        ..text('weather', weather)
        ..item('section', section, _writeSectionPrivate)
        ..items('units', units, _writeUnitView)
        ..items('hqs', hqs, _writeHqView)
        ..items('relics', relics, _writeRelicView)
        ..maybe('hold', hold, (w, k, v) => w.item(k, v, _writeHoldView))
        ..items('world', world, writeEvent);
    case TickUpdate():
      w
        ..choice('type', _HostTag.tickUpdate)
        ..time('at_us', message.at)
        ..maybe('weather', message.weather, _writeOptionalText)
        ..items('moved', message.moved, _writeUnitPosition)
        ..items('appeared', message.appeared, _writeUnitView)
        ..texts('gone', message.gone)
        ..items('events', message.events, writeEvent)
        ..items('bursts', message.bursts, _writeBurst)
        ..items('unseen_hits', message.unseenHits, _writeUnseenHit)
        ..items('fired', message.fired, _writeFired)
        ..items('own_units', message.ownUnits, _writeUnitView)
        ..maybe(
          'section',
          message.section,
          (w, k, v) => w.item(k, v, _writeSectionPrivate),
        )
        ..items('hqs', message.hqs, _writeHqView)
        ..texts('hqs_gone', message.hqsGone)
        ..items('relics', message.relics, _writeRelicView);
    case RelicAlert(:final at, :final relicId, :final team):
      w
        ..choice('type', _HostTag.relicAlert)
        ..time('at_us', at)
        ..text('relic', relicId)
        ..text('team', team);
    case Goodbye(:final reason):
      w
        ..choice('type', _HostTag.goodbye)
        ..choice('reason', reason);
    case Roster(:final units, :final weapons):
      w
        ..choice('type', _HostTag.roster)
        ..items('units', units, _writeRosterUnit)
        ..items('weapons', weapons, _writeRosterWeapon);
  }
}

/// Reads a host message.
HostMessage readHostMessage(FieldReader r) =>
    switch (r.choice('type', _HostTag.values)) {
      _HostTag.signInAccepted => SignInAccepted(
        accountId: r.text('account'),
        sectionId: r.text('section'),
        team: r.text('team'),
        battleTime: r.time('battle_time_us'),
      ),
      _HostTag.signInRefused => SignInRefused(
        r.choice('reason', SignInRefusal.values),
      ),
      _HostTag.commandAccepted => CommandAccepted(
        requestId: r.integer('request'),
        seq: r.integer('seq'),
      ),
      _HostTag.commandRefused => CommandRefused(
        requestId: r.integer('request'),
        reason: r.text('reason'),
      ),
      _HostTag.sectionView => SectionView(
        at: r.time('at_us'),
        weather: r.text('weather'),
        section: r.item('section', _readSectionPrivate),
        units: r.items('units', _readUnitView),
        hqs: r.items('hqs', _readHqView),
        relics: r.items('relics', _readRelicView),
        hold: r.maybe('hold', (r, k) => r.item(k, _readHoldView)),
        world: r.items('world', readEvent),
      ),
      _HostTag.tickUpdate => TickUpdate(
        at: r.time('at_us'),
        weather: r.maybe('weather', _readOptionalText),
        moved: r.items('moved', _readUnitPosition),
        appeared: r.items('appeared', _readUnitView),
        gone: r.texts('gone'),
        events: r.items('events', readEvent),
        bursts: r.items('bursts', _readBurst),
        unseenHits: r.items('unseen_hits', _readUnseenHit),
        fired: r.items('fired', _readFired),
        ownUnits: r.items('own_units', _readUnitView),
        section: r.maybe('section', (r, k) => r.item(k, _readSectionPrivate)),
        hqs: r.items('hqs', _readHqView),
        hqsGone: r.texts('hqs_gone'),
        relics: r.items('relics', _readRelicView),
      ),
      _HostTag.relicAlert => RelicAlert(
        at: r.time('at_us'),
        relicId: r.text('relic'),
        team: r.text('team'),
      ),
      _HostTag.goodbye => Goodbye(r.choice('reason', GoodbyeReason.values)),
      _HostTag.roster => Roster(
        units: r.items('units', _readRosterUnit),
        weapons: r.items('weapons', _readRosterWeapon),
      ),
    };

void _writeRosterUnit(FieldWriter w, RosterUnit unit) => w
  ..text('unit_type', unit.unitType)
  ..text('category', unit.category)
  ..integer('price', unit.price)
  ..texts('weapons', unit.weapons);

RosterUnit _readRosterUnit(FieldReader r) => RosterUnit(
  unitType: r.text('unit_type'),
  category: r.text('category'),
  price: r.integer('price'),
  weapons: r.texts('weapons'),
);

void _writeRosterWeapon(FieldWriter w, RosterWeapon weapon) => w
  ..text('weapon', weapon.weapon)
  ..integer('price', weapon.price);

RosterWeapon _readRosterWeapon(FieldReader r) =>
    RosterWeapon(weapon: r.text('weapon'), price: r.integer('price'));

void _writeTime(FieldWriter w, String key, Duration value) =>
    w.time(key, value);

Duration _readTime(FieldReader r, String key) => r.time(key);

void _writeApView(FieldWriter w, ApView ap) => w
  ..number('value', ap.value)
  ..time('at_us', ap.at)
  ..number('per_hour', ap.perHour)
  ..number('max', ap.max);

ApView _readApView(FieldReader r) => ApView(
  value: r.number('value'),
  at: r.time('at_us'),
  perHour: r.number('per_hour'),
  max: r.number('max'),
);

void _writeUnitPrivate(FieldWriter w, UnitPrivate unit) => w
  ..choice('place', unit.place)
  ..item('ap', unit.ap, _writeApView)
  ..number('sight_range_m', unit.sightRangeM)
  ..number('morale', unit.morale)
  ..integer('rounds', unit.rounds)
  ..number('xp_earned', unit.xpEarned)
  ..number('xp_unspent', unit.xpUnspent)
  ..maybe('transport', unit.transportId, _writeOptionalText)
  ..maybe('moving_until_us', unit.movingUntil, _writeTime)
  ..maybe('busy_until_us', unit.busyUntil, _writeTime)
  ..maybe('observing_until_us', unit.observingUntil, _writeTime);

UnitPrivate _readUnitPrivate(FieldReader r) => UnitPrivate(
  place: r.choice('place', UnitPlace.values),
  ap: r.item('ap', _readApView),
  sightRangeM: r.number('sight_range_m'),
  morale: r.number('morale'),
  rounds: r.integer('rounds'),
  xpEarned: r.number('xp_earned'),
  xpUnspent: r.number('xp_unspent'),
  transportId: r.maybe('transport', _readOptionalText),
  movingUntil: r.maybe('moving_until_us', _readTime),
  busyUntil: r.maybe('busy_until_us', _readTime),
  observingUntil: r.maybe('observing_until_us', _readTime),
);

void _writeUnitView(FieldWriter w, UnitView unit) => w
  ..text('unit', unit.unitId)
  ..text('unit_type', unit.unitType)
  ..text('section', unit.sectionId)
  ..text('team', unit.team)
  ..number('hp', unit.hp)
  ..number('max_hp', unit.maxHp)
  ..maybe('position', unit.position, (w, k, v) => w.position(k, v))
  ..flag('flying', value: unit.flying)
  ..maybe('weapon', unit.weapon, _writeOptionalText)
  ..maybe(
    'private',
    unit.private,
    (w, k, v) => w.item(k, v, _writeUnitPrivate),
  );

UnitView _readUnitView(FieldReader r) => UnitView(
  unitId: r.text('unit'),
  unitType: r.text('unit_type'),
  sectionId: r.text('section'),
  team: r.text('team'),
  hp: r.number('hp'),
  maxHp: r.number('max_hp'),
  position: r.maybe('position', (r, k) => r.position(k)),
  flying: r.flag('flying'),
  weapon: r.maybe('weapon', _readOptionalText),
  private: r.maybe('private', (r, k) => r.item(k, _readUnitPrivate)),
);

void _writeUnitPosition(FieldWriter w, UnitPosition moved) => w
  ..text('unit', moved.unitId)
  ..position('at', moved.position);

UnitPosition _readUnitPosition(FieldReader r) =>
    UnitPosition(r.text('unit'), r.position('at'));

void _writeBurst(FieldWriter w, Burst burst) => w
  ..text('attacker', burst.attackerId)
  ..text('section', burst.sectionId)
  ..text('weapon', burst.weapon)
  ..integer('shots', burst.shots)
  ..integer('hits', burst.hits)
  ..items('impacts', burst.impacts, _writeImpact);

Burst _readBurst(FieldReader r) => Burst(
  attackerId: r.text('attacker'),
  sectionId: r.text('section'),
  weapon: r.text('weapon'),
  shots: r.integer('shots'),
  hits: r.integer('hits'),
  impacts: r.items('impacts', _readImpact),
);

void _writeUnseenHit(FieldWriter w, UnseenHit hit) => w
  ..text('target', hit.targetId)
  ..number('damage', hit.damage)
  ..choice('result', hit.result);

UnseenHit _readUnseenHit(FieldReader r) => UnseenHit(
  targetId: r.text('target'),
  damage: r.number('damage'),
  result: r.choice('result', ImpactResult.values),
);

void _writeFired(FieldWriter w, Fired fired) => w
  ..text('attacker', fired.attackerId)
  ..text('section', fired.sectionId)
  ..text('weapon', fired.weapon)
  ..integer('shots', fired.shots)
  ..items('impacts', fired.impacts, _writeImpact);

Fired _readFired(FieldReader r) => Fired(
  attackerId: r.text('attacker'),
  sectionId: r.text('section'),
  weapon: r.text('weapon'),
  shots: r.integer('shots'),
  impacts: r.items('impacts', _readImpact),
);

void _writeHqView(FieldWriter w, HqView hq) => w
  ..text('team', hq.team)
  ..position('position', hq.position)
  ..number('hp', hq.hp)
  ..number('max_hp', hq.maxHp)
  ..maybe('ap', hq.ap, (w, k, v) => w.item(k, v, _writeApView));

HqView _readHqView(FieldReader r) => HqView(
  team: r.text('team'),
  position: r.position('position'),
  hp: r.number('hp'),
  maxHp: r.number('max_hp'),
  ap: r.maybe('ap', (r, k) => r.item(k, _readApView)),
);

void _writeRelicView(FieldWriter w, RelicView relic) => w
  ..text('relic', relic.relicId)
  ..position('position', relic.position)
  ..maybe('owner', relic.owner, _writeOptionalText);

RelicView _readRelicView(FieldReader r) => RelicView(
  relicId: r.text('relic'),
  position: r.position('position'),
  owner: r.maybe('owner', _readOptionalText),
);

void _writeHoldView(FieldWriter w, HoldView hold) => w
  ..text('team', hold.team)
  ..time('since_us', hold.since)
  ..time('wins_at_us', hold.winsAt);

HoldView _readHoldView(FieldReader r) => HoldView(
  team: r.text('team'),
  since: r.time('since_us'),
  winsAt: r.time('wins_at_us'),
);

void _writeOffer(FieldWriter w, OfferPosted offer) => w
  ..integer('offer', offer.offerId)
  ..text('captor_section', offer.captorSectionId)
  ..text('owner_section', offer.ownerSectionId)
  ..texts('released', offer.released)
  ..texts('wanted', offer.wanted)
  ..integer('price', offer.price);

OfferPosted _readOffer(FieldReader r) => OfferPosted(
  offerId: r.integer('offer'),
  captorSectionId: r.text('captor_section'),
  ownerSectionId: r.text('owner_section'),
  released: r.texts('released'),
  wanted: r.texts('wanted'),
  price: r.integer('price'),
);

void _writeSectionPrivate(FieldWriter w, SectionPrivate section) => w
  ..integer('money', section.money)
  ..number('xp', section.xp)
  ..maybe('locked_until_us', section.lockedUntil, _writeTime)
  ..texts('stored_weapons', section.storedWeapons)
  ..items('prisoners', section.prisoners, _writeJoinedUnit)
  ..items('offers', section.offers, _writeOffer);

SectionPrivate _readSectionPrivate(FieldReader r) => SectionPrivate(
  money: r.integer('money'),
  xp: r.number('xp'),
  lockedUntil: r.maybe('locked_until_us', _readTime),
  storedWeapons: r.texts('stored_weapons'),
  prisoners: r.items('prisoners', _readJoinedUnit),
  offers: r.items('offers', _readOffer),
);
