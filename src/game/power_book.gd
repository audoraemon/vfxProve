class_name PowerBook
extends RefCounted
## The 11 draftable powers: Divine Power cost, cooldown (seconds), how they are aimed, their effect script and icons.
## Costs and cooldowns are the spec's starting values (§4.2); aim "drag" = press at the start point, drag the
## direction, release.

const POWERS := [
	{"key": "heaven", "name": "Heaven Splitter", "path": "res://src/fx/set2/heaven_splitter.gd",
		"dp": 10, "cooldown": 20.0, "aim": "drag", "shape": "line + 8 fissures"},
	{"key": "tornado", "name": "Tornado Tempest", "path": "res://src/fx/set2/tornado_tempest.gd",
		"dp": 15, "cooldown": 30.0, "aim": "click", "shape": "roaming vortex, 10 s"},
	{"key": "dragon", "name": "Dragonfire Parade", "path": "res://src/fx/set2/dragonfire_parade.gd",
		"dp": 18, "cooldown": 35.0, "aim": "click", "shape": "cone, faces down-right on screen"},
	{"key": "tsunami", "name": "Tsunami Breaker", "path": "res://src/fx/set2/tsunami_breaker.gd",
		"dp": 20, "cooldown": 40.0, "aim": "drag", "shape": "moving wall"},
	{"key": "gravity", "name": "Gravity Distortion", "path": "res://src/fx/gravity_distortion.gd",
		"dp": 20, "cooldown": 45.0, "aim": "click", "shape": "pull field"},
	{"key": "laser", "name": "Walking Laser Grid", "path": "res://src/fx/walking_laser_grid.gd",
		"dp": 22, "cooldown": 45.0, "aim": "drag", "shape": "moving lane"},
	{"key": "orbital", "name": "Orbital Strike", "path": "res://src/fx/orbital_strike.gd",
		"dp": 22, "cooldown": 45.0, "aim": "click", "shape": "random bombardment"},
	{"key": "cinder", "name": "Cinderfall Barrage", "path": "res://src/fx/set2/cinderfall_barrage.gd",
		"dp": 25, "cooldown": 50.0, "aim": "click", "shape": "volcano + stone rain"},
	{"key": "judgement", "name": "Judgement of the Ancients", "path": "res://src/fx/set2/judgement_of_the_ancients.gd",
		"dp": 30, "cooldown": 60.0, "aim": "click", "shape": "8 punches + slam"},
	{"key": "glacial", "name": "Glacial Cataclysm", "path": "res://src/fx/set2/glacial_cataclysm.gd",
		"dp": 30, "cooldown": 60.0, "aim": "click", "shape": "burst + freeze + ice"},
	{"key": "nova", "name": "Nuclear Nova", "path": "res://src/fx/nuclear_nova.gd",
		"dp": 40, "cooldown": 120.0, "aim": "click", "shape": "huge circle"},
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


static func get_power(key: String) -> Dictionary:
	for p: Dictionary in POWERS:
		if p.key == key:
			return p
	return {}


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
