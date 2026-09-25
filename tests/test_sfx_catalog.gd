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
	t.check(count == 86, "catalog covers all 86 generated files (got %d)" % count)
	for cue in [&"orb_hit", &"laser_sizzle"]:
		t.check(Sfx.paths_for(cue).size() > 1, "%s has variants" % cue)
