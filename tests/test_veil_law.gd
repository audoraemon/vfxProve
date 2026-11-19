extends RefCounted
## The law of the Veil (Veil authority powers spec §4, Task 1): two sizes per power (VeilRules), the dusk ledger on the crowd
## (Crowd.lay_dusk(), in_dark(), sight_scale_at()), the dark stamp Rules.cast() puts on a Veil cast, the aim ring that shows the
## size a cast would get, and the Veil tree's rows in the book and the tree.


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
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func run(t) -> void:
	_sizes(t)
	_book_and_tree(t)
	var made := _setup()
	_ledger(t, made)
	_sight(t, made)
	_stamp(t, made)
	_ring(t, made)
	_stubs(t, made)
	_done(made)


static func _sizes(t) -> void:
	t.check(VeilRules.size("doom", "RADIUS", false) == 0.8 and VeilRules.size("doom", "RADIUS", true) == 1.6, "doom two sizes")
	t.check(VeilRules.size("evernight", "TAKE_EVERY", false) == 2.0 and VeilRules.size("evernight", "TAKE_EVERY", true) == 1.5
		and VeilRules.size("cloak", "MOST", true) == 8.0 and VeilRules.size("doom", "NOPE", true) == 0.0
		and VeilRules.size("smite", "RADIUS", true) == 0.0, "a stat's two sizes; 0 for one the table does not name")
	t.check(VeilRules.wants(PackedStringArray(["smite", "doom"])) and not VeilRules.wants(PackedStringArray(["smite"]))
		and VeilRules.wants(PackedStringArray(["evernight"])) and not VeilRules.wants(PackedStringArray()), "wants")
	t.check(VeilRules.DUSK_R == 3.0 and VeilRules.DUSK_TIME == 20.0 and VeilRules.BLIGHT_MAX == 3, "the law's constants")
	var ring_ok := true
	for k: String in VeilRules.RING:
		if VeilRules.size(k, String(VeilRules.RING[k]), false) <= 0.0 or not Targeting.AREAS.has(k) \
				or not is_equal_approx(float(Targeting.AREAS[k].r), VeilRules.size(k, String(VeilRules.RING[k]), false)):
			ring_ok = false
	t.check(ring_ok, "every ring stat has two sizes, and the area's own radius is the light one")


static func _book_and_tree(t) -> void:
	t.check(GodTree.TABLE["veil"] == [["doom", "blight"], ["slumber", "cloak"], ["unseen", "dreamless"], ["dread", "shadowplay"],
		["swallow", "evernight"]], "tree")
	var cools := {"slumber": 40.0, "cloak": 45.0, "dreamless": 35.0, "dread": 70.0, "shadowplay": 90.0, "swallow": 999.0,
		"evernight": 999.0}
	for k: String in ["slumber", "cloak", "dreamless", "dread", "shadowplay", "swallow", "evernight"]:
		var row := PowerBook.get_power(k)
		t.check(PowerBook.authority_of(k) == "veil" and PowerBook.is_quiet(k) and PowerBook.blurb(k) != ""
			and PowerBook.blurb(k).length() <= 70 and String(row.get("aim", "")) == "click"
			and is_equal_approx(PowerBook.cooldown(k), float(cools[k])) and ResourceLoader.exists(String(row.path))
			and PowerBook.family(k) == "veil" and Rules.POWER_KINDS.has(k) and String(row.get("shape", "")) != "", k)
	t.check(PowerBook.might("slumber") == 3 and PowerBook.might("cloak") == 3 and PowerBook.might("dreamless") == 3
		and PowerBook.might("dread") == 4 and PowerBook.might("shadowplay") == 5 and PowerBook.might("swallow") == 6
		and PowerBook.might("evernight") == 6, "might")
	t.check(String(PowerBook.get_power("unseen").get("blurb", "")) != "", "Unseen Hour has a blurb of its own")
	t.check(Rules.POWER_KINDS["dreamless"] == [&"dreamless", &"dreamt"] and Rules.POWER_KINDS["shadowplay"] == [&"shadow"]
		and Rules.POWER_KINDS["swallow"] == [&"void"] and Rules.POWER_KINDS["evernight"] == [&"night"]
		and Rules.POWER_KINDS["blight"] == [] and Rules.POWER_KINDS["slumber"] == [], "the new kill kinds are the powers' credit")
	var keys := PowerBook.of_authority("veil")
	t.check(keys.find("unseen") >= 0 and keys.find("slumber") == keys.find("unseen") + 1
		and keys.find("evernight") == keys.find("unseen") + 7, "the seven rows follow Unseen Hour in the book (%s)" % [keys])
	t.check(is_equal_approx(float(Targeting.AREAS["evernight"].r), 0.6) and not VeilRules.RING.has("evernight")
		and String(Targeting.AREAS["swallow"].shape) == "circle" and is_equal_approx(float(Targeting.AREAS["swallow"].r), 10.0),
		"areas: circles at the light radius; Evernight only a mark where the click lands")


static func _ledger(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var p := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	t.check(crowd.dusk != null and not crowd.dusk.enabled and not crowd.night_mission, "the ledger is there, off by default")
	crowd.dusk.enabled = false
	t.check(crowd.lay_dusk(p, 3.0, 20.0) == 0 and not crowd.in_dark(p) and crowd.dusk.count() == 0, "off: nothing laid")
	crowd.dusk.enabled = true
	var heard: Array = []
	var on_laid := func(at: Vector2, r: float) -> void: heard.append([at, r])
	crowd.dusk.laid.connect(on_laid)
	var id := crowd.lay_dusk(p, 3.0, 20.0)
	t.check(id > 0 and heard == [[p, 3.0]], "the laid signal fires once per lay with (at, r) (%s)" % [heard])
	t.check(crowd.in_dark(p) and crowd.in_dark(p + Vector2(2.9, 0)) and not crowd.in_dark(p + Vector2(3.1, 0)), "patch edge")
	t.check(is_equal_approx(crowd.dusk.r_at(p), 3.0) and crowd.dusk.r_at(p + Vector2(3.5, 0.0)) == 0.0, "r_at: the patch's radius, 0 outside")
	crowd.dusk.step(19.9)
	t.check(crowd.in_dark(p), "still dark at 19.9 s")
	crowd.dusk.step(0.2)
	t.check(not crowd.in_dark(p) and crowd.dusk.count() == 0, "fades at 20 s")
	var id2 := crowd.lay_dusk(p, 3.0, -1.0)
	crowd.dusk.step(500.0)
	t.check(crowd.in_dark(p), "lasting")
	crowd.dusk.end(id2)
	t.check(not crowd.in_dark(p), "ended")
	# Two patches: ending one leaves the other; the larger one is r_at's.
	var a := crowd.lay_dusk(p, 3.0, 20.0)
	var b := crowd.lay_dusk(p + Vector2(1.0, 0.0), 5.0, 20.0)
	t.check(a != b and is_equal_approx(crowd.dusk.r_at(p), 5.0), "two patches: the larger covers (%f)" % crowd.dusk.r_at(p))
	crowd.dusk.end(b)
	t.check(crowd.in_dark(p) and not crowd.in_dark(p + Vector2(5.0, 0.0)) and is_equal_approx(crowd.dusk.r_at(p), 3.0),
		"ending one leaves the other")
	crowd.dusk.end(a)
	t.check(heard.size() == 4, "one signal per lay (%d)" % heard.size())
	crowd.dusk.laid.disconnect(on_laid)
	# Veil and night count as dark; Evernight is everywhere.
	var q := p + Vector2(0.0, 12.0)
	var far := p + Vector2(40.0, 0.0)
	t.check(not crowd.in_dark(q), "lit before the veil")
	crowd.veil(q, 5.0, 20.0)
	t.check(crowd.in_dark(q) and not crowd.dusk.covers(q), "veil is dark (and is no dusk patch)")
	crowd.night_mission = true
	t.check(crowd.in_dark(far), "night mission is dark")
	crowd.night_mission = false
	t.check(not crowd.in_dark(far), "and a day is not")
	crowd.dusk.everywhere = true
	t.check(crowd.in_dark(far) and not crowd.dusk.covers(far), "Evernight is dark everywhere, though no patch covers")
	crowd.dusk.everywhere = false
	# The crowd's clock steps the ledger.
	crowd.lay_dusk(far, 3.0, 1.0)
	crowd.advance(1.5)
	t.check(not crowd.in_dark(far), "the crowd's advance ages the patches")
	crowd.lay_dusk(far, 3.0, -1.0)
	crowd.dusk.clear()
	t.check(crowd.dusk.count() == 0, "(cleared)")


static func _sight(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var p := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var in_dusk := p
	var in_dusk2 := p + Vector2(1.0, 0.0)
	var lit := p + Vector2(10.0, 0.0)
	var lit2 := p + Vector2(11.0, 0.0)
	t.check(is_equal_approx(crowd.sight_scale_at(in_dusk, lit), 1.0), "an empty ledger: the day's sight")
	crowd.sight_scale = 0.6
	t.check(crowd.sight_scale_at(in_dusk, lit) == crowd.sight_scale, "an empty ledger: exactly sight_scale")
	crowd.sight_scale = 1.0
	var id := crowd.lay_dusk(p, 3.0, 20.0)
	t.check(is_equal_approx(crowd.sight_scale_at(in_dusk, in_dusk2), 0.6), "0.6 once")
	t.check(is_equal_approx(crowd.sight_scale_at(lit, in_dusk), 0.6) and is_equal_approx(crowd.sight_scale_at(in_dusk, lit), 0.6),
		"either end in dusk shortens the line")
	t.check(is_equal_approx(crowd.sight_scale_at(Vector2.INF, in_dusk), 0.6) and is_equal_approx(crowd.sight_scale_at(Vector2.INF, lit), 1.0),
		"INF is no point: only the other end counts")
	crowd.sight_scale = 0.6
	t.check(is_equal_approx(crowd.sight_scale_at(in_dusk, lit), 0.6), "night: not 0.36")
	crowd.sight_scale = 1.0
	t.check(is_equal_approx(crowd.sight_scale_at(lit, lit2), 1.0), "lit: 1.0")
	# The witness reach follows: one standing in dusk sees a death only from 0.6 of DOOM_WITNESS.
	var w: Person = crowd.citizens[0]
	for o in crowd.citizens + crowd.soldiers:
		o.ground_pos = p + Vector2(-27.0, -27.0)
	var death := lit
	w.ground_pos = death + Vector2(Crowd.DOOM_WITNESS * 0.8, 0.0)
	t.check(crowd.nearest_witness(death) == w, "a lit witness at 0.8 of the reach sees it")
	var id2 := crowd.lay_dusk(death, 3.0, 20.0)
	t.check(crowd.nearest_witness(death) == null and is_equal_approx(crowd.doom_witness(death), Crowd.DOOM_WITNESS * 0.6),
		"in dusk the same witness does not (reach %f)" % crowd.doom_witness(death))
	w.ground_pos = death + Vector2(Crowd.DOOM_WITNESS * 0.5, 0.0)
	t.check(crowd.nearest_witness(death) == w, "but one at half the reach still does")
	crowd.dusk.end(id)
	crowd.dusk.end(id2)
	t.check(is_equal_approx(crowd.doom_witness(death), Crowd.DOOM_WITNESS) and crowd.doom_witness() == Crowd.DOOM_WITNESS,
		"no dusk: the day's reach")


static func _stamp(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var p := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var lit := p + Vector2(10.0, 0.0)
	crowd.dusk.enabled = false
	var plain := Rules.new().setup(PackedStringArray(["smite"]), null, made[1], made[3], crowd, made[6])
	t.check(not crowd.dusk.enabled, "the gate: no Veil power carried, the ledger stays off")
	plain.free()
	var rules := Rules.new().setup(PackedStringArray(["doom", "smite"]), null, made[1], made[3], crowd, made[6])
	t.check(crowd.dusk.enabled, "the gate: a Veil power carried turns the ledger on")
	rules.free_play = true
	var casts: Array = []
	rules.caster = func(_s: GDScript, _g: Vector2, e: Dictionary) -> FxTimeline:
		casts.append(e)
		return null
	var id := crowd.lay_dusk(p, 3.0, 20.0)
	rules.cast(0, p)
	rules.cast(0, lit)
	rules.cast(1, p)
	rules.cast(0, lit, {"dark": true})
	t.check(casts.size() == 4 and casts[0].get("dark") == true and casts[1].get("dark") == false and not casts[2].has("dark")
		and casts[3].get("dark") == true, "doom on dusk ground: dark; on lit ground: light; smite: no key; a key already given wins (%s)" % [casts])
	crowd.dusk.end(id)
	rules.free()
	crowd.dusk.enabled = true


static func _ring(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var p := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var lit := p + Vector2(10.0, 0.0)
	var rules := Rules.new().setup(PackedStringArray(["doom", "unseen", "smite"]), null, made[1], made[3], crowd, made[6])
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var aim := Targeting.new().setup(rules, crowd)
	var id := crowd.lay_dusk(p, 3.0, 20.0)
	aim.pick(0)
	aim.hover(p)
	t.check(is_equal_approx(float(aim.area().r), 1.6) and aim.ring_tag() == "DARK", "doom's ring on dusk: 1.6, DARK (%s)" % [aim.area()])
	aim.hover(lit)
	t.check(is_equal_approx(float(aim.area().r), 0.8) and aim.ring_tag() == "LIGHT", "doom's ring on lit ground: 0.8, LIGHT")
	aim.pick(1)
	aim.hover(p)
	t.check(is_equal_approx(float(aim.area().r), 7.0), "Unseen Hour's on dusk: 7")
	aim.pick(2)
	t.check(is_equal_approx(float(aim.area().r), float(Targeting.AREAS["smite"].r)) and aim.ring_tag() == "", "smite's is its own, no tag")
	crowd.dusk.end(id)
	aim.free()
	rules.free()


## Each stub builds and lands its dusk, with a crowd and without one (the VFX Sandbox).
static func _stubs(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var grid: WalkGrid = made[2]
	var p := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var bare := FxContext.new()
	bare.rng = RandomNumberGenerator.new()
	bare.overhead = Node2D.new()
	bare.ground = Node2D.new()
	var bad := []
	for path: String in ["slumber", "cloak_of_night", "dreamless", "dread_of_the_dark", "shadow_play", "the_swallowing_dark", "evernight"]:
		var before := crowd.dusk.count()
		var fx: FxTimeline = FxTimeline.cast(load("res://src/fx/veil/%s.gd" % path), ctx, p)
		if fx == null or crowd.dusk.count() != before + 1 or not crowd.dusk.covers(p + Vector2(2.9, 0.0)):
			bad.append(path)
		if fx != null:
			fx.free()
		var lone: FxTimeline = FxTimeline.cast(load("res://src/fx/veil/%s.gd" % path), bare, p)
		if lone == null:
			bad.append(path + " (no crowd)")
		else:
			lone.free()
	t.check(bad.is_empty(), "each stub lands its dusk, and builds with no crowd (%s)" % [bad])
	bare.overhead.free()
	bare.ground.free()
	crowd.dusk.clear()
