extends SceneTree
## Scripted citizen-behaviour scenarios (v0.04), on the real mission at a fixed step (run with --fixed-fps 60), so
## each prints the same numbers every run. Each ends with a checksum of everyone's position and mind.
##
## usage: godot --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=calm
##   [--seconds=60] [--shots]
##   calm   nothing cast: where citizens are, by kind of place, every 20 s; --shots saves captures at the end
##   strike after 20 s of calm, one Heaven Splitter in the market: intents by distance from it, over 30 s
##   escalate  three casts across town, 15 s apart: the alarm stage, the bell and everyone's intents every 5 s
##   gates  an evacuation called after 20 s of calm; --hazard puts a lasting danger on the Main Gate's approach at
##          5 s: evacuees by chosen exit, reroutes and queues over 40 s
##   bell   a strike in the west after 20 s of calm; --kill-keeper kills the bellkeeper first (quietly): the Bell
##          Tower's state, the stage and the alarm every 2 s over 30 s
##   fire   three houses set burning in the west quarter after 20 s of calm: fires, intensity, responders over 40 s
##   rite   (Prepared) City Emergency called after 20 s of calm: the Banishing Rite's state, the ring, its progress and
##          the manifestation's clock every 5 s over 90 s; --interrupt quietly kills three of the ring's clergy 10 s
##          into the chant (as Silent Doom will): the rite breaks, and the rest regather after the cooldown
##   engineers  (Prepared) City Emergency called after 20 s of calm, then a Heaven Splitter on the Citadel and the
##          bridge brought down: the Citadel's health, the bridge and each team's job every 5 s over 60 s
##   boats  (Prepared) an evacuation called after 20 s of calm: evacuees by chosen way out (south road, east road,
##          dock), the boats' state, load and crowd, and escapes, over 40 s; --cut-bridge brings the bridge down at 5 s
##   quiet  (loadout Silent Doom, Blight, Heaven Splitter, Nuclear Nova) after 20 s of calm: Silent Doom on the
##          bellkeeper, Blight on the Bell Tower and on the Main Gate, then at 30 s a Heaven Splitter in the west: the
##          alarm, the stage, the bell and the dead every 5 s over 60 s; --shots photographs the rot and the doom
##   opening  (v0.05 M7) stealth against loud: the same four loud casts from 30 s (Heaven Splitter in the west and the
##          north-west, Cinderfall Barrage, Heaven Splitter at the Citadel), and with --quiet a quiet opening first at 20 s
##          (Silent Doom on the bellkeeper, Blight on the Bell Tower and the Main Gate): the alarm, the stage, the bell
##          and the escapes every 5 s over 100 s, then the stage history
##   siege  (v0.05 M7) one scripted siege for comparing the difficulty tiers (--difficulty=): eight casts over 105 s
##          from 20 s (the first in the west, clear of the Bell Tower), then a report every 15 s to 150 s -- escapes, the Citadel, the clock, the rite, the boats, the
##          engineers
##   clip   (v0.06) a power's preview clip for the draft, recorded in the town rather than the sandbox (whose dummy
##          troopers cannot be lured, confused or infected): --power=<key> [--at=x,y] [--snap] [--seconds=s]
##          [--setup=rite|evac]; --snap aims at the citizen nearest --at;
##          Prepared, the power in slot 1, cast after 20 s of calm (and the setup), PowerBook.CLIP_FRAMES frames over
##          its run into assets/clips/<key>.png
## --difficulty=<tier> plays any scenario at that tier (default Organized; rite, engineers and boats: Prepared).

const SEED := 7

var mission: Mission


func _initialize() -> void:
	mission = load("res://scenes/mission.tscn").instantiate()
	root.add_child(mission)
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var scenario := Battlefield.arg_value(args, "--scenario")
	var seconds := float(Battlefield.arg_value(args, "--seconds")) if Battlefield.arg_value(args, "--seconds") != "" \
		else 60.0
	while not mission.is_prewarmed or not mission.started():
		await process_frame
	# A fixed seed (--seed=, default SEED): without a scripted flag the mission seeds itself from the clock.
	var seed_arg := Battlefield.arg_value(args, "--seed")
	var tier := Battlefield.arg_value(args, "--difficulty")
	if tier == "" and scenario in ["rite", "engineers", "boats", "clip"]:
		tier = "prepared"
	if tier != "":
		mission.difficulty = ResponseProfile.tier_named(tier)
	var powers := PackedStringArray()
	if scenario == "quiet":
		powers = PackedStringArray(["doom", "blight", "heaven", "nova"])
	elif scenario == "clip":
		powers = PackedStringArray([Battlefield.arg_value(args, "--power"), "heaven", "cinder", "nova"])
	elif scenario == "opening":
		powers = PackedStringArray(["doom", "blight", "heaven", "cinder"])
	mission.start(powers, int(seed_arg) if seed_arg != "" else SEED)
	mission._intro_left = 0.0
	mission._rules.set_process(true)
	match scenario:
		"calm", "":
			await _calm(seconds, "--shots" in args)
		"strike":
			await _strike("--shots" in args)
		"escalate":
			await _escalate()
		"fire":
			await _fire("--shots" in args)
		"bell":
			await _bell("--kill-keeper" in args, "--shots" in args)
		"rite":
			await _rite("--interrupt" in args, "--shots" in args)
		"engineers":
			await _engineers("--shots" in args)
		"boats":
			await _boats("--cut-bridge" in args, "--shots" in args)
		"quiet":
			await _quiet("--shots" in args)
		"opening":
			await _opening("--quiet" in args)
		"clip":
			await _clip(Battlefield.arg_value(args, "--power"), Battlefield.arg_value(args, "--at"),
				Battlefield.arg_value(args, "--seconds"), Battlefield.arg_value(args, "--setup"))
		"siege":
			await _siege()
		"gates":
			await _gates("--hazard" in args, "--shots" in args)
	print("BEHAVIOUR checksum=%d" % _checksum())
	quit()


func _calm(seconds: float, shots: bool) -> void:
	var t := 0.0
	while t < seconds:
		await _frames(20 * 60)
		t += 20.0
		print("BEHAVIOUR calm t=%d %s" % [roundi(t), _places()])
	if shots:
		var bf: Battlefield = mission._bf
		for shot in [["behaviour_market.png", Vector2(0.8, 2.0), 1.0], ["behaviour_town.png", Vector2(0, 2), 0.3],
				["behaviour_farms.png", Vector2(2.0, 24.0), 0.5]]:
			bf.camera.zoom = Vector2.ONE * float(shot[2])
			bf.camera.position = Iso.ground_to_screen(shot[1]).round()
			await _frames(3)
			await bf.save_capture(shot[0])


func _strike(shots: bool) -> void:
	await _frames(20 * 60)
	var at := Vector2(0.8, 2.0)
	mission._rules.cast(0, at, {"dir": Vector2(1, 0)})
	var t := 0.0
	for mark in [0.5, 2.0, 5.0, 10.0, 20.0, 30.0]:
		await _frames(roundi((mark - t) * 60.0))
		t = mark
		print("BEHAVIOUR strike t=%.1f %s" % [t, _bands(at)])
		if shots and is_equal_approx(mark, 2.0):
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 0.6
			bf.camera.position = Iso.ground_to_screen(at).round()
			await _frames(2)
			await bf.save_capture("behaviour_strike.png")


func _escalate() -> void:
	await _frames(20 * 60)
	var casts := [[0.0, 0, Vector2(0.8, 2.0)], [15.0, 2, Vector2(-9.0, 5.0)], [30.0, 1, Vector2(7.0, -3.0)]]
	var t := 0.0
	var crowd: Crowd = mission._crowd
	while t <= 60.0:
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			mission._rules.dp = Rules.DP_MAX
			mission._rules._cooldowns[int(c[1])] = 0.0
			mission._rules._playing = null
			mission._rules.cast(int(c[1]), c[2], {"dir": Vector2(1, 0.3).normalized()})
		var intents := {}
		for p: Person in crowd.citizens:
			if is_instance_valid(p) and p.state != DummyEnemy.State.DEAD:
				var k: String = Person.Intent.keys()[p.intent()]
				intents[k] = int(intents.get(k, 0)) + 1
		print("BEHAVIOUR escalate t=%d stage=%s alarm=%d bell=%s escaped=%d %s" % [roundi(t), crowd.alarms.stage_name(),
			roundi(crowd.alarm), crowd.alarms.bell_rung, crowd.escaped_count, intents])
		await _frames(5 * 60)
		t += 5.0
	for h in crowd.alarms.history:
		print("BEHAVIOUR stage at %.1f: %s (%s)" % [float(h[0]), AlarmManager.NAMES[h[1]], h[2]])


func _bell(kill_keeper: bool, shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	if kill_keeper and crowd.bell.keeper != null:
		crowd._field.kill(crowd.bell.keeper, &"test")
	mission._rules.cast(0, Vector2(-10.0, 3.0), {"dir": Vector2(1, 0)})
	var t := 0.0
	var shot := false
	while t < 30.0:
		await _frames(2 * 60)
		t += 2.0
		var k: Person = crowd.bell.keeper
		var where := "-" if k == null or not is_instance_valid(k) else "%s mind=%s goal=%s foot=%.1f" % [k.ground_pos.round(),
			Person.Mind.keys()[k.mind], k.goal().round(), k.ground_pos.distance_to(crowd.bell.foot)]
		print("BEHAVIOUR bell t=%d state=%s progress=%.1f stage=%s alarm=%d rung=%s keeper %s" % [roundi(t),
			BellNetwork.State.keys()[crowd.bell.state], crowd.bell.progress, crowd.alarms.stage_name(), roundi(crowd.alarm),
			crowd.alarms.bell_rung, where])
		if shots and not shot and crowd.bell.state == BellNetwork.State.CLIMBING:
			shot = true
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 1.0
			bf.camera.position = (Iso.ground_to_screen(TownLayout.BELL_TOWER.get_center()) + Vector2(0, -20)).round()
			await _frames(2)
			await bf.save_capture("behaviour_bell.png")


func _rite(interrupt: bool, shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var rules: Rules = mission._rules
	crowd.add_alarm(AlarmManager.CITY_ALARM)
	var t := 0.0
	var struck := false
	var shot := false
	while t < 90.0:
		await _frames(5 * 60)
		t += 5.0
		var r := crowd.rite
		if interrupt and not struck and r.state == BanishingRite.State.CHANTING and r.progress >= 10.0:
			struck = true
			for e in r.circle.slice(0, 3):
				crowd._field.kill(e[0], &"test")
			r.step(0.0)
			print("BEHAVIOUR rite t=%d three of the clergy killed" % roundi(t))
		print("BEHAVIOUR rite t=%d state=%s ring=%d called=%d progress=%.1f clergy=%d cathedral=%d%% time_left=%.1f stage=%s" % [
			roundi(t), BanishingRite.State.keys()[r.state], r.in_ring(), r.circle.size(), r.progress, r.living_clergy(),
			roundi(100.0 * r.cathedral.hp / r.cathedral.max_hp) if is_instance_valid(r.cathedral) else 0, rules.time_left,
			crowd.alarms.stage_name()])
		if shots and not shot and r.state == BanishingRite.State.CHANTING and r.progress >= 5.0:
			shot = true
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 1.0
			bf.camera.position = (Iso.ground_to_screen(r.centre) + Vector2(0, -30)).round()
			await _frames(2)
			await bf.save_capture("behaviour_rite.png")


func _engineers(shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var rules: Rules = mission._rules
	var town: Town = mission._town
	crowd.add_alarm(AlarmManager.CITY_ALARM)
	rules.cast(0, town.citadel.origin, {"dir": Vector2(1, 0)})
	var bridge := town.bridge
	bridge.destroy(bridge.center(), &"nova")
	var e := crowd.engineers
	var t := 0.0
	var shots_taken := {}
	while t < 60.0:
		await _frames(5 * 60)
		t += 5.0
		var parts := []
		for team: Dictionary in e.teams:
			var job: Dictionary = team.job
			parts.append("standby" if job.is_empty() else "%s%s %d%%%s" % ["rebuild " if job.rebuild else "",
				EngineerManager.Job.keys()[job.type], roundi(100.0 * e.job_fraction(team)), " working" if team.working else ""])
		print("BEHAVIOUR engineers t=%d citadel=%.1f%% cap=%.0f%% bridge=%s teams=%s stage=%s" % [roundi(t),
			100.0 * town.citadel.fraction(), 100.0 * town.citadel.repair_cap() / town.citadel.max_health,
			"down" if bridge.destroyed else "standing", parts, crowd.alarms.stage_name()])
		if shots:
			for team: Dictionary in e.teams:
				var job: Dictionary = team.job
				if not team.working or job.is_empty():
					continue
				var name := "behaviour_engineers_%s.png" % ("rebuild" if job.rebuild else String(EngineerManager.Job.keys()[job.type]).to_lower())
				if shots_taken.has(name):
					continue
				shots_taken[name] = true
				var bf: Battlefield = mission._bf
				bf.camera.zoom = Vector2.ONE * 1.0
				bf.camera.position = (Iso.ground_to_screen(job.site) + Vector2(0, -40)).round()
				await _frames(2)
				await bf.save_capture(name)
	if shots:
		var bf: Battlefield = mission._bf
		bf.camera.position = (Iso.ground_to_screen(bridge.center()) + Vector2(0, -40)).round()
		await _frames(2)
		await bf.save_capture("behaviour_engineers_after.png")


func _boats(cut_bridge: bool, shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	crowd.alarms.bell_rung = true
	crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
	crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
	crowd.add_alarm(100.0)
	var f := crowd.ferry
	var t := 0.0
	for mark in [1.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0]:
		await _frames(roundi((mark - t) * 60.0))
		t = mark
		if cut_bridge and t == 5.0:
			mission._town.bridge.destroy(mission._town.bridge.center(), &"nova")
		var by_exit := {}
		for p: Person in crowd.citizens:
			if not is_instance_valid(p) or p.state == DummyEnemy.State.DEAD or p.mind != Person.Mind.FLEE or p.inside:
				continue
			var k := "south" if p.goal() == TownLayout.EXITS[0] else ("east" if p.goal() == TownLayout.EXITS[1]
				else ("dock" if p.goal() == f.board_at else "none"))
			by_exit[k] = int(by_exit.get(k, 0)) + 1
		print("BEHAVIOUR boats t=%d by exit %s boats=%s aboard=%d waiting=%d trips=%d carried=%d escaped=%d bridge=%s" % [
			roundi(t), by_exit, RiverFerry.State.keys()[f.state], f.aboard.size(), f.waiting(), f.trips, f.carried,
			crowd.escaped_count, "down" if mission._town.bridge.destroyed else "up"])
		if shots and (t == 15.0 or t == 25.0):
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 1.0
			var at := f.board_at if t == 15.0 else TownLayout.POSTERN_AT
			bf.camera.position = (Iso.ground_to_screen(at) + Vector2(0, -30)).round()
			await _frames(2)
			await bf.save_capture("behaviour_boats.png" if t == 15.0 else "behaviour_postern.png")


func _quiet(shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var rules: Rules = mission._rules
	var gate: Structure = mission._town.gates[0]
	var keeper: Person = crowd.bell.keeper
	var casts := [[0.0, 0, keeper.ground_pos if keeper != null else Vector2.ZERO, "doom on the bellkeeper"],
		[2.0, 1, crowd.bell.tower.center(), "blight on the Bell Tower"],
		[4.0, 1, gate.center() - Vector2(0, 0.5), "blight on the Main Gate"],
		[10.0, 2, Vector2(-10.0, 3.0), "Heaven Splitter in the west"]]
	var t := 0.0
	var shot := {}
	var bf: Battlefield = mission._bf
	if shots:
		# The aim previews: Silent Doom rings who it would take, Blight outlines what it would ruin.
		for slot in [0, 1]:
			var aim_at: Vector2 = keeper.ground_pos if slot == 0 else crowd.bell.tower.center() + Vector2(0.6, 0.6)
			mission._aim.pick(slot)
			bf.camera.zoom = Vector2.ONE * 1.5
			bf.camera.position = (Iso.ground_to_screen(aim_at) + Vector2(0, -16)).round()
			await _frames(2)
			# The mission aims wherever the mouse is, every frame: put the mouse on the target.
			bf.get_viewport().warp_mouse(bf.get_viewport().get_canvas_transform() * Iso.ground_to_screen(aim_at))
			await _frames(3)
			await bf.save_capture("behaviour_aim_%s.png" % ["doom", "blight"][slot])
		mission._aim.unfocus()
	while t <= 60.0:
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			rules.dp = Rules.DP_MAX
			rules._cooldowns[int(c[1])] = 0.0
			rules._playing = null
			rules.cast(int(c[1]), c[2], {"dir": Vector2(1, 0)})
			print("BEHAVIOUR quiet t=%.1f %s" % [t, c[3]])
			if shots and int(c[1]) == 0:
				bf.camera.zoom = Vector2.ONE * 1.5
				bf.camera.position = (Iso.ground_to_screen(c[2]) + Vector2(0, -16)).round()
				await _frames(roundi(SilentDoom.T_STRIKE * 60.0) - 6)
				await bf.save_capture("behaviour_doom.png")
		print("BEHAVIOUR quiet t=%.1f alarm=%.1f stage=%s bell=%s keeper=%s killed=%d threats=%d gate=%s" % [t,
			crowd.alarm, crowd.alarms.stage_name(), BellNetwork.State.keys()[crowd.bell.state],
			"alive" if is_instance_valid(keeper) and keeper.is_alive() else "dead", crowd.killed_citizens,
			crowd.threats.active_count(), "jammed" if gate.blighted else "open"])
		if shots and t >= 5.0 and not shot.has("rot"):
			shot["rot"] = true
			bf.camera.zoom = Vector2.ONE * 1.0
			bf.camera.position = (Iso.ground_to_screen(crowd.bell.tower.center()) + Vector2(0, -30)).round()
			await _frames(2)
			await bf.save_capture("behaviour_blight.png")
		var step := 2.0 if t < 4.0 else 5.0
		await _frames(roundi(step * 60.0))
		t += step


## Cast slot `slot` at `at` now, whatever its cooldown, the DP left or another power still playing.
func _force_cast(slot: int, at: Vector2, dir := Vector2(1, 0)) -> FxTimeline:
	var rules: Rules = mission._rules
	rules.dp = Rules.DP_MAX
	rules._cooldowns[slot] = 0.0
	rules._playing = null
	return rules.cast(slot, at, {"dir": dir})


## A power's draft preview, recorded in the town: the camera close on the cast, the HUD hidden, CLIP_FRAMES frames
## spread over `seconds` (default: the effect's run), each the screen's middle at half size, as the sandbox's clips.
func _clip(key: String, at_arg: String, seconds_arg: String, setup: String) -> void:
	var at := Vector2(0.8, 2.0)
	if at_arg != "":
		var xy := at_arg.split(",")
		at = Vector2(float(xy[0]), float(xy[1]))
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	if setup == "rite":
		crowd.add_alarm(AlarmManager.CITY_ALARM)
		await _frames(20 * 60)
	elif setup == "evac":
		crowd.alarms.bell_rung = true
		crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
		crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
		crowd.add_alarm(100.0)
		await _frames(10 * 60)
	if "--snap" in OS.get_cmdline_user_args():
		# Aim at the citizen nearest the point asked for (a queue forms where it will, not where it was guessed).
		var best := INF
		var near := at
		for p: Person in crowd.citizens:
			if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) < best:
				best = p.ground_pos.distance_to(at)
				near = p.ground_pos
		at = near
	var bf: Battlefield = mission._bf
	mission._hud.visible = false
	bf.camera.zoom = Vector2.ONE * 1.5
	bf.camera.position = (Iso.ground_to_screen(at) + Vector2(0, -16)).round()
	bf.camera.reset_smoothing()
	await _frames(2)
	var fx := _force_cast(0, at, Vector2(1, 0))
	var run := float(seconds_arg) if seconds_arg != "" else (fx.duration if fx != null else 4.0)
	var crop := PowerBook.CLIP_SIZE * 2
	var rows := ceili(float(PowerBook.CLIP_FRAMES) / PowerBook.CLIP_COLUMNS)
	var sheet := Image.create(PowerBook.CLIP_SIZE.x * PowerBook.CLIP_COLUMNS, PowerBook.CLIP_SIZE.y * rows, false,
		Image.FORMAT_RGBA8)
	var t := 0.0
	for i in PowerBook.CLIP_FRAMES:
		var due := run * (float(i) + 0.5) / float(PowerBook.CLIP_FRAMES)
		await _frames(maxi(roundi((due - t) * 60.0), 0))
		t = due
		await RenderingServer.frame_post_draw
		var img := bf.get_viewport().get_texture().get_image()
		var from := Vector2i((img.get_width() - crop.x) / 2, (img.get_height() - crop.y) / 2)
		var frame := img.get_region(Rect2i(from, crop))
		frame.convert(Image.FORMAT_RGBA8)
		frame.resize(PowerBook.CLIP_SIZE.x, PowerBook.CLIP_SIZE.y, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, PowerBook.CLIP_SIZE), Vector2i(PowerBook.clip_frame(i).position))
		if i == PowerBook.CLIP_FRAMES / 2 or i == PowerBook.CLIP_FRAMES - 1:
			_clip_report(key, at, t)
	var out := ProjectSettings.globalize_path(PowerBook.clip_path(key))
	sheet.save_png(out)
	print("BEHAVIOUR clip ", out)


func _opening(quiet: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var gate: Structure = mission._town.gates[0]
	var keeper: Person = crowd.bell.keeper
	var casts: Array = []
	if quiet:
		casts.append_array([[0.0, 0, keeper.ground_pos if keeper != null else Vector2.ZERO],
			[2.0, 1, crowd.bell.tower.center()], [4.0, 1, gate.center() - Vector2(0, 0.5)]])
	casts.append_array([[10.0, 2, Vector2(-10.0, 3.0)], [25.0, 2, Vector2(-9.0, -11.0)], [40.0, 3, Vector2(-9.0, 9.0)],
		[55.0, 2, Vector2(-10.5, -8.0)]])
	var t := 0.0
	while t <= 100.0:
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			_force_cast(int(c[1]), c[2])
		if int(t) % 5 == 0:
			print("BEHAVIOUR opening t=%d alarm=%.1f stage=%s bell=%s escaped=%d alive=%d" % [roundi(t), crowd.alarm,
				crowd.alarms.stage_name(), BellNetwork.State.keys()[crowd.bell.state], crowd.escaped_count,
				crowd.alive_citizens()])
		await _frames(60)
		t += 1.0
	for h in crowd.alarms.history:
		print("BEHAVIOUR stage at %.1f: %s (%s)" % [float(h[0]), AlarmManager.NAMES[h[1]], h[2]])


func _siege() -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var rules: Rules = mission._rules
	var citadel: Citadel = mission._town.citadel
	var o := TownLayout.CITADEL_ORIGIN
	# The default loadout: heaven, tsunami, cinder, nova.
	if crowd.rite != null:
		crowd.rite.broken.connect(func(why: String) -> void: print("BEHAVIOUR siege rite broken: %s" % why))
		crowd.rite.ended.connect(func(why: String) -> void: print("BEHAVIOUR siege rite ended: %s" % why))
		crowd.rite.completed.connect(func() -> void: print("BEHAVIOUR siege rite completed"))
	var casts := [[0.0, 0, Vector2(-10.0, 3.0)], [15.0, 2, Vector2(-9.0, 5.0)], [30.0, 3, o], [45.0, 1, Vector2(5.0, -3.0)],
		[60.0, 0, o + Vector2(0.0, 2.5)], [75.0, 2, Vector2(10.0, 10.0)], [90.0, 3, o], [105.0, 0, Vector2(2.0, 12.0)]]
	var t := 0.0
	while t <= 130.0:
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			_force_cast(int(c[1]), c[2], Vector2(1, 0.3).normalized())
		if int(t) % 15 == 0:
			var teams := []
			if crowd.engineers != null:
				for team: Dictionary in crowd.engineers.teams:
					teams.append("idle" if (team.job as Dictionary).is_empty() else String(EngineerManager.Job.keys()[team.job.type]).to_lower())
			print("BEHAVIOUR siege t=%d stage=%s alarm=%d escaped=%d alive=%d citadel=%.0f%% stability=%.0f%% clock=%s rite=%s boats=%d engineers=%s jobs=%d over=%s" % [
				roundi(t), crowd.alarms.stage_name(), roundi(crowd.alarm), crowd.escaped_count, crowd.alive_citizens(),
				100.0 * citadel.fraction(), 100.0 * rules.stability.total(), UiTheme.clock(rules.time_left),
				BanishingRite.State.keys()[crowd.rite.state] if crowd.rite != null else "-",
				crowd.ferry.carried if crowd.ferry != null else 0, teams,
				crowd.engineers.jobs().size() if crowd.engineers != null and crowd.engineers.active else -1, rules.over_reason])
		await _frames(60)
		t += 1.0
	for h in crowd.alarms.history:
		print("BEHAVIOUR stage at %.1f: %s (%s)" % [float(h[0]), AlarmManager.NAMES[h[1]], h[2]])


## What the power is doing halfway through its clip, for the record.
func _clip_report(key: String, at: Vector2, t: float) -> void:
	var crowd: Crowd = mission._crowd
	var near := 0
	var watching := 0
	for p: Person in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and p.ground_pos.distance_to(at) <= 2.5:
			near += 1
			if p.mind == Person.Mind.OBSERVE:
				watching += 1
	var queues := []
	for g in mission._town.gates:
		queues.append(crowd.waiting_at(g) if g.walkable else -1)
	var confused := 0
	for p: Person in crowd.citizens:
		if is_instance_valid(p) and p.mind == Person.Mind.CONFUSED:
			confused += 1
	print("BEHAVIOUR clip %s t=%.1f within 2.5: %d citizens, %d watching; confused=%d sick=%d plague_dead=%d alarm=%.1f threats=%d queues(main,side,postern)=%s escaped=%d" % [
		key, t, near, watching, confused, crowd.plague.sick.size() if crowd.plague != null else 0,
		crowd.plague.deaths if crowd.plague != null else 0, crowd.alarm, crowd.threats.active_count(), queues,
		crowd.escaped_count])


func _fire(shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var lit := 0
	for st in mission._bf.ctx.env.structures():
		if lit < 3 and st.kind == Structure.Kind.HOUSE and st.role == &"house" and st.center().distance_to(Vector2(-12, 3)) < 3.5:
			crowd.fires.ignite(st, 0.4)
			lit += 1
	var t := 0.0
	for mark in [2.0, 5.0, 10.0, 15.0, 20.0, 30.0, 40.0]:
		await _frames(roundi((mark - t) * 60.0))
		t = mark
		var parts := []
		var crew := 0
		for st in crowd.fires.fires.keys():
			parts.append("%.2f" % crowd.fires.intensity(st))
			crew += (crowd.fires.fires[st].responders as Array).size()
		var assisting := 0
		for p: Person in crowd.citizens:
			if is_instance_valid(p) and p.mind == Person.Mind.ASSIST:
				assisting += 1
		print("BEHAVIOUR fire t=%d fires=%d intensity=[%s] responders=%d stage=%s" % [roundi(t), crowd.fires.fires.size(),
			", ".join(parts), assisting, crowd.alarms.stage_name()])
		if shots and t == 10.0:
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 1.0
			bf.camera.position = Iso.ground_to_screen(Vector2(-12, 2.5)).round()
			await _frames(2)
			await bf.save_capture("behaviour_fire.png")


func _gates(hazard: bool, shots := false) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	crowd.alarms.bell_rung = true
	crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
	crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
	crowd.add_alarm(100.0)
	var t := 0.0
	var placed := false
	for mark in [1.0, 5.0, 6.0, 10.0, 20.0, 30.0, 40.0]:
		await _frames(roundi((mark - t) * 60.0))
		t = mark
		if hazard and not placed and t >= 5.0:
			placed = true
			crowd.threats.register(Vector2(2.7, 11.5), 2.5, 0.8, 60.0, 8.0, 12.0, &"test")
		var by_exit := {}
		var rerouting := 0
		for p: Person in crowd.citizens:
			if not is_instance_valid(p) or p.state == DummyEnemy.State.DEAD or p.mind != Person.Mind.FLEE:
				continue
			var k := "south" if p.goal() == TownLayout.EXITS[0] else ("east" if p.goal() == TownLayout.EXITS[1] else "none")
			by_exit[k] = int(by_exit.get(k, 0)) + 1
			if p.intent() == Person.Intent.REROUTE:
				rerouting += 1
		var queues := []
		for g in crowd.evac.gates:
			queues.append(crowd.waiting_at(g))
		if shots and t == 10.0:
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 0.6
			bf.camera.position = Iso.ground_to_screen(Vector2(6.0, 9.0)).round()
			await _frames(2)
			await bf.save_capture("behaviour_gates.png")
		print("BEHAVIOUR gates t=%d by exit %s rerouting=%d queues(main,side)=%s escaped=%d" % [roundi(t), by_exit,
			rerouting, queues, crowd.escaped_count])


## Living citizens' intents, by distance band (ground units) from `at`.
func _bands(at: Vector2) -> String:
	var bands := [[0.0, 6.0], [6.0, 12.0], [12.0, 20.0], [20.0, 999.0]]
	var parts := []
	for b in bands:
		var counts := {}
		for p: Person in mission._crowd.citizens:
			if not is_instance_valid(p) or p.state == DummyEnemy.State.DEAD:
				continue
			var d := p.ground_pos.distance_to(at)
			if d >= float(b[0]) and d < float(b[1]):
				var k: String = Person.Intent.keys()[p.intent()]
				counts[k] = int(counts.get(k, 0)) + 1
		parts.append("%d-%d:%s" % [b[0], mini(int(b[1]), 99), counts])
	return " ".join(parts)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Citizens by the kind of place they are nearest (within 1.5 units), or "walking"/"elsewhere".
func _places() -> Dictionary:
	var anchors := TownLayout.anchors()
	var out := {}
	for p: Person in mission._crowd.citizens:
		if not is_instance_valid(p) or p.state == DummyEnemy.State.DEAD:
			continue
		var kind := "walking" if p.has_goal() else "elsewhere"
		if kind == "elsewhere":
			var best := 1.5
			for k in anchors:
				for g: Vector2 in anchors[k]:
					var d := g.distance_to(p.ground_pos)
					if d < best:
						best = d
						kind = k
		out[kind] = int(out.get(kind, 0)) + 1
	return out


func _checksum() -> int:
	var h := 17
	for p: Person in mission._crowd.citizens + mission._crowd.soldiers:
		if is_instance_valid(p):
			h = (h * 31 + roundi(p.ground_pos.x * 100.0)) % 1000000007
			h = (h * 31 + roundi(p.ground_pos.y * 100.0)) % 1000000007
			h = (h * 31 + int(p.mind)) % 1000000007
	return h
