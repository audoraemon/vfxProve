extends RefCounted
## Cloak of Night (Veil, Tier 2; spec 5.4): the 3 nearest within 2 (the 8 nearest within 4 in the dark) are hidden from the watch for
## 25 s. hidden_from_watch() answers for the witness check, the watch's sight and a soldier's choice of whom to fight; it is not a
## guise. The cloak counts down, a second cast takes over the count, and a cast ending, cut short or freed lifts only its own.

const RD := preload("res://tests/test_raise_dead.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const DT := 0.05


static func _cast(ctx: FxContext, at: Vector2, extra := {}) -> CloakOfNightFx:
	return FxTimeline.cast(CloakOfNightFx, ctx, at, extra) as CloakOfNightFx


static func _ring(crowd: Crowd, at: Vector2, n: int, first := 10) -> Array[Person]:
	var ps: Array[Person] = []
	for i in n:
		var p: Person = crowd.citizens[first + i]
		p.ground_pos = at + Vector2(0.2 + 0.2 * float(i), 0.1)
		ps.append(p)
	return ps


static func run(t) -> void:
	_book(t)
	var made := RD._setup()
	_marks(t, made)
	_dark(t, made)
	_sight(t, made)
	_not_a_guise(t, made)
	_countdown(t, made)
	_overlap(t, made)
	_teardown(t, made)
	_quiet(t, made)
	_busy(t, made)
	_indoors(t, made)
	_shimmer(t, made)
	RD._done(made)
	_watcher(t)
	_no_crowd(t)


static func _book(t) -> void:
	var p := PowerBook.get_power("cloak")
	t.check(not p.is_empty() and String(p.get("authority", "")) == "veil" and String(p.aim) == "click" and float(p.cooldown) == 45.0,
		"the row: Veil, a click, 45 s (%s)" % [p])
	t.check(CloakOfNightFx.SPAN == 25.0 and CloakOfNightFx.KEY == &"cloak", "25 s, the status key cloak")
	t.check(VeilRules.size("cloak", "MARK_R", false) == 2.0 and VeilRules.size("cloak", "MARK_R", true) == 4.0
		and VeilRules.size("cloak", "MOST", false) == 3.0 and VeilRules.size("cloak", "MOST", true) == 8.0, "3 within 2 in the light, 8 within 4 in the dark")


## Light: the 3 nearest within 2.0 carry the status; a fourth inside 2.0 does not.
static func _marks(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var ps := _ring(crowd, at, 5)
	ps[4].ground_pos = at + Vector2(3.0, 0.0)  # past 2
	var picked := CloakOfNightFx.marked_at(made[3], at)
	t.check(Array(picked) == [ps[0], ps[1], ps[2]], "marked_at: the 3 nearest within 2, nearest first (%d)" % picked.size())
	var fx := _cast(made[5], at)
	var ok := true
	for i in 3:
		ok = ok and ps[i].statuses.has(&"cloak") and is_equal_approx(float(ps[i].statuses[&"cloak"]), CloakOfNightFx.SPAN)
	t.check(ok, "light: the 3 nearest carry 25 s of cloak")
	t.check(not ps[3].statuses.has(&"cloak") and ps[3].ground_pos.distance_to(at) < 2.0, "a fourth inside 2.0 does not")
	t.check(not ps[4].statuses.has(&"cloak"), "one past 2.0 does not")
	fx.end_now()
	t.check(not ps[0].statuses.has(&"cloak"), "cut short, the cloak is off")


## Dark (extra["dark"]): the 8 nearest within 4.
static func _dark(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var ps := _ring(crowd, at, 10)
	for i in 10:
		ps[i].ground_pos = at + Vector2(0.3 * float(i + 1), 0.0)
	ps[9].ground_pos = at + Vector2(3.8, 0.0)
	ps[8].ground_pos = at + Vector2(4.5, 0.0)  # past 4
	var fx := _cast(made[5], at, {"dark": true})
	var n := 0
	for p in ps:
		if p.statuses.has(&"cloak"):
			n += 1
	t.check(n == 8 and ps[0].statuses.has(&"cloak") and not ps[8].statuses.has(&"cloak"), "dark: 8 within 4.0 (%d)" % n)
	fx.end_now()


## While cloaked: hidden_from_watch(), no witness, a soldier's fight pick skips them; the control is seen.
static func _sight(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var p: Person = crowd.citizens[31]
	var s: Person = crowd.soldiers[1]
	p.ground_pos = at
	s.ground_pos = at + Vector2(0.8, 0.0)
	t.check(crowd.nearest_witness(at) == p, "control: the one beside a death is its witness")
	p.fight(null, 10.0, 0.1)
	s.fight(null, 10.0, Person.SOLDIER_BLOW, Person.FightRule.HOSTILES)
	t.check(s._fightable(p), "control: a soldier would go for the fighting citizen")
	var fx := _cast(made[5], at)
	t.check(p.hidden_from_watch(), "cloaked: hidden from the watch")
	t.check(not s._fightable(p), "a soldier's fight pick skips the cloaked")
	s._fight_step(0.6)
	t.check(s.fight_target != p, "and does not choose him")
	t.check(crowd.nearest_witness(at) != p, "the cloaked is no witness")
	fx.end_now()
	t.check(not p.hidden_from_watch() and s._fightable(p) and crowd.nearest_witness(at) == p,
		"the cloak ended: fought and witnessing again (positive control)")
	p.stop_fighting()
	s.stop_fighting()


## Not a guise: guised() is false and Death's undead (spare_guise) do not spare the cloaked.
static func _not_a_guise(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var cloaked: Person = crowd.citizens[3]
	var other: Person = crowd.citizens[4]
	cloaked.ground_pos = at + Vector2(0.5, 0.0)
	other.ground_pos = at + Vector2(4.0, 0.0)
	var fx := _cast(made[5], cloaked.ground_pos)
	t.check(cloaked.hidden_from_watch() and not cloaked.guised() and not cloaked.statuses.has(&"guise"), "hidden but not guised")
	var body := RD._body(made, 5, at, &"mob")
	var v := Visitors.new().setup(made[3], crowd, made[2], made[4])
	var z := DeathParts.zombie(v, body, false)
	for i in roundi(0.6 / DT):
		v.step(DT)
	t.check(z.target == cloaked, "a zombie with spare_guise does not spare the cloaked (target %s)" % [z.target])
	v.clear()
	fx.end_now()


static func _countdown(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var p: Person = crowd.citizens[32]
	p.ground_pos = at
	var fx := _cast(made[5], at)
	RD._run(fx, CloakOfNightFx.SPAN - 1.0)
	t.check(p.hidden_from_watch() and absf(float(p.statuses[&"cloak"]) - 1.0) < 0.11, "a second before the end, a second left (%.2f)" % float(p.statuses.get(&"cloak", -1.0)))
	RD._run(fx, 1.5)
	t.check(not p.hidden_from_watch() and not p.statuses.has(&"cloak") and fx.finished, "at 25 s the cloak is gone, and the effect with it")


## A second cast gives the full 25 s again and takes over the count; the first ending leaves the second's.
static func _overlap(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var p: Person = crowd.citizens[33]
	p.ground_pos = at
	var a := _cast(made[5], at)
	RD._run(a, 10.0)
	var b := _cast(made[5], at)
	t.check(is_equal_approx(float(p.statuses[&"cloak"]), 25.0), "a second cast gives the full 25 s again")
	for i in roundi(16.0 / DT):
		if not a.finished:
			a._process(DT)
		b._process(DT)
	t.check(a.finished and p.hidden_from_watch() and absf(float(p.statuses[&"cloak"]) - 9.0) < 0.11,
		"recast at 10 s: the first ends at 25 s and leaves the second's 9 s (%.2f)" % float(p.statuses.get(&"cloak", -1.0)))
	RD._run(b, 9.5)
	t.check(not p.hidden_from_watch(), "then it ends")


## end_now() and a freed node lift every status this cast laid, and not one a second cast laid.
static func _teardown(t, made: Array) -> void:
	for mode in ["end_now", "free"]:
		RD._clear_all(made)
		var crowd: Crowd = made[0]
		var at := RD._empty(made)
		var ps := _ring(crowd, at, 3)
		var a := _cast(made[5], at)
		RD._run(a, 1.0)
		# A second cast, aimed so that only the middle one is within its light circle... it takes the nearest 3, so shrink
		# the field: the other two go far off, then come back after it has taken over the middle one.
		var far0 := ps[0].ground_pos
		var far2 := ps[2].ground_pos
		ps[0].ground_pos = at + Vector2(40.0, 0.0)
		ps[2].ground_pos = at + Vector2(41.0, 0.0)
		var b := _cast(made[5], ps[1].ground_pos)
		ps[0].ground_pos = far0
		ps[2].ground_pos = far2
		t.check(int(ps[1].get_meta(&"cloak_owner", 0)) == b.get_instance_id(), "%s: the second cast owns the person it re-laid" % mode)
		t.check(int(ps[0].get_meta(&"cloak_owner", 0)) == a.get_instance_id(), "%s: the first still owns the others" % mode)
		if mode == "end_now":
			a.end_now()
		else:
			a.free()
		t.check(not ps[0].statuses.has(&"cloak") and not ps[2].statuses.has(&"cloak"), "%s: every cloak the first laid is lifted" % mode)
		t.check(ps[1].statuses.has(&"cloak") and ps[1].hidden_from_watch(), "%s: and not the one the second laid" % mode)
		b.end_now()
		t.check(not ps[1].statuses.has(&"cloak") and not ps[1].has_meta(&"cloak_owner"), "%s: the second lifts its own (positive control)" % mode)
	# A person who loses the status to someone else's hand is not relaid by the count.
	RD._clear_all(made)
	var at2 := RD._empty(made)
	var q := _ring(made[0], at2, 1)[0]
	var f := _cast(made[5], at2)
	q.statuses.erase(&"cloak")
	RD._run(f, 1.0)
	t.check(not f.finished and not q.statuses.has(&"cloak"), "a cloak taken off by another reader is not relaid by the count")
	f.end_now()


## Silent: no alarm, no fright, nobody turns; the code never calls them.
static func _quiet(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var near := _ring(crowd, at, 3, 20)
	var alarm := crowd.alarm
	var held := crowd.held_count()
	var fx := _cast(made[5], at)
	RD._run(fx, 2.0, near)
	var calm := near.all(func(p: Person) -> bool: return p.mind == Person.Mind.CALM)
	t.check(crowd.alarm == alarm and crowd.held_count() == held and calm, "no alarm, no fright, everyone stays calm")
	var src := FileAccess.get_file_as_string("res://src/fx/veil/cloak_of_night.gd")
	t.check(src != "" and not src.contains("add_alarm") and not src.contains("fright(") and not src.contains("panic(") and not src.contains("on_cast")
		and not src.contains("randf") and not src.contains("ctx.rng"), "the code never alarms, frightens, panics or rolls")
	fx.end_now()


## One shimmer per cloaked person, drawn only; it goes when the cloak does; the person's own look is untouched.
static func _shimmer(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var ps := _ring(crowd, at, 3, 40)
	var plain: Variant = ps[0]._art_signature()
	var fx := _cast(made[5], at)
	t.check(fx.shimmers.size() == 3 and fx.shimmers.all(func(m: Node2D) -> bool: return is_instance_valid(m)), "a shimmer for each of the 3")
	t.check(ps[0]._art_signature() == plain and ps[0]._sprite_pose()[0] != &"lurch", "they walk normally: no grey, no lurch")
	var m0: Node2D = fx.shimmers[0]
	m0._process(0.1)
	t.check(m0.visible and not m0.is_queued_for_deletion(), "the shimmer shows while kept")
	ps[0].statuses.erase(&"cloak")
	m0._process(0.1)
	t.check(m0.is_queued_for_deletion(), "it frees itself when the cloak lifts")
	fx.end_now()


## The watch's sight: a patrol soldier beside a cloaked believer in the Hunt does not see him; the uncloaked control does.
static func _watcher(t) -> void:
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
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	var lead := d.lamp(0)
	var lp := lead.man as Person
	var soldier := d.patrols[0][0] as Person
	Kit.arrive(soldier, lp.ground_pos + Vector2(1.0, 0.0))
	soldier.send_to_post(soldier.ground_pos)
	t.check(d._seen_by(lead) != null, "control: uncloaked, the believer is seen")
	var fx := _cast(ctx, lp.ground_pos)
	t.check(lp.hidden_from_watch() and d._seen_by(lead) == null, "EscortDirector._seen_by() does not see the cloaked")
	fx.end_now()
	t.check(d._seen_by(lead) != null, "and sees him again once it ends")
	ctx.overhead.free()
	ctx.ground.free()
	Kit.done(s)


## No crowd, no rules (the VFX Sandbox): the cast builds and finishes at the light size.
static func _no_crowd(t) -> void:
	var ctx := FxContext.new()
	ctx.rng = RandomNumberGenerator.new()
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	ctx.world = Node2D.new()
	var fx := _cast(ctx, Vector2.ZERO)
	t.check(fx != null and fx.shimmers.is_empty() and fx.duration == 1.0, "no crowd: builds, marks nobody")
	for i in 40:
		if not fx.finished:
			fx._process(DT)
	t.check(fx.finished, "and finishes without an error")
	ctx.overhead.free()
	ctx.ground.free()
	ctx.world.free()


## C16: through Rules, the cloak locks the other slots only until it lands (T_LAND); it runs on for 25 s after.
static func _busy(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var ps := _ring(crowd, at, 2)
	var rules := Rules.new().setup(PackedStringArray(["cloak", "slumber"]), null, made[1], made[3], crowd, made[6])
	rules.caster = func(s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		return FxTimeline.cast(s, made[5], g, e)
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, why: String) -> void: refused.append([slot, why]))
	var fx := rules.cast(0, at) as CloakOfNightFx
	t.check(fx != null and fx.busy == CloakOfNightFx.T_LAND and fx.duration == CloakOfNightFx.SPAN, "cast through Rules; busy is its landing time")
	t.check(rules.cast(1, at + Vector2(6.0, 0.0)) == null and refused == [[1, "busy"]], "before it lands another power is refused busy (%s)" % [refused])
	refused.clear()
	RD._run(fx, CloakOfNightFx.T_LAND + 0.1)
	t.check(rules.busy_left() == 0.0 and not fx.finished and ps[0].hidden_from_watch(), "landed: the rules are free, the cloak still runs and holds")
	var other := rules.cast(1, at + Vector2(6.0, 0.0))
	t.check(other != null and refused.is_empty() and not fx.finished and ps[0].hidden_from_watch() and ps[1].hidden_from_watch(),
		"after landing another power can be cast while the cloak still runs and its people are still cloaked (%s)" % [refused])
	if other != null:
		other.end_now()
	fx.end_now()
	rules.free()


## VC5: the indoors are not cloaked (marked_at skips them, as Corpse Guise's does: the cloak hides people from the watch's eyes
## out of doors; indoors nobody watches), though they stand nearest.
static func _indoors(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var ps := _ring(crowd, at, 2, 60)
	ps[0].inside = true
	var picked := CloakOfNightFx.marked_at(made[3], at)
	t.check(not picked.has(ps[0]) and picked.has(ps[1]), "one indoors is not marked; the one out of doors beside him is")
	ps[0].inside = false
	t.check(CloakOfNightFx.marked_at(made[3], at).has(ps[0]), "out of doors he is (positive control)")
