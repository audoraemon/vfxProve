class_name PowerBook
extends RefCounted
## The draftable powers: Divine Power cost, cooldown (seconds), how they are aimed, their effect script and icons, and
## their kind (v0.06: the draft's tabs).
## Costs and cooldowns are the spec's starting values (§4.2); aim "drag" = press at the start point, drag the
## direction, release. The two quiet powers (v0.05, "quiet") register no danger for the town and raise no alarm
## when cast (Crowd.on_cast()): Silent Doom's deaths count only if someone saw them, Blight adds one alarm.

const POWERS := [
	{"key": "doom", "name": "Silent Doom", "path": "res://src/fx/quiet/silent_doom.gd",
		"dp": 8, "cooldown": 15.0, "aim": "click", "shape": "up to 3 struck down, unseen", "quiet": true,
		"kind": "quiet"},
	{"key": "wisp", "name": "Will-o'-Wisp", "path": "res://src/fx/control/will_o_wisp.gd",
		"dp": 10, "cooldown": 25.0, "aim": "click", "shape": "lures up to 25 calm people, 12 s", "quiet": true,
		"kind": "control"},
	{"key": "heaven", "name": "Heaven Splitter", "path": "res://src/fx/set2/heaven_splitter.gd",
		"dp": 10, "cooldown": 20.0, "aim": "drag", "shape": "line + 8 fissures", "kind": "cataclysm"},
	{"key": "blight", "name": "Blight", "path": "res://src/fx/quiet/blight.gd",
		"dp": 12, "cooldown": 25.0, "aim": "click", "shape": "ruins a well, bell, gate, dock or rite", "quiet": true,
		"kind": "quiet"},
	{"key": "thorns", "name": "Thornwall", "path": "res://src/fx/control/thornwall.gd",
		"dp": 14, "cooldown": 30.0, "aim": "drag", "shape": "3-unit bramble wall, 25 s", "quiet": true,
		"kind": "control"},
	{"key": "tornado", "name": "Tornado Tempest", "path": "res://src/fx/set2/tornado_tempest.gd",
		"dp": 15, "cooldown": 30.0, "aim": "click", "shape": "roaming vortex, 10 s", "kind": "cataclysm"},
	{"key": "dragon", "name": "Dragonfire Parade", "path": "res://src/fx/set2/dragonfire_parade.gd",
		"dp": 18, "cooldown": 35.0, "aim": "click", "shape": "cone, faces down-right on screen", "kind": "cataclysm"},
	{"key": "tsunami", "name": "Tsunami Breaker", "path": "res://src/fx/set2/tsunami_breaker.gd",
		"dp": 20, "cooldown": 40.0, "aim": "drag", "shape": "moving wall", "kind": "cataclysm"},
	{"key": "gravity", "name": "Gravity Distortion", "path": "res://src/fx/gravity_distortion.gd",
		"dp": 20, "cooldown": 45.0, "aim": "click", "shape": "pull field", "kind": "cataclysm"},
	{"key": "laser", "name": "Walking Laser Grid", "path": "res://src/fx/walking_laser_grid.gd",
		"dp": 22, "cooldown": 45.0, "aim": "drag", "shape": "moving lane", "kind": "cataclysm"},
	{"key": "orbital", "name": "Orbital Strike", "path": "res://src/fx/orbital_strike.gd",
		"dp": 22, "cooldown": 45.0, "aim": "click", "shape": "random bombardment", "kind": "cataclysm"},
	{"key": "cinder", "name": "Cinderfall Barrage", "path": "res://src/fx/set2/cinderfall_barrage.gd",
		"dp": 25, "cooldown": 50.0, "aim": "click", "shape": "volcano + stone rain", "kind": "cataclysm"},
	{"key": "judgement", "name": "Judgement of the Ancients", "path": "res://src/fx/set2/judgement_of_the_ancients.gd",
		"dp": 30, "cooldown": 60.0, "aim": "click", "shape": "8 punches + slam", "kind": "cataclysm"},
	{"key": "glacial", "name": "Glacial Cataclysm", "path": "res://src/fx/set2/glacial_cataclysm.gd",
		"dp": 30, "cooldown": 60.0, "aim": "click", "shape": "burst + freeze + ice", "kind": "cataclysm"},
	{"key": "nova", "name": "Nuclear Nova", "path": "res://src/fx/nuclear_nova.gd",
		"dp": 40, "cooldown": 120.0, "aim": "click", "shape": "huge circle", "kind": "cataclysm"},
]
const ICON_DIR := "res://assets/pixellab/icons/"
## Preview clips for the draft: each power recorded once from the sandbox (bash tools/capture.sh --capture-clip)
## into one sprite sheet -- CLIP_FRAMES frames spread over the whole effect, CLIP_COLUMNS to a row.
const CLIP_DIR := "res://assets/clips/"
const CLIP_FRAMES := 16
const CLIP_COLUMNS := 4
const CLIP_SIZE := Vector2i(152, 86)
## How fast the draft plays a clip: 16 frames at 8 a second is a two-second time-lapse of the whole power.
const CLIP_FPS := 8.0


## How far each power is seen and heard, how severe it is and how long it stays dangerous (v0.04 local awareness):
## [sight, sound, severity, seconds]. People inside its area plus Person.THREAT_MARGIN run clear of it; within sight
## or earshot they stop and look; beyond that they go on with their day.
const REACH := {
	"heaven": [6.0, 9.0, 0.5, 3.0], "tornado": [8.0, 11.0, 0.6, 10.0], "dragon": [8.0, 11.0, 0.6, 5.0],
	"tsunami": [8.0, 12.0, 0.7, 5.0], "gravity": [6.0, 9.0, 0.6, 6.0], "laser": [7.0, 10.0, 0.6, 6.0],
	"orbital": [9.0, 14.0, 0.7, 6.0], "cinder": [10.0, 16.0, 0.8, 8.0], "judgement": [9.0, 14.0, 0.8, 6.0],
	"glacial": [8.0, 12.0, 0.7, 6.0], "nova": [40.0, 40.0, 1.0, 4.0],
}
## For a cast with no known power (the sandbox, scripted tests): v0.03's single 7-unit fright, heard to 10.
const REACH_DEFAULT := [7.0, 10.0, 0.6, 4.0]


static func get_power(key: String) -> Dictionary:
	for p: Dictionary in POWERS:
		if p.key == key:
			return p
	return {}


## The draft's tabs (v0.06): what a power is for.
const KINDS := ["cataclysm", "control", "quiet", "curse"]
const KIND_TITLES := ["CATACLYSM", "CONTROL", "QUIET", "CURSE"]


static func of_kind(kind: String) -> PackedStringArray:
	var out := PackedStringArray()
	for p: Dictionary in POWERS:
		if String(p.get("kind", "")) == kind:
			out.append(p.key)
	return out


static func kind_of(key: String) -> String:
	return String(get_power(key).get("kind", ""))


## A quiet power (v0.05): its cast is no danger the town can see.
static func is_quiet(key: String) -> bool:
	return bool(get_power(key).get("quiet", false))


static func keys() -> PackedStringArray:
	var out := PackedStringArray()
	for p: Dictionary in POWERS:
		out.append(p.key)
	return out


## 84x84 painted icon (Prepare cards).
static func icon(key: String) -> Texture2D:
	return load(ICON_DIR + key + ".png")


## 42x42 copy for the HUD slots.
static func hud_icon(key: String) -> Texture2D:
	return load(ICON_DIR + "hud/" + key + ".png")


static func clip_path(key: String) -> String:
	return CLIP_DIR + key + ".png"


## The power's preview sheet, or null when it has not been recorded.
static func clip(key: String) -> Texture2D:
	var path := clip_path(key)
	return load(path) if ResourceLoader.exists(path) else null


## Where frame `i` sits in a sheet.
static func clip_frame(i: int) -> Rect2:
	return Rect2(Vector2(float(i % CLIP_COLUMNS) * CLIP_SIZE.x, float(i / CLIP_COLUMNS) * CLIP_SIZE.y), Vector2(CLIP_SIZE))
