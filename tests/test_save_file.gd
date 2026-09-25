extends RefCounted
## The save file: defaults when there is nothing to read, a round trip, only better scores recorded, and a
## file that has been damaged or hand-edited does not take the game down with it.


static func run(t) -> void:
	var path := "user://test_save_file.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var fresh := SaveFile.new().load_from(path)
	t.check(fresh.best_score == 0 and fresh.best_rank == "-", "no save file means no best score (%d, %s)" % [fresh.best_score, fresh.best_rank])
	t.check(fresh.last_loadout.is_empty(), "and no loadout to preselect")

	# A better score is recorded, a worse one is not.
	t.check(fresh.record(6200, "B"), "the first score is the best score")
	t.check(fresh.best_score == 6200 and fresh.best_rank == "B", "and is kept with its rank (%d, %s)" % [fresh.best_score, fresh.best_rank])
	t.check(not fresh.record(5000, "C"), "a worse run does not beat it")
	t.check(fresh.best_score == 6200 and fresh.best_rank == "B", "and does not overwrite it (%d, %s)" % [fresh.best_score, fresh.best_rank])
	t.check(fresh.record(12500, "S"), "a better run does")
	t.check(fresh.best_score == 12500 and fresh.best_rank == "S", "with its own rank (%d, %s)" % [fresh.best_score, fresh.best_rank])

	fresh.remember_loadout(PackedStringArray(["nova", "heaven", "cinder", "gravity"]))
	fresh.save_to(path)
	var read := SaveFile.new().load_from(path)
	t.check(read.best_score == 12500 and read.best_rank == "S", "the best score comes back (%d, %s)" % [read.best_score, read.best_rank])
	t.check(read.last_loadout == PackedStringArray(["nova", "heaven", "cinder", "gravity"]),
		"and the loadout comes back in its own order (%s)" % [read.last_loadout])

	# A loadout with a key that is not a power any more is dropped rather than carried into the draft.
	read.remember_loadout(PackedStringArray(["nova", "kettle", "cinder"]))
	read.save_to(path)
	var filtered := SaveFile.new().load_from(path)
	t.check(filtered.last_loadout == PackedStringArray(["nova", "cinder"]),
		"a key that is not a power is dropped (%s)" % [filtered.last_loadout])

	# A damaged file reads as a fresh one instead of raising. `\x00\x01` is not a valid GDScript string
	# escape (only `\uXXXX` is), so the raw bytes are appended after the text instead.
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("this is not a config file\n")
	f.store_buffer(PackedByteArray([0, 1]))
	f.close()
	var broken := SaveFile.new().load_from(path)
	t.check(broken.best_score == 0 and broken.last_loadout.is_empty(),
		"a damaged save file reads as a fresh one (%d, %s)" % [broken.best_score, broken.last_loadout])

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	t.check(not FileAccess.file_exists(path), "the test cleans up after itself")
