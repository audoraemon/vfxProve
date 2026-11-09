extends RefCounted
## Dominion's ten powers have five ability levels (the Dominion ability levels spec, "DS"): each power's levels table holds exactly DS's
## numbers, level 1 is the effect's own constants (so nothing already recorded moves), a cast reads its level through PowerBook.stat(),
## the cooldown is the level's, the twist gate is level 5 only, and the previews and the tree's text follow the level. The twists
## themselves have their own files (test_dominion_twist_<key>.gd).

const KEYS := ["whisper", "discord", "madness", "wisp", "clearmind", "saint", "sanctuary", "anathema", "voice", "schism"]

## DS's tables: key -> stat -> the five levels (index 0 = level 1). "cooldown" is the row field; Divine Schism has none (once a night).
const DS := {
	"whisper": {"REACH": [10.0, 11.0, 12.0, 13.0, 14.0], "ATTACK_SECS": [10.0, 11.0, 12.0, 13.0, 14.0], "cooldown": [8.0, 7.5, 7.0, 6.5, 6.0]},
	"discord": {"DISCORD_R": [1.2, 1.3, 1.4, 1.5, 1.6], "DISCORD_TIME": [15.0, 16.0, 17.0, 18.0, 20.0],
		"cooldown": [30.0, 28.0, 26.0, 24.0, 22.0]},
	"madness": {"RADIUS": [1.5, 1.65, 1.8, 1.95, 2.1], "SEED": [0.02, 0.04, 0.06, 0.08, 0.10], "cooldown": [40.0, 38.0, 36.0, 34.0, 32.0]},
	"wisp": {"LURE_MAX": [25, 27, 30, 32, 35], "WISP_TIME": [12.0, 13.0, 14.0, 15.0, 16.0],
		"ENTHRALL_TIME": [30.0, 32.0, 34.0, 37.0, 40.0], "cooldown": [30.0, 28.0, 26.0, 25.0, 24.0]},
	"clearmind": {"RADIUS": [5.0, 5.4, 5.8, 6.2, 6.5], "TRANCE_TIME": [30.0, 32.0, 34.0, 37.0, 40.0],
		"cooldown": [60.0, 57.0, 54.0, 51.0, 48.0]},
	"saint": {"RADIUS": [6.0, 6.4, 6.8, 7.2, 7.5], "SPAN": [30.0, 32.0, 34.0, 37.0, 40.0], "cooldown": [60.0, 57.0, 54.0, 51.0, 48.0]},
	"sanctuary": {"MAX_GUARDS": [40, 44, 48, 52, 55], "SPAN": [40.0, 44.0, 48.0, 52.0, 55.0], "PICK_R": [5.0, 5.25, 5.5, 5.75, 6.0],
		"cooldown": [90.0, 86.0, 82.0, 78.0, 74.0]},
	"anathema": {"RADIUS": [6.0, 6.4, 6.8, 7.2, 7.5], "SPAN": [40.0, 44.0, 48.0, 52.0, 55.0], "cooldown": [90.0, 86.0, 82.0, 78.0, 74.0]},
	"voice": {"COMMAND_X": [1.0, 1.1, 1.2, 1.3, 1.4], "GATHER_CAPACITY": [150, 160, 175, 185, 200],
		"cooldown": [180.0, 170.0, 160.0, 150.0, 140.0]},
	"schism": {"REGION": [14.0, 15.0, 16.0, 17.0, 18.0], "MAX_FIGHTERS": [140, 150, 160, 170, 180], "DURATION": [25.0, 27.0, 29.0, 32.0, 35.0]},
}
## DS's Might column for levels 1-5.
const DS_MIGHT := {
	"whisper": [1, 1, 2, 2, 3], "discord": [2, 2, 3, 3, 4], "madness": [2, 2, 3, 3, 4], "wisp": [2, 2, 3, 3, 4],
	"clearmind": [3, 3, 4, 4, 5], "saint": [3, 3, 4, 4, 5], "sanctuary": [4, 4, 5, 5, 6], "anathema": [4, 4, 5, 5, 6],
	"voice": [5, 5, 6, 6, 7], "schism": [6, 6, 7, 7, 8],
}
## The twist texts (plan D7).
const TWISTS := {
	"whisper": "Held String: whisper the same one again", "discord": "Tangled Threads: forgetting spreads one hop",
	"madness": "Directed Frenzy: the broken hunt soldiers", "wisp": "Procession: click again to lead the light",
	"clearmind": "Sleepwalk: click again to walk the entranced", "saint": "Passed Mark: the mark outlives its bearer",
	"sanctuary": "Pressed into Service: intruders guard", "anathema": "Spreading Mark: spreads to buildings near",
	"voice": "Second Word: click again for a second command", "schism": "Turn the Tide: click a fighter to turn them",
}
## The consts a table's level 1 must equal, with their type: key -> stat -> the effect's own number.
const BASE := {
	"whisper": {"REACH": MindWhisperFx.REACH, "ATTACK_SECS": MindWhisperFx.ATTACK_SECS},
	"discord": {"DISCORD_R": DiscordFx.DISCORD_R, "DISCORD_TIME": DiscordFx.DISCORD_TIME},
	"madness": {"RADIUS": MadnessBloomFx.RADIUS, "SEED": MadnessBloomFx.SEED},
	"wisp": {"LURE_MAX": WillOWisp.LURE_MAX, "WISP_TIME": WillOWisp.WISP_TIME, "ENTHRALL_TIME": WillOWisp.ENTHRALL_TIME},
	"clearmind": {"RADIUS": ClearMindFx.RADIUS, "TRANCE_TIME": ClearMindFx.TRANCE_TIME},
	"saint": {"RADIUS": SaintFx.RADIUS, "SPAN": SaintFx.SPAN},
	"sanctuary": {"MAX_GUARDS": SacredSanctuaryFx.MAX_GUARDS, "SPAN": SacredSanctuaryFx.SPAN, "PICK_R": SacredSanctuaryFx.PICK_R},
	"anathema": {"RADIUS": AnathemaFx.RADIUS, "SPAN": AnathemaFx.SPAN},
	"voice": {"COMMAND_X": VoiceOfGodFx.COMMAND_X, "GATHER_CAPACITY": VoiceOfGodFx.GATHER_CAPACITY},
	"schism": {"REGION": DivineSchismFx.REGION, "MAX_FIGHTERS": DivineSchismFx.MAX_FIGHTERS, "DURATION": DivineSchismFx.DURATION},
}


static func run(t) -> void:
	_shapes(t)
	_level_one(t)
	_might(t)
	_cooldown_at_level(t)
	_cast_reads_level3(t)
	_twist_gate(t)
	_previews(t)
	_tree_text(t)
	_person_hooks(t)


# --- A world to cast in -------------------------------------------------------------------------------------------------------

static func _world() -> Array:
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
	# Everyone far off in a corner and calm.
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		if not p.soldier:
			p.mind = Person.Mind.CALM
		i += 1
	return [crowd, env, grid, field, world, ctx, town]


static func _drop(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()
	(made[6] as Node).free()


## Send these people back to a corner of their own, calm, out of every later cast's way.
static func _stow(crowd: Crowd, people: Array) -> void:
	for p: Person in people:
		p.stop_fighting()
		p.release_compulsion()
		p.clear_badge()
		var i := crowd.citizens.find(p)
		p.ground_pos = Vector2(-27.0 + float(i % 40) * 0.3, -19.0 - float(i / 40) * 0.3)
		p.mind = Person.Mind.CALM


static func _cast(path: String, ctx: FxContext, at: Vector2, extra: Dictionary) -> FxTimeline:
	return FxTimeline.cast(load(path), ctx, at, extra)


# --- The tables ---------------------------------------------------------------------------------------------------------------

static func _shapes(t) -> void:
	for key: String in KEYS:
		var row := PowerBook.get_power(key)
		t.check(PowerBook.has_levels(key) and PowerBook.levels_problems(row).is_empty(),
			"%s has a valid levels table (%s)" % [key, PowerBook.levels_problems(row)])
		var want: Array = DS[key].keys()
		want.sort()
		var table: Array = row.levels
		for lv in PowerBook.MAX_LEVEL:
			var have: Array = []
			for stat_name: String in (table[lv] as Dictionary):
				if not PowerBook.TWIST_KEYS.has(stat_name):
					have.append(stat_name)
			have.sort()
			t.check(have == want, "%s level %d names exactly DS's stats (%s)" % [key, lv + 1, have])
			var carries := (table[lv] as Dictionary).has("twist") or (table[lv] as Dictionary).has("twist_text")
			t.check(carries == (lv == PowerBook.MAX_LEVEL - 1), "%s: only level 5 carries the twist (level %d)" % [key, lv + 1])
		var might_key := false
		for stat_name: String in (table[0] as Dictionary):
			might_key = might_key or stat_name.to_lower() == "might" or stat_name == "dp"
		t.check(not might_key, "%s: no Might key in the table (Might is PowerBook.might())" % key)
		var text := PowerBook.twist(key)
		var room := SkillTreeScreen.DETAIL.size.x - 16.0 - UiTheme.width("Level 5   ", UiTheme.SIZE_SMALL)
		t.check(text != "" and text == String(TWISTS[key]) and text == String((table[4] as Dictionary).twist_text)
			and UiTheme.width(text, UiTheme.SIZE_SMALL) <= room,
			"%s: the twist is D7's text and fits the tree's detail line (%d chars, %.0f of %.0f px)" % [key, text.length(),
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
		for stat_name: String in DS[key]:
			for lv in PowerBook.MAX_LEVEL:
				var want: Variant = DS[key][stat_name][lv]
				var have: Variant = (row.levels[lv] as Dictionary)[stat_name]
				t.check(have == want and typeof(have) == typeof(want), "%s %s at level %d is DS's %s (%s)" % [key, stat_name, lv + 1, want, have])
	t.check(typeof(WillOWisp.LURE_MAX) == TYPE_INT and typeof(SacredSanctuaryFx.MAX_GUARDS) == TYPE_INT
		and typeof(VoiceOfGodFx.GATHER_CAPACITY) == TYPE_INT and typeof(DivineSchismFx.MAX_FIGHTERS) == TYPE_INT
		and typeof(PowerBook.level_stat("wisp", 5, "LURE_MAX", 0)) == TYPE_INT
		and typeof(PowerBook.level_stat("sanctuary", 5, "MAX_GUARDS", 0)) == TYPE_INT
		and typeof(PowerBook.level_stat("voice", 5, "GATHER_CAPACITY", 0)) == TYPE_INT
		and typeof(PowerBook.level_stat("schism", 5, "MAX_FIGHTERS", 0)) == TYPE_INT and VoiceOfGodFx.COMMAND_X == 1.0,
		"LURE_MAX, MAX_GUARDS, GATHER_CAPACITY and MAX_FIGHTERS stay int; COMMAND_X is 1.0")
	t.check(PowerBook.cooldown("schism", 5) == 999.0 and PowerBook.cooldown("schism", 1) == 999.0,
		"Divine Schism stays 999 (once a night) at every level")


static func _might(t) -> void:
	for key: String in KEYS:
		for lv in PowerBook.MAX_LEVEL:
			t.check(PowerBook.might(key, lv + 1) == int(DS_MIGHT[key][lv]),
				"%s level %d costs DS's %d Might (%d)" % [key, lv + 1, DS_MIGHT[key][lv], PowerBook.might(key, lv + 1)])
	t.check(PowerBook.might("voice", 5) + PowerBook.might("schism", 5) == 15, "Voice 7 + Schism 8 = 15 at level 5, under the cap of 16")


## Rules with Mind Whisper and Will-o'-Wisp and a caster that only records: the cooldown a cast starts is the slot's level's.
static func _cooldown_at_level(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var rules := Rules.new().setup(PackedStringArray(["whisper", "wisp"]), null, made[1], made[3], crowd, made[6], MissionBook.last_judgement())
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline:
		return null
	rules.levels = {"whisper": 3, "wisp": 5}
	var who: Person = crowd.citizens[0]
	rules.cast(0, who.ground_pos, {"target": who, "to": who.ground_pos})
	t.check(is_equal_approx(rules.cooldown_left(0), 7.0) and is_equal_approx(rules.cooldown_of(0), 7.0),
		"levels {whisper 3}: a whisper casts into 7 s (%s)" % rules.cooldown_left(0))
	rules.cast(1, Vector2(10, 10), {"mode": "lure"})
	t.check(is_equal_approx(rules.cooldown_of(1), 24.0) and is_equal_approx(rules.cooldown_left(1), 24.0),
		"levels {wisp 5}: a LURE cast waits 24 s (%s)" % rules.cooldown_left(1))
	rules.advance(30.0)
	rules.cast(1, Vector2(10, 10), {"mode": "enthrall"})
	t.check(is_equal_approx(rules.cooldown_left(1), 75.0) and is_equal_approx(rules.cooldown_of(1), 75.0),
		"an ENTHRALL cast waits its own 75 s at level 5 too (%s)" % rules.cooldown_left(1))
	rules.free()
	_drop(made)


## A cast at level 3 reads the level-3 numbers.
static func _cast_reads_level3(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var grid: WalkGrid = made[2]
	var env: EnvironmentField = made[1]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var at2 := at + Vector2(0.0, 12.0)
	var next := 0

	# Mind Whisper: the attack order lasts 12 s at level 3 (10 at level 1).
	var a: Person = crowd.citizens[next]
	var b: Person = crowd.citizens[next + 1]
	next += 2
	a.ground_pos = at
	b.ground_pos = at + Vector2(3.0, 0.0)
	var whisper: MindWhisperFx = _cast("res://src/fx/dominion/mind_whisper.gd", ctx, at, {"target": a, "order": "attack", "foe": b, "level": 3})
	t.check(is_equal_approx(whisper.lv_attack_secs, 12.0) and is_equal_approx(a._fight_left, 12.0),
		"Whisper level 3: the attack order lasts 12 s (%s)" % a._fight_left)
	whisper.free()
	_stow(crowd, [a, b])
	var c: Person = crowd.citizens[next]
	var d: Person = crowd.citizens[next + 1]
	next += 2
	c.ground_pos = at2
	d.ground_pos = at2 + Vector2(3.0, 0.0)
	var plain: MindWhisperFx = _cast("res://src/fx/dominion/mind_whisper.gd", ctx, at2, {"target": c, "order": "attack", "foe": d})
	t.check(is_equal_approx(plain.lv_attack_secs, MindWhisperFx.ATTACK_SECS) and is_equal_approx(c._fight_left, 10.0),
		"and 10 s at level 1 (%s)" % c._fight_left)
	plain.free()
	_stow(crowd, [c, d])

	# Discord: the circle is 1.4 at level 3 (a person 1.35 away is taken; not at level 1), and they forget for 17 s.
	var near: Person = crowd.citizens[next]
	var near1: Person = crowd.citizens[next + 1]
	next += 2
	near.ground_pos = at + Vector2(1.35, 0.0)
	near1.ground_pos = at2 + Vector2(1.35, 0.0)
	var discord: DiscordFx = _cast("res://src/fx/quiet/discord.gd", ctx, at, {"level": 3})
	t.check(is_equal_approx(discord.lv_discord_r, 1.4) and is_equal_approx(discord.lv_discord_time, 17.0)
		and near.mind == Person.Mind.CONFUSED and is_equal_approx(near.confused_left(), 17.0),
		"Discord level 3: a person 1.35 away is confused for 17 s (%s)" % near.confused_left())
	var discord1: DiscordFx = _cast("res://src/fx/quiet/discord.gd", ctx, at2, {})
	t.check(near1.mind != Person.Mind.CONFUSED and is_equal_approx(discord1.lv_discord_r, DiscordFx.DISCORD_R),
		"and at level 1 the same distance is out of the circle")
	discord.free()
	discord1.free()
	_stow(crowd, [near, near1])

	# Madness Bloom: the seed is 0.06 at level 3 and the circle 1.8 (a person 1.7 away is taken).
	var mad: Person = null
	for k in range(next, crowd.citizens.size()):
		if not MadnessManager.RESISTANCE.has(MadnessManager.kind_of(crowd.citizens[k])):
			mad = crowd.citizens[k]
			next = k + 1
			break
	mad.ground_pos = at + Vector2(1.7, 0.0)
	var bloom: MadnessBloomFx = _cast("res://src/fx/curse/madness_bloom.gd", ctx, at, {"level": 3})
	t.check(is_equal_approx(bloom.lv_radius, 1.8) and is_equal_approx(bloom.lv_seed, 0.06) and bloom.afflicted.has(mad)
		and is_equal_approx(float(mad.statuses[MadnessManager.STATUS]), 0.06),
		"Madness level 3: a person 1.7 away is seeded at 0.06")
	bloom.free()
	_stow(crowd, [mad])

	# Will-o'-Wisp: 30 of 31 calm people are drawn at level 3 (25 at level 1); the light burns 14 s, ENTHRALL 34.
	var calm: Array[Person] = []
	for k in 31:
		var p: Person = crowd.citizens[next + k]
		p.mind = Person.Mind.CALM
		p.ground_pos = at + Vector2(0.15 * float(k % 10) - 0.7, 0.3 * float(k / 10) + 1.0)
		calm.append(p)
	next += 31
	t.check(WillOWisp.drawn(field, at, 30).size() == 30 and WillOWisp.drawn(field, at).size() == WillOWisp.LURE_MAX,
		"Wisp drawn(..., 30) caps 30 of 31 calm people; the default is LURE_MAX")
	var wisp: WillOWisp = _cast("res://src/fx/control/will_o_wisp.gd", ctx, at, {"level": 3})
	var lured := 0
	for p in calm:
		lured += 1 if p.lured() else 0
	t.check(wisp.lv_lure_max == 30 and lured == 30 and is_equal_approx(wisp.duration, 14.0) and is_equal_approx(wisp.lv_wisp_time, 14.0),
		"Wisp level 3: lures 30 for 14 s (%d lured, duration %.1f)" % [lured, wisp.duration])
	wisp.free()
	var held: WillOWisp = _cast("res://src/fx/control/will_o_wisp.gd", ctx, at, {"level": 3, "mode": "enthrall"})
	t.check(is_equal_approx(held.duration, 34.0) and is_equal_approx(held.lv_enthrall_time, 34.0), "and ENTHRALL holds 34 s (%.1f)" % held.duration)
	held.end_now()
	held.free()
	_stow(crowd, calm)

	# Clear Mind: the trance lasts 34 s at level 3.
	var trance: ClearMindFx = _cast("res://src/fx/dominion/clear_mind.gd", ctx, at, {"level": 3})
	t.check(is_equal_approx(trance.duration, ClearMindFx.T_CAST + 34.0 + 0.5) and is_equal_approx(trance.lv_radius, 5.8),
		"Clear Mind level 3: duration T_CAST + 34 + 0.5, circle 5.8 (%.2f)" % trance.duration)
	trance.free()

	# Saint or Sinner: span 34 s, and a person 6.6 from the chosen joins (circle 6.8; 6.0 at level 1).
	var chosen: Person = crowd.citizens[next]
	var joiner: Person = crowd.citizens[next + 1]
	var chosen1: Person = crowd.citizens[next + 2]
	var joiner1: Person = crowd.citizens[next + 3]
	next += 4
	chosen.ground_pos = at
	joiner.ground_pos = at + Vector2(6.6, 0.0)
	chosen1.ground_pos = at2
	joiner1.ground_pos = at2 + Vector2(6.6, 0.0)
	var saint: SaintFx = _cast("res://src/fx/dominion/saint_or_sinner.gd", ctx, at, {"level": 3, "mode": "sinner"})
	saint._process(SaintFx.T_CAST + 0.05)
	t.check(is_equal_approx(saint.duration, SaintFx.T_CAST + 34.0 + 0.5) and saint.people.has(joiner),
		"Saint level 3: duration T_CAST + 34 + 0.5, and a person at 6.6 from the chosen joins")
	var saint1: SaintFx = _cast("res://src/fx/dominion/saint_or_sinner.gd", ctx, at2, {"mode": "sinner"})
	saint1._process(SaintFx.T_CAST + 0.05)
	t.check(not saint1.people.has(joiner1) and is_equal_approx(saint1.duration, SaintFx.T_CAST + SaintFx.SPAN + 0.5),
		"and at level 1 that person is outside the circle")
	saint.free()
	saint1.free()
	_stow(crowd, [chosen, joiner, chosen1, joiner1])
	for p in crowd.citizens:
		p.stop_fighting()

	# Sacred Sanctuary: 48 of 50 within 5.5 at level 3.
	var everyone: Array[Person] = []
	for k in 50:
		var p: Person = crowd.citizens[next + k]
		p.mind = Person.Mind.CALM
		p.ground_pos = at + Vector2.from_angle(TAU * float(k) / 50.0) * (1.0 + 4.4 * float(k % 5) / 4.0)
		everyone.append(p)
	next += 50
	t.check(SacredSanctuaryFx.picked_at(field, at).size() == 40 and SacredSanctuaryFx.picked_at(field, at, 5.5, 48).size() == 48
		and SacredSanctuaryFx.picked_at(field, at, 5.5, 60).size() == 50,
		"picked_at() defaults to level 1 (40 within 5.0) and takes the level's reach and cap (%d)" % SacredSanctuaryFx.picked_at(field, at).size())
	var sanct: SacredSanctuaryFx = _cast("res://src/fx/dominion/sacred_sanctuary.gd", ctx, at, {"level": 3, "to": at + Vector2(0.0, 8.0)})
	t.check(sanct.guards.size() == 48 and sanct.lv_max_guards == 48 and is_equal_approx(sanct.lv_pick_r, 5.5)
		and is_equal_approx(sanct.duration, SacredSanctuaryFx.T_CAST + 48.0 + 0.5),
		"Sanctuary level 3 picks 48 of 50 within 5.5, standing 48 s (%d)" % sanct.guards.size())
	sanct.free()
	_stow(crowd, everyone)

	# Anathema: a house 6.6 away is marked at level 3 (district 6.8; 6.0 at level 1), for 48 s.
	var house: Structure = crowd.shelters.shelters.keys()[0]
	var click := house.center() + Vector2(6.6, 0.0)
	var curse: AnathemaFx = _cast("res://src/fx/dominion/anathema.gd", ctx, click, {"level": 3, "mode": "cursed"})
	curse._process(AnathemaFx.T_CAST + 0.05)
	t.check(curse.buildings.has(house) and not AnathemaFx.marked_at(env, click).has(house) and AnathemaFx.marked_at(env, click, 6.8).has(house)
		and is_equal_approx(curse.duration, AnathemaFx.T_CAST + 48.0 + 0.5) and crowd.structure_mark(house) == AnathemaFx.CURSED,
		"Anathema level 3 marks a house 6.6 away, 48 s; level 1 would not (%d buildings)" % curse.buildings.size())
	curse.free()

	# Voice of God: a kneel lasts 12 x 1.2 s at level 3.
	var voice: VoiceOfGodFx = _cast("res://src/fx/dominion/voice_of_god.gd", ctx, at, {"level": 3, "mode": "kneel"})
	t.check(is_equal_approx(voice.seconds, 12.0 * 1.2) and voice.lv_gather_capacity == 175,
		"Voice level 3: a kneel is 12.0 x 1.2 s, the gather cap 175 (%.2f)" % voice.seconds)
	voice.free()
	var voice1: VoiceOfGodFx = _cast("res://src/fx/dominion/voice_of_god.gd", ctx, at, {"mode": "kneel"})
	t.check(voice1.seconds == 12.0, "and at level 1 it is exactly 12.0")
	voice1.free()

	# Divine Schism: 29 s at level 3, and a person 15.5 away is enlisted (region 16; 14 at level 1).
	var fighter: Person = null
	var fighter1: Person = null
	for k in range(next, crowd.citizens.size()):
		if DivineSchismFx.fights(crowd.citizens[k]):
			if fighter == null:
				fighter = crowd.citizens[k]
			else:
				fighter1 = crowd.citizens[k]
				break
	fighter.ground_pos = at + Vector2(15.5, 0.0)
	fighter1.ground_pos = at2 + Vector2(15.5, 0.0)
	var schism: DivineSchismFx = _cast("res://src/fx/dominion/divine_schism.gd", ctx, at, {"level": 3, "mode": "faction"})
	schism._process(DivineSchismFx.T_BREAK + 2.0)
	t.check(is_equal_approx(schism.duration, DivineSchismFx.T_BREAK + 29.0 + 0.5) and fighter.side != 0
		and schism.lv_max_fighters == 160 and is_equal_approx(schism.lv_region, 16.0),
		"Schism level 3: duration T_BREAK + 29 + 0.5, and a person 15.5 away is enlisted (side %d)" % fighter.side)
	var schism1: DivineSchismFx = _cast("res://src/fx/dominion/divine_schism.gd", ctx, at2, {"mode": "faction"})
	schism1._process(DivineSchismFx.T_BREAK + 2.0)
	t.check(fighter1.side == 0, "and at level 1 that person is outside the region")
	schism.free()
	schism1.free()
	_drop(made)


static func _twist_gate(t) -> void:
	var all := true
	for key: String in KEYS:
		all = all and PowerBook.twist_at({"level": 5}, key) and not PowerBook.twist_at({"level": 4}, key) \
			and not PowerBook.twist_at({"level": 6}, key) and not PowerBook.twist_at({}, key)
	t.check(all, "twist_at is true at level 5 of each of the ten, false at 4, 6 and with no level")


static func _previews(t) -> void:
	var same := true
	for key in ["discord", "madness", "clearmind", "anathema", "sanctuary"]:
		same = same and Targeting.area_at(key, 1) == Targeting.AREAS[key]
	t.check(same, "at level 1 the five previews cover exactly their AREAS entry")
	t.check(is_equal_approx(float(Targeting.area_at("discord", 5).r), 1.6) and is_equal_approx(float(Targeting.area_at("madness", 5).r), 2.1)
		and is_equal_approx(float(Targeting.area_at("clearmind", 4).r), 6.2) and is_equal_approx(float(Targeting.area_at("anathema", 5).r), 7.5),
		"Discord, Madness, Clear Mind and Anathema follow their stats")
	t.check(is_equal_approx(float(Targeting.area_at("sanctuary", 3).r), 5.5), "Sanctuary's circle is its PICK_R (5.5 at level 3)")
	t.check(Targeting.area_at("saint", 5) == Targeting.AREAS.saint, "Saint's pick has no levelled stat, so the preview is unchanged")
	var o := Vector2(1.0, 1.0)
	t.check(is_equal_approx(MindWhisperFx.clamp_to(null, o, o + Vector2(20.0, 0.0)).distance_to(o), 10.0)
		and is_equal_approx(MindWhisperFx.clamp_to(null, o, o + Vector2(20.0, 0.0), 14.0).distance_to(o), 14.0),
		"a whisper is clamped to REACH, or to the level's reach when given")


static func _tree_text(t) -> void:
	var got := PowerBook.level_change("wisp", 3)
	t.check(got == "lure cap 27 -> 30, lure time 13.0 -> 14.0, enthrall 32.0 -> 34.0, cooldown 28.0 -> 26.0", "Wisp 2 -> 3 names its four numbers (%s)" % got)
	var all_five := true
	var all_one := true
	for key: String in KEYS:
		all_five = all_five and PowerBook.level_change(key, 5).ends_with(PowerBook.twist(key))
		all_one = all_one and PowerBook.level_change(key, 1) == ""
	t.check(all_five and all_one, "level 5's change ends with the twist text; level 1 changes nothing")
	t.check(PowerBook.level_change("voice", 5).ends_with("Second Word: click again for a second command"), "Voice level 5 ends with D7's text")
	t.check(PowerBook.level_change("smite", 2) == "kill radius 0.6 -> 0.65, damage 45.0 -> 50.0, cooldown 10.0 -> 9.5",
		"Ruin's tree text is unchanged (%s)" % PowerBook.level_change("smite", 2))
	t.check(PowerBook.level_change("anathema", 2).begins_with("district 6.0 -> 6.4") and PowerBook.level_change("madness", 2).begins_with("radius 1.5 -> 1.65"),
		"Anathema's RADIUS reads as the district, Madness's as its radius")


static func _arrive(p: Person) -> void:
	if p.goal() != Vector2.INF:
		p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func _person_hooks(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	# Held String: with hold_string() the whisper wears off with no shake-off; without it, shaken for 20 s.
	var held: Person = crowd.citizens[0]
	var plain: Person = crowd.citizens[1]
	held.ground_pos = at
	plain.ground_pos = at + Vector2(3.0, 0.0)
	var spot := grid.nearest_walkable(at + Vector2(0.0, 2.0))
	t.check(held.whisper(spot, 8.0), "a whisper takes")
	held.hold_string()
	_arrive(held)
	held._think(8.5)
	t.check(held.mind != Person.Mind.WHISPERED and not held.shaken() and held.whisper(spot, 8.0),
		"a whisper held by hold_string() wears off with no shake-off, and another takes at once")
	plain.whisper(spot, 8.0)
	_arrive(plain)
	plain._think(8.5)
	t.check(plain.mind != Person.Mind.WHISPERED and plain.shaken() and not plain.whisper(spot, 8.0), "without it the person is shaken off as always")
	for i in 199:
		plain.tick(0.1)
	t.check(plain.shaken(), "still shaken at 19.9 s")
	plain.tick(0.2)
	t.check(not plain.shaken(), "and not past 20 s")
	# A whisper laid after hold_string() without it clears the flag.
	var again: Person = crowd.citizens[2]
	again.ground_pos = at + Vector2(-3.0, 0.0)
	again.whisper(spot, 8.0)
	again.hold_string()
	again.whisper(spot, 8.0)
	_arrive(again)
	again._think(8.5)
	t.check(again.shaken(), "a later whisper laid without hold_string() clears the flag (it shakes as always)")

	# relure(): a lured person's goal moves; a calm one is not touched.
	var lured: Person = crowd.citizens[3]
	var calm: Person = crowd.citizens[4]
	lured.ground_pos = at + Vector2(1.0, 0.0)
	calm.ground_pos = at + Vector2(-1.0, 0.0)
	lured.mind = Person.Mind.CALM
	calm.mind = Person.Mind.CALM
	var elsewhere := grid.nearest_walkable(at + Vector2(0.0, -3.0))
	t.check(lured.lure(at, 10.0) and lured.relure(elsewhere) and lured.goal().distance_to(elsewhere) < 0.5 and lured.mind == Person.Mind.OBSERVE,
		"relure() on a lured person moves its goal and keeps it staring")
	t.check(not calm.relure(elsewhere), "and is false for a calm one")

	# Sleepwalk needs no hook: an entranced person compelled to a spot keeps its trance.
	var walker: Person = crowd.citizens[5]
	walker.ground_pos = at + Vector2(2.0, 2.0)
	walker.mind = Person.Mind.CALM
	t.check(walker.entrance(30.0), "a person is entranced")
	walker.compel(elsewhere, 20.0, Person.WILL_ABSOLUTE, ClearMindFx.CALM, false, &"", ClearMindFx.TRANCE)
	t.check(walker.mind == Person.Mind.COMPELLED and walker.fearless_left > 29.0, "and compelled to a spot, keeps fearless_left (%.1f)" % walker.fearless_left)
	_drop(made)
