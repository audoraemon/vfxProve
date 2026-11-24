extends RefCounted
## The Veil's ten powers have five ability levels (the Veil ability levels spec, "VS"): each power's levels table holds exactly VS's
## numbers (a sized stat as [light, dark]), level 1 is today's constants and VeilRules.SIZES (so nothing recorded moves), every effect
## reads its level through PowerBook.stat() / VeilRules.size(), the dusk a cast leaves grows with the level, the aim rings what the slot's
## level would take, and the tree words it. The twists themselves have their own files; here the gate is only level 5.

const RD := preload("res://tests/test_raise_dead.gd")
const EV := preload("res://tests/test_veil_evernight.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")

const KEYS := ["doom", "blight", "slumber", "cloak", "unseen", "dreamless", "dread", "shadowplay", "swallow", "evernight"]

## VS's tables: key -> stat -> the five levels (index 0 = level 1). A sized stat is [light, dark]; "cooldown" is the row field.
const VS := {
	"doom": {"RADIUS": [[0.8, 1.6], [0.8, 1.75], [0.85, 1.9], [0.85, 2.05], [0.9, 2.2]], "cooldown": [10.0, 9.5, 9.0, 8.5, 8.0]},
	"blight": {"DUSK_R": [[3.0, 5.0], [3.1, 5.3], [3.2, 5.6], [3.3, 5.9], [3.4, 6.2]],
		"ILL_MOST": [[1, 3], [1, 3], [1, 4], [1, 4], [1, 5]], "ILL_REACH": [2.0, 2.2, 2.4, 2.6, 2.8],
		"cooldown": [20.0, 19.0, 18.0, 17.0, 16.0]},
	"slumber": {"RADIUS": [[1.5, 3.5], [1.55, 3.75], [1.6, 4.0], [1.65, 4.25], [1.7, 4.5]], "SLEEP_TIME": [20.0, 22.0, 24.0, 26.0, 28.0],
		"cooldown": [40.0, 38.0, 36.0, 34.0, 32.0]},
	"cloak": {"MARK_R": [[2.0, 4.0], [2.05, 4.25], [2.1, 4.5], [2.15, 4.75], [2.2, 5.0]],
		"MOST": [[3, 8], [3, 9], [3, 10], [4, 11], [4, 12]], "SPAN": [25.0, 27.0, 29.0, 31.0, 33.0],
		"cooldown": [45.0, 43.0, 41.0, 39.0, 37.0]},
	"unseen": {"RADIUS": [[5.0, 7.0], [5.1, 7.4], [5.2, 7.8], [5.3, 8.2], [5.4, 8.6]],
		"VEIL_TIME": [[20.0, 30.0], [20.5, 32.0], [21.0, 34.0], [21.5, 36.0], [22.0, 38.0]], "cooldown": [60.0, 58.0, 56.0, 54.0, 52.0]},
	"dreamless": {"REACH": [[1.0, 2.0], [1.05, 2.25], [1.1, 2.5], [1.15, 2.75], [1.2, 3.0]],
		"MOST": [[1, 4], [1, 5], [1, 6], [2, 7], [2, 8]], "REST": [20.0, 22.0, 24.0, 26.0, 28.0],
		"cooldown": [35.0, 33.5, 32.0, 30.5, 29.0]},
	"dread": {"REACH": [[6.0, 12.0], [6.25, 12.0], [6.5, 12.0], [6.75, 12.0], [7.0, 12.0]], "HOLD": [25.0, 27.5, 30.0, 32.5, 35.0],
		"cooldown": [70.0, 67.0, 64.0, 61.0, 58.0]},
	"shadowplay": {"RADIUS": [[3.0, 6.0], [3.1, 6.3], [3.15, 6.6], [3.25, 6.9], [3.3, 7.2]], "SPAN": [30.0, 32.0, 34.0, 36.0, 38.0],
		"cooldown": [90.0, 87.0, 84.0, 81.0, 78.0]},
	"swallow": {"FULL_R": [[10.0, 14.0], [10.2, 14.5], [10.4, 15.0], [10.6, 15.5], [10.8, 16.0]], "GROW": [0.5, 0.55, 0.6, 0.65, 0.7]},
	"evernight": {"NIGHT_TIME": [[60.0, 90.0], [62.0, 93.0], [64.0, 96.0], [66.0, 99.0], [68.0, 102.0]], "TAKE_LAST": [10, 10, 11, 11, 12],
		"TORCHES": [6, 6, 6, 5, 5]},
}
## The stats that are a [light, dark] pair.
const PAIRS := {
	"doom": ["RADIUS"], "blight": ["DUSK_R", "ILL_MOST"], "slumber": ["RADIUS"], "cloak": ["MARK_R", "MOST"],
	"unseen": ["RADIUS", "VEIL_TIME"], "dreamless": ["REACH", "MOST"], "dread": ["REACH"], "shadowplay": ["RADIUS"],
	"swallow": ["FULL_R"], "evernight": ["NIGHT_TIME"],
}
## The twist texts (VL16): the tree's level column words them, so they must fit its detail line.
const TWISTS := {
	"doom": "No Witness: the nearest who saw it falls too", "blight": "Watchful Rot: the watch falls ill in your rot",
	"slumber": "Heavy Air: who walks in sleeps too", "cloak": "Averted Eyes: the watch near them turns away",
	"unseen": "Eyes Within: see the watch; leavers stay blind", "dreamless": "Found by No One: never found; a finder rests",
	"dread": "The Dark Looks Back: who stops to look is held", "shadowplay": "The Shadows Keep Watch: who comes close joins",
	"swallow": "Nothing Leaves: who walks out is taken too", "evernight": "The Light Gives Way: the torchlight shrinks",
}
## The plain (not paired) stats' effect constants: a level-1 table value must equal them, same type.
const BASE := {
	"blight": {"ILL_REACH": BlightFx.ILL_REACH}, "slumber": {"SLEEP_TIME": SlumberFx.SLEEP_TIME}, "cloak": {"SPAN": CloakOfNightFx.SPAN},
	"dreamless": {"REST": DreamlessFx.REST}, "dread": {"HOLD": DreadOfTheDarkFx.HOLD}, "shadowplay": {"SPAN": ShadowPlayFx.SPAN},
	"swallow": {"GROW": TheSwallowingDarkFx.GROW}, "evernight": {"TAKE_LAST": EvernightFx.TAKE_LAST, "TORCHES": EvernightFx.TORCHES},
}
## Stats a level may only lower.
const FALLING := ["cooldown", "TORCHES"]


static func run(t) -> void:
	_shapes(t)
	_level_one(t)
	_values(t)
	_never_worse(t)
	_might(t)
	_sizes_by_level(t)
	_twist_gate(t)
	_tree(t)
	_evernight_takes(t)
	var made := RD._setup()
	var ctx: FxContext = made[5]
	ctx.lights = LightField.new()
	_cast_reads_level(t, made)
	_dusk_by_level(t, made)
	_previews(t, made)
	_refusal(t, made)
	_gate_builds(t, made)
	ctx.lights.free()
	ctx.lights = null
	RD._done(made)


# --- The tables ---------------------------------------------------------------------------------------------------------------

static func _shapes(t) -> void:
	for key: String in KEYS:
		var row := PowerBook.get_power(key)
		t.check(PowerBook.has_levels(key) and PowerBook.levels_problems(row).is_empty(),
			"%s has a valid levels table (%s)" % [key, PowerBook.levels_problems(row)])
		var want: Array = VS[key].keys()
		want.sort()
		var table: Array = row.levels
		for lv in PowerBook.MAX_LEVEL:
			var have: Array = []
			for stat_name: String in (table[lv] as Dictionary):
				if not PowerBook.TWIST_KEYS.has(stat_name):
					have.append(stat_name)
			have.sort()
			t.check(have == want, "%s level %d names exactly VS's stats (%s)" % [key, lv + 1, have])
			var carries := (table[lv] as Dictionary).has("twist") or (table[lv] as Dictionary).has("twist_text")
			t.check(carries == (lv == PowerBook.MAX_LEVEL - 1), "%s: only level 5 carries the twist (level %d)" % [key, lv + 1])
			var pairs_ok := true
			for stat_name: String in PAIRS[key]:
				var v: Variant = (table[lv] as Dictionary)[stat_name]
				pairs_ok = pairs_ok and v is Array and (v as Array).size() == 2
			t.check(pairs_ok, "%s level %d: every sized stat is a [light, dark] pair" % [key, lv + 1])
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
		for stat_name: String in BASE.get(key, {}):
			var base: Variant = BASE[key][stat_name]
			var got: Variant = PowerBook.level_stat(key, 1, stat_name, null)
			t.check(got == base and typeof(got) == typeof(base),
				"%s %s at level 1 is the effect's own const, same type (%s vs %s)" % [key, stat_name, got, base])
			t.check(PowerBook.stat({}, key, stat_name, null) == base and PowerBook.stat({"level": 1}, key, stat_name, null) == base,
				"%s %s: a cast with no level, or level 1, reads the const" % [key, stat_name])
		for stat_name: String in PAIRS[key]:
			var got: Array = PowerBook.level_stat(key, 1, stat_name, [])
			var sized: Array = VeilRules.SIZES[key][stat_name]
			t.check(got == sized and typeof(got[0]) == typeof(sized[0]) and typeof(got[1]) == typeof(sized[1]),
				"%s %s at level 1 is VeilRules.SIZES' pair, same types (%s vs %s)" % [key, stat_name, got, sized])
		if VS[key].has("cooldown"):
			t.check(PowerBook.cooldown(key, 1) == float(row.cooldown), "%s: level 1's cooldown is the row's (%s)" % [key, PowerBook.cooldown(key, 1)])
		else:
			t.check(PowerBook.cooldown(key, 1) == PowerBook.cooldown(key, 5) and PowerBook.cooldown(key, 5) == float(row.cooldown),
				"%s has no cooldown stat: once a descent at every level" % key)
	t.check(SilentDoom.RADIUS == VeilRules.SIZES.doom.RADIUS[0] and VeilRules.dusk_r(1) == VeilRules.DUSK_R
		and VeilRules.dusk_time(1) == VeilRules.DUSK_TIME and VeilRules.DUSK_RS[0] == VeilRules.DUSK_R and VeilRules.DUSK_TIMES[0] == VeilRules.DUSK_TIME,
		"Silent Doom's RADIUS is the light size; the dusk at level 1 is DUSK_R and DUSK_TIME")


static func _values(t) -> void:
	for key: String in KEYS:
		var row := PowerBook.get_power(key)
		for stat_name: String in VS[key]:
			for lv in PowerBook.MAX_LEVEL:
				var want: Variant = VS[key][stat_name][lv]
				var have: Variant = (row.levels[lv] as Dictionary)[stat_name]
				var same := false
				if want is Array:
					same = have is Array and (have as Array).size() == (want as Array).size()
					for i in (want as Array).size() if same else 0:
						same = same and have[i] == want[i] and typeof(have[i]) == typeof(want[i])
				else:
					same = have == want and typeof(have) == typeof(want)
				t.check(same, "%s %s at level %d is VS's %s (%s)" % [key, stat_name, lv + 1, want, have])
	var dusk := true
	for lv in PowerBook.MAX_LEVEL:
		dusk = dusk and is_equal_approx(VeilRules.dusk_r(lv + 1), 3.0 + 0.25 * float(lv)) and is_equal_approx(VeilRules.dusk_time(lv + 1), 20.0 + 2.0 * float(lv))
	t.check(dusk and VeilRules.dusk_r(0) == 3.0 and VeilRules.dusk_r(9) == 4.0 and VeilRules.dusk_time(-3) == 20.0 and VeilRules.dusk_time(9) == 28.0,
		"the dusk by level is VS 5.1 (3.0 / 20 s to 4.0 / 28 s), the level clamped 1-5")


static func _never_worse(t) -> void:
	var bad := PackedStringArray()
	for key: String in KEYS:
		for stat_name: String in VS[key]:
			var falling := FALLING.has(stat_name)
			for lv in range(1, PowerBook.MAX_LEVEL):
				var a: Variant = VS[key][stat_name][lv - 1]
				var b: Variant = (PowerBook.get_power(key).levels[lv] as Dictionary)[stat_name]
				var pa: Array = a if a is Array else [a]
				var pb: Array = b if b is Array else [b]
				for i in pa.size():
					if (falling and pb[i] > pa[i]) or (not falling and pb[i] < pa[i]):
						bad.append("%s %s level %d" % [key, stat_name, lv + 1])
	t.check(bad.is_empty(), "level to level: cooldown and TORCHES never rise, every other number never falls (%s)" % [bad])


static func _might(t) -> void:
	for key: String in KEYS:
		var dp := int(PowerBook.get_power(key).dp)
		var want := [dp, dp, dp + 1, dp + 1, dp + 2]
		var have := []
		for lv in PowerBook.MAX_LEVEL:
			have.append(PowerBook.might(key, lv + 1))
		t.check(have == want, "%s: Might is dp, dp, dp+1, dp+1, dp+2 (%s)" % [key, have])
	t.check(PowerBook.might("swallow", 5) + PowerBook.might("evernight", 5) == 16, "Swallow 8 + Evernight 8 = 16 at level 5, the cap")
	t.check(PowerBook.might("dread", 5) + PowerBook.might("shadowplay", 5) == 13, "Dread 6 + Shadow Play 7 = 13 at level 5")


static func _sizes_by_level(t) -> void:
	t.check(VeilRules.size("doom", "RADIUS", true, 5) == 2.2 and VeilRules.size("doom", "RADIUS", false, 5) == 0.9
		and VeilRules.size("doom", "RADIUS", true) == 1.6 and VeilRules.size("cloak", "MOST", false, 4) == 4.0
		and VeilRules.size("cloak", "MARK_R", true, 4) == 4.75,
		"VeilRules.size() reads the level: doom dark 5 is 2.2, cloak light 4 takes 4")
	t.check(VeilRules.size("evernight", "TAKE_EVERY", true, 5) == 1.5 and VeilRules.size("evernight", "TAKE_EVERY", false, 5) == 2.0
		and VeilRules.pair("evernight", "TAKE_EVERY", 5) == [2.0, 1.5],
		"a stat the table does not name falls back to SIZES (Evernight's TAKE_EVERY)")
	t.check(VeilRules.size("smite", "RADIUS", true, 5) == 0.0 and VeilRules.size("doom", "NOPE", true, 5) == 0.0
		and VeilRules.pair("smite", "RADIUS", 5).is_empty() and VeilRules.pair("doom", "RADIUS", 3) == [0.85, 1.9],
		"an unknown key or stat is 0.0 / [] as before")
	t.check(VeilRules.dusk_row("doom", 1).is_empty() and VeilRules.dusk_row("evernight", 5).is_empty() and VeilRules.dusk_row("smite", 5).is_empty()
		and VeilRules.dusk_row("slumber", 3) == {"label": "dusk", "old": "3.25 for 22 s", "new": "3.5 for 24 s"},
		"dusk_row: none at level 1, for Evernight and for a non-Veil key")


static func _twist_gate(t) -> void:
	var all := true
	for key: String in KEYS:
		for lv in range(0, 8):
			all = all and PowerBook.twist_at({"level": lv}, key) == (lv == 5)
		all = all and not PowerBook.twist_at({}, key)
	t.check(all, "twist_at is true at level 5 of each of the ten and nowhere else, and with no level")


static func _tree(t) -> void:
	var rows := PowerBook.level_rows("doom", 2)
	t.check(rows.has({"label": "radius", "old": "0.8 / 1.6", "new": "0.8 / 1.75"})
		and rows.has({"label": "dusk", "old": "3.0 for 20 s", "new": "3.25 for 22 s"}),
		"Silent Doom 1 -> 2 prints its pair 'light / dark' and the dusk (%s)" % [rows])
	t.check(rows.size() == 3 and rows.back().label == "dusk", "doom's rows: radius, cooldown, then the dusk last (%s)" % [rows])
	var ever := PowerBook.level_rows("evernight", 2)
	var has_dusk := false
	for r: Dictionary in ever:
		has_dusk = has_dusk or r.label == "dusk"
	t.check(not has_dusk and not ever.is_empty(), "Evernight lays no dusk, so it has no dusk row (%s)" % [ever])
	t.check(PowerBook.level_change("cloak", 5).ends_with(PowerBook.twist("cloak")) and PowerBook.level_change("cloak", 1) == ""
		and PowerBook.level_change("cloak", 2).contains("reach 2.0 / 4.0 -> 2.05 / 4.25"),
		"Cloak's level 5 change ends with its twist; level 1 says nothing (%s)" % PowerBook.level_change("cloak", 2))
	t.check(PowerBook.level_change("slumber", 3) == "radius 1.55 / 3.75 -> 1.6 / 4.0, sleep 22.0 -> 24.0, cooldown 38.0 -> 36.0, dusk 3.25 for 22 s -> 3.5 for 24 s",
		"Slumber 2 -> 3 in words (%s)" % PowerBook.level_change("slumber", 3))
	var all_five := true
	for key: String in KEYS:
		all_five = all_five and PowerBook.level_change(key, 5).ends_with(PowerBook.twist(key)) and PowerBook.level_change(key, 1) == ""
	t.check(all_five, "each of the ten: level 5's change ends with the twist, level 1 changes nothing")
	t.check(PowerBook._stat_text([1, 3]) == "1 / 3" and PowerBook._stat_text(Vector2i(5, 7)) == "5-7" and PowerBook._stat_text(2.5) == "2.5",
		"a two-element Array prints 'light / dark'; the other kinds as before")


# --- Evernight's takes ---------------------------------------------------------------------------------------------------------

## The takes a level-N Evernight schedules and the sum of take_count(k), by day and in a NIGHT mission.
static func _evernight_takes(t) -> void:
	var made := RD._setup()
	var ctx: FxContext = made[5]
	ctx.lights = LightField.new()
	var crowd: Crowd = made[0]
	var want := [[1, false, 29, 218], [5, false, 33, 281], [5, true, 67, 570]]
	for w in want:
		EV._fresh(made)
		crowd.night_mission = bool(w[1])
		var fx := FxTimeline.cast(EvernightFx, ctx, Vector2.ZERO, {"level": int(w[0])}) as EvernightFx
		var sum := 0
		for k in range(1, fx.takes + 1):
			sum += fx.take_count(k)
		t.check(fx.takes == int(w[2]) and sum == int(w[3]),
			"Evernight level %d %s: %d takes, %d taken in all (%d, %d)" % [w[0], "in a NIGHT mission" if w[1] else "by day", w[2], w[3], fx.takes, sum])
		fx.end_now()
		crowd.night_mission = false
	ctx.lights.free()
	ctx.lights = null
	RD._done(made)


# --- A cast reads its level -----------------------------------------------------------------------------------------------------

## The nth person of `crowd.citizens` would be `_put` by EV; this sets `n` calm citizens round `at` at distance `d`.
static func _ring(crowd: Crowd, at: Vector2, d: float, n: int, start := 0.0) -> Array[Person]:
	var out: Array[Person] = []
	for i in n:
		var p := EV._put(crowd, at + Vector2(d, 0.0).rotated(start + TAU * float(i) / float(maxi(n, 1))))
		out.append(p)
	return out


static func _cast_reads_level(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := EV._fresh(made)

	# Silent Doom: level 3 in the dark strikes a person at 1.85 (the dark radius is 1.9); level 1 does not (1.6).
	var near := EV._put(crowd, at + Vector2(1.85, 0.0))
	var doom := FxTimeline.cast(SilentDoom, ctx, at, {"level": 3, "dark": true})
	doom._process(SilentDoom.T_STRIKE + 0.05)
	t.check(not near.is_alive(), "Silent Doom level 3 in the dark strikes a person at 1.85")
	doom.end_now()
	near = EV._put(crowd, at + Vector2(1.85, 0.0))
	var doom1 := FxTimeline.cast(SilentDoom, ctx, at, {"dark": true})
	doom1._process(SilentDoom.T_STRIKE + 0.05)
	t.check(near.is_alive(), "and at level 1 he is not struck")
	doom1.end_now()

	# Blight: level 3 in the dark sickens 4 (the picked one and three of those within 2.4); level 1 has the reach of 2.0.
	at = EV._fresh(made)
	var picked := EV._put(crowd, at)
	var others := _ring(crowd, at, 2.3, 6)
	t.check(BlightFx.sick_with(crowd, picked, 4, 2.4).size() == 4 and BlightFx.sick_with(crowd, picked, 4).size() == 1
		and BlightFx.sick_with(crowd, picked, 4, 2.4).slice(1).all(func(p: Person) -> bool: return others.has(p)),
		"sick_with(.., 4, 2.4) sickens four with the others at 2.3; the default reach of 2.0 finds none")
	var blight := FxTimeline.cast(BlightFx, ctx, at, {"level": 3, "dark": true}) as BlightFx
	blight._process(BlightFx.T_ROT + 0.1)
	var sick := 0
	for p in [picked] + others:
		sick += 1 if p.home_sick else 0
	t.check(sick == 4, "a level-3 Blight in the dark cast on a person makes four ill (%d)" % sick)
	blight.end_now()

	# Slumber: level 3 sleeps 24 s in a light ring of 1.6.
	at = EV._fresh(made)
	var fall := EV._put(crowd, at + Vector2(1.55, 0.0))
	var fall_out := EV._put(crowd, at + Vector2(0.0, 1.65))
	var slumber := FxTimeline.cast(SlumberFx, ctx, at, {"level": 3, "dark": false}) as SlumberFx
	slumber._process(SlumberFx.T_FALL + 0.05)
	t.check(is_equal_approx(slumber.lv_sleep_time, 24.0) and is_equal_approx(slumber._r, 1.6) and fall.is_asleep() and not fall_out.is_asleep(),
		"Slumber level 3 in the light: 24 s, a ring of 1.6 (%s, %s)" % [slumber.lv_sleep_time, slumber._r])
	slumber.end_now()
	var slumber1 := FxTimeline.cast(SlumberFx, ctx, at, {}) as SlumberFx
	t.check(slumber1.lv_sleep_time == SlumberFx.SLEEP_TIME, "and level 1 keeps SLEEP_TIME")
	slumber1.end_now()

	# Cloak of Night: level 4 in the light hides 4 (MOST 4), not 3.
	at = EV._fresh(made)
	_ring(crowd, at, 1.5, 6)
	var cloak := FxTimeline.cast(CloakOfNightFx, ctx, at, {"level": 4, "dark": false}) as CloakOfNightFx
	t.check(cloak._ids.size() == 4 and is_equal_approx(cloak.lv_span, 31.0) and is_equal_approx(cloak.duration, 31.0),
		"Cloak level 4 in the light hides four for 31 s (%d, %s)" % [cloak._ids.size(), cloak.lv_span])
	cloak.end_now()

	# Unseen Hour: level 3 in the dark veils 7.8 for 34 s.
	at = EV._fresh(made)
	var hour := FxTimeline.cast(UnseenHourFx, ctx, at, {"level": 3, "dark": true}) as UnseenHourFx
	t.check(is_equal_approx(hour.radius, 7.8) and is_equal_approx(hour.veil_time, 34.0),
		"Unseen Hour level 3 in the dark: 7.8 for 34 s (%s, %s)" % [hour.radius, hour.veil_time])
	hour.end_now()

	# Dreamless: level 4 in the light seats two (MOST 2); found 26 s after the sit.
	at = EV._fresh(made)
	_ring(crowd, at, 1.0, 3)
	var dream := FxTimeline.cast(DreamlessFx, ctx, at, {"level": 4, "dark": false}) as DreamlessFx
	dream._process(DreamlessFx.T_SIT + 0.05)
	t.check(dream.resting == 2 and is_equal_approx(dream.lv_rest, 26.0)
		and is_equal_approx(dream.rest_left(), DreamlessFx.T_SIT + 26.0 - dream.t) and is_equal_approx(dream.duration, DreamlessFx.T_SIT + 27.0),
		"Dreamless level 4 in the light: two sit, found at T_SIT + 26 (%d, %s)" % [dream.resting, dream.lv_rest])
	dream.end_now()

	# Dread: level 3 holds 30 s; in the light its reach is 6.5.
	at = EV._fresh(made)
	var dread := FxTimeline.cast(DreadOfTheDarkFx, ctx, at, {"level": 3, "dark": false}) as DreadOfTheDarkFx
	t.check(is_equal_approx(dread.lv_hold, 30.0) and is_equal_approx(dread.reach, 6.5)
		and is_equal_approx(dread.duration, DreadOfTheDarkFx.T_FALL + 30.0 + DreadOfTheDarkFx.T_FADE),
		"Dread level 3 in the light: held 30 s, reach 6.5 (%s, %s)" % [dread.lv_hold, dread.reach])
	dread.end_now()
	var dread1 := FxTimeline.cast(DreadOfTheDarkFx, ctx, at, {"dark": true}) as DreadOfTheDarkFx
	t.check(dread1.lv_hold == DreadOfTheDarkFx.HOLD and dread1.reach == 12.0, "and level 1 keeps HOLD and its 12 in the dark")
	dread1.end_now()

	# Shadow Play: level 3 in the dark a circle of 6.6, ending T_RISE + 34 s.
	at = EV._fresh(made)
	var play := FxTimeline.cast(ShadowPlayFx, ctx, at, {"level": 3, "dark": true}) as ShadowPlayFx
	t.check(is_equal_approx(play._r, 6.6) and is_equal_approx(play.lv_span, 34.0) and is_equal_approx(play.duration, ShadowPlayFx.T_RISE + 34.0),
		"Shadow Play level 3 in the dark: 6.6, ends at T_RISE + 34 (%s, %s)" % [play._r, play.duration])
	play.end_now()

	# The Swallowing Dark: level 3 in the light grows to 10.4 at 0.6 a second.
	at = EV._fresh(made)
	var swallow := FxTimeline.cast(TheSwallowingDarkFx, ctx, at, {"level": 3, "dark": false}) as TheSwallowingDarkFx
	t.check(is_equal_approx(swallow.full_r, 10.4) and is_equal_approx(swallow.lv_grow, 0.6) and is_equal_approx(swallow.t_full, 10.4 / 0.6),
		"Swallowing Dark level 3 in the light: 10.4 at 0.6 a second (%s, %s)" % [swallow.full_r, swallow.t_full])
	swallow.end_now()

	# Evernight: level 4 by day lasts 66 s and lights 5 torches (6 soldiers could).
	at = EV._fresh(made)
	var soldiers: Array[Person] = []
	for i in 6:
		soldiers.append(EV._put(crowd, at + Vector2(-20.0 + 8.0 * float(i), 12.0), true))
	var night := FxTimeline.cast(EvernightFx, ctx, at, {"level": 4}) as EvernightFx
	t.check(is_equal_approx(night.night_time, 66.0) and night.lv_torches == 5 and night.lv_take_last == 11
		and EvernightFx.bearers(crowd, night.lv_torches).size() == 5 and EvernightFx.bearers(crowd).size() == 6,
		"Evernight level 4 by day: 66 s, 5 torches of 6 soldiers, the last take 11 (%s, %d)" % [night.night_time, night.lv_torches])
	night.end_now()


# --- The dusk -------------------------------------------------------------------------------------------------------------------

static func _dusk_by_level(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := EV._fresh(made)
	var slumber := FxTimeline.cast(SlumberFx, ctx, at, {"level": 3}) as SlumberFx
	t.check(is_equal_approx(crowd.dusk.r_at(at), 3.5), "a level-3 Slumber lays a dusk of 3.5 (%s)" % crowd.dusk.r_at(at))
	crowd.dusk.step(23.9)
	t.check(crowd.dusk.r_at(at) > 0.0, "live at 23.9 s")
	crowd.dusk.step(0.2)
	t.check(crowd.dusk.r_at(at) == 0.0, "and gone after 24.0 s")
	slumber.end_now()
	crowd.dusk.clear()
	var slumber1 := FxTimeline.cast(SlumberFx, ctx, at, {}) as SlumberFx
	t.check(is_equal_approx(crowd.dusk.r_at(at), 3.0), "a level-1 cast lays 3.0 (unchanged)")
	crowd.dusk.step(19.9)
	t.check(crowd.dusk.r_at(at) > 0.0, "live at 19.9 s")
	crowd.dusk.step(0.2)
	t.check(crowd.dusk.r_at(at) == 0.0, "and gone after 20.0 s")
	slumber1.end_now()

	# A power's own area wins when it is larger: Swallowing Dark lays its full size.
	EV._fresh(made)
	var swallow := FxTimeline.cast(TheSwallowingDarkFx, ctx, at, {"level": 3, "dark": false}) as TheSwallowingDarkFx
	swallow._process(swallow.t_full + 0.1)
	t.check(is_equal_approx(crowd.dusk.r_at(at), 10.4), "Swallowing Dark lays its full_r, 10.4 at level 3 (%s)" % crowd.dusk.r_at(at))
	swallow.end_now()

	# Evernight lays none.
	EV._fresh(made)
	var night := FxTimeline.cast(EvernightFx, ctx, at, {"level": 5}) as EvernightFx
	night._process(EvernightFx.WAVE + 0.5)
	t.check(crowd.dusk.count() == 0, "Evernight lays no dusk (%d)" % crowd.dusk.count())
	night.end_now()

	# A blighted building's foothold: level 5 in the dark is 6.2, level 1 in the light 3.0.
	EV._fresh(made)
	var env: EnvironmentField = made[1]
	var target: Structure = null
	for s in env.structures():
		if BlightFx.building(s) and (target == null or s.get_instance_id() < target.get_instance_id()):
			target = s
	t.check(target != null, "(a standing building to blight)")
	if target != null:
		var c := target.center()
		var blight := FxTimeline.cast(BlightFx, ctx, c, {"level": 5, "dark": true}) as BlightFx
		blight._process(BlightFx.T_ROT + 0.1)
		t.check(crowd.footholds.has(target) and is_equal_approx(crowd.dusk.r_at(c), 6.2),
			"a level-5 Blight in the dark leaves a foothold of 6.2 (%s)" % crowd.dusk.r_at(c))
		blight.end_now()
		BlightFx.heal(crowd, env, target)
		crowd.dusk.clear()
		var blight1 := FxTimeline.cast(BlightFx, ctx, c, {"dark": false}) as BlightFx
		blight1._process(BlightFx.T_ROT + 0.1)
		t.check(crowd.footholds.has(target) and is_equal_approx(crowd.dusk.r_at(c), 3.0),
			"and level 1 in the light leaves 3.0 (%s)" % crowd.dusk.r_at(c))
		blight1.end_now()
		BlightFx.heal(crowd, env, target)
	crowd.dusk.clear()


# --- The aim --------------------------------------------------------------------------------------------------------------------

static func _previews(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := EV._fresh(made)
	var rules := Rules.new().setup(PackedStringArray(["cloak", "dreamless", "blight", "dread"]), null, made[1], made[3], crowd, made[6])
	rules.levels = {"cloak": 3, "dreamless": 5, "blight": 5, "dread": 5}
	var aim := Targeting.new().setup(rules, crowd)
	aim.pick(0)
	aim.hover(at)
	t.check(is_equal_approx(float(aim.area().r), 2.1), "Cloak at level 3 over light ground rings 2.1 (%s)" % [aim.area()])
	crowd.lay_dusk(at, 1.0, 120.0)
	t.check(crowd.in_dark(at) and is_equal_approx(float(aim.area().r), 4.5), "and over dark ground 4.5 (%s)" % [aim.area()])
	t.check(Targeting.AREAS.cloak.r == 2.0 and Targeting.area_at("cloak", 5) == Targeting.AREAS.cloak, "AREAS stays level 1")
	aim.pick(3)
	aim.hover(at + Vector2(9.0, 0.0))
	t.check(not crowd.in_dark(at + Vector2(9.0, 0.0)) and is_equal_approx(float(aim.area().r), 7.0),
		"Dread at level 5 over light ground rings 7.0 (level 1: 6.0) (%s)" % [aim.area()])
	aim.hover(at)
	t.check(crowd.in_dark(at) and is_equal_approx(float(aim.area().r), 12.0), "and over dark ground 12.0 (%s)" % [aim.area()])
	aim.free()
	rules.free()
	crowd.dusk.clear()
	EV._fresh(made)
	_ring(crowd, at, 3.0, 12)
	t.check(Targeting.veil_ringed("cloak", crowd, at, true, 4).size() == 11 and Targeting.veil_ringed("cloak", crowd, at, true).size() == 8
		and Targeting.veil_ringed("cloak", crowd, at, false, 4).size() == 0,
		"veil_ringed: the dark level-4 cloak takes 11 of 12 in reach, level 1 takes 8, the light one (2.15) none at 3.0")
	EV._fresh(made)
	_ring(crowd, at, 1.1, 3)
	t.check(Targeting.veil_ringed("dreamless", crowd, at, false, 5).size() == 2 and Targeting.veil_ringed("dreamless", crowd, at, false).size() == 0,
		"the light level-5 Dreamless rings two within 1.2; level 1 (1.0) none at 1.1")
	EV._fresh(made)
	for q in crowd.citizens + crowd.soldiers:
		q.home_sick = false  # the casts above sickened some: they would not be "ill able" here
	var p := EV._put(crowd, at)
	_ring(crowd, at, 2.5, 6)
	t.check(Targeting.blight_ill(crowd, p, true, 5).size() == 5 and Targeting.blight_ill(crowd, p, true).size() == 1
		and Targeting.blight_ill(crowd, p, true, 1).size() == 1 and Targeting.blight_ill(crowd, p, false, 5).size() == 1,
		"blight_ill: level 5 in the dark takes five within 2.8; level 1 (2.0) only the picked one")


static func _refusal(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := EV._fresh(made)
	crowd.lay_dusk(at + Vector2(7.2, 0.0), 0.6, 120.0)
	var rules := Rules.new().setup(PackedStringArray(["dread"]), null, made[1], made[3], crowd, made[6])
	var casts: Array = []
	rules.caster = func(s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		var fx := FxTimeline.cast(s, made[5], g, e)
		casts.append([fx, e])
		return fx
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, why: String) -> void: refused.append([slot, why]))
	var got := rules.cast(0, at)
	t.check(got == null and refused == [[0, "no_dark"]] and rules.cooldown_left(0) == 0.0,
		"level 1: dusk only 6.6 from the click is refused (%s)" % [refused])
	t.check(DreadOfTheDarkFx.refusal(crowd, at, false) == "no_dark" and DreadOfTheDarkFx.refusal(crowd, at, false, 5) == "",
		"refusal() takes the level's light reach (6.0 refuses, 7.0 allows)")
	refused.clear()
	rules.levels = {"dread": 5}
	got = rules.cast(0, at)
	t.check(got != null and refused.is_empty() and casts.size() == 1 and int(casts[0][1].level) == 5 and is_equal_approx(rules.cooldown_left(0), 58.0),
		"level 5: the same click is cast (7.0 reach), the level told and its 58 s cooldown started (%s)" % [refused])
	if got != null:
		got.end_now()
	rules.free()
	crowd.dusk.clear()


## A level-5 cast of each of the ten plays level 5's numbers and builds nothing level 1 does not (no node more, none less).
static func _gate_builds(t, made: Array) -> void:
	var ctx: FxContext = made[5]
	var all_same := true
	var bad := PackedStringArray()
	for key: String in KEYS:
		var counts := []
		for lv in [1, 5]:
			var at := EV._fresh(made)
			_ring(made[0], at, 1.0, 2)
			var before := [ctx.overhead.get_child_count(), ctx.ground.get_child_count(), (made[4] as Node).get_child_count()]
			var fx := FxTimeline.cast(load(String(PowerBook.get_power(key).path)), ctx, at, {"level": lv, "dark": true})
			fx._process(0.2)
			counts.append([ctx.overhead.get_child_count() - before[0], ctx.ground.get_child_count() - before[1],
				(made[4] as Node).get_child_count() - before[2]])
			fx.end_now()
		if counts[0] != counts[1]:
			bad.append("%s %s" % [key, counts])
			all_same = false
	t.check(all_same, "a level-5 cast of each builds the same nodes as level 1 (no twist yet in G1): %s" % [bad])
