extends RefCounted
## Veil Task 4: Blight reworked (spec §5.2, §11.1). What a click takes (BlightFx.pick(): a director's thing, the building under the
## click, a person within PICK, the nearest building within REACH); any building becomes a foothold (blighted, its light out, a lasting
## dusk of 3 / 5, at most VeilRules.BLIGHT_MAX); a person walks home sick (in the dark with the 2 nearest), a quarry is only ill; no
## alarm; a cast with nothing in reach is refused and spends no cooldown; an effect cut short leaves nothing.


## A director with one point of its own and one quarry.
class TestDirector extends MissionDirector:
	var spot := Vector2.INF
	var mine: Person

	func blight_target(at: Vector2) -> Vector2:
		return spot if spot != Vector2.INF and at.distance_to(spot) <= BlightFx.REACH else Vector2.INF

	func quarry(p: Person) -> bool:
		return p != null and p == mine


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
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	crowd.spawn()
	crowd.dusk.enabled = true
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	ctx.rules = Rules.new()
	return [crowd, env, grid, field, world, ctx, town]


static func _done(made: Array) -> void:
	var crowd: Crowd = made[0]
	for s in crowd.footholds.duplicate():
		BlightFx.heal(crowd, made[1], s)
	crowd.clear()
	var ctx: FxContext = made[5]
	ctx.rules.free()
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


## Everyone far off in a corner.
static func _scatter(crowd: Crowd) -> void:
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		p.inside = false
		i += 1


## Plain houses (no use for v0.05's Blight), by instance id.
static func _houses(env: EnvironmentField) -> Array[Structure]:
	var out: Array[Structure] = []
	for s in env.structures():
		if is_instance_valid(s) and s.kind == Structure.Kind.HOUSE and not BlightFx.blightable(s) and BlightFx.building(s):
			out.append(s)
	out.sort_custom(func(a: Structure, b: Structure) -> bool: return a.get_instance_id() < b.get_instance_id())
	return out


## `n` plain houses whose middles lie at least `gap` apart.
static func _far_houses(env: EnvironmentField, n: int, gap: float) -> Array[Structure]:
	var out: Array[Structure] = []
	for h in _houses(env):
		var ok := true
		for o in out:
			if o.center().distance_to(h.center()) < gap:
				ok = false
		if ok:
			out.append(h)
		if out.size() == n:
			break
	return out


## The nearest Blight building's distance from `at` (0 inside one).
static func _building_gap(env: EnvironmentField, at: Vector2) -> float:
	var best := INF
	for s in env.structures():
		if BlightFx.building(s):
			best = minf(best, s.distance_to(at))
	return best


## A walkable point with no building within 3 and away from the scattered crowd.
static func _open_spot(env: EnvironmentField, grid: WalkGrid) -> Vector2:
	var m := TownLayout.MAP
	var y := m.position.y + 4.0
	while y < m.end.y - 4.0:
		var x := m.position.x + 4.0
		while x < m.end.x - 4.0:
			var g := Vector2(x, y)
			if g.distance_to(Vector2(-24.0, -24.0)) > 8.0 and grid.on_streets(g) and _building_gap(env, g) > 3.0:
				return g
			x += 1.0
		y += 1.0
	return Vector2.INF


## A point 0.9 off a plain house's side, with no other building nearer: [the house, the point].
static func _beside(env: EnvironmentField) -> Array:
	for h in _houses(env):
		var f := h.footprint
		var c := h.center()
		for g in [Vector2(f.end.x + 0.9, c.y), Vector2(f.position.x - 0.9, c.y), Vector2(c.x, f.end.y + 0.9), Vector2(c.x, f.position.y - 0.9)]:
			if absf(_building_gap(env, g) - 0.9) < 0.001 and absf(h.distance_to(g) - 0.9) < 0.001:
				return [h, g]
	return []


static func _cast(ctx: FxContext, at: Vector2, dark := false, run := BlightFx.T_ROT + 0.05) -> FxTimeline:
	var fx: FxTimeline = FxTimeline.cast(load("res://src/fx/quiet/blight.gd"), ctx, at, {"dark": dark})
	fx._process(run)
	return fx


static func run(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	_scatter(crowd)
	var open := _open_spot(env, grid)
	t.check(open != Vector2.INF, "an open spot exists (%s)" % open)
	_pick(t, made, open)
	_buildings(t, made)
	_people(t, made, open)
	_kept(t, made, open)
	_refusal(t, made, open)
	_teardown(t, made)
	_done(made)
	_no_crowd(t)


static func _pick(t, made: Array, open: Vector2) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var ctx: FxContext = made[5]
	var h: Structure = _houses(env)[0]
	var p: Person = crowd.citizens[0]
	# A director's thing wins, even over the building under the click.
	var d := TestDirector.new()
	d.spot = h.center()
	ctx.rules.director = d
	var took := BlightFx.pick(ctx, h.center())
	t.check(took.kind == &"director" and took.at == h.center(), "a director's own target wins (%s)" % took.kind)
	ctx.rules.director = null
	# A click inside a footprint takes that building, even with a person 0.3 away.
	p.ground_pos = h.center() + Vector2(0.3, 0.0)
	took = BlightFx.pick(ctx, h.center())
	t.check(took.kind == &"building" and took.s == h, "a click on a building takes the building, not the person 0.3 away")
	# Off any building: a person within 0.5 wins over a building 0.9 away; with no person, that building.
	var side := _beside(env)
	t.check(side.size() == 2, "a point 0.9 off a house exists")
	if side.size() == 2:
		p.ground_pos = side[1]
		took = BlightFx.pick(ctx, side[1])
		t.check(took.kind == &"person" and took.p == p, "off a building a person within 0.5 wins over a building 0.9 away (%s)" % took.kind)
		p.ground_pos = Vector2(-27.0, -27.0)
		took = BlightFx.pick(ctx, side[1])
		t.check(took.kind == &"building" and took.s == side[0], "with nobody there, the nearest building within 1.0")
	took = BlightFx.pick(ctx, open)
	t.check(took.kind == &"none", "nothing in reach: none")
	p.ground_pos = open + Vector2(0.6, 0.0)
	t.check(BlightFx.pick(ctx, open).kind == &"none", "a person 0.6 away is out of reach")
	# A BELIEVER under the click is passed over.
	var b: Person = crowd.citizens[1]
	var faith := b.profile.faith
	b.profile.faith = CitizenProfile.Faith.BELIEVER
	b.ground_pos = open + Vector2(0.1, 0.0)
	p.ground_pos = open + Vector2(0.4, 0.0)
	took = BlightFx.pick(ctx, open)
	t.check(took.kind == &"person" and took.p == p, "a believer under the click is passed over for the next")
	p.ground_pos = Vector2(-27.0, -27.0)
	t.check(BlightFx.pick(ctx, open).kind == &"none", "a believer alone: nothing to take")
	b.profile.faith = faith
	_scatter(crowd)


static func _buildings(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var ctx: FxContext = made[5]
	var four := _far_houses(env, 4, 12.0)
	t.check(four.size() == 4, "four houses far apart")
	var h := four[0]
	var c := h.center()
	var alarm := crowd.alarm
	var told: Array = []
	var on_blight := func(s: Structure) -> void: told.append(s)
	env.structure_blighted.connect(on_blight)
	t.check(BlightFx.lit(h) and not h.blighted and not BlightFx.blightable(h), "a plain house, lit, no use for v0.05's Blight")
	var fx := _cast(ctx, c)
	t.check(h.blighted and not BlightFx.lit(h) and crowd.footholds == [h], "any building: a plain house is blighted, its light is gone")
	t.check(crowd.dusk.covers(c + Vector2(2.9, 0.0)) and not crowd.dusk.covers(c + Vector2(3.1, 0.0)) and crowd.dusk.count() == 1,
		"dusk covers its middle + 2.9 and not + 3.1")
	fx._process(1.0)
	t.check(fx.finished, "the effect ends")
	crowd.dusk.step(300.0)
	t.check(h.blighted and not BlightFx.lit(h) and crowd.dusk.covers(c + Vector2(2.9, 0.0)), "and the foothold still holds after 300 s")
	t.check(crowd.alarm == alarm and told.is_empty(), "no alarm, and nothing in the town is told of a house")
	# Dark: 4.9 / 5.1.
	BlightFx.heal(crowd, env, h)
	t.check(not h.blighted and BlightFx.lit(h) and crowd.dusk.count() == 0 and crowd.footholds.is_empty(), "healed: clean, lit, no dusk")
	var hd := four[1]
	fx = _cast(ctx, hd.center(), true)
	t.check(hd.blighted and crowd.dusk.covers(hd.center() + Vector2(0.0, 4.9)) and not crowd.dusk.covers(hd.center() + Vector2(0.0, 5.1)),
		"dark: dusk covers + 4.9 and not + 5.1")
	fx.end_now()
	BlightFx.heal(crowd, env, hd)
	# A building with a use: env.structure_blighted, Structure.blighted (as today), no alarm.
	var well := BlightFx.target(env, TownLayout.WELLS[0].get_center())
	alarm = crowd.alarm
	fx = _cast(ctx, well.center())
	t.check(well.blighted and told == [well] and crowd.alarm == alarm, "a well: structure_blighted fired, blighted, no alarm")
	fx.end_now()
	BlightFx.heal(crowd, env, well)
	var tower: Structure = crowd.bell.tower
	alarm = crowd.alarm
	fx = _cast(ctx, tower.center())
	t.check(tower.blighted and told.has(tower) and crowd.alarm == alarm, "the bell tower: blighted, no alarm")
	fx.end_now()
	BlightFx.heal(crowd, env, tower)
	env.structure_blighted.disconnect(on_blight)
	# The cap: the fourth heals the first.
	for s in four:
		_cast(ctx, s.center()).end_now()
	t.check(crowd.footholds == [four[1], four[2], four[3]], "the cap: three footholds, oldest first")
	t.check(not four[0].blighted and BlightFx.lit(four[0]) and not crowd.dusk.covers(four[0].center()),
		"the fourth blight heals the first: its light back, its dusk gone")
	var stand := true
	for i in range(1, 4):
		stand = stand and four[i].blighted and not BlightFx.lit(four[i]) and crowd.dusk.covers(four[i].center())
	t.check(stand and crowd.dusk.count() == 3, "the other three stand")
	for s in crowd.footholds.duplicate():
		BlightFx.heal(crowd, env, s)


static func _people(t, made: Array, open: Vector2) -> void:
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	_scatter(crowd)
	crowd.dusk.clear()
	var p: Person = crowd.citizens[2]
	p.ground_pos = open
	var alarm := crowd.alarm
	var killed := crowd.killed_citizens
	var alive := crowd.alive_citizens()
	var fx := _cast(ctx, open + Vector2(0.2, 0.0))
	t.check(p.home_sick and p.is_alive() and not p.inside, "a person: sick, walking home")
	t.check(crowd.dusk.covers(open) and crowd.dusk.count() == 1, "and the cast leaves its dusk")
	fx.end_now()
	for i in 4000:
		p.tick(0.05)
		if p.inside:
			break
	t.check(p.inside and p.home_sick and p.is_alive(), "goes inside, home sick")
	t.check(crowd.killed_citizens == killed and crowd.alive_citizens() == alive and crowd.alarm == alarm,
		"no death, no kill credit, alarm unchanged")
	# Light: only the one.
	_scatter(crowd)
	var a: Person = crowd.citizens[3]
	var b: Person = crowd.citizens[4]
	var c: Person = crowd.citizens[5]
	var d: Person = crowd.citizens[6]
	a.ground_pos = open
	b.ground_pos = open + Vector2(0.6, 0.0)
	c.ground_pos = open + Vector2(0.0, 1.0)
	d.ground_pos = open + Vector2(-1.5, 0.0)
	_cast(ctx, open).end_now()
	t.check(a.home_sick and not b.home_sick and not c.home_sick and not d.home_sick, "light: only the one")
	# Dark: that one and the 2 nearest within 2.0; a fourth at 1.5 does not.
	a.ground_pos = open + Vector2(0.0, -0.2)
	a.home_sick = false
	var e: Person = crowd.citizens[7]
	e.ground_pos = open
	_cast(ctx, open, true).end_now()
	t.check(e.home_sick and b.home_sick and a.home_sick and not c.home_sick and not d.home_sick,
		"dark: that one and the 2 nearest within 2.0 go home; a fourth does not")
	# A quarry: ill for 20 s at half pace, stays on the street.
	_scatter(crowd)
	var q: Person = crowd.citizens[8]
	q.ground_pos = open
	var dir := TestDirector.new()
	dir.mine = q
	ctx.rules.director = dir
	_cast(ctx, open).end_now()
	t.check(not q.home_sick and is_equal_approx(q.ill_left(), BlightFx.ILL_TIME) and is_equal_approx(q.pace_hold(), 0.5)
		and not q.inside, "quarry: stays on the street, half pace for 20 s")
	ctx.rules.director = null
	# The picked person dies before T_ROT: no error, nobody sent home.
	_scatter(crowd)
	var v: Person = crowd.citizens[9]
	var w: Person = crowd.citizens[10]
	v.ground_pos = open
	w.ground_pos = open + Vector2(0.5, 0.0)
	fx = _cast(ctx, open, true, 0.4)
	field.kill(v, &"smite")
	fx._process(0.6)
	t.check(not v.is_alive() and not v.home_sick and not w.home_sick, "the picked person dies before T_ROT: nobody sent home")
	fx.end_now()
	_scatter(crowd)


## Final review, Critical 3: one the mission keeps alive (Crowd.spared(): a director's keeps_alive -- the Escort's charge) is never
## sent home sick. A dark Blight on a guard beside him leaves him well and takes the next nearest instead; a click on him picks the
## next thing in Blight's order, or nothing ("no_blight") when nothing else is there. No luck: distance, then instance id.
static func _kept(t, made: Array, open: Vector2) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var ctx: FxContext = made[5]
	_scatter(crowd)
	crowd.dusk.clear()
	for p in crowd.citizens + crowd.soldiers:
		p.home_sick = false
	var g: Person = crowd.soldiers[0]
	var k: Person = crowd.citizens[20]
	var o1: Person = crowd.citizens[21]
	var o2: Person = crowd.citizens[22]
	var keep := func(p: Person) -> bool: return p == k
	crowd.mission_keeps.append(keep)
	t.check(crowd.spared(k) and not crowd.spared(o1), "(the charge is kept alive: Crowd.spared())")
	g.ground_pos = open
	k.ground_pos = open + Vector2(0.5, 0.0)
	o1.ground_pos = open + Vector2(1.0, 0.0)
	o2.ground_pos = open + Vector2(1.5, 0.0)
	_cast(ctx, open, true).end_now()
	t.check(g.home_sick and not k.home_sick and o1.home_sick and o2.home_sick,
		"dark Blight beside a kept charge: he stays well, the next nearest go instead (guard %s, kept %s, %s, %s)"
		% [g.home_sick, k.home_sick, o1.home_sick, o2.home_sick])
	# A click on the charge himself: the next by Blight's order (a person within PICK).
	_scatter(crowd)
	for p in crowd.citizens + crowd.soldiers:
		p.home_sick = false
	k.ground_pos = open
	o1.ground_pos = open + Vector2(0.4, 0.0)
	var took := BlightFx.pick(ctx, open)
	t.check(took.kind == &"person" and took.p == o1, "a click on the kept charge picks the next one within reach (%s)" % took.kind)
	_cast(ctx, open).end_now()
	t.check(not k.home_sick and o1.home_sick, "and that one goes home sick, not the charge")
	o1.home_sick = false
	o1.ground_pos = Vector2(-27.0, -27.0)
	t.check(BlightFx.choose(env, crowd, null, open).kind == &"none", "the charge alone: nothing to blight (refused \"no_blight\")")
	crowd.mission_keeps.erase(keep)
	crowd.dusk.clear()
	_scatter(crowd)


static func _refusal(t, made: Array, open: Vector2) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	_scatter(crowd)
	var rules := Rules.new().setup(PackedStringArray(["blight"]), null, env, made[3], crowd, made[6])
	var casts: Array = []
	rules.caster = func(_s: GDScript, _g: Vector2, e: Dictionary) -> FxTimeline:
		casts.append(e)
		return null
	var refused: Array = []
	rules.cast_refused.connect(func(_s: int, why: String) -> void: refused.append(why))
	t.check(BlightFx.refusal(rules, open) == "no_blight" and BlightFx.refusal(null, open) == "", "the refusal: no_blight, none without rules")
	rules.cast(0, open)
	t.check(refused == ["no_blight"] and casts.is_empty() and rules.cooldown_left(0) == 0.0,
		"nothing in reach: Rules refuses the cast with a reason and no cooldown is spent")
	t.check(Hud.VEIL_REFUSALS.get("no_blight", "") == "NOTHING HERE TO BLIGHT", "the HUD's words")
	rules.cast(0, _houses(env)[0].center())
	t.check(casts.size() == 1 and refused.size() == 1 and rules.cooldown_left(0) > 0.0, "(control) on a house it goes out")
	rules.free()


static func _teardown(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	crowd.dusk.clear()
	var h: Structure = _houses(made[1])[1]
	var fx := _cast(ctx, h.center(), false, 0.4)
	fx.free()
	t.check(not h.blighted and BlightFx.lit(h) and crowd.dusk.count() == 0 and crowd.footholds.is_empty(),
		"the effect freed at 0.4 s: nothing blighted, no dusk laid")
	fx = _cast(ctx, h.center(), false, 0.4)
	fx.end_now()
	t.check(not h.blighted and crowd.dusk.count() == 0, "ended at 0.4 s: the same")
	fx = _cast(ctx, h.center(), false, 0.4)
	fx._process(1.0)
	t.check(h.blighted and crowd.footholds == [h] and crowd.dusk.count() == 1, "(control) left to run: blighted")
	fx.free()
	t.check(h.blighted and not BlightFx.lit(h) and crowd.dusk.count() == 1, "and the foothold outlives the freed effect")
	BlightFx.heal(crowd, made[1], h)


## No crowd, no rules (the VFX Sandbox): it builds, blights at the light size and finishes.
static func _no_crowd(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var ctx := FxContext.new()
	ctx.env = env
	ctx.rng = RandomNumberGenerator.new()
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	var h: Structure = _houses(env)[0]
	t.check(BlightFx.pick(ctx, h.center()).kind == &"building" and BlightFx.pick(null, h.center()).kind == &"none", "no crowd: it picks")
	var fx := _cast(ctx, h.center())
	fx._process(1.0)
	t.check(fx.finished and h.blighted and BlightFx.lit(h), "no crowd: blighted, no foothold, it finishes")
	fx = _cast(ctx, h.center() + Vector2(40.0, 40.0))
	fx._process(1.0)
	t.check(fx.finished, "no crowd, nothing there: it finishes")
	ctx.overhead.free()
	ctx.ground.free()
