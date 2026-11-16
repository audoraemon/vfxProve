extends RefCounted
## Death's ten powers have five ability levels (the Death and Decree ability levels spec, "DS"): each power's levels table holds
## exactly DS's numbers, level 1 is the effect's own constants (so nothing already recorded moves), a cast reads its level through
## PowerBook.stat(), the cooldown is the level's, the twist gate is level 5 only, and the previews follow the level. The twists
## themselves have their own files (test_death_twist_<key>.gd).

const RD := preload("res://tests/test_raise_dead.gd")

const KEYS := ["deathmark", "raise", "pestilence", "gravecall", "guise", "walker", "gatebelow", "pale", "serpent", "gravetide"]

## DS's tables: key -> stat -> the five levels (index 0 = level 1). "cooldown" is the row field; the Tier 5 pair has none (once a descent).
const DS := {
	"deathmark": {"MARK_TIME": [10.0, 9.5, 9.0, 8.5, 8.0], "GAWKERS": [8, 9, 10, 11, 12], "LOOK_R": [4.0, 4.25, 4.5, 4.75, 5.0],
		"cooldown": [20.0, 19.0, 18.0, 17.0, 16.0]},
	"raise": {"ZOMBIE_LIFE": [30.0, 32.0, 34.0, 36.0, 38.0], "CHAIN": [3, 3, 4, 4, 5], "SPIRIT_LIFE": [20.0, 21.0, 22.0, 23.0, 24.0],
		"cooldown": [25.0, 24.0, 23.0, 22.0, 21.0]},
	"pestilence": {"INFECT_MAX": [3, 3, 4, 4, 5], "INFECT_R": [1.2, 1.3, 1.4, 1.5, 1.6], "cooldown": [48.0, 46.0, 44.0, 42.0, 40.0]},
	"gravecall": {"SPIRITS": [3, 3, 4, 4, 5], "HAUNT": [20.0, 21.0, 22.0, 23.0, 24.0], "FREEZE": [3.0, 3.25, 3.5, 3.75, 4.0],
		"cooldown": [30.0, 29.0, 28.0, 27.0, 26.0]},
	"guise": {"MOST": [4, 4, 5, 5, 6], "MARK_R": [2.0, 2.1, 2.2, 2.3, 2.4], "SPAN": [25.0, 27.0, 29.0, 31.0, 33.0],
		"cooldown": [50.0, 48.0, 46.0, 44.0, 42.0]},
	"walker": {"WALK_LIFE": [40.0, 42.0, 44.0, 46.0, 48.0], "KILLS_MOST": [2, 2, 3, 3, 4], "ATTACK_R": [6.0, 6.25, 6.5, 6.75, 7.0],
		"cooldown": [30.0, 29.0, 28.0, 27.0, 26.0]},
	"gatebelow": {"REACH": [6.0, 6.25, 6.5, 6.75, 7.0], "EDGE": [4.2, 4.375, 4.55, 4.725, 4.9], "SPAN": [12.0, 12.5, 13.0, 13.5, 14.0],
		"WRAITH_TOUCHES": [3, 3, 4, 4, 5], "cooldown": [90.0, 87.0, 84.0, 81.0, 78.0]},
	"pale": {"RADIUS": [10.0, 10.25, 10.5, 10.75, 11.0], "SPAN": [16.0, 17.0, 18.0, 19.0, 20.0], "HORDE_KILLS": [24, 26, 28, 30, 32],
		"cooldown": [120.0, 116.0, 112.0, 108.0, 104.0]},
	"serpent": {"LENGTH": [14.0, 14.5, 15.0, 15.5, 16.0], "BAND": [2.0, 2.1, 2.2, 2.3, 2.4], "SIGHT": [12.0, 12.5, 13.0, 13.5, 14.0],
		"SICK": [20.0, 21.0, 22.0, 23.0, 24.0]},
	"gravetide": {"GIANT_LIFE": [60.0, 63.0, 66.0, 69.0, 72.0], "GIANT_BLOWS": [12, 13, 14, 15, 16], "SLAM_R": [3.5, 3.6, 3.7, 3.8, 4.0],
		"SLAM_WRECK": [60.0, 65.0, 70.0, 75.0, 80.0]},
}
## DS's Might column for levels 1-5.
const DS_MIGHT := {
	"deathmark": [1, 1, 2, 2, 3], "raise": [1, 1, 2, 2, 3], "pestilence": [3, 3, 4, 4, 5], "gravecall": [2, 2, 3, 3, 4],
	"guise": [3, 3, 4, 4, 5], "walker": [3, 3, 4, 4, 5], "gatebelow": [5, 5, 6, 6, 7], "pale": [6, 6, 7, 7, 8],
	"serpent": [6, 6, 7, 7, 8], "gravetide": [6, 6, 7, 7, 8],
}
## The twist texts: the tree's level column words them, so they must fit its detail line.
const TWISTS := {
	"deathmark": "The Wake: the body rises as a zombie", "raise": "Body and Soul: each half brings the other",
	"pestilence": "Foul Dead: its dead breathe plague 15 s", "gravecall": "Swelling Host: those who die there haunt too",
	"guise": "Deathless: a hidden one falls, then rises", "walker": "Borrowed Life: victims leave no body",
	"gatebelow": "Graves Answer: graves drag the living down", "pale": "The Pall Grows: each death widens the grey",
	"serpent": "Shed Skin: a sick band along its path", "gravetide": "Scattered Bones: the giant falls to skeletons",
}
## The consts a table's level 1 must equal, with their type: key -> stat -> the effect's own number.
const BASE := {
	"deathmark": {"MARK_TIME": DeathMarkFx.MARK_TIME, "GAWKERS": DeathMarkFx.GAWKERS, "LOOK_R": DeathMarkFx.LOOK_R},
	"raise": {"ZOMBIE_LIFE": RaiseTheDeadFx.ZOMBIE_LIFE, "CHAIN": RaiseTheDeadFx.CHAIN, "SPIRIT_LIFE": RaiseTheDeadFx.SPIRIT_LIFE},
	"pestilence": {"INFECT_MAX": PestilenceFx.INFECT_MAX, "INFECT_R": PestilenceFx.INFECT_R},
	"gravecall": {"SPIRITS": GravecallFx.SPIRITS, "HAUNT": GravecallFx.HAUNT, "FREEZE": GravecallFx.FREEZE},
	"guise": {"MOST": CorpseGuiseFx.MOST, "MARK_R": CorpseGuiseFx.MARK_R, "SPAN": CorpseGuiseFx.SPAN},
	"walker": {"WALK_LIFE": WalkingCorpseFx.WALK_LIFE, "KILLS_MOST": WalkingCorpseFx.KILLS_MOST, "ATTACK_R": WalkingCorpseFx.ATTACK_R},
	"gatebelow": {"REACH": TheGateBelowFx.REACH, "EDGE": TheGateBelowFx.EDGE, "SPAN": TheGateBelowFx.SPAN,
		"WRAITH_TOUCHES": DeathParts.WRAITH_TOUCHES},
	"pale": {"RADIUS": PaleReignFx.RADIUS, "SPAN": PaleReignFx.SPAN, "HORDE_KILLS": PaleReignFx.HORDE_KILLS},
	"serpent": {"LENGTH": PaleSerpentFx.LENGTH, "BAND": PaleSerpentFx.BAND, "SIGHT": PaleSerpentFx.SIGHT, "SICK": PaleSerpentFx.SICK},
	"gravetide": {"GIANT_LIFE": GraveTideFx.GIANT_LIFE, "GIANT_BLOWS": GraveTideFx.GIANT_BLOWS, "SLAM_R": GraveTideFx.SLAM_R,
		"SLAM_WRECK": GraveTideFx.SLAM_WRECK},
}
const INT_STATS := ["MOST", "CHAIN", "INFECT_MAX", "SPIRITS", "KILLS_MOST", "GAWKERS", "HORDE_KILLS", "GIANT_BLOWS", "WRAITH_TOUCHES"]


static func run(t) -> void:
	_shapes(t)
	_level_one(t)
	_might(t)
	_cooldown_at_level(t)
	_cast_reads_level3(t)
	_twist_gate(t)
	_previews(t)
	_tree_text(t)


# --- A world to cast in -------------------------------------------------------------------------------------------------------

## Everyone far off in a corner and calm (the raise-the-dead world, so a body can be laid).
static func _world() -> Array:
	var made := RD._setup()
	RD._clear_all(made)
	return made


## The nth citizen, set down at `at`, calm.
static func _put(made: Array, n: int, at: Vector2) -> Person:
	var p: Person = (made[0] as Crowd).citizens[n]
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	return p


## Walkable ground with room round it, away from the town's heart.
static func _spot(made: Array, i := 0) -> Vector2:
	return (made[2] as WalkGrid).nearest_walkable(TownLayout.MARKET_SQUARE.get_center() + Vector2(float(i) * 14.0, 0.0))


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
			and UiTheme.width(text, UiTheme.SIZE_SMALL) <= room and not text.contains(". "),
			"%s: the twist fits the tree's detail line (%d chars, %.0f of %.0f px)" % [key, text.length(),
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
		if DS[key].has("cooldown"):
			t.check(PowerBook.cooldown(key, 1) == float(row.cooldown), "%s: level 1's cooldown is the row's (%s)" % [key, PowerBook.cooldown(key, 1)])
		for stat_name: String in DS[key]:
			for lv in PowerBook.MAX_LEVEL:
				var want: Variant = DS[key][stat_name][lv]
				var have: Variant = (row.levels[lv] as Dictionary)[stat_name]
				t.check(have == want and typeof(have) == typeof(want), "%s %s at level %d is DS's %s (%s)" % [key, stat_name, lv + 1, want, have])
			var is_int := INT_STATS.has(stat_name)
			t.check(stat_name == "cooldown" or (typeof(DS[key][stat_name][0]) == (TYPE_INT if is_int else TYPE_FLOAT)),
				"%s %s keeps its type (int for counts, float for the rest)" % [key, stat_name])
	t.check(PowerBook.cooldown("serpent", 1) == PowerBook.cooldown("serpent", 5) and PowerBook.cooldown("gravetide", 1) == PowerBook.cooldown("gravetide", 5),
		"the Serpent and Grave Tide have no cooldown stat: once a descent at every level")
	t.check(PowerBook.stat({"level": 4}, "gatebelow", "EDGE", 0.0) == 4.725 and TheGateBelowFx.EDGE == 4.2,
		"The Gate Below's lip is a table stat (4.2 at level 1, not derived from REACH)")
	t.check(PaleReignFx.HORDE_CAP == 24 and PaleReignFx.MAX_RISEN == 16 and GraveTideFx.GRAVES_MOST == 24 and GraveTideFx.LIVING_CAP == 60
		and GraveTideFx.MOST == 30 and TheGateBelowFx.ARMS == 36 and RaiseTheDeadFx.RING_R == 3.0 and RaiseTheDeadFx.MOST == 8,
		"the frame's own caps stay at every level (HORDE_CAP, MAX_RISEN, GRAVES_MOST, LIVING_CAP, ARMS, the ring)")


static func _might(t) -> void:
	for key: String in KEYS:
		for lv in PowerBook.MAX_LEVEL:
			t.check(PowerBook.might(key, lv + 1) == int(DS_MIGHT[key][lv]),
				"%s level %d costs DS's %d Might (%d)" % [key, lv + 1, DS_MIGHT[key][lv], PowerBook.might(key, lv + 1)])
	t.check(PowerBook.might("serpent", 5) + PowerBook.might("gravetide", 5) == 16, "Serpent 8 + Grave Tide 8 = 16 at level 5, the cap")
	t.check(PowerBook.might("gatebelow", 5) + PowerBook.might("pale", 5) == 15, "Gate 7 + Pale 8 = 15 at level 5, under the cap of 16")


## Rules with Death Mark and Pestilence and a caster that only records: the cooldown a cast starts is the slot's level's.
static func _cooldown_at_level(t) -> void:
	var made := _world()
	var rules := Rules.new().setup(PackedStringArray(["deathmark", "pestilence", "serpent"]), null, made[1], made[3], made[0], made[6],
		MissionBook.last_judgement())
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline:
		return null
	rules.levels = {"deathmark": 3, "pestilence": 5}
	rules.cast(0, Vector2(10, 10), {})
	t.check(is_equal_approx(rules.cooldown_left(0), 18.0) and is_equal_approx(rules.cooldown_of(0), 18.0),
		"levels {deathmark 3}: a Death Mark casts into 18 s (%s)" % rules.cooldown_left(0))
	rules.cast(1, Vector2(10, 10), {})
	t.check(is_equal_approx(rules.cooldown_of(1), 40.0) and is_equal_approx(rules.cooldown_left(1), 40.0),
		"levels {pestilence 5}: a Pestilence cast waits 40 s (%s)" % rules.cooldown_left(1))
	rules.free()
	RD._done(made)


## A cast at level 3 reads the level-3 numbers (and level 1 the consts).
static func _cast_reads_level3(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var at := _spot(made, 0)
	var next := 0

	# Death Mark: 9 s to death, ten gawkers from 4.5 away (8, 4 at level 1).
	var victim := _put(made, next, at)
	next += 1
	var mark: DeathMarkFx = FxTimeline.cast(DeathMarkFx, ctx, at, {"level": 3}) as DeathMarkFx
	t.check(mark.marked == victim and is_equal_approx(mark.lv_mark_time, 9.0) and mark.lv_gawkers == 10 and is_equal_approx(mark.lv_look_r, 4.5)
		and is_equal_approx(mark.duration, 9.0 + DummyEnemy.BODY_HOLD),
		"Death Mark level 3: 9 s, 10 gawkers, drawn from 4.5 (%s, %s, %s)" % [mark.lv_mark_time, mark.lv_gawkers, mark.lv_look_r])
	mark.free()
	victim.statuses.erase(&"frail")
	victim.statuses.erase(&"slow")
	var at1 := at + Vector2(0.0, 12.0)
	var one := _put(made, next, at1)
	next += 1
	var mark1: DeathMarkFx = FxTimeline.cast(DeathMarkFx, ctx, at1, {}) as DeathMarkFx
	t.check(mark1.marked == one and mark1.lv_mark_time == DeathMarkFx.MARK_TIME and mark1.lv_gawkers == DeathMarkFx.GAWKERS
		and mark1.lv_look_r == DeathMarkFx.LOOK_R, "and level 1 reads the consts")
	mark1.free()
	one.statuses.erase(&"frail")
	one.statuses.erase(&"slow")

	# Raise the Dead: the zombies live 34 s and the chain is 4 (3 more may rise, not 2).
	var body := RD._body(made, next, at + Vector2(0.0, 24.0))
	next += 1
	var raise: RaiseTheDeadFx = FxTimeline.cast(RaiseTheDeadFx, ctx, body.pos, {"level": 3}) as RaiseTheDeadFx
	t.check(raise.lv_chain == 4 and raise._left == 3 and is_equal_approx(raise.lv_zombie_life, 34.0) and is_equal_approx(raise.lv_spirit_life, 22.0)
		and is_equal_approx(raise.duration, 34.0 + RaiseTheDeadFx.FADE),
		"Raise level 3: chain 4 (3 more may rise), zombies 34 s, spirits 22 s (%s, %s)" % [raise.lv_chain, raise.duration])
	raise.free()
	RD._clear_all(made)

	# Pestilence: 4 infected within 1.4 (3 within 1.2 at level 1).
	var sick: Array[Person] = []
	for k in 5:
		sick.append(_put(made, next + k, at + Vector2(0.0, 36.0) + Vector2(1.3, 0.0).rotated(float(k) * 0.4)))
	next += 5
	var pest: PestilenceFx = FxTimeline.cast(PestilenceFx, ctx, at + Vector2(0.0, 36.0), {"level": 3}) as PestilenceFx
	t.check(pest.lv_infect_max == 4 and is_equal_approx(pest.lv_infect_r, 1.4),
		"Pestilence level 3: 4 infected within 1.4 (%s, %s)" % [pest.lv_infect_max, pest.lv_infect_r])
	t.check(PestilenceFx.victims_at(field, at + Vector2(0.0, 36.0), 1.4, 4).size() == 4
		and PestilenceFx.victims_at(field, at + Vector2(0.0, 36.0)).is_empty(),
		"five people 1.3 away: four at level 3's reach, none at level 1's")
	pest.free()
	RD._clear_all(made)

	# Gravecall: four wraiths haunt 22 s, a soldier froze 3.5 s.
	var gc: GravecallFx = FxTimeline.cast(GravecallFx, ctx, at, {"to": at + Vector2(6.0, 0.0), "level": 3}) as GravecallFx
	t.check(gc.lv_spirits == 4 and is_equal_approx(gc.lv_haunt, 22.0) and is_equal_approx(gc.lv_freeze, 3.5) and gc._slots.size() == 4,
		"Gravecall level 3: 4 wraiths, haunt 22 s, freeze 3.5 s (%s, %s)" % [gc.lv_spirits, gc._slots.size()])
	gc.free()

	# Corpse Guise: five people within 2.2 (4 within 2.0 at level 1), 29 s.
	var guised: Array[Person] = []
	var gat := at + Vector2(0.0, 48.0)
	for k in 6:
		guised.append(_put(made, next + k, gat + Vector2(2.1, 0.0).rotated(float(k) * 1.0)))
	next += 6
	var guise: CorpseGuiseFx = FxTimeline.cast(CorpseGuiseFx, ctx, gat, {"level": 3}) as CorpseGuiseFx
	t.check(guise.lv_most == 5 and guise.marked.size() == 5 and is_equal_approx(guise.lv_mark_r, 2.2) and is_equal_approx(guise.lv_span, 29.0)
		and is_equal_approx(guise.duration, 29.0), "Guise level 3: five hidden within 2.2 for 29 s (%s, %s)" % [guise.lv_most, guise.marked.size()])
	t.check(CorpseGuiseFx.marked_at(field, gat).is_empty(), "and none of them within level 1's 2.0")
	guise.free()
	RD._clear_all(made)

	# Walking Corpse: 44 s, 3 kills, an attack reach of 6.5.
	var wbody := RD._body(made, next, at + Vector2(0.0, 60.0))
	next += 1
	var walk: WalkingCorpseFx = FxTimeline.cast(WalkingCorpseFx, ctx, wbody.pos, {"to": wbody.pos + Vector2(2.0, 0.0), "level": 3}) as WalkingCorpseFx
	t.check(is_equal_approx(walk.lv_walk_life, 44.0) and walk.lv_kills_most == 3 and is_equal_approx(walk.lv_attack_r, 6.5)
		and is_equal_approx(walk.duration, 44.0 + WalkingCorpseFx.SETTLE),
		"Walking Corpse level 3: 44 s, 3 kills, attack reach 6.5 (%s, %s)" % [walk.lv_walk_life, walk.lv_kills_most])
	walk.free()
	RD._clear_all(made)

	# The Gate Below: reach 6.5, the lip 4.55, 13 s open, wraiths touch 4 times.
	var gate: TheGateBelowFx = FxTimeline.cast(TheGateBelowFx, ctx, at, {"level": 3}) as TheGateBelowFx
	t.check(is_equal_approx(gate.lv_reach, 6.5) and is_equal_approx(gate.lv_edge, 4.55) and is_equal_approx(gate.lv_span, 13.0)
		and gate.lv_wraith_touches == 4, "Gate level 3: reach 6.5, lip 4.55, 13 s, 4 touches (%s, %s)" % [gate.lv_reach, gate.lv_edge])
	t.check(is_equal_approx(TheGateBelowFx.arm_spots(at, gate.lv_reach).back().distance_to(at), 6.5)
		and is_equal_approx(TheGateBelowFx.arm_spots(at)[TheGateBelowFx.ARMS - 1].distance_to(at), TheGateBelowFx.REACH),
		"the hands stand out to the level's reach")
	gate.free()
	var gate1: TheGateBelowFx = FxTimeline.cast(TheGateBelowFx, ctx, at, {}) as TheGateBelowFx
	t.check(gate1.lv_edge == 4.2 and gate1.lv_reach == 6.0 and gate1.lv_wraith_touches == 3 and gate1.lv_span == 12.0,
		"and level 1 keeps 4.2, 6.0, 12 s and three touches exactly")
	gate1.free()

	# Pale Reign: 10.5, 18 s, 28 kills.
	var pale: PaleReignFx = FxTimeline.cast(PaleReignFx, ctx, at, {"level": 3}) as PaleReignFx
	t.check(pale.lv_horde_kills == 28 and is_equal_approx(pale.lv_radius, 10.5) and is_equal_approx(pale.lv_span, 18.0),
		"Pale Reign level 3: 28 kills, 10.5 wide, 18 s (%s, %s)" % [pale.lv_horde_kills, pale.lv_radius])
	pale.free()

	# The Pale Serpent: 15 long, shadow 2.2, seen from 13, sick 22 s; a long drag stops at the level's length.
	var far := at + Vector2(30.0, 0.0)
	var serp: PaleSerpentFx = FxTimeline.cast(PaleSerpentFx, ctx, at, {"dir": Vector2.RIGHT, "to": far, "level": 3}) as PaleSerpentFx
	t.check(is_equal_approx(serp.lv_length, 15.0) and is_equal_approx(serp.lv_band, 2.2) and is_equal_approx(serp.lv_sight, 13.0)
		and is_equal_approx(serp.lv_sick, 22.0) and is_equal_approx(serp._len, 15.0),
		"Serpent level 3: 15 long, shadow 2.2, seen from 13, sickness 22 (%s)" % serp._len)
	t.check(is_equal_approx(PaleSerpentFx.end_of(at, {"to": far}).distance_to(at), 14.0)
		and is_equal_approx(PaleSerpentFx.end_of(at, {"to": far}, 16.0).distance_to(at), 16.0),
		"end_of() stops at LENGTH, or at the level's when given")
	serp.free()

	# Grave Tide: the giant stands 66 s, 14 blows, slams 3.7 wide and 70 on walls.
	var tide: GraveTideFx = FxTimeline.cast(GraveTideFx, ctx, at, {"level": 3}) as GraveTideFx
	t.check(is_equal_approx(tide.lv_giant_life, 66.0) and tide.lv_giant_blows == 14 and is_equal_approx(tide.lv_slam_r, 3.7)
		and is_equal_approx(tide.lv_slam_wreck, 70.0) and GraveTideFx.MOST == 30 and GraveTideFx.LIVING_CAP == 60,
		"Grave Tide level 3: giant 66 s, 14 blows, slam 3.7, walls 70 (%s)" % tide.lv_giant_life)
	tide.free()
	RD._done(made)


static func _twist_gate(t) -> void:
	var all := true
	for key: String in KEYS:
		all = all and PowerBook.twist_at({"level": 5}, key) and not PowerBook.twist_at({"level": 4}, key) \
			and not PowerBook.twist_at({"level": 6}, key) and not PowerBook.twist_at({}, key)
	t.check(all, "twist_at is true at level 5 of each of the ten, false at 4, 6 and with no level")


static func _previews(t) -> void:
	var same := true
	for key: String in KEYS:
		same = same and Targeting.area_at(key, 1) == Targeting.AREAS[key]
	t.check(same, "at level 1 the ten previews cover exactly their AREAS entry")
	t.check(is_equal_approx(float(Targeting.area_at("pestilence", 5).r), 1.6) and is_equal_approx(float(Targeting.area_at("guise", 3).r), 2.2)
		and is_equal_approx(float(Targeting.area_at("gatebelow", 5).r), 7.0) and is_equal_approx(float(Targeting.area_at("pale", 4).r), 10.75),
		"Pestilence, Guise, the Gate and Pale Reign follow their stats")
	t.check(is_equal_approx(float(Targeting.area_at("serpent", 5).length), 16.0) and is_equal_approx(float(Targeting.area_at("serpent", 5).half), 2.4)
		and Targeting.area_at("serpent", 5).min == PaleSerpentFx.MIN_LENGTH, "the Serpent's lane is its LENGTH and its BAND")
	t.check(Targeting.area_at("raise", 5) == Targeting.AREAS.raise and Targeting.area_at("gravetide", 5) == Targeting.AREAS.gravetide
		and Targeting.area_at("deathmark", 5) == Targeting.AREAS.deathmark and Targeting.area_at("walker", 5) == Targeting.AREAS.walker,
		"Raise's ring, the tide's aura, Death Mark's and the walker's pick have no levelled stat, so their previews stay")


static func _tree_text(t) -> void:
	var got := PowerBook.level_change("gatebelow", 3)
	t.check(got == "reach 6.25 -> 6.5, rift 4.375 -> 4.55, time 12.5 -> 13.0, wraith touches 3 -> 4, cooldown 87.0 -> 84.0",
		"Gate 2 -> 3 names its five numbers (%s)" % got)
	var all_five := true
	var all_one := true
	for key: String in KEYS:
		all_five = all_five and PowerBook.level_change(key, 5).ends_with(PowerBook.twist(key))
		all_one = all_one and PowerBook.level_change(key, 1) == ""
	t.check(all_five and all_one, "level 5's change ends with the twist text; level 1 changes nothing")
	t.check(PowerBook.level_change("pale", 2) == "radius 10.0 -> 10.25, time 16.0 -> 17.0, kills 24 -> 26, cooldown 120.0 -> 116.0",
		"Pale Reign 1 -> 2 (%s)" % PowerBook.level_change("pale", 2))
	t.check(PowerBook.level_change("smite", 2) == "kill radius 0.6 -> 0.65, damage 45.0 -> 50.0, cooldown 10.0 -> 9.5",
		"Ruin's tree text is unchanged (%s)" % PowerBook.level_change("smite", 2))
