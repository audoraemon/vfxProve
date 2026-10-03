extends RefCounted
## The save file: defaults when there is nothing to read, a round trip, only better results recorded -- per mission
## since v0.08 -- a pre-v0.08 file read as Last Judgement's, and a file that has been damaged or hand-edited does
## not take the game down with it.


static func run(t) -> void:
	var path := "user://test_save_file.cfg"
	var lj := MissionBook.LAST_JUDGEMENT
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var fresh := SaveFile.new().load_from(path)
	t.check(fresh.best_score == 0 and fresh.best_rank == "-", "no save file means no best score (%d, %s)" % [fresh.best_score, fresh.best_rank])
	t.check(fresh.loadout_for(lj).is_empty(), "and no loadout to preselect")
	t.check(fresh.last_mission == lj, "and Last Judgement is the mission chosen (%s)" % fresh.last_mission)

	# A better score is recorded, a worse one is not.
	t.check(fresh.record(lj, {"won": true, "score": 6200, "rank": "B"}), "the first score is the best score")
	t.check(fresh.best_score == 6200 and fresh.best_rank == "B", "and is kept with its rank (%d, %s)" % [fresh.best_score, fresh.best_rank])
	t.check(not fresh.record(lj, {"won": false, "score": 5000, "rank": "C"}), "a worse run does not beat it")
	t.check(fresh.best_score == 6200 and fresh.best_rank == "B", "and does not overwrite it (%d, %s)" % [fresh.best_score, fresh.best_rank])
	t.check(fresh.record(lj, {"won": true, "score": 12500, "rank": "S"}), "a better run does")
	t.check(fresh.best_score == 12500 and fresh.best_rank == "S", "with its own rank (%d, %s)" % [fresh.best_score, fresh.best_rank])
	t.check(int(fresh.best(lj).best_score) == 12500 and String(fresh.best(lj).best_rank) == "S",
		"best() reports the same (%s)" % fresh.best(lj))

	fresh.remember_loadout(lj, PackedStringArray(["nova", "heaven", "cinder", "gravity"]))
	fresh.save_to(path)
	var read := SaveFile.new().load_from(path)
	t.check(read.best_score == 12500 and read.best_rank == "S", "the best score comes back (%d, %s)" % [read.best_score, read.best_rank])
	t.check(read.loadout_for(lj) == PackedStringArray(["nova", "heaven", "cinder", "gravity"]),
		"and the loadout comes back in its own order (%s)" % [read.loadout_for(lj)])

	# A loadout with a key that is not a power any more is dropped rather than carried into the draft.
	read.remember_loadout(lj, PackedStringArray(["nova", "kettle", "cinder"]))
	read.save_to(path)
	var filtered := SaveFile.new().load_from(path)
	t.check(filtered.loadout_for(lj) == PackedStringArray(["nova", "cinder"]),
		"a key that is not a power is dropped (%s)" % [filtered.loadout_for(lj)])
	# So is a key the mission does not allow (trivially true while Last Judgement allows every power).
	var outside := 0
	for key in filtered.loadout_for(lj):
		if not MissionBook.get_mission(lj).allows(key):
			outside += 1
	t.check(outside == 0, "a key outside the mission's pool is dropped (%d)" % outside)

	# An unscored mission (The Warning, M4): a first win is a new best, so is a first bonus; a loss clears nothing.
	var unscored := SaveFile.new()
	t.check(not bool(unscored.best("warning").won) and not bool(unscored.best("warning").bonus),
		"a mission never played is neither won nor its bonus earned")
	t.check(unscored.record("warning", {"won": true, "bonuses": [{"label": "Unseen", "earned": true}]}),
		"a first win with its bonus is a new best")
	t.check(bool(unscored.best("warning").won) and bool(unscored.best("warning").bonus),
		"and is kept as won, with the bonus (%s)" % unscored.best("warning"))
	t.check(not unscored.record("warning", {"won": false, "bonuses": [{"label": "Unseen", "earned": false}]}),
		"a later loss is not a new best")
	t.check(bool(unscored.best("warning").won) and bool(unscored.best("warning").bonus), "and does not clear the win")
	var second := SaveFile.new()
	t.check(second.record("warning", {"won": true, "bonuses": [{"label": "Unseen", "earned": false}]})
		and not bool(second.best("warning").bonus), "a win without the bonus is a new best, the bonus not earned")
	t.check(second.record("warning", {"won": true, "bonuses": [{"label": "Unseen", "earned": true}]}),
		"then earning the bonus is a new best too")
	t.check(not second.record("warning", {"won": true, "bonuses": [{"label": "Unseen", "earned": true}]}),
		"but winning the same way again is not")
	t.check(unscored.best_score == 0, "another mission's results leave Last Judgement's best alone")

	# The mission last chosen, and each mission's own section, round-trip.
	unscored.last_mission = lj
	unscored.remember_loadout(lj, PackedStringArray(["heaven"]))
	unscored.save_to(path)
	var both := SaveFile.new().load_from(path)
	t.check(both.last_mission == lj and bool(both.best("warning").won) and bool(both.best("warning").bonus),
		"the mission last chosen and an unscored mission's best come back (%s, %s)" % [both.last_mission, both.best("warning")])
	t.check(both.loadout_for(lj) == PackedStringArray(["heaven"]) and both.loadout_for("warning").is_empty(),
		"each mission keeps its own loadout (%s, %s)" % [both.loadout_for(lj), both.loadout_for("warning")])
	var cfg := ConfigFile.new()
	cfg.load(path)
	t.check(cfg.has_section("mission." + lj) and cfg.has_section("mission.warning") and not cfg.has_section_key("kak", "best_score"),
		"the file keeps one section per mission (%s)" % [cfg.get_sections()])
	var stranger := ConfigFile.new()
	stranger.set_value("kak", "last_mission", "no_such_mission")
	stranger.save(path)
	t.check(SaveFile.new().load_from(path).last_mission == lj, "a mission the game does not know reads as Last Judgement")

	# A save from before v0.08 kept the one mission's numbers in [kak]: they are Last Judgement's.
	var old := ConfigFile.new()
	old.set_value("kak", "best_score", 9000)
	old.set_value("kak", "best_rank", "B")
	old.set_value("kak", "last_loadout", PackedStringArray(["nova"]))
	old.set_value("kak", "difficulty", int(ResponseProfile.Tier.GOD_RESISTANT))
	old.save(path)
	var migrated := SaveFile.new().load_from(path)
	t.check(migrated.best_score == 9000 and migrated.best_rank == "B" and int(migrated.best(lj).best_score) == 9000,
		"an old save's best is Last Judgement's (%d, %s)" % [migrated.best_score, migrated.best_rank])
	t.check(migrated.loadout_for(lj) == PackedStringArray(["nova"]) and migrated.difficulty == ResponseProfile.Tier.GOD_RESISTANT,
		"and so is its loadout, with its difficulty kept (%s)" % [migrated.loadout_for(lj)])
	migrated.save_to(path)
	var resaved := SaveFile.new().load_from(path)
	t.check(resaved.best_score == 9000 and resaved.loadout_for(lj) == PackedStringArray(["nova"]),
		"and it survives being saved in the new form (%d, %s)" % [resaved.best_score, resaved.loadout_for(lj)])

	# A damaged file reads as a fresh one instead of raising. `\x00\x01` is not a valid GDScript string
	# escape (only `\uXXXX` is), so the raw bytes are appended after the text instead.
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("this is not a config file\n")
	f.store_buffer(PackedByteArray([0, 1]))
	f.close()
	var broken := SaveFile.new().load_from(path)
	t.check(broken.best_score == 0 and broken.loadout_for(lj).is_empty(),
		"a damaged save file reads as a fresh one (%d, %s)" % [broken.best_score, broken.loadout_for(lj)])

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	t.check(not FileAccess.file_exists(path), "the test cleans up after itself")
