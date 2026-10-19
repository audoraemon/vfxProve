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


## Read `path`; a missing or damaged file, or a value that is not a number, leaves the default (1.0); numbers clamp to 0..1.
func load_from(path := PATH) -> Settings:
	music = 1.0
	sfx = 1.0
	ui = 1.0
	var cf := ConfigFile.new()
	if cf.load(path) != OK:
		return self
	for key: String in BUSES:
		var v: Variant = cf.get_value(SECTION, key, 1.0)
		if typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT:
			set(key, clampf(float(v), 0.0, 1.0))
	return self


func save_to(path := PATH) -> void:
	var cf := ConfigFile.new()
	for key: String in BUSES:
		cf.set_value(SECTION, key, snappedf(float(get(key)), 0.001))
	cf.save(path)


## Put every volume on its bus. A bus the layout lacks is skipped (test_audio_mix says so when the layout did not load).
func apply() -> void:
	for key: String in BUSES:
		var i := AudioServer.get_bus_index(BUSES[key])
		if i >= 0:
			AudioServer.set_bus_volume_db(i, bus_db(float(get(key))))


## -80 dB (silence) at 0, else the linear volume in decibels.
static func bus_db(v: float) -> float:
	return -80.0 if v <= 0.0 else linear_to_db(v)


func level(key: String) -> float:
	return float(get(key)) if BUSES.has(key) else 1.0


func set_level(key: String, v: float) -> void:
	if not BUSES.has(key):
		return
	set(key, clampf(v, 0.0, 1.0))
	apply()
