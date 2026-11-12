extends RefCounted
## The Remains ledger (Death authority, spec §4): only a whole-body death is written down, as values; a remain lapses at
## 45 s (its soul at 15 s), the oldest goes past 60, and Rules refuses a cast that needs a body the ground lacks.


static func _setup() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	return [crowd, env, field, world, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[3] as Node).free()


## The nth living citizen, set down at `at`, then killed as `kind`.
static func _kill(made: Array, n: int, at: Vector2, kind: StringName) -> Person:
	var p: Person = made[0].citizens[n]
	p.ground_pos = at
	(made[2] as EnemyField).kill(p, kind)
	return p


static func run(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var rem: Remains = crowd.remains
	t.check(rem != null and not rem.enabled and rem.all().is_empty(), "the ledger is off by default and empty")
	_kill(made, 0, Vector2(1, 1), &"deathmark")
	t.check(rem.all().is_empty(), "off by default: a deathmark death records nothing")

	rem.enabled = true
	var kinds: Array[StringName] = [&"deathmark", &"plague", &"mob", &"frenzy", &"lightning", &"stone", &"pit", &"doom", &"water"]
	for i in kinds.size():
		_kill(made, 1 + i, Vector2(2.0 + float(i) * 3.0, 2.0), kinds[i])
	var got := rem.all()
	t.check(got.size() == 4 and got.all(func(r): return Remains.BODY_KINDS.has(r.kind)),
		"on: deathmark, plague, mob, frenzy record a remain; lightning, stone, pit, doom, water record none (%d)" % got.size())
	t.check(got[0].design != "" and got[0].pos.is_equal_approx(Vector2(2, 2)) and not got[0].soldier,
		"a remain keeps where, who and the design")

	# Time: 45 s life, 15 s soul.
	var r0: Remains.Remain = got[0]
	rem.step(14.0)
	var soul14 := rem.has_soul(r0)
	rem.step(2.0)
	t.check(soul14 and not rem.has_soul(r0) and rem.all().size() == 4, "a remain lapses at 45 s; its soul at 15 s (soul gone at 16 s, body still there)")
	rem.step(28.0)
	t.check(rem.all().size() == 4, "still there at 44 s")
	rem.step(2.0)
	t.check(rem.all().is_empty(), "gone by 46 s")

	# Over 60, the oldest lapses first.
	for i in 62:
		var p: Person = crowd.citizens[10 + i]
		p.ground_pos = Vector2(-20.0 + float(i) * 0.1, -20.0)
		(made[2] as EnemyField).kill(p, &"mob")
		rem.step(0.01)
	var list := rem.all()
	t.check(list.size() == Remains.MAX and is_equal_approx(list[0].pos.x, -19.8),
		"over 60, the oldest lapses first (%d kept, oldest at x=%.1f)" % [list.size(), list[0].pos.x])
	for r in rem.all():
		rem.take(r)

	# Picking.
	_kill(made, 80, Vector2(5, 5), &"mob")
	var near_r := rem.pick(Vector2(5.8, 5.0))
	t.check(near_r != null and rem.pick(Vector2(6.2, 5.0)) == null, "pick finds the nearest within 1.0, null beyond")
	near_r.hidden = true
	t.check(rem.pick(Vector2(5, 5)) == null and rem.all().is_empty(), "a hidden remain is never picked")
	near_r.hidden = false

	# Take and move.
	rem.step(10.0)
	rem.move(near_r, Vector2(9, 9), false)
	rem.step(10.0)
	t.check(is_equal_approx(rem.age(near_r), 10.0) and rem.has_soul(near_r) and rem.pick(Vector2(9, 9)) == near_r,
		"move restarts its clock")
	rem.take(near_r)
	t.check(rem.pick(Vector2(9, 9)) == null, "take uses it up")

	# The person freed: the remain still raises.
	var victim := _kill(made, 90, Vector2(-5, 5), &"deathmark")
	var design := victim._design()
	crowd.citizens.erase(victim)
	victim.free()
	var left := rem.pick(Vector2(-5, 5))
	t.check(left != null and left.design == design and left.design != "",
		"the person node freed: the remain still raises, with its design string intact")
	t.check(rem._drawn(left), "its corpse node gone, the remain is what is drawn lying there")
	rem.take(left)

	# A risen body leaves no corpse behind: take() hides the person's own corpse at once (its timer still frees it), and the remain
	# is drawn only where its corpse no longer shows.
	var marked := _kill(made, 91, Vector2(-6, 6), &"deathmark")
	var held := rem.pick(Vector2(-6, 6))
	t.check(held != null and marked.visible and not rem._drawn(held),
		"a Death Mark corpse lies there itself: the remain is not drawn over it")
	rem.take(held)
	t.check(is_instance_valid(marked) and not marked.visible and marked.state == DummyEnemy.State.DEAD,
		"taking a Death Mark remain hides its node at once")
	rem.move(held, Vector2(-8, 8), false)
	t.check(rem._drawn(held) and rem._shown_count() == 1, "moved, it is drawn once, where it now lies")
	rem.take(held)

	# Rules.
	var rules := Rules.new().setup(PackedStringArray(["smite", "deathmark"]), null, made[1], made[2], crowd, made[4])
	var rem_on_before := Remains.wants(["smite", "deathmark"])
	t.check(not rem_on_before, "a loadout with no raise, walker or gravetide does not need the ledger")
	t.check(rules.body_check("body", Vector2(0, 0)) == "no_dead" and rules.body_check("any_body", Vector2(0, 0)) == "no_dead"
		and rules.body_check("soul", Vector2(0, 0)) == "no_dead" and rules.body_check("", Vector2(0, 0)) == "",
		"Rules refuses a needs-body cast with no remain: no_dead (body, any_body, soul)")
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, reason: String): refused.append([slot, reason]))
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	t.check(Rules.needs_of("smite", "") == "" and rules.cooldown_left(0) == 0.0,
		"a power without needs casts as before, and no cooldown is spent by a check")
	_kill(made, 100, Vector2(7, 7), &"mob")
	var there := rem.pick(Vector2(7, 7))
	t.check(rules.body_check("body", Vector2(7, 7)) == "" and rules.body_check("any_body", Vector2(-9, -9)) == ""
		and rules.body_check("soul", Vector2(7, 7)) == "", "a body there passes body, any_body and soul")
	rem.step(16.0)
	t.check(rules.body_check("soul", Vector2(7, 7)) == "soul_gone" and rules.body_check("body", Vector2(7, 7)) == "",
		"a body whose soul has gone: soul_gone for a soul cast, body still fine")
	there.hidden = true
	t.check(rules.body_check("any_body", Vector2(0, 0)) == "no_dead", "any_body ignores hidden remains")

	t.check(Remains.wants(["smite", "raise"]) and not Remains.wants(["smite"]) and Remains.wants(["gravetide"]) and Remains.wants(["walker"]),
		"Remains.wants(['smite','raise']) is true, wants(['smite']) is false")
	var on_rules := Rules.new().setup(PackedStringArray(["smite", "raise"]), null, made[1], made[2], crowd, made[4])
	t.check(crowd.remains.enabled, "Rules turns the ledger on for a raise loadout")
	_done(made)
