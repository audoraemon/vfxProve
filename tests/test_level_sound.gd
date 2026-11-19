extends RefCounted
## A power heard heavier at a higher level (LevelSound, skill-tree sound pass): FxContext.play makes a power's cues louder
## and lower per level and, from level 4, lays its school's weight under its main cue; every skill-tree power names a
## main cue it plays and a school with a weight.


## A stand-in for the battlefield's Sfx that writes down what it was asked to play and at what pitch.
class Rec extends Node:
	var played: Array = []
	var pitches: Array = []

	func play(cue: StringName, at: Vector2, db := 0.0) -> Variant:
		var p := Node.new()
		played.append([cue, at, db])
		pitches.append(1.0)
		p.set_meta(&"i", played.size() - 1)
		add_child(p)
		return p

	func set_voice_pitch(p: Node, mul: float) -> void:
		pitches[int(p.get_meta(&"i"))] = mul


static func run(t) -> void:
	_levels(t)
	_main_cues(t)
	_hearing(t)


static func _play_at(level: int, cue: StringName) -> Rec:
	var ctx := FxContext.new()
	var rec := Rec.new()
	ctx.sfx = rec
	ctx.hear([level, &"smite_strike", &"lvl_ruin"])
	ctx.play(cue, Vector2(2, 3), -5.0)
	return rec


static func _levels(t) -> void:
	var one := _play_at(1, &"smite_strike")
	t.check(one.played.size() == 1 and is_equal_approx(one.played[0][2], -5.0) and one.pitches[0] == 1.0,
		"at level 1 a cue plays as called (%s)" % [one.played])
	var three := _play_at(3, &"smite_strike")
	t.check(three.played.size() == 1, "under level 4 the main cue carries no weight (%s)" % [three.played])
	t.near(three.played[0][2], -5.0 + 2.0 * LevelSound.LEVEL_DB, 0.001, "level 3 plays two steps louder")
	t.check(three.pitches[0] < 1.0, "level 3 plays lower (%s)" % three.pitches[0])
	var five := _play_at(5, &"smite_strike")
	t.check(five.played.size() == 2 and five.played[1][0] == &"lvl_ruin" and five.played[1][1] == Vector2(2, 3),
		"at level 5 the main cue carries its school's weight where it plays (%s)" % [five.played])
	t.near(five.played[1][2], -5.0 + LevelSound.weight_db(5), 0.001, "the weight sits under the main cue's call")
	t.check(LevelSound.weight_db(5) > LevelSound.weight_db(4) and LevelSound.weight_db(5) < 0.0,
		"the weight is stronger at level 5 and still under the main cue")
	var other := _play_at(5, &"smite_call")
	t.check(other.played.size() == 1 and other.played[0][2] > -5.0,
		"a power's other cues are heavier at level 5 but carry no weight (%s)" % [other.played])
	for r: Rec in [one, three, five, other]:
		r.free()


static func _main_cues(t) -> void:
	for school: String in LevelSound.WEIGHT:
		var w: StringName = LevelSound.WEIGHT[school]
		t.check(Sfx.CATALOG.has(w) and Sfx.paths_for(w).size() >= 2, "%s's weight %s is a catalog cue with its takes" % [school, w])
	for type: String in GodTree.RING:
		for tier in range(1, 6):
			for i in 2:
				var key := String(GodTree.TABLE[type][tier - 1][i])
				if key == "":
					continue
				t.check(LevelSound.MAIN.has(key) and LevelSound.MAIN[key][1] == type,
					"skill-tree power %s names its main cue and school %s" % [key, type])
				if not LevelSound.MAIN.has(key):
					continue
				var cue: StringName = LevelSound.MAIN[key][0]
				var path := String(PowerBook.get_power(key).get("path", ""))
				t.check(Sfx.CATALOG.has(cue), "%s's main cue %s is a catalog cue" % [key, cue])
				t.check(FileAccess.get_file_as_string(path).contains("&\"%s\"" % cue), "%s plays its main cue %s (%s)" % [key, cue, path])


static func _hearing(t) -> void:
	t.check(LevelSound.key_of(load(String(PowerBook.get_power("smite").path))) == "smite", "an effect script names its power")
	t.check(LevelSound.key_of(null) == "", "no script, no power")
	var ctx := FxContext.new()
	var was := ctx.hearing()
	ctx.hear([5, &"a", &"b"])
	t.check(ctx.level == 5 and ctx.main_cue == &"a" and ctx.weight_cue == &"b", "a power's hearing is set while its code runs")
	ctx.hear(was)
	t.check(ctx.level == 1 and ctx.main_cue == &"" and ctx.weight_cue == &"", "and put back after")
