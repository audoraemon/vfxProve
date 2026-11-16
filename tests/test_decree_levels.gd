extends RefCounted
## Decree's ten powers have five ability levels (the Death and Decree ability levels spec, "DS"): each power's levels table holds
## exactly DS's numbers, level 1 is the effect's own constants (so nothing already recorded moves), a cast reads its level through
## PowerBook.stat(), the cooldown is the level's, the twist gate is level 5 only, and the previews follow the level. The twists
## themselves have their own files (test_decree_twist_<key>.gd).

const RD := preload("res://tests/test_raise_dead.gd")

const KEYS := ["noleave", "breath", "redefine", "bound", "erase", "disorder", "eminent", "fenced", "cage", "sealed"]

## DS's tables: key -> stat -> the five levels (index 0 = level 1). "cooldown" is the row field; the Tier 5 pair has none (once a descent).
const DS := {
	"noleave": {"RADIUS": [3.0, 3.15, 3.3, 3.45, 3.6], "HOLD_TIME": [15.0, 16.0, 17.0, 18.0, 19.0], "cooldown": [20.0, 19.0, 18.0, 17.0, 16.0]},
	"breath": {"RADIUS": [2.5, 2.65, 2.8, 2.95, 3.1], "HOLD_TIME": [8.0, 8.5, 9.0, 9.5, 10.0], "cooldown": [25.0, 24.0, 23.0, 22.0, 21.0]},
	"redefine": {"MAX_NAMED": [3, 3, 4, 4, 5], "SPAN": [25.0, 27.0, 29.0, 31.0, 33.0], "cooldown": [45.0, 43.0, 41.0, 39.0, 37.0]},
	"bound": {"REACH": [10.0, 10.5, 11.0, 11.5, 12.0], "SPAN": [20.0, 22.0, 24.0, 26.0, 28.0], "cooldown": [45.0, 43.0, 41.0, 39.0, 37.0]},
	"erase": {"MAX_LEN": [10.0, 10.5, 11.0, 11.5, 12.0], "CRUSH_W": [1.0, 1.05, 1.1, 1.15, 1.2], "THROW_W": [3.0, 3.15, 3.3, 3.45, 3.6],
		"cooldown": [60.0, 58.0, 56.0, 54.0, 52.0]},
	"disorder": {"RADIUS": [5.0, 5.25, 5.5, 5.75, 6.0], "HOLD_TIME": [15.0, 16.0, 17.0, 18.0, 19.0], "cooldown": [45.0, 43.0, 41.0, 39.0, 37.0]},
	"eminent": {"LENGTH": [10.0, 10.5, 11.0, 11.5, 12.0], "HALF_W": [1.0, 1.05, 1.1, 1.15, 1.2], "cooldown": [80.0, 77.0, 74.0, 71.0, 68.0]},
	"fenced": {"RADIUS": [7.0, 7.25, 7.5, 7.75, 8.0], "HOLD_TIME": [30.0, 32.0, 34.0, 36.0, 38.0], "cooldown": [80.0, 77.0, 74.0, 71.0, 68.0]},
	"cage": {"RADIUS": [12.0, 12.5, 13.0, 13.5, 14.0], "CLOSE_TIME": [30.0, 29.0, 28.0, 27.0, 26.0]},
	"sealed": {"RADIUS": [10.0, 10.5, 11.0, 11.5, 12.0], "COUNTDOWN": [30.0, 29.0, 28.0, 27.0, 26.0]},
}
## DS's Might column for levels 1-5.
const DS_MIGHT := {
	"noleave": [1, 1, 2, 2, 3], "breath": [2, 2, 3, 3, 4], "redefine": [3, 3, 4, 4, 5], "bound": [3, 3, 4, 4, 5],
	"erase": [4, 4, 5, 5, 6], "disorder": [3, 3, 4, 4, 5], "eminent": [4, 4, 5, 5, 6], "fenced": [5, 5, 6, 6, 7],
	"cage": [6, 6, 7, 7, 8], "sealed": [6, 6, 7, 7, 8],
}
## The twist texts: the tree's level column words them, so they must fit its detail line.
const TWISTS := {
	"noleave": "Held for Trial: the freed are named criminal", "breath": "And None May Leave: sealed for the first 2 s",
	"redefine": "Precedent: name one near a named one", "bound": "Party to the Bond: attackers join the bond",
	"erase": "Shortcut: the ends stay joined as a door", "disorder": "Bad Counsel: leavers carry the disorder 8 s",
	"eminent": "Further Claim: a second strip, round a corner", "fenced": "Third Clause: add one more rule",
	"cage": "Dragged Cage: click to drag the cage along", "sealed": "The Ledger Remembers: all who stood in it die",
}
## The consts a table's level 1 must equal, with their type: key -> stat -> the effect's own number.
const BASE := {
	"noleave": {"RADIUS": NoLeaveFx.RADIUS, "HOLD_TIME": NoLeaveFx.HOLD_TIME},
	"breath": {"RADIUS": BreathFx.RADIUS, "HOLD_TIME": BreathFx.HOLD_TIME},
	"redefine": {"MAX_NAMED": RedefineFx.MAX_NAMED, "SPAN": RedefineFx.SPAN},
	"bound": {"REACH": BoundFx.REACH, "SPAN": BoundFx.SPAN},
	"erase": {"MAX_LEN": EraseFx.MAX_LEN, "CRUSH_W": EraseFx.CRUSH_W, "THROW_W": EraseFx.THROW_W},
	"disorder": {"RADIUS": DisorderFx.RADIUS, "HOLD_TIME": DisorderFx.HOLD_TIME},
	"eminent": {"LENGTH": EminentFx.LENGTH, "HALF_W": EminentFx.HALF_W},
	"fenced": {"RADIUS": FencedFx.RADIUS, "HOLD_TIME": FencedFx.HOLD_TIME},
	"cage": {"RADIUS": CageFx.RADIUS, "CLOSE_TIME": CageFx.CLOSE_TIME},
	"sealed": {"RADIUS": SealedFx.RADIUS, "COUNTDOWN": SealedFx.COUNTDOWN},
}
const INT_STATS := ["MAX_NAMED"]

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
	t.check(PowerBook.cooldown("cage", 1) == PowerBook.cooldown("cage", 5) and PowerBook.cooldown("sealed", 1) == PowerBook.cooldown("sealed", 5),
		"the Cage and the Sealed Verdict have no cooldown stat: once a descent at every level")
	t.check(typeof(RedefineFx.MAX_NAMED) == TYPE_INT and typeof(PowerBook.level_stat("redefine", 5, "MAX_NAMED", 0.0)) == TYPE_INT
		and NoLeaveFx.RADIUS == 3.0 and BreathFx.CHOKE == 3.0, "MAX_NAMED stays int; BreathFx.CHOKE stays 3 at every level")


static func _might(t) -> void:
	for key: String in KEYS:
		for lv in PowerBook.MAX_LEVEL:
			t.check(PowerBook.might(key, lv + 1) == int(DS_MIGHT[key][lv]),
				"%s level %d costs DS's %d Might (%d)" % [key, lv + 1, DS_MIGHT[key][lv], PowerBook.might(key, lv + 1)])
	t.check(PowerBook.might("cage", 5) + PowerBook.might("sealed", 5) == 16, "Cage 8 + Sealed Verdict 8 = 16 at level 5, the cap")
	t.check(PowerBook.might("eminent", 5) + PowerBook.might("fenced", 5) == 13, "Eminent 6 + Fenced 7 = 13 at level 5, under the cap of 16")


## Rules with Leaving Is Prohibited and Disorder and a caster that only records: the cooldown a cast starts is the slot's level's.
static func _cooldown_at_level(t) -> void:
	var made := _world()
	var rules := Rules.new().setup(PackedStringArray(["noleave", "disorder"]), null, made[1], made[3], made[0], made[6],
		MissionBook.last_judgement())
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline:
		return null
	rules.levels = {"noleave": 3, "disorder": 5}
	rules.cast(0, Vector2(10, 10), {})
	t.check(is_equal_approx(rules.cooldown_left(0), 18.0) and is_equal_approx(rules.cooldown_of(0), 18.0),
		"levels {noleave 3}: a Leaving Is Prohibited casts into 18 s (%s)" % rules.cooldown_left(0))
	rules.cast(1, Vector2(10, 10), {})
	t.check(is_equal_approx(rules.cooldown_of(1), 37.0) and is_equal_approx(rules.cooldown_left(1), 37.0),
		"levels {disorder 5}: a Disorder cast waits 37 s (%s)" % rules.cooldown_left(1))
	rules.free()
	RD._done(made)


## A cast at level 3 reads the level-3 numbers (and level 1 the consts).
static func _cast_reads_level3(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var at: Vector2 = (made[2] as WalkGrid).nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var next := 0

	# Leaving Is Prohibited: a 3.3 cell for 17 s.
	var nl: NoLeaveFx = FxTimeline.cast(NoLeaveFx, ctx, at, {"level": 3}) as NoLeaveFx
	t.check(is_equal_approx(nl.lv_radius, 3.3) and is_equal_approx(nl.lv_hold_time, 17.0)
		and is_equal_approx(nl.duration, NoLeaveFx.T_SEAL + 17.0 + NoLeaveFx.CRACK_TIME + NoLeaveFx.FALL_TIME),
		"Leaving level 3: a 3.3 cell for 17 s (%s, %s)" % [nl.lv_radius, nl.lv_hold_time])
	nl.free()
	var nl1: NoLeaveFx = FxTimeline.cast(NoLeaveFx, ctx, at, {}) as NoLeaveFx
	t.check(nl1.lv_radius == NoLeaveFx.RADIUS and nl1.lv_hold_time == NoLeaveFx.HOLD_TIME, "and level 1 reads the consts")
	nl1.free()

	# Breathing Is Prohibited: 2.8 for 9 s (choke stays 3).
	var br: BreathFx = FxTimeline.cast(BreathFx, ctx, at, {"level": 3}) as BreathFx
	t.check(is_equal_approx(br.lv_radius, 2.8) and is_equal_approx(br.lv_hold_time, 9.0)
		and is_equal_approx(br.duration, BreathFx.T_LAND + 9.0 + BreathFx.FADE), "Breathing level 3: 2.8 for 9 s (%s)" % br.lv_radius)
	br.free()

	# Redefine: four named (3 at level 1) for 29 s.
	var gat := at + Vector2(0.0, 14.0)
	var five: Array[Person] = []
	for k in 5:
		five.append(_put(made, next + k, gat + Vector2(0.4 + 0.15 * float(k), 0.0)))
	next += 5
	var rd: RedefineFx = FxTimeline.cast(RedefineFx, ctx, gat, {"mode": "criminal", "level": 3}) as RedefineFx
	t.check(rd.lv_max_named == 4 and rd.named.size() == 4 and is_equal_approx(rd.lv_span, 29.0) and is_equal_approx(rd.duration, 29.0 + RedefineFx.FADE),
		"Redefine level 3: four named for 29 s (%s, %s)" % [rd.lv_max_named, rd.named.size()])
	t.check(RedefineFx.named_at(field, gat).size() == 3 and RedefineFx.named_at(field, gat, 5).size() == 5,
		"named_at() takes the level's count (3 by default)")
	rd.free()
	RD._clear_all(made)

	# Bound in Law: two 10.8 apart are refused at level 1 ("far") and bound at level 3 (reach 11), for 24 s.
	var bat := at + Vector2(0.0, 28.0)
	var one := _put(made, next, bat)
	var two := _put(made, next + 1, bat + Vector2(10.8, 0.0))
	next += 2
	t.check(BoundFx.refusal(field, bat, two.ground_pos) == "far" and BoundFx.refusal(field, bat, two.ground_pos, 11.0) == ""
		and BoundFx.pair_at(field, bat, Vector2.INF).is_empty() and BoundFx.pair_at(field, bat, Vector2.INF, 11.0).size() == 2,
		"Bound: the pair 10.8 apart is far at 10 and fine at 11; with no second click the nearest within reach")
	var bd: BoundFx = FxTimeline.cast(BoundFx, ctx, bat, {"to": two.ground_pos, "level": 3}) as BoundFx
	t.check(is_equal_approx(bd.lv_reach, 11.0) and is_equal_approx(bd.lv_span, 24.0) and bd.linked and bd.a == one and bd.b == two
		and is_equal_approx(bd.duration, 24.0 + BoundFx.FADE), "Bound level 3: reach 11, 24 s, the pair bound (%s)" % bd.linked)
	bd.free()
	RD._clear_all(made)

	# Erasing Distance: a drag of 20 is a line of 11 at level 3 (10 at level 1).
	var ea := at + Vector2(0.0, 42.0)
	var er: EraseFx = FxTimeline.cast(EraseFx, ctx, ea, {"dir": Vector2.RIGHT, "to": ea + Vector2(20.0, 0.0), "level": 3}) as EraseFx
	t.check(is_equal_approx(er.lv_max_len, 11.0) and is_equal_approx(er.length, 11.0) and is_equal_approx(er.lv_crush_w, 1.1)
		and is_equal_approx(er.lv_throw_w, 3.3), "Erase level 3: a line of 11, crush 1.1, throw 3.3 (%s)" % er.length)
	er.free()
	var er1: EraseFx = FxTimeline.cast(EraseFx, ctx, ea, {"dir": Vector2.RIGHT, "to": ea + Vector2(20.0, 0.0)}) as EraseFx
	t.check(is_equal_approx(er1.length, 10.0) and er1.lv_crush_w == EraseFx.CRUSH_W and er1.lv_throw_w == EraseFx.THROW_W,
		"and 10 at level 1")
	er1.free()

	# Disorder: 5.5 for 17 s.
	var dis: DisorderFx = FxTimeline.cast(DisorderFx, ctx, at, {"level": 3}) as DisorderFx
	t.check(is_equal_approx(dis.lv_radius, 5.5) and is_equal_approx(dis.lv_hold_time, 17.0)
		and is_equal_approx(dis.duration, DisorderFx.T_LAND + 17.0 + DisorderFx.FADE), "Disorder level 3: 5.5 for 17 s (%s)" % dis.lv_radius)
	dis.free()

	# Eminent Domain: 11 long, 1.1 each side.
	var em: EminentFx = FxTimeline.cast(EminentFx, ctx, ea, {"dir": Vector2.RIGHT, "level": 3}) as EminentFx
	t.check(is_equal_approx(em.lv_length, 11.0) and is_equal_approx(em.lv_half_w, 1.1) and em.to.is_equal_approx(ea + Vector2(11.0, 0.0)),
		"Eminent level 3: a strip 11 long and 1.1 each side (%s)" % em.to)
	em.free()

	# Fenced Rule: 7.5 for 34 s.
	var fe: FencedFx = FxTimeline.cast(FencedFx, ctx, at, {"mode": "run_arms", "level": 3}) as FencedFx
	t.check(is_equal_approx(fe.lv_radius, 7.5) and is_equal_approx(fe.lv_hold_time, 34.0)
		and is_equal_approx(fe.duration, FencedFx.T_LAND + 34.0 + FencedFx.FADE), "Fenced level 3: 7.5 for 34 s (%s)" % fe.lv_radius)
	fe.free()

	# The Closing Cage: a ring of 13 closing in 28 s.
	var cg: CageFx = FxTimeline.cast(CageFx, ctx, at, {"level": 3}) as CageFx
	t.check(is_equal_approx(cg.lv_radius, 13.0) and is_equal_approx(cg.lv_close_time, 28.0) and is_equal_approx(cg.radius, 13.0)
		and is_equal_approx(cg.duration, CageFx.T_LAND + 28.0 + CageFx.FADE), "Cage level 3: a ring of 13 closing in 28 s (%s)" % cg.lv_close_time)
	t.check(is_equal_approx(CageFx.radius_at(CageFx.T_LAND + 14.0, 13.0, 28.0), lerpf(13.0, CageFx.END_R, 0.5))
		and is_equal_approx(CageFx.radius_at(CageFx.T_LAND + 15.0), lerpf(12.0, CageFx.END_R, 0.5)),
		"radius_at() takes the level's start and time (the consts by default)")
	cg.free()

	# The Sealed Verdict: a bell in 28 s over a district of 11.
	var sv: SealedFx = FxTimeline.cast(SealedFx, ctx, at, {"level": 3}) as SealedFx
	t.check(is_equal_approx(sv.lv_countdown, 28.0) and is_equal_approx(sv.lv_radius, 11.0) and is_equal_approx(sv.left(), 28.0)
		and is_equal_approx(sv.duration, 28.0 + SealedFx.BURN), "Sealed level 3: the bell in 28 s over 11 (%s)" % sv.left())
	var inside := _put(made, next, at + Vector2(10.5, 0.0))
	next += 1
	t.check(SealedFx.doomed_at(crowd, field, at, 11.0).has(inside) and not SealedFx.doomed_at(crowd, field, at).has(inside),
		"doomed_at() takes the level's radius (10.5 away is inside 11, outside 10)")
	sv.free()
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
	t.check(is_equal_approx(float(Targeting.area_at("noleave", 5).r), 3.6) and is_equal_approx(float(Targeting.area_at("breath", 3).r), 2.8)
		and is_equal_approx(float(Targeting.area_at("disorder", 5).r), 6.0) and is_equal_approx(float(Targeting.area_at("fenced", 4).r), 7.75)
		and is_equal_approx(float(Targeting.area_at("cage", 5).r), 14.0) and is_equal_approx(float(Targeting.area_at("sealed", 2).r), 10.5),
		"the six circles follow their RADIUS")
	var erase := Targeting.area_at("erase", 5)
	var eminent := Targeting.area_at("eminent", 5)
	t.check(is_equal_approx(float(erase.length), 12.0) and is_equal_approx(float(erase.half), 1.2) and is_equal_approx(float(erase.outer), 3.6)
		and is_equal_approx(float(eminent.length), 12.0) and is_equal_approx(float(eminent.half), 1.2) and erase.min == 2.0,
		"Erasing Distance's lane is MAX_LEN, CRUSH_W and THROW_W; Eminent's is LENGTH and HALF_W (the rest stays)")
	t.check(Targeting.area_at("redefine", 5) == Targeting.AREAS.redefine and Targeting.area_at("bound", 5) == Targeting.AREAS.bound,
		"Redefine's and Bound's picks have no levelled area, so their previews stay")


static func _tree_text(t) -> void:
	var got := PowerBook.level_change("erase", 3)
	t.check(got == "line 10.5 -> 11.0, crush 1.05 -> 1.1, throw 3.15 -> 3.3, cooldown 58.0 -> 56.0", "Erase 2 -> 3 names its four numbers (%s)" % got)
	var all_five := true
	var all_one := true
	for key: String in KEYS:
		all_five = all_five and PowerBook.level_change(key, 5).ends_with(PowerBook.twist(key))
		all_one = all_one and PowerBook.level_change(key, 1) == ""
	t.check(all_five and all_one, "level 5's change ends with the twist text; level 1 changes nothing")
	t.check(PowerBook.level_change("cage", 2) == "radius 12.0 -> 12.5, closes in 30.0 -> 29.0", "the Cage 1 -> 2 (%s)" % PowerBook.level_change("cage", 2))
	t.check(PowerBook.level_change("sealed", 2) == "radius 10.0 -> 10.5, bell in 30.0 -> 29.0", "the Verdict 1 -> 2 (%s)" % PowerBook.level_change("sealed", 2))
	t.check(PowerBook.level_change("smite", 2) == "kill radius 0.6 -> 0.65, damage 45.0 -> 50.0, cooldown 10.0 -> 9.5",
		"Ruin's tree text is unchanged (%s)" % PowerBook.level_change("smite", 2))
