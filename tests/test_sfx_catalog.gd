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
	t.check(count == 142, "catalog covers all 142 generated files (got %d)" % count)
	for cue in [&"orb_hit", &"laser_sizzle"]:
		t.check(Sfx.paths_for(cue).size() > 1, "%s has variants" % cue)

	# Every sound has a source and every source is built into a file the catalog plays. A source is a GodotSfxr
	# resource or score (tools/audio/sfxr/<category>/), a recipe of recordings (tools/audio/foley/<category>/..., the
	# powers' over tools/audio/synth.py's renders) or a music score (tools/audio/music/<cue>.score.json).
	var played := {}
	for cue in Sfx.CATALOG:
		for path in Sfx.paths_for(cue):
			played[path] = true
	var unbaked := ""
	var sourced := {}
	var from := {"sfxr": 0, "foley": 0, "music": 0}
	for kind: String in ["sfxr", "foley"]:
		for file in _sources("res://tools/audio/%s/" % kind, ""):
			var rel: String = file.trim_suffix(".score.json").trim_suffix(".json").trim_suffix(".tres")
			var wav := "res://assets/audio/%s.wav" % rel
			sourced[wav] = true
			from[kind] += 1
			if not played.has(wav) or not ResourceLoader.exists(wav):
				unbaked += " " + rel
	for file in DirAccess.get_files_at("res://tools/audio/music/"):
		if file.begins_with("music_") and file.ends_with(".score.json"):
			var wav := "res://assets/audio/music/%s.wav" % file.trim_suffix(".score.json")
			sourced[wav] = true
			from["music"] += 1
			if not played.has(wav) or not ResourceLoader.exists(wav):
				unbaked += " " + file
	t.check(unbaked == "", "every source is built and in the catalog (not:%s)" % unbaked)
	t.check(sourced.size() == 142 and from["sfxr"] == 14 and from["foley"] == 124 and from["music"] == 4,
		"all 142 sounds have a source: 14 GodotSfxr, 124 recipes of recordings, 4 music (%d: %s)" % [sourced.size(), from])
	var orphan := ""
	for path: String in played:
		if not sourced.has(path):
			orphan += " " + path.get_file()
	t.check(orphan == "", "and every file the catalog plays has a source (not:%s)" % orphan)


## Every source file under `dir` (a GodotSfxr resource or score, or a recipe), as a path relative to the root it was
## first called with, without "voices" (instruments, not cues) or any folder starting with "_" (set aside).
static func _sources(root: String, rel: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := root + rel
	for sub in DirAccess.get_directories_at(dir):
		if sub == "voices" or sub.begins_with("_"):
			continue
		out.append_array(_sources(root, rel + sub + "/"))
	if rel != "":
		for file in DirAccess.get_files_at(dir):
			if file.get_extension() in ["tres", "json"]:
				out.append(rel + file)
	return out
