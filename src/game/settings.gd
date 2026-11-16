class_name Settings
extends RefCounted
## The player's volumes (v0.11.2, spec §2.1): Music, Sounds and Interface, each 0..1 (1 = the mix as authored, 0 = silent).
## Its own file, not the progress save: FLOW and the photograph runs write test saves, and a volume must never ride along
## with a test save or be lost with a damaged one. Game loads and applies it at boot; the Options panel changes and saves it.

const PATH := "user://kak_settings.cfg"
const SECTION := "audio"
## The bus each key sets.
const BUSES := {"music": "Music", "sfx": "SFX", "ui": "UI"}

var music := 1.0
var sfx := 1.0
var ui := 1.0
## The furthest the camera zooms out (logical zoom): ZOOM_OUT_NEAR (0.85, the default and the old fixed cap) down to ZOOM_OUT_FAR.
var zoom_out := ZOOM_OUT_NEAR

const VIEW_SECTION := "view"
const ZOOM_OUT_NEAR := 0.85
const ZOOM_OUT_FAR := 0.35
## The Options bar's steps between near and far (0.05 each).
const ZOOM_OUT_STEPS := 10
## What Mission.zoom_min() reads: the zoom_out of the Settings last apply()'d (Game's), read live so a change in the pause
## Options takes effect on resume. A headless run never applies one, so it keeps the default.
static var live_zoom_out := ZOOM_OUT_NEAR


## Read `path`; a missing or damaged file, or a value that is not a number, leaves the default (1.0); numbers clamp to 0..1.
func load_from(path := PATH) -> Settings:
	music = 1.0
	sfx = 1.0
	ui = 1.0
	zoom_out = ZOOM_OUT_NEAR
	var cf := ConfigFile.new()
	if cf.load(path) != OK:
		return self
	var z: Variant = cf.get_value(VIEW_SECTION, "zoom_out", ZOOM_OUT_NEAR)
	if typeof(z) == TYPE_FLOAT or typeof(z) == TYPE_INT:
		zoom_out = clean_zoom_out(float(z))
	for key: String in BUSES:
		var v: Variant = cf.get_value(SECTION, key, 1.0)
		if typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT:
			var f := float(v)
			set(key, clampf(f, 0.0, 1.0) if is_finite(f) else 1.0)  # nan and inf are damage: the default
	return self


func save_to(path := PATH) -> void:
	var cf := ConfigFile.new()
	for key: String in BUSES:
		cf.set_value(SECTION, key, snappedf(float(get(key)), 0.001))
	cf.set_value(VIEW_SECTION, "zoom_out", snappedf(zoom_out, 0.001))
	cf.save(path)


## Put every volume on its bus. A bus the layout lacks is skipped (test_audio_mix says so when the layout did not load).
func apply() -> void:
	live_zoom_out = zoom_out
	for key: String in BUSES:
		var i := AudioServer.get_bus_index(BUSES[key])
		if i >= 0:
			AudioServer.set_bus_volume_db(i, bus_db(float(get(key))))


## -80 dB (silence) at 0, else the linear volume in decibels.
static func bus_db(v: float) -> float:
	return -80.0 if v <= 0.0 else linear_to_db(v)


## The settings key ("music", "sfx", "ui") for a key or a bus name ("Music", "SFX", "UI"), or "" (and an error) for anything else.
static func key_for(name: String) -> String:
	for key: String in BUSES:
		if name == key or name == BUSES[key]:
			return key
	push_error("Settings: unknown volume '%s' (keys music/sfx/ui, buses Music/SFX/UI)" % name)
	return ""


func level(name: String) -> float:
	var key := key_for(name)
	return float(get(key)) if key != "" else 1.0


func set_level(name: String, v: float) -> void:
	var key := key_for(name)
	if key == "":
		return
	set(key, clampf(v, 0.0, 1.0) if is_finite(v) else 1.0)
	apply()


## `z` clamped to ZOOM_OUT_FAR..ZOOM_OUT_NEAR; nan and inf are damage: the default.
static func clean_zoom_out(z: float) -> float:
	return clampf(z, ZOOM_OUT_FAR, ZOOM_OUT_NEAR) if is_finite(z) else ZOOM_OUT_NEAR


## The Options bar's step (0 = near .. ZOOM_OUT_STEPS = far) of the zoom-out limit, and back.
func zoom_step() -> int:
	return roundi((ZOOM_OUT_NEAR - zoom_out) / (ZOOM_OUT_NEAR - ZOOM_OUT_FAR) * float(ZOOM_OUT_STEPS))


func set_zoom_step(step: int) -> void:
	var k := float(clampi(step, 0, ZOOM_OUT_STEPS)) / float(ZOOM_OUT_STEPS)
	zoom_out = snappedf(lerpf(ZOOM_OUT_NEAR, ZOOM_OUT_FAR, k), 0.001)
	live_zoom_out = zoom_out
