extends RefCounted
## Ruin's ten powers have five ability levels (the Ruin ability levels spec, "RS"): each power's levels table holds exactly RS's
## numbers, level 1 is the effect's own constants (so nothing already recorded moves), a cast reads its level through PowerBook.stat(),
## the cooldown is the level's, the twist gate is level 5 only, and the previews and the tree's text follow the level.

const FxStage := preload("res://tests/fx_stage.gd")
const TornadoFx := preload("res://src/fx/set2/tornado_tempest.gd")
const DragonFx := preload("res://src/fx/set2/dragonfire_parade.gd")
const TsunamiFx := preload("res://src/fx/set2/tsunami_breaker.gd")
const CinderFx := preload("res://src/fx/set2/cinderfall_barrage.gd")

const KEYS := ["smite", "ember", "tornado", "scatter", "solaris", "dragon", "tsunami", "cinder", "tempest", "shatter"]

## RS's tables: key -> stat -> the five levels (index 0 = level 1). "cooldown" is the row field; Tempest and Earthshatter have none.
const RS := {
	"smite": {"KILL_R": [0.6, 0.65, 0.7, 0.75, 0.8], "DAMAGE": [45.0, 50.0, 55.0, 60.0, 65.0], "cooldown": [10.0, 9.5, 9.0, 8.5, 8.0]},
	"ember": {"START_LEVEL": [0.45, 0.5, 0.55, 0.6, 0.65], "REACH": [1.0, 1.0, 1.2, 1.2, 1.4], "cooldown": [15.0, 14.0, 13.0, 12.0, 11.0]},
	"tornado": {"PULL_RADIUS": [3.2, 3.4, 3.6, 3.8, 4.0], "LIFETIME": [10.0, 11.0, 12.0, 13.0, 14.0],
		"cooldown": [45.0, 45.0, 42.0, 40.0, 38.0]},
	"scatter": {"BLASTS": [12, 13, 14, 15, 16], "KILL_R": [0.9, 0.9, 1.0, 1.0, 1.1], "cooldown": [30.0, 29.0, 28.0, 27.0, 25.0]},
	"solaris": {"RADIUS": [2.2, 2.4, 2.6, 2.8, 3.0], "BEAM_TIME": [5.0, 5.0, 5.5, 6.0, 6.5],
		"cooldown": [105.0, 100.0, 100.0, 95.0, 90.0]},
	"dragon": {"BREATH_TIME": [2.4, 2.6, 2.8, 3.0, 3.2], "SWEEP_ARC": [1.0, 1.0, 1.1, 1.2, 1.3],
		"cooldown": [54.0, 52.0, 50.0, 48.0, 46.0]},
	"tsunami": {"LENGTH": [6.5, 7.0, 7.5, 8.0, 8.5], "WIDTH": [8.0, 8.5, 9.0, 10.0, 11.0], "cooldown": [60.0, 58.0, 55.0, 53.0, 50.0]},
	"cinder": {"STONES": [20, 22, 24, 26, 28], "RADIUS": [5.8, 5.8, 6.2, 6.6, 7.0], "cooldown": [75.0, 72.0, 70.0, 66.0, 62.0]},
	"tempest": {"STORM_TIME": [25.0, 27.0, 29.0, 31.0, 33.0],
		"VOLLEY": [Vector2i(5, 7), Vector2i(5, 7), Vector2i(6, 8), Vector2i(6, 8), Vector2i(7, 9)],
		"VOLLEY_EVERY": [1.3, 1.3, 1.3, 1.2, 1.2]},
	"shatter": {"MAX_LENGTH": [18.0, 20.0, 22.0, 24.0, 26.0], "HALF": [1.1, 1.2, 1.2, 1.3, 1.4], "SPEED": [2.0, 2.0, 2.2, 2.2, 2.5]},
}
## RS's Might column for levels 1-5.
const RS_MIGHT := {
	"smite": [1, 1, 2, 2, 3], "ember": [1, 1, 2, 2, 3], "tornado": [3, 3, 4, 4, 5], "scatter": [2, 2, 3, 3, 4],
	"solaris": [4, 4, 5, 5, 6], "dragon": [3, 3, 4, 4, 5], "tsunami": [4, 4, 5, 5, 6], "cinder": [4, 4, 5, 5, 6],
	"tempest": [5, 5, 6, 6, 7], "shatter": [5, 5, 6, 6, 7],
}
## The consts a table's level 1 must equal, with their type: key -> stat -> the effect's own number.
const BASE := {
	"smite": {"KILL_R": SmiteFx.KILL_R, "DAMAGE": SmiteFx.DAMAGE},
	"ember": {"START_LEVEL": EmberFx.START_LEVEL, "REACH": EmberFx.REACH},
	"tornado": {"PULL_RADIUS": TornadoFx.PULL_RADIUS, "LIFETIME": TornadoFx.LIFETIME},
	"scatter": {"BLASTS": ScatterStrikeFx.BLASTS, "KILL_R": ScatterStrikeFx.KILL_R},
	"solaris": {"RADIUS": LightOfSolaris.RADIUS, "BEAM_TIME": LightOfSolaris.BEAM_TIME},
	"dragon": {"BREATH_TIME": DragonFx.BREATH_TIME, "SWEEP_ARC": DragonFx.SWEEP_ARC},
	"tsunami": {"LENGTH": TsunamiFx.LENGTH, "WIDTH": TsunamiFx.WIDTH},
	"cinder": {"STONES": CinderFx.STONES, "RADIUS": CinderFx.RADIUS},
	"tempest": {"STORM_TIME": TempestFx.STORM_TIME, "VOLLEY": TempestFx.VOLLEY, "VOLLEY_EVERY": TempestFx.VOLLEY_EVERY},
	"shatter": {"MAX_LENGTH": EarthshatterFx.MAX_LENGTH, "HALF": EarthshatterFx.HALF, "SPEED": EarthshatterFx.SPEED},
}


static func run(t) -> void:
	_shapes(t)
	_level_one(t)
	_might(t)
	_cooldown_at_level(t)
	_cast_reads_level3(t)
	_cast_reads_level3_staged(t)
	_twist_gate(t)
	_previews(t)
	_tree_text(t)


## A bare context for an effect that needs only the field and the ground (the rest of the stage is null: the effect plays unstaged).
static func _ctx(seed_value: int) -> FxContext:
	var env := EnvironmentField.new()
	var field := EnemyField.new()
	field.env = env
	field.bounds = Rect2(-30.0, -30.0, 60.0, 60.0)
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = seed_value
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return ctx


static func _drop(ctx: FxContext) -> void:
	ctx.field.clear()
	ctx.field.free()
	ctx.env.clear()
	ctx.env.free()
	ctx.overhead.free()
	ctx.ground.free()


static func _shapes(t) -> void:
	for key: String in KEYS:
		var row := PowerBook.get_power(key)
		t.check(PowerBook.has_levels(key) and PowerBook.levels_problems(row).is_empty(),
			"%s has a valid levels table (%s)" % [key, PowerBook.levels_problems(row)])
		var want: Array = RS[key].keys()
		want.sort()
		var table: Array = row.levels
		for lv in PowerBook.MAX_LEVEL:
			var have: Array = []
			for stat_name: String in (table[lv] as Dictionary):
				if not PowerBook.TWIST_KEYS.has(stat_name):
					have.append(stat_name)
			have.sort()
			t.check(have == want, "%s level %d names exactly RS's stats (%s)" % [key, lv + 1, have])
			var carries := (table[lv] as Dictionary).has("twist") or (table[lv] as Dictionary).has("twist_text")
			t.check(carries == (lv == PowerBook.MAX_LEVEL - 1), "%s: only level 5 carries the twist (level %d)" % [key, lv + 1])
		var might_key := false
		for stat_name: String in (table[0] as Dictionary):
			might_key = might_key or stat_name.to_lower() == "might" or stat_name == "dp"
		t.check(not might_key, "%s: no Might key in the table (Might is PowerBook.might())" % key)
		var text := PowerBook.twist(key)
		var room := SkillTreeScreen.DETAIL.size.x - 16.0 - UiTheme.width("Level 5   ", UiTheme.SIZE_SMALL)
		t.check(text != "" and text == String((table[4] as Dictionary).twist_text)
			and UiTheme.width(text, UiTheme.SIZE_SMALL) <= room,
			"%s: the twist is level 5's text and fits the tree's detail line (%d chars, %.0f of %.0f px)" % [key, text.length(),
				UiTheme.width(text, UiTheme.SIZE_SMALL), room])


static func _level_one(t) -> void:
	for key: String in KEYS:
		var row := PowerBook.get_power(key)
		for stat_name: String in BASE[key]:
			var base: Variant = BASE[key][stat_name]
			var got: Variant = PowerBook.level_stat(key, 1, stat_name, null)
			t.check(got == base and typeof(got) == typeof(base),
				"%s %s at level 1 is the effect's own const, same type (%s vs %s)" % [key, stat_name, got, base])
			t.check(PowerBook.stat({}, key, stat_name, null) == base and PowerBook.stat({"level": 1}, key, stat_name, null) == base,
				"%s %s: a cast with no level, or level 1, reads the const" % [key, stat_name])
		t.check(PowerBook.cooldown(key, 1) == float(row.cooldown), "%s: level 1's cooldown is the row's (%s)" % [key, PowerBook.cooldown(key, 1)])
		for stat_name: String in RS[key]:
			for lv in PowerBook.MAX_LEVEL:
				var want: Variant = RS[key][stat_name][lv]
				var have: Variant = (row.levels[lv] as Dictionary)[stat_name]
				t.check(have == want and typeof(have) == typeof(want), "%s %s at level %d is RS's %s (%s)" % [key, stat_name, lv + 1, want, have])
	t.check(typeof(PowerBook.level_stat("scatter", 1, "BLASTS", 0)) == TYPE_INT and typeof(PowerBook.level_stat("cinder", 5, "STONES", 0)) == TYPE_INT
		and PowerBook.level_stat("tempest", 1, "VOLLEY", Vector2i.ZERO) == TempestFx.VOLLEY,
		"BLASTS and STONES stay int, VOLLEY stays a Vector2i")
	t.check(PowerBook.cooldown("tempest", 5) == 999.0 and PowerBook.cooldown("shatter", 3) == 999.0 and PowerBook.cooldown("nosuch", 3) == 0.0
		and PowerBook.cooldown("doom", 5) == 10.0,
		"Tempest and Earthshatter stay 999 at every level, an unknown key is 0.0, a power with no table keeps its cooldown")


static func _might(t) -> void:
	for key: String in KEYS:
		for lv in PowerBook.MAX_LEVEL:
			t.check(PowerBook.might(key, lv + 1) == int(RS_MIGHT[key][lv]),
				"%s level %d costs RS's %d Might (%d)" % [key, lv + 1, RS_MIGHT[key][lv], PowerBook.might(key, lv + 1)])


## Rules with two Ruin powers and a caster that only records: the cooldown a cast starts is the slot's level's.
static func _cooldown_at_level(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	var rules := Rules.new().setup(PackedStringArray(["smite", "tornado"]), null, env, field, crowd, town, MissionBook.last_judgement())
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline:
		return null
	rules.cast(0, Vector2(10, 10))
	t.check(is_equal_approx(rules.cooldown_left(0), 10.0) and is_equal_approx(rules.cooldown_of(0), 10.0)
		and is_equal_approx(rules.cooldown_of(1), 45.0),
		"with no levels: Smite 10 s, Tornado 45 s (%s, %s)" % [rules.cooldown_left(0), rules.cooldown_of(1)])
	rules.advance(20.0)
	rules.levels = {"smite": 3, "tornado": 5}
	rules.cast(0, Vector2(10, 10))
	t.check(is_equal_approx(rules.cooldown_left(0), 9.0) and is_equal_approx(rules.cooldown_of(1), 38.0) and rules.cooldown_left(1) == 0.0,
		"levels {smite 3, tornado 5}: Smite casts into 9 s, Tornado's full cooldown is 38 s (%s, %s)" % [rules.cooldown_left(0), rules.cooldown_of(1)])
	rules.advance(20.0)
	rules.cast(0, Vector2(10, 10), {"level": 5})
	t.check(is_equal_approx(rules.cooldown_left(0), 8.0), "a caller that sets the level gets that level's cooldown (%s)" % rules.cooldown_left(0))
	t.check(rules.cooldown_of(5) == 0.0 and rules.live_fx("smite") == null, "an empty slot has no cooldown; nothing is running")
	rules.teardown()
	rules.free()
	crowd.clear()
	field.clear()
	field.free()
	env.clear()
	env.free()
	town.free()
	crowd.free()
	world.free()


## The effects a bare context can play: a level-3 cast reads the level-3 numbers.
static func _cast_reads_level3(t) -> void:
	# Smite: 0.7 at level 3. A person 0.68 away dies at level 3 and lives at level 1.
	var ctx := _ctx(1)
	var near := DummyEnemy.new()
	near.ground_pos = Vector2(0.68, 0.0)
	ctx.field.add(near)
	var fx: SmiteFx = FxTimeline.cast(load("res://src/fx/ruin/smite.gd"), ctx, Vector2.ZERO, {"level": 3})
	t.check(is_equal_approx(fx.lv_kill_r, 0.7) and is_equal_approx(fx.lv_damage, 55.0), "Smite level 3 reads KILL_R 0.7 and DAMAGE 55")
	fx._process(SmiteFx.T_STRIKE + 0.05)
	t.check(not near.is_alive() and fx.struck == 1, "a person 0.68 away dies to a level-3 bolt")
	fx._process(3.0)
	fx.free()
	_drop(ctx)
	ctx = _ctx(1)
	near = DummyEnemy.new()
	near.ground_pos = Vector2(0.68, 0.0)
	ctx.field.add(near)
	fx = FxTimeline.cast(load("res://src/fx/ruin/smite.gd"), ctx, Vector2.ZERO)
	fx._process(SmiteFx.T_STRIKE + 0.05)
	t.check(is_equal_approx(fx.lv_kill_r, SmiteFx.KILL_R) and near.is_alive() and fx.struck == 0,
		"the same person lives at level 1 (kill radius %.2f)" % fx.lv_kill_r)
	fx._process(3.0)
	fx.free()
	_drop(ctx)

	# Scatter: 14 bursts at level 3 (12 at 1), the schedule and busy follow.
	ctx = _ctx(2)
	var scatter: ScatterStrikeFx = FxTimeline.cast(load("res://src/fx/ruin/scatter_strike.gd"), ctx, Vector2.ZERO, {"level": 3})
	t.check(scatter.points.size() == 14 and scatter.lv_blasts == 14 and is_equal_approx(scatter.lv_kill_r, 1.0)
		and is_equal_approx(scatter.busy, ScatterStrikeFx.T_FIRST + ScatterStrikeFx.BLAST_GAP * 14.0),
		"Scatter level 3 draws 14 points, kills within 1.0, locks the slots for 14 gaps (%d)" % scatter.points.size())
	scatter._process(10.0)
	t.check(scatter.blasts == 14, "and all 14 go (%d)" % scatter.blasts)
	scatter.free()
	_drop(ctx)

	# Solaris: the beam burns 5.5 s at level 3.
	ctx = _ctx(3)
	var sun: LightOfSolaris = FxTimeline.cast(load("res://src/fx/solaris/light_of_solaris.gd"), ctx, Vector2.ZERO, {"level": 3})
	t.check(is_equal_approx(sun.duration, LightOfSolaris.T_CHARGE + 5.5 + LightOfSolaris.AFTER) and is_equal_approx(sun.lv_radius, 2.6)
		and is_equal_approx(sun.lv_t_end, LightOfSolaris.T_CHARGE + 5.5),
		"Solaris level 3: radius 2.6, the beam lifts at T_CHARGE + 5.5 (duration %.2f)" % sun.duration)
	sun.free()
	_drop(ctx)

	# Tempest: the storm lasts 29 s at level 3.
	ctx = _ctx(4)
	var storm: TempestFx = FxTimeline.cast(load("res://src/fx/ruin/tempest.gd"), ctx, Vector2.ZERO, {"level": 3})
	t.check(is_equal_approx(storm.duration, TempestFx.T_GATHER + 29.0 + TempestFx.T_BREAK) and storm.lv_volley == Vector2i(6, 8)
		and is_equal_approx(storm.lv_volley_every, 1.3),
		"Tempest level 3: 29 s of storm, volleys of 6-8 (duration %.1f)" % storm.duration)
	storm.t = TempestFx.T_GATHER + 28.5
	t.check(storm.storming(), "and it is still storming 28.5 s in")
	storm.t = TempestFx.T_GATHER + 29.5
	t.check(not storm.storming(), "and over by 29.5 s")
	storm.free()
	_drop(ctx)

	# Earthshatter: a 30-unit run is clamped to 22 at level 3, at 2.2 a second.
	ctx = _ctx(5)
	var crack: EarthshatterFx = FxTimeline.cast(load("res://src/fx/ruin/earthshatter.gd"), ctx, Vector2.ZERO,
		{"to": Vector2(30.0, 0.0), "level": 3})
	t.check(is_equal_approx(crack.length, 22.0) and is_equal_approx(crack.busy, EarthshatterFx.T_CRACK + 22.0 / 2.2)
		and is_equal_approx(crack.lv_half, 1.2),
		"Earthshatter level 3: the run clamps to 22, the crawl takes 22 / 2.2 s (length %.1f)" % crack.length)
	crack.free()
	_drop(ctx)
	ctx = _ctx(5)
	crack = FxTimeline.cast(load("res://src/fx/ruin/earthshatter.gd"), ctx, Vector2.ZERO, {"to": Vector2(30.0, 0.0)})
	t.check(is_equal_approx(crack.length, EarthshatterFx.MAX_LENGTH) and is_equal_approx(crack.busy, EarthshatterFx.T_CRACK + 18.0 / 2.0),
		"and at level 1 it clamps to 18 as it always did")
	crack.free()
	_drop(ctx)

	# Ember: reach 1.2 at level 3 finds a house 1.1 away; level 1 finds none.
	ctx = _ctx(6)
	var house := ctx.env.add_structure(Rect2(Vector2(1.1, 0.0), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var ember: EmberFx = FxTimeline.cast(load("res://src/fx/ruin/ember.gd"), ctx, Vector2.ZERO, {"level": 3})
	t.check(is_equal_approx(ember.lv_reach, 1.2) and ember.fuel == house and is_equal_approx(ember.lv_start_level, 0.55),
		"Ember level 3: reach 1.2 picks a house 1.1 away, the fire starts at 0.55")
	ember.free()
	var plain: EmberFx = FxTimeline.cast(load("res://src/fx/ruin/ember.gd"), ctx, Vector2.ZERO)
	t.check(plain.fuel == null and is_equal_approx(plain.lv_reach, EmberFx.REACH), "at level 1 the same house is out of reach")
	plain.free()
	t.check(EmberFx.target(ctx.env, Vector2.ZERO) == null and EmberFx.target(ctx.env, Vector2.ZERO, 1.2) == house,
		"EmberFx.target() takes the reach, REACH by default")
	_drop(ctx)


## The set2 effects draw on the whole stage: a Battlefield (tests/fx_stage.gd) plays them headless.
static func _cast_reads_level3_staged(t) -> void:
	var bf := FxStage.make(7)
	var tornado = FxTimeline.cast(load("res://src/fx/set2/tornado_tempest.gd"), bf.ctx, Vector2(-12.0, -12.0), {"level": 3})
	t.check(is_equal_approx(tornado.lv_pull_radius, 3.6) and is_equal_approx(tornado.lv_lifetime, 12.0)
		and is_equal_approx(tornado.lv_t_end, TornadoFx.T_FORM + 12.0)
		and is_equal_approx(tornado.duration, TornadoFx.T_FORM + 12.0 + 2.8),
		"Tornado level 3: pull 3.6, 12 s of life (duration %.1f)" % tornado.duration)
	tornado._process(0.5)
	var dragon = FxTimeline.cast(load("res://src/fx/set2/dragonfire_parade.gd"), bf.ctx, Vector2(12.0, -12.0), {"level": 3})
	t.check(is_equal_approx(dragon.lv_breath_time, 2.8) and is_equal_approx(dragon.lv_sweep_arc, 1.1)
		and is_equal_approx(dragon.duration, 11.5 + 0.4),
		"Dragon level 3: a 2.8 s breath over 1.1 rad, the cast 0.4 s longer (duration %.2f)" % dragon.duration)
	dragon._process(0.5)
	var wave = FxTimeline.cast(load("res://src/fx/set2/tsunami_breaker.gd"), bf.ctx, Vector2(-12.0, 12.0), {"level": 3, "dir": Vector2(1, 0)})
	t.check(is_equal_approx(wave.lv_length, 7.5) and is_equal_approx(wave.lv_width, 9.0), "Tsunami level 3: 7.5 long, 9.0 wide")
	wave._process(0.5)
	var cinder = FxTimeline.cast(load("res://src/fx/set2/cinderfall_barrage.gd"), bf.ctx, Vector2(12.0, 12.0), {"level": 3})
	t.check(cinder.lv_stones == 24 and is_equal_approx(cinder.lv_radius, 6.2), "Cinder level 3: 24 stones over 6.2")
	cinder._process(0.5)
	FxStage.drop(bf)


static func _twist_gate(t) -> void:
	var all := true
	for key: String in KEYS:
		all = all and PowerBook.twist_at({"level": 5}, key) and not PowerBook.twist_at({"level": 4}, key) \
			and not PowerBook.twist_at({}, key) and not PowerBook.twist_at({"level": 1}, key)
	t.check(all, "twist_at is true at level 5 of each of the ten, false at 4, 1 and with no level")
	t.check(not PowerBook.twist_at({"level": 9}, "smite") and not PowerBook.twist_at({"level": 6}, "smite"), "and false above the top level (9, 6)")
	t.check(not PowerBook.twist_at({"level": 5}, "doom") and not PowerBook.twist_at({"level": 5}, "nosuch"),
		"and false for a power with no table, or no power")


static func _previews(t) -> void:
	t.check(Targeting.area_at("tornado", 1) == Targeting.AREAS.tornado and Targeting.area_at("tornado", 5).r == 4.0,
		"the tornado's circle is its PULL_RADIUS at the level (3.2 at 1, 4.0 at 5)")
	t.check(is_equal_approx(float(Targeting.area_at("tsunami", 4).half), 5.0) and is_equal_approx(float(Targeting.area_at("tsunami", 4).length), 8.0),
		"the tsunami's lane at level 4 is 8.0 long and 5.0 each side")
	t.check(Targeting.area_at("scatter", 5) == Targeting.AREAS.scatter and Targeting.area_at("heaven", 5) == Targeting.AREAS.heaven
		and Targeting.area_at("tempest", 5) == Targeting.AREAS.tempest,
		"a circle no table changes (Scatter's RADIUS), a power with no table and Tempest's mark are unchanged")
	var same := true
	for key: String in KEYS:
		same = same and Targeting.area_at(key, 1) == Targeting.AREAS[key]
	t.check(same, "at level 1 every one of the ten covers exactly its AREAS entry")
	t.check(is_equal_approx(float(Targeting.area_at("smite", 3).r), 0.7) and is_equal_approx(float(Targeting.area_at("ember", 5).r), 1.4)
		and is_equal_approx(float(Targeting.area_at("cinder", 5).r), 7.0) and is_equal_approx(float(Targeting.area_at("solaris", 5).r), 3.0)
		and is_equal_approx(float(Targeting.area_at("dragon", 5).arc), 1.3) and is_equal_approx(float(Targeting.area_at("shatter", 3).length), 22.0)
		and is_equal_approx(float(Targeting.area_at("shatter", 5).half), 1.4),
		"Smite, Ember, Cinder, Solaris, Dragon and Earthshatter follow their stats")
	t.check(Targeting.area_at("cinder", 5).inner == Targeting.AREAS.cinder.inner and Targeting.area_at("tornado", 5).roam == 7.0,
		"and keep the rest of their entry (the volcano's inner ring, the tornado's roam)")


static func _tree_text(t) -> void:
	var two := PowerBook.level_change("smite", 2)
	t.check(two == "kill radius 0.6 -> 0.65, damage 45.0 -> 50.0, cooldown 10.0 -> 9.5", "Smite 1 -> 2 names the three numbers (%s)" % two)
	var tempest := PowerBook.level_change("tempest", 3)
	t.check(tempest.contains("5-7 -> 6-8") and tempest.contains("storm 27.0 -> 29.0") and not tempest.contains("volley every"),
		"Tempest 2 -> 3 prints the volley as 5-7 -> 6-8 (%s)" % tempest)
	t.check(PowerBook.level_change("cinder", 3).contains("rain radius 5.8 -> 6.2") and PowerBook.level_change("solaris", 3).contains("radius 2.4 -> 2.6")
		and not PowerBook.level_change("solaris", 3).contains("rain"),
		"Cinderfall's RADIUS reads as the rain radius, Solaris's as its radius")
	var all_five := true
	var all_one := true
	for key: String in KEYS:
		all_five = all_five and PowerBook.level_change(key, 5).ends_with(PowerBook.twist(key))
		all_one = all_one and PowerBook.level_change(key, 1) == ""
	t.check(all_five and all_one, "level 5's change ends with the twist text; level 1 changes nothing")
	t.check(PowerBook.level_change("doom", 2) == PowerBook.NO_LEVELS, "a power with no table still says Levels to come")
	t.check(PrepareScreen.cooldown_text(PowerBook.get_power("smite"), 5) == "8 s" and PrepareScreen.cooldown_text(PowerBook.get_power("smite"), 2) == "9.5 s"
		and PrepareScreen.cooldown_text(PowerBook.get_power("smite")) == "10 s" and PrepareScreen.cooldown_text({"cooldown": 2.5}) == "2.5 s",
		"the cards print the level's cooldown (8 s at level 5, 9.5 s at 2)")
