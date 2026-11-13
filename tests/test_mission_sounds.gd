extends RefCounted
## Mission event sounds (mission sound pass): MissionDirector._sound() plays a cue where a mission's moment happens through
## the FX context's player, and nothing without one, for a cue the catalog lacks or with no place; every cue a director or
## the omen names is in the catalog with its takes.

const CUES := [&"msn_door", &"msn_unbar", &"msn_gate_out", &"msn_cart", &"msn_grain", &"msn_rot", &"msn_mob", &"msn_seize",
	&"msn_bolt", &"msn_star_fall", &"msn_star_land", &"msn_chant", &"msn_knock", &"msn_cheer", &"msn_address", &"msn_scatter",
	&"msn_gather", &"msn_shut", &"msn_fanfare", &"msn_boat", &"msn_shatter", &"msn_light_out", &"msn_relight", &"msn_knights",
	&"msn_standard", &"msn_dismay", &"msn_preach", &"msn_eye_sees", &"msn_doom", &"msn_shackle", &"msn_ruin", &"msn_rebuild",
	&"msn_rope", &"msn_lock"]


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


## Every cue the directors, the falling star and the mission's rite and ferry name is a catalog cue, and each cue is heard.
static func _named(t) -> void:
	var named := {}
	var re := RegEx.create_from_string("(?:_sound|ctx\\.play)\\(&\"(\\w+)\"")
	for path in _scripts():
		for m in re.search_all(FileAccess.get_file_as_string(path)):
			named[StringName(m.get_string(1))] = path
	for cue: StringName in named:
		t.check(Sfx.CATALOG.has(cue), "%s (named in %s) is a catalog cue" % [cue, named[cue]])
	for cue: StringName in CUES:
		t.check(named.has(cue), "%s is heard in a mission" % cue)


## The scripts that play mission cues: every director, the omen's falling star, and the mission's rite and ferry.
static func _scripts() -> Array:
	var out := ["res://src/game/mission.gd"]
	for dir in ["res://src/game/mission/", "res://src/fx/omen/"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				out.append(dir + f)
	return out
