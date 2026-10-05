class_name SaveFile
extends RefCounted
## What survives between runs (spec §6; per mission since v0.08): the difficulty, the mission last chosen, and for
## each mission its best result -- the best score with the rank it earned, or whether it was won and its bonus
## earned -- and the last loadout drafted for it, so Prepare can preselect it. One ConfigFile, and a bad read is
## never fatal -- a player with a corrupted save should lose their best score, not the game.
##   [kak]                 difficulty, last_mission
##   [mission.<id>]        best_score, best_rank, won, bonus, last_loadout, paths_won
##   [campaign]            night, dp, bites, tally_<path>, last_path, bell_rang, nights_won, ending (v0.10)
## paths_won (v0.09) is the paths of the Long Night that were won: a night won by a new path is a new best.
## A save from before v0.08 kept best_score, best_rank and last_loadout in [kak]: they are Last Judgement's.

const PATH := "user://kak_save.cfg"
const SECTION := "kak"
## A mission's section is this prefix and its id.
const MISSION_SECTION := "mission."
## The rank shown when nothing has been scored yet.
const NO_RANK := "-"

## The difficulty last chosen (v0.05; ResponseProfile.Tier).
var difficulty := ResponseProfile.DEFAULT
## The mission last picked on the board (v0.08), for the board's selection and Prepare.
var last_mission := MissionBook.LAST_JUDGEMENT
## The Lantern campaign begun or ended (v0.10), or null when none was ever begun.
var campaign: CampaignState
## Last Judgement's best, for the Title (read-only).
var best_score: int:
	get:
		return int(best(MissionBook.LAST_JUDGEMENT).best_score)
var best_rank: String:
	get:
		return String(best(MissionBook.LAST_JUDGEMENT).best_rank)

## Mission id -> {best_score, best_rank, won, bonus, last_loadout, paths_won}.
var _missions := {}


func load_from(path := PATH) -> SaveFile:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		# Missing is the normal first run; damaged is rare and not worth a crash. Either way: defaults.
		return self
	difficulty = clampi(int(cfg.get_value(SECTION, "difficulty", ResponseProfile.DEFAULT)), 0,
		ResponseProfile.NAMES.size() - 1) as ResponseProfile.Tier
	var wanted := String(cfg.get_value(SECTION, "last_mission", MissionBook.LAST_JUDGEMENT))
	last_mission = wanted if MissionBook.get_mission(wanted).id == wanted else MissionBook.LAST_JUDGEMENT
	for section in cfg.get_sections():
		if section.begins_with(MISSION_SECTION):
			_read(cfg, section, section.trim_prefix(MISSION_SECTION))
	# Before v0.08 the one mission's numbers sat in [kak].
	if not cfg.has_section(MISSION_SECTION + MissionBook.LAST_JUDGEMENT):
		_read(cfg, SECTION, MissionBook.LAST_JUDGEMENT)
	campaign = CampaignState.read(cfg)
	return self


func save_to(path := PATH) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "difficulty", int(difficulty))
	cfg.set_value(SECTION, "last_mission", last_mission)
	for id in _missions:
		var entry: Dictionary = _missions[id]
		var section: String = MISSION_SECTION + id
		for key in ["best_score", "best_rank", "won", "bonus", "last_loadout", "paths_won"]:
			cfg.set_value(section, key, entry[key])
	if campaign != null:
		campaign.write(cfg)
	var err := cfg.save(path)
	if err != OK:
		push_warning("KAK could not write its save file (%d): %s" % [err, path])


## A mission's best: best_score, best_rank, won, bonus and paths_won (a copy; defaults when it was never played).
func best(id: String) -> Dictionary:
	var entry := _entry(id)
	return {"best_score": entry.best_score, "best_rank": entry.best_rank, "won": entry.won, "bonus": entry.bonus,
		"paths_won": PackedStringArray(entry.paths_won)}


## Take a finished mission's result (Rules.result()). True when it is a new best, which is what earns the NEW BEST!
## line: a higher score for a scored mission, else a first win or a first bonus earned.
func record(id: String, result: Dictionary) -> bool:
	var entry := _entry(id)
	var won := bool(result.get("won", false))
	if result.has("score"):
		entry.won = entry.won or won
		var new_path := false
		var path := String(result.get("path", ""))
		var paths: PackedStringArray = entry.paths_won
		if won and path != "" and not paths.has(path):
			paths.append(path)
			entry.paths_won = paths  # (a packed array is a value: the entry keeps the copy that grew)
			new_path = true
		var score := int(result.score)
		if score <= int(entry.best_score):
			return new_path
		entry.best_score = score
		entry.best_rank = String(result.get("rank", NO_RANK))
		return true
	var bonus := false
	for b in result.get("bonuses", []):
		bonus = bonus or bool((b as Dictionary).get("earned", false))
	var better: bool = (won and not entry.won) or (bonus and not entry.bonus)
	entry.won = entry.won or won
	entry.bonus = entry.bonus or bonus
	return better


## The last loadout drafted for a mission, in slot order. Empty when there is nothing to preselect.
func loadout_for(id: String) -> PackedStringArray:
	return PackedStringArray(_entry(id).last_loadout)


func remember_loadout(id: String, keys: PackedStringArray) -> void:
	_entry(id).last_loadout = _known(id, keys)


## A mission's entry, made on first use.
func _entry(id: String) -> Dictionary:
	if not _missions.has(id):
		_missions[id] = {"best_score": 0, "best_rank": NO_RANK, "won": false, "bonus": false,
			"last_loadout": PackedStringArray(), "paths_won": PackedStringArray()}
	return _missions[id]


## One mission's numbers from a section of the file.
func _read(cfg: ConfigFile, section: String, id: String) -> void:
	var entry := _entry(id)
	entry.best_score = int(cfg.get_value(section, "best_score", 0))
	entry.best_rank = String(cfg.get_value(section, "best_rank", NO_RANK))
	entry.won = bool(cfg.get_value(section, "won", false))
	entry.bonus = bool(cfg.get_value(section, "bonus", false))
	entry.last_loadout = _known(id, PackedStringArray(cfg.get_value(section, "last_loadout", PackedStringArray())))
	var paths = cfg.get_value(section, "paths_won", PackedStringArray())
	entry.paths_won = PackedStringArray(paths) if paths is PackedStringArray or paths is Array else PackedStringArray()


## Only keys that are still powers, and that the mission allows. A save from an older build (or a hand-edited one)
## cannot put a key the game has never heard of into the draft.
func _known(id: String, keys: PackedStringArray) -> PackedStringArray:
	var def := MissionBook.get_mission(id)
	var out := PackedStringArray()
	for key in keys:
		if not PowerBook.get_power(key).is_empty() and def.allows(key):
			out.append(key)
	return out
