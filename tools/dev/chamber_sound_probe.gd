extends SceneTree
## Dev check (God's Chamber step 7, design section 9): the calm-minute probe. Runs the room's sound plan (ChamberSound, its own seeded
## random) for 60 s at rest and counts what plays; the design's target is at most about 6 occasional sounds a minute.
## Usage: godot --headless --path . -s tools/dev/chamber_sound_probe.gd [-- --seeds=200 --json=<file> --seed=<n>]
##   --json writes one seed's minute (bed + events with their file, pan and level) for tools/dev/chamber_room_mix.py.


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var seeds := 200
	var one := 7
	var json := ""
	for a in args:
		if a.begins_with("--seeds="):
			seeds = int(a.get_slice("=", 1))
		elif a.begins_with("--seed="):
			one = int(a.get_slice("=", 1))
		elif a.begins_with("--json="):
			json = a.get_slice("=", 1)
	var g := GodSlot.make(1, "ruin", 77)
	g.tier = 3
	g.notice = 40
	var st := ChamberLife.state(g, HubStatus.new(g))
	var counts := {}
	var worst := 0
	var total := 0
	for seed in seeds:
		var plan := ChamberSound.new()
		plan.setup(st, seed)
		var n := plan.calm_minute().size()
		counts[n] = int(counts.get(n, 0)) + 1
		worst = maxi(worst, n)
		total += n
		plan.free()
	print("calm-minute probe: %d seeds, mean %.2f, worst %d a minute (target <= %d); counts %s" % [seeds, float(total) / seeds, worst,
		ChamberSound.MAX_PER_MINUTE, counts])
	if json != "":
		var plan := ChamberSound.new()
		plan.setup(st, one)
		var events := []
		var clock := 0.0
		for i in 3600:
			clock += 1.0 / 60.0
			for e: Dictionary in plan.step(1.0 / 60.0):
				events.append({"t": snappedf(clock, 0.001), "cue": String(e.cue), "file": ProjectSettings.globalize_path(e.path),
					"pan": e.pan, "db": e.db})
		plan.free()
		var out := {"seed": one, "state": {"tier": 3, "notice": 40}, "bed": ProjectSettings.globalize_path(Sfx.paths_for(ChamberSound.BED)[0]),
			"bed_db": float(Sfx.CATALOG[ChamberSound.BED].db), "music": ProjectSettings.globalize_path("res://assets/audio/music/music_theme.wav"),
			"music_db": Music.DB, "events": events}
		var f := FileAccess.open(json, FileAccess.WRITE)
		f.store_string(JSON.stringify(out, "  "))
		f.close()
		print("wrote ", json, ": ", events.size(), " sounds in 60 s")
	quit()
