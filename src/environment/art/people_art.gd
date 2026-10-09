class_name PeopleArt
extends RefCounted
## People sprites (PixelLab people; docs/superpowers/specs/2026-10-03-pixellab-people-design.md): which design a
## citizen or soldier wears, and where each animation frame sits in the shared atlas (assets/pixellab/people/atlas.png,
## packed by tools/dev/make_people_atlas.py from the PixelLab frames). The atlas also holds a white silhouette of every
## frame: Person draws it over the sprite to tint it (char, ice, flash, sickness) with no shader of its own, so every
## person stays in one draw batch. Shown while SpriteArt.on(): F7 and `-- --art=procedural` switch people too.

const DIR := "res://assets/pixellab/people/"
const ANIMS := [&"idle", &"walk", &"run", &"stumble", &"death"]
## Frames a second per animation; stumble and death hold their last frame.
const FPS := {&"idle": 4.0, &"walk": 8.0, &"run": 12.0, &"stumble": 10.0, &"death": 12.0}
## FPS by ANIMS index.
const FPS_AT: Array[float] = [4.0, 8.0, 12.0, 10.0, 12.0]
## The diagonals, in atlas order: front-right, front-left, back-right, back-left.
enum Facing { SE, SW, NE, NW }
const DIR_NAMES := ["south-east", "south-west", "north-east", "north-west"]
## Each citizen role's designs, in CitizenProfile.Role order: one look, or two picked by the person's look. The
## capital's roles wear existing designs: the baker a merchant's, the washer a commoner's (a resident's), the dockworker
## the labourer's, the monk the priest's, the beggar the plainer resident look (no ragged design yet).
const CITIZEN := [["resident_a", "resident_b"], ["merchant_a", "merchant_b"], ["craft_a", "craft_b"], ["laborer"],
	["clergy"], ["caregiver_a", "caregiver_b"], ["farmer"], ["bellkeeper"], ["engineer"], ["watchman"],
	["mayor"], ["noble"], ["merchant_a", "merchant_b"], ["resident_a", "resident_b"], ["laborer"], ["clergy"],
	["resident_b"]]
## Designs not generated yet that wear another's until they are: the watchman (v0.08) the bellkeeper's dark navy coat
## and cap, the nearest to his dark cloak (Person draws his lantern over it); the Mayor (v0.09) a merchant's, with
## Person's gold chain over it, and the Prince's noble a resident's, with its crown; and the Lantern Knight (v0.10 M3)
## an escort's white tabard until M5's PixelLab pass.
const STAND_INS := {"watchman": "bellkeeper", "mayor": "merchant_a", "noble": "resident_a", "knight": "escort"}
## Each soldier's design, in Person.Corps order.
const SOLDIER := ["guard", "marshal", "escort", "rescue", "knight"]
## Stand-ins while a design is not generated yet.
const FALLBACK_CITIZEN := "resident_a"
const FALLBACK_SOLDIER := "guard"

static var _manifest := {}
static var _loaded := false
static var _atlas: Texture2D
## ready(), worked out once per manifest load: every person asks it every frame.
static var _ready := false
## Each design's frame table, read out of the manifest once (info()), and the manifest's load count, so a person that
## cached one can tell a reload made it stale.
static var _info := {}
static var generation := 0


static func manifest() -> Dictionary:
	if not _loaded:
		_loaded = true
		_manifest = {}
		var path := DIR + "manifest.json"
		if FileAccess.file_exists(path):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if parsed is Dictionary:
				_manifest = parsed
		if ResourceLoader.exists(DIR + "atlas.png"):
			_atlas = load(DIR + "atlas.png")
		_ready = not _manifest.is_empty() and _atlas != null
	return _manifest


static func reload() -> void:
	_loaded = false
	_info = {}
	generation += 1


## The atlas and its manifest are there (else people keep their procedural bodies).
static func ready() -> bool:
	if not _loaded:
		manifest()
	return _ready


static func atlas() -> Texture2D:
	manifest()
	return _atlas


static func has(design: String) -> bool:
	return manifest().get("designs", {}).has(design)


static func cell() -> Vector2:
	var c: Array = manifest().get("cell", [24, 24])
	return Vector2(c[0], c[1])


## The design a person should wear: its role's (its look, 0..1, picks between two), or its corps'.
static func wanted(soldier: bool, role: int, corps: int, look: float) -> String:
	if soldier:
		return SOLDIER[clampi(corps, 0, SOLDIER.size() - 1)]
	var looks: Array = CITIZEN[clampi(role, 0, CITIZEN.size() - 1)]
	return looks[mini(int(look * looks.size()), looks.size() - 1)]


## The design a person wears: the one it should, else the design standing in for it (STAND_INS), else its role's
## first look, else the stand-in.
static func design_for(soldier: bool, role: int, corps: int, look: float) -> String:
	var d := wanted(soldier, role, corps, look)
	if has(d):
		return d
	if STAND_INS.has(d) and has(STAND_INS[d]):
		return STAND_INS[d]
	if not soldier:
		var first: String = CITIZEN[clampi(role, 0, CITIZEN.size() - 1)][0]
		if has(first):
			return first
	return FALLBACK_SOLDIER if soldier else FALLBACK_CITIZEN


static func frame_count(design: String, anim: StringName, facing: int) -> int:
	var d: Dictionary = manifest().designs[design]
	return int(d.frames[String(anim)][DIR_NAMES[facing]])


## A design's frame table for drawing every frame of every person: [where its frames start, where its silhouettes
## start, its foot, the cell, its frame counts by ANIMS index * 4 + facing]. The same numbers as frame_rect(),
## silhouette_rect(), foot() and frame_count(), which look them up in the manifest's dictionaries call by call (and
## allocate their defaults): a person on screen needs them a few times a second, a crowd ~0.4 ms a frame.
static func info(design: String) -> Array:
	var got: Variant = _info.get(design)
	if got != null:
		return got
	var d: Dictionary = manifest().designs[design]
	var counts := PackedInt32Array()
	for anim in ANIMS:
		for f in DIR_NAMES.size():
			counts.append(frame_count(design, anim, f))
	var made := [Vector2(d.block[0], d.block[1]), Vector2(d.sil[0], d.sil[1]), foot(design), cell(), counts]
	_info[design] = made
	return made


static func _cell_offset(anim: StringName, facing: int, frame: int, n: int) -> Vector2:
	var c := cell()
	return Vector2((frame % n) * c.x, (ANIMS.find(anim) * 4 + facing) * c.y)


## The frame's rect in the atlas (frames wrap).
static func frame_rect(design: String, anim: StringName, facing: int, frame: int) -> Rect2:
	var d: Dictionary = manifest().designs[design]
	var b := Vector2(d.block[0], d.block[1])
	return Rect2(b + _cell_offset(anim, facing, frame, frame_count(design, anim, facing)), cell())


## The same frame's white silhouette.
static func silhouette_rect(design: String, anim: StringName, facing: int, frame: int) -> Rect2:
	var d: Dictionary = manifest().designs[design]
	var b := Vector2(d.sil[0], d.sil[1])
	return Rect2(b + _cell_offset(anim, facing, frame, frame_count(design, anim, facing)), cell())


## A pixel of the atlas's white square: flat shapes (a person's shadow) drawn from it, tinted, share the crowd's
## texture, so they do not break its draw batch the way an untextured rect does.
static func white_rect() -> Rect2:
	var w: Array = manifest().get("white", [0, 0])
	return Rect2(Vector2(w[0], w[1]) + Vector2(3, 3), Vector2.ONE)


## Where the feet are in a cell: drawn at -foot, the feet stand on the person's ground point.
static func foot(design: String) -> Vector2:
	var f: Array = manifest().designs[design].foot
	return Vector2(f[0], f[1])
