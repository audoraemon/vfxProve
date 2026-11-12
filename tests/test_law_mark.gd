extends RefCounted
## Decree's law on a person (LawMark, spec §4.1; plan Task 1): one shared, timed status per owner, asked by every guard's sight and
## seizure, every fight and every witness check. NOBODY is seen by no one and is no one's witness; OFFICER is no suspect to a guard but
## still a witness; CRIMINAL is gone for by every guard who sees him (a FightRule.TARGET_ONLY fight); the latest law set holds; each
## owner lifts only his own; a law runs out by itself; and it changes perception only, never a count. A freed body is no one's law.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const Bells := preload("res://tests/test_bell_ringers.gd")
const Silence := preload("res://tests/test_silence_witness.gd")
const Tax := preload("res://tests/test_tax_collector.gd")
const Proc := preload("res://tests/test_procession.gd")
const Hide := preload("res://tests/test_hide_faithful.gd")


static func run(t) -> void:
	_statuses(t)
	_fights(t)
	_criminal(t)
	_witnesses(t)
	_seizure(t)
	_believers(t)
	_freed(t)


## A citizen out of doors, calm, not `skip`, set down at `at`.
static func _bystander(crowd: Crowd, at: Vector2, skip: Array) -> Person:
	for p in crowd.citizens:
		if MissionDirector._alive(p) and not p.inside and not skip.has(p) and not p.held_by_god() and p.mind != Person.Mind.FLEE:
			Kit.arrive(p, at)
			p.mind = Person.Mind.CALM
			return p
	return null


## Everyone out of doors within `reach` of `at` but `keep` moved well off.
static func _clear(crowd: Crowd, at: Vector2, reach: float, keep: Array) -> void:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and not keep.has(p) and p.ground_pos.distance_to(at) <= reach:
				Kit.arrive(p, at + Vector2(reach + 8.0, 0.0))


## The statuses and the sight and witness checks on The Warning's town: MissionDirector._sees, WarningDirector.witnesses(),
## Crowd.nearest_witness() (Silent Doom's) and TempleReport._witness() (a report's relay).
static func _statuses(t) -> void:
	var s := Kit.world(MissionBook.warning())
	var d: WarningDirector = s.d
	var crowd: Crowd = s.crowd
	var m := d.messenger
	_clear(crowd, m.ground_pos, Crowd.DOOM_WITNESS + 1.0, [m])
	var a := _bystander(crowd, m.ground_pos + Vector2(1.2, 0.0), [m])
	var report := TempleReport.new(m, Vector2.ZERO)
	report.skip = func(_p: Person) -> bool: return false
	var look := a.ground_pos + Vector2(0.2, 0.0)
	var seen := func() -> Array:
		return [d._sees(a, a.ground_pos + Vector2(1.0, 0.0), 2.0, null), d.witnesses().has(a), crowd.nearest_witness(look, m) == a,
			report._witness(crowd, look) == a]
	t.check(a.law == null and LawMark.kind_of(a) == &"" and not LawMark.unseen_by_all(a) and not LawMark.unseen_by_guards(a)
		and not LawMark.wanted(a) and seen.call() == [true, true, true, true],
		"no law: he sees at 1.0, is a witness of the messenger, Silent Doom's nearest and a report's relay (%s)" % [seen.call()])

	LawMark.set_law(a, &"nobody", 5.0, 1)
	t.check(a.law != null and LawMark.kind_of(a) == &"nobody" and LawMark.unseen_by_all(a) and LawMark.unseen_by_guards(a)
		and not LawMark.wanted(a), "NOBODY: unseen by all, and so by the guards")
	t.check(seen.call() == [false, false, false, false],
		"NOBODY: _sees at 1.0 is false, and he is no witness, not Silent Doom's nor a relay's (%s)" % [seen.call()])

	LawMark.set_law(a, &"officer", 5.0, 2)
	t.check(LawMark.kind_of(a) == &"officer" and LawMark.unseen_by_guards(a) and not LawMark.unseen_by_all(a) and not LawMark.wanted(a),
		"OFFICER set after: the latest law holds -- unseen by the guards, not by all")
	t.check(seen.call() == [true, true, true, true], "OFFICER: a citizen witness still sees him (%s)" % [seen.call()])

	LawMark.lift(a, 2)
	t.check(LawMark.kind_of(a) == &"nobody" and seen.call() == [false, false, false, false],
		"the officer's owner lifts his law: the other owner's NOBODY still holds")
	LawMark.lift(a, 99)
	t.check(LawMark.kind_of(a) == &"nobody", "an owner with no law on him lifts nothing")
	LawMark.lift(a, 1)
	t.check(a.law == null and LawMark.kind_of(a) == &"" and seen.call() == [true, true, true, true],
		"the last owner lifts his: no law, and every check is as before")

	LawMark.set_law(a, &"bound", 5.0, 3)
	t.check(LawMark.kind_of(a) == &"bound" and not LawMark.unseen_by_all(a) and not LawMark.unseen_by_guards(a) and not LawMark.wanted(a)
		and seen.call() == [true, true, true, true], "BOUND changes no sight")
	LawMark.lift(a, 3)
	LawMark.set_law(a, &"nonsense", 5.0, 4)
	LawMark.set_law(a, &"nobody", 0.0, 5)
	t.check(a.law == null, "an unknown kind or no time sets no law")

	# Expiry: by LawMark.step, and through the person's own tick.
	LawMark.set_law(a, &"nobody", 1.0, 6)
	LawMark.step(a, 0.5)
	var mid := LawMark.kind_of(a)
	LawMark.step(a, 0.55)
	t.check(mid == &"nobody" and LawMark.kind_of(a) == &"" and a.law == null, "a 1 s law holds at 0.5 s and is gone after 1 s of step")
	LawMark.set_law(a, &"nobody", 1.0, 6)
	for i in roundi(1.1 / DT):
		a.tick(DT)
	Kit.arrive(a, m.ground_pos + Vector2(1.2, 0.0))
	look = a.ground_pos + Vector2(0.2, 0.0)
	t.check(LawMark.kind_of(a) == &"" and a.law == null and seen.call() == [true, true, true, true],
		"the person's own tick runs the law out: every check back to normal (%s)" % [seen.call()])
	Kit.done(s)


## Person._fightable asks the law: a NOBODY is no one's to strike, even the one a fight was set on; an OFFICER is no hostile to a soldier
## breaking up a fight (FightRule.HOSTILES), though a frenzy still goes for him.
static func _fights(t) -> void:
	var s := Kit.world(MissionBook.warning())
	var d: WarningDirector = s.d
	var crowd: Crowd = s.crowd
	var at := d.messenger.ground_pos
	var a := _bystander(crowd, at + Vector2(0.5, 0.0), [d.messenger])
	var mad := _bystander(crowd, at, [d.messenger, a])
	var hunter := _bystander(crowd, at + Vector2(0.0, 0.5), [d.messenger, a, mad])
	var guard: Person = null
	for g in crowd.soldiers:
		if MissionDirector._alive(g) and not g.inside:
			guard = g
			break
	Kit.arrive(guard, at + Vector2(-0.5, 0.0))
	mad.fight(null, 5.0, 0.34, Person.FightRule.ANYONE)
	hunter.fight(a, 5.0, 0.34, Person.FightRule.TARGET_ONLY)
	guard.fight(null, 5.0, Person.SOLDIER_BLOW, Person.FightRule.HOSTILES)
	a.mind = Person.Mind.FIGHT  # a fighting citizen: a hostile to the soldier
	t.check(mad._fightable(a) and hunter._fightable(a) and guard._fightable(a), "no law: the frenzy, his hunter and the soldier may all strike him")
	LawMark.set_law(a, &"nobody", 5.0, 1)
	t.check(not mad._fightable(a) and not hunter._fightable(a) and not guard._fightable(a), "NOBODY: no one may strike him, not even his hunter")
	LawMark.set_law(a, &"officer", 5.0, 1)
	t.check(mad._fightable(a) and hunter._fightable(a) and not guard._fightable(a),
		"OFFICER: the soldier sees one of the garrison, no hostile; the frenzy and his hunter still go for him")
	LawMark.lift(a, 1)
	t.check(guard._fightable(a), "the law lifted, he is a hostile again")
	Kit.done(s)


## CRIMINAL: every guard within LawMark.SIGHT -- a soldier, a watchman -- goes for him in a TARGET_ONLY fight; a citizen does not, nor a
## guard further off; the law over, they are called off.
static func _criminal(t) -> void:
	var s := Kit.world(MissionBook.warning())
	var d: WarningDirector = s.d
	var crowd: Crowd = s.crowd
	var c := d.messenger
	var at := c.ground_pos
	_clear(crowd, at, LawMark.SIGHT + 6.0, [c])
	var soldiers: Array[Person] = []
	for g in crowd.soldiers:
		if MissionDirector._alive(g) and not g.inside and not g.held_by_god() and g.mind != Person.Mind.ASLEEP:
			soldiers.append(g)
	var near := soldiers[0]
	var far := soldiers[1]
	Kit.arrive(near, at + Vector2(LawMark.SIGHT - 1.0, 0.0))
	Kit.arrive(far, at + Vector2(LawMark.SIGHT + 2.0, 0.0))
	var watch := _bystander(crowd, at + Vector2(0.0, 1.0), [c])
	watch.profile.role = CitizenProfile.Role.WATCHMAN
	var plain := _bystander(crowd, at + Vector2(0.0, -1.0), [c, watch])
	plain.profile.role = CitizenProfile.Role.RESIDENT
	c.tick(DT)
	t.check(near.mind != Person.Mind.FIGHT and watch.mind != Person.Mind.FIGHT, "no law: no guard goes for him")
	LawMark.set_law(c, &"criminal", 4.0, 1)
	t.check(LawMark.wanted(c) and not LawMark.unseen_by_guards(c) and not LawMark.unseen_by_all(c), "CRIMINAL: wanted, and seen")
	c.tick(DT)
	t.check(near.mind == Person.Mind.FIGHT and near.fight_target == c and near._fight_rule == Person.FightRule.TARGET_ONLY,
		"a soldier within sight goes for him, a TARGET_ONLY fight")
	t.check(watch.mind == Person.Mind.FIGHT and watch.fight_target == c and watch._fight_rule == Person.FightRule.TARGET_ONLY,
		"so does a watchman")
	t.check(far.mind != Person.Mind.FIGHT and plain.mind != Person.Mind.FIGHT, "a soldier beyond sight does not, nor a plain citizen")
	LawMark.step(c, 4.0)
	t.check(LawMark.kind_of(c) == &"" and near.mind != Person.Mind.FIGHT and watch.mind != Person.Mind.FIGHT,
		"the law run out, the guards are called off")
	# Freed while wanted: his hunters let him go, without error.
	LawMark.set_law(c, &"criminal", 4.0, 1)
	Kit.arrive(near, at + Vector2(1.0, 0.0))
	near.mind = Person.Mind.POST
	c.tick(DT)
	var hunted := near.mind == Person.Mind.FIGHT and near.fight_target == c
	Kit.free_body(s, c)
	Kit.run_for(s, DT * 2.0)
	t.check(hunted and near.mind != Person.Mind.FIGHT, "a wanted man freed: his hunter gives up the fight")
	Kit.done(s)


## No director's witnesses() takes a NOBODY: The Warning's (in _statuses), the Ringer's, the Witness's, the Assassination's (the tax
## collector) and the Procession's.
static func _witnesses(t) -> void:
	# The Ringer (Bell Ringers).
	var s := Bells._world()
	var bd: BellRingersDirector = s.d
	var r := bd.ringers[0]
	bd._send(0)
	Kit.run_for(s, RingerDirector.OUT_PAUSE + RingerDirector.MATE_TICK * 2.0 + DT * 4.0)
	var c := r.messenger
	Bells._clear_round(s, c, r.mates)
	for v: Variant in r.mates:
		Kit.arrive(v as Person, c.ground_pos + Vector2(6.0, 0.0))
	var man := _bystander(s.crowd, c.ground_pos + Vector2(1.0, 0.0), [c] + r.crew())
	var before := r.witnesses().has(man)
	LawMark.set_law(man, &"nobody", 5.0, 1)
	t.check(before and not r.witnesses().has(man), "the Ringer: a NOBODY by the carrier is no witness (before: %s)" % before)
	Kit.done(s)

	# The Witness (Silence the witness): only his mates.
	s = Silence._world()
	var w := Silence._out(s, 0)
	c = w.messenger
	var mate: Person = null
	for v: Variant in w.mates:
		if MissionDirector._alive(v):
			mate = v as Person
			break
	Kit.arrive(mate, c.ground_pos + Vector2(1.2, 0.0))
	mate.mind = Person.Mind.CALM
	before = w.witnesses().has(mate)
	LawMark.set_law(mate, &"nobody", 5.0, 1)
	t.check(before and not w.witnesses().has(mate), "the Witness: a NOBODY mate is no witness (before: %s)" % before)
	Kit.done(s)

	# The Assassination (The Tax Collector).
	s = Tax._world()
	var ad: TaxCollectorDirector = s.d
	var q := ad.quarries[0]
	ad._set_out(q)
	Tax._clear_round(s.crowd, q.target)
	man = _bystander(s.crowd, q.target.ground_pos + Vector2(1.5, 0.0), [q.target])
	before = ad.witnesses(q).has(man)
	LawMark.set_law(man, &"nobody", 5.0, 1)
	t.check(before and not ad.witnesses(q).has(man), "the Assassination: a NOBODY by the quarry is no witness (before: %s)" % before)
	Kit.done(s)

	# The Procession.
	s = Proc._setup()
	var pd: ProcessionDirector = s.d
	var prince := pd.prince
	Proc._clear_round(s, prince.ground_pos, Crowd.DOOM_WITNESS, [prince])
	man = _bystander(s.crowd, prince.ground_pos + Vector2(1.2, 0.0), [prince])
	before = pd.witnesses().has(man)
	LawMark.set_law(man, &"nobody", 5.0, 1)
	t.check(before and not pd.witnesses().has(man), "the Procession: a NOBODY by the Prince is no witness (before: %s)" % before)
	Proc._done(s)


## The Escort type's sight (EscortDirector._seen_by, Hide the faithful's inquisitors): a NOBODY or an OFFICER believer is seen by no watcher,
## a CRIMINAL is; and the believer is still counted in the town (left_count()).
static func _seizure(t) -> void:
	var s := Hide._world()
	var d: HideFaithfulDirector = s.d
	Hide._clear_watch(d)
	d._come_out(0)
	Kit.run_for(s, EscortDirector.TICK + DT)
	var lead := d.lamp(0)
	var lp := lead.man as Person
	var inq := d.inquisitors[0] as Person
	Kit.arrive(inq, lp.ground_pos + Vector2(1.0, 0.0))
	var left := d.left_count()
	t.check(d._watching(inq) and d._seen_by(lead) == inq, "no law: an inquisitor at 1.0 sees the believer")
	LawMark.set_law(lp, &"nobody", 5.0, 1)
	t.check(d._seen_by(lead) == null and d.left_count() == left, "NOBODY: no watcher sees him, and he still counts (%d)" % d.left_count())
	LawMark.set_law(lp, &"officer", 5.0, 1)
	t.check(d._seen_by(lead) == null and d.left_count() == left, "OFFICER: no suspect to the inquisitor, and he still counts")
	LawMark.set_law(lp, &"criminal", 5.0, 1)
	t.check(d._seen_by(lead) == inq, "CRIMINAL: seen")
	LawMark.lift(lp, 1)
	t.check(d._seen_by(lead) == inq, "the law lifted: seen again")
	Kit.done(s)


## Perception only, and an override's sight (First Prayers' _sees() calls the base's): a NOBODY Faithful sees nothing, and a NOBODY
## Believer is still counted by believers_outside(), the count BelieversObjective reads.
static func _believers(t) -> void:
	var s := Kit.world(MissionBook.first_prayers())
	var d: FirstPrayersDirector = s.d
	var f: Person = null
	for v in d.faithful:
		if MissionDirector._alive(v) and not v.inside:
			f = v
			break
	f.mind = Person.Mind.CALM
	var b := _bystander(s.crowd, f.ground_pos + Vector2(4.0, 0.0), [f] + d.faithful)
	d.believers.append(b)
	var n := d.believers_outside()
	var spot := f.ground_pos + Vector2(1.0, 0.0)
	var before := d._sees(f, spot, 2.0, null)
	LawMark.set_law(f, &"nobody", 5.0, 1)
	t.check(before and not d._sees(f, spot, 2.0, null), "First Prayers: a NOBODY Faithful sees nothing at 1.0 (before: %s)" % before)
	LawMark.set_law(b, &"nobody", 5.0, 1)
	t.check(n >= 1 and d.believers_outside() == n, "a NOBODY Believer is still counted (%d of %d)" % [d.believers_outside(), n])
	Kit.done(s)


## A freed body passed to every helper answers the default, without error.
static func _freed(t) -> void:
	var p := Person.new()
	var gone: Variant = p
	p.free()
	LawMark.set_law(gone, &"nobody", 5.0, 1)
	LawMark.lift(gone, 1)
	LawMark.step(gone, 0.1)
	t.check(LawMark.kind_of(gone) == &"" and not LawMark.unseen_by_guards(gone) and not LawMark.unseen_by_all(gone) and not LawMark.wanted(gone)
		and LawMark.kind_of(null) == &"" and not LawMark.unseen_by_all(null), "a freed body or none: no law, and no error")
