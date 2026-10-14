extends RefCounted


static func run(t) -> void:
	var count := 0
	for cue in Sfx.CATALOG:
		for path in Sfx.paths_for(cue):
			count += 1
			t.check(ResourceLoader.exists(path), "sfx file exists: %s" % path)
		var stream := Sfx.load_stream(cue)
		t.check(stream is AudioStreamWAV, "cue %s loads as AudioStreamWAV" % cue)
		if stream is AudioStreamWAV and Sfx.CATALOG[cue].get("loop", false):
			t.check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "cue %s loops" % cue)
			t.check(stream.loop_end > 0, "cue %s loop_end set" % cue)
	t.check(count == 115, "catalog covers all 115 generated files (got %d)" % count)
	for cue in [&"orb_hit", &"laser_sizzle"]:
		t.check(Sfx.paths_for(cue).size() > 1, "%s has variants" % cue)

	# The GodotSfxr categories (tools/audio/sfxr_bake.gd): every source is baked to a file the catalog plays, and every
	# file the catalog plays from those folders has its source, so none is left over from tools/audio/synth.py.
	var played := {}
	for cue in Sfx.CATALOG:
		for path in Sfx.paths_for(cue):
			played[path] = true
	var src := "res://tools/audio/sfxr/"
	var unbaked := ""
	var sourced := {}
	for category in DirAccess.get_directories_at(src):
		if category == "voices":
			continue
		for file in DirAccess.get_files_at(src + category):
			var name := file.trim_suffix(".score.json") if file.ends_with(".score.json") else file.trim_suffix(".tres")
			if name == file:
				continue
			var wav := "res://assets/audio/%s/%s.wav" % [category, name]
			sourced[wav] = true
			if not played.has(wav) or not ResourceLoader.exists(wav):
				unbaked += " " + name
	t.check(unbaked == "", "every GodotSfxr source is baked and in the catalog (not:%s)" % unbaked)
	t.check(sourced.size() == 37, "37 sounds come from GodotSfxr (%d)" % sourced.size())
	var orphan := ""
	for path: String in played:
		var category := path.get_base_dir().get_file()
		if category in ["ui", "citizen", "building", "music"] and not sourced.has(path):
			orphan += " " + path.get_file()
	t.check(orphan == "", "and every interface, citizen, building and music file has a source (not:%s)" % orphan)
