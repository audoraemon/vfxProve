extends RefCounted
## Corpse Guise (Death, Tier III, quiet; spec 5.3): up to 4 people within 2 of the click pass as the walking dead for 25 s.
## The watch looks straight past them (soldiers, watchmen, inquisitors: no seizure, no witness, no report, no fight), and
## Death's own undead leave them alone. The cast raises no alarm and frightens nobody. statuses[&"guise"] holds the seconds
## left; the effect counts it down and takes it off at zero, so a believer whose guise ends is seen and seized as before.

const RD := preload("res://tests/test_raise_dead.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const Mira := preload("res://tests/test_miras_house.gd")
const Lamb := preload("res://tests/test_lost_lamb.gd")
const DT := 0.05


static func _cast(ctx: FxContext, at: Vector2) -> CorpseGuiseFx:
	return FxTimeline.cast(CorpseGuiseFx, ctx, at) as CorpseGuiseFx


static func run(t) -> void:
	_book(t)
	var made := RD._setup()
	_marks(t, made)
	_zombies(t, made)
	_quiet(t, made)
	_witness(t, made)
	_fight(t, made)
	_countdown(t, made)
	_overlap(t, made)
	_looks(t, made)
	_shrouds(t, made)
	RD._done(made)
	_watcher(t)
	_inquisitor(t)
	_seized_after(t)
	_faithful(t)
	_freed_fx(t)
	_mira(t)
	_lamb_hunters(t)
	_exodus_searchers(t)
	_trail_waits(t)


## The row: Tier III's 3 Might, 50 s, a click, quiet (no danger for the town to see), Death's.
static func _book(t) -> void:
	var p := PowerBook.get_power("guise")
	t.check(not p.is_empty() and int(p.dp) == 3 and float(p.cooldown) == 50.0 and String(p.aim) == "click"
		and PowerBook.is_quiet("guise") and String(p.get("authority", "")) == "death" and not p.has("alarm"),
		"Corpse Guise: Death, 3 DP, 50 s, a click, quiet, no alarm (%s)" % [p])
	t.check(not PowerBook.REACH.has("guise") and not PowerBook.IMPACT.has("guise"), "no reach, no impact: nothing for the town to see")
	t.check(CorpseGuiseFx.MARK_R == 2.0 and CorpseGuiseFx.MOST == 4 and CorpseGuiseFx.SPAN == 25.0, "a circle of 2, 4 at most, 25 s")
	var area: Dictionary = Targeting.AREAS.get("guise", {})
	t.check(String(area.get("shape", "")) == "circle" and float(area.get("r", 0.0)) == CorpseGuiseFx.MARK_R
		and Targeting.AREA_STATS.get("guise", {}) == {"r": "MARK_R"}, "its area is the marking circle (%s)" % [area])
	t.check(Sfx.CATALOG.has(&"q_guise") and PowerBook.icon("guise") != null and PowerBook.hud_icon("guise") != null
		and PowerBook.clip("guise") != null, "its own cue q_guise, its icons and its clip")
	t.check(Rules.POWER_KINDS.get("guise", null) == [] and PowerBook.FAMILY.get("guise", "") == "death", "it kills nobody; Death's family")


## "marks the 4 nearest within 2, not 5": the nearest by distance, a tie broken by instance id; nobody past 2.
static func _marks(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var ps: Array[Person] = []
	for i in 7:
		ps.append(crowd.citizens[10 + i])
	ps[0].ground_pos = at + Vector2(0.3, 0.0)
	ps[1].ground_pos = at + Vector2(0.0, 0.6)
	ps[2].ground_pos = at + Vector2(-0.9, 0.0)
	ps[3].ground_pos = at + Vector2(1.2, 0.0)  # these two tie: the lower instance id is marked
	ps[4].ground_pos = at + Vector2(0.0, -1.2)
	ps[5].ground_pos = at + Vector2(1.5, 0.0)  # the fifth within 2: not marked
	ps[6].ground_pos = at + Vector2(2.5, 0.0)  # past 2
	var tie_win := ps[3] if ps[3].get_instance_id() < ps[4].get_instance_id() else ps[4]
	var tie_lose := ps[4] if tie_win == ps[3] else ps[3]
	var picked := CorpseGuiseFx.marked_at(made[3], at)
	t.check(Array(picked) == [ps[0], ps[1], ps[2], tie_win], "the 4 nearest within 2, a tie by instance id (%d picked)" % picked.size())
	var fx := _cast(made[5], at)
	var want: Array = [ps[0], ps[1], ps[2], tie_win]
	var ok := fx.marked.size() == CorpseGuiseFx.MOST
	for p in want:
		ok = ok and p.guised() and is_equal_approx(float(p.statuses[&"guise"]), CorpseGuiseFx.SPAN)
	t.check(ok, "marks the 4 nearest within 2, not 5: each holds 25 s of guise")
	t.check(not tie_lose.guised() and not ps[5].guised() and not ps[6].guised(), "the fifth within 2 and the one past 2 are not marked")
	fx.end_now()
	t.check(not ps[0].guised() and not ps[0].statuses.has(&"guise"), "an effect cut short takes its guise off")


## "Death's zombies pass a guised person by": a zombie risen beside a guised person goes for the one farther off.
static func _zombies(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var guised: Person = crowd.citizens[3]
	var other: Person = crowd.citizens[4]
	guised.ground_pos = at + Vector2(0.5, 0.0)
	other.ground_pos = at + Vector2(4.0, 0.0)
	var fx := _cast(made[5], guised.ground_pos)
	t.check(guised.guised() and not other.guised(), "one guised, one not")
	var body := RD._body(made, 5, at, &"mob")
	var v := Visitors.new().setup(made[3], crowd, made[2], made[4])
	var z := DeathParts.zombie(v, body, false)
	for i in roundi(0.6 / DT):
		v.step(DT)
	t.check(z.target == other, "Death's zombies pass a guised person by (target %s)" % [z.target])
	v.clear()
	fx.end_now()


## "no alarm, no fright from the cast": the crowd hears nothing, holds no danger, and everyone near stays calm.
static func _quiet(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var near: Array = []
	for i in 6:
		var p: Person = crowd.citizens[20 + i]
		p.ground_pos = at + Vector2(0.4 * float(i), 0.3)
		near.append(p)
	var alarm := crowd.alarm
	var held := crowd.held_count()
	crowd.on_cast(at, Vector2.ZERO, 0.0, "guise")
	var fx := _cast(made[5], at)
	RD._run(fx, 2.0, near)
	var calm := near.all(func(p: Person) -> bool: return p.mind == Person.Mind.CALM)
	t.check(crowd.alarm == alarm and crowd.held_count() == held and calm,
		"no alarm, no fright from the cast (alarm %.2f -> %.2f, held %d, minds %s)" % [alarm, crowd.alarm, crowd.held_count(),
			near.map(func(p: Person) -> String: return Person.Mind.keys()[p.mind])])
	var src := FileAccess.get_file_as_string("res://src/fx/death/corpse_guise.gd")
	t.check(src != "" and not src.contains("add_alarm") and not src.contains("fright(") and not src.contains("panic("),
		"the effect's code never alarms, frightens or panics anyone")
	fx.end_now()


## A guised person is no witness: Crowd.nearest_witness() passes over him.
static func _witness(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var p: Person = crowd.citizens[30]
	p.ground_pos = at + Vector2(0.5, 0.0)
	t.check(crowd.nearest_witness(at) == p, "the one beside a death is its witness")
	var fx := _cast(made[5], p.ground_pos)
	t.check(p.guised() and crowd.nearest_witness(at) == null, "guised, he is no witness")
	fx.end_now()
	t.check(crowd.nearest_witness(at) == p, "and a witness again once it ends")


## Soldiers' choice of a citizen to fight passes over a guised one (a power's own order -- TARGET_ONLY -- still holds).
static func _fight(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var c: Person = crowd.citizens[31]
	var s: Person = crowd.soldiers[1]
	c.ground_pos = at
	s.ground_pos = at + Vector2(0.8, 0.0)
	c.fight(null, 10.0, 0.1)
	t.check(c.mind == Person.Mind.FIGHT, "a citizen fighting")
	s.fight(null, 10.0, Person.SOLDIER_BLOW, Person.FightRule.HOSTILES)
	t.check(s._fightable(c), "a soldier would go for him")
	var fx := _cast(made[5], c.ground_pos)
	t.check(c.guised() and not s._fightable(c), "a soldier looks straight past a guised one")
	s._fight_step(0.6)
	t.check(s.fight_target != c, "and does not choose him")
	fx.end_now()
	t.check(s._fightable(c), "the guise ended, he would again")
	c.stop_fighting()
	s.stop_fighting()


## The guise counts down in statuses[&"guise"] and comes off at zero.
static func _countdown(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var p: Person = crowd.citizens[32]
	p.ground_pos = at
	var fx := _cast(made[5], at)
	RD._run(fx, CorpseGuiseFx.SPAN - 1.0)
	t.check(p.guised() and absf(float(p.statuses[&"guise"]) - 1.0) < 0.11, "a second before the end, a second left (%.2f)" % float(p.statuses.get(&"guise", -1.0)))
	RD._run(fx, 1.5)
	t.check(not p.guised() and not p.statuses.has(&"guise") and fx.finished, "at 25 s the guise is gone, and the effect with it")


## A second cast on the guised gives them the full 25 s again; the first one ending does not take it off.
static func _overlap(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var p: Person = crowd.citizens[33]
	p.ground_pos = at
	var a := _cast(made[5], at)
	RD._run(a, 10.0)
	var b := _cast(made[5], at)
	for i in roundi(16.0 / DT):
		if not a.finished:
			a._process(DT)
		b._process(DT)
	t.check(a.finished and p.guised() and absf(float(p.statuses[&"guise"]) - 9.0) < 0.11,
		"recast at 10 s: the first ends at 25 s and leaves the second's 9 s (%.2f)" % float(p.statuses.get(&"guise", -1.0)))
	RD._run(b, 9.5)
	t.check(not p.guised(), "then it ends")


## Each guised person wears a shroud mark (grey shroud, closed eye) for the whole span; a second cast leaves one.
static func _shrouds(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var ps: Array[Person] = []
	for i in 4:
		var p: Person = crowd.citizens[40 + i]
		p.ground_pos = at + Vector2(0.4 * float(i), 0.2)
		ps.append(p)
	var fx := _cast(made[5], at)
	t.check(fx.shrouds.size() == 4, "each guised person carries a shroud mark for the whole span (%d marks)" % fx.shrouds.size())
	RD._run(fx, CorpseGuiseFx.SPAN - 0.5)
	var live := fx.shrouds.all(func(m: Node2D) -> bool: return is_instance_valid(m) and m.visible and not m.is_queued_for_deletion())
	t.check(live and fx.shrouds.size() == 4, "each guised person carries a shroud mark for the whole span: all valid at SPAN - 0.5")
	# The marks' own logic (they are detached here, so step them by hand): kept and visible, hidden indoors, freed at the lift.
	var kept := true
	for m in fx.shrouds:
		m._process(0.0)
		kept = kept and is_instance_valid(m) and not m.is_queued_for_deletion() and m.visible
	t.check(kept, "a mark steps on, valid and visible, while its guise is kept")
	var inner: CorpseGuiseFx.GuiseMark = fx.shrouds[1]
	inner.who.inside = true
	inner._process(0.0)
	t.check(not inner.visible and not inner.is_queued_for_deletion(), "a mark hides while its person is indoors")
	inner.who.inside = false
	inner._process(0.0)
	t.check(inner.visible, "and shows again when he comes out")
	var lifted: CorpseGuiseFx.GuiseMark = fx.shrouds[0]
	lifted.who.statuses.erase(&"guise")
	lifted._process(0.0)
	t.check(lifted.is_queued_for_deletion(), "a mark frees itself the moment its guise lifts")
	RD._run(fx, 0.6)
	var gone := fx.shrouds.all(func(m: Node2D) -> bool: return not is_instance_valid(m) or m.is_queued_for_deletion())
	t.check(gone, "and none at SPAN + 0.1")
	# A second cast on the same person: one mark once the first stops keeping him.
	RD._clear_all(made)
	var q: Person = crowd.citizens[44]
	q.ground_pos = at
	var a := _cast(made[5], at)
	RD._run(a, 5.0)
	var b := _cast(made[5], at)
	RD._run(b, 0.1)
	var n := 0
	for m in a.shrouds + b.shrouds:
		if is_instance_valid(m) and not m.is_queued_for_deletion() and m.who == q and m.fx._keeps(q):
			n += 1
	var drawn := 0
	for m in a.shrouds + b.shrouds:
		if is_instance_valid(m) and not m.is_queued_for_deletion() and m.who == q:
			drawn += 1
	t.check(n == 1 and drawn == 1, "a guise taken over by a second cast keeps one mark (%d keeping, %d alive)" % [n, drawn])
	# Freed early: the marks go with the effect.
	var marks: Array = b.shrouds.duplicate()
	b.free()
	t.check(marks.all(func(m) -> bool: return not is_instance_valid(m) or m.is_queued_for_deletion()), "a freed effect leaves no mark behind")


## The guised are drawn greyed with eyes down: the walking dead's lurch when they walk, and a redraw when it starts and ends.
static func _looks(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var p: Person = crowd.citizens[34]
	p.ground_pos = at
	p._stride = true
	t.check(p._sprite_pose()[0] == &"walk", "walking, he walks")
	var plain := p._art_signature()
	var fx := _cast(made[5], at)
	t.check(p._sprite_pose()[0] == &"lurch", "guised, he shambles head down like the walking dead")
	p._stride = false
	var still := p._art_signature()
	p._flash = 0.001  # the full fold, with a flash term that rounds to 0: the same picture
	t.check(p._art_signature() == still, "the guised quiet signature is the full fold's integer")
	p._flash = 0.0
	fx.end_now()
	t.check(p._art_signature() != still, "the guise ending redraws him")
	p._stride = true
	t.check(p._art_signature() == plain, "and he looks as before")
	p._stride = false


# --- The watch, in the Hunt (Hide the Faithful) ---

static func _hunt() -> Dictionary:
	var s := Kit.world(HuntBook.def(MissionBook.HIDE_FAITHFUL))
	var d: HideFaithfulDirector = s.d
	for v: Variant in d._watchers():
		if MissionDirector._alive(v):
			Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(60.0, 60.0))
	d._come_out(0)
	Kit.run_for(s, EscortDirector.TICK + DT)
	_give_ctx(s)
	return s


## An FxContext over a mission world (the kit's, Mira's House's, The Lost Lamb's: the same keys), kept as s.ctx.
static func _give_ctx(s: Dictionary) -> FxContext:
	var ctx := FxContext.new()
	ctx.env = s.env
	ctx.field = s.field
	ctx.crowd = s.crowd
	ctx.world = s.world
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 7
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	s["ctx"] = ctx
	return ctx


## Frees a world's FxContext layers (an effect freed unfinished takes its guise off).
static func _drop_ctx(s: Dictionary) -> void:
	var ctx: FxContext = s.ctx
	ctx.overhead.free()
	ctx.ground.free()


static func _hunt_done(s: Dictionary) -> void:
	_drop_ctx(s)
	Kit.done(s)


## Runs the night and the guise together.
static func _run_both(s: Dictionary, fx: FxTimeline, seconds: float) -> void:
	for i in roundi(seconds / DT):
		if not fx.finished:
			fx._process(DT)
		Kit.run_for(s, DT)


## "a watcher does not see a guised believer": a patrol soldier a step away passes him by.
static func _watcher(t) -> void:
	var s := _hunt()
	var d: HideFaithfulDirector = s.d
	var lead := d.lamp(0)
	var lp := lead.man as Person
	var fx := _cast(s.ctx, lp.ground_pos)
	t.check(lp.guised(), "the lamp-bearer is guised")
	var soldier := d.patrols[0][0] as Person
	Kit.arrive(soldier, lp.ground_pos + Vector2(1.0, 0.0))
	soldier.send_to_post(soldier.ground_pos)
	_run_both(s, fx, 2.0 * EscortDirector.TICK + DT)
	t.check(not lead.held and d.seizures == 0 and d._seen_by(lead) == null,
		"a watcher does not see a guised believer (held %s, seizures %d)" % [lead.held, d.seizures])
	_hunt_done(s)
	# The control: the same patrol soldier a step from the same believer, unguised, sees and seizes him.
	var n := _hunt()
	var e: HideFaithfulDirector = n.d
	var lead2 := e.lamp(0)
	var lp2 := lead2.man as Person
	var soldier2 := e.patrols[0][0] as Person
	Kit.arrive(soldier2, lp2.ground_pos + Vector2(1.0, 0.0))
	soldier2.send_to_post(soldier2.ground_pos)
	Kit.run_for(n, 2.0 * EscortDirector.TICK + DT)
	t.check(not lp2.guised() and lead2.held and lead2.seizer == soldier2 and e.seizures == 1, "the control: unguised, he is seen and seized")
	_hunt_done(n)


## "an inquisitor beside a guised believer does not seize him", nor takes up his trail.
static func _inquisitor(t) -> void:
	var s := _hunt()
	var d: HideFaithfulDirector = s.d
	var lead := d.lamp(0)
	var lp := lead.man as Person
	var fx := _cast(s.ctx, lp.ground_pos)
	var by := d.inquisitors[0] as Person
	Kit.arrive(by, lp.ground_pos + Vector2(1.0, 0.0))
	by.send_to_post(by.ground_pos)
	by.mind = Person.Mind.POST
	_run_both(s, fx, 2.0 * EscortDirector.TICK + DT)
	t.check(not lead.held and d.seizures == 0, "an inquisitor beside a guised believer does not seize him")
	# The search following this household's trail goes to a believer the inquisitors can see, never to a guised one.
	d._trail = 0
	var to := d._search_point()
	var h: ExodusDirector.Household = d.households[0]
	var none_seen := true
	for c: EscortDirector.Charge in h.members:
		if not d._resolved(c) and not (c.man as Person).inside and not (c.man as Person).guised():
			none_seen = false
	var at_guised := false
	for c: EscortDirector.Charge in h.members:
		if (c.man as Person).guised() and to == (c.man as Person).ground_pos:
			at_guised = true
	t.check(not at_guised and (to != Vector2.INF or none_seen), "the trail never leads to a guised believer (%s)" % [to])
	_hunt_done(s)


## "when the guise ends he can be seized again" (review focus 4): the inquisitor still beside him seizes him once it is off.
static func _seized_after(t) -> void:
	var s := _hunt()
	var d: HideFaithfulDirector = s.d
	var lead := d.lamp(0)
	var lp := lead.man as Person
	var fx := _cast(s.ctx, lp.ground_pos)
	var by := d.inquisitors[0] as Person
	Kit.arrive(by, lp.ground_pos + Vector2(1.0, 0.0))
	by.send_to_post(by.ground_pos)
	by.mind = Person.Mind.POST
	_run_both(s, fx, CorpseGuiseFx.SPAN - 1.0)
	t.check(not lead.held and lp.guised(), "a second before the guise ends, still passed by")
	Kit.arrive(by, lp.ground_pos + Vector2(1.0, 0.0))
	Kit.arrive(lp, lp.ground_pos)
	_run_both(s, fx, 1.0 + 2.0 * EscortDirector.TICK + DT)
	t.check(not lp.guised() and lead.held and d.seizures == 1, "when the guise ends he can be seized again (held %s, seizer %s)" % [lead.held, lead.seizer])
	_hunt_done(s)


## The Faithful do not see a guised person either: faithful_seeing() and watchers() asked about him find no one.
static func _faithful(t) -> void:
	var made := RD._setup()
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var seen: Person = crowd.citizens[40]
	var f: Person = crowd.citizens[41]
	seen.ground_pos = at
	f.ground_pos = at + Vector2(1.0, 0.0)
	var d := MissionDirector.new()
	d.faithful.assign([f])
	t.check(d.faithful_seeing(seen.ground_pos, 3.0, null, seen) == f and Array(d.watchers(seen.ground_pos, 3.0, null, seen)) == [f],
		"a Faithful a step away sees him")
	var fx := _cast(made[5], seen.ground_pos)
	t.check(seen.guised() and d.faithful_seeing(seen.ground_pos, 3.0, null, seen) == null and d.watchers(seen.ground_pos, 3.0, null, seen).is_empty(),
		"guised, no Faithful sees him")
	fx.end_now()
	RD._done(made)

## An effect freed without finishing (its layer torn down mid-night) still takes its guise off and lets go of its count.
static func _freed_fx(t) -> void:
	var made := RD._setup()
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var p: Person = crowd.citizens[42]
	p.ground_pos = at
	var fx := _cast(made[5], at)
	RD._run(fx, 3.0)
	t.check(p.guised() and CorpseGuiseFx._owner.has(p.get_instance_id()), "guised, and counted by the cast")
	fx.free()
	t.check(not p.guised() and not CorpseGuiseFx._owner.has(p.get_instance_id()), "the cast freed unfinished: the guise is off, the count let go")
	RD._done(made)


## Runs a mission world (crowd, then Rules) and an effect together.
static func _run_with(s: Dictionary, fx: FxTimeline, seconds: float) -> void:
	for i in roundi(seconds / DT):
		if fx != null and not fx.finished:
			fx._process(DT)
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)


## Mira's House: a guised mourner at the door goes in and comes out under a Faithful's eyes, and nobody reports him.
static func _mira(t) -> void:
	var s: Dictionary = Mira._setup()
	var d: MirasHouseDirector = s.d
	var ctx := _give_ctx(s)
	var g := d.grieving[0]
	Mira._blind(d, d.door)
	var f := d.faithful[0]
	f.ground_pos = d.door + Vector2(2.5, 0.0)
	Mira._bring(d, g)
	var fx := FxTimeline.cast(CorpseGuiseFx, ctx, d.door) as CorpseGuiseFx
	t.check(g.guised() and not f.guised(), "the mourner at the door guised, the Faithful 2.5 off not")
	_run_with(s, fx, DT * 2.0)
	t.check(g.inside and d.reports.is_empty() and d.reports_started == 0, "a guised mourner at Mira's door is not seen going in: no report")
	_run_with(s, fx, MirasHouseDirector.READ_SECONDS + 0.5)
	t.check(not g.inside and d.believers.has(g) and g.guised() and d.reports.is_empty() and d.reports_started == 0,
		"nor coming out, a Believer, under the same Faithful's eyes")
	_drop_ctx(s)
	Mira._done(s)


## The Lost Lamb (the Escort type's searchers): at 2:30 they are named, but nobody homes on a guised charge; once it is off they go.
static func _lamb_hunters(t) -> void:
	var s: Dictionary = Lamb._world()
	var d: LostLambDirector = s.d
	var ctx := _give_ctx(s)
	Lamb._clear_watchers(d)
	Lamb._run(s, LostLambDirector.HUNT_AT - 5.0)
	var fx := FxTimeline.cast(CorpseGuiseFx, ctx, d.charge.ground_pos) as CorpseGuiseFx
	_run_with(s, fx, 5.0 + DT * 2.0)
	var near := 0
	for h in d.hunters:
		near += 1 if h.goal().distance_to(d.charge.ground_pos) < 1.5 or h.anchor.distance_to(d.charge.ground_pos) < 1.5 else 0
	t.check(d.charge.guised() and d.hunters.size() == LostLambDirector.HUNTERS and near == 0,
		"the searchers are named, but nobody homes on a guised charge (%d of %d near him)" % [near, d.hunters.size()])
	_run_with(s, fx, CorpseGuiseFx.SPAN)
	var ok := not d.charge.guised() and d.hunters.size() == LostLambDirector.HUNTERS
	for h in d.hunters:
		ok = ok and h.mind == Person.Mind.DUTY and h.anchor.distance_to(d.charge.ground_pos) < 1.5
	t.check(ok, "once the guise is off they walk to him")
	_drop_ctx(s)
	Lamb._done(s)


## The Exodus: a household's searchers leave the Temple, but hold while its lamp is guised; once it is off they go to him.
static func _exodus_searchers(t) -> void:
	var s := Kit.world(MissionBook.exodus())
	var d: ExodusDirector = s.d
	var ctx := _give_ctx(s)
	for v: Variant in d._watchers():
		if MissionDirector._alive(v):
			Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(60.0, 60.0))
	d._come_out(0)
	Kit.run_for(s, EscortDirector.TICK + DT)
	var h: ExodusDirector.Household = d.households[0]
	Kit.run_for(s, ExodusDirector.HUNT_AFTER - 3.0)
	var fx := FxTimeline.cast(CorpseGuiseFx, ctx, (d.lamp(0).man as Person).ground_pos) as CorpseGuiseFx
	_run_with(s, fx, 3.0 + DT * 2.0)
	var lead := d.lamp(0).man as Person
	var near := 0
	for v: Variant in h.searchers:
		near += 1 if (v as Person).anchor.distance_to(lead.ground_pos) < 1.5 else 0
	t.check(h.sent and lead.guised() and near == 0, "sent out, the searchers do not home on a guised lamp (%d near)" % near)
	_run_with(s, fx, CorpseGuiseFx.SPAN)
	lead = d.lamp(0).man as Person
	var ok := h.sent and not lead.guised()
	for v: Variant in h.searchers:
		ok = ok and (v as Person).anchor.distance_to(lead.ground_pos) < 1.5
	t.check(ok, "once the guise is off they go to its lamp")
	_drop_ctx(s)
	Kit.done(s)


## Hide the Faithful (review focus 4): the search reaching the door of a household out and wholly guised waits there, and takes up its
## trail once the guise is off -- the household is not lost to the search for the night.
static func _trail_waits(t) -> void:
	var s := _hunt()
	var d: HideFaithfulDirector = s.d
	var ctx: FxContext = s.ctx
	var hh: ExodusDirector.Household = d.households[0]
	var k := -1
	for i in d._search.size():
		if int(d._search[i].household) == 0:
			k = i
	t.check(k >= 0 and hh.out, "household 0 is out, and its house is on the list")
	var fxs: Array[CorpseGuiseFx] = []
	for c: EscortDirector.Charge in hh.members:
		var p := c.man as Person
		if not d._resolved(c) and not p.inside and not p.guised():
			fxs.append(FxTimeline.cast(CorpseGuiseFx, ctx, p.ground_pos) as CorpseGuiseFx)
	var all := true
	for c: EscortDirector.Charge in hh.members:
		all = all and (d._resolved(c) or (c.man as Person).inside or (c.man as Person).guised())
	t.check(all and not d._trail_seen(0), "every believer of it out of doors is guised: no trail to see")
	d._search_at = k
	d._search_stop = -1.0
	d._trail = -1
	var door: Vector2 = d._search[k].door
	var by := d.inquisitors[0] as Person
	var searched := d.searched
	for i in roundi((2.0 * EscortDirector.TICK + DT) / DT):
		for fx in fxs:
			fx._process(DT)
		Kit.arrive(by, door)
		Kit.run_for(s, DT)
	t.check(d._trail == -1 and d._search_at == k and d.searched == searched and d._search_stop < 0.0,
		"the search at the door of a wholly guised household waits there: no trail, not passed by (at %d of %d, trail %d)" % [d._search_at, k, d._trail])
	for fx in fxs:
		fx.end_now()
	Kit.arrive(by, door)
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	var held := 0
	for c: EscortDirector.Charge in hh.members:
		held += 1 if c.held else 0
	var trailed := d._trail == 0 and d.searched == searched + 1 and (s.banners as Array).has("THE INQUISITION FINDS THE TRAIL")
	t.check(trailed or held > 0, "once the guise is off the search has them again: trailed or seized (trail %d, %d held)" % [d._trail, held])
	_hunt_done(s)
