extends RefCounted
## Mission event sounds (mission sound pass): MissionDirector._sound() plays a cue where a mission's moment happens through
## the FX context's player, and nothing without one, for a cue the catalog lacks or with no place; every cue a director or
## the omen names is in the catalog with its takes.

const CUES := [&"msn_door", &"msn_unbar", &"msn_gate_out", &"msn_cart", &"msn_grain", &"msn_rot", &"msn_mob", &"msn_seize",
	&"msn_bolt", &"msn_star_fall", &"msn_star_land", &"msn_chant"]


## A stand-in for the battlefield's Sfx that writes down what it was asked to play.
class Rec extends Node:
	var played: Array = []

	func play(cue: StringName, at: Vector2, _db := 0.0) -> Variant:
		played.append([cue, at])
		return null


static func run(t) -> void:
	_helper(t)
	_catalog(t)
	_named(t)


static func _helper(t) -> void:
	var d := MissionDirector.new()
	d._sound(&"msn_door", Vector2(3, 4))  # no context: nothing, and no error
	t.check(d.ctx == null, "a director with no FX context plays nothing")
	var rec := Rec.new()
	d.ctx = FxContext.new()
	d.ctx.sfx = rec
	d._sound(&"msn_door", Vector2(3, 4))
	d._sound(&"no_such_cue", Vector2(1, 1))
	d._sound(&"msn_cart", Vector2.INF)
	t.check(rec.played.size() == 1 and rec.played[0][0] == &"msn_door" and rec.played[0][1] == Vector2(3, 4),
		"_sound plays the cue where it happens, and skips a cue the catalog lacks and a moment with no place (%s)" % [rec.played])
	rec.free()


static func _catalog(t) -> void:
	for cue: StringName in CUES:
		t.check(Sfx.CATALOG.has(cue) and Sfx.paths_for(cue).size() >= 2, "%s is in the catalog with its takes" % cue)
		t.check(Sfx.CATALOG.get(cue, {}).get("voices", 0) >= 1, "%s has a voice limit" % cue)


## Every cue the directors and the falling star name is a catalog cue, and each tier-1 moment has its sound.
static func _named(t) -> void:
	var named := {}
	var re := RegEx.create_from_string("(?:_sound|ctx\\.play)\\(&\"(\\w+)\"")
	for dir in ["res://src/game/mission/", "res://src/fx/omen/"]:
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".gd"):
				continue
			var text := FileAccess.get_file_as_string(dir + f)
			for m in re.search_all(text):
				named[StringName(m.get_string(1))] = dir + f
	for cue: StringName in named:
		t.check(Sfx.CATALOG.has(cue), "%s (named in %s) is a catalog cue" % [cue, named[cue]])
	for cue: StringName in CUES:
		t.check(named.has(cue), "%s is heard in a mission" % cue)
