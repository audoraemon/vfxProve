extends RefCounted
## Corpse Guise (Death, Tier III, quiet; spec 5.3): up to 4 people within 2 of the click pass as the walking dead for 25 s.
## The watch looks straight past them (soldiers, watchmen, inquisitors: no seizure, no witness, no report, no fight), and
## Death's own undead leave them alone. The cast raises no alarm and frightens nobody. statuses[&"guise"] holds the seconds
## left; the effect counts it down and takes it off at zero, so a believer whose guise ends is seen and seized as before.

const RD := preload("res://tests/test_raise_dead.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
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
	RD._done(made)
	_watcher(t)
	_inquisitor(t)
	_seized_after(t)
	_faithful(t)


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
	return s


static func _hunt_done(s: Dictionary) -> void:
	var ctx: FxContext = s.ctx
	for c in ctx.overhead.get_children():
		(c as FxTimeline).end_now()
	ctx.overhead.free()
	ctx.ground.free()
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
