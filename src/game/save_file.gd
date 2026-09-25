class_name SaveFile
extends RefCounted
## What survives between runs (spec §6): the best score with the rank it earned, and the last loadout the
## player drafted, so Prepare can preselect it. One ConfigFile, three values, and a bad read is never fatal --
## a player with a corrupted save should lose their best score, not the game.

const PATH := "user://kak_save.cfg"
const SECTION := "kak"
## The rank shown when nothing has been scored yet.
const NO_RANK := "-"

var best_score := 0
var best_rank := NO_RANK
## The last drafted loadout, in slot order. Empty when there is nothing to preselect.
var last_loadout := PackedStringArray()


func load_from(path := PATH) -> SaveFile:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		# Missing is the normal first run; damaged is rare and not worth a crash. Either way: defaults.
		return self
	best_score = int(cfg.get_value(SECTION, "best_score", 0))
	best_rank = String(cfg.get_value(SECTION, "best_rank", NO_RANK))
	last_loadout = _known(PackedStringArray(cfg.get_value(SECTION, "last_loadout", PackedStringArray())))
	return self


func save_to(path := PATH) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "best_score", best_score)
	cfg.set_value(SECTION, "best_rank", best_rank)
	cfg.set_value(SECTION, "last_loadout", last_loadout)
	var err := cfg.save(path)
	if err != OK:
		push_warning("KAK could not write its save file (%d): %s" % [err, path])


## Take a finished mission's score. True when it is the new best, which is what earns the NEW BEST! line.
func record(score: int, rank: String) -> bool:
	if score <= best_score:
		return false
	best_score = score
	best_rank = rank
	return true


func remember_loadout(keys: PackedStringArray) -> void:
	last_loadout = _known(keys)


## Only keys that are still powers. A save from an older build (or a hand-edited one) cannot put a key the
## game has never heard of into the draft.
func _known(keys: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for key in keys:
		if not PowerBook.get_power(key).is_empty():
			out.append(key)
	return out
