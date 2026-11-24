extends RefCounted
## Mission clarity, the hunt group (spec 5.5, plan Task 6): The Heretic Hunt, The Lantern's Eye and Break the Hunt. Every verb a step or a hint
## names is proved in a Kit world through the game's own entry points (ClarityKit.apply(), and for the verbs the hints promise through a
## real Rules.cast() with the power's own effect); each why-not banner is asked in a world where it is true and in one where the cast reaches
## nothing; the readers only read; every colour named is a tag drawn.

const ClarityKit := preload("res://tests/clarity_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")

static var IDS := PackedStringArray(["heretic_hunt", "lantern_eye", "break_hunt"])
## A look of the hunt's people (Hunt TICK) and a little more.
const LOOK := 0.6

## What was proved, "id/phase/verb" -> true: every row of cases() must be in it, so a row never stands for nothing.
static var _proved := {}
## The effect contexts a real cast made (freed at the end of the run).
static var _ctxs: Array = []


## The cases the copy needs: every verb a step or hint names, per mission and phase (the `phase` is the hint's phase, "" the mission's own;
## the mission's own line talks of the whole night, so its verbs are proved where the thing they act on stands).
static func cases() -> Array:
	var rows := [
		["heretic_hunt", "", ["kill", "lead", "strike", "rot"]],
		["heretic_hunt", "guarded", ["kill", "lead", "confuse"]],
		["heretic_hunt", "open", ["strike", "rot"]],
		["heretic_hunt", "waiting", ["kill", "lead", "confuse"]],
		["heretic_hunt", "captain", ["kill"]],
		["heretic_hunt", "searching", ["kill"]],
		["lantern_eye", "", ["kill", "lead", "strike", "rot"]],
		["lantern_eye", "guarded", ["kill", "lead", "confuse"]],
		["lantern_eye", "open", ["strike", "rot"]],
		["lantern_eye", "shattered", ["kill", "lead", "confuse"]],
		["lantern_eye", "waiting", ["kill", "lead"]],
		["lantern_eye", "eye", ["strike", "rot"]],
		["break_hunt", "", ["kill", "scare", "hold"]],
		["break_hunt", "carried", ["kill", "scare"]],
		["break_hunt", "taken", ["kill", "scare"]],
	]
	var out := []
	for r: Array in rows:
		for v: String in r[2]:
			out.append({"id": r[0], "phase": r[1], "verb": v})
	return out


static func run(t) -> void:
	_proved.clear()
	_heretic_counts(t)
	_eye_counts(t)
	_break_counts(t)
	_real_casts(t)
	_why_heretic(t)
	_why_eye(t)
	_why_break(t)
	_read_only(t)
	_colours(t)
	_copy(t)
	var missing := PackedStringArray()
	for c: Dictionary in cases():
		if not _proved.has("%s/%s/%s" % [c.id, c.phase, c.verb]):
			missing.append("%s/%s/%s" % [c.id, c.phase, c.verb])
	t.check(missing.is_empty(), "every case row was run (%d; missing %s)" % [cases().size(), ", ".join(missing)])
	ClarityKit.check_coverage(t, IDS, cases())
	for ctx: FxContext in _ctxs:
		ctx.overhead.free()
		ctx.ground.free()
	_ctxs.clear()


## One proof: records the case and checks it.
static func _say(t, id: String, phase: String, verb: String, ok: bool, what: String) -> void:
	_proved["%s/%s/%s" % [id, phase, verb]] = true
	t.check(ok, "%s %s %s: %s" % [id, phase if phase != "" else "(own)", verb, what])


# ---- worlds ----


static func _hh(raised := 0) -> Dictionary:
	var s := ClarityKit.world(MissionBook.heretic_hunt())
	for i in raised:
		(s.d as HereticHuntDirector)._raise(i)
	return s


## Step `i`'s guards moved well off their ring: off guard, still alive.
static func _hh_clear(d: HuntDirector, i: int) -> void:
	for g: HuntDirector.Guard in d.steps[i].party:
		if MissionDirector._alive(g.man):
			Kit.arrive(g.man as Person, g.post + Vector2(5.0, 5.0))


## Standard `i` raised, cleared and broken by a Smite (test_heretic_hunt's own way).
static func _hh_break(s: Dictionary, i: int) -> void:
	var d: HereticHuntDirector = s.d
	d._raise(i)
	_hh_clear(d, i)
	(s.env as EnvironmentField).damage_radius(d.standard(i).center(), SmiteFx.HIT_R, SmiteFx.DAMAGE, &"smite")


static func _eye(raised := 0) -> Dictionary:
	var s := ClarityKit.world(MissionBook.lantern_eye())
	for i in raised:
		(s.d as LanternEyeDirector)._raise(i)
	return s


## Tower `i`'s guards moved well off it (test_lantern_eye's own way).
static func _eye_clear(d: LanternEyeDirector, i: int) -> void:
	for g: HuntDirector.Guard in d.steps[i].party:
		if MissionDirector._alive(g.man):
			Kit.arrive(g.man as Person, g.post + (g.post - d.towers[i].center()).normalized() * 6.0)


## Mirror 0 raised, unguarded and shattered by two blows, its wrights out at their posts.
static func _eye_shattered() -> Dictionary:
	var s := _eye(1)
	var d: LanternEyeDirector = s.d
	_eye_clear(d, 0)
	ClarityKit.apply(s, "strike", d.outer_face(0))
	ClarityKit.apply(s, "strike", d.outer_face(0))
	for w: HuntDirector.Guard in d.wrights[0]:
		Kit.arrive(w.man as Person, w.post)
	return s


static func _bh(i := 0) -> Dictionary:
	var s := ClarityKit.world(MissionBook.break_hunt())
	(s.d as BreakHuntDirector)._raise(i)
	Kit.run_for(s, LOOK)
	return s


## Step `i`'s escorts as people.
static func _escorts(d: BreakHuntDirector, i: int) -> Array[Person]:
	var out: Array[Person] = []
	for g: HuntDirector.Guard in d.steps[i].party:
		if MissionDirector._alive(g.man):
			out.append(g.man as Person)
	return out


## Every escort of step `i` held (an oath), so none guards the bearer.
static func _bh_hold(s: Dictionary, i: int) -> void:
	for e in _escorts(s.d, i):
		ClarityKit.apply(s, "hold", e)


# ---- the counts ----


## A guard of step `i` goes off guard by `verb`: the party on guard shrinks.
static func _guard_goes(t, id: String, phase: String, verb: String, s: Dictionary, i: int) -> void:
	var d: HuntDirector = s.d
	var men := d.party_on(i)
	var n := men.size()
	var man: Person = men[0]
	if verb == "lead":
		s["to"] = man.ground_pos + Vector2(4.0, 0.0)
	ClarityKit.apply(s, verb, man)
	Kit.run_for(s, LOOK)
	_say(t, id, phase, verb, n >= 2 and d.party_on(i).size() < n, "a guard goes off guard (%d -> %d on guard)" % [n, d.party_on(i).size()])


static func _heretic_counts(t) -> void:
	# The guards: killed, led, confused (the party on guard shrinks); in the mission's own phase, once guarded, and while waiting.
	for verb: String in ["kill", "lead", "confuse"]:
		var s := _hh(1)
		t.check((s.d as HuntDirector).hint_phase() == "guarded", "heretic_hunt: a raised standard with its party is the guarded phase")
		_guard_goes(t, "heretic_hunt", "guarded", verb, s, 0)
		ClarityKit.done(s)
	for verb: String in ["kill", "lead"]:
		var s := _hh(1)
		_guard_goes(t, "heretic_hunt", "", verb, s, 0)
		ClarityKit.done(s)
	for verb: String in ["kill", "lead", "confuse"]:
		var s := _hh()
		_hh_break(s, 0)
		t.check((s.d as HuntDirector).hint_phase() == "waiting", "heretic_hunt: one broken and the next to come is the waiting phase")
		_guard_goes(t, "heretic_hunt", "waiting", verb, s, 1)
		ClarityKit.done(s)
	# The standard, its guards gone: a blow or the rot breaks it (own phase, and open).
	for phase: String in ["", "open"]:
		for verb: String in ["strike", "rot"]:
			var s := _hh(1)
			var d: HereticHuntDirector = s.d
			_hh_clear(d, 0)
			t.check(d.hint_phase() == "open", "heretic_hunt: its guards off it, the open phase")
			ClarityKit.apply(s, verb, d.standard(0))
			_say(t, "heretic_hunt", phase, verb, d.broken(0), "the unguarded standard breaks")
			ClarityKit.done(s)
	# The captain: killed, he is down (out and walking; then searching the houses).
	for phase: String in ["captain", "searching"]:
		var s := _hh()
		var d: HereticHuntDirector = s.d
		for i in 3:
			_hh_break(s, i)
		d._call_head()
		Kit.run_for(s, 0.2)
		if phase == "searching":
			Kit.arrive(d.head as Person, d.head_route[0])
			Kit.run_for(s, HereticHuntDirector.CAPTAIN_STOP + 0.3)
		t.check(d.hint_phase() == phase, "heretic_hunt: the captain out is the %s phase (%s)" % [phase, d.hint_phase()])
		ClarityKit.apply(s, "kill", d.head)
		_say(t, "heretic_hunt", phase, "kill", d.head_down(), "the captain is down")
		ClarityKit.done(s)
	# A lure on a guard (the plan's "lure far" row): a guard on duty refuses it, so no text names Lure for the hunt.
	var s := _hh(1)
	var d: HuntDirector = s.d
	var man: Person = d.party_on(0)[0]
	s["light"] = man.ground_pos + Vector2(6.0, 0.0)
	ClarityKit.apply(s, "lure", man)
	t.check(not bool(s.took) and d.party_on(0).has(man),
		"a lure on a guard on duty is refused: the hunt's copy never names Lure (Ruling: duty minds answer no light)")
	ClarityKit.done(s)


static func _eye_counts(t) -> void:
	for verb: String in ["kill", "lead", "confuse"]:
		var s := _eye(1)
		t.check((s.d as HuntDirector).hint_phase() == "guarded", "lantern_eye: a raised mirror with its party is the guarded phase")
		_guard_goes(t, "lantern_eye", "guarded", verb, s, 0)
		ClarityKit.done(s)
	for verb: String in ["kill", "lead"]:
		var s := _eye(1)
		_guard_goes(t, "lantern_eye", "", verb, s, 0)
		ClarityKit.done(s)
	for verb: String in ["kill", "lead"]:
		var s := _eye(1)
		var d: LanternEyeDirector = s.d
		d._gone(0)
		t.check(d.hint_phase() == "waiting", "lantern_eye: one gone and the next to come is the waiting phase (%s)" % d.hint_phase())
		_guard_goes(t, "lantern_eye", "waiting", verb, s, 1)
		ClarityKit.done(s)
	# The mirror, unguarded: two blows or one rot shatter it (own phase, and open).
	for phase: String in ["", "open"]:
		for verb: String in ["strike", "rot"]:
			var s := _eye(1)
			var d: LanternEyeDirector = s.d
			_eye_clear(d, 0)
			t.check(d.hint_phase() == "open", "lantern_eye: its guards off it, the open phase")
			if verb == "strike":
				ClarityKit.apply(s, "strike", d.outer_face(0))
				var once := not d.shattered[0]
				ClarityKit.apply(s, "strike", d.outer_face(0))
				_say(t, "lantern_eye", phase, verb, once and d.shattered[0], "one blow cracks it, the second shatters it")
			else:
				ClarityKit.apply(s, "rot", d.towers[0])
				_say(t, "lantern_eye", phase, verb, d.shattered[0], "one rot shatters it")
			ClarityKit.done(s)
	# The wrights of a shattered mirror: killed, led or confused, one stops working.
	for verb: String in ["kill", "lead", "confuse"]:
		var s := _eye_shattered()
		var d: LanternEyeDirector = s.d
		var w: HuntDirector.Guard = d.wrights[0][0]
		var both := d._working(w) and d._working(d.wrights[0][1])
		t.check(d.hint_phase() == "shattered" and both, "lantern_eye: a shattered mirror's two wrights are at work (%s)" % d.hint_phase())
		if verb == "lead":
			s["to"] = (w.man as Person).ground_pos + Vector2(4.0, 0.0)
		ClarityKit.apply(s, verb, w.man)
		Kit.run_for(s, 0.1)
		_say(t, "lantern_eye", "shattered", verb, not d._working(w), "the wright stops working")
		ClarityKit.done(s)
	# The Eye: all three stand together, a blow or a rot shatters one.
	for verb: String in ["strike", "rot"]:
		var s := _eye(3)
		var d: LanternEyeDirector = s.d
		for i in 3:
			_eye_clear(d, i)
		Kit.run_for(s, 0.2)
		t.check(d.hint_phase() == "eye", "lantern_eye: three whole mirrors open the Eye (%s)" % d.hint_phase())
		if verb == "strike":
			ClarityKit.apply(s, "strike", d.outer_face(0))
			ClarityKit.apply(s, "strike", d.outer_face(0))
		else:
			ClarityKit.apply(s, "rot", d.towers[0])
		_say(t, "lantern_eye", "eye", verb, d.shattered[0], "a mirror is shattered while the Eye counts down")
		ClarityKit.done(s)


## Bearer `i` of a Break the Hunt world with no escort by him: his escorts held (an oath); then `verb` breaks the standard.
static func _bh_breaks(t, phase: String, verb: String, s: Dictionary, i: int) -> void:
	var d: BreakHuntDirector = s.d
	var b := d.bearer(i)
	b.fearless_left = 600.0  # (the held escorts' own panic is not what these cases prove)
	_bh_hold(s, i)
	if phase == "" and verb == "hold":
		_say(t, "break_hunt", phase, verb, not d._guarded(i) and not d.steps[i].broken and d.bearer(i) != null,
			"his escorts held, nobody guards the bearer, and the standard still stands")
		return
	b.fearless_left = 0.0 if verb == "scare" else 600.0
	t.check(not d._guarded(i), "break_hunt %s: (set-up) no escort guards him" % phase)
	ClarityKit.apply(s, verb, b)
	Kit.run_for(s, LOOK * 2.0)
	_say(t, "break_hunt", phase, verb, d.steps[i].broken, "the lone bearer's standard breaks")


static func _break_counts(t) -> void:
	# The mission's own phase: hold the escorts, then kill or scare the bearer.
	for verb: String in ["hold", "kill", "scare"]:
		var s := _bh(0)
		t.check((s.d as BreakHuntDirector).hint_phase() == "" and (s.d as BreakHuntDirector).guarded(0), "break_hunt: a raised standard is guarded by its escorts")
		_bh_breaks(t, "", verb, s, 0)
		ClarityKit.done(s)
	# Carried: the bearer killed with his escorts by him, one takes it up; the other dead, the new bearer killed or scared.
	for verb: String in ["kill", "scare"]:
		var s := _bh(0)
		var d: BreakHuntDirector = s.d
		ClarityKit.apply(s, "kill", d.bearer(0))
		Kit.run_for(s, LOOK * 2.0)
		t.check(d.hint_phase() == "carried" and not d.steps[0].broken, "break_hunt: an escort took the standard up: the carried phase (%s)" % d.hint_phase())
		for e in _escorts(d, 0):
			ClarityKit.apply(s, "kill", e)
		if verb == "scare":
			Kit.run_for(s, BreakHuntDirector.BH_STEADY + 1.5)  # the new bearer is steady for a few seconds: a fright waits for them
		else:
			d.bearer(0).fearless_left = 600.0
		t.check(d.hint_phase() == "carried" and not d._guarded(0), "break_hunt: the new bearer has no escort by him (%s)" % d.hint_phase())
		ClarityKit.apply(s, verb, d.bearer(0))
		Kit.run_for(s, LOOK * 2.0)
		_say(t, "break_hunt", "carried", verb, d.steps[0].broken, "the lone new bearer's standard breaks")
		ClarityKit.done(s)
	# Taken: a house is taken (the mission's own flag), the next bearer killed or scared.
	for verb: String in ["kill", "scare"]:
		var s := ClarityKit.world(MissionBook.break_hunt())
		var d: BreakHuntDirector = s.d
		d._taken[0] = true
		d._raise(1)
		Kit.run_for(s, LOOK)
		t.check(d.hint_phase() == "taken", "break_hunt: a taken house is the taken phase (%s)" % d.hint_phase())
		_bh_breaks(t, "taken", verb, s, 1)
		ClarityKit.done(s)


# ---- the real casts (pre-flight B2, ruling R2): the power's own effect through Rules.cast ----


## Casts `key` at `at` through Rules.cast() with the power's own effect (an FxContext of the world's own pieces).
static func _cast_real(s: Dictionary, key: String, at: Vector2, extra := {}) -> void:
	var rules: Rules = s.rules
	var ctx := FxContext.new()
	ctx.env = s.env
	ctx.field = s.field
	ctx.crowd = s.crowd
	ctx.rules = rules
	ctx.world = s.world
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 7
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	_ctxs.append(ctx)
	var slot := rules.loadout.find(key)
	if slot < 0:
		var l := rules.loadout
		l.append(key)
		rules.loadout = l
		var c := rules._cooldowns
		c.append(0.0)
		rules._cooldowns = c
		slot = l.size() - 1
	rules._cooldowns[slot] = 0.0
	rules._playing = null
	rules.caster = func(script: GDScript, ground: Vector2, e: Dictionary) -> FxTimeline: return FxTimeline.cast(script, ctx, ground, e)
	rules.cast(slot, at, extra)


static func _real_casts(t) -> void:
	# Discord (confuse) on a Heretic Hunt guard: every guard within its circle is confused, and the party on guard shrinks.
	var s := _hh(1)
	var d: HuntDirector = s.d
	var n := d.party_on(0).size()
	var man: Person = d.party_on(0)[0]
	_cast_real(s, "discord", man.ground_pos)
	t.check(man.mind == Person.Mind.CONFUSED and d.party_on(0).size() < n,
		"the real Discord confuses a guard on the hunt's standard and takes him off guard (%d -> %d)" % [n, d.party_on(0).size()])
	ClarityKit.done(s)
	# Mind Whisper (lead) on a guard: he walks off, no longer guarding.
	s = _hh(1)
	d = s.d
	n = d.party_on(0).size()
	man = d.party_on(0)[0]
	_cast_real(s, "whisper", man.ground_pos, {"to": man.ground_pos + Vector2(4.0, 0.0), "target": man})
	t.check(man.mind == Person.Mind.WHISPERED and d.party_on(0).size() < n,
		"the real Mind Whisper leads a guard of the hunt off (%d -> %d)" % [n, d.party_on(0).size()])
	ClarityKit.done(s)
	# Oathbound (hold) on the escorts of a bearer: held, none of them guards him.
	s = _bh(0)
	var bh: BreakHuntDirector = s.d
	var es := _escorts(bh, 0)
	t.check(bh.guarded(0), "(set-up) the bearer is guarded")
	_cast_real(s, "oath", es[0].ground_pos)
	var held := 0
	for e in es:
		held += 1 if e.mind == Person.Mind.COMPELLED else 0
	t.check(held >= 1 and (held == es.size()) == (not bh._guarded(0)),
		"the real Oathbound holds the escorts it reaches (%d of %d), and a bearer with none left free is unguarded" % [held, es.size()])
	ClarityKit.done(s)


# ---- the why-nots ----


## `far`: a point the cast of `key` reaches none of `from` from.
static func _far(key: String, from: Vector2) -> Vector2:
	return from + Vector2(Crowd._cast_radius(key) + MissionDirector.WHY_MARGIN + 2.0, 0.0)


static func _why_heretic(t) -> void:
	var s := _hh(1)
	var d: HereticHuntDirector = s.d
	var std := d.standard(0)
	var c := std.center()
	t.check(d.why_not("smite", c) == HuntDirector.WHY_STRIKE, "a blow on the guarded standard: %s (%s)" % [HuntDirector.WHY_STRIKE, d.why_not("smite", c)])
	t.check(d.why_not("smite", _far("smite", c)) == "", "the same blow far from it says nothing")
	ClarityKit.apply(s, "strike", std)
	t.check(is_equal_approx(std.hp, std.max_hp) and not std.destroyed and d.why_not("smite", s.at) == HuntDirector.WHY_STRIKE,
		"the real blow only shakes the standard, and says why")
	var man: Person = d.party_on(0)[0]
	t.check(d.why_not("smite", man.ground_pos) == "", "a blow that kills a guard counts, so no banner")
	t.check(d.why_not("blight", c) == "" and d.blight_words(c) == "THEIR GUARD KEEPS IT", "Rot keeps its own banner, so none is added")
	t.check(d.why_not("ember", c) == "" and d.why_not("whisper", man.ground_pos) == "" and d.why_not("discord", man.ground_pos) == "",
		"a fire, a Lead and a Confuse near the guards say nothing")
	t.check(MissionBook.heretic_hunt().make_director().why_not("smite", c) == "", "a director that is not set up has nothing to say")
	# A hold that took a guard: he still guards.
	ClarityKit.apply(s, "hold", man)
	t.check(man.held_by_god() and d.party_on(0).has(man) and d.why_not("oath", s.at) == HuntDirector.WHY_HELD,
		"a held guard still guards: %s (%s)" % [HuntDirector.WHY_HELD, d.why_not("oath", s.at)])
	t.check(d.why_not("oath", _far("oath", man.ground_pos)) == "", "the same hold far from him says nothing")
	t.check(d.why_not("belllies", s.at) == "" and d.why_not("whisper", s.at) == "" and d.why_not("doom", s.at) == "",
		"The Bell Lies in its calm mode, a Lead and a kill do not get it")
	ClarityKit.done(s)
	# Open: nothing to say about a blow.
	s = _hh(1)
	d = s.d
	_hh_clear(d, 0)
	t.check(d.why_not("smite", d.standard(0).center()) == "", "an unguarded standard takes the blow: no banner")
	ClarityKit.done(s)


static func _why_eye(t) -> void:
	var s := _eye(1)
	var d: LanternEyeDirector = s.d
	var c := d.towers[0].center()
	t.check(d.why_not("smite", c) == HuntDirector.WHY_STRIKE, "a blow on the guarded mirror's tower: %s (%s)" % [HuntDirector.WHY_STRIKE, d.why_not("smite", c)])
	t.check(d.why_not("smite", _far("smite", c + Vector2(d.towers[0].footprint.size.x, 0.0))) == "", "the same blow far from it says nothing")
	var man: Person = d.party_on(0)[0]
	ClarityKit.apply(s, "hold", man)
	t.check(d.why_not("oath", s.at) == HuntDirector.WHY_HELD, "a held guard of the mirror still guards (%s)" % d.why_not("oath", s.at))
	ClarityKit.done(s)
	# The wrights: held, one still works.
	s = _eye_shattered()
	d = s.d
	var w: HuntDirector.Guard = d.wrights[0][0]
	var p := w.man as Person
	t.check(d.why_not("oath", p.ground_pos) == "", "a hold with no wright held says nothing")
	ClarityKit.apply(s, "hold", p)
	t.check(p.held_by_god() and d._working(w) and d.why_not("oath", s.at) == LanternEyeDirector.WHY_WRIGHT,
		"a held wright still works: %s (%s)" % [LanternEyeDirector.WHY_WRIGHT, d.why_not("oath", s.at)])
	t.check(d.why_not("oath", _far("oath", p.ground_pos)) == "" and d.why_not("doom", s.at) == "" and d.why_not("whisper", s.at) == "",
		"far from him, or with a kill or a Lead, nothing")
	var q := (d.wrights[0][1] as HuntDirector.Guard).man as Person
	s["light"] = q.ground_pos
	ClarityKit.apply(s, "lure", q)
	t.check(not bool(s.took) and not q.lured(), "a lure on a wright on duty is refused (so there is nothing to say of it)")
	ClarityKit.done(s)


static func _why_break(t) -> void:
	var s := _bh(0)
	var d: BreakHuntDirector = s.d
	var b := d.bearer(0)
	var kill_r := float(PowerBook.level_stat("smite", 1, "KILL_R", 0.6))
	var near := b.ground_pos + Vector2(kill_r + 0.5, 0.0)
	t.check(d.guarded(0) and d.why_not("smite", near) == BreakHuntDirector.BH_WHY_STEADIED,
		"a fright on a guarded bearer: %s (%s)" % [BreakHuntDirector.BH_WHY_STEADIED, d.why_not("smite", near)])
	t.check(d.why_not("smite", _far("smite", b.ground_pos)) == "", "the same cast far from him says nothing")
	t.check(d.why_not("smite", b.ground_pos) == "" and d.why_not("doom", b.ground_pos) == "" and d.why_not("whisper", b.ground_pos) == "",
		"a bolt that kills him, a kill and a Lead say nothing (a taken-up standard has its own banner)")
	ClarityKit.apply(s, "scare", b)
	t.check(d.why_not("smite", s.at) == BreakHuntDirector.BH_WHY_STEADIED, "after the fright has run, the escorts as they stood still steady him")
	ClarityKit.done(s)
	s = _bh(0)
	d = s.d
	_bh_hold(s, 0)
	t.check(not d._guarded(0) and d.why_not("smite", d.bearer(0).ground_pos + Vector2(kill_r + 0.5, 0.0)) == "",
		"a fright on a bearer with no escort by him breaks the standard: no banner")
	ClarityKit.done(s)


# ---- read-only, colours, copy ----


static func _read_only(t) -> void:
	var s := _hh(1)
	ClarityKit.assert_read_only(t, s, "Heretic Hunt (guarded)")
	ClarityKit.done(s)
	s = _eye_shattered()
	ClarityKit.assert_read_only(t, s, "Lantern's Eye (shattered)")
	ClarityKit.done(s)
	s = _eye(1)
	ClarityKit.assert_read_only(t, s, "Lantern's Eye (guarded)")
	ClarityKit.done(s)
	s = _bh(0)
	ClarityKit.assert_read_only(t, s, "Break the Hunt")
	ClarityKit.done(s)


## Every colour a step or hint names is a tag the director draws in that phase.
static func _colours(t) -> void:
	for ph: String in ["", "guarded", "open", "waiting", "coming", "captain", "searching"]:
		var s := _hh(1 if ph in ["", "guarded", "open"] else 0)
		var d: HereticHuntDirector = s.d
		match ph:
			"open":
				_hh_clear(d, 0)
			"waiting":
				_hh_break(s, 0)
			"coming", "captain", "searching":
				for i in 3:
					_hh_break(s, i)
				if ph != "coming":
					d._call_head()
					Kit.run_for(s, 0.2)
				if ph == "searching":
					Kit.arrive(d.head as Person, d.head_route[0])
					Kit.run_for(s, HereticHuntDirector.CAPTAIN_STOP + 0.3)
		var want := ph if ph != "" else "guarded"
		t.check(d.hint_phase() == want, "heretic_hunt colours: the world is in the %s phase (%s)" % [want, d.hint_phase()])
		for text in ClarityKit.texts("heretic_hunt", ph):
			ClarityKit.colours_ok(t, d, text, "heretic_hunt/%s" % ph)
		ClarityKit.done(s)
	for ph: String in ["", "guarded", "open", "shattered", "waiting", "eye"]:
		var s: Dictionary
		match ph:
			"shattered":
				s = _eye_shattered()
			"waiting":
				s = _eye(1)
				(s.d as LanternEyeDirector)._gone(0)
			"eye":
				s = _eye(3)
				for i in 3:
					_eye_clear(s.d, i)
				Kit.run_for(s, 0.2)
			"open":
				s = _eye(1)
				_eye_clear(s.d, 0)
			_:
				s = _eye(1)
		var d: LanternEyeDirector = s.d
		var want := ph if ph != "" else "guarded"
		t.check(d.hint_phase() == want, "lantern_eye colours: the world is in the %s phase (%s)" % [want, d.hint_phase()])
		for text in ClarityKit.texts("lantern_eye", ph):
			ClarityKit.colours_ok(t, d, text, "lantern_eye/%s" % ph)
		ClarityKit.done(s)
	for ph: String in ["", "carried", "taken"]:
		var s := _bh(0)
		var d: BreakHuntDirector = s.d
		if ph == "carried":
			ClarityKit.apply(s, "kill", d.bearer(0))
			Kit.run_for(s, LOOK * 2.0)
		elif ph == "taken":
			d._taken[0] = true
			Kit.run_for(s, 0.1)
		t.check(d.hint_phase() == ph, "break_hunt colours: the world is in the %s phase (%s)" % [ph, d.hint_phase()])
		for text in ClarityKit.texts("break_hunt", ph):
			ClarityKit.colours_ok(t, d, text, "break_hunt/%s" % ph)
		ClarityKit.done(s)


## The copy's shape: a step starts with a vocabulary verb or one of the wait openers, and a wait carries its counter.
static func _copy(t) -> void:
	var odd := PackedStringArray()
	var openers := ["Keep", "Be at", "Ambush", "Ascend"]
	for id in IDS:
		for step: Dictionary in MissionSteps.steps(id):
			var label := String(step["t"])
			var verb_first := MissionVerbs.verbs().has(label.get_slice(" ", 0).to_lower())
			var opener := false
			for o: String in openers:
				opener = opener or label.begins_with(o)
			if not verb_first and not opener:
				odd.append("%s: %s (opener)" % [id, label])
			if label.begins_with("Be at") and step.get("c", "") != MissionSteps.COUNT_S:
				odd.append("%s: %s (a wait with no counter)" % [id, label])
	t.check(odd.is_empty(), "every hunt step opens with a verb or a wait opener, and a wait counts (%s)" % "; ".join(odd))
	# The hints with {n} fit three lines filled to three digits.
	var long := PackedStringArray()
	for id in IDS:
		for ph in ClarityKit.phases_of(id):
			var filled := MissionHints.filled(MissionHints.line(id, ph), 999.0)
			if UiTheme.wrap(filled, Hud.HINT_W, UiTheme.TEXT_S).size() > Hud.HINT_LINES:
				long.append("%s/%s" % [id, ph])
	t.check(long.is_empty(), "every hunt hint fits %d lines filled with 999 (%s)" % [Hud.HINT_LINES, ", ".join(long)])
